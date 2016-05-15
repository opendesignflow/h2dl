package edu.kit.ipe.adl.h2dl

import edu.kit.ipe.adl.indesign.module.maven.MavenModule
import edu.kit.ipe.adl.indesign.core.brain.Brain
import edu.kit.ipe.adl.indesign.core.harvest.Harvest
import edu.kit.ipe.adl.indesign.tcl.module.TCLModule
import edu.kit.ipe.adl.h2dl.tool.icarus.ICarusHarvester
import edu.kit.ipe.adl.h2dl.tool.icarus.IVerilogTool
import java.io.File

object TryIcarusVerilog extends App {
  Brain += (

    Harvest, TCLModule, H2DLModule, MavenModule)

  Brain.init

  // Look For Stuff in current directory
  //--------------
  Harvest.run
  Harvest.run
  Harvest.printHarvesters
  
  var iverilog = ICarusHarvester.getResource[IVerilogTool].get
  
  // Compile
  //---------------
  var vfile = new File("verilog/counter_tb.v").getAbsoluteFile
  var outFile = new File(vfile.getAbsolutePath.replace(".v",".vpp"))
  
  var process = iverilog.createToolProcess("-g2012","-o",outFile.getAbsolutePath,vfile.getAbsolutePath)
  //var process = iverilog.createToolProcess("-v")
  
  //-- Get IO in Buffer
  process.outputToBuffer
  
  //-- Run 
  var code =  process.startProcessAndWait
 
  
  println("Done: "+code)
  println("Output: "+process.getOutputString)
  
}