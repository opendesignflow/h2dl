package org.odfi.eda.h2dl.fsmdesigner

import com.idyria.osi.ooxoo.model.producers
import com.idyria.osi.ooxoo.model.ModelBuilder
import com.idyria.osi.ooxoo.model.producer
import com.idyria.osi.ooxoo.model.out.markdown.MDProducer
import com.idyria.osi.ooxoo.model.out.scala.ScalaProducer
import org.odfi.wsb.fwapp.framework.json.JSONIOTrait
import com.idyria.osi.ooxoo.core.buffers.structural.io.sax.STAXSyncTrait

@producers(Array(
  new producer(value = classOf[ScalaProducer])))
object FSMDesignerModel extends ModelBuilder {

  // Name and description trait
  //----------
  val nameAndDescription = "NameAndDescription" is {
    isTrait
    attribute("name")
    "Description" ofType ("cdata")
  }

  // FSM
  //---------
  "FSM" is {

    withTrait(classOf[JSONIOTrait])

    // Name an description
    makeTraitAndUseCustomImplementation
    withTrait(nameAndDescription)

    // IO
    // ---------------

    "Input" multiple {
      withTrait(nameAndDescription)
    }

    "Output" multiple {
      withTrait(nameAndDescription)
    }

    // States
    //------------
    "State" multiple {
      makeTraitAndUseSameNameImplementation
      withTrait(nameAndDescription)

      //-- State ID
      attribute("id")

      //-- Initial State?
      attribute("initial") ofType ("boolean")

      // Output value
      //-----------------
      "Output" multiple {
        withTrait(nameAndDescription)
        attribute("value")
      }

      // Transitions
      //--------------
      "Transition" multiple {
        makeTraitAndUseSameNameImplementation
        withTrait(nameAndDescription)

        //-- Target state ID
        attribute("to")

        "Condition" multiple {
          withTrait(nameAndDescription)

          "Input" multiple {
            attribute("name")
            attribute("value")
          }
        }
      }

      // GUI data
      //--------------
      attribute("x") ofType "integer"
      attribute("y") ofType "integer"
    }
  }

  // State machine from ROME Software
  //-------------------
  "StateMachine" is {

    withTrait(classOf[STAXSyncTrait])
    withTrait(classOf[JSONIOTrait])

    "State" multiple {
      attribute("name")
      
      "StateTransition" multiple {
        attribute("nextstate")
        
        "Condition" is {
          attribute("relation")
          
          "Lvalue" is {
            
            "Action" is {
              attribute("what")
            }
          }
          "Rvalue" is {
            
          }
        }
      }
    }

  }
  
  // FSM Designer
  //--------------------
  "project" is {
    
    withTrait(classOf[STAXSyncTrait])
    withTrait(classOf[JSONIOTrait])
    
    "fsm" multiple {
      
      attribute("fname")
      attribute("resetstate") ofType("integer")
      
      // IO
      //---------
      "globals" is {
        "name" multiple("string")
      }
      
      "inputnames" is {
         "name" multiple("cdata")
      }
      "outputnames" is {
         "name" multiple("cdata")
      }
      
      // State
      //-------------
      "state" multiple {
        attribute("id") ofType("integer")
        attribute("posy") ofType("double")
        attribute("posx") ofType("double")
        attribute("color") ofType("long")
        
        "sname" ofType("cdata")
        "output" ofType("string")
      }
      
      "trans" multiple {
        attribute("id") ofType("integer")
        attribute("textposy") ofType("double")
        attribute("textposx") ofType("double")
        attribute("color") ofType("long")
        
        "name" ofType("cdata")
        "default" ofType("integer")
        "start" ofType("integer")
        "end" ofType("integer")
        
        "condition" multiple {
          "cname" ofType("cdata")
          "input" ofType("string")
        }
      }
      
      
      
    }
  }

}