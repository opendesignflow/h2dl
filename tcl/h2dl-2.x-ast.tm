## The AST Package provides the core tree syntax modelisation
package provide odfi::dev::hw::h2dl::ast 2.0.0
package require odfi::attributes 2.0.0
package require odfi::flextree 1.0.0

namespace eval odfi::dev::hw::h2dl::ast {

    proc astOperatorToNode operator {

        puts "Operator : $operator"
        if {$operator!= "*"  && [odfi::common::isClass $operator odfi::flextree::FlexNode]} {
            #puts "$operator is a class"
            return $operator
        } else {

            switch -regexp -- $operator {
                {\+} {
                   return [[namespace current]::ASTAdd new -operator +]   
                }
                {\*} {
                   return [::new [namespace current]::ASTMultiply #auto]    
                }
                {==} {
                   return [[namespace current]::ASTCompare new]    
                }

                {[0-9]+} {
                    return [[namespace current]::ASTConstant new -constant $operator]    
                }

                {&} {
                    return [[namespace current]::ASTAnd new]    
                }

                {\|} {
                    return [[namespace current]::ASTBitOr new]    
                }

                {!} {
                    return [[namespace current]::ASTNegate new -operator !]    
                }
                {\?} {
                    return [[namespace current]::ASTIf new -operator !]    
                }
                 {:} {
                    return [[namespace current]::ASTElse new -operator !]    
                }
                {<<} {
                    return [[namespace current]::ASTShiftLeft new ]    
                }
                {>>} {
                    return [[namespace current]::ASTShiftRight new ]    
                }
                {<-} {
                    return [[namespace current]::ASTRangeSelect new ]    
                }
                {,} {
                    return [[namespace current]::ASTConcat new ]    
                }
                {Z} {
                    return [[namespace current]::ASTRangeSelect new ]    
                }
                {[A-Za-z0-9_]+} {
                    puts "Try to find $operator as a variable in caller context"
                    if {[catch [list odfi::closures::value $operator] res]} {
                        error "Could not find $operator as variable in caller context -> $res"
                    }
                    return $res
                    puts "Found: $res"
                    return [[namespace current]::ASTConstant new -constant $operator]    
                }
                default {
                    error "Unsupported ast node: $operator cannot be converted to a representation"
                }
            }

        }
        
    }

    ## Transform an expression to an AST
    proc buildAST {args} {

        if {[llength $args]==1} {
            set args [lindex $args 0]
        }

        if {[odfi::common::isClass $args [namespace current]::ASTNode]} {
            return $args
        }

        ## Resolve non resolvable $variables 
        #set args [odfi::closures::subst $args]

        #set expr {}
        #foreach i $args {
        #    switch -exact -- $i {
        #        ( {
         #        set expr "$expr {"    
        #        }
        #       ) {
         #        #lappend expr   
         ##       }
          #      default {
         #           lappend expr $i
         #       }
          #  }
       # }
       set expr [regsub -all {\)} $args " } "]
       set expr [regsub -all {\(} $expr " \{ "]

        set expr [regsub -all {\[} $expr " \{\[ "]
        set expr [regsub -all {\]} $expr " \]\} "]
        
        
        #([llength $expr])

        ## Add spaces before and after operators 
        set operators {+ -- - / << >> <- ? == = <=}
        set map {}
        foreach op $operators {
            lappend map "$op" " $op "
        }
        set expr [string map $map $expr]

        puts "Trans Expression is $expr ([llength $expr]) (before: $args)"

        ## Stacks
        set stack [odfi::flist::MutableList new]
        $stack += [list "" $expr]
        set topParent ""
        #set expressions [list [list "" $expr]]
        #set res {}

        ## Process 
        #####
        while {[$stack size]>0} {

            ## Get current 
            set currentPair [$stack pop]
            set currentParent [lindex $currentPair 0]
            set currentExpression [lindex $currentPair  1]

            if {[llength $currentExpression]==0} {
                continue
            }

            
            
            #set currentExpression [lindex [lindex $expressions 0] 1]
            #set resultParent [lindex [lindex $expressions 0] 0]

            ## Checks 
            #############
            #puts "Expression ($currentExpression) Size: [llength $currentExpression]"

            ## Size must be 3 or 
            #if {[llength $currentExpression]<3} {
            #    error "Expression $currentExpression must be of format: operand operator operand . 
            #    An operand may be a subexpression. 
            #    Maybe a parenthesis is unbalanced"
            #}

            ## Process depending on size 
            ##################################

            ## Size 1, only one node, try to convert to node, and add to parent return it if it's a node, or convert it to a node, otherwise error 
            ## Size 2, Format: operator operand 
            ## Size 3, Format: operand  operator  operand
            ## Otherwise, error 
            switch -exact -- [llength $currentExpression] {
                1 {
                   set returnNode [lindex $currentExpression 0]
                   set returnNode [astOperatorToNode $returnNode]

                   ## Set as top node or add 
                   if {$currentParent==""} {
                        set topParent $returnNode
                   } else {
                        #puts "Done Add Child $returnNode"

                        $currentParent addChild $returnNode
                        # puts "Left: [$currentParent firstChild]"
                        #puts "Rifht: [$currentParent lastChild]"
                   }

                   #if {[odfi::common::isClass $returnNode ::odfi::flextree::FlexNode]} {
                        #odfi::log::error "Expression $currentExpression has not understandable format"
                    #    return $returnNode
                   #} else {

                        ## Convert to constant
                    #    return [astOperatorToNode $returnNode]
                   #}
                }
                2 {
                    
                    set left ""
                    set operator [lindex $currentExpression 0]
                    set right [lindex $currentExpression 1]

                    #puts "Format Operator ($operator) Operand ($right) for $currentExpression"

                    ## Get Operator Node 
                    set operatorNode [astOperatorToNode $operator]
                    
                    ## If not an ASTOperator, then it is a value holder from which we want to select 
                    if {![$operatorNode isClass odfi::dev::hw::h2dl::ast::ASTOperator]} {
                        set source $operatorNode
                        set operatorNode [ASTSelect new]
                        $operatorNode addChild $source
                    }

                    ## Add To parent or set as top 
                    if {$currentParent==""} {
                        set topParent $operatorNode
                    } else {
                        $currentParent addChild $operatorNode
                    }

                    ## Stack Operands
                    $stack += [list $operatorNode $right]

                    
                }
                3 {

                   

                    set left [lindex $currentExpression 0]
                    set operator [lindex $currentExpression 1]
                    set right [lindex $currentExpression 2]

                     #puts "Format Operand operator Operand ($currentExpression)"
                     #puts "-- Left: $left"
                     #puts "-- Right: $right"

                    ## Get Operator Node 
                    set operatorNode [astOperatorToNode $operator]
                    
                    ## If not an ASTOperator, then it is a value holder from which we want to select 
                    if {![$operatorNode isClass odfi::dev::hw::h2dl::ast::ASTOperator]} {
                        
                        #set source $operatorNode
                        #set operatorNode [ASTSelect new]
                        #$operatorNode addChild $source

                        ## If the first node is an operator, then use it as source
                        ## The right part becomes the operator + right
                        set firstNodeOperator [astOperatorToNode $left]
                        if {[$firstNodeOperator isClass odfi::dev::hw::h2dl::ast::ASTOperator]} {
                            set operatorNode $firstNodeOperator
                            set right  [concat $operator [list $right]] 
                            set left   ""

                        }
                    }

                    ## Add To parent or set as top 
                    if {$currentParent==""} {
                        set topParent $operatorNode
                    } else {
                        $currentParent addChild $operatorNode
                    }

                    ## Stack Operands
                    $stack += [list $operatorNode $left]
                    $stack += [list $operatorNode $right]
                }
                default {

                    ##  Try to recognise
                    ##  Take first 3
                    set newExpresssion [lrange $currentExpression 0 2]
                    set nextExpression [lrange $currentExpression 3 end]

                    set left [lindex $newExpresssion 0]
                    set operator [lindex $newExpresssion 1]
                    set right [lindex $newExpresssion 2]

                    ## Get operator node
                    set operatorNode [astOperatorToNode $operator]

                    ## Add To parent or set as top 
                    if {$currentParent==""} {
                        set topParent $operatorNode
                    } else {
                        $currentParent addChild $operatorNode
                    }

                    ## Add left and right to stack
                    $stack += [list $operatorNode $left]
                    $stack += [list $operatorNode $right]

                    ## Add next expression to stack too
                    $stack += [list $operatorNode $nextExpression]

                    #odfi::log::error "Expression $currentExpression has no understandable format"
                }
            }            

        }
        
        #
        puts "Top parent is of type: [$topParent info class]"
         #puts "Left: [$topParent firstChild]"
        #                puts "Rifht: [$topParent lastChild]"
        return $topParent

    } 


    ## Base Nodes Definition
    ##########################


    ## The AST Node is the basic Node Definition
    nx::Class create ASTNode -superclass odfi::flextree::FlexNode {

        


        :public method toString args {
            return [info class]
        }

        ## Child positions
        ################

        ## @return true if the provided node is the first child
        :public method isLeft node {
            if {[child 0]==$node} {
                return true
            } else {
                return false
            }
        }

    }


    #############################
    ## Container AST 
    ################################
    nx::Class create ASTGroup -superclass ASTNode {
      
    

    }

    #############################
    ## Branching AST 
    ################################
    nx::Class create ASTBranchNode -superclass ASTNode {
       

        :public method toString args {
            return "branch"
        }

    }
    #############################
    ## Operands AST 
    ################################
    nx::Class create ASTOperand -superclass ASTNode {

         variable -accessor public operator ""

        

        :public method toString args {
            return $operator
        }

    }

    ## Utility to fast create operands 
    proc createASTOperand {name symbol} {

    }

    createASTOperand NonBlockingAssign <=
    createASTOperand Add +
    createASTOperand Multiply *
    createASTOperand Compare ==

    #################################################
    ## Simple Logical and Mathematical Operators 
    ##################################################
    nx::Class create ASTOperator -superclass ASTNode {

        :property -accessor public {operator "UNDEFINED"}

        :method init args {
            next
        }

        :public method toString args {
            return $operator
        }

    }

    nx::Class create ASTNegate -superclasses ASTOperator {
        :method init args {
            set operator "!"
            next
        }
    }

    nx::Class create ASTAdd -superclass ASTOperator {
      :method init args {
            set operator "+"
            next
        }
    }

    nx::Class create ASTAnd -superclass ASTOperator {
    
        :method init args {
            set operator "&"
            next
        }
    }

    nx::Class create ASTBitOr -superclass ASTOperator {
        
        :method init args {
            set operator "|"
            next
        }

    }

    nx::Class create ASTShiftLeft -superclass ASTOperator {
        
        :method init args {
            set operator "<<"
            next
        }

    }

    nx::Class create ASTShiftRight -superclass ASTOperator {
        
        :method init args {
            set operator ">>"
            next
        }

    }

    nx::Class create ASTRangeSelect -superclass ASTOperator {
        
        :method init args {
            set operator "<-"
            next
        }

    }

    nx::Class create ASTConcat -superclass ASTOperator {
        
        :method init args {
            set operator ":"
            next
        }

    }

    
    nx::Class create ASTSelect -superclass ASTOperator {
        
        :method init args {
            #set operator "<-"
            next
        }

    }

    ## Comparisons 
    nx::Class create ASTCompare -superclass ASTOperator {
      
        :method init args {
            set operator "=="
            next
        }

    }

    #### Branching 
    ########################

    ## Left: Condition 
    ## Second: Body 
    ## Right : Else
    nx::Class create ASTIf -superclass ASTOperator {
      
        :method init args {
            set operator "?"
            next
        }

    }

    nx::Class create ASTElse -superclass ASTOperator {
      
        :method init args {
            set operator ":"
            next
        }

    }



    ##############
    ## Value: For nodes that can provide a value or be updated
    ##############
    nx::Class create ASTValue -superclass ASTNode {
   
        :property -accessor public {currentValue 0}
        :property -accessor public {availableValue 0}
       


        ## Building functions
        #################

        ## Defered value update
        ## @ast @leaf Value target 
        ## @ast @left Value result
        :public method <= args {

            set astNode [::new [namespace parent]::ASTNonBlockingAssign $this.assignnb.#auto]

            #puts "Non blocking assign on AST Value: $args"

            ## Left : target
            $astNode addChild $this

            ## Right: Created expression
            $astNode addChild [[namespace parent]::buildAST [split $args]]

            ## Try to stack value to a parent 
            storeToCurrentASTNode $astNode
            

            return $astNode
        }

        :public method toString args {
           # puts "To string on $this : [$this info class] -> [namespace current]"
            return [$this name]
        }

    }

    nx::Class create ASTNonBlockingAssign -superclasses ASTOperator {

        :property {fromBitRange -1}
        :property {toBitRange   -1}

        :method init args {
            set :operator "<="
            next
        }

        :public method test2  args {

        }

        ## This method merges all the values on the left side to the first available value 
        #:public method mergeLeft args {

         #   set left [:child 0]

        #}
    }

    nx::Class create ASTBlockingAssign -superclasses ASTOperator {

        :property {fromBitRange -1}
        :property {toBitRange   -1}

        :method init args {
            set :operator "="
            next
        }

      
    }

    ## Constant 
    ##############
    nx::Class create ASTConstant -superclass ASTNode {
      

        :property -accessor public constant:required



        :public method toString args {
            return "$constant"
        }
    }


    ##########################
    ## Control Structures
    ## @group
    ##########################

    nx::Class create  If -superclass ASTNode {
        

        :method init {cTest body args} {

            if {[llength $args]==1} {
                set args [lindex $args 0]
            }

            ## First Child is the If part
            ########
            set ifNode [::new [namespace parent]::ASTBranchNode $this.ifNode]
            addChild $ifNode

            ## Add Expression left of the if node
            $ifNode addChild [[namespace parent]::buildAST $cTest]

            ## Add Group Node for the if body 
            
            set ifBodyNode [::new [namespace parent]::ASTGroup $this.if.body]
            $ifNode addChild $ifBodyNode
            set currentNode $ifBodyNode

            ## Execute body
            odfi::closures::doClosure $body 1
            set currentNode ""

            ## Remaining 

            ## Else If 
            ################
            #puts "Args: $args"
            set i 0
            foreach elseifIndex [lsearch -exact -all $args elseif] {

                set condition [lindex $args [expr $elseifIndex+1]]
                set body      [lindex $args [expr $elseifIndex+2]]

                ## Create and IF with body for this elseif
                set elseifNode [::new [namespace parent]::ASTBranchNode $this.elseif$i $condition $body]

                addChild $elseifNode

                ## Add else if condition
                $elseifNode addChild [[namespace parent]::buildAST $condition]

                set elseifBodyNode [::new [namespace parent]::ASTGroup $this.elseif.body]
                $elseifNode addChild $elseifBodyNode
                set currentNode $elseifBodyNode

                ## Execute body
                odfi::closures::doClosure $body 1
                set currentNode ""
               
                incr i

            }
            ## Else 
            ################
            set elseIndex [lsearch -exact $args else]
            if {$elseIndex!=-1} {

                set body      [lindex $args [expr $elseIndex+1]]

                 ## Add Group Node for the if body 
                set elseNode [::new [namespace parent]::ASTGroup $this.else]

                addChild $elseNode
                set currentNode $elseNode

                ## Execute body
                odfi::closures::doClosure $body 1
                set currentNode ""

            }

        }
    }

}




