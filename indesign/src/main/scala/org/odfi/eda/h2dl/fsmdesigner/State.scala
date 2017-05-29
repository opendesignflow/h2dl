package org.odfi.eda.h2dl.fsmdesigner

class State extends StateTrait {
  

  def transition(to:State, name : String = "") : Transition = {
    this.transitions.find(_.to==to.id.toString) match {
      case Some(t) => t 
      case None => 
        val t = transitions.add
        t.to = to.id
        if (name!="") {
          t.name = name
        }
        t
    }
  }
  
  // Output
  def outputToBinaryString = {
    outputs.map(_.value.toString).mkString
  }
  
}