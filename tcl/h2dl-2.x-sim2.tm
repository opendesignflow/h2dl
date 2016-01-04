## The AST Package provides the core tree syntax modelisation
package provide odfi::dev::hw::h2dl::sim2 2.0.0
package require odfi::dev::hw::h2dl 2.0.0
package require odfi::dev::hw::h2dl::sim::vcd 2.0.0


namespace eval  odfi::dev::hw::h2dl::sim2 {


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

        :variable -accessor public scheduleList {}

        ## Start/Stop control 
        :variable stop false
 
        :public method init args {
            
            set :immediateSchedule [odfi::flist::MutableList new]
            #set :scheduleList      [odfi::flist::MutableList new]

            next
        }
        :public method stop args {
            set :stop true
        }

        :public method scheduleNow node {
            ${:immediateSchedule} += $node
        }

        :public method scheduleClosure {at closure} {

            set cl [odfi::richstream::template::stringToString $closure]

            #puts "Scheduling cl $cl"
            ## Create an Immediate Node 
            set node [ImmediateSchedulable new -nextTime $at]
            $node public object method run {simulator time {-instance ""}} "
                :apply {
                    $cl 
                }
            "

            :schedule $node
            return 

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

        ## Schedules a node to be run 
        ## Look for a node that has a higher time than ours. If not found, add first 
        :public method schedule node {

            set targetTime [$node nextTime get]
            if {$targetTime==-1} {
                return
            }

            set index 0
            set done false 
            foreach scheduled ${:scheduleList} {

                set scheduledTime [$scheduled nextTime get]
                if {$scheduledTime>$targetTime} {
                    set  :scheduleList [linsert ${:scheduleList} $index $node]
                    #puts "Scheduled at $index"
                    set done true
                    break
                }

                incr index 

            }

            if {!$done} {
                #set  :scheduleList [linsert ${:scheduleList} 0 $node]
                lappend :scheduleList $node
                #puts "Scheduled [$node info class] at 0"
                
            }

            #puts "done scheduling"

            #${:scheduleList} foreach {
             #   
#
            #}
        }

        :public method run {baseNode targetFile}  {

            set ::odfi::dev::hw::h2dl::sim2::currentSimulator [current object]

            odfi::log::info "Running Simulator on node [$baseNode toString]"

            ## Prepare VCD File 
            #####################
            set vcd [::odfi::dev::hw::h2dl::sim::vcd::VCDDump new -targetFile $targetFile]


            ## Look for the signals to dump 
            ############################################
            odfi::log::info "Looking for signals to dumps "
            set masters {}
            $baseNode walkBreadthFirst {

                set continue true
                if {[::odfi::common::isClass $node ::odfi::dev::hw::h2dl::sim2::SimulationDumpable]} {
                    odfi::log::info "Found"
                    $vcd registerDumpSignal $node
                    set continue false
                } elseif {[::odfi::common::isClass $node ::odfi::dev::hw::h2dl::Instance]} {

                    ## Search Master 
                    if {[odfi::common::isClass [$node master get] ::odfi::dev::hw::h2dl::Master]} {
                        lappend masters  [$node master get]
                        puts "Saving master $masters"
                        set continue false
                    }
                    
                    
                }
                return $continue
            }

            ## Search Masters
            #set masters [lsort -unique $masters]
            puts "Masters: $masters"
            foreach m $masters {
                puts "SDearching master: $m"
                $m  walkBreadthFirst {

                    set continue true
                    if {[::odfi::common::isClass $node ::odfi::dev::hw::h2dl::sim2::SimulationDumpable]} {
                        $vcd registerDumpSignal $node
                        set continue false
                    }
                    return $continue
                }
            }

            ## Prepare VCD 
            #######################
            $vcd writeHeader
            
            #$vcd close 
            #return 0

            ## Time Preparation
            ##########
            set :currentTime 0


            ## Run Principle
            ##   1. Go in base level children, and ask Simulation Nodes for scheduling
            ##   2. Further Scheduling should happen automatically as nodes register themselves
            ################
            [$baseNode shade odfi::dev::hw::h2dl::sim2::Schedulable children] foreach {
                puts "Found schedulable"
                $it schedule [current object] ${:currentTime}
            }
            puts "Running [llength ${:scheduleList}]"

            ## Main Scheduling Thread 
            ################
            while {!${:stop} && [llength ${:scheduleList}]>0} {

               

                #puts "Running node"
                ## Take 
                set node [lindex ${:scheduleList} 0]
                set :scheduleList [lreplace ${:scheduleList} 0 0]

                 puts "(TIME: ${:currentTime}) [$node info class]"

                ## Increment time if necessary
                set nodeTime [$node nextTime get]
                if {${:currentTime}<$nodeTime} {
                    set :currentTime $nodeTime
                    $vcd time ${:currentTime}
                } 

                ## Run 
                $node run [current object] ${:currentTime}

                ## Schedule 
                #$node schedule [current object] ${:currentTime}

            

            }



            return 0

        }

    }


    #########################
    ## Language Definition for Simulation language 
    #################################


    odfi::language::Language define SIM {

        +type Schedulable {

            +var nextTime 0 

            +method run {simulator currentTime {-instance ""}} {
                next
                #[:shade odfi::dev::hw::h2dl::sim2::Schedulable children] foreach {
                    #puts "---> Found schedulable [$it info class]"
                 #   $it schedule $simulator ${:currentTime}
                #}
            }

            +method schedule {simulator currentTime} {
                next
            }
        }

        +type ImmediateSchedulable : Schedulable {
            
            +method schedule {simulator currentTime} {
                #next
                set :nextTime $currentTime
                $simulator schedule [current object]
                
            }

        }



        ## IncTime is a list of times
        ## The next time, will always be the current one on the list
        :every : ::odfi::dev::hw::h2dl::Logic  incTime  {

            ## The index of the incTime to use
            +var currentIncTime 0

            ## Time of first activation
            +var first 0

            +exportTo ::odfi::dev::hw::h2dl::Module sim
            +mixin    Schedulable

            +method schedule {simulator currentTime} {
                
                if {${:first}>0} {
                    set targetTime ${:first}
                    set :first 0
                } else {
                    set targetTime [expr $currentTime + ${:incTime}]
                }

                #puts "Scheduling every at $targetTime "
                set :nextTime $targetTime

                $simulator schedule [current object]
                #set targetTime [${:first}!= 0 ? ${:first} : ]

            }

            +method run {simulator currentTime {-instance ""}} {
                #puts "Running Every at $currentTime"

                [:shade odfi::dev::hw::h2dl::sim2::Schedulable children] foreach {
                    #puts "---> Found schedulable [$it info class]"
                    $it schedule $simulator ${:currentTime}
                }

                ## Reschedule 
                :schedule $simulator $currentTime
            }
            
        }

        :at : ::odfi::dev::hw::h2dl::Logic  absoluteTime {

             +mixin   Schedulable
             +exportTo ::odfi::dev::hw::h2dl::Module sim

             +method schedule {simulator currentTime} {
                
                #puts "Scheduling every at $targetTime "
                set :nextTime ${:absoluteTime}

                $simulator schedule [current object]
                #set targetTime [${:first}!= 0 ? ${:first} : ]

            }

            +method run {simulator currentTime {-instance ""}} {
                #puts "Running Every at $currentTime"

                [:shade odfi::dev::hw::h2dl::sim2::Schedulable children] foreach {
                    #puts "---> Found schedulable [$it info class]"
                    $it schedule $simulator ${:currentTime}
                }

            }

            ## Stop Node 
            :stop  when {

                +mixin  ImmediateSchedulable
                
                +method run {simulator currentTime {-instance ""}} {

                    puts "*********************************** STOP"
                    $simulator stop

                    
                }
                
            }


        }

        ## Utility
        ##################
        +type TBUtils {
            +exportTo ::odfi::dev::hw::h2dl::Module sim

            +method registers args {
                foreach reg $args {
                    :register $reg {
                        :sim:setValue 0
                    }
                }
            }
        }
       
       


    }
    SIM produceNX

    ## Schedule Utility 
    nx::Class create ScheduleOnInstance -superclasses Schedulable {
        :property -accessor public instance
        :property -accessor public node

        :method init args {
            next
        }

        :public method run {simulator currentTime {-instance ""}} {
            ${:node} run $simulator $currentTime -instance ${:instance}

        }
    }


    ####################################################################################
    ## Value Probing and set 
    #####################################################################################


    ## SimValue is just a holder node to store simulation values 
    nx::Class create SimulationValue -superclass odfi::flextree::FlexNode {

        :mixins add ::odfi::dev::hw::h2dl::sim::vcd::VCDDumpValue
        :mixins add ::odfi::dev::hw::h2dl:::InstanceSupport

        :property value:required

        :property {forcedValue 0}
        :property {useForcedValue false}

        :variable -accessor public previousValue x

        :method init args {
            next

            #:value valuecmd TEST
            :registerEventPoint valueChanged
             
        }

        ## If in forced mode, don't update (has been during set forced)
        :public method setValue val  {

            if {!${:useForcedValue}} {
                set :previousValue ${:value}
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

        :public method getPreviousValue args {
            if {${:useForcedValue}} {
                return ${:forcedValue}
            } else {
                return ${:previousValue}
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
        [current object] object mixins add ::odfi::dev::hw::h2dl::sim2::SimulationDumpable
    }

    #############################
    ## Simulation Value Interface support 
    ###########################################

    set targetClasses {::odfi::dev::hw::h2dl::Register ::odfi::dev::hw::h2dl::Bit ::odfi::dev::hw::h2dl::IO ::odfi::dev::hw::h2dl::ast::ASTNode}
    nx::Class create SimulationValueSupport {

        ## Adds a value node to the target. Calls set sim value if none present
        :public method sim:addValue  {value } {

            if {[[:shade ::odfi::dev::hw::h2dl::sim2::SimulationValue children] size]==0} {
                return [:sim:setValue $value ]
            } else {
                set valueNodes [::odfi::dev::hw::h2dl::sim2::SimulationValue new -value $value]
                :addChild $valueNodes

                return $valueNodes

            }

            
        }

        :public method sim:setUpdateValue  {value {-now false} {-forced false} } {

            ## Get update value 
            set v [:sim:getUpdateValue]
            $v setValue $value
         }

         ## Utility Method to set a value on a signal node 
         ##  1. Update existing value node, or add a new one
         ##  @param -now if set to true, updates all the value nodes to make sure non blocking assignments are overriden
         :public method sim:setValue  {value {-now false} {-forced false} {-instance ""} } {

            next 

            ## Find Target Instance 
            ##  - From provided value 
            ##  - From current hierarchy
            if {$instance=="" && [odfi::common::isClass $value ::odfi::dev::hw::h2dl::sim2::SimulationValue]} {
                set instance [$value findFirstInstanceInHierarchy]
            } elseif {$instance=="" && [odfi::common::isClass [current object] ::odfi::dev::hw::h2dl::Signal]} {
                set instance [:findFirstInstanceInHierarchy]
            }

            ## Force value being an object
           # puts "Setting value $value"
            if {![odfi::common::isClass $value ::odfi::dev::hw::h2dl::sim2::SimulationValue]} {
                set value [::odfi::dev::hw::h2dl::sim2::SimulationValue new -value $value]
                set newValue $value 
            } else {

                ## If Value is already in our list, don'T do anthing
                ## MUST be to avoid cycles in value set 
                #if {[[:noShade children] contains $value]} {
                #    return $value
                #}

                set newValue [$value copy]
            }

            ## Try to find if the value belongs to an instance 
            #set instanceContainer [$value findFirstInstanceInHierarchy]

            #puts "Setting value on [current object], [:info class] , v is $newValue, Instance : $instance"

            ## IF an instance is provided, set it to new value parent 
            ## If an instance is not provided, try to set to this object's instance 
            if {$instance!=""} {
                $newValue addParent $instance
            } 
            #elseif {[:isClass odfi::dev::hw::h2dl::InstanceSupport] && [:findFirstInstanceInHierarchy]!=""} {
            #    $newValue addParent [:findFirstInstanceInHierarchy]
            #}

            ## Search function for value :
            ##   - Be a SimulationValue, share the instance 
            set filterFunc {
                expr { [$it isClass ::odfi::dev::hw::h2dl::sim2::SimulationValue] && [$it shade odfi::dev::hw::h2dl::Instance parent] == $instance}
            }

            #puts "in parent set Value"
            ## Take all value nodes, or just the last one 
            #set valueNodes [:shade ::odfi::dev::hw::h2dl::sim2::SimulationValue children]
            set valueNodes [:shade $filterFunc children]
           # puts "looking for Value with correct Instance container, found [$valueNodes size]"

            ## If no value, create one 
            ## Otherwise update, all or just the last one 
            if {[$valueNodes size]==0} {

                #set valueNodes [::odfi::dev::hw::h2dl::sim2::SimulationValue new -value $value]
               # puts "Adding child to [current object]"
                :addChild $newValue

                return $newValue

            } else {


                ## Save return value
                set toReturn [$valueNodes at 0]

                ## Update 
                $valueNodes foreach {
                    if {$forced} {
                        $it setForcedValue [$newValue getValue]
                    } else {
                        $it setValue [$newValue getValue]
                    }
                }

               
                
                #if {!$now} {
                   
                #    [$valueNodes at end]
                    
                #} else {
                    
                 #   set valueNodes [$valueNodes asTCLList]
                    
                #}

                ## Update 
                #foreach node $valueNodes {
                 #   if {$forced} {
                  #      $node setForcedValue $value
                   # } else {
                    #    $node setValue $value
                    #}
                    
                #}

                return $toReturn
            
            }  

         }


        :public method sim:unForceValues  {{-instance ""}} {

            ## Normal Search 
            ## Search function for value :
            ##   - Be a SimulationValue, share the instance 
            set filterFunc {
                expr { [$it isClass ::odfi::dev::hw::h2dl::sim2::SimulationValue] && [$it shade odfi::dev::hw::h2dl::Instance parent] == $instance}
            }
            set valueNodes [:shade $filterFunc children]

            #set valueNodes [:shade ::odfi::dev::hw::h2dl::sim2::SimulationValue children]
            $valueNodes foreach {
                #puts "node: [$it info lookup methods]"
                $it unForceValue
            }
         }

        ## Merges the right most value with the left most: Take right most value, delete all but first, set value
        :public method sim:mergeValues args {

            
            set firstValue [:shade ::odfi::dev::hw::h2dl::sim2::SimulationValue  child 0] 
            set lastValue  [:shade ::odfi::dev::hw::h2dl::sim2::SimulationValue  child end] 

            #puts "merging values of [:info class] $firstValue $lastValue "

            if {$firstValue!=$lastValue} {
                
                ## Only do something if more than one value 

                :sim:setValue [$lastValue getValue] -now true -force true

                
                [:shade ::odfi::dev::hw::h2dl::sim2::SimulationValue children] foreachFrom 1 {
                    $it detach 
                    $it destroy
                }

            } 
        }

         ## Return the actual value, means the left most node
         ## If no Value available, returns an empty string
         :public method sim:getValue {{-instance ""}} {

            #puts "Getting from next on [:info class]"

            set v [next]

            #puts "Done"
            

            #puts "Getting value for [:info class], instance $instance, super returned $v"
            if {$v!="" && [$v isClass ::odfi::dev::hw::h2dl::sim2::SimulationValue]} {
                return $v
            }

            ## If no instance was provided, try to use the one of the signal 
            if {$instance=="" && [:isClass odfi::dev::hw::h2dl::InstanceSupport]} {
                set instance [:findFirstInstanceInHierarchy]
                #set instance ::nsf::__#9V
            }

            #puts "showing"
            #[:shade ::odfi::dev::hw::h2dl::sim2::SimulationValue children] foreach {
            #    puts "--> Val: $it ([$it getValue]) , p: [$it findFirstInstanceInHierarchy]"
            #}

            ## Normal Search 
            ## Search function for value :
            ##   - Be a SimulationValue, share the instance 
            set filterFunc {
                expr { [$it isClass ::odfi::dev::hw::h2dl::sim2::SimulationValue] && [$it shade odfi::dev::hw::h2dl::Instance parent] == $instance}
            }
            set valueNodes [:shade $filterFunc children]

            if {[$valueNodes size] > 0} {
                return [$valueNodes at 0]
            } else {
                return ""
            }

         }

         :public method sim:updateValue {{-instance ""}} {
            return [:sim:getValue -instance $instance]
         }

         ## Return the value to use for update, which is the right most one
         ## If only one value available, create a new one
         :public method sim:getUpdateValue args {

            set firstValue [:shade ::odfi::dev::hw::h2dl::sim2::SimulationValue  child 0] 
            set lastValue  [:shade ::odfi::dev::hw::h2dl::sim2::SimulationValue  child end] 
            if {$firstValue!=$lastValue} {
                return $lastValue
            } elseif {$firstValue=="" && $lastValue==""} {

                return [:sim:setValue 0]

            } else {
                return [:sim:addValue [$firstValue getValue]]

            }


         }

        :public method sim:onValueUpdate { {-instance ""} listenClosure} {

            #puts "Value update concerning instance: $instance "

            set listenClosure [odfi::richstream::template::stringToString $listenClosure 3]
            
            #return 
            set code [odfi::richstream::template::stringToString {

                #puts "CHILD ADDED, DUMP SIGNAL [:name get]"
                
                ## Get Child and filter if it is a value 
                ##  - If it is the first and only value, listen on the value, and run code 
                ##  - If not , do nothing

                set child [:child end]
                if {[::odfi::common::isClass $child ::odfi::dev::hw::h2dl::sim2::SimulationValue]} {

                    set lastValueChild [:shade ::odfi::dev::hw::h2dl::sim2::SimulationValue child end]
                    set targetInstance "<% return $instance %>"
                    set childInstance  [$child findFirstInstanceInHierarchy]
                    ## Check child has the right targetInstance 

                    puts "---> Added simulation value to node [:name get], target instance from child is $childInstance, answer to instance $targetInstance"

                    ## Go listen on value otherwise ignore
                    #if {$child == $lastValueChild} RELEVANT?
                    if {$targetInstance=="*" || ($childInstance == $targetInstance)} {

                        ## Listen on value 
                        ##################
                        set vcCK [$child onValueChanged {

                            <% return $listenClosure %>
                        }]
                        

                        ## Execute closure 
                        ####################
                        puts "---> trigeering value changed on $child von child added of [current object], created value listening closure: $vcCK"
                        #puts "---> Code is [$vcCK cget -preparedClosure]"
                        #$child callValueChanged
                        $child apply {
                            $vcCK apply
                        }

                        #%%listenClosure%%


                    }
                    

                    ## get VCD Scope from parent list
                    
                }

            }]

            ## Insert Listen Closure inside current node 
            #puts "Listen Closure is now: $code"
            #puts "Sim value update wait on [current object] for instance $instance"
            #:onChildAdded $code


            ## If there is already a left most value, listen onto this one already
            if {$instance=="*"} {
                set actualValueSearch ""
            } else {
                set actualValueSearch $instance
            }
            set actualValue [:sim:getValue -instance $actualValueSearch]
            if {$actualValue!=""} {
                $actualValue onValueChanged $listenClosure

                if {$instance=="*"} {
                    :onChildAdded $code
                }

            } else {
                :onChildAdded $code
            }

            return $listenClosure
         }


    }
    foreach targetClass $targetClasses {


        $targetClass mixins add SimulationValueSupport


     }
     ## EOF value update support

    ######################################################
    ## Bit Value Update Support 
    ##  - Idea: Overwrite the getValue and Update Value methods to read/change bits from parent value
    ######################################################
    ::odfi::dev::hw::h2dl::Bit public method sim:getValue {{-instance ""}} {
        

        #puts "In Bit get value"
        ## Value Must be present in parents  which is the main value holder 
        set parentValue [[:parent] sim:getValue -instance $instance]

        if {$parentValue==""} {
            error "Get Bit value at index ${:index} of parent [:parent name get], no value"
        }
        #puts "In Bit getValue: $parentValue"

        ## Create new bit value 
        set bitValue [expr ([$parentValue getValue] >> ${:index}) & 0x1]

        ## Return 
        return [::odfi::dev::hw::h2dl::sim2::SimulationValue new -value $bitValue]

        ## Set value 
        #:sim:setValue $bitValue
        #return [:sim:getValue]

     }

     ::odfi::dev::hw::h2dl::Bit public method sim:setValue {value {-now false} {-forced false}  {-instance ""} } {

         

        #puts "Setting value $value on Bit"
        #return next

        ## Value Must be present in parents  which is the main value holder 
        set currentValue [[:parent] sim:getValue -instance $instance]
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


    ######################################################
    ## AST Blocking Update support
    ######################################################

    
    ## Blocking Update is schedulable, and immediate schedule
    ## Schedule Run is meant to Perform the update 
    ################################# 
    odfi::dev::hw::h2dl::ast::ASTBlockingAssign mixins add ImmediateSchedulable
    odfi::dev::hw::h2dl::ast::ASTBlockingAssign public method run {simulator currentTime {-instance ""}} {



        #puts "Performing NB Update on [:child 0]"
        set targetAssignee [:child 0]
        set expression     [:child 1]


        ## If no instance was provided try to find one 
        if {$instance==""} {
            set instance [$targetAssignee findFirstInstanceInHierarchy]
        }

        #[$targetAssignee name get]
        puts "Blocking Updating Value for [$targetAssignee info class] -> $instance "

        ## Get Expression Value 
        #set newValue [$expression sim:getUpdateValue]
        set newValue [$expression sim:updateValue -instance $instance]

        ## If no new value, just do nothgin!
        if {$newValue != ""} {
            #puts "Blocking Updating Value for [$targetAssignee info class] [$targetAssignee name get] -> $newValue "

            $targetAssignee sim:setValue [$newValue getValue]  -instance $instance
            #$targetAssignee sim:mergeValues
        }
        

        return 

    }


    ## Add Support for immediate value update to = 
    ##########
    nx::Class create BlockingUpdateSimSupport {

        odfi::dev::hw::h2dl::ValueHolder mixins add BlockingUpdateSimSupport

        ## Let normal work, and look for updatable values on the expression side 
        :public method = args {


            set astNode [next]

            return $astNode

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

    ######################################################
    ## AST Non Blocking Update support
    ######################################################

    
    ## Non  Blocking Update is schedulable, and immediate schedule
    ## Schedule Run is meant to Perform the update of the values on the right side of the expressions 
    ################################# 
    odfi::dev::hw::h2dl::ast::ASTNonBlockingAssign mixins add ImmediateSchedulable
    odfi::dev::hw::h2dl::ast::ASTNonBlockingAssign public method run {simulator currentTime {-instance ""}} {

        ## Procedure 
        ##  1. update the value using existing one on the right side
        ##  2. Set value to the assignee at the end of the phase
        set targetAssignee [:child 0]
        set expression     [:child 1]

        #[$targetAssignee name get]
        #puts "ASTNonBlockingAssign Updating Value for [$targetAssignee info class] and expression [$expression info class] "

        ## Get Expression Value 
        #set newValue [$expression sim:getUpdateValue]
        set newValue [$expression sim:updateValue -instance $instance]

        ## If no new value, just do nothgin!
        if {$newValue != ""} {
             #puts "IN NB: $instance"
            #puts "----> $newValue"
            $simulator scheduleClosure $currentTime {
                set target <% return $targetAssignee %> 
             #   puts "Merging Non blocking value on [$target info class], value instance <% return $instance %>"
                <% return $targetAssignee %> sim:setValue <% return [$newValue getValue] %>  -instance <% return $instance %>
            }

        }
       



    }

    ## Posedge Support 
    ############################
    odfi::dev::hw::h2dl::Posedge mixins add Schedulable
    odfi::dev::hw::h2dl::Posedge public method run {simulator currentTime {-instance ""}} {
        puts "Posedge is running on $instance"

        ## FIXME ? Let nodes schedule themselves??
        [:shade odfi::dev::hw::h2dl::sim2::Schedulable children] foreach {
                    #puts "---> Found schedulable [$it info class]"

                    set sNode [odfi::dev::hw::h2dl::sim2::ScheduleOnInstance new -instance $instance -node $it]

                    ${simulator} schedule $sNode

                    #$it schedule $simulator ${:currentTime} 
        }
        #next
    }
    odfi::dev::hw::h2dl::Posedge public method +build args {


        #puts "********* BUILDING Posedge with simulation interface: [[:signal get] info class]  ****************"



        ## Lookout for Signal changing its value
        set signal [:signal get]
        :addChild $signal
        $signal sim:onValueUpdate -instance * {

            set posedge <% return [current object] %>
            if {[:getValue]==1 && [:getPreviousValue]==0} {
            
                ## A value was updated to 1, which means, we must activate for this instance 
                set signal [:parent]
                set instance [:findFirstInstanceInHierarchy]
                #puts "**** Posedge is to be activated. Parent is [$signal name get], and value references an Instance: $instance"
                
                set sNode [odfi::dev::hw::h2dl::sim2::ScheduleOnInstance new -instance $instance -node $posedge]
                $sNode nextTime set 0

                ${odfi::dev::hw::h2dl::sim2::currentSimulator} schedule $sNode

                return 
                
            }

            

        }

        return 

    }

    ## Negedge Support 
    ############################
    odfi::dev::hw::h2dl::Negedge mixins add Schedulable
    odfi::dev::hw::h2dl::Negedge public method run {simulator currentTime {-instance ""}} {
        puts "Negedge is running on $instance"

        ## FIXME ? Let nodes schedule themselves??
        [:shade odfi::dev::hw::h2dl::sim2::Schedulable children] foreach {
                    #puts "---> Found schedulable [$it info class]"

                    set sNode [odfi::dev::hw::h2dl::sim2::ScheduleOnInstance new -instance $instance -node $it]

                    ${simulator} schedule $sNode

                    #$it schedule $simulator ${:currentTime} 
        }
        #next
    }
    odfi::dev::hw::h2dl::Negedge public method +build args {


        puts "********* BUILDING Negedge with simulation interface: [[:signal get] info class]  ****************"



        ## Lookout for Signal changing its value
        set signal [:signal get]
        :addChild $signal
        $signal sim:onValueUpdate -instance * {

            set posedge <% return [current object] %>
            if {[:getValue]==0 && [:getPreviousValue]==1} {
            
                ## A value was updated to 1, which means, we must activate for this instance 
                set signal [:parent]
                set instance [:findFirstInstanceInHierarchy]
                puts "**** Negedge is to be activated. Parent is [$signal name get], and value references an Instance: $instance"
                
                set sNode [odfi::dev::hw::h2dl::sim2::ScheduleOnInstance new -instance $instance -node $posedge]
                $sNode nextTime set 0

                ${odfi::dev::hw::h2dl::sim2::currentSimulator} schedule $sNode

                return 
                
            }

            

        }

        return 

    }

    #########################################
    ## AST Logic Updates 
    ##  - Basic Rule: Read values using geValue, write using getUpdateValue
    ###########################################

    proc valueUpdaterBuilder {forClass updaterBody} {

        nx::Class create ${forClass}SimValueUpdater {
            upvar updaterBody updaterBody
            :public method updateValue {{-instance ""}} $updaterBody

        }

        $forClass domain-mixins add ${forClass}SimValueUpdater -prefix sim
    }

    valueUpdaterBuilder ::odfi::dev::hw::h2dl::ast::ASTConstant {
        #puts "IN Overload os cons"
        return [:sim:getValue]
    }
    ::odfi::dev::hw::h2dl::ast::ASTConstant method init args {
        next 
        :sim:setValue ${:constant}
    }
    
    valueUpdaterBuilder ::odfi::dev::hw::h2dl::ast::ASTNegate {

        

        set valueSource [:child 0]

        ## Get Value 
        #################
        set value [$valueSource sim:getValue -instance $instance]

        ## Create New Value 
        #########################
        if {[$valueSource width get]==1} {
            set negated [expr !int([$value getValue])]
        } else {
            set negated [expr ~int([$value getValue])]
        }

        ## Store 
        ##################
        #:sim:setUpdateValue $negated

        return [::odfi::dev::hw::h2dl::sim2::SimulationValue new -value $negated]
        
       
    }


     valueUpdaterBuilder ::odfi::dev::hw::h2dl::ast::ASTAdd {

        #puts "In ADD Update "

        ## Left and right values 
        set left [:child 0]
        set right [:child 1]
        #catch {$left sim:updateValue}
        #catch {$right sim:updateValue}


        ## Value Objects
        set valLeft  [$left  sim:updateValue -instance $instance]
        set valRight [$right sim:updateValue -instance $instance]

        #puts "Left is [$left info class] -> $valLeft -> $instance" 

        ## Get real values or 0 if no available
        set vl [expr {$valLeft == ""} ? 0 : [$valLeft getValue]]
        set vr [expr {$valRight == ""} ? 0 : [$valRight getValue]]


        #puts "-- in add $valLeft $valRight"
        set resVal [expr $vl + $vr]

        return [::odfi::dev::hw::h2dl::sim2::SimulationValue new -value $resVal]



        ## Value Objects
        set valLeft  [$left shade ::odfi::dev::hw::h2dl::sim2::SimulationValue child 0]
        set valRight [$right shade ::odfi::dev::hw::h2dl::sim2::SimulationValue child 0]

        ## Get real values or 0 if no available
        set vl [expr {$valLeft == ""} ? 0 : [$valLeft getValue]]
        set vr [expr {$valRight == ""} ? 0 : [$valRight getValue]]


        puts "-- in add $valLeft $valRight"
        set resVal [expr $vl + $vr]

        return [::odfi::dev::hw::h2dl::sim2::SimulationValue new -value $resVal]

     }

     valueUpdaterBuilder ::odfi::dev::hw::h2dl::ast::ASTAnd {

        #

        ## Left and right values 
        set left [:child 0]
        set right [:child 1]

        #puts "In ADD Update $left ([$left info class]), $right ([$right info class])"

        ## Left and Right could be operators
        if {[odfi::common::isClass $left ::odfi::dev::hw::h2dl::ast::ASTOperator]} {
            set valLeft [$left sim:updateValue  -instance $instance]
        } else {
            set valLeft  [$left shade ::odfi::dev::hw::h2dl::sim2::SimulationValue child 0]
        }
        if {[odfi::common::isClass $right ::odfi::dev::hw::h2dl::ast::ASTOperator]} {
            set valRight [$right sim:updateValue  -instance $instance]
        } else {
            #puts "------ fetchign val right from simulation value node: [$right shade ::odfi::dev::hw::h2dl::sim2::SimulationValue child 0] "
            set valRight  [$right shade ::odfi::dev::hw::h2dl::sim2::SimulationValue child 0]
        }

        #catch {$left sim:updateValue}
        #catch {$right sim:updateValue}

        ## Value left 
        #puts "--> Values ($valLeft) <-> ($valRight)"

        #set valLeft  [$left shade ::odfi::dev::hw::h2dl::sim2::SimulationValue child 0]
        #set valRight [$right shade ::odfi::dev::hw::h2dl::sim2::SimulationValue child 0]

        if {$valLeft == "" || $valRight == ""} {
            return ""
        }

        set resVal [expr [$valLeft getValue] & [$valRight getValue]]

        return [::odfi::dev::hw::h2dl::sim2::SimulationValue new -value $resVal]

     }

     valueUpdaterBuilder ::odfi::dev::hw::h2dl::ast::ASTBitOr {

        #puts "In ADD Update "

        ## Left and right values 
        set left [:child 0]
        set right [:child 1]
        catch {$left sim:updateValue  -instance $instance }
        catch {$right sim:updateValue  -instance $instance}

        ## Value left 

        set valLeft  [$left shade ::odfi::dev::hw::h2dl::sim2::SimulationValue child 0]
        set valRight [$right shade ::odfi::dev::hw::h2dl::sim2::SimulationValue child 0]

        if {$valLeft == "" || $valRight == ""} {
            return ""
        }

        set resVal [expr [$valLeft getValue] | [$valRight getValue]]

        return [::odfi::dev::hw::h2dl::sim2::SimulationValue new -value $resVal]

     }

     valueUpdaterBuilder ::odfi::dev::hw::h2dl::ast::ASTShiftLeft {

        puts "In SL"

        ## Left and right values 
        set left [:child 0]
        set right [:child 1]
        #catch {$left sim:updateValue}
        #catch {$right sim:updateValue}


        ## Value Objects
        set valLeft  [$left  sim:updateValue -instance $instance]
        set valRight [$right sim:updateValue -instance $instance]


        set resVal [expr [$valLeft getValue] << [$valRight getValue]]

        return [::odfi::dev::hw::h2dl::sim2::SimulationValue new -value $resVal]


     }
     valueUpdaterBuilder ::odfi::dev::hw::h2dl::ast::ASTCompare {

        ## Left and right values 
        set left [:child 0]
        set right [:child 1]
        #catch {$left sim:updateValue -instance $instance}
        #catch {$right sim:updateValue -instance $instance}

        ## Value left 

        set valLeft  [$left sim:updateValue -instance $instance]
        set valRight [$right sim:updateValue -instance $instance]

        puts "Comparing from left ($left) [$left info class] and instance is $instance, $valLeft == $valRight"

        if {$valLeft == "" || $valRight == ""} {
            return 0
        }

        set resVal [expr [$valLeft getValue] == [$valRight getValue]]

        return [::odfi::dev::hw::h2dl::sim2::SimulationValue new -value $resVal]

     }


     valueUpdaterBuilder ::odfi::dev::hw::h2dl::ast::ASTIf {


        ## First Child: Condition expression
        set condition [:child 0]

        ## Second Child: Body 
        set body [:child 1]

        ## Process:
        ## - Test Condition
        ## - If OK, get body's value
        ## - If not, get value from else if any 
        set conditionValue [$condition sim:updateValue -instance $instance]
        #puts "Condition: [$condition info class]"
        #puts "Condition returns: [$conditionValue getValue]"
    
        if {[$conditionValue getValue]!=0} {

            set bodyValue [$body sim:updateValue -instance $instance]
            #puts "-> Val: [$bodyValue getValue]"

            return [::odfi::dev::hw::h2dl::sim2::SimulationValue new -value [$bodyValue getValue]]

        } else {

            set else [:child 2]
            set elseBody [$else child 0]

            #puts "--> in Else [$else info class], body  is [$elseBody info class]"

            set elseValue [$elseBody sim:updateValue -instance $instance]
            #puts "--> in Else [$else info class], body  is [$elseBody info class], value $elseValue"

            return [::odfi::dev::hw::h2dl::sim2::SimulationValue new -value [$elseValue getValue]]
        }


     }

     valueUpdaterBuilder ::odfi::dev::hw::h2dl::ast::ASTSelect {

        ## Left is the source 
        ## Right is the range 
        set source [:child 0]
        set range  [:child 1]

        set start [[[$range child 0] sim:updateValue -instance $instance] getValue]
        set stop  [[[$range child 1] sim:updateValue -instance $instance] getValue]
        set size [expr abs($stop - $start)+1]

        ## Get Value of source 
        ## Extract from start to stop
        set sourceValue [[$source sim:getValue -instance $instance] getValue]

        
        set fullmask  0xFFFFFFFFFFFFFFFF
        set sizeMask  [expr  $fullmask >> (64-$size)]

        #puts "Size mask: [format %x $sizeMask]"

        set extracted   [expr ($sourceValue >> $start) & $sizeMask ]
        return [::odfi::dev::hw::h2dl::sim2::SimulationValue new -value $extracted]
     }

     ###############################################
     ## Reset Stuff 
     ###############################################
     ::odfi::dev::hw::h2dl::Reset +builder {

        #puts "(SIM) Building Reset Handler son $expr [$expr info class] -> ${:currentShading} -> [[$expr children] size]"

        :object variable -accessor public +sim_active false

        ## Idea: 
        ##   1. Listen to all changeable values in expression to update expression result when needed
        ##   2. Use the Forced Value interface to forced value during reset time

        ## Base Signal
        set signal [:parent]


        ${expr} shade ::odfi::dev::hw::h2dl::Signal walkBreadthFirst {

            set reg $node 

            #puts "(SIM1) Listening on [$reg name get] for reset value"
          


            $reg sim:onValueUpdate -instance * {

                set resetExpression <% return $expr %>
                set resetNode       [$resetExpression   parent]
                set signalNode      [$resetNode         parent]
                set value           [current object]

                ## The target instance can be determined by the instance of the value 
                set targetInstance [$value findFirstInstanceInHierarchy]

                puts "(SIM2) Reset update because of value change, target instance is $targetInstance"

                ## 1. Update Simulation Value of Expression Node 
                ## 2. if 1/true, set signalNode value to 0
                set updateNow [$resetNode isAsync ? true : false]
                set resValue [[$resetExpression sim:updateValue -instance $targetInstance ] getValue]

                puts "(SIM2) --> reset res: $resValue, target node to reset: [$signalNode name get]"
                #puts "(SIM1) Value in reset expression was updated. Reset expression is: $resetExpression ([$resetExpression info class]), returned value: $resValue"

                if {$resValue} {
                    $signalNode sim:setValue 0 -now $updateNow -forced true  -instance $targetInstance
                    #$signalNode sim:setForcedValue 0 -now $updateNow
                    #$resetNode +sim_active set true

                     #puts "(SIM1) Forcing value of SR2 to 0"
                } else {
                    #$resetNode +sim_active set false
                    $signalNode sim:unForceValues  -instance $targetInstance

                    #puts "(SIM1) UnForcing value of SR2 to 0"
                }


            }

        }

     }

     ##########################################
     ## Connection 
     ###########################################

     ## Input: If not value, maybe there is one on the connection 
     valueUpdaterBuilder ::odfi::dev::hw::h2dl::Input {

        ## Get value 
        set val [:sim:getValue -instance $instance]

        ## None, Look for connection 
        ##  Two cases:
        ##   - There is a connection 
        ##   - There is no instance in the hierarchy, meaning we are on the master cell:
        ##      - 
        if {$val==""} {

            ## Look for instance in hierarchy
            set  currentInstance [:findFirstInstanceInHierarchy]
            if {$currentInstance==""} {
                puts "Signal is in Master"

                ## There should be a child, with the target instance 
                [:children] foreach {
                    puts "child IO: $it [$it info class]"
                }
                set foundChildren [[:children] filter { expr {[$it findFirstInstanceInHierarchy] == $instance}}]
                puts "Found children: [$foundChildren size]"

            } else {
                puts "Input belongs to instance $currentInstance"
            }
            puts "No value on input [:name get], belongs to instance $currentInstance"

            [:getParentsRaw] foreach {
                puts "P: [$it info class]"
            }
            ## Look for connection parent 

            set connection [:shade odfi::dev::hw::h2dl::Connection parent]
            if {$connection!=""} {
                puts "Found Connection in parent"
                set  sourceElement [$connection parent]
                puts "Source element: [$sourceElement info class]"
            }
        }
        return $val

     }

     ## Standard Connection
     odfi::dev::hw::h2dl::Connection +builder {

        set parent [:parent]
        #puts "Buld Connection from [$parent name get] to [[:child 0] name get]"

        ## - Listen on destination if we are an input 
        ## Outputs are meant to be written, not updated 
        if {[$parent isClass odfi::dev::hw::h2dl::Input]} {

             set signal [[:child 0]]

           

            ## Find Instance 
            ########
            set parentInstance [$parent findFirstInstanceInHierarchy]
            set signalInstance [$signal findFirstInstanceInHierarchy]
            if {$signalInstance==""} {
                set signalInstance *
            }
             puts "Connecting [$parent name get] ($parent) to a value of signal $signal [$signal info class] , with signal instance $signalInstance, set to parent instance $parentInstance"
           

            ## Listen on the signal
            ## If changed, set value on parent 
            $signal sim:onValueUpdate -instance $signalInstance "
                puts \"---------- Updated Signal \[\[:parent\] name get\] (\[:parent\]) , setting to $parent under instance $parentInstance-------------\"
                ## Copy the value, very IMPORTANT because new Value must fully belong to the IO to be able to detect the Instance
                $parent sim:setValue \[current object\] -now true -instance $parentInstance
            "
            
            ## Init Value 
            set signalValue [$signal sim:getValue -instance $signalInstance]
            if {$signalValue!=""} {
                $parent sim:setValue [$signalValue getValue] -instance $parentInstance
            }

            #set cCode [$signal sim:onValueUpdate -instance $signalInstance {
            #    set io <% return $parent %> 
            #    puts "----- Connection signal [[:parent] name get] updated, propagate to IO: $io -----\n\n"
            #}]
            #puts "Created connection with listener $cCode"

            ## The parent may be an IO referencing the IO of the master Instance 
            #set masterIO [$parent shade odfi::dev::hw::h2dl::Input parent]
            #puts "--> IO has a reference to a parent IO which should belong to a master: $masterIO [[$parent getParentsRaw] size]"
            #if {$masterIO!=""} {
             #   $parent sim:onValueUpdate {
              #      puts "IO updated, forwarding to master IO"
               #     <% return $masterIO %> sim:setValue [current object]
                #}
            #}
            
        }

        #puts "in sim builder"
     }


     ##########################################
     ## Master/Instance stuff  
     ###########################################

     ## Connect IOs to their master parent for the value monitoring
     odfi::dev::hw::h2dl::IO +builder {

        #puts "Building IO [:name get]"

        ## If the parent is an IO of the same type, take it as master IO 
        ## Make value change connection on both sides
        :onParentAdded {


            set masterIO [[:getParentsRaw] at end]
            set instanceContainer [:findFirstInstanceInHierarchy]
            #puts "Added parent to IO"

            if {[$masterIO isClass odfi::dev::hw::h2dl::Input]} {
                puts "IO [:name get] ([current object]) had another IO added as parent ($masterIO)"
               
                set co [current object]

                ## Listen on local changes and propagate to master IO  
                :sim:onValueUpdate -instance $instanceContainer {

                    set originalIO <% return $co %> 
                    set masterIO   <% return $masterIO %>
                    <% ::puts "bulding it $co " %>
                    puts "IO [$originalIO name get] ($originalIO) updated ->  forwarding to master IO [$masterIO name get]"
                    $masterIO sim:setValue [current object] -instance <% return $instanceContainer %>
                }

                

            } elseif {[$masterIO isClass odfi::dev::hw::h2dl::Output]} {

                puts "IO [:name get] ([current object]) had another IO added as parent ($masterIO), common"

                ## Listen on Master IO and propagate
                ## -instance $instanceContainer
                $masterIO sim:onValueUpdate -instance $instanceContainer  {

                    set originalIO <% return [current object] %> 
                    set masterIO   <% return $masterIO %>
                    puts "Master IO [$masterIO name get] ($masterIO) updated ->  forwarding to IO [$originalIO name get] ($originalIO)"
                    $originalIO sim:setValue [current object] -instance <% return $instanceContainer %>
                }

            }
        }
     }

}
