package org.odfi.eda.h2dl.hdl

class HDLHierarchy extends HierarchyTrait {
  
  // Input Outputs
  //---------------
  def createInput(name:String) = {
    
    this.inputs.find(_.name.toString==name) match {
      case Some(i) => i 
      case None => 
        val i = this.inputs.add
        i.name = name
        i
    }
  }
  def createInputs(names:String*) = names.map(createInput(_))
  
  def createOutput(name:String) = {
    
    this.outputs.find(_.name.toString==name) match {
      case Some(i) => i 
      case None => 
        val i = this.outputs.add
        i.name = name
        i
    }
  }
  def createOutputs(names:String*) = names.map(createOutput(_))
  
  def createInputOutput(name:String) = {
    
    this.outputs.find(_.name.toString==name) match {
      case Some(i) => i 
      case None => 
        val i = this.ios.add
        i.name = name
        i
    }
  }
  def createInputOutputs(names:String*) = names.map(createInputOutput(_))
}