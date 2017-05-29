package org.odfi.eda.h2dl.fsmdesigner

import java.io.File
import org.odfi.eda.h2dl.verilog.H2DLVerilogProducer

object FSMDesignerExample extends App {

  // Create FSM
  //--------------
  val fsm = new FSM
  fsm.name = "Counter FSM"

  fsm.createStates("!IDLE", "COUNTING", "OVERFLOW", "OVERFLOW_ERROR")

  fsm.createInputs("start", "stop")
  fsm.createOutputs("counting")

  fsm.transition("IDLE" -> "COUNTING", "Enabled").on("start" -> "1")
  fsm.transition("COUNTING" -> "OVERFLOW", "Overflowed").on("start" -> "1")
  fsm.transition("OVERFLOW" -> "COUNTING", "Cleared Overflow").on("start" -> "1")

  println(s"var fsmStr='" + fsm.toJSonString + "';")

  // To HDL
  //--------------

  val hdl = fsm.toH2DL

  println("HDL: " + hdl.toXMLString)

  // To Verilog
  //----------------
  val targetFile = new File("fsm.v")
  val producer = new H2DLVerilogProducer

  // producer.toVerilog(targetFile, hdl)
  producer.toVerilog(System.out, hdl)

  // Import Rudolf Thing
  //-------------------
  val statemachine = new StateMachine
  statemachine.fromFile(new File("example-rome.xml"))
  val fsmimported = new FSM
  fsmimported.name="Example From ROME"
  fsmimported.fromRome(statemachine)
  println(s"var fsmStr='" + fsmimported.toJSonString + "';")

}