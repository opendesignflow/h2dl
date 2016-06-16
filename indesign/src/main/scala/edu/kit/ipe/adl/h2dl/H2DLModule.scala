package edu.kit.ipe.adl.h2dl

import java.io.File

import edu.kit.ipe.adl.h2dl.tool.ExternalToolHarvester
import edu.kit.ipe.adl.h2dl.tool.ghdl.GHDLHarvester
import edu.kit.ipe.adl.h2dl.tool.gtkwave.GTKWaveHarvester
import edu.kit.ipe.adl.h2dl.tool.gtkwave.VCDFileHarvester
import edu.kit.ipe.adl.h2dl.tool.icarus.ICarusHarvester
import edu.kit.ipe.adl.h2dl.ui.H2DLVHDLAnalyser
import edu.kit.ipe.adl.h2dl.ui.H2DLVerilogAnalyser
import edu.kit.ipe.adl.h2dl.ui.H2DLWelcomeView
import edu.kit.ipe.adl.indesign.core.harvest.Harvest
import edu.kit.ipe.adl.indesign.core.harvest.fs.FileSystemHarvester
import edu.kit.ipe.adl.indesign.core.module.IndesignModule
import edu.kit.ipe.adl.indesign.core.module.ui.www.WWWViewHarvester
import edu.kit.ipe.adl.odfi.ODFIHarvester
import edu.kit.ipe.adl.h2dl.tool.rsync.RsyncToolHarvester

object H2DLModule extends IndesignModule {

  /*var odfiHarvester = new ODFIHarvester(new File("""odfi-manager"""))
  var exttoolHarvester =new ExternalToolHarvester(new File("tools"))*/
  onLoad {

    println("IN H2DLModule LOAD")
    // Add UI
    //-------------
    /*IndesignWWWView.defaultView = Some(new H2DLWelcomeView)
    WWWViewHarvester.deliverDirect(new H2DLVerilogAnalyser)
    WWWViewHarvester.deliverDirect(new H2DLVHDLAnalyser)*/

    // Add Tools Harvester
    //-------------------
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
}