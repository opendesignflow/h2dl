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
package provide odfi::h2dl 2.0.0

package require odfi::language 1.0.0

package require odfi::attributes 2.0.0

package require odfi::log 1.0.0


namespace eval odfi::h2dl {
    
        


    odfi::language::Language define CONNECTING {

        #:connection : HW.Named name {
        #    
        #}

    }
    CONNECTING produceNX


    odfi::language::Language define HW {
        

        ## Elaboration Support 
        ###########################
        +type ElaborationSupport {
            
            :elaboration name {
                +var buildClosure ""

                +method build cl {
                    set :buildClosure [odfi::closures::newITCLLambda $cl]
                }

                +method elaborate args {
                    return [${:buildClosure} apply]
                }
            }

            +method elaborate name {

                ## Get master 
                set master [:master get]
                
                ## Look for name
                puts "looking for elaboration: $name, master is $master" 
                set allElabs [$master shade odfi::h2dl::Elaboration children]
                $allElabs foreach {
                    puts "Elab [$it name get]"
                }
                set elaboration [$master shade odfi::h2dl::Elaboration findChildByProperty name $name]
                if {$elaboration!=""} {
                    puts "Elaborating $elaboration"
                    return [$elaboration elaborate]
                }
            }
        }

        ## Base 
        +type H2DLObject : ElaborationSupport {

            +var file ""
            +var line ""
            +mixin ::odfi::attributes::AttributesContainer
            +mixin ::odfi::log::Logger -prefix log

            +method init args {
                next 
                :log:setPrefix [:info class]
                #set location  [odfi::common::findUserCodeLocation]
                #set :file [lindex $location 0]
                #set :line [lindex $location 1]

            }

            ## Common Stuff 
            ##############
            :comment value {

            }
            
            ## parent Searching
            ############
            +method getParentModule args {
                return [:findParentInPrimaryLine {$it isClass ::odfi::h2dl::Module}]
            }
        }

        +type Structural {

        }

        :+type Named  : H2DLObject  {
            
            :+var name false
            :+var description ""

            +method toString args {
                return "[:info class].${:name}"
            }
            
            ## Return only parents with Module hierarchy
            #+method formatHierarchyString separator {

             #   set parents [:shade odfi::h2dl::Module getPrimaryParents]
              #  return [[$parents map { return [$it name get]}] mkString $separator]

            #}

        }

        ## Logic Content 
        #####################
        :logic : H2DLObject  {

            ## Branching
            ##################

            ## IF // Else // Else If 
            :if : ::odfi::h2dl::Logic condition {
                +builder {
                    #puts "buildlocatino [::odfi::common::findFileLocation]"
                    set :condition [::odfi::h2dl::ast::buildAST [uplevel 3 [list subst ${:condition}]]]
                    :addChild ${:condition} 
                }
            }
            :elseif : ::odfi::h2dl::Logic condition {
                +builder {
                    set :condition [::odfi::h2dl::ast::buildAST [subst ${:condition}]]
                    :addChild ${:condition} 
                }
            } 
            :else : ::odfi::h2dl::Logic {

            } 


            #:if condition body {
#
 #           }

            ## test
            #:match : H2DLObject signal {
            #    :if value body  {


                #}
                #:else body {

                #}
            #}

            ## Case 
            :case : H2DLObject signals {
                +builder {
                    set :signals [odfi::flist::MutableList fromList [subst ${:signals}]]
                }
                :on : H2DLObject value {

                }
                :default {

                }
            }

        }
        


        ## Master / Instance 
        ######################

        ## This Type is a marker for an actual master instance 
        +type Master  : H2DLObject {

            +var baseClass "-"

            +method buildInstance node {
                next
                #puts "IN MASTER [:info class], configuring instance $node"
            }

            +method createInstance name {

                #puts "Creating Instance of [:info class]"
                set newNode [:doCreateInstance $name] 

               # puts "Creating Instance of [:info class], $newNode"

                $newNode object mixins add Instance
                catch {$newNode mixins delete Master}

                ## Set master in variable and as child of Instance
                $newNode master set [current object]
                [current object] addParent $newNode
                #$newNode addChild [current object]
                #$newNode addParent [current object]
                    
                #puts "Creating Instance of [:info class], $newNode"

                next $newNode
                return $newNode
                #next
                #return [${:baseClass} createInstance]
            }

            +method doCreateInstance name {
                next
            }
        }

        

        +type Instance : H2DLObject  {
            +var master ""



        }
        

        +type InstanceSupport {

            ## Filter out masters
            +method findFirstInstanceInHierarchy args {
                return [:findParentInPrimaryLine { expr {[$it isClass odfi::h2dl::Instance] && ![$it isClass odfi::h2dl::Master]}  }]
            }
        }



        ## IO / Signals 
        ####################
        +type Signal : Named {
            +mixin InstanceSupport
            +var  width  1
            +var  offset 0
            +var  type   digital
            
            ## Sub Elements: Bit
            ###############
            :bit : H2DLObject index  {
                +unique index
            }
            
            
            ## Size Utility
            #########
            +method size value {
                #puts "Defining size as $args"
                :width set $value
            }

            ## increase the width of the signal by one per default, or more if specified
            +method widen {{count 1}} {
                incr :width $count
               
            }
            
            ## decrease the width of the signal by one per default, or more if specified
            +method schrink {{count 1}} {
                incr :width -$count
            }
            

            ## Bit Mapping
            #########
            :bitMap expression name {
                +var wire ""
                +builder {
                    
                    ## Get Index/Range from Expression
                    #puts "Bit map expression ${:expression}"
                    set :expression [::odfi::h2dl::ast::buildAST ${:expression}]
                    
                    #puts "Bit map expression ${:expression} -> $expression"
                    
                    #exit
                    ## Create Wire
                    set mappedWire [[[:parent] parent] wire [[:parent] name get]_[:name get]] 
                    uplevel 4 "set [$mappedWire name get] $mappedWire"
                    #puts "Mapped wire is in [[$mappedWire parent] name get]"
                    
                    ## Set Size to wire 
                    if {[${:expression} isClass odfi::h2dl::ast::ASTRange]} {
                        $mappedWire width set [${:expression} getSize]
                    }

                    ## Create Assign construct, and move it to parent, to ease output generation
                    set assignNode [$mappedWire assign "[:parent] @ ${:expression}"]
                    #$assignNode setFirstParent [$mappedWire parent]
                    #$assignNode addParent $mappedWire

                    set :wire $mappedWire     
                }
            }

            ## Assignment 
            :assign : H2DLObject expression {
                 +builder {
                     set :expression [::odfi::h2dl::ast::buildAST ${:expression}]
                     :addChild ${:expression}

                 }
            }

            ## Io Transform 
            +method toOutput {{cl ""}} {
                :object mixins add ::odfi::h2dl::Output
                set :type "wire"
                if {$cl!=""} {
                    :apply $cl
                }
                ## Make sure we are in Module parent 
                #set moduleParent [:findParentInPrimaryLine {$it isClass ::odfi::h2dl::Module}]
               # $moduleParent addChild [current object]
            }
            
            ## Io Transform 
            +method toInput {{cl ""}} {
                :object mixins add ::odfi::h2dl::Input
                set :type "wire"
                if {$cl!=""} {
                    :apply $cl
                }
                
            }
            
            +method toInout {{cl ""}} {
                :object mixins add ::odfi::h2dl::Inout
                set :type "wire"
                if {$cl!=""} {
                    :apply $cl
                }
                
            }
            
            +method isInput args {
              
                return [expr {[:classMatchExpression ::odfi::h2dl::Input !::odfi::h2dl::Output !::odfi::h2dl::Inout] || [:hasMixin ::odfi::h2dl::Input]} ]
            }
            +method isOutput args {
               
                
                return [expr {[:classMatchExpression  ::odfi::h2dl::Output !::odfi::h2dl::Input !::odfi::h2dl::Inout] || [:hasMixin ::odfi::h2dl::Output]} ]
                
            }
            +method isInout args {
            
                
                return [expr {[:classMatchExpression ::odfi::h2dl::Inout !::odfi::h2dl::Output !::odfi::h2dl::Input] || [:hasMixin ::odfi::h2dl::Inout]} ]
            }
            
            +method matchDirection target {
            
                #puts "Matching directions of [:info class] to [$target info class]"
                catch {:object mixins delete ::odfi::h2dl::Input}
                catch {:object mixins delete ::odfi::h2dl::Output}
                catch {:object mixins delete ::odfi::h2dl::Inout}
                if {[$target isClass ::odfi::h2dl::Input]} {
                    :object mixins add ::odfi::h2dl::Input
                } elseif {[$target isClass ::odfi::h2dl::Output]} {
                   # puts "--> CHanging to output"
                    :object mixins add ::odfi::h2dl::Output
                } elseif {[$target isClass ::odfi::h2dl::Inout]} {
                    :object mixins add ::odfi::h2dl::Inout
                }
                #puts "--> now   [:info class]"
            }
        }

        +type WritableSignal : Signal {

            :reset expr {
                +var type "async"
                +method sync args {
                    set :type "sync"
                }
                +method async args {
                    set :type "async"
                }
                +method isSync args {
                    if {${:type}=="sync"} {
                        return true 
                    } 
                    return false
                }
                +method isAsync args {
                    if {${:type}=="async"} {
                        return true 
                    } 
                    return false
                }
                +builder {

                    puts "Building reset with expression ${:expr}"
                    set expr [::odfi::h2dl::ast::buildAST ${:expr}]
                    set :expr $expr

                    :addChild $expr

                    next 
                    return
                    ## FIXME: Idea: Go on all modifiable values on the expression, and add a listener
                    $expr shade ::odfi::h2dl::Register walkDepthFirst {

                        set reg $node 

                        puts "Listening on [$reg name get] for reset value"
                        $reg onChildAdded {

                            set c [:child end]

                        }

                    }
                }
            }

        }


        :+type IO : Signal {
            +var type "wire"
            +var connect ""


           
            
            +method register args {
                set :type "reg"
            }
            +method electrical args {
                set :type "electrical"
            }
            +method power value {
                set :type "power"    
            }

            ## Connection 
            :connection : Named signal {
                +builder {

                    #puts "Buildign IO connections of [:name get] with ${:signal} "
                    set baseSignal [:parent]

                    ## Options:
                    ##   - Target signal already has a connection, then take the name 
                    ##   - Target Signal and source Signal have the same parent, just use target signal name 
                    ##   - Target Signal and source Signal don't have the same parent, use the target's parent name prefixed to signal name to make signal look hierarchical
                    ## Checks: 
                    ##   - Check source and target signals are not the same direction

                    ## Signal may be a string, but then construct a dummy 
                    ###########
                    if {[catch {${:signal} isClass ::odfi::h2dl::Signal} res]} {
                        #puts "Connection by string -> $res"
                        set n ${:signal}
                        set :signal [::odfi::h2dl::Signal new]
                        ${:signal} name set $n 
                        ${:signal} attribute ::odfi::h2dl::dummy true 
                    }
                    
                    ## Get Actual Connection
                    #########
                    set actual [:shade ::odfi::h2dl::Connection firstChild]
                    if {$actual!=""} {
                        
                        set ourWidth [$baseSignal width get]
                        
                        puts "Adding connection to actual"
                        set actualConnectionTarget [$actual firstChild]
                        if {[$actualConnectionTarget isClass ::odfi::h2dl::Signal]} {
                            
                            ## Make sure there are enough bits to connect
                            set actualTargetWidth [$actualConnectionTarget width get]
                            set remainingWidth [expr  $ourWidth - $actualTargetWidth]
                            if {$remainingWidth<=0} {
                                :log:warning "Cannot connect [$baseSignal name get] to ${:signal} name get, nothing left to connect"
                                return
                            }
                            
                            ## Ok, then create a concat
                            ##########
                            puts "Creating range concat"
                            ## First: take a range of target
                            set targetRange [$actualConnectionTarget ast:range 0 [expr $remainingWidth -1]]
                            set resultConcat [${:signal}  ast:concat $targetRange]
                            set :name $resultConcat
                            :clearChildren
                            :addChild $resultConcat
                        }
                        
                    
                    } else {
                    
                        ## Set name 
                        #puts "Signal is: ${:signal} [${:signal} info class] "
                        if {[odfi::common::isClass ${:signal} ::odfi::h2dl::IO] || [${:signal} isClass ::odfi::h2dl::Signal]} {
                            
    
                           # puts "using signal "
                           
                            ## If parent from signal and base signal is same, just take the name of the signal
                            ## Otherwise, append the name of the target signal's parent
                            if {[${:signal} parent]!="" && ([[$baseSignal parent] getPrimaryTreeDepth] == [[${:signal} parent] getPrimaryTreeDepth])} {
                                
                                if {[[${:signal} parent] name get]==""} {
                                    set :name [${:signal} name get]
                                } else {
                                    set :name [[${:signal} parent] name get]_[${:signal} name get]
                                }
                               
                            } else {
                                set :name [${:signal} name get]
                                #set :name [[${:signal} parent] name get]_[$signal name get]
    
                                
                            }
    
                            ## Resolve port direction
                            if {[$baseSignal isClass ::odfi::h2dl::IO] && [${:signal} isClass ::odfi::h2dl::IO]} {
                                ${:signal} matchDirection $baseSignal
                                #if {[$baseSignal isOutput] && [${:signal} isInput]} {
                                #    ${:signal} toOutput
                                #}
                            }
    
                            ## Add target signal 
                            :addChild ${:signal}
    
                        } else {
                            # Use as is
                            set :name ${:signal}
                        }
                        ## Check Signal 
                        #if {[[:parent]}
                        
                        ## Use name to make sure the containing module has a signal for connection
                        ##############
                        ::ignore {
                            if {[::odfi::common::isObject [:name get]]} {
                                
                                set  target [:name get]
                                if {[$target isClass ::odfi::h2dl::Bit]} {                 
                                    set target [$target parent]  
                                } elseif {[$target isClass ::odfi::h2dl::ast::ASTRangeSelect]} {            
                                    set rangeTarget [$target firstChild]
                                    set target      $rangeTarget         
                                }
                                
                                ## Check there is a signal for target in parent
                                set module [[[:parent] parent] getParentModule]
                                set signal [$module shade ::odfi::h2dl::Signal findChildByProperty name [$target name get]]
                                if {$signal==""} {
                                     puts "Adding Signal  [$target name get] for connection in module [$module name get]"
                                     $module wire [$target name get] {
                                        :width set  [$target width get]
                                    }
                                }
                            } else {
                                ## Check there is a signal for target in parent
                                set module [[[:parent] parent] getParentModule]
                                set signal [$module shade ::odfi::h2dl::Signal findChildByProperty name  [:name get]]
                                if {$signal==""} {
                                     puts "Adding Signal  [:name get] for connection in module [$module name get]"
                                     $module wire [:name get] {
                                    }
                                }
                                
                            }
                        }
                    
                    }

                    
                    
                    
                }
            }
            ## EOF Connection definition
            
            ## If Connection is in parents or child, then signal has a connection
            +method hasConnection args {
                if {[:shade odfi::h2dl::Connection parent]!="" || ![:shade odfi::h2dl::Connection isLeaf]} {
                    return true 
                } else {
                    return false 
                }
            }


            ## Push IO 
            ##############
            +method copyInto targetParent {
                
                ## Copy
                set   resultSignal   [[current object] copy]
                $resultSignal name set [[current object] name get]
                
                ## Copy Attributes 
                :shade odfi::attributes::AttributeGroup eachChild {
                    #puts "Copying attribute group [$it name get] for [$resultSignal name get]"
                    $resultSignal addChild [$it copy]
                    
                }
                
                $targetParent addChild $resultSignal
                
                return $resultSignal
                
            }
            
            ## For now, just push up to parent
            +method pushUp {{prefix ""} {cl ""} } {

                set sourceParent [:parent]
                set source [current object]
                set targetParent [$sourceParent shade ::odfi::h2dl::Module parent]

                #puts "Push up of IO with name [$source name get]"
                #puts "push to target parent: $targetParent, source parent: $sourceParent"
                
                set resultSignal ""
                if {$targetParent!=""} {
                    
                    ## Look if exsiting in parent

                    ## If Existing into parent, force our direction
                    ## Target in parent has either the same name of an equivalent attribute
                    set iosearchtime [time {
                        set ios [$targetParent shade ::odfi::h2dl::IO children]
                        
                    }]
                    set searchtime [time {
                       
                        set inParent [$ios findOption {
                            if {([$it name get] == [$source name get]) || [$it attributeMatch ::odfi::h2dl name [$source name get]] } {
                                return true
                            } else {
                                return false
                            }
                        }]
                    }]
                    #puts "search time: $iosearchtime -> $searchtime"
                 
                    #set inParent [$targetParent shade ::odfi::h2dl::IO findChildByProperty name [:name get]]
                    
                    if {[$inParent isDefined]} {
                        
                        set inParentIO [$inParent get]
                        $inParentIO width set [:width get]
                        $inParentIO matchDirection $source
                        set  resultSignal $inParentIO
                        
                    } else {
                    
                        ## Copy IO 
                        
                        set   resultSignal   [[current object] copy]
                        $resultSignal name set [[current object] name get]
                       
                        puts "Target new IO has name  1 [$resultSignal name get] [$resultSignal info class]"
    
                        ## Rename 
                        if {$prefix!=""} {
                            $resultSignal name set ${prefix}_[$resultSignal name get]
                        }
    
                        
                    }
                    
                    
                    ## Finalisation
                    #$targetParent apply {
                    #    set resultSignal [:input [$sourceParent name get]_[$source name get] $cl]
                    #}

                    

                    # puts "Target new IO has name 2 [$resultSignal name get]"

                    ## Copy Attributes 
                    :shade odfi::attributes::AttributeGroup eachChild {
                        #puts "Copying attribute group [$it name get] for [$resultSignal name get]"
                        $resultSignal addChild [$it copy]
                    }
                    
                    ## Add to parent if necessary once object is ready
                    if {![$inParent isDefined]} {
                    
                        $targetParent addChild $resultSignal
                    }
                    
                    ## Make connection 
                    #$resultSignal connection $source 
                    $source connection $resultSignal
                   
                }
                    

            
            }

            ## For now, just push up to parent
            +method pushThrough count {

                set sourceParent [:parent]
                set source [current object]
                set targetParent [$sourceParent parent]
                set resultSignal ""
                set currentCount 0
                set currentName [$sourceParent name get]_[$source name get]
                while {$currentCount<$count && $targetParent!=""} {
                    
                    set currentName [$sourceParent name get]_[$source name get]

                    ## Add to target parent 
                    $targetParent apply {
                        set resultSignal [:input $currentName {

                        }]
                    }

                    ## Make connection 
                    $source connection $resultSignal

                    ## Go to next 
                    set targetParent    [$targetParent parent]
                    set source          [$resultSignal]
                    set sourceParent    [$resultSignal parent]
                    incr currentCount

                    
                    #puts "Push current name $currentName"

                }
            }
        }
        
        :module : Named name {
            
            #+mixin verilog <- odfi::h2dl::verilog::VerilogGen
            +mixin Master

            +mixin ::odfi::h2dl::Logic
            +mixin ::odfi::h2dl::Structural
            +expose name
            +exportTo         ::odfi::h2dl::Module
            +exportToPublic

            #+builder {
               # puts "Inside Module builder [:info class]"
            #}

            ## Master behavior
            #######################

            ## When a parent is added, if it is another module, then create an instance instead
            ## Same After building if we are in a hierarchy
            ## !! Ignore this for now, because unsure it is a whished behavior
            +builder {
                #return 
                
                ## If an IO was added, add it to the instances
                #########
                :onChildAdded {
                    set child [:lastChild]
                    if {[$child isClass ::odfi::h2dl::IO]} {
                        [:shade ::odfi::h2dl::Instance parents] foreach {
                            :transferIOToInstance $it $child 
                        }
                    }
                }
                
                ## IGNORE THis for now
                set postBuildCl {
                    
                    lassign  [::odfi::common::findFileLocation] f l frame up           
                    #puts "module build loc:  [::odfi::common::findFileLocation] , current level [info level]"
                   
                    ::set p [:noShade parent end]
                    #puts "module parent: $p"
                    if {$p!="" && [$p isClass ::odfi::h2dl::Module] && ![:isClass odfi::h2dl::Instance]} {
                        ::set instance [:createInstance  [:name get]_I]
                        #puts "created instance: $instance -> [$instance info lookup methods] "
                        $p addChild $instance
                        uplevel $up [list ::set  [:name get] $instance]
                    }
                
                    return
                    set p [:noShade parent end]
                    
                    ## Only if added to a Module, and we are not a module ourselves already
                    if {$p!=""} {
                        #puts "*** Module added a parent [$p info class]"
                        if {[$p isClass odfi::h2dl::Module] && ![:isClass odfi::h2dl::Instance]} {

                            set instance [:createInstance [:name get]_I]
                            #[current object] detach
                            #$p removeChild [current object]
                            $p addChild $instance
                            
                            ## Update variable
                        }
                    }
                }
                #:onParentAdded $postBuildCl
                :onBuildDone $postBuildCl
            }
            
            +method instanceFromFile f {
            
                set moduleName [lindex [split [file tail $f] .] 0]
                puts "instance from: $moduleName"
                
                rsource $f 
                
                set inst [[::set $moduleName] getLatestInstance]
                if {$inst==""} {
                    set inst [[::set $moduleName]  createInstance ${moduleName}_I]
                    
                }
                uplevel set $moduleName $inst
                
                
            }
            
            ## get latests instnace: instances are parents of the module definition
            +method getLatestInstance args {
                return [:shade ::odfi::h2dl::Instance parent end]
            }
            
            +method getAllInstances args {
                return [:shade ::odfi::h2dl::Instance parents]
            }
            
            ## Wiping module will detach it and also all the instances
            +method wipe args {
                
                [:getAllInstances] foreach {
                    $it detach
                    $it clearChildren
                }
                :detach
            
            }

            +method transferIOToInstance {instance io} {
                
                set nio [$io copy]
                
                $nio clearParents
                $nio clearChildren

                ## Rebuild 
                $nio +build

                ## Add to current node 
                $instance addChild $nio

                ## Set base IO as parent to find back original definition later
                $nio addParent $io

                ## Res Set IO as class variable again
                $instance object variable -accessor public [$nio name get] $nio

                ## Transfer Existing Connections 
                ## Only the ones specified by attribute
                ################
                ::ignore {
                    $io shade odfi::h2dl::Connection eachChild {
                    {conn i} => 
                        if {[$conn parent]==$io} {
                            $conn detach
                            $nio addChild $conn 
                        } else {
                            $conn clearChildren
                            $conn addChild $nio
                        }
                    }
                }
                if {[$io hasAttribute ::odfi::h2dl connection]} {
                   # $nio connection [$io getAttribute ::odfi::h2dl connection]
                }
                

                ## Transfer Attributes 
                ###############
                $io shade odfi::attributes::AttributeGroup eachChild {
                    {attrs i} => 
                    #puts "Found Attributes Container on base IO"
                    $nio addChild $attrs
                } 
                
                next
            }

            +method doCreateInstance name {
                #puts "INSIDE DO CREATE INSTANCE $name"
                set newInstance [[:info class] new -name $name]
                
                ## Copy/Import all the IOS
                [:shade odfi::h2dl::IO children] foreach {

                    ## Copy and detach
                    ################
                    :transferIOToInstance $newInstance $it 
                      
                }
                #puts "EOF DO CREATE INSTANCE $name"
                return $newInstance
            }

           
            +method getModelInstanceName args {
                return ${:name}
            }

            ## Submodules  instantiation
            ##################
            
            +method instantiate {module keyword variableName} {
                
                ## Create instance 
                set instance [$module createInstance $variableName]
                
                ## Add 
                :addChild $instance 
                
                ## Set variable in parent context
                uplevel [list set $variableName $instance]
            }
            
            #:submodule : Module 

            ## IO and signals 
            ##################
            
            :input : IO name {
               +expose name  
               +exposeToObject name            
            }
            
            :output : IO name { 
               +expose  name
               +exposeToObject name  
               +mixin WritableSignal               
            }
            
            :inout : IO name {
                +expose  name
                +exposeToObject name  
                +mixin WritableSignal           

                :highz expr {
                    
                    +builder { 
                        set :expr [::odfi::h2dl::ast::buildAST ${:expr}]
                        :addChild ${:expr}

                        next            
                    }
                }

            }
            
            ## Power Connections
            #############
            :power : IO name {
                +expose name  
                +var value GND
                
                +builder {
                    set :type power
                }
                
               
            
            }
            ## Signals helpers
            ############
            +method onSignals {match cl} {
                [:shade ::odfi::h2dl::Signal findChildrenByProperty name $match] foreach $cl
                
            }
            
            ## IO Connection
            ##############
            
            
            
            +method connect {ioName keywork signal} {
                
                ## Left Connect
                ##########
                set left [::odfi::flist::MutableList new ]
                set leftSize 0
                [:shade ::odfi::h2dl::IO findChildrenByProperty name $ioName] foreach {
                    $left += $it
                    incr leftSize [$it width get]
                }
                puts "Left: [$left size] "
                
                #if {[string first * $ioName]>=0} {
                #    
                #} else {
                #    $left += $ioName
                #}
                
               
                ## Right Size
                ## Right can be a search match too
                #######
                if {![::odfi::common::isObject $signal]} {
                    set right [uplevel [list :shade ::odfi::h2dl::Signal findChildrenByProperty name $signal ]]
                    set right [$right asTCLList]
                    set rightSize 0
                    foreach r $right { incr rightSize [$r width get]}
                    puts "Right: [llength $right] $right"
                } else {
                
                    set right $signal  
                }
                
                ## Right can be an expression
                ############
                if {[$right isClass ::odfi::h2dl::ast::ASTNode]} {
                    
                    $left foreach {
                        $it connection $right
                    }
                    return
                } else {
                    set rightSize [$signal width get]
                }
                
                
                ## Checks
                #############
                if {$leftSize!=$rightSize} {
                    error "Cannot connect  $ioName to $signal, bit sizes differ (left=$leftSize,right=$rightSize)"
                }
                
                ## Cases:
                ## Left has less signals than right
                if {[$left size]<=[llength $right]} {
                    
                    set rightIndex 0
                    $left foreach {
                        {leftSignal leftI} => 
                            repeat [expr [llength $right]/[$left size]] {
                                
                                $leftSignal connection [lindex $right $rightIndex]
                                
                                incr rightIndex
                            }
                    }
                    
                } else {
                    
                    ## Go over left, and connect to right bits
                    set currentRight 0
                    set currentRightBit 0
                    $left foreach {
                       {io i} => 
                       
                            set rightSignal [lindex $right $currentRight]
                            
                       
                           if {[$rightSignal width get]==1} {
                               $io connection $rightSignal
                               incr currentRight
                               set currentRightBit 0
                           } else {
                               $io connection [$rightSignal bit $currentRightBit]
                               incr currentRightBit
                               if {$currentRightBit>[$rightSignal width get]} {
                                 incr currentRight
                                 set currentRightBit 0
                               }
                           }
                          
                    }
                    #error "Left has more signals than right, not supported yet"
                }
                
                return
                if {[$left size]!=$rightSize} {
                    error "Cannot connect $ioName to $signal, size differ (left=[$left size],right=$rightSize)"
                }
                
                $left foreach {
                    {io i} => 
                    if {[$signal width get]==1} {
                        $io connection $signal
                    } else {
                        $io connection [$signal bit $i]
                    }
                       
                }
                
                return
                
                set io [:shade ::odfi::h2dl::IO findChildByProperty name $ioName]
                if {$io==""} {
                    error "Cannot Connect io $ioName from [:name get] , not found"
                } else {
                    $io connection $signal
                }
                
            }
            
            +method connectMap map {
                
                foreach {io KW target} $map {
                    
                    ## Get io
                    set foundIO [:getIO $io] 
                    if {$foundIO==""} {
                        :log:warning "Cannot map connection $io, not found"
                    }
                    
                    ## Subst target
                    set target [subst $target]
                    
                    $foundIO connection $target
                    
                    
                }
            
            }
            
            ## Creates Wires in parent context for non connected IOs, and connect to them
            +method wiresForNotConnected args {
                
                set target [:parent]
                :shade ::odfi::h2dl::IO eachChild {
                    
                    if {![$it hasConnection]} {
                        set w [$target wire [:name get]_[$it name get] [list :width set [$it width get]  ] ]
                        uplevel 2 set [:name get]_[$it name get] $w
                        $it connection $w
                    }
                    
                }
                
            }
            
            +method pushUpAll filter {
                
                ## Source and target
                set sourceModule [current object]
                
                ## Get Parent Module
                set targetParent [$sourceModule shade ::odfi::h2dl::Module parent]
                
                if {$targetParent==""} {
                    :log:warn "Cannot call push up All if no parent module is present"
                    return
                }
                
                ## Get selection
                puts "filter: $filter"
                set selection [[:shade ::odfi::h2dl::IO children] filter $filter]
                
                if {[$selection size]==0} {
                    :log:warn "Cannot call push up All if no IOs match selection $filter"
                }
                
                puts "Processing push all into [$targetParent name get]..."
                ## FOreach in selection, look in parent IOs for a match
                ## Do this reverse to go once through parent IO and pop out of selection the found items
                ## This way we only go through a decreasing list repeatidely
                ## This function should be performant enough
                set targetIOS [$targetParent shade ::odfi::h2dl::IO children]
                $targetIOS foreach {
                    {targetIO i} => 
                        
                        ## Search in selection for io with same name
                        set found [$selection findOption {expr {[$it name get] == [$targetIO name get]}} -remove true]
                        puts "Found: [$found isDefined] -> selection size now=[$selection size]"
                        
                        ## If found, match directions and sizes
                        if {[$found isDefined]} {
                            $targetIO matchDirection    [$found get]
                            $targetIO width set         [[$found get] width get]
                        }
                        
                }
                
                ## Selection has now a remaining set of IOS to create
                $selection foreach {
                    {createIO i} => 
                        
                        puts "Creating [$createIO name get] into parent"
                        
                        ## Copy  into parent
                        set newIO [$createIO copyInto $targetParent]
                        
                        ## Make connection
                        $createIO connection $newIO
                     
                }
               
                
                
            }
            
            
            +method getIO name {
                return [:shade ::odfi::h2dl::IO findChildByProperty name $name]
            }
            +method findAllIO match {
                return [:shade ::odfi::h2dl::IO findChildrenByProperty name $match]
            }
            
            ## Signals
            ###################

            :register : WritableSignal name {
                +expose name
                +exportTo ::odfi::h2dl::Logic
                
            }

            :wire : Signal name {
                +expose name
                +exportTo ::odfi::h2dl::Logic
                
                
               
            }

            ## Named Value is like a constant with a name 
            ## Can map to Verilog Define or localparam for example
            :namedValue name value {
                +exportTo ::odfi::h2dl::Logic
            }

            :+type SyncBlock : Logic  {

                :reset signal {
                    
                }
                
                +method implementReset res {
                    ## Setting Up Reset 
                    puts "Setting up reset for Stage $res -------------------------"
                    #set :reset $res
                    :reset $res {

                    }
                    
                    ## Content 
                    #set content [:shade odfi::h2dl::ast::ASTNode children]
                    set content [:shade {$it notClass odfi::h2dl::Reset} children]
                     $content foreach {
                        $it detachFrom [current object] 
                    }
                    
                    #$fullContent foreach {
                    #    puts "Full Content to move: [$it info class]"
                    #}
                    
                    ## Add Reset Values for Registers  to Reset if 
                    ## Rest of the logic for the else node
                    :if {$res == 0} {
    
                        set alreadyReset {}
                        $content foreach {
    
                            
    
                            ## Search in content for all the NB assign to put them as reset value 
                            $it walkDepthFirstPostorder -level 1 {
                                if {[$node isClass odfi::h2dl::ast::ASTNonBlockingAssign]} {
    
                                    ## If the target value is already a child of current if, do nothing 
                                    if {[lsearch $alreadyReset [$node firstChild]]==-1} {
                                        [$node firstChild] <= 0
                                        lappend alreadyReset [$node firstChild]
                                    
                                    }
                                    return false 
                                    
                                }
                                return true
                            }
                            
                        }
                    }
                    :else {
                        $content foreach {
                            #$it detachFrom 
                            #puts "Setting first parent: [$it info class] [[current object] info class]"
                            $it setFirstParent [current object]
                        }
                    }
                
                }

                +method doReset res {
                    
                    :onBuildDone {
                        :implementReset <% return $res %>
                       
                    }
                }
            }
            :posedge : SyncBlock signal {
                #+type Logic
                +exportTo Logic
            }

            :negedge : SyncBlock signal {
                #+type Logic
                 +exportTo Logic
            }

            ## Analog names 
            :analog : Signal name {
                +expose name
            }


            ## Stage Block 
            #######################
            :stage : Posedge name signal {
                +exportTo Logic
                +mixin ::odfi::h2dl::Structural
                #+var reset ""

                +builder {

                    ## Signal Can be an expression 
                    set :signal [::odfi::h2dl::ast::buildAST [subst ${:signal}] ]

                    ## Transform to negedge if necessary
                    if {[${:signal} isClass odfi::h2dl::ast::ASTNegate]} {
                        set :signal [${:signal} firstChild]
                        :object mixins add ::odfi::h2dl::Negedge
                    }
                    :onBuildDone {

                        ## Get All Signals and Move them up 
                        set signals [:shade odfi::h2dl::Signal children ]

                        ## Move them to parent, and change the name 
                        $signals foreach {
                            $it detachFrom [current object]
                            $it setFirstParent [:parent]
                            $it name set [:name get]_stage_[$it name get]
                        }

                    }
                }

                +method negedge args {
                    :object-mixins add [namespace current]::Negedge
                }
                
                

            }

            
        }
         
        
    }
    HW produceNX
   


    namespace eval fsm {

        odfi::language::Language default {

            :fsm : ::odfi::h2dl::Logic name {
                +exportTo ::odfi::h2dl::Logic
                +expose name
                #:input name default {
                #    +expose
                #}
                #:output name {
                #    +expose
                #}

                +builder {
                    :onBuildDone {

                        set states [odfi::flist::MutableList new]
                        :shade ::odfi::h2dl::fsm::State walkDepthFirstPostorder {
                            $states += $node
                            return true
                        }
                        set vectorSize [expr  [$states size] == 0 ? 0 : int(ceil(log([$states size])/log(2)))]
                        $states foreach {

                            [:parent] namedValue [$it name get] ${vectorSize}'d$i
                          
                        }

                    }
                }

                :state name {
                    +exportTo State
                    +var initial false
                    #+var values
                    #+method value {output value} {
                    #    lappend :values $output $value
                    #}
                    :goto to {
                        :on expression {
         
                            +builder {
                                set :expression [::odfi::h2dl::ast::buildAST ${:expression}]

                                #puts "Left: [${:expression} firstChild]"
                                #puts "Rifht: [${:expression} lastChild]"
                            }
                        } 

                        ## Something to be done when this transition is matched
                        :do {

                        }
                    }

                    ## Progress Construct is used to got to first defined state
                    :progressOn conditions {

                        +builder {
                            [:parent] onBuildDone {
                              
                           # puts "------- Doing progress with size [[:children] size]"
                            set states [:shade odfi::h2dl::fsm::State children]
                            if {[$states size]>1 || [$states size]==0} {
                                odfi::log::error "Progress utility can only be used if one sub-state is defined"
                            } else {
                                set targetState [$states first]
                                set progressNode [:shade odfi::h2dl::fsm::ProgressOn firstChild]
                                :goto [$targetState name get] {
                                    #foreach expr [$progressNode conditions get] {
                                       # puts "On Expression: [$progressNode conditions get]"
                                        :on [$progressNode conditions get] {

                                        }
                                    #}
                                }
                            }
                        }
                        }
                        
                        
                    }

                    :do : ::odfi::h2dl::Logic {

                    }

                    :entering  : ::odfi::h2dl::Logic {

                    }

                    :leaving  : ::odfi::h2dl::Logic {

                    }

                    :oppositePhase : ::odfi::h2dl::Logic {

                    }
                }

                +method toModule parent {

                }

                +method toCase {{tparent ""}} {
                    
                    ## Auto set to FSM container
                    if {$tparent==""} {
                        set p [:parent]
                        if {$p=="" || ![$p isClass ::odfi::h2dl::Logic]} {
                            error "Cannot create FSM to non Logic Parent"
                        } else {
                            set tparent $p
                        }
                        
                    }
                    
                    puts "Produce a Case "
                    set fsm [current object]

                    ## First: Take out the registers 
                    ##########
                    :shade ::odfi::h2dl::Signal eachChild {
                        $it detachFrom $fsm
                        $tparent addChild $it
                    }

                    ## Gather All States 
                    #############
                    set states [odfi::flist::MutableList new]
                    :shade ::odfi::h2dl::fsm::State walkDepthFirstPostorder {
                        #puts "Found State"
                        $states += $node
                        return true
                    }

                    ## Size of vector 
                    set size [$states size]
                    set vectorSize [expr $size == 0 ? 0 : int(ceil(log($size)/log(2)))]
                    #puts "$size States -> $vectorSize"

                    ## Add State Vector 
                    $tparent register [:name get]_state {
                        :width set $vectorSize
                    }

                    ## Find Inputs 
                    #########
                    set inputs [odfi::flist::MutableList new]
                    #:walkDepthFirstPostorder {
                    #    if {[$node isClass ::odfi::h2dl::fsm::On]} {
                    #        puts "Found On condition with expression: [$node expression get] ([[$node expression get] info class]), first child [[$node expression get] firstChild]"
                    #    }
                    #}
                    :shade ::odfi::h2dl::fsm::On walkDepthFirstPostorder {
                        #puts "Found On condition with expression: [$node expression get] ([[$node expression get] info class]), first child [[$node expression get] shade odfi::h2dl::Signal firstChild]"
                        $inputs += [[$node expression get] firstChild]
                    }
                    set inputs [$inputs compact]
                    #puts "Found Conditions: [$inputs size]"


                    set inputVectorSize [expr [$inputs size] == 0 ? 1 : int(ceil(log([$inputs size])/log(2)))]

                    ## Add input Vector 
                    #$tparent wire [:name get]_inputs {
                    #    :width set $inputVectorSize
                    #}

                    ## Second: Create State Case 
                    #######################
                    set stateRegister [set [:name get]_state]
                    [:parent] case [concat [set [:name get]_state] [$inputs toTCLList]] {

                        ## Doc 
                        :comment "---- FSM [$fsm name get] : State Case"
                        :comment "-----------"
                        set mainCase [current object]

                        ## Set Cases for each State 
                        $states foreach {
                            {state i} => 

                                ## Default On:
                                ##   - Stay on state or go somewhere else if a transition is defined as default 
                                ##   - Add 

                                ## Get Do 
                                set dos [$state shade ::odfi::h2dl::fsm::Do  children]

                                ## Create On 
                                #set on [:on "{$i,[lrepeat [$inputs size] x]}" {

                                #}]
                                ##$on description set

                                ## Add Dos to on
                                #$dos foreach { $on addChild $it}

                                ## Transitions 
                                ###################
                                $state shade ::odfi::h2dl::fsm::Goto eachChild {

                                    {goto gototi} => 

                                        puts "Found a transition to create an on for"

                                        ## Construct base input value 
                                        set inputValue [lrepeat [$inputs size] x]

                                        ## Find all Ons for this transition 
                                        $goto shade ::odfi::h2dl::fsm::On eachChild {
                                            
                                            {on oni} => 

                                                ## Get Target input and value 
                                                set onExpression [$on expression get]
                                                set targetInput [$onExpression firstChild]
                                                set value 0 
                                                if {[$onExpression isClass ::odfi::h2dl::ast::ASTNegate]} {
                                                    set value 0
                                                } elseif {[$onExpression isClass ::odfi::h2dl::ast::ASTCompare] && [[$onExpression lastChild] isClass ::odfi::h2dl::ast::ASTConstant] } {
                                                    set value [[$onExpression lastChild] constant get]
                                                }  else {
                                                    error "Transition on can only be an expression negating a signal or comparing to a constant"
                                                }

                                                ## Replace inputValue x with this inputvalue 
                                                set inputIndex [$inputs indexOf $targetInput]
                                                set inputValue [lreplace $inputValue $inputIndex $inputIndex $value]

                                        }
                                        ## EOF Search all conditions 


                                        ## Create an on for the transition 
                                        ###############

                                        ## Get the entering of the target state 
                                        set targetState [$states find { expr {[$it name get] } == { [$goto to get] } } ]
                                        set requirements [[$targetState shade ::odfi::h2dl::fsm::Entering children] map {
                                            #puts "Filtering BA in requirement: [[$it children] size]"
                                            return [$it shade ::odfi::h2dl::ast::ASTBlockingAssign children]
                                        }]

                                        ## Get the leaving of current state 
                                        set leavings [[$state shade ::odfi::h2dl::fsm::Leaving children] map {
                                            #puts "Filtering BA in requirement: [[$it children] size]"
                                            return [$it shade { expr [$it isClass ::odfi::h2dl::ast::ASTBlockingAssign] || [$it isClass ::odfi::h2dl::ast::ASTNonBlockingAssign] } children]
                                        }]

                                        ## Add the Dos of the Transition 
                                        $leavings import [[$goto shade ::odfi::h2dl::fsm::Do children] map {
                                            #puts "Filtering BA in requirement: [[$it children] size]"
                                            return [$it shade { expr [$it isClass ::odfi::h2dl::ast::ASTBlockingAssign] || [$it isClass ::odfi::h2dl::ast::ASTNonBlockingAssign] } children]
                                        }]

                                        #puts "Setting UP Case option for transition to [$goto to get], state register is $stateRegister -> [$stateRegister name get]"
                                        #puts "Found requirements: [$requirements size]"
                                        set joinedVal [join $inputValue ""]
                                        $mainCase on "{ [$state name get] , [llength $inputValue]\'b$joinedVal }" {
                                           #[[lindex$mainCase signals get
                                           
                                           :comment "Case to go to state [$goto to get]"
                                           $stateRegister <= $goto

                                           :comment "Leaving\n"
                                           $leavings foreach {
                                            
                                                $it foreach {
                                               
                                                    set nb [::odfi::h2dl::ast::ASTNonBlockingAssign new]
                                                    $nb addChild [$it firstChild]
                                                    $nb addChild [$it lastChild]
                                                    #$it detach
                                                    :addChild $nb
                                                }
                                            }

                                           :comment "Requirements\n"
                                           $requirements foreach {
                                            {req i} => 
                                             puts "In Requirement, nbs: [$req size]"
                                             $req foreach {
                                               
                                                set nb [::odfi::h2dl::ast::ASTNonBlockingAssign new]
                                                $nb addChild [$it firstChild]
                                                $nb addChild [$it lastChild]
                                                $it detach
                                                :addChild $nb
                                             }
                                           }


                                        }


                                }
                        }
                    }

                    ## Third: Create the DataPath Case 
                    #################
                    [:parent] case [concat [set [:name get]_state]] {

                        :comment "---- FSM [$fsm name get] : DataPath Case"
                        :comment "-----------"

                        ## Gather All DO 
                        ############
                        set dos [odfi::flist::MutableList new]
                        :shade ::odfi::h2dl::fsm::Do walkDepthFirstPostorder {
                            $dos += $node
                        }
                        if {[$dos size]==0} {
                            [current object] detach
                        }


                    }

                }
            }

        }
        #odfi::h2dl::Module domain-mixins add odfi::h2dl::fsm::Fsm
        
    }
    
    
    odfi::language::Language define TESTBENCH {
        
        :testbench name {
            +type Module
            +var  test
        }
        
    }




    ## Wrapper for better module definition
    ## args: {PARAMETER VALUE}* CLOSURE
    ## Last element of args will be the closure
    ## The Closure will be used as builder
    proc ModuleDefinition {name args} {

        set closure [lindex $args end]
        set args [lrange $args 0 end-1]

        #puts "Module Def with args: $args"

        #odfi::language::Language default {
#
        #    :$name : ::odfi::h2dl::Module name {
#
         #       +builder $closure
#
       #     }
        #}:+exportToParent

        ## Args will be used as parameters to customise the Model Instance Name
        ##############
        set argsNames {}
        foreach arg $args {
           lappend argsNames "[lindex $arg 0]\${:[lindex $arg 0]}" 
        }
        set argsNames [join $argsNames _]

        set instanceNameMethod "
            +method getMasterName args {
                return \[lindex \[split \[:info class\] :\] end\]_$argsNames
            }
        "

       # puts "Model Definition $name with model instance name : $instanceNameMethod and cl $closure"

        set builder {

            ## Check if there is a master
            ## If not, keep building
            #set masterParent [:shade odfi::h2dl::Master parent]
            #if {$masterParent!=""} {
            #    puts "Building Module Instance ${:name} with parent, only keeping IOs"
            #} else {
            #    <% return $closure %>
            #}
        }
        #[odfi::richstream::embeddedTclFromStringToString $builder]
        set code "
           odfi::language::Language default {

            :$name : ::odfi::h2dl::Module  name $args {

                #puts \"Inside module def with args \${args}\"
                :$instanceNameMethod
                :+exportToParent 
                :+expose name
                :+superclass  ::odfi::h2dl::MasterSupported
                +method buildMaster args {
                    $closure
                }
                +builder {
                    #puts \"Building \[:info class\]\"
                    #puts \"(MDEF) Inside builder of module def \[:info class\]\"
                    
                }


            }
        }
        "

        #puts "Created MDef with $code "
        uplevel $code
        #uplevel [list odfi::language::Language default [list \
        #    :$name : ::odfi::h2dl::Module name $args [list \
        #    :+builder $closure ; \
        #     ] \
         #   ]]


    }
     

    ##################################
    ## Value Expressions
    ##################################
    nx::Class create ValueHolder  {
        WritableSignal mixins add ValueHolder
        Analog mixins add ValueHolder
        Bit    mixins add ValueHolder


        :public method <= args {

           # puts "Expression for Updating [:name get] $args"
            
            ## Create Node for this update 
            set astNode [::odfi::h2dl::ast::ASTNonBlockingAssign new]

            ## extract args
            ## 
            if {[llength $args]==1} {
               set args [lindex $args 0]
              
           }

            ## Create Expression node 
            set expressionNode [::odfi::h2dl::ast::buildAST $args]
            #$expressionNode  object mixins add odfi::flextree::utils::StdoutPrinter

            #puts "NB expression: [$expressionNode info class]"

            ## Left: Target Register 
            ## Right: Expression
            $astNode addChild [current object]
            $astNode addChild $expressionNode

            #puts "Res: $expressionNode"
            #$expressionNode printAll

            #puts "Calling context: [uplevel 1 :info class]"
            ## Add Update to where it was called 
            uplevel :addChild $astNode

            #:addChild $expressionNode

            return $astNode


        }

        ## NB Assign Format: reg < 0 < 1 expr , updates bit 0 or reg using bit 1 of expression
        :public method < {intoBit keywork fromBit args} {

            ## Create Node for this update 
            set astNode [::odfi::h2dl::ast::ASTNonBlockingAssign new -fromBitRange $fromBit -toBitRange $intoBit]

            ## Create Expression node 
            set expressionNode [::odfi::h2dl::ast::buildAST $args]
            $expressionNode  object mixins add odfi::flextree::utils::StdoutPrinter

            ## Left: Target Register 
            ## Right: Expression
            $astNode addChild [current object]
            $astNode addChild $expressionNode


            ## Add Update to where it was called 
            uplevel :addChild $astNode

            return $astNode

        }   

        :public method = args {

            #puts "Expression for Updating [:name get] $args"
            
            ## Create Node for this update 
            set astNode [::odfi::h2dl::ast::ASTBlockingAssign new]

            #:eachChild {
            #    puts "Child for clk before expr: [$it info class]"
            #}

            ## Create Expression node 
            set expressionNode [::odfi::h2dl::ast::buildAST $args]
            $expressionNode  object mixins add odfi::flextree::utils::StdoutPrinter

            #:eachChild {
            #    puts "Child for clk after expr: [$it info class]"
            #}

            ## Left: Target Register 
            ## Right: Expressio
            set  leftSide     [current object]
            $astNode addChild $leftSide
            $astNode addChild $expressionNode

            #:eachChild {
            #    puts "Child for clk after added to AST expr: [$it info class]"
            #}

            #puts "Res: $expressionNode"
            #$expressionNode printAll

            ## Add Update to where it was called 
            #puts "Calling context: [uplevel 2 :info class]"
            
            #uplevel 2 [list :addChild $astNode]
            uplevel :addChild $astNode

            #:eachChild {
            #    puts "Child for clk after added to uplevel: [$it info class]"
            #}

            return $astNode

            

            #:addChild $expressionNode

            ## Return node 
            return $astNode

        }
    }

    
}


