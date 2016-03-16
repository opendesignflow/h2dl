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
            if {[[:children] size] < [$results size]} {
                $results drop [expr [$results size] - [[:children] size]]
            }
            
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

            puts "Writing Out Module Instance, with master: $master"

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

            puts "Writing Out Module [:name get]"
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

            #### Instances
            $out << "[:verilog:reduceTabs 1]// Instances"
            $out << "[:verilog:reduceTabs 1]//---------------"
            $results @> filterRemove {[lindex $it 0] isClass odfi::h2dl::Instance} @> foreach {

                set res [lindex $it 1]
                $out << [[lindex $it 0] verilog:reduceTabs]$res
            }

            $out << ""
            $out << ""

            #### Logic
            $out << "[:verilog:reduceTabs 1]// Logic"
            $out << "[:verilog:reduceTabs 1]//---------------"

            $results @> foreach {
                #puts "Found Logic elements"
                $out << [[lindex $it 0] verilog:reduceTabs][lindex $it 1]
            }

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
        if {![$parent isClass ::odfi::h2dl::Structural]} {
            return "[:name get]"
        } else {
            set size [expr [:width get] > 1 ? "{ \[[expr [:width get]-1]:0\]}" : "{}"]
            return "reg $size [:name get];"
        }
        

        #return "[:verilog:reduceTabs]register [:name get]"
    }

    defineReduce ::odfi::h2dl::Wire {
        
        if {[:isClass ::odfi::h2dl::IO]} {
            return [next]
            
        }
        
        #puts "Writing Out Wire [:name get]"
        #puts "Current parent is  [$parent info class]"
        if {[$parent isClass ::odfi::h2dl::ast::ASTNode]} {
            return "[:name get]"
        } else {
            set size [expr [:width get] > 1 ? "{ \[[expr [:width get]-1]:0\]}" : "{}"]
            set subResults [$results @> map { return [[lindex $it 0] verilog:reduceTabs -1][lindex $it 1]} @> mkString {"\n" "\n" "\n" } ]
            return "wire $size [:name get];$subResults"
        }
        

        #return "[:verilog:reduceTabs]register [:name get]"
    }

    defineReduce ::odfi::h2dl::IO {
    
        #puts "Writing Out IO [:name get]"
        if {[$parent isClass ::odfi::h2dl::ast::ASTNode]} {
            return "[:name get]"
        } elseif {[$parent isClass ::odfi::h2dl::Instance]} {

            ## Connection 
            set connectionString  ".[:name get]()"

            ## Child Connection 
            set cconnection [:shade odfi::h2dl::Connection child 0]
            if {$cconnection!=""} {
                set connectionString  ".[:name get]([[$cconnection firstChild] name get])"
            } else {
                 ## Parent Connection ?
                set pconnection [:shade odfi::h2dl::Connection parent]
                if {$pconnection!=""} {
                    set connectionString  ".[:name get]([[$pconnection parent] name get])"
                }
            }

           

            #puts "Foudn Connections on IO instance: $pconnection  $cconnection "

            return $connectionString 
        } else {

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
            if {[:isClass ::odfi::h2dl::Input]} {
                return "$desc    input [:type get]$size [:name get]"
            } elseif {[:isClass ::odfi::h2dl::Output]} {

                ## Make sure type is reg if an assignment is made 
                set type [:type get]
                if {[[:shade ::odfi::h2dl::ast::ASTNonBlockingAssign parents] size]!=0} {
                    set type "reg"
                }

                return "$desc    output ${type}$size [:name get]"

            } elseif {[:isClass ::odfi::h2dl::Inout]} {
                return "$desc    inout [:type get]$size [:name get]"
            }
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
        return "[lindex [$results at 0] 1] <= [lindex [$results at 1] 1];"
    }

    defineReduce ::odfi::h2dl::Assign {

        #puts "NB results $results [[lindex $results 0] info class]"
        #return "[$results @> map { return [lindex $it 1]} @> mkString {-}]"
        #puts "******* ASSIGN [$results size]"
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
        #puts "CONSTANT OUT"
        set rangeDef [:lastChild]
        if {[$rangeDef isClass ::odfi::h2dl::ast::ASTConstant]} {
            return "[[:firstChild] name get]\[[$rangeDef constant get]\]"
        } elseif {[$rangeDef isClass ::odfi::h2dl::ast::ASTRange]} {
            return "[[:firstChild] name get]\[[[$rangeDef firstChild] constant get]:[[$rangeDef lastChild] constant get]\]"
        }
        
    }

    defineReduce ::odfi::h2dl::ast::ASTConcat {
        #puts "CONSTANT OUT"
        set left [lindex [$results at 0] 1]
        set right [expr {[$results size]>1} ? {[lindex [$results at 1] 1]} : "{}"]

        #puts "Concact out"

        return "{$left , $right}"
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

       

        :public method produce {{outputFolder "."}} {


            ## Check output folder 
            ##############
            file mkdir $outputFolder
           
            

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
                :walkDepthFirstPreorder {
                    {namedValue parent} => 

                        if {[$namedValue isClass odfi::h2dl::NamedValue]} {
                            $namedValue detachFrom $parent 
                            $namedValue setFirstParent $module 
                            return false 
                        } elseif {[$namedValue isClass odfi::h2dl::Module]} {
                            return false
                        }
                        
                
                    return true
                }

                ## Find All Assigns on IOS and add them to top module 
                :shade odfi::h2dl::IO eachChild {

                    $it shade odfi::h2dl::Assign eachChild {
                        $module addChild $it
                    }

            
                }


            }

            set res [:shade ::odfi::h2dl::verilog::VerilogReduce reducePlus {

                


                ## Produce Results 
                #########################
                ::set __r [$node verilog:reduce $parent $results]

                ## Write to file if Module Master, and remove from results to avoid duplications
                if {[$node isClass odfi::h2dl::Module] && ![$node isClass odfi::h2dl::Instance] && ![$node hasAttribute ::odfi::h2dl blackbox]} {

                    puts "Module was created from file : [$node file get]"
                    puts "Module -> To File ${outputFolder}/[$node name get].v" 
                    
                    ##puts "Module Res: $__r"
                    
                    odfi::files::writeToFile ${outputFolder}/[$node name get].v $__r 

                    ## Add to f
                    $fFileStream << [file normalize ${outputFolder}/[$node name get].v]

                    ::set __r ""
                }
                return $__r
               

            } ]

            ## Write F File out 
            ##########################
            $fFileStream close
            #odfi::files::writeToFile ${outputFolder}/netlist.f [join $filesList \n]


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
            }

            ## Remove Header Definition and take content as imported 
            ##############
            #set res [regexp {.*module.*\);(.*)endmodule} $content -> realContent ]
            
            set remaining [string range $fileContent [expr [string first ");" $fileContent]+2] end]

            ## Remove last "endmodule"
            set remaining [string map {endmodule ""} $remaining]

            #puts "Regexp match: $res"
            :importContent $remaining

            ## Parse IO 
            ###################
            set ios [odfi::dev::hw::rtl::extractIOFromFile $inFile]
            foreach io $ios {
                puts "Found io: [$io getName]"
                
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

