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
package provide odfi::h2dl::verilog 2.0.0
package require odfi::h2dl          2.0.0
package require odfi::h2dl::ast     2.0.0
package require odfi::h2dl::section 2.0.0

package require odfi::richstream 3.0.0


namespace eval odfi::h2dl::verilog {

    nx::Class create VerilogReduce {

        :public method verilog:reduce {parent results} {
           # puts "Inside common Reduce"

            ## Filter extra results 
            #if {[[:children] size] < [$results size]} {
             #   $results drop [expr [$results size] - [[:children] size]]
            #}
            
            next
        }

        ## Get tabs for current hierarchy level
        :public method verilog:reduceTabs {{incr 0}} {

            return [join [lrepeat [expr [:getTreeDepth]+ $incr] "    "]]

        }
    }

    proc defineReduce {target closure} {

        #puts "Called Define REduce for $target"
        $target public method verilog:reduce {parent results} $closure
        $target mixins add ::odfi::h2dl::verilog::VerilogReduce
        #$target domain-mixins add ::odfi::h2dl::verilog::VerilogReduce -prefix verilog
        
    }
    ## Components
    ######################
    defineReduce ::odfi::h2dl::Module {

        

        if {[:isClass ::odfi::h2dl::Instance]} {

            
            ## Get Master 
            set master [:master get]

            ## Create Type Name from Hierarchy. If black box, don't modify 
            #set typeName [:shade odfi::h2dl::Module formatHierarchyString {$it name get} "_"]_[$master name get]
            set typeName [$master name get]

            #puts "Writing Out Module Instance of [$master name get], with master: $master"

            ## Prepare Stream To write out 
            #####################################
            set out [::new odfi::richstream::RichStream #auto]

            ## Name 
            ##############
            $out <<< "$typeName [:name get]"

            ### IOS
            #############
            set ioString [$results @> filterRemove {[lindex $it 0] isClass odfi::h2dl::IO} @> map {

                set ioRes [lindex $it 1]
                #$out << [[lindex $it 0] verilog:reduceTabs]$regRes
                return [[lindex $it 0] verilog:reduceTabs]$ioRes
            } mkString {"(\n" ",\n" "\n);" } ]
            $out << [:verilog:reduceTabs]${ioString};

            ## EOF IO 
            #$out <<  ";"

            ## Return result 
            #####################
            set str [$out toString]
            odfi::common::deleteObject $out

            $results clear            

            #puts "Result of Module: \n\r$str"
            return $str

            #return "INSTANCE [:name get]"

        } elseif {[:isClass ::odfi::h2dl::Master] && ![:hasAttribute ::odfi::h2dl blackbox]} {

            #puts "Writing Out Module [:name get]"
            puts "Results Content: [$results size]"
            
            ## Type name from hierarchy if enabled
            #set typeName [join [list [:shade odfi::h2dl::Module formatHierarchyString {$it name get} "_"] [:name get]] _]
            set typeName [:name get]

            ## Prepare Stream To write out 
            #####################################
            set out [::new odfi::richstream::RichStream #auto]

            ## Write Definition [:getModelInstanceName] 
            ############################
            $out <<< "module $typeName "

            ### IOS
            set ioString [$results @> filterRemove {[lindex $it 0] isClass odfi::h2dl::IO} @> map {




                set ioRes [lindex $it 1]
                #$out << [[lindex $it 0] verilog:reduceTabs]$regRes
                return $ioRes
            } mkString {"(\n" ",\n" "\n)" } ]
            $out <<< $ioString

            ## EOF IO 
            $out <<  ";"

            ## Content 
            #######################

            #### Parameters
            $out << "[:verilog:reduceTabs 1]// Parametersrs"
            $out << "[:verilog:reduceTabs 1]//---------------"
            $results @> filterRemove {[lindex $it 0] isClass odfi::h2dl::NamedValue} @> mapSort {[lindex $it 0] name get} @> foreach {

                set regRes [lindex $it 1]
                $out << [[lindex $it 0] verilog:reduceTabs]$regRes
            }
            $out << ""
            $out << ""

            #### Signaling
            $out << "[:verilog:reduceTabs 1]// Signaling"
            $out << "[:verilog:reduceTabs 1]//---------------"
            
           
            # Output results from registers 
            #puts "Doing Registers with method chain $results"
            $results @> filterRemove {[lindex $it 0] isClass odfi::h2dl::Signal} @> mapSort {[lindex $it 0] name get} @> foreach {

                set regRes [lindex $it 1]
                $out << [[lindex $it 0] verilog:reduceTabs]$regRes
            }

            $out << ""
            $out << ""

            #### Assignments
            $out << "[:verilog:reduceTabs 1]// Assigments"
            $out << "[:verilog:reduceTabs 1]//---------------"

            $results @> filterRemove {[lindex $it 0] isClass odfi::h2dl::Assign} @> foreach {

                set regRes [lindex $it 1]
                $out << [[lindex $it 0] verilog:reduceTabs]$regRes
            }


            $out << ""
            $out << ""

            #### Imported Sections 
            $results @> filterRemove {[lindex $it 0] isClass odfi::h2dl::section::TextContentSection} @> foreach {
                #puts "Found Logic elements"
                $out << [[lindex $it 0] verilog:reduceTabs][lindex $it 1]
            }
            $out << ""
            $out << ""

            #### Logic
            $out << "[:verilog:reduceTabs 1]// Logic"
            $out << "[:verilog:reduceTabs 1]//---------------"

            $results @> filterRemove {[lindex $it 0] isClass odfi::h2dl::Logic} @> foreach {
                #puts "Found Logic elements"
                $out << [[lindex $it 0] verilog:reduceTabs][lindex $it 1]
            }

            #### Instances
            $out << "[:verilog:reduceTabs 1]// Instances"
            $out << "[:verilog:reduceTabs 1]//---------------"
            $results @> filterRemove {[lindex $it 0] isClass odfi::h2dl::Instance} @> foreach {

                set res [lindex $it 1]
                $out << [[lindex $it 0] verilog:reduceTabs]$res
            }

            $out << ""
            $out << ""

            

            $out << ""
            $out << ""
            ## End Module 
            ######################
            $out <<  "endmodule"

            ## Return result 
            #####################
            $results clear              
            set str [$out toString]
            odfi::common::deleteObject $out

            #puts "Result of Module: \n\r$str"
            return $str

        }
        

    }

    defineReduce ::odfi::h2dl::Register {

        #puts "Writing Out Register [:name get]"
        #puts "Current parent is  [$parent info class]"
        if {[$parent isClass ::odfi::h2dl::Structural]} {
            set size [expr [:width get] > 1 ? "{ \[[expr [:width get]-1]:0\]}" : "{}"]
            return "reg $size [:name get];"
        } else {
            return "[:name get]"
        }
      
        

        #return "[:verilog:reduceTabs]register [:name get]"
    }

    defineReduce ::odfi::h2dl::Wire {
        
   
        
        if {[:isClass ::odfi::h2dl::IO]} {
            return [next]
            
        }
        
        set res ""
        #puts "Writing Out Wire [:name get]"
        #puts "Current parent is  [$parent info class]"
        if {[$parent isClass ::odfi::h2dl::ast::ASTNode] || [$parent isClass ::odfi::h2dl::Assign]} {
            set res "[:name get]"
        } else {
            set size [expr [:width get] > 1 ? "{ \[[expr [:width get]-1]:0\]}" : "{}"]
            #set subResults [$results @> map { return [[lindex $it 0] verilog:reduceTabs -1][lindex $it 1]} @> mkString {"\n" "\n" "\n" } ]
            
            set type wire
            if {[$parent hasAttribute ::odfi::h2dl testbench]} {
                set type logic
            }
            set res "$type $size [:name get]; // AAGAGA"
        }
        
        
        ## If there is a result for an assign, pull it up
        set assignRes [$results @> findOption {[lindex $it 0] isClass ::odfi::h2dl::Assign}]
        if {[$assignRes isDefined]} {
            #puts "FOUND ASSIGN FOR WIRE"
            #set res [::odfi::flist::MutableList new]
            
            set res [list [list [current object] $res] [$assignRes get]]
           # puts "now res ist: $res"
        }
        
        #puts "return res: $res"
        return $res 
        

        #return "[:verilog:reduceTabs]register [:name get]"
    }

    defineReduce ::odfi::h2dl::Connection {
    
        return [$results @> map {lindex $it 1} @> mkString]
    }

    defineReduce ::odfi::h2dl::IO {
    
        #puts "Writing Out IO [:name get] [$parent info class]"
        
        if {[$parent isClass ::odfi::h2dl::Instance]} {

            ## Connection 
            set connectionString  ".[:name get]()"

            
            ## Connection to/from
            ############
            set connection [:shade odfi::h2dl::Connection child 0]
            set connectionTo   true
            set connectionFrom false
            if {$connection==""} {
                set connection [:shade odfi::h2dl::Connection parent]
                if {$connection!=""} {
                    set connectionTo   false
                    set connectionFrom true
                }
                
            }
            
            #puts "Writing Out Connection IO [:name get] [$parent info class] ($parent) <- $connection"
            
    
            if {$connection==""} {
                return ".[:name get]()"
            }
            
            ## Connection Name can be a string or an object
            ########
            set connectionName [$connection name get]
            set connectionSignalName ""
            set connectionString ".[:name get]()"
            
            ## If not an object, use string
            if {[::odfi::common::isObject $connectionName]} {
            
                ## If connection is a signal, a bit or a range
                if {[$connectionName isClass ::odfi::h2dl::Bit]} {
                    
                    set connectionSignalName  [[$connectionName parent] name get]
                    set connectionSignalSize  [[$connectionName parent] width get]
                    set connectionString     ".[:name get]([[$connectionName parent] name get]\[[$connectionName index get]\])"
                    
                } elseif {[$connectionName isClass ::odfi::h2dl::Signal]} {
                    
                    set connectionSignalName $connectionName
                    set connectionSignalSize  [$connectionName width get]
                    set connectionString     ".[:name get]([$connectionName name get])"  
                              
                } elseif {[$connectionName isClass ::odfi::h2dl::ast::ASTRangeSelect]} {
                
                    set rangeTarget [$connectionName firstChild]
                    set range       [$connectionName lastChild]
                    set first       [[$range firstChild] constant get]
                    set last        [[$range lastChild]  constant get]
                    
                    # [$results @> map {lindex $it 1} @> mkString]
                    set connectionString  ".[:name get]([$rangeTarget name get]\[${last}:${first}\])"  
                    set connectionSignalName  [$rangeTarget name get]
                    set connectionSignalSize  [$rangeTarget  width get]                            
                }
            
            } else {
            
                set connectionSignalName $connectionName
                set connectionSignalSize 1
                set connectionString ".[:name get]($connectionName)"
                if {$connectionName==[:name get]} {
                    set connectionSignalSize [:width get]
                }
                
            }
            
            ## Make sure the parent module has a signal for the connection
            if {$connectionSignalName!=""} {
                #set module [[:parent] getParentModule]
               # set signal [$module shade ::odfi::h2dl::Signal findChildByProperty name $connectionSignalName]
                #if {$signal==""} {
                     #puts "Adding Signal  $connectionSignalName for connection in module [$module name get]"
                     #$module wire $connectionSignalName {
                     #   :width set  $connectionSignalSize
                    #}
                #}
            }

            ## Return connection string
            return $connectionString
            
            
            
        } elseif {[$parent isClass ::odfi::h2dl::Module]} {

           set res ""

            ## Description
            set desc [:description get]
            if {$desc!="" && $desc!="{}"} {
                set  desc "    // [:description get]\n"
            } else {
                set desc ""
            }
            
            ## Size 
            set size ""
            if {[:width get]>1} {
                set size " \[[expr [:width get]-1]:0\]"
            }

            ## Definition
            if {[:isInput]} {
                set res "$desc    input [:type get]$size [:name get]"
            } elseif {[:isOutput]} {

                ## Make sure type is reg if an assignment is made
                ## Assignment means the node has a Non blocking parent and is on the left
                set type [:type get]
                
                if {[:shade ::odfi::h2dl::ast::ASTNonBlockingAssign isLeftOfOneParent]} {
                    set type "reg"
                }
                #if {[[:shade ::odfi::h2dl::ast::ASTNonBlockingAssign parents] size]!=0} {
                #    set type "reg"
                #}

                set res "$desc    output ${type}$size [:name get]"

            } elseif {[:isInout]} {
                set res "$desc    inout [:type get]$size [:name get]"
            }
            
            
            ## If there is a result for an assign, pull it up
            set assignRes [$results @> findOption {[lindex $it 0] isClass ::odfi::h2dl::Assign}]
            if {[$assignRes isDefined]} {
                #puts "FOUND ASSIGN FOR IO"
                #set res [::odfi::flist::MutableList new]
                
                set res [list [list [current object] $res] [$assignRes get]]
                #puts "now res ist: $res"
            }
            
            return $res
            
        } else {
            return "[:name get]"
        }

        

    }

    defineReduce ::odfi::h2dl::NamedValue {

        return "localparam [:name get] = [:value get];"
    }

    ## Cases 
    ###################

    defineReduce ::odfi::h2dl::Case {

        set out [::new odfi::richstream::RichStream #auto]

        ## prepare signals
        puts "Case signals: "
        [:signals get] foreach {
            puts "-> $it // [$it info class]"
        }
        set signalNames [[[:signals get] map {$it name get}] mkString ,]

        ## Begin
        ##############
        $results @> filterRemove { [lindex $it 0] isClass ::odfi::h2dl::Comment} @> foreach {
            $out << [[lindex $it 0] verilog:reduceTabs -1][lindex $it 1]
        }
        $out << "[:verilog:reduceTabs]casex ({$signalNames})"

        ## Cases 
        ##############
        $results foreach {
            if {[[lindex $it 0] isClass odfi::h2dl::On]} {
                $out << "[lindex $it 1]"
            }
        }


        ## End 
        ################
        $out << "[:verilog:reduceTabs]endcase"
        set str [$out toString]
        odfi::common::deleteObject $out

        return $str
    }

    defineReduce ::odfi::h2dl::On {
        #puts "Results for on, number of children: [[:children] size] , results size: [$results size]"

        #puts "On Results, [[$results at 0]"
        
        #puts "Inside on, showing Children"
        #:noShade eachChild {
        #    puts "----> [$it info class]"
        #}
        return "[:verilog:reduceTabs][:value get] : begin

[$results @> filter {[lindex $it 0] isClass odfi::h2dl::ast::ASTNonBlockingAssign} @> map { return [[lindex $it 0] verilog:reduceTabs][lindex $it 1]} @> mkString {\n}]
 
[:verilog:reduceTabs]end"
    }

    ## Assignments
    ##################
    defineReduce ::odfi::h2dl::ast::ASTBlockingAssign {
        return "[lindex [$results at 0] 1] = [lindex [$results at 1] 1];"
    }

    defineReduce ::odfi::h2dl::ast::ASTNonBlockingAssign {

        #puts "NB results $results [[lindex [$results at 1] 0] info class]"
        #return "[$results @> map { return [lindex $it 1]} @> mkString {-}]"
        
        ## Right part may be a concat without the
        puts "NB with right:  [$results at 1]"
        set right "[lindex [$results at 1] 1]"
        set right [string map {( \{ ) \}} $right]
        #if {[string first "," $right]!=-1 && [string first "\}" $right]==-1} {
        #    set right "{$right}"
        #}
        
        return "[lindex [$results at 0] 1] <= $right;"
    }

    defineReduce ::odfi::h2dl::Assign {

        #puts "NB results $results [[lindex $results 0] info class]"
        #return "[$results @> map { return [lindex $it 1]} @> mkString {-}]"
        #puts "******* ASSIGN on  [[:shade odfi::h2dl::Signal parent] name get] [current object] [$results size]"
        #if {[$results size]==1} {
        #    puts "Output: [$results at 0] -> [$results @> map { return [lindex $it 1]} @> mkString ]"
        #}
        return "assign [[:shade odfi::h2dl::Signal parent] name get] = [$results @> map { return [lindex $it 1]} @> mkString ];"
    }

    ## AST NOdes 
    ############################

    defineReduce ::odfi::h2dl::ast::ASTCompare {
        
        ##puts "Compare out with results: [$results size]"

        set left [lindex [$results at 0] 1]
        set right [expr {[$results size]>1} ? {[lindex [$results at 1] 1]} : "{}"]

        return "$left == $right"
    }

     defineReduce ::odfi::h2dl::ast::ASTNegate {
        #puts "CONSTANT OUT"

        set left [lindex [$results at 0] 1]
        #set right [expr {[$results size]>1} ? {[lindex [$results at 1] 1]} : "{}"]

        return "~ $left"
    }

    defineReduce ::odfi::h2dl::ast::ASTConstant {
        #puts "CONSTANT OUT"
        return "[:constant get]"
    }
    
   

    defineReduce ::odfi::h2dl::ast::ASTRangeSelect {
       
        set rangeDef [:lastChild]
        
        #puts "Range Out for [[:firstChild] name get] -> [$rangeDef info class] , parent is: [$parent info class]"
        
        if {[$rangeDef isClass ::odfi::h2dl::ast::ASTConstant]} {
            return "[[:firstChild] name get]\[[$rangeDef constant get]\]"
        } elseif {[$rangeDef isClass ::odfi::h2dl::ast::ASTRange]} {
           # puts "-> Range: [$rangeDef firstChild] -- [$rangeDef lastChild]"
            return "[[:firstChild] name get]\[[[$rangeDef firstChild] constant get]:[[$rangeDef lastChild] constant get]\]"
        }
        
    }

    defineReduce ::odfi::h2dl::ast::ASTConcat {
    
        puts "ASTConcat OUT [$results size]"
        set allRes [lindex [$results at 0] 1]
        
        set finalRes [$results @> map {
            return [lindex $it 1]
        } @> mkString [list "(" "," ")"]]
        return $finalRes
        
        #set left [lindex [$results at 0] 1]
        #set right [expr {[$results size]>1} ? {[lindex [$results at 1] 1]} : "{}"]
        #return "{$left , $right}"
        
        #puts "Concact out"

        
    }

    defineReduce ::odfi::h2dl::ast::ASTShiftLeft {

         #puts "SL out"

        set left [lindex [$results at 0] 1]
        set leftNode [lindex [$results at 0] 0]
        set right [expr {[$results size]>1} ? {[lindex [$results at 1] 1]} : "{}"]

        return " $left\[[expr [$leftNode width get] -2]:[expr $right -1]\]  "
        
    }

    defineReduce ::odfi::h2dl::ast::ASTShiftRight {

         #puts "SL out"

        set left [lindex [$results at 0] 1]
        set leftNode [lindex [$results at 0] 0]
        set right [expr {[$results size]>1} ? {[lindex [$results at 1] 1]} : "{}"]

        return " { $left\[0\] ,$left\[[expr [$leftNode width get] -1]:[expr $right ]\]  } "
        
    }

    defineReduce ::odfi::h2dl::ast::ASTAdd {

         #puts "SL out"

        set left [lindex [$results at 0] 1]
        set leftNode [lindex [$results at 0] 0]
        set right [expr {[$results size]>1} ? {[lindex [$results at 1] 1]} : "{}"]

        return "$left + $right"
        
    }
    
    defineReduce ::odfi::h2dl::ast::ASTGreaterThan {
   
            #puts "SL out"
   
       set left [lindex [$results at 0] 1]
       set leftNode [lindex [$results at 0] 0]
       set right [expr {[$results size]>1} ? {[lindex [$results at 1] 1]} : "{}"]
   
       return "$left >= $right"
       
    }

    defineReduce ::odfi::h2dl::ast::ASTAnd {

         #puts "SL out"

        set left [lindex [$results at 0] 1]
        set leftNode [lindex [$results at 0] 0]
        set right [expr {[$results size]>1} ? {[lindex [$results at 1] 1]} : "{}"]

        return "$left && $right"
        
    }

    defineReduce ::odfi::h2dl::ast::ASTIf {

        set left [lindex [$results at 0] 1]
        set leftNode [lindex [$results at 0] 0]
        set right [expr {[$results size]>1} ? {[lindex [$results at 1] 1]} : "{}"]

        return "$left ? $right"

    }

    defineReduce ::odfi::h2dl::ast::ASTElse {
        set left [lindex [$results at 0] 1]
        set leftNode [lindex [$results at 0] 0]
        set right [expr {[$results size]>1} ? {[lindex [$results at 1] 1]} : "{}"]

        return "$left : $right"
    }

    ## Logic 
    ###################
    defineReduce ::odfi::h2dl::If {

        #puts "Reducing if with ccount: [[:children] size] // [$results size]"

        set left [lindex [$results at 0] 1]
        $results pop 
        return "if ($left) begin
[$results @> map { return [[lindex $it 0] verilog:reduceTabs][lindex $it 1]} @> mkString { \n \n \n}]
[:verilog:reduceTabs]end"
    }
    defineReduce ::odfi::h2dl::Elseif {

        #puts "Reducing if with ccount: [[:children] size] // [$results size]"

        set left [lindex [$results at 0] 1]
        $results pop 
        return "else if ($left) begin
[$results @> map { return [[lindex $it 0] verilog:reduceTabs][lindex $it 1]} @> mkString { \n \n \n}]
[:verilog:reduceTabs]end"
    }

    defineReduce ::odfi::h2dl::Else {

        return "else begin
[$results @> map { return [[lindex $it 0] verilog:reduceTabs][lindex $it 1]} @> mkString { \n \n \n}]
[:verilog:reduceTabs]end"
    }

    ## Sections and Blocks 
    ###############################
    defineReduce ::odfi::h2dl::Stage {

        set out [::new odfi::richstream::RichStream #auto]

        ## Setup 
        ##############
        $out << "[:verilog:reduceTabs]// Stage: [:name get]"
        $out << "[:verilog:reduceTabs]//------------------------"

        ## Sync block
        #################

        set edge [expr {[:isClass odfi::h2dl::Negedge]} ? "{negedge}" : "{posedge}" ]

        ## Find reset 
        set resetStr ""
        set reset [:shade ::odfi::h2dl::Reset firstChild]
        puts "********* RESET: $reset"
        if {$reset!=""} {
            set r [$reset signal get]
            if {[string match "*_n" [$r name get]]} {
                set resetStr " or negedge [$r name get]"
            } else {
                set resetStr " or posedge [$r name get]"
            }
        }
        #set reset [:shade odfi::h2dl::Reset firstChild]
        #set resetEdge "" 

        $out << "[:verilog:reduceTabs]always @($edge [[:signal get] name get]$resetStr) begin"

        ##### Reset 

        ##### Body
        $out << [$results @> map { return [[lindex $it 0] verilog:reduceTabs][lindex $it 1]} @> mkString { \n \n \n}]


        ## Return 
        #############
        $out << "[:verilog:reduceTabs]end"

        set str [$out toString]
        odfi::common::deleteObject $out

        return $str
    }

    defineReduce ::odfi::h2dl::Posedge {

        set out [::new odfi::richstream::RichStream #auto]

        ## Setup 
        ##############
        $out << ""
        $out << "[:verilog:reduceTabs]// Posedge"
        $out << "[:verilog:reduceTabs]//------------------------"

        ## Sync block
        #################

        set edge [expr {[:isClass odfi::h2dl::Negedge]} ? "{negedge}" : "{posedge}" ]

        ## Find reset 
        set resetStr ""
        set reset [:shade ::odfi::h2dl::Reset firstChild]
        #puts "********* RESET: $reset"
        if {$reset!=""} {
            set r [$reset signal get]
            if {[$r hasAttribute ::odfi::h2dl::reset async] && [string match "*_n" [$r name get]]} {
                set resetStr " or negedge [$r name get]"
            } elseif {[$r hasAttribute ::odfi::h2dl::reset async]} {
                set resetStr " or posedge [$r name get]"
            }
        }
        #set reset [:shade odfi::h2dl::Reset firstChild]
        #set resetEdge "" 

        $out << "[:verilog:reduceTabs]always @($edge [[:signal get] name get]$resetStr) begin"

        ##### Reset 

        ##### Body
        $out << [$results @> map { return [[lindex $it 0] verilog:reduceTabs][lindex $it 1]} @> mkString { \n \n \n}]


        ## Return 
        #############
        $out << "[:verilog:reduceTabs]end"
        set str [$out toString]
        odfi::common::deleteObject $out

        return $str

    }

    ## FSM 
    #################
    defineReduce ::odfi::h2dl::fsm::Goto {
        if {[$parent isClass ::odfi::h2dl::ast::ASTNode]} {
            return [:to get]
        } 
       
    }

    defineReduce ::odfi::h2dl::fsm::State {
        #if {[$parent isClass ::odfi::h2dl::ast::ASTNode]} {
            return [:name get]
        #} 
       
    }

    defineReduce ::odfi::h2dl::fsm::Fsm {

        ## Create Values
        ## Gather All States 
        #############
        #set states [odfi::flist::MutableList new]
        #:shade ::odfi::h2dl::fsm::State walkDepthFirstPostorder {
        #    $states += $node
        #    return true
        #}
        #set vectorSize [expr int(ceil(log([$states size])/log(2)))]
       
        ## Produce String 
        #######################
        #set i -1
        #$states @> map {
        #    incr i
        #    return "localparam [$it name get] = ${vectorSize}'d$i;\n"
        #} @> mkString

    }

    ## Others 
    #####################
    defineReduce ::odfi::h2dl::Comment {
        #puts "CONSTANT OUT"
        return "//[:value get]"
    }

    ## Generic Verilog Gen 
    #################################
    nx::Class create VerilogGen {

       

        :public method generate {{outputFolder "."}} {



            ## Check output folder 
            ##############
            
            ## If Relative, set to caller file by default, this is more intuitive than interpreter start location
            if {[odfi::files::isRelative $outputFolder]} {
            
                ## Get Caller Location
                lassign [uplevel odfi::common::findFileLocation] callerFile callerLine
                set outputFolder [file dirname $callerFile]/$outputFolder       
            }
            
            file mkdir $outputFolder
           
            
            ## Read Timestamp
            ## Timesteamp will be overwritten only if successful
            #######################
            set existingTimeStamp -1
            if {[file exists $outputFolder/verilogen.ts]} {
                set existingTimeStamp [expr [odfi::files::readFileContent $outputFolder/verilogen.ts]]
            }
            

            ## Start Producing
            #######################
            odfi::log::info "Start Producing verilog to ${outputFolder} on object [:info class] ->  ${:name}"

            ## List of created files 
            set filesList {}


            ## Prepare 
            ###################

            ## Module Prepares 
            if {[:isClass ::odfi::h2dl::Module]} {

                set module [current object]

                ## Prepare F File 
                ###############
                set fFileStream [::new odfi::richstream::RichStream #auto]

                $fFileStream streamToFile $outputFolder/[$module name get].f

                ## Find All the NamedValue for local params, and put them in the top module 
                #:walkDepthFirstPreorder {
                #    {namedValue parent} => 

                 #       if {[$namedValue isClass odfi::h2dl::NamedValue]} {
                 #           $namedValue detachFrom $parent 
                 #           $namedValue setFirstParent $module 
                  #          return false 
                  #      } elseif {[$namedValue isClass odfi::h2dl::Module]} {
                  #          return false
                  #      }
                        
                
                  #  return true
                #}

                ## Find All Assigns on IOS and add them to top module 
                #:shade odfi::h2dl::IO eachChild {

                    #$it shade odfi::h2dl::Assign eachChild {
                       # {assign i} => 
                        #    $assign detach
                        #    $module addChild $assign
                   # }

            
               # }


            }

            set res [:shade ::odfi::h2dl::verilog::VerilogReduce reducePlus {

                


                ## Produce Results 
                #########################
                

                ## Write to file if Module Master, and remove from results to avoid duplications
                if {[$node isClass odfi::h2dl::Module] && ![$node isClass odfi::h2dl::Instance] && ![$node hasAttribute ::odfi::h2dl blackbox]} {

                   puts "visiting module $node [$node name get] , with parent: $parent -> [$results size]"
                   if {$parent!=""} {
                    #puts "--> parent: [$parent name get] ([$parent info class])"
                   }
                   
                   
                    
                    ## If module was generated somewhere else, use that somewhere
                    ########
                    if {[$node hasAttribute ::odfi::h2dl::verilog generatedFile]} {
                        
                        #$fFileStream << [$node getAttribute ::odfi::h2dl::verilog generatedFile]
                        ::set __r ""
                        
                    } else {
                    
                        puts "--> generate"
                        ## Write File 
                        ################
                        
                        ## First Check existing file and its timestamp
                        set targetFile ${outputFolder}/[$node name get].v
                       
                        if {$existingTimeStamp>0 && [file exists $targetFile]} {
                            
                            set lastModified [file mtime $targetFile ]
                         
                            ## If modified after last generation, make backup and warning
                            if {$lastModified>$existingTimeStamp} {
                                odfi::log::warn "File $targetFile was generated and modified after generation, a backup has been saved"
                                file copy -force $targetFile ${targetFile}.genbackup
                            }
                        }
                        
                        ## Produce
                        puts "Calling regduce [$results size]"
                        ::set __r [$node verilog:reduce $parent $results]
                        
                        #puts "Module was created from file : [$node file get]"
                        #puts "Module -> To File ${outputFolder}/[$node name get].v" 
                        
                        ##puts "Module Res: $__r"
                        
                        ## Normal write
                        odfi::files::writeToFile ${outputFolder}/[$node name get].v $__r 
                        $node attribute ::odfi::h2dl::verilog generatedFile ${outputFolder}/[$node name get].v
    
                        ## Add to f
                        $fFileStream << [file normalize ${outputFolder}/[$node name get].v]
    
                        ## Add Companion sources 
                        ## - Copy to output 
                        ## - Add to .f for verilog/vhdl files
                        if {[$node hasAttribute ::odfi::verilog companions]} {
                            foreach companion [$node getAttribute ::odfi::verilog companions] {
                            
                                if {![file exists $companion]} {
                                    error "Cannot Copy Companion source file $companion of [$node name get] because the file does not exist"
                                } else {
                                
                                    ## Before copying check timestamps
                                    ## First Check existing file and its timestamp
                                    set targetFile ${outputFolder}/[file tail $companion]
                                    set allowCopy true
                                    
                                    if {$existingTimeStamp>0 && [file exists $targetFile]} {
                                        
                                        set lastModified [file mtime $targetFile ]
                                     
                                        ## If modified after last generation, make backup and warning
                                        if {$lastModified>$existingTimeStamp} {
                                            odfi::log::warn "File $targetFile was copied as companion and modified after copy, nothing will be done for this file but a copy was saved"
                                            file copy -force $targetFile ${targetFile}.genbackup
                                            set allowCopy false
                                        }
                                    }
                                    
                                    ## Normal copy then
                                    if {$allowCopy} {
                                        file copy -force $companion $targetFile
                                    }
                                    
    
                                    ## Add to .f if necessary
                                    if {[string match "*.v" $companion] || [string match "*.vhdl" $companion] || [string match "*.vhd" $companion] || [string match "*.sv" $companion]} {
                                        $fFileStream << [file normalize ${outputFolder}/[file tail $companion]]
                                    }
                                }
                            }
                        }
    
                        ::set __r ""
                    
                    }
                    
                
                ## EOF Module    
                } elseif {[$node isClass odfi::h2dl::Module] && [$node isClass odfi::h2dl::Instance]} {
                
                    $fFileStream << [[$node master get] getAttribute ::odfi::h2dl::verilog generatedFile]
                    
                    ## Produce results for other cases
                    ::set __r [$node verilog:reduce $parent $results]
                    
                ## EOF Instance
                } else {
                    
                    ## Produce results for other cases
                    ::set __r [$node verilog:reduce $parent $results]
                }
                
                return $__r
               

            } ]
            ## EOF Res

            ## Write F File out 
            ##########################
            
            $fFileStream close
            #odfi::files::writeToFile ${outputFolder}/netlist.f [join $filesList \n]

            ## Save Timestamp
            #######################
            set currentTimestamp [clock seconds]
            ::odfi::files::writeToFile $outputFolder/verilogen.ts $currentTimestamp
           


            return ""

            ## Perform necessary transformations
            ############################

            :walkDepthFirstPreorder {
                if {[$node isClass odfi::h2dl::Inout] && [$node shade odfi::h2dl::Highz firstChild]!=""} {

                    puts "VErilog found an InOut to resolve"
                    set module [$node parent]
                    set highz [$node shade odfi::h2dl::Highz firstChild]
                    ## Add A register to the output
                    $module register [$node name get]_out {
                        :width set [$node width get]
                    }

                    ## Find Usage of Inout Signal in assignments and replace with new register

                    ## Set an Assign expression
                    $node = [$highz expr get] ? Z : [set [$node name get]_out]
                }
            }

            

        }

        ## Add Content add the place in current module 
        ###############################

        :public method importContent content {

            ## Get content from file if from file 
            set name "Verilog Imported Content "
            #if {[file exists $content]} {
            #    set name "$name from $content"
            #    set content [odfi::files::readFileContent $content]
            #}

            ##puts "IMporting ot [:info class] [:info lookup methods]-> [[:info class] info mixins], "
            
            :section:textContentSection $name $content

        }

        package require odfi::dev::hw::rtl 1.0.0
        :public method merge inFile {

            if {[file exists $inFile]} {
                set fileContent [odfi::files::readFileContent $inFile]
            } else {
                error "Cannot merge non existent file: $inFile"
            }

            ## Remove Header Definition and take content as imported 
            ##############
            #set res [regexp {.*module.*\);(.*)endmodule} $content -> realContent ]
            
            set remaining [string range $fileContent [expr [string first ");" $fileContent]+2] end]

            ## Remove last "endmodule"
            set remaining [string map {endmodule ""} $remaining]

            #puts "Regexp match: $res"
            set importedContent [:importContent $remaining]

            ## Parse IO 
            ###################
            set ios [odfi::dev::hw::rtl::extractIOFromFile $inFile]
            foreach io $ios {
                #puts "Found io: [$io getName]"
                
                ## Create 
                if {[$io isInput]} {
                    set newIO [uplevel :input [$io getName]]
                } elseif {[$io isInputOutput]} {
                    set newIO [uplevel :inout [$io getName]]
                } else {
                    set newIO [uplevel :output [$io getName]]
                }

                ## Set Size 
                $newIO width set [$io getSize]
            }


            $importedContent
        }

        defineReduce ::odfi::h2dl::section::TextContentSection {

            if {[file exists [:content get]]} {
                set r "
// Section [:name get] Imported from file [:content get]
`include \"[file normalize [:content get]]\"
"
            } else {
                            set r "
// Section [:name get]
[string map {\\\$ \$} [:content get] ]
"
            }

            return $r
        }

         defineReduce ::odfi::h2dl::section::LogicSection {
         
            set out [::new odfi::richstream::RichStream #auto]
            $out << "// Section [:name get]"
            $out << ""

            
            $results @> foreach {
                #puts "Found Logic elements"
                $out << [[lindex $it 0] verilog:reduceTabs][lindex $it 1]
            }

            set str [$out toString]
            odfi::common::deleteObject $out
            $results clear            
            return $str
        }

    }
    ::odfi::h2dl::Module domain-mixins add ::odfi::h2dl::verilog::VerilogGen -prefix verilog


}

