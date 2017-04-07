package edu.kit.ipe.adl.h2dl
/*
import org.odfi.tcl.indesign.core.brain.Brain
import org.odfi.tcl.indesign.core.harvest.Harvest
import org.odfi.tcl.indesign.tcl.module.TCLModule
import org.odfi.tcl.indesign.tcl.TclInterpreter
import org.odfi.tcl.indesign.tcl.module.TCLPackageHarvester
import org.odfi.tcl.indesign.tcl.module.TCLPackageFolder
import org.odfi.tcl.indesign.module.maven.MavenProjectHarvester
import org.odfi.tcl.indesign.module.maven.MavenModule

object TryParseH2DL extends App {

  Brain += (

    Harvest, TCLModule, H2DLModule, MavenModule)

  Brain.init

  // Look For Stuff in current directory
  //--------------
  Harvest.run
  Harvest.run
  Harvest.printHarvesters

  // Get Interpreter
  //-----------------
  var interpreter = TCLModule.getInterpreter("default")

  interpreter.evalString("puts Hello")

  interpreter.evalString("""
    |
    | puts "Loading package: [package names]"
    package require itcl
    package require odfi::h2dl::verilog::parse
    #package require odfi::nx::domainmixin 1.0.0
    #package require odfi::closures 3.0.0
    

      

    """.stripMargin)

  //-- Parse
  interpreter = TCLModule.getInterpreter("default")
  interpreter.forgetPackages("*odfi*")
  TCLModule.reloadInterpreterPackages("default")
  interpreter.evalString("package require odfi::h2dl::verilog::parse")
  var res = interpreter.evalString("""|
      | odfi::h2dl::verilog::parse::reverse E:/Common/Projects/git/adl/lectures/ss16/vorlesung/hdl/counter.v
      """).asList.toNXList

      //Thread.sleep(5000)
      
  interpreter = TCLModule.getInterpreter("default")
  interpreter.forgetPackages("*odfi*")
  TCLModule.reloadInterpreterPackages("default")

  interpreter.evalString("package require odfi::h2dl::verilog::parse")
  res = interpreter.evalString("""|
      | odfi::h2dl::verilog::parse::reverse E:/Common/Projects/git/adl/lectures/ss16/vorlesung/hdl/counter.v
      """).asList.toNXList
  println("Res is: " + res.getClass)
  println("IO is: " + res.head("shade odfi::h2dl::IO children"))

  res.foreach {
    obj =>
      println("Info: " + obj.getNXClass)
  }

  interpreter.close
}*/