package org.odfi.eda.h2dl.fsmdesigner

class Transition extends TransitionTrait {
  
  def on(inputAndValue:(String,String)*) = {
    
    val condition = this.conditions.add
    
    inputAndValue.foreach {
      case (inputName,value) => 
        val cinput = condition.inputs.add
        cinput.name = inputName
        cinput.value = value
    }
    
  }
}