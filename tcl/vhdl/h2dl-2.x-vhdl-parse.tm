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
package provide odfi::h2dl::vhdl::parse 2.0.0
package require odfi::h2dl::verilog          2.0.0
package require odfi::files 2.0.0

namespace eval odfi::h2dl::vhdl::parse {

    proc reverse file {
   
        set res {}
        ## Content is content or file
        set content $file
        set isFile false
        if {[file exists $content]} {
            set content [odfi::files::readFileContent $content]
            set isFile true
        }
 
        set lineReader [::new ::odfi::files::LineReader #auto $content]

        ## Look for modules
        ##########################
        #puts "content: $content"
        set modules [regexp  -inline -all {entity\s+(\w+)\s+is} $content]

       # puts "Found modules: $modules"
        foreach moduleContent $modules {
            lappend res [reverseModule $moduleContent]
        }

        ## Single Parse remaining lines
        ###########

        return $res
    }

    proc reverseModule moduleContent {

        regexp {module\s+([\w_]+);?} $moduleContent -> moduleName

        #puts "Module $moduleName"

        ## Create Module
        ##################
        set __module [::odfi::h2dl::module $moduleName]
        ${__module} apply {
            
            ## Go For IOs and such
            ###########
            set ioRegexp {(\w+)\s*:\s*(in|out|inout)\s+(\w+)(\(.+\))?;?} 
            set ios  [regexp -all -line -inline $ioRegexp $moduleContent]
            
            #puts "IOS: $ios"
            foreach {match dir type size name comment} $ios {
                
                #puts "IOD dir: $dir -> $name"
                if {$dir=="input"} {
                    set io [:input $name]
                } else {
                    set io [:output $name]
                }
            }
            
            ## Go For Instances
            ##############
            set instancesRegexp {\n\r?\s*((?!if|begin|else\s+)\w+)\s+(#\([\w\.\(\)]+\)\s*)?((?!(if|begin|else)\s+)\w+)\s+\(([^;]+)\);}
            set instances  [regexp -all  -inline $instancesRegexp $moduleContent]
            foreach {match type parameters name connections} $instances {
                
                #puts "CUrrent [current object]"
                set instanceModule [::odfi::h2dl::module $type {}]
                #puts "Instance: $type -> $instanceModule"
               # puts "CUrrent [current object]"
                #
                set instance [$instanceModule createInstance $name]
                :addChild $instance
            }
            
        }
  
        return ${__module}
    }

}

