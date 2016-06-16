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

namespace eval odfi::h2dl::verilog::parse {

    proc reverse {file args} {
   
   
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
        set modules [regexp  -inline -all {module\s+(?:[\w_]+);?(?:(?!endmodule.+).)+endmodule} $content]

        #puts "Found modules: $modules"
        
        foreach moduleContent $modules {
            
                lappend res [reverseModule $moduleContent]
            
           
        }

        ## Single Parse remaining lines
        ###########

        return $res
    }

    proc reverseModule {moduleContent args} {


        
        
        #puts "REverse: $moduleContent"
        regexp {module\s+([\w_]+);?} $moduleContent -> moduleName

        #puts "Module $moduleName"
        
        ## Create Module
        ##################
        set __module [::odfi::h2dl::module $moduleName]
        ## Go For IOs and such
        ###########
                    
        #set embeddedIORegexp {(input|output|inout)\s*(wire|reg)?\s*(\[.+:.+\]\s*)?([\w,\s]+)\s*;(\/\/.*)?}
        set embeddedIORegexp {(input|output|inout)\s*(wire|reg)?\s*(\[.+:.+\]\s*)?([\w]+(?:\s*,\s*(?!input)[\w]+)*)\s*;?(\/\/.*)?}
        set ios2  [regexp -all -inline $embeddedIORegexp $moduleContent]
        foreach {match dir type size name comment} $ios2 {
           
           ## Get List of names
           set names [split $name ,]
                                    
            
            foreach name $names {
                #puts "IOD dir: $dir -> $name"
                if {$dir=="input"} {
                
                    set io [${__module} input $name]
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

}

