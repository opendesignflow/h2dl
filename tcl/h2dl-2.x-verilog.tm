package provide odfi::dev::hw::h2dl::verilog 2.0.0
package require odfi::dev::hw::h2dl 2.0.0
package require odfi::dev::hw::h2dl::ast 2.0.0

package require odfi::richstream 3.0.0


namespace eval odfi::dev::hw::h2dl::verilog {

    nx::Trait create VerilogReduce {

        :public method verilog:reduce {parent results} {
           # puts "Inside common Reduce"
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
        $target mixins add ::odfi::dev::hw::h2dl::verilog::VerilogReduce
        #$target domain-mixins add ::odfi::dev::hw::h2dl::verilog::VerilogReduce -prefix verilog
        
    }
    ## Components
    ######################
    defineReduce ::odfi::dev::hw::h2dl::Module {

        puts "Writing Out Module [:name get]"
        puts "Results Content: [$results size]"

        ## Prepare Stream To write out 
        #####################################
        set out [::new odfi::richstream::RichStream #auto]

        ## Write Definition 
        ############################
        $out <<< "module [:getModelInstanceName] "

        ### IOS
        set ioString [$results @> filterRemove {[lindex $it 0] isClass odfi::dev::hw::h2dl::IO} @> map {




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
        $results @> filterRemove {[lindex $it 0] isClass odfi::dev::hw::h2dl::NamedValue} @> mapSort {[lindex $it 0] name get} @> foreach {

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
        $results @> filterRemove {[lindex $it 0] isClass odfi::dev::hw::h2dl::Signal} @> mapSort {[lindex $it 0] name get} @> foreach {

            set regRes [lindex $it 1]
            $out << [[lindex $it 0] verilog:reduceTabs]$regRes
        }

        $out << ""
        $out << ""

        #### Assignments
        $out << "[:verilog:reduceTabs 1]// Assigments"
        $out << "[:verilog:reduceTabs 1]//---------------"

        $results @> filterRemove {[lindex $it 0] isClass odfi::dev::hw::h2dl::Assign} @> foreach {

            set regRes [lindex $it 1]
            $out << [[lindex $it 0] verilog:reduceTabs]$regRes
        }


        $out << ""
        $out << ""

        #### Instances
        $out << "[:verilog:reduceTabs 1]// Instances"
        $out << "[:verilog:reduceTabs 1]//---------------"

        $out << ""
        $out << ""

        #### Logic
        $out << "[:verilog:reduceTabs 1]// Logic"
        $out << "[:verilog:reduceTabs 1]//---------------"

        $results @> foreach {
            puts "Found Logic elements"
            $out << [[lindex $it 0] verilog:reduceTabs][lindex $it 1]
        }

        $out << ""
        $out << ""
        ## End Module 
        ######################
        $out <<  "endmodule"
        ## Return result 
        #####################
        set str [$out toString]
        odfi::common::deleteObject $out

        #puts "Result of Module: \n\r$str"
        return $str

    }

    defineReduce ::odfi::dev::hw::h2dl::Register {

        #puts "Writing Out Register [:name get]"
        #puts "Current parent is  [$parent info class]"
        if {![$parent isClass ::odfi::dev::hw::h2dl::Structural]} {
            return "[:name get]"
        } else {
            set size [expr [:width get] > 1 ? "{ \[[expr [:width get]-1]:0\]}" : "{}"]
            return "reg $size [:name get];"
        }
        

        #return "[:verilog:reduceTabs]register [:name get]"
    }

    defineReduce ::odfi::dev::hw::h2dl::Wire {

        #puts "Writing Out Register [:name get]"
        #puts "Current parent is  [$parent info class]"
        if {[$parent isClass ::odfi::dev::hw::h2dl::ast::ASTNode]} {
            return "[:name get]"
        } else {
            set size [expr [:width get] > 1 ? "{ \[[expr [:width get]-1]:0\]}" : "{}"]
            set subResults [$results @> map { return [[lindex $it 0] verilog:reduceTabs -1][lindex $it 1]} @> mkString {"\n" "\n" "\n" } ]
            return "wire $size [:name get];$subResults"
        }
        

        #return "[:verilog:reduceTabs]register [:name get]"
    }

    defineReduce ::odfi::dev::hw::h2dl::IO {

        if {[$parent isClass ::odfi::dev::hw::h2dl::ast::ASTNode]} {
            return "[:name get]"
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
            if {[:info class]=="::odfi::dev::hw::h2dl::Input"} {
                return "$desc    input [:type get]$size [:name get]"
            } elseif {[:info class]=="::odfi::dev::hw::h2dl::Output"} {
                return "$desc    output [:type get]$size [:name get]"
            } elseif {[:info class]=="::odfi::dev::hw::h2dl::Inout"} {
                return "$desc    inout [:type get]$size [:name get]"
            }
        }

        

    }

    defineReduce ::odfi::dev::hw::h2dl::NamedValue {

        return "localparam [:name get] = [:value get];"
    }

    ## Cases 
    ###################

    defineReduce ::odfi::dev::hw::h2dl::Case {

        set out [::new odfi::richstream::RichStream #auto]

        ## prepare signals
        puts "Case signals: "
        [:signals get] foreach {
            puts "-> $it // [$it info class]"
        }
        set signalNames [[[:signals get] map {$it name get}] mkString ,]

        ## Begin
        ##############
        $results @> filterRemove { [lindex $it 0] isClass ::odfi::dev::hw::h2dl::Comment} @> foreach {
            $out << [[lindex $it 0] verilog:reduceTabs -1][lindex $it 1]
        }
        $out << "[:verilog:reduceTabs]casex ({$signalNames})"

        ## Cases 
        ##############
        $results foreach {
            $out << "[lindex $it 1]"
        }


        ## End 
        ################
        $out << "[:verilog:reduceTabs]endcase"
        set str [$out toString]
        odfi::common::deleteObject $out

        return $str
    }

    defineReduce ::odfi::dev::hw::h2dl::On {
        #puts "Results for on, number of children: [[:children] size] , results size: [$results size]"

        #puts "On Results, [[$results at 0]""
        return "[:verilog:reduceTabs][:value get] : begin

[$results @> map { return [[lindex $it 0] verilog:reduceTabs][lindex $it 1]} @> mkString {\n}]

[:verilog:reduceTabs]end"
    }

    ## Assignments
    ##################
    defineReduce ::odfi::dev::hw::h2dl::ast::ASTBlockingAssign {
        return "[lindex [$results at 0] 1] = [lindex [$results at 1] 1];"
    }

    defineReduce ::odfi::dev::hw::h2dl::ast::ASTNonBlockingAssign {

        #puts "NB results $results [[lindex [$results at 1] 0] info class]"
        #return "[$results @> map { return [lindex $it 1]} @> mkString {-}]"
        return "[lindex [$results at 0] 1] <= [lindex [$results at 1] 1];"
    }

    defineReduce ::odfi::dev::hw::h2dl::Assign {

        #puts "NB results $results [[lindex $results 0] info class]"
        #return "[$results @> map { return [lindex $it 1]} @> mkString {-}]"
        #puts "******* ASSIGN [$results size]"
        return "assign [[:parent] name get] = [$results @> map { return [lindex $it 1]} @> mkString ];"
    }

    ## AST NOdes 
    ############################

    defineReduce ::odfi::dev::hw::h2dl::ast::ASTCompare {
        #puts "CONSTANT OUT"

        set left [lindex [$results at 0] 1]
        set right [expr {[$results size]>1} ? {[lindex [$results at 1] 1]} : "{}"]

        return "$left == $right"
    }

    defineReduce ::odfi::dev::hw::h2dl::ast::ASTConstant {
        #puts "CONSTANT OUT"
        return "[:constant get]"
    }

    defineReduce ::odfi::dev::hw::h2dl::ast::ASTRangeSelect {
        #puts "CONSTANT OUT"
        return "[[:firstChild] name get]\[[[:lastChild] constant get]\]"
    }

    defineReduce ::odfi::dev::hw::h2dl::ast::ASTConcat {
        #puts "CONSTANT OUT"
        set left [lindex [$results at 0] 1]
        set right [expr {[$results size]>1} ? {[lindex [$results at 1] 1]} : "{}"]

        #puts "Concact out"

        return "{$left , $right}"
    }

    defineReduce ::odfi::dev::hw::h2dl::ast::ASTShiftLeft {

         #puts "SL out"

        set left [lindex [$results at 0] 1]
        set leftNode [lindex [$results at 0] 0]
        set right [expr {[$results size]>1} ? {[lindex [$results at 1] 1]} : "{}"]

        return " $left\[[expr [$leftNode width get] -2]:[expr $right -1]\]  "
        
    }

    defineReduce ::odfi::dev::hw::h2dl::ast::ASTShiftRight {

         #puts "SL out"

        set left [lindex [$results at 0] 1]
        set leftNode [lindex [$results at 0] 0]
        set right [expr {[$results size]>1} ? {[lindex [$results at 1] 1]} : "{}"]

        return " $left\[[expr [$leftNode width get] -1]:[expr $right ]\]  "
        
    }

    defineReduce ::odfi::dev::hw::h2dl::ast::ASTAdd {

         #puts "SL out"

        set left [lindex [$results at 0] 1]
        set leftNode [lindex [$results at 0] 0]
        set right [expr {[$results size]>1} ? {[lindex [$results at 1] 1]} : "{}"]

        return "$left + $right"
        
    }

    defineReduce ::odfi::dev::hw::h2dl::ast::ASTIf {

        set left [lindex [$results at 0] 1]
        set leftNode [lindex [$results at 0] 0]
        set right [expr {[$results size]>1} ? {[lindex [$results at 1] 1]} : "{}"]

        return "$left ? $right"

    }
    defineReduce ::odfi::dev::hw::h2dl::ast::ASTElse {
        set left [lindex [$results at 0] 1]
        set leftNode [lindex [$results at 0] 0]
        set right [expr {[$results size]>1} ? {[lindex [$results at 1] 1]} : "{}"]

        return "$left : $right"
    }

    ## Logic 
    ###################
    defineReduce ::odfi::dev::hw::h2dl::If {

        set left [lindex [$results at 0] 1]
        $results pop 
        return "if ($left) begin
[$results @> map { return [[lindex $it 0] verilog:reduceTabs][lindex $it 1]} @> mkString { \n \n \n}]
[:verilog:reduceTabs]end"
    }

    defineReduce ::odfi::dev::hw::h2dl::Else {

        return "else begin
[$results @> map { return [[lindex $it 0] verilog:reduceTabs][lindex $it 1]} @> mkString { \n \n \n}]
[:verilog:reduceTabs]end"
    }

    ## Sections and Blocks 
    ###############################
    defineReduce ::odfi::dev::hw::h2dl::Stage {

        set out [::new odfi::richstream::RichStream #auto]

        ## Setup 
        ##############
        $out << "[:verilog:reduceTabs]// Stage: [:name get]"
        $out << "[:verilog:reduceTabs]//------------------------"

        ## Sync block
        #################

        set edge [expr {[:isClass odfi::dev::hw::h2dl::Negedge]} ? "{negedge}" : "{posedge}" ]

        ## Find reset 
        set resetStr ""
        set reset [:shade ::odfi::dev::hw::h2dl::Reset firstChild]
        puts "********* RESET: $reset"
        if {$reset!=""} {
            set r [$reset signal get]
            if {[string match "*_n" [$r name get]]} {
                set resetStr " or negedge [$r name get]"
            } else {
                set resetStr " or posedge [$r name get]"
            }
        }
        #set reset [:shade odfi::dev::hw::h2dl::Reset firstChild]
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
    defineReduce ::odfi::dev::hw::h2dl::fsm::Goto {
        if {[$parent isClass ::odfi::dev::hw::h2dl::ast::ASTNode]} {
            return [:to get]
        } 
       
    }

    defineReduce ::odfi::dev::hw::h2dl::fsm::State {
        #if {[$parent isClass ::odfi::dev::hw::h2dl::ast::ASTNode]} {
            return [:name get]
        #} 
       
    }

    defineReduce ::odfi::dev::hw::h2dl::fsm::Fsm {

        ## Create Values
        ## Gather All States 
        #############
        #set states [odfi::flist::MutableList new]
        #:shade ::odfi::dev::hw::h2dl::fsm::State walkDepthFirstPostorder {
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
    defineReduce ::odfi::dev::hw::h2dl::Comment {
        #puts "CONSTANT OUT"
        return "//[:value get]"
    }

    ## Generic Verilog Gen 
    #################################
    nx::Class create VerilogGen {

       

        :public method produce {{outputFolder "."}} {


            

            ## Start Producing
            #######################
            odfi::log::info "Start Producing verilog to ${outputFolder} on object [:info class] ->  ${:name}"

            ## List of created files 
            set filesList {}

            ## Prepare 
            ###################

            ## Module Prepares 
            if {[:isClass ::odfi::dev::hw::h2dl::Module]} {

                set module [current object]

                ## Find All the NamedValue for local params, and put them in the top module 
                :shade odfi::dev::hw::h2dl::NamedValue walkDepthFirstPreorder {
                    {namedValue parent} => 
                        $namedValue detachFrom $parent 
                        $namedValue setFirstParent $module 
                
                    return true
                }

                ## Find All Assigns on IOS and add them to top module 
                :shade odfi::dev::hw::h2dl::IO eachChild {

                    $it shade odfi::dev::hw::h2dl::Assign eachChild {
                        $module addChild $it
                    }

            
                }


            }

            set res [:shade ::odfi::dev::hw::h2dl::verilog::VerilogReduce reducePlus {

                


                ## Produce Results 
                #########################
                ::set __r [$node verilog:reduce $parent $results]

                ## Write to file if Module 
                if {[$node isClass odfi::dev::hw::h2dl::Module]} {
                    puts "Module -> To File ${outputFolder}/[$node name get].v" 
                    puts "Module Res: $__r"
                    odfi::files::writeToFile ${outputFolder}/[$node name get].v $__r 
                }
                return $__r
               

            } ]

            ## Write F File out 
            ##########################
            #odfi::files::writeToFile ${outputFolder}/netlist.f [join $filesList \n]


            return ""

            ## Perform necessary transformations
            ############################

            :walkDepthFirstPreorder {
                if {[$node isClass odfi::dev::hw::h2dl::Inout] && [$node shade odfi::dev::hw::h2dl::Highz firstChild]!=""} {

                    puts "VErilog found an InOut to resolve"
                    set module [$node parent]
                    set highz [$node shade odfi::dev::hw::h2dl::Highz firstChild]
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

    }
    ::odfi::dev::hw::h2dl::Module domain-mixins add ::odfi::dev::hw::h2dl::verilog::VerilogGen -prefix verilog


}

