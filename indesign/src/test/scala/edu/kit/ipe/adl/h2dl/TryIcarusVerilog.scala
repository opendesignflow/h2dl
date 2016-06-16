package edu.kit.ipe.adl.h2dl
/*
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

  // Args
  //------------

  args.indexOf("--tools") match {
    case -1 =>
    case i =>
      var targetFile = new File(new File(args(i + 1)).getCanonicalPath)
      println(s"Tools folder: ${args(i + 1)} -> ${targetFile.getCanonicalPath}  ")
      targetFile match {
        case f if (!f.exists || !f.isDirectory()) => sys.error("Tools Folder must exists and be directory")
        case f => H2DLModule.exttoolHarvester.basePath = targetFile
      }

  }

  args.indexOf("--odfi") match {
    case -1 =>
    case i =>
      var targetFile = new File(args(i + 1)).getCanonicalFile
      targetFile match {
        case f if (!f.exists || !f.isDirectory()) => sys.error("ODFI Folder must exists and be directory")
        case f => H2DLModule.odfiHarvester.managerPath = targetFile
      }

  }

  Brain.init

  // Look For Stuff in current directory
  //--------------
  Harvest.run
  Harvest.run
  Harvest.printHarvesters

  var iverilog = ICarusHarvester.getResource[IVerilogTool].get

  // Compile
  //---------------
  var vfile = new File("verilog/counter.v").getAbsoluteFile
  var outFile = new File(vfile.getAbsolutePath.replace(".v", ".vpp"))

  println(s"V:"+vfile.getAbsolutePath)
  var process = iverilog.createToolProcess("-g2012", "-o", outFile.getAbsolutePath, vfile.getAbsolutePath)
  //var process = iverilog.createToolProcess("-v")

  //-- Get IO in Buffer
  process.outputToBuffer

  //-- Run 
  var code = process.startProcessAndWait

  println("Done: " + code)
  println("Output: " + process.getOutputString)

}*/