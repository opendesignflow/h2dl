package provide odfi::h2dl::stdlib 2.0.0
package require odfi::h2dl 2.0.0
package require odfi::h2dl::verilog 2.0.0

namespace eval h2dl::lib::counter {

    ::odfi::language::Language default {

        :counter : ::odfi::h2dl::Register name {

            +exportTo ::odfi::h2dl::Logic stdlib
            +exportTo ::odfi::h2dl::Module stdlib
            +expose name
            +var overflow false
            +var oReg ""
            +var lastCycleReg ""

            +method init args {
                 ## Change name a bit
                set :name [:name get]
                next
            }

            +method createLogic args {

                set target [:parent]
                set ctReg [current object]

                $target apply {
                     $ctReg <= $ctReg + 1
                     
                     if {${:oReg}!=""} {
                        ${:oReg} <= ( $ctReg == [expr 2**[$ctReg width get] -1 ] ) ? ( 1 : 0 )
                     }

                     if {${:lastCycleReg}!=""} {
                        ${:lastCycleReg} <= ( $ctReg == [expr 2**[$ctReg width get] -2 ] ) ? ( 1 : 0 )
                     }
                }

            }

            +method overflow v {
                set :overflow $v
                set target [:parent]
                set :oReg [$target register [:name get]_overflow]
                uplevel 3 [list set [:name get]_overflow ${:oReg}]

                if {$v==true} {

                    set target [:parent]
                    set ctReg [current object]

                    #$target apply {
                    #    set oReg [$target register [$ctReg name get]_overflow]
                    #    $oReg <= ( $ctReg == [expr 2**[$ctReg width get] -1 ] ) ? 1 : 0

                     #   uplevel 4 [list set [$ctReg name get]_overflow $oReg]
                    #}


                }
            }

            +method lastCycle v {
                set target [:parent]
                set :lastCycleReg [$target register [:name get]_last_cycle]
                 puts "in counter got to level : [uplevel 3 [list info level]] -> [:name get]_last_cycle "
                uplevel 3 [list set [:name get]_last_cycle ${:lastCycleReg}]
            }

            ## Create Appropriate Features 
            +builder {

               

                :onBuildDone {
                    if {[[:parent] isClass odfi::h2dl::::SyncBlock]} {
                        :createLogic
                    }
                }
            
            }
        }

        #::odfi::h2dl::Logic domain-mixins [namespace current]::register

    }


    ## Testbench Utils 
    ##########################

    ::odfi::language::Language default {

        set targetPrefix tb

        :always : ::odfi::h2dl::Logic time {
            +exportTo ::odfi::h2dl::Logic $targetPrefix
            +mixin ::odfi::h2dl::verilog::VerilogReduce

            +method verilog:reduce {parent results} {

                set resStr [$results map {
                    return "[[lindex $it 0] verilog:reduceTabs][lindex $it 1]"
                }]
                set resStr [$resStr mkString "\n"]
                return "always begin
                #${:time} $resStr
                end"
            }
        }

    }

}
