package org.odfi.eda.h2dl.tech

import org.odfi.indesign.core.harvest.fs.HarvestedFile
import org.odfi.eda.h2dl.techfiles.lib.LibFile
import java.io.File
import org.odfi.indesign.core.brain.Brain
import org.odfi.eda.h2dl.H2DLModule
import org.odfi.tcl.module.TCLModule
import org.odfi.indesign.core.harvest.Harvest
import org.odfi.eda.h2dl.tool.rsync.RsyncTool
import org.odfi.eda.h2dl.tool.rsync.RsyncToolHarvester

object TryLibFileParse extends App {

  // Tools
 /* Brain += (
    Harvest, TCLModule, H2DLModule)
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
  Harvest.run
  Harvest.printHarvesters
*/
  /*
  var tool = RsyncToolHarvester.getResource[RsyncTool].get
  var process = tool.createToolProcess("--help")

  println(s"Running RSYNC: "+tool.startPath)
  process.inheritIO
  var res = process.startProcessAndWait
  System.out.flush()
  println(s"Run Res: "+res)*/
  
  var pb = new ProcessBuilder
  pb.command("""E:\Common\Projects\git\builds\builds\verilog-toolchain\hdl-tc-x86_64-w64-mingw32\bin\rsync.exe""")
  pb.inheritIO()
  var p = pb.start()
  var res = p.waitFor()
  println(s"Run Res: "+res)
  sys.exit

  var lf = new LibFile(new HarvestedFile(new File("src/test/resources/lib/fast_vdd1v0_basicCells.lib").toPath))

  var model = lf.getLibModel

  println(s"Found: " + model)
}