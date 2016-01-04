## The AST Package provides the core tree syntax modelisation
package provide odfi::dev::hw::h2dl::sim1 2.0.0
package require odfi::dev::hw::h2dl 2.0.0
package require odfi::dev::hw::h2dl::sim::vcd 2.0.0


namespace eval  odfi::dev::hw::h2dl::sim1 {


    variable currentSimulator -1

    #####################################
    ## Simulator to drive the simulation process 
    #####################################
    nx::Object create Simulator  {

        :object variable -accessor public currentSimulator -1

    }
    nx::Class create Simulator {

        ## Resolution in PS
        :property -accessor public {resolution 10}

        ## Next time step 
        :variable -accessor public nextTime 0
        :variable -accessor public currentTime 0

        ## Immediate schedule
        :variable -accessor public immediateSchedule {}

        ## Start/Stop control 
        :variable stop false

        :public method init args {
            
            set :immediateSchedule [odfi::flist::MutableList new]

            next
        }
        :public method stop args {
            set :stop true
        }

        :public method scheduleNow node {
            ${:immediateSchedule} += $node
        }

        :public method scheduleClosureNow args {

            set closure [lindex $args end]
            set args [lrange $args 0 end-1]

            set node [SimulationAlwaysActive new]

            puts "SChedule: [$node disable get]"
            #puts "Closure to schedule $args"
            $node object method interact args "
                puts \"inside closure schedule host node with $args\"
               
                :apply {
                    $closure 
                }

                puts \"DONE\"
            " 

            :scheduleNow $node
            #${:immediateSchedule} += $node

        }

        :public method run {baseNode targetFile}  {

            set odfi::dev::hw::h2dl::sim1::currentSimulator [current object]

            odfi::log::info "Running Simulator on node [$baseNode toString]"

            ## Prepare VCD File 
            #####################
            set vcd [::odfi::dev::hw::h2dl::sim::vcd::VCDDump new -targetFile $targetFile]


            ## Look for the signals to dump 
            ##############
            odfi::log::info "Looking for signals to dumps "
            $baseNode walkBreadthFirst {

                if {[::odfi::common::isClass $node ::odfi::dev::hw::h2dl::sim1::SimulationDumpable]} {
                    $vcd registerDumpSignal $node
                }
                return true
            }

            ## Prepare VCD 
            #######################
            $vcd writeHeader
            
            #$vcd close 
            #return 0

            ## Loop as long as not stop function has been found, or nextTime > currentTime
            ########################
            set nextTime 0
            set :stop false 
            while {!${:stop}} {

                ## Set currentTime to nextTime
                set :currentTime ${nextTime}

                ## Limit the max time 
                if {${:currentTime}>10000} {
                    break
                }

                #odfi::log::info "Iteration time ${:currentTime}"

                $vcd time ${:currentTime}

                ## Walk the tree in depth first order
                ## On Simulation Active nodes:
                ##  - Ignore if not active 
                ##  - record next active time if declared active
                set processNodeClosure {
                    
                    node => 

                    #if {${:currentTime}>80} {
                    #    :stop
                   # }

                    ## Global Stop 
                    if {${:stop}} {
                       return false
                    }

                    ## Normal Processing 
                    set continue false


                    #odfi::log::info "(TIME: ${:currentTime}) on node $node // [$node info class] // [$node parent]"

                    if {[::odfi::common::isClass $node ::odfi::dev::hw::h2dl::sim1::SimulationActive]} {

                        set continue false

                        ## Check active heuristic 
                        set active [$node isActive ${:currentTime}]
                        if {$active} {

                            odfi::log::info "(TIME: ${:currentTime}) node [$node info class] is active"
                            
                            $node lastActiveTime ${:currentTime}


                            ## Simulation Value Update : Update and don't go further in tree
                            #################################
                            if {[::odfi::common::isClass $node ::odfi::dev::hw::h2dl::sim1::SimulationValueUpdater]} {

                                $node sim:updateValue
                                #if {[catch {$node sim:updateValue} res]} {
#
                                 #   ::puts "Error on updateValue $res"
                               # } 

                                
                            } else {
                                set continue true
                            }

                            ## Call Interact 
                            #######################
                            #puts "Node methods: [$node info  lookup methods]"
                            if {[lsearch -exact [$node info lookup methods] "interact"]!=-1} {
                                $node interact
                                 odfi::log::info "(TIME: ${:currentTime}) node [$node info class] is active after intract"
                            }
                            if {[lsearch -exact [$node info lookup methods] "sim:interact"]!=-1} {
                                $node  sim:interact
                            }
                            
                        } 


                        ## Update next time for node, only if not disabled
                        if {![$node disable get] || $active} {
                            set nextTimeForcompoent  [$node nextActiveTime]
                            if {$nextTime==${:currentTime}} {
                                set nextTime $nextTimeForcompoent
                            } elseif {($nextTimeForcompoent>0) && ($nextTimeForcompoent>${:currentTime}) && ($nextTimeForcompoent < $nextTime)} {
                                set nextTime $nextTimeForcompoent
                            }
                            #set nextTime [expr ($nextTimeForcompoent>0) && ($nextTimeForcompoent < $nextTime || ($nextTime==${:currentTime} && $nextTimeForcompoent!=${:currentTime})  ) ? $nextTimeForcompoent : $nextTime]

                            #odfi::log::info "Set next time to ${nextTime}"

                        } else {
                            set continue false
                        }
                        
                        

                        

        


                    } else {
                         set continue true
                    }


            


                    return $continue
                }

                ## Run on Top 
                $baseNode walkDepthFirstPreorder $processNodeClosure

                ## Run Immediate Stuff
                #odfi::log::info "---- Event Schedules --------"
                ${:immediateSchedule} popAll {

                    node =>
                        $node walkDepthFirstPreorder $processNodeClosure

                    ## update active time and value 
                    #$node lastActiveTime ${:currentTime}
                    #if {[::odfi::common::isClass $node ::odfi::dev::hw::h2dl::sim1::SimulationValueUpdater]} {

                     #   $node sim:updateValue 

                            
                    #}   

                    ## Request next time 
                    #set nextTimeForcompoent  [$node nextActiveTime]
                    #set nextTime [expr ($nextTimeForcompoent>0) && ($nextTimeForcompoent < $nextTime || $nextTime==${:currentTime} ) ? $nextTimeForcompoent : $nextTime]

                    ## Stop 
                    #if {${:stop}} {
                    #    break
                    #}
                }
                #odfi::log::info "---- EOF Event Schedules --------"

                #odfi::log::info "Set next time to ${nextTime} with current ${:currentTime} (immediate left: [${:immediateSchedule} size])"

                ## Stop condition 
                if {${nextTime}<=${:currentTime}} {
                    :stop
                }
            }
            ## EOF TIME LOOP

            puts "--EOF SIM"

        }

    }


   

    #################################
    ## base Traits used by Simulation Package 
    ## used for simulator run, or integration with main H2Dl Language 
    ################################
    nx::Class create SimulationActive -superclasses odfi::flextree::FlexNode {
        
        #Every mixins add SimulationActive
        #At    mixins add SimulationActive

        :variable lastActiveTime 0

        :variable -accessor public disable false

        :method init args {
            next 
        }

        #:public method isActive time  {
        #    return false 
        #}

        #:public method nextActiveTime args {
         #   next
         #   return 0
        #}
        :public method lastActiveTime t {
            set :lastActiveTime $t
        }

        :public method interact args {
            next
        }

    }

    nx::Class create SimulationAlwaysActive -superclasses  SimulationActive {

        :method init args {
            next 
        }

        :public method isActive time {
            return true
        }

        :public method nextActiveTime args {
            return -1
        }

    }

    ####################
    ## Some Nodes must not go through during simulation, because they activate themselves
    #####################
    nx::Class create SimulationNeverActive -superclass  SimulationActive {


        :public method isActive time {
            
            set :disabled true
            return false
        }

        :public method nextActiveTime args {
            return -1
        }

    }

    nx::Class create SimulationActiveOnRequest -superclass  SimulationActive {

        :property -accessor public {__activate false}

        :public method isActive time {
            if {${:__activate}==true} {
                set :disabled false 
                set :__activate false 
                return true 
            } else {
                set :disabled true
                return false
            }
            
        }

        :public method nextActiveTime args {
            return -1
        }

    }

    odfi::dev::hw::h2dl::Posedge mixins add immediateSchedule
 
    odfi::dev::hw::h2dl::Posedge public method +build args {

        puts "********* BUILDING Posedge with simulation interface: [[:signal get] info class]  ****************"
        

        ## Lookout for Signal changing its value
        set signal [:signal get]
        :addChild $signal
        $signal sim:onValueUpdate {

            set signal [:parent]
            set posedge [[$signal parents get] find { odfi::common::isClass $it odfi::dev::hw::h2dl::Posedge} ]
            puts "********* Activating Posedge for immediate schedule : [$posedge info class] ****************"
            $posedge __activate set true
            ${odfi::dev::hw::h2dl::sim1::currentSimulator} scheduleNow $posedge

        }

        return 
        

        $signal onChildAdded {

            ## Need to get this again, because it is an asynchronous call
            set signal [current object]
            set child [:child end]
            set valueChild [$signal shade ::odfi::dev::hw::h2dl::sim1::SimulationValue child 0]

            if {[::odfi::common::isClass $child ::odfi::dev::hw::h2dl::sim1::SimulationValue]} {

                #puts "Added Simulation Value $child , with main value: $valueChild"

                ## If there is a first value child, and this is a new one, just ignore its
                if {$valueChild!="" && $valueChild!=$child} {

                } else {


                    ## Check 
                    set value [$child getValue]
                    if {$value==1} {

                         puts "********* Activating Posedge for immediate schedule  ****************"
                         set posedge [[$signal parents get] find { odfi::common::isClass $it odfi::dev::hw::h2dl::Posedge} ]
                         $posedge __activate set true
                         ${odfi::dev::hw::h2dl::sim1::currentSimulator} scheduleNow $posedge
                         #$__caller __activate set true

                    }

                    ## Value Changed, Monitor value as well
                    $child onValueChanged {

                        set signal [:parent]

                        ## Check 
                        set value [:getValue]
                        if {$value==1} {

                             
                             set posedge [[$signal parents get] find { odfi::common::isClass $it odfi::dev::hw::h2dl::Posedge} ]
                             puts "********* Activating Posedge for immediate schedule : [$posedge info class] ****************"
                             $posedge __activate set true
                             ${odfi::dev::hw::h2dl::sim1::currentSimulator} scheduleNow $posedge
                             #$__caller __activate set true

                        }
                    }

                }
                
            }

        }


        next 
    }

     #########################
    ## Language Definition for Simulation language 
    #################################


    odfi::language::Language define SIM {

        ## IncTime is a list of times
        ## The next time, will always be the current one on the list
        :every : ::odfi::dev::hw::h2dl::Logic  incTime  {

            ## The index of the incTime to use
            +var currentIncTime 0

            ## Time of first activation
            +var first 0

            +exportTo ::odfi::dev::hw::h2dl::Module sim
            +mixin   SimulationActive

            +builder {
                set :currentIncTime 0
            }
            +method nextActiveTime args {

                if {${:first}>0} {
                    return   [expr ${:first}+${:lastActiveTime}]
                } else {
                    return [expr [lindex ${:incTime} ${:currentIncTime}]+${:lastActiveTime}]
                }

                
            }

            ## Active -> Switch to next time
            +method isActive time {

                #puts "Checking isActive at time $time against [:nextActiveTime] with first: ${:first}"

                ## Consume first time or normal times
                if {${:first}>0 && $time == [expr ${:first}+${:lastActiveTime}]} {
                    
                    set :first 0
                    return true 

                } elseif {${:first}<=0 && $time == [expr [lindex ${:incTime} ${:currentIncTime}]+${:lastActiveTime}]} {
                    
                    set :currentIncTime [expr (${:currentIncTime}+1)%[llength ${:incTime}]]
                    return true 
                
                } else {
                    return false
                }
            }
        }

        :at : ::odfi::dev::hw::h2dl::Logic  absoluteTime {

             +mixin   SimulationActive
             +exportTo ::odfi::dev::hw::h2dl::Module sim


             +method isActive time {
                if {$time == ${:absoluteTime}} {
                    set :disable true
                    return true 

                } else {
                    return false
                }
             }

            +method nextActiveTime args {
                return ${:absoluteTime}
            }

            ## Stop Node 
            :stop  when {

                +mixin  ::odfi::dev::hw::h2dl::sim1::SimulationAlwaysActive
                
                +method interact args {

                    puts "*********************************** STOP"
                    ${odfi::dev::hw::h2dl::sim1::currentSimulator} stop

                    next
                }
                
            }
        }

        ## Init is an alias for at 0 
        :initial {
            +exportTo ::odfi::dev::hw::h2dl::Signal sim

            +builder {
                set at [[:parent] addChild [odfi::dev::hw::h2dl::sim1::At new -absoluteTime 0]]
                :detach 
                $at addChild [current object]
            }
        }

        ## Set a value to a node 
        :value val {
            +exportTo ::odfi::dev::hw::h2dl::Signal sim

            +builder {
                #set v [odfi::dev::hw::h2dl::sim1::SimulationValue new -value ${:val}]
                #[:parent] addChild $v
                [:parent] sim:setValue ${:val}
                :detach
            }
        }


    }
    SIM produceNX

    ## This Trait is added to the nodes that can update a value 
    ## Ex: <= or = 
    nx::Class create SimulationValueUpdater -superclass  SimulationAlwaysActive {

        ::odfi::dev::hw::h2dl::ast::ASTNonBlockingAssign mixins add SimulationValueUpdater
        ::odfi::dev::hw::h2dl::ast::ASTBlockingAssign mixins add SimulationValueUpdater

    }

    ## SimValue is just a holder node to store simulation values 
    nx::Class create SimulationValue -superclass odfi::flextree::FlexNode {

        :mixins add ::odfi::dev::hw::h2dl::sim::vcd::VCDDumpValue
        
        :property value:required

        :property {forcedValue 0}
        :property {useForcedValue false}

        :method init args {

            #:value valuecmd TEST
            :registerEventPoint valueChanged
            next 
        }

        ## If in forced mode, don't update (has been during set forced)
        :public method setValue val  {

            if {!${:useForcedValue}} {
                set :value $val 
                :callValueChanged $val
            }
            
        }

        :public method getValue args {
            if {${:useForcedValue}} {
                return ${:forcedValue}
            } else {
                return ${:value}
            }
            
        }

        :public method getHexValue args {

            set v [:getValue]

            return "[format %x $v]"
            
        }

        :public method setForcedValue val {
            set :forcedValue $val
            :setValue $val
            set :useForcedValue true
        }

        :public method unForceValue args {
            set :useForcedValue false
        }
    }

    ## Language element for elements containing values to be dumpable
    ## This is a Type marker
    nx::Class create SimulationDumpable {


    }

    ::odfi::dev::hw::h2dl::Signal public method sim:probe args {
        [current object] object mixins add ::odfi::dev::hw::h2dl::sim1::SimulationDumpable
    }


    #######################################
    ## Value Updating Interface to AST package 
    ###############################################

    ## Add Support for immediate value update to = 
    ##########
    nx::Class create BlockingUpdateSimSupport {

        odfi::dev::hw::h2dl::ValueHolder mixins add BlockingUpdateSimSupport

        ## Let normal work, and look for updatable values on the expression side 
        :public method = args {

            set astNode [next]
            set expressionNode [$astNode child end]
            set leftSide [$astNode child 0]

            ## Value Update, do it event based 
            ######################
            ${expressionNode} shade ::odfi::dev::hw::h2dl::Register walkBreadthFirst {

                set reg $node           

                ## If Assignee is same as on the right, don't listen to avoid loops
                if {$reg!=$leftSide} {

                    #puts "Listening on [$reg name get]"
                    $reg sim:onValueUpdate {


                        set assignNode      <% return $astNode %>
                        set expression       [$assignNode child 1]
                        set signalNode      [$assignNode child 0]
                        set value [current object]

                        #puts "Updated   [$signalNode name get]"

                        ## Update value
                        set resValueNode [$expression sim:updateValue]
                        if {$resValueNode!=""} {
                             set resValue [$resValueNode getValue]

                            ## Assign
                            #puts " %%%%%%%%%%%%%%%%%%%%%%%%%% Updating [$signalNode name get]" 
                            $signalNode sim:setValue $resValue -now true 
                        }
                       

                    }
                }
                

            }

            return $astNode


        }
    }


    proc valueUpdaterBuilder {forClass updaterBody} {

        nx::Class create ${forClass}SimValueUpdater {
            upvar updaterBody updaterBody
            :public method updateValue args $updaterBody

        }

        $forClass domain-mixins add ${forClass}SimValueUpdater -prefix sim
    }

    ## Merge values right to left for node
    proc mergeValues node {

        set allValues [$targetAssignee shade ::odfi::dev::hw::h2dl::sim1::SimulationValue children]
        if {[$allValues size]>1} {
            set first [$allValues at 0]
            $allValues foreach {
                #$first setV
            }
        }
    }




    ## Update Non blocking assignment
    ###################################


    valueUpdaterBuilder ::odfi::dev::hw::h2dl::ast::ASTNonBlockingAssign {



        set targetAssignee [:child 0]
        set expression     [:child 1]

        puts "NB Updating Value for [$targetAssignee info class] // [$expression info class] "



        #[$targetAssignee name get]
        #puts "Blocking Updating Value for [$targetAssignee info class] "

        ## Get Expression Value 
        set newValue [$expression sim:updateValue]

        ## Non Blocking: Always add value as an extra node 
        ## There might already be an extra node 
        set firstValue [$targetAssignee shade ::odfi::dev::hw::h2dl::sim1::SimulationValue  child 0] 
        set lastValue  [$targetAssignee shade ::odfi::dev::hw::h2dl::sim1::SimulationValue  child end] 
       
       # puts "Values: $firstValue  , $lastValue <- $targetFinalValue"
        puts "----> Value: [$newValue getValue] ($firstValue // $lastValue)"
        #$targetAssignee sim:addValue [$newValue getValue]

        $targetAssignee sim:setUpdateValue [$newValue getValue]
        return 

        ## Try to reduce to newValue / currentValue
        set newValue "" 
        set currentValue ""

        ## Cases for expression: 
        ##  - An AST Operator: Calculate value and assign 
        ##  - A FlexNode, look for value
        if {[::odfi::common::isClass $expression ::odfi::dev::hw::h2dl::ast::ASTOperator] || [::odfi::common::isClass $expression ::odfi::dev::hw::h2dl::ast::ASTConstant]} {


            #puts "nb Updating value for Nont blocking assignment to $targetAssignee, with main operator [$expression info class]"

            ## New value 
            set newValue [$expression sim:updateValue]
            #puts "nb new value: $newValue"

            ## If new value is empty, or not a SimulationValue, assume the operator already updated the value 
            if {$newValue!="" || [::odfi::common::isClass $newValue ::odfi::dev::hw::h2dl::sim1::SimulationValue]} {

                ## Current value: add or  update 
                set currentValue [$targetAssignee shade ::odfi::dev::hw::h2dl::sim1::SimulationValue child 0]
                if {$currentValue!=""} {
                    #$currentValue detach
                    #$currentValue delete object
                    #$currentValue setValue [$newValue getValue]
                
                } else {

                    ## Make sure newvalue is also orphan before adding, to avoid weird stuff
                    #$newValue detach
                    #$targetAssignee addChild $newValue

                }

                

            } else {
                error "After Updating Expressions value, nothing was returned: $newValue"
            }

            ## Debug: 
            ## Current value 
            #set currentValue [$targetAssignee shade ::odfi::dev::hw::h2dl::sim1::SimulationValue child 0]
            #puts "Current value of node  [$targetAssignee name get] [$currentValue getValue]"

        } elseif {[::odfi::common::isClass $expression ::odfi::flextree::FlexNode]} {

            ## Look for value 
            set newValue [$expression shade ::odfi::dev::hw::h2dl::sim1::SimulationValue child 0]
            if {$newValue==""} {
                
                error "AST Non Blocking update, cannot fetch value from flexnode $expression , maybe not initialised"
            
            } else {

                ## Update left side value or add one
                set currentValue [$targetAssignee shade ::odfi::dev::hw::h2dl::sim1::SimulationValue child end]
                if {$currentValue!=""} {
                    #$currentValue setValue [$expressionValue getValue]
                } else {
                    #set newValue [::odfi::dev::hw::h2dl::sim1::SimulationValue new -value [$expressionValue getValue]]
                    #$targetAssignee addChild $newValue
                }

            }

        } else {
            error "AST Non Blocking update, expression is $expression , cannot start anything with that"
        }


        ## Perform Update 
        ##  -> If no value, add the newValue 
        ##  -> If a value, just update 
        ###########

        ## Bit Range is 
        ##   - fromBitRange or 0 
        ##   - toBitRange or size or left value
        set fromBitRange [expr ${:fromBitRange}>  0  ? ${:fromBitRange} : 0]
        set toBitRange   [expr ${:toBitRange}  >= 0  ? ${:toBitRange}   : [expr [$targetAssignee width get] -1]]

        ## Prepare Value from bit ranges: Extract and replace to correct targetPosition
        set extractedValue [$newValue getValue]
        #puts "----- value from operator is $extractedValue , extracting from ${fromBitRange} to ${toBitRange}"
        
        set extractedValue [expr ($extractedValue >> $fromBitRange) & ~(1<< (${toBitRange}+1))]
      
       # puts "----- after extraction $extractedValue"

        # If no actual value, no need to extract and all
        set targetFinalValue $extractedValue
        if {$currentValue!=""} {
            set targetFinalValue [$currentValue getValue]
            
        } 
        if {$fromBitRange == 0} {
            set targetFinalValue $extractedValue
        } else {
            set targetFinalValue [expr  $targetFinalValue | ($targetFinalValue & ( $extractedValue << ${fromBitRange} ) | ($extractedValue << ${fromBitRange}) ) ]
        }
        
       # puts "----- Remaining $targetFinalValue "
   

        ## Non Blocking: Always add value as an extra node 
        ## There might already be an extra node 
        set firstValue [$targetAssignee shade ::odfi::dev::hw::h2dl::sim1::SimulationValue  child 0] 
        set lastValue  [$targetAssignee shade ::odfi::dev::hw::h2dl::sim1::SimulationValue  child end] 
       
       # puts "Values: $firstValue  , $lastValue <- $targetFinalValue"
       
        if {$firstValue != $lastValue} {
            $lastValue setValue $targetFinalValue
        } else {
            set newValueToAdd [::odfi::dev::hw::h2dl::sim1::SimulationValue new -value $targetFinalValue ]
            $targetAssignee addChild $newValueToAdd
        }
        

        #if {$currentValue!=""} {
        #    $currentValue setValue $targetFinalValue
        #} else {
        #    $newValue detach
        #    $newValue setValue $targetFinalValue
        #    $targetAssignee addChild $newValue
        #}

        

    }

    ## Non blocking assignments must be updated at the end of a node's processing
    ::odfi::dev::hw::h2dl::Posedge public method sim:interact args {

        #puts "In posedge interact, schedule an action"
         ${odfi::dev::hw::h2dl::sim1::currentSimulator} scheduleClosureNow "
            ## Go through all non blocking assign nodes, and merge values
            [current object] shade ::odfi::dev::hw::h2dl::ast::ASTNonBlockingAssign walkDepthFirstPreorder {

                abn =>

               # puts \"Updating\"
                set left \[\$abn noShade child 0\]
                \$left sim:mergeValues
                return true
            }

         "   

        return 
        ${odfi::dev::hw::h2dl::sim1::currentSimulator} scheduleClosureNow [list node [current object]] {

            #puts "--> Inside posedge action: $node [[$node children] size] ******************************************************************************"

            ## Go through all non blocking assign nodes, and merge values
            $node shade ::odfi::dev::hw::h2dl::ast::ASTNonBlockingAssign walkDepthFirstPreorder {
           
                
               

                    set left [$node noShade child 0]
                    $left sim:mergeValues
                    return 

                 #   puts "Updating NB assign $node -> [$node info class] -> $left"

                    ## This method merges all the values on the left side to the first available value 
                    #set left [$node noShade child 0]
                    set values   [$left shade ::odfi::dev::hw::h2dl::sim1::SimulationValue children]
                    if {[$values size] >1 } {
                        set firstVal [$values at 0]
                        ::repeat [expr [$values size]-1] {
                            set val [$values at [expr $i+1]]
                            $firstVal setValue [$val getValue]
                            $val detach
                        }
                    }

              
                
                
                #$node mergeLeft
            }

           # puts " EOF posedge action*********************************************************************************************************************"
        }
    }


    ## Update Blocking Assignment 
    #######################

    valueUpdaterBuilder ::odfi::dev::hw::h2dl::ast::ASTBlockingAssign {



        set targetAssignee [:child 0]
        set expression     [:child 1]

        #[$targetAssignee name get]
        #puts "Blocking Updating Value for [$targetAssignee info class] "

        ## Get Expression Value 
        set newValue [$expression sim:updateValue]

        puts "Blocking Updating Value for [$targetAssignee info class] [$targetAssignee name get] -> [$newValue getValue]"

        $targetAssignee sim:setValue [$newValue getValue]
        $targetAssignee sim:mergeValues

        return 

        ## Perform Update 
        ##  -> If no value, add the newValue 
        ##  -> If a value, just update 
        ###########

        ## Prepare Value from bit ranges: Extract and replace to correct targetPosition
        set extractedValue [$newValue getValue]
        #puts "----- value from operator is $extractedValue , extracting from ${:fromBitRange} to ${:toBitRange}"
        if {${:fromBitRange}>=0} {
            set extractedValue [expr $extractedValue >> ${:fromBitRange} & 0x1]
        }
        #puts "----- after extraction $extractedValue"

        set targetFinalValue $extractedValue
        if {$currentValue!=""} {
            set targetFinalValue [$currentValue getValue]
        }
        #puts "----- merging $targetFinalValue with $extractedValue"
        ## Replace: Merge extractedValue and targetFinal, otherwise targetFinal is just the extractedValue
        if {${:toBitRange}>=0} {
             
            set targetFinalValue [expr  $targetFinalValue | ($targetFinalValue & ( $extractedValue << ${:toBitRange} ) | ($extractedValue << ${:toBitRange}) ) ]

        } else {

            set targetFinalValue $extractedValue
        }
       #puts "----- Remaining $targetFinalValue "

       #puts "Placing value to target: $currentValue"

       $targetAssignee sim:setValue $targetFinalValue
       return 

        if {$currentValue!=""} {
            $currentValue setValue $targetFinalValue
        } else {


            $newValue detach
            $targetAssignee addChild $newValue
            $newValue setValue $targetFinalValue
            
            
        }

        return 

        ## Try to reduce to newValue / currentValue
        set newValue "" 
        set currentValue ""

        ## Cases for expression: 
        ##  - An AST Operator: Calculate value and assign 
        ##  - A FlexNode, look for value
        if {[::odfi::common::isClass $expression ::odfi::dev::hw::h2dl::ast::ASTOperator] || [::odfi::common::isClass $expression ::odfi::dev::hw::h2dl::ast::ASTConstant]} {


            #puts "nb Updating value for Nont blocking assignment to $targetAssignee, with main operator [$expression info class]"

            ## New value 
            set newValue [$expression sim:updateValue]
            #puts "nb new value: $newValue"

            ## If new value is empty, or not a SimulationValue, assume the operator already updated the value 
            if {$newValue!="" || [::odfi::common::isClass $newValue ::odfi::dev::hw::h2dl::sim1::SimulationValue]} {

                ## Current value: add or  update 
                set currentValue [$targetAssignee shade ::odfi::dev::hw::h2dl::sim1::SimulationValue child 0]
                if {$currentValue!=""} {
                    #$currentValue detach
                    #$currentValue delete object
                    #$currentValue setValue [$newValue getValue]
                
                } else {

                    ## Make sure newvalue is also orphan before adding, to avoid weird stuff
                    #$newValue detach
                    #$targetAssignee addChild $newValue

                }

                

            } else {
                odfi::log::warning  "After Updating Expressions value, nothing was returned: $newValue"
                return 
            }

            ## Debug: 
            ## Current value 
            #set currentValue [$targetAssignee shade ::odfi::dev::hw::h2dl::sim1::SimulationValue child 0]
            #puts "Current value of node  [$targetAssignee name get] [$currentValue getValue]"

        } elseif {[::odfi::common::isClass $expression ::odfi::flextree::FlexNode]} {

            ## Look for value 
            set newValue [$expression shade ::odfi::dev::hw::h2dl::sim1::SimulationValue child 0]
            if {$newValue==""} {
                
                odfi::log::warning "AST Blocking update, cannot fetch value from flexnode $expression , maybe not initialised"
                return
            } else {

                ## Update left side value or add one
                set currentValue [$targetAssignee shade ::odfi::dev::hw::h2dl::sim1::SimulationValue child end]
                if {$currentValue!=""} {
                    #$currentValue setValue [$expressionValue getValue]
                } else {
                    #set newValue [::odfi::dev::hw::h2dl::sim1::SimulationValue new -value [$expressionValue getValue]]
                    #$targetAssignee addChild $newValue
                }

            }

        } else {
            error "AST Non Blocking update, expression is $expression , cannot start anything with that"
        }


        

        

    }



    ## Constant
    ###################################
    valueUpdaterBuilder ::odfi::dev::hw::h2dl::ast::ASTConstant {

        set valueNode [:shade ::odfi::dev::hw::h2dl::sim1::SimulationValue child 0]
        if {$valueNode!=""} {
            return $valueNode
        } else {
            set valueNode [::odfi::dev::hw::h2dl::sim1::SimulationValue new -value ${:constant}]
            :addChild $valueNode
            return $valueNode
        }
        
    }


    ## Mathematical update
    ###################################
    valueUpdaterBuilder ::odfi::dev::hw::h2dl::ast::ASTNegate {

        

        set valueSource [:child 0]

        ## Get Value 
        #################
        set value [$valueSource shade ::odfi::dev::hw::h2dl::sim1::SimulationValue child 0]
        if {$value==""} {
            odfi::log::error "Cannot Negate non existent value of node $valueSource ([$valueSource info class]). Make sure an initial value was set before starting"
        }

        if {[$valueSource width get]==1} {
            set negated [expr !int([$value getValue])]
        } else {
            set negated [expr ~int([$value getValue])]
        }
        #puts "negating"
       # set negated [expr ~int([$value getValue])]
        #puts "Negated from [$value getValue] to $negated ([format %b $negated]) "

        ## Return new Value 
        set newValue [::odfi::dev::hw::h2dl::sim1::SimulationValue new -value $negated]

        return $newValue

        #puts "Updating Negate base value: $value ([$value info class]), for parent of type [$valueSource info class] ([[$value parent] info class])"
        #[$value parents] foreach {
        #    puts "--> Parent of SimulationValue: [$it info class]"
        #}

        set negated [expr ~int([$value getValue])]
        puts "Negated from [$value getValue] to $negated"
        $value setValue $negated

        # puts "Done Updating Negate base value: $value"
        ## Return 
        return ""
        
       
    }


     valueUpdaterBuilder ::odfi::dev::hw::h2dl::ast::ASTAdd {

        #puts "In ADD Update "

        ## Left and right values 
        set left [:child 0]
        set right [:child 1]
        catch {$left sim:updateValue}
        catch {$right sim:updateValue}

        ## Value Objects
        set valLeft  [$left shade ::odfi::dev::hw::h2dl::sim1::SimulationValue child 0]
        set valRight [$right shade ::odfi::dev::hw::h2dl::sim1::SimulationValue child 0]

        ## Get real values or 0 if no available
        set vl [expr {$valLeft == ""} ? 0 : [$valLeft getValue]]
        set vr [expr {$valRight == ""} ? 0 : [$valRight getValue]]


        puts "-- in add $valLeft $valRight"
        set resVal [expr $vl + $vr]

        return [::odfi::dev::hw::h2dl::sim1::SimulationValue new -value $resVal]

     }

     valueUpdaterBuilder ::odfi::dev::hw::h2dl::ast::ASTAnd {

        #

        ## Left and right values 
        set left [:child 0]
        set right [:child 1]

        #puts "In ADD Update $left ([$left info class]), $right ([$right info class])"

        ## Left and Right could be operators
        if {[odfi::common::isClass $left ::odfi::dev::hw::h2dl::ast::ASTOperator]} {
            set valLeft [$left sim:updateValue]
        } else {
            set valLeft  [$left shade ::odfi::dev::hw::h2dl::sim1::SimulationValue child 0]
        }
        if {[odfi::common::isClass $right ::odfi::dev::hw::h2dl::ast::ASTOperator]} {
            set valRight [$right sim:updateValue]
        } else {
            #puts "------ fetchign val right from simulation value node: [$right shade ::odfi::dev::hw::h2dl::sim1::SimulationValue child 0] "
            set valRight  [$right shade ::odfi::dev::hw::h2dl::sim1::SimulationValue child 0]
        }

        #catch {$left sim:updateValue}
        #catch {$right sim:updateValue}

        ## Value left 
        #puts "--> Values ($valLeft) <-> ($valRight)"

        #set valLeft  [$left shade ::odfi::dev::hw::h2dl::sim1::SimulationValue child 0]
        #set valRight [$right shade ::odfi::dev::hw::h2dl::sim1::SimulationValue child 0]

        if {$valLeft == "" || $valRight == ""} {
            return ""
        }

        set resVal [expr [$valLeft getValue] & [$valRight getValue]]

        return [::odfi::dev::hw::h2dl::sim1::SimulationValue new -value $resVal]

     }

     valueUpdaterBuilder ::odfi::dev::hw::h2dl::ast::ASTBitOr {

        #puts "In ADD Update "

        ## Left and right values 
        set left [:child 0]
        set right [:child 1]
        catch {$left sim:updateValue}
        catch {$right sim:updateValue}

        ## Value left 

        set valLeft  [$left shade ::odfi::dev::hw::h2dl::sim1::SimulationValue child 0]
        set valRight [$right shade ::odfi::dev::hw::h2dl::sim1::SimulationValue child 0]

        if {$valLeft == "" || $valRight == ""} {
            return ""
        }

        set resVal [expr [$valLeft getValue] | [$valRight getValue]]

        return [::odfi::dev::hw::h2dl::sim1::SimulationValue new -value $resVal]

     }


     valueUpdaterBuilder ::odfi::dev::hw::h2dl::ast::ASTCompare {

        ## Left and right values 
        set left [:child 0]
        set right [:child 1]
        catch {$left sim:updateValue}
        catch {$right sim:updateValue}

        ## Value left 

        set valLeft  [$left shade ::odfi::dev::hw::h2dl::sim1::SimulationValue child 0]
        set valRight [$right shade ::odfi::dev::hw::h2dl::sim1::SimulationValue child 0]

        if {$valLeft == "" || $valRight == ""} {
            return 0
        }

        set resVal [expr [$valLeft getValue] == [$valRight getValue]]

        return [::odfi::dev::hw::h2dl::sim1::SimulationValue new -value $resVal]

     }


     ## Value Object Utilities 
     ################################
     set targetClasses {::odfi::dev::hw::h2dl::Register ::odfi::dev::hw::h2dl::Bit ::odfi::dev::hw::h2dl::IO}
     foreach targetClass $targetClasses {


        ## Adds a value node to the target. Calls set sim value if none present
        $targetClass public method sim:addValue  {value } {

            if {[[:shade ::odfi::dev::hw::h2dl::sim1::SimulationValue children] size]==0} {
                return [:sim:setValue $value ]
            } else {
                set valueNodes [::odfi::dev::hw::h2dl::sim1::SimulationValue new -value $value]
                :addChild $valueNodes

                return $valueNodes

            }

            
        }

         $targetClass public method sim:setUpdateValue  {value {-now false} {-forced false} } {

            ## Get update value 
            set v [:sim:getUpdateValue]
            $v setValue $value
         }
         ## Utility Method to set a value on a signal node 
         ##  1. Update existing value node, or add a new one
         ##  @param -now if set to true, updates all the value nodes to make sure non blocking assignments are overriden
         $targetClass public method sim:setValue  {value {-now false} {-forced false} } {

            #puts "in parent set Value"
            ## Take all value nodes, or just the last one 
            set valueNodes [:shade ::odfi::dev::hw::h2dl::sim1::SimulationValue children]


            ## If no value, create one 
            ## Otherwise update, all or just the last one 
            if {[$valueNodes size]==0} {

                set valueNodes [::odfi::dev::hw::h2dl::sim1::SimulationValue new -value $value]
                :addChild $valueNodes

                return $valueNodes

            } else {

                 set toReturn [$valueNodes at 0]
                if {!$now} {
                   
                    set valueNodes [$valueNodes at end]
                    
                } else {
                    
                    set valueNodes [$valueNodes asTCLList]
                    
                }

                ## Update 
                foreach node $valueNodes {
                    if {$forced} {
                        $node setForcedValue $value
                    } else {
                        $node setValue $value
                    }
                    
                }

                return $toReturn
            
            }  

         }


         $targetClass public method sim:unForceValues args {
            set valueNodes [:shade ::odfi::dev::hw::h2dl::sim1::SimulationValue children]
            $valueNodes foreach {
                #puts "node: [$it info lookup methods]"
                $it unForceValue
            }
         }

        ## Merges the right most value with the left most: Take right most value, delete all but first, set value
        $targetClass public method sim:mergeValues args {

            
            set firstValue [:shade ::odfi::dev::hw::h2dl::sim1::SimulationValue  child 0] 
            set lastValue  [:shade ::odfi::dev::hw::h2dl::sim1::SimulationValue  child end] 

            #puts "merging values of [:info class] $firstValue $lastValue "

            if {$firstValue!=$lastValue} {
                
                ## Only do something if more than one value 

                :sim:setValue [$lastValue getValue] -now true -force true

                
                [:shade ::odfi::dev::hw::h2dl::sim1::SimulationValue children] foreachFrom 1 {
                    $it detach 
                    $it destroy
                }

            } 
        }

         ## Return the actual value, means the left most node
         ## If no Value available, returns an empty string
         $targetClass public method sim:getValue args {

            set valueNodes [:shade ::odfi::dev::hw::h2dl::sim1::SimulationValue children]
            if {[$valueNodes size] > 0} {
                return [$valueNodes at 0]
            } else {
                return ""
            }

         }

         ## Return the value to use for update, which is the right most one
         ## If only one value available, create a new one
         $targetClass public method sim:getUpdateValue args {

            set firstValue [:shade ::odfi::dev::hw::h2dl::sim1::SimulationValue  child 0] 
            set lastValue  [:shade ::odfi::dev::hw::h2dl::sim1::SimulationValue  child end] 
            if {$firstValue!=$lastValue} {
                return $lastValue
            } elseif {$firstValue=="" && $lastValue==""} {

                return [:sim:setValue 0]

            } else {
                return [:sim:addValue [$firstValue getValue]]

            }


         }

         $targetClass public method sim:onValueUpdate listenClosure {


            set listenClosure [odfi::richstream::embeddedTclFromStringToString $listenClosure]
            set code [odfi::richstream::embeddedTclFromStringToString {

                #puts "CHILD ADDED, DUMP SIGNAL [:name get]"
                
                ## Get Child and filter if it is a value 
                ##  - If it is the first and only value, listen on the value, and run code 
                ##  - If not , do nothing

                set child [:child end]
                if {[::odfi::common::isClass $child ::odfi::dev::hw::h2dl::sim1::SimulationValue]} {

                    set lastValueChild [:shade ::odfi::dev::hw::h2dl::sim1::SimulationValue child end]

                    ## Go listen on value otherwise ignore
                    if {$child == $lastValueChild} {

                        ## Listen on value 
                        ##################
                        $child onValueChanged {

                            <% return $listenClosure %>
                        }

                        ## Execute closure 
                        ####################
                        $child callValueChanged
                        #%%listenClosure%%


                    }
                    

                    ## get VCD Scope from parent list
                    
                }

            }]

            ## Insert Listen Closure inside current node 
            #puts "Listen Closure is now: $code"
            :onChildAdded $code

            ## If there is already a left most value, listen onto this one already
            set actualValue [:sim:getValue]
            if {$actualValue!=""} {
                $actualValue onValueChanged $listenClosure
            }
         }


     }
     ## EOF value update support


     

     ## Reset Stuff 
     #########################
     #::odfi::dev::hw::h2dl::Reset public method sim:interact args {
#
     #   next
     #}

     

     ::odfi::dev::hw::h2dl::Reset +builder {

        puts "(SIM1) Building Reset Handler son $expr [$expr info class] -> ${:currentShading} -> [[$expr children] size]"

        :object variable -accessor public +sim_active false

        ## Idea: 
        ##   1. Listen to all changeable values in expression to update expression result when needed
        ##   2. Use the Forced Value interface to forced value during reset time

        set signal [:parent]
        #$signal sim:onValueUpdate {

           
        #    set signal [:parent]
            
        #    puts "(SIM1) Value on [$signal name get] was updated, checking "

         #   set reset  [$signal shade ::odfi::dev::hw::h2dl::Reset child 0]
         #   if {[$reset +sim_active get]} {
         #       set updateNow [$reset isAsync ? true : false]
               # $signal sim:setValue 0 -now $updateNow
         #   }
        #}

        ${:expr} shade ::odfi::dev::hw::h2dl::Register walkDepthFirst {

            set reg $node 

            #puts "(SIM1) Listening on [$reg name get] for reset value"
          


            $reg sim:onValueUpdate {

                set resetExpression <% return $expr %>
                set resetNode       [$resetExpression   parent]
                set signalNode      [$resetNode         parent]
                set value [current object]

                

                ## 1. Update Simulation Value of Expression Node 
                ## 2. if 1/true, set signalNode value to 0
                set updateNow [$resetNode isAsync ? true : false]
                set resValue [[$resetExpression sim:updateValue] getValue]

                #puts "(SIM1) Value in reset expression was updated. Reset expression is: $resetExpression ([$resetExpression info class]), returned value: $resValue"

                if {$resValue} {
                    $signalNode sim:setValue 0 -now $updateNow -forced true
                    #$signalNode sim:setForcedValue 0 -now $updateNow
                    $resetNode +sim_active set true

                     #puts "(SIM1) Forcing value of SR2 to 0"
                } else {
                    $resetNode +sim_active set false
                    $signalNode sim:unForceValues

                    #puts "(SIM1) UnForcing value of SR2 to 0"
                }


            }

        }

     }
     #::odfi::dev::hw::h2dl::Reset public method +build args {
     #   next 
     #   puts "(SIM1) Building Reset Handlers"
     #}


     ## Branching Nodes 
     ###############################

     valueUpdaterBuilder ::odfi::dev::hw::h2dl::ast::ASTIf {

        #puts "Update if with expression [:info class]"

        set expression [:child 0]

        ## If Expression is a ValueHolder node, then just take the value 
        ## Otherwise update 
        ############
        set expressionValue [$expression sim:updateValue]
        if {$expressionValue==""} {
            error "ASTIF Simulation Update, the target expression ($expression // [$expression info class]) triggers no value, maybe not initialised or so"
        }

        #if {[$expression isClass odfi::dev::hw::h2dl::ValueHolder]} {
        #    set expressionValue [$expression sim:getValue]
        #} else {
        #    set expressionValue [$expression sim:updateValue]
        #}

        #puts "Expression value to test $expressionValue"
        if {[$expressionValue getValue]} {

            #puts "If matches, let's return the body's value"

            ## Take Body expression 
            ##################
            set body [:child 1]
            set expressionValue [$body sim:updateValue]
            return [::odfi::dev::hw::h2dl::sim1::SimulationValue new -value [$expressionValue getValue]] 

        } else {

            ## Else 
            set else [:child 2]
            set elseExpression [$else child 0]

            
            set expressionValue [$elseExpression sim:updateValue]
            if {$elseExpression==""} {
            error "ASTIF Simulation Update, the else expression ($elseExpression // [$elseExpression info class]) triggers no value, maybe not initialised or so"
            }

            #puts "Else processing: [$elseExpression info class] -> [$expressionValue getValue] "

            return [::odfi::dev::hw::h2dl::sim1::SimulationValue new -value [$expressionValue getValue]] 

        }

        

        #puts "Value to return : [$expressionValue getValue]"

        

     }

     ## Value Holding : Bit support 
     #############################
     valueUpdaterBuilder ::odfi::dev::hw::h2dl::ValueHolder {

        return [:sim:getValue]

     }
     valueUpdaterBuilder ::odfi::dev::hw::h2dl::Input {

        return [:sim:getValue]

     }

     ::odfi::dev::hw::h2dl::Bit public method sim:getValue args {


        ## Value Must be present in parents  which is the main value holder 
        set parentValue [:parent sim:getValue]

        if {$parentValue==""} {
            error "Get Bit value at index ${:index} of parent [:parent name get], no value"
        }
        #puts "In Bit getValue: $parentValue"

        ## Create new bit value 
        set bitValue [expr ([$parentValue getValue] >> ${:index}) & 0x1]

        ## Return 
        return [::odfi::dev::hw::h2dl::sim1::SimulationValue new -value $bitValue]

        ## Set value 
        #:sim:setValue $bitValue
        #return [:sim:getValue]

     }

     ::odfi::dev::hw::h2dl::Bit public method sim:setUpdateValue {value {-now false} {-forced false} } {

        #puts "Setting value $value on Bit"
        #return next

        ## Value Must be present in parents  which is the main value holder 
        set currentValue [:parent sim:getUpdateValue]
        set parent [:parent]

        ## Update from to 
        set fromBitRange 0
        set toBitRange   ${:index}
        set newvalue  $value
 

        ## Bit Range is 
        ##   - fromBitRange or 0 
        ##   - toBitRange or size or left value
        set fromBitRange [expr ${fromBitRange}>  0  ? ${fromBitRange} : 0]
        set toBitRange   [expr ${toBitRange}  >= 0  ? ${toBitRange}   : [expr [$parent width get] -1]]

        ## Prepare Value from bit ranges: Extract and replace to correct targetPosition
        set extractedValue $newvalue
        #puts "----- value from operator is $extractedValue , extracting from ${fromBitRange} to ${toBitRange}"
        
        #set extractedValue [expr ($extractedValue >> $fromBitRange) & ~(1<< (${toBitRange}+1))]
      
       # puts "----- after extraction $extractedValue"

        # If no actual value, no need to extract and all
        set targetFinalValue $extractedValue
        if {$currentValue!=""} {
           set targetFinalValue [$currentValue getValue]
            
        } 

        if {$value==0} {
            set targetFinalValue [expr [$currentValue getValue] & ~( 1 << ${toBitRange})]
        } else {
            set targetFinalValue [expr [$currentValue getValue] | ( 1 << ${toBitRange} )]
        }
        #set targetFinalValue [expr  $targetFinalValue | ($targetFinalValue & ~( $extractedValue << ${toBitRange} ) | ($extractedValue << ${toBitRange}) ) ]

        #if {$fromBitRange == 0} {
        #    set targetFinalValue $extractedValue
        #} else {
        #    set targetFinalValue [expr  $targetFinalValue | ($targetFinalValue & ~( $extractedValue << ${toBitRange} ) | ($extractedValue << ${toBitRange}) ) ]
        #}

        #puts "Res: $targetFinalValue"

        $currentValue setValue $targetFinalValue

        #$parentValue setValue [expr  [$parentValue getValue] | ([$parentValue getValue] & ( $newvalue << ${fromIndex} ) | ($newvalue << ${fromIndex}) ) ]


        #:sim:setValue [expr  [$parentValue getValue] | ([$parentValue getValue] & ( $newvalue << ${fromIndex} ) | ($newvalue << ${fromIndex}) ) ]

     }
     #::odfi::dev::hw::h2dl::Bit public method sim:setValue {value {-now false} {-forced false} } {

        ## Record Value normaly 
      #  set valueNode [next]

        ## Update from to 
       # set fromIndex ${:index}
        #set toIndex   ${:index}
        #set newvalue  [$valueNode getValue]

        ## Now update to parent 
        #set parentValue [:parent sim:getValue]

        #$parentValue setValue [expr  [$parentValue getValue] | ([$parentValue getValue] & ( $newvalue << ${fromBitRange} ) | ($newvalue << ${fromBitRange}) ) ]

     #}


     ## Connection Support 
     ################
     #puts "A Conn builders: [odfi::dev::hw::h2dl::Connection +builders get] "
     odfi::dev::hw::h2dl::Connection +builder {

        set parent [:parent]
        #puts "Buld Connection from [$parent name get] to [[:child 0] name get]"

        ## Listen on destination if we are an input 
        ## Outputs are meant to be written, not updated 
        if {[$parent isClass odfi::dev::hw::h2dl::Input]} {
            set signal [[:child 0]]
            $signal sim:onValueUpdate "
                puts \"Updated IO\"
                $parent sim:setValue \[:getValue\] -now true
            "
        }

        #puts "in sim builder"
     }

    # puts "Conn builders: [odfi::dev::hw::h2dl::Connection +builders get] "

}
