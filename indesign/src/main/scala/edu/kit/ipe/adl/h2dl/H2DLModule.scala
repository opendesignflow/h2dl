package edu.kit.ipe.adl.h2dl

import java.io.File

import org.odfi.indesign.core.harvest.Harvest
import org.odfi.indesign.core.module.IndesignModule

import edu.kit.ipe.adl.h2dl.tool.ExternalToolHarvester
import edu.kit.ipe.adl.h2dl.tool.ghdl.GHDLHarvester
import edu.kit.ipe.adl.h2dl.tool.gtkwave.GTKWaveHarvester
import edu.kit.ipe.adl.h2dl.tool.icarus.ICarusHarvester
import edu.kit.ipe.adl.h2dl.tool.rsync.RsyncToolHarvester

import edu.kit.ipe.adl.h2dl.project.H2DLProjectHarvester
import edu.kit.ipe.adl.h2dl.tool.sphynx.SphynxProjectHarvester
import edu.kit.ipe.adl.h2dl.tool.msys.MsysHarvester
import org.odfi.indesign.core.harvest.fs.FileSystemHarvester
import org.odfi.indesign.core.harvest.fs.FSGlobalWatch

object H2DLModule extends IndesignModule {

  /*var odfiHarvester = new ODFIHarvester(new File("""odfi-manager"""))
  var exttoolHarvester =new ExternalToolHarvester(new File("tools"))*/
  onLoad {

    println("IN H2DLModule LOAD")
    requireModule(FSGlobalWatch)
    
    // Add UI
    //-------------
    /*IndesignWWWView.defaultView = Some(new H2DLWelcomeView)
    WWWViewHarvester.deliverDirect(new H2DLVerilogAnalyser)
    WWWViewHarvester.deliverDirect(new H2DLVHDLAnalyser)*/

    // Add Tools Harvester
    //-------------------
    //Harvest.registerAutoHarvesterObject(classOf[FileSystemHarvester],H2DLProjectHarvester)
    //Harvest --> H2DLProjectHarvester
    Harvest.addHarvester(FileSystemHarvester)
    FileSystemHarvester --> H2DLProjectHarvester
    H2DLProjectHarvester --> SphynxProjectHarvester
    Harvest --> MsysHarvester

    //H2DLProjectHarvester --> (new ExternalToolHarvester)

    Harvest.registerAutoHarvesterObject(classOf[ExternalToolHarvester], GTKWaveHarvester)
    Harvest.registerAutoHarvesterObject(classOf[ExternalToolHarvester], ICarusHarvester)
    Harvest.registerAutoHarvesterObject(classOf[ExternalToolHarvester], GHDLHarvester)
    Harvest.registerAutoHarvesterObject(classOf[ExternalToolHarvester], RsyncToolHarvester)

    config match {
      case Some(config) =>
        var keys = config.getKeys("externalTool", "folder")
        keys.foreach {
          key =>
            key.values.foreach {
              case folder if (new File(folder).exists()) =>
                var exttoolHarvester = new ExternalToolHarvester(new File(folder))
                Harvest.addHarvester(exttoolHarvester)
              case _ =>
              //-- Does not work
            }
        }

      case None =>
    }
    /*Harvest.addHarvester(exttoolHarvester)
    exttoolHarvester.addChildHarvester(GTKWaveHarvester)
    exttoolHarvester.addChildHarvester(ICarusHarvester)
    exttoolHarvester.addChildHarvester(GHDLHarvester)
    exttoolHarvester.addChildHarvester(RsyncToolHarvester)*/

    // ADD VCD Harvester
    //--------------------
    // Harvest.registerAutoHarvesterObject(classOf[FileSystemHarvester], VCDFileHarvester)

    // Add ODFI Harvester
    //------------------
    //var odfiHarvester = new ODFIHarvester(new File("""E:\Common\Projects\git\odfi-manager"""))
    //var odfiHarvester = new ODFIHarvester(new File("""odfi-manager"""))
    //Harvest.addHarvester(odfiHarvester)
  }

  onStop {
    H2DLProjectHarvester.clean
    //SphynxProjectHarvester.clean
    MsysHarvester.clean

  }
}