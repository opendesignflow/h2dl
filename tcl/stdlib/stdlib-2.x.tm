package provide odfi::h2dl::stdlib 2.0.0
package require odfi::h2dl 2.0.0
package require odfi::h2dl::verilog 2.0.0
package require odfi::h2dl::section 2.0.0


## Global Utils 
#######################
namespace eval ::h2dl::lib::utils {


    ## Reset Resolution

}


## Counter 
###############
namespace eval ::h2dl::lib::counter {

    ::odfi::language::Language default {

        :counter : ::odfi::h2dl::section::LogicSection clk name size {

            +exportTo ::odfi::h2dl::Logic stdlib
            +exportTo ::odfi::h2dl::Module stdlib
            +expose name
            +var overflow     false
            +var overflowReg ""
            +var overflowIf ""
            +var lastCycleReg ""
            +var targetSyncClock ""
            +var counter ""

            +method init args {
                 ## Change name a bit
                set :name [:name get]
                next
            }
            
            
            
            ## Create Appropriate Features 
            +builder {
                
                set :counter [:register [:name get]_counter {
                   :width set ${:size}
                }]
                               
                set :targetSyncClock [:posedge ${:clk} {
                   
                }]
               
                
                :onBuildDone {
                    #if {[[:parent] isClass odfi::h2dl::::SyncBlock]} {
                    #    :createLogic
                    #}
                    ${:targetSyncClock} apply {
                        ${:counter} <= ${:counter} + 1
                    }
                    ${:targetSyncClock} moveToChildPosition end
                     
                    
                }
            
            }
            
            +method doReset s {
                :onBuildDone {
                    ${:targetSyncClock} implementReset <% return $s %>
                }
            }
            
            +method width {set value} {
                ${:counter} width set $value
            }
            
            +method addOverflow {name value} {
                
                set target       [:parent]
                set parentModule [:getParentModule]
                
                set overflowReg  [:register [:name get]_${name}_overflow]
                
                :addGlobalOverflow
                ${:targetSyncClock} apply {
                    
                    ## Calculate overflow
                    $overflowReg <= ( ${:counter} == $value ) ? ( 1 : 0 )
                    
                    ## Reset on Real Overflow
                    ${:overflowIf} apply {
                        $overflowReg <= 0
                    }
                }
                
                ## Add Overflow Reg to caller
                lassign  [::odfi::common::findFileLocation] f l frame up
                uplevel $up [list set [$overflowReg name get] $overflowReg]
            }
            
            +method addCompare {name value} {
                            
                set target       [:parent]
                set parentModule [:getParentModule]
                
                set overflowCompare  [:register [:name get]_${name}_compare]
                
                :addGlobalOverflow
                ${:targetSyncClock} apply {
                    
                    ## Calculate overflow
                    $overflowCompare <= ( ${:counter} gt $value ) ? ( 1 : 0 )
                    
                    ## Reset on Real Overflow
                    ${:overflowIf} apply {
                        $overflowCompare <= 0
                    }
                }
                
                ## Add Overflow Reg to caller
                lassign  [::odfi::common::findFileLocation] f l frame up
                uplevel $up [list set [$overflowCompare name get] $overflowCompare]
            }

            +method createLogic args {

                set target [:parent]
                set ctReg [current object]
                set parentModule [:getParentModule]

                $target apply {
                     $ctReg <= $ctReg + 1
                     
                     #if {${:oReg}!=""} {
                     #   ${:oReg} <= ( $ctReg == [expr 2**[$ctReg width get] -1 ] ) ? ( 1 : 0 )
                     #}

                     #if {${:lastCycleReg}!=""} {
                     #   ${:lastCycleReg} <= ( $ctReg == [expr 2**[$ctReg width get] -2 ] ) ? ( 1 : 0 )
                     #}
                }

            }

            +method addGlobalOverflow args {
                #set :overflow $v
                #set target [:parent]
                
                if {${:overflowIf}==""} {
                    set :overflowReg [:register [:name get]_overflow]
                    ${:targetSyncClock} apply {
                    
                        ${:overflowReg} <= ( ${:counter} == [expr 2**[${:counter} width get] -1 ] ) ? ( 1 : 0 )
                        
                        [:parent] overflowIf set [:if {${:overflowReg}} {
                        
                        }]
                    }
                
                }
               
                
                return 
                #uplevel 3 [list set [:name get]_overflow ${:oReg}]

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

           
        }

        #::odfi::h2dl::Logic domain-mixins [namespace current]::register
        
        ## Clock Domain Sync Stuff
        ################
        :reset_sync : ::odfi::h2dl::section::LogicSection baseReset KW1 targetReset KW2 targetClock {

            +exportTo ::odfi::h2dl::Logic stdlib
            +exportTo ::odfi::h2dl::Module stdlib
            
            +builder {
                set :targetReset [:register ${:targetReset}]
                :posedge ${:targetClock} {
                    ${:targetReset} <= ${:baseReset}
                }
                
                ## Set variable in caller
                lassign  [::odfi::common::findFileLocation] f l frame up    
                puts "Reset sync caller level: $up"
                
                uplevel $up [list set [${:targetReset} name get] ${:targetReset}]
            }
        
        }

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
