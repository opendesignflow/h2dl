package edu.kit.ipe.adl.h2dl.main

import edu.kit.ipe.adl.indesign.core.brain.Brain
import edu.kit.ipe.adl.indesign.module.scala.ScalaModule
import edu.kit.ipe.adl.indesign.core.module.ui.www.IndesignWWWUIModule
import edu.kit.ipe.adl.indesign.core.module.eclipse.EclipseModule
import edu.kit.ipe.adl.indesign.module.maven.MavenModule
import edu.kit.ipe.adl.indesign.core.harvest.Harvest
import edu.kit.ipe.adl.indesign.core.module.git.GitModule
import edu.kit.ipe.adl.h2dl.H2DLModule
import edu.kit.ipe.adl.indesign.core.harvest.fs.FileSystemHarvester
import java.io.File
import edu.kit.ipe.adl.h2dl.verilog.VerilogFIleHarvester
import edu.kit.ipe.adl.indesign.tcl.module.TCLModule
import edu.kit.ipe.adl.h2dl.vhdl.VHDLFileHarvester

object VerilogAnalyse extends App {

  // Setup Modules
  //------------------
  Brain += (

    Harvest, IndesignWWWUIModule, TCLModule, H2DLModule)

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

  // Look For Stuff in current directory
  //---------------
  var fsh = new FileSystemHarvester
  fsh.addPath(new File("verilog").toPath())

  fsh.addChildHarvester(new VerilogFIleHarvester)
  fsh.addChildHarvester(new VHDLFileHarvester)

  Harvest.addHarvester(fsh)

  Brain.init

  Harvest.run
  Harvest.printHarvesters

}