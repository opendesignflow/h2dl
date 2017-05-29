package org.odfi.eda.h2dl.fsmdesigner

import org.odfi.eda.h2dl.hdl.HDLHierarchy
import java.io.File

class FSM extends FSMTrait {

  // States
  //----------

  def getStatesWithId = states.filter(_.id != null)

  /**
   * Find or create State
   * States with name begining with "!"+ are marked initial
   */
  def state(id: String) = {
    val (stateId, initial) = id.trim()(0) match {
      case '!'   => (id.trim.dropWhile(_ == '!'), true)
      case other => (id.trim, false)
    }

    getStatesWithId.find(_.id.toString == stateId) match {
      case Some(found) => found
      case None =>
        val s = states.add
        s.id = stateId
        if (initial) s.initial = true
        s
    }
  }

  def createStates(ids: String*) = ids.map(state(_))

  // Search
  //-----------------
  
  def findStateFromBinaryString(str:String) : Option[State] = {
    
    states.find {
      state => 
        
        state.outputToBinaryString==str
    }
    
   
  }
  
  // IO
  //--------------

  /**
   * Return or create input
   */
  def input(name: String) = {
    inputs.find(_.name.toString == name) match {
      case Some(i) => i
      case None =>
        val i = inputs.add
        i.name = name
        i
    }
  }

  /**
   * Return or create output
   */
  def output(name: String) = {
    outputs.find(_.name.toString == name) match {
      case Some(o) => o
      case None =>
        val o = outputs.add
        o.name = name
        o
    }
  }
  def createInputs(names: String*) = names.map(input(_))
  def createOutputs(names: String*) = names.map(output(_))

  // Transition
  //--------------
  def transition(fromTo: Tuple2[String, String], name: String = ""): Transition = {
    val from = state(fromTo._1)
    val to = state(fromTo._2)
    from.transition(to, name)
    //from.transistions
  }

  // H2DL Transfer
  //---------------
  def toH2DL = {

    //-- Create Hiearchy
    val hierarchy = new HDLHierarchy
    hierarchy.name = name

    //-- IO
    hierarchy.createInputs("clk@clock", "res_n@reset")
    this.inputs.foreach(input => hierarchy.createInput(input.name))
    this.outputs.foreach(input => hierarchy.createOutput(input.name))

    //-- Sync Block
    hierarchy

  }

  // Import ROME
  //----------------
  def fromRome(s: StateMachine) = {

    s.states.foreach {
      case state if (state.stateTransitions.size > 0) =>
        val localState = this.state(state.name)
        state.stateTransitions.foreach {
          tr =>
            //-- Create Transition
            val localtransition = localState.transition(this.state(tr.nextstate))

            //-- Create label from condition

            tr.condition match {
              case null =>
              case cond if (cond.relation.toString == "Smaller" && cond.lvalue != null && cond.lvalue.action != null) =>
                println(s"Found cond")
                localtransition.name = s"< ${cond.lvalue.action.what}"

              case cond =>
                println(s"T: " + cond.relation)

            }

        }
      case other =>
    }

  }

  // Import FSMDesigner
  //---------------------

  /**
   * Import from FSM designer file, import first FSM from file
   */
  def fromDesigner(f: File) = {

    val project = new project
    project.fromFile(f)

    // Import
    project.fsms.headOption match {
      case Some(fsm) =>

        this.name = fsm.fname

        // IO
        if (fsm.globals != null) {
          fsm.globals.names.foreach {
            name => this.input(name)
          }
        }
        if (fsm.inputnames != null) {
          fsm.inputnames.names.foreach {
            name => this.input(name)
          }
        }
        if (fsm.outputnames != null) {
          fsm.outputnames.names.foreach {
            name => this.output(name)
          }
        }

        // States
        //--------
        fsm.states.foreach {
          state =>
            
            //-- Create state
            val localstate = this.state(state.sname)

            //-- Create output values
            state.output.data.zipWithIndex.foreach {
              case (outputValue,bitIndex) =>
                val localoutput = localstate.outputs.add
                localoutput.name = fsm.outputnames.names(bitIndex)
                localoutput.value = outputValue.toString    
            }
            
            // Add transitions from this state
            fsm.trans.foreach {
              case trans if (trans.start.data == state.id.data) =>

                val localtransition = localstate.transition(this.state(fsm.states.find(s => s.id.data == trans.end.data).get.sname))

              case other =>
            }
        }

      case None =>
    }

  }
}