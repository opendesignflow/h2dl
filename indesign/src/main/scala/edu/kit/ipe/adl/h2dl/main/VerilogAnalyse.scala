package edu.kit.ipe.adl.h2dl.main

import java.io.File

import org.bridj.BridJ

import com.idyria.osi.wsb.webapp.localweb.LocalWebEngine
import com.idyria.osi.wsb.webapp.resources.ResourcesIntermediary

import edu.kit.ipe.adl.h2dl.DesignGroupHarvester
import edu.kit.ipe.adl.h2dl.DesignGroupResource
import edu.kit.ipe.adl.h2dl.H2DLModule
import edu.kit.ipe.adl.h2dl.verilog.VerilogFIleHarvester
import edu.kit.ipe.adl.h2dl.verilog.VerilogFile
import edu.kit.ipe.adl.h2dl.vhdl.VHDLFileHarvester
import edu.kit.ipe.adl.indesign.core.brain.Brain
import edu.kit.ipe.adl.indesign.core.harvest.Harvest
import edu.kit.ipe.adl.indesign.core.harvest.Harvester
import edu.kit.ipe.adl.indesign.core.harvest.fs.FileSystemHarvester
import edu.kit.ipe.adl.indesign.core.harvest.fs.HarvestedFile
import edu.kit.ipe.adl.indesign.core.heart.Heart
import edu.kit.ipe.adl.indesign.core.heart.HeartTask
import edu.kit.ipe.adl.indesign.core.module.ui.www.IndesignWWWUIModule
import edu.kit.ipe.adl.indesign.tcl.module.TCLModule
import edu.kit.ipe.adl.h2dl.ui.H2DLWelcomeView
import com.idyria.osi.tea.logging.TLog
import com.idyria.osi.vui.core.view.AViewCompiler
import com.idyria.osi.tea.files.FileWatcherAdvanced
import com.idyria.osi.wsb.webapp.localweb.SingleViewIntermediary
import com.idyria.osi.wsb.webapp.http.connector.websocket.WebsocketInterface
import edu.kit.ipe.adl.h2dl.techfiles.lib.LibFile
import edu.kit.ipe.adl.indesign.core.config.Config
import edu.kit.ipe.adl.indesign.core.config.ooxoo.OOXOOFSConfigImplementation
import edu.kit.ipe.adl.indesign.tcl.integration.TclintLibrary
import edu.kit.ipe.adl.indesign.tcl.TclInterpreter

object VerilogAnalyse extends App {

  // TLog.setLevel(classOf[Harvester],TLog.Level.FULL)
  
 
  
  
  // Setup Modules
  //------------------
  /*Brain += (

    Harvest, IndesignWWWUIModule, TCLModule, H2DLModule)*/

  //-- Setup COnfig
  Config.setImplementation(new OOXOOFSConfigImplementation(new File("indesign-config")))
  Brain.deliverDirect(Harvest)
  Brain.deliverDirect(Config)
  Brain.deliverDirect(IndesignWWWUIModule)
  Brain.deliverDirect(TCLModule)
  Brain.deliverDirect(H2DLModule)

  // LocalWebEngine.enableDebug

  // TLog.setLevel(classOf[Harvester], TLog.Level.FULL)
  /*TLog.setLevel(classOf[AViewCompiler[_, _]], TLog.Level.FULL)
      TLog.setLevel(classOf[FileWatcherAdvanced], TLog.Level.FULL)
      TLog.setLevel(classOf[SingleViewIntermediary], TLog.Level.FULL)
       TLog.setLevel(classOf[WebsocketInterface], TLog.Level.FULL)*/

  // Args
  //------------

  args.indexOf("--tools") match {
    case -1 =>
    case i =>
      var targetFile = new File(new File(args(i + 1)).getCanonicalPath)
      println(s"Tools folder: ${args(i + 1)} -> ${targetFile.getCanonicalPath}  ")
      targetFile match {
        case f if (!f.exists || !f.isDirectory()) => sys.error("Tools Folder must exists and be directory")
        case f => 
          //H2DLModule.exttoolHarvester.basePath = targetFile
      }

  }

  args.indexOf("--odfi") match {
    case -1 =>
    case i =>
      var targetFile = new File(args(i + 1)).getCanonicalFile
      targetFile match {
        case f if (!f.exists || !f.isDirectory()) => sys.error("ODFI Folder must exists and be directory")
        case f => 
          //H2DLModule.odfiHarvester.managerPath = targetFile
      }

  }

  // Look For Stuff in current directory
  //---------------
  var basePath = args.indexOf("--content") match {
    case -1 => new File("hdl").getCanonicalFile
    case i =>
      var targetFile = new File(args(i + 1)).getCanonicalFile
      targetFile match {
        case f if (!f.exists || !f.isDirectory()) => sys.error("Content Folder Folder must exists and be directory")
        case f => f
      }

  }
  basePath.mkdirs

  val fsh = new FileSystemHarvester
  fsh.addPath(basePath.toPath())
  var dgh = fsh.addChildHarvester(DesignGroupHarvester())

  //fsh.addChildHarvester(new VerilogFIleHarvester)
  //fsh.addChildHarvester(new VHDLFileHarvester)

  
  
 
  
  
  Harvest.addHarvester(fsh)
  //println(s"CL: "+Thread.currentThread().getContextClassLoader)
  
  
  
  
  
   /*TclintLibrary.enableDebug()
  //var i = new TclInterpreter
  sys.exit*/
  
 /* Harvest.run
  Harvest.printHarvesters
  Harvest.run
  Harvest.run
  Brain.moveToStart*/
  
  /*System.getProperty("java.library.path").split(";").foreach {
    s => 
      println("Path: "+s)
  }*/
  
  //-- Load TCL
  //TCLModule.getInterpreter("default")
  println(s"CL: "+Thread.currentThread().getContextClassLoader)
  //TclintLibrary.enableDebug()
  //var i = new TclInterpreter
  //sys.exit
  

  // Test Design Group
  //----------------
  /*Harvest.onHarvesters[VerilogFIleHarvester] {
    case vh =>
      vh.onResources[HarvestedFile] {
        case f =>
          println("Verilog File: " + f + " -> " + f.parentResource.get.parentResource)
      }
  }

  println("Try with Design Group as basis")
  dgh.onResources[DesignGroupResource] {
    case dg =>
      println("Design Group: " + dg)
      dg.onDerivedResources[VerilogFile] {
        case f =>
          println("--> Verilog File: " + f + " -> " + f.parentResource.get.parentResource)
      }
  }*/

  ResourcesIntermediary.addFilesSource(basePath.getCanonicalFile.getAbsolutePath)

  

  // Start
  //----------
  Harvest.run
  Brain.moveToInit
  Harvest.run
  
  /*System.getProperty("java.library.path").split(";").foreach {
    s => 
      println("Path: "+s)
  }*/
  Brain.moveToStart
  
  // UI Setup
  //----------------
  LocalWebEngine.addViewHandler("/h2dl", classOf[H2DLWelcomeView])

  // Schedule Harvesting
  //--------
  Heart.pump(new HeartTask[Any] {

    this.scheduleEvery = Some(3000)

    def getId = "Harvest"

    def doTask: Any = {

      //Harvest.run

    }

  })

}