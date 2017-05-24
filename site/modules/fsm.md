# FSM

The Fsm module provides an FSM DSL wich converst to HDL representation at runtime


  :fsm NAME {

    :state NAME {

        (:state NAME) *

        ## Got to the first sub-state
        :progressOn "EXPRESSION"

        :state NAME {

            :goto NAME {
                :on "EXPRESSION"

                ## Assignements to be executed when this transition is matched
                :do {
                    ASSIGNMENTS
                }
            }

            ## Assignements will be ready when entering this state
            :entering {

            }

            ## Assignments will be run when leaving the state
            :leaving {

            }

            ## This will be done for every cycle on this state
            :do {

            }

            :state NAME {

            }

            :state NAME {

            }

        }


    }

  }


## Convert to H2DL

### To Case 

A special function must be called to create an H2DL representation
Usually, the function should be provided with the target parent, for more flexibility

    :fsm NAME {
        ...

    }

    ## Create in Current Parent
    $NAME toCase [current object]
