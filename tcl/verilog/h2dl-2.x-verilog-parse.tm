# ODFI H2DL
# Copyright (C) 2016 Richard Leys  <leys.richard@gmail.com> , University of Karlsruhe  - Asic and Detector Lab Group
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
package provide odfi::h2dl::verilog::parse 2.0.0
package require odfi::h2dl::verilog          2.0.0
package require odfi::files 2.0.0
package require odfi::flist 1.0.0

namespace eval odfi::h2dl::verilog::parse {

    proc reverse {file args} {

        set res [::odfi::flist::MutableList new]

        ## Content is content or file
        set content $file
        set isFile false

        #puts "content: $content"
        if {[file exists $content]} {
            set content [odfi::files::readFileContent $content]
            set isFile true
            #puts "Reversing file $file"
        }

        set lineReader [::new ::odfi::files::LineReader #auto $content]

        ## Look for modules
        ##########################
        #puts "content: $content"
        set modules [regexp  -inline -all {(?:\n\r?|^)\s*module\s+(?:[\w_]+)(?:(?!endmodule).+)endmodule} $content]

        #puts "Found modules: $modules"

        foreach moduleContent $modules {

            $res += [reverseModule $moduleContent]

        }

        ## Single Parse remaining lines
        ###########

        return $res
    }

    proc reverseModule {moduleContent args} {

        #puts "REverse: $moduleContent"
        regexp {(?:\n\r?|^)\s*module\s+([\w_]+);?} $moduleContent -> moduleName

        #puts "Module $moduleName"

        ## Create Module
        ##################
        set __module [::odfi::h2dl::module $moduleName {
            :attribute ::odfi::h2dl blackbox
        }]
        ## Go For IOs and such
        ###########

        #set embeddedIORegexp {(input|output|inout)\s*(wire|reg)?\s*(\[.+:.+\]\s*)?([\w,\s]+)\s*;(\/\/.*)?}
        set embeddedIORegexp {(input|output|inout)\s*(wire|reg)?\s*(\[.+:.+\]\s*)?([\w]+(?:\s*,\s*(?!input|outputinout|)[\w]+)*)\s*;?(\/\/.*)?}
        set embeddedIORegexp {\n\r?\s*(input|output|inout)\s*(wire|reg)?\s*(\[[\d\w]+:[\d\w]+\]\s*)?([\w_]+)}

        set ios2  [regexp -all -inline $embeddedIORegexp $moduleContent]
        #foreach {match dir type size name comment} $ios2
        foreach {match dir type size name} $ios2 {

            ## Get List of names
            set names [split $name ,]

            puts "found io name: $names"

            foreach name $names {
                #puts "IOD dir: $dir -> $name"
                if {$dir=="input"} {

                    set io [${__module} input $name]
                } elseif {$dir=="inout"} {
                    set io [${__module} inout $name]
                } else {
                    set io [${__module} output $name]
                }
            }

        }

        ## Go For Instances
        ##############

        set instancesRegexp {\n\r?\s*((?!if|begin|else\s+)[\w\\_]+)\s*(#\([\w\.\(\)]+\)\s*)?((?!(if|begin|else)\s*)[\w\\\[\]_]+)?\s*\(([^;]+)\);}
        set instances  [regexp -all  -inline $instancesRegexp $moduleContent]
        foreach {match type parameters name connections} $instances {

            if {$name!=""} {
                #puts "CUrrent [current object]"
                set instanceModule [::odfi::h2dl::module $type {}]
                #puts "Instance: $type -> $instanceModule"
                # puts "CUrrent [current object]"
                #
                set instance [$instanceModule createInstance $name]
                ${__module} addChild $instance
            }

        }

        #puts "Module $moduleName -> ${__module}"

        return ${__module}
    }

    ## Reverse file and take first module
    proc moduleFrom {f args} {

        set res [reverse $f]

        set first [$res at 0]
        puts "found module: $first"
        if {[lsearch -exact $args ->]>=0} {
            uplevel [list set [lindex $args [expr [lsearch -exact $args ->]+1 ] ] $first]
        }

        return $first

    }

    proc moduleInstanceFrom {f args} {

        set module [moduleFrom $f]
        if {$module!=""} {
            
            set iname [$module name get]_I
            if {[lsearch -exact $args ->]>=0} {
                set iname [lindex $args [expr [lsearch -exact $args ->]+1 ] ]
                
            }
            
            ## Instance
            set instance [$module createInstance $iname]
            uplevel :addChild $instance
            
            ## add
            uplevel [list set $iname $instance]
        }
        

    }

}

