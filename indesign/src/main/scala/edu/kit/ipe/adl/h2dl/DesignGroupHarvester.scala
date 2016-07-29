package edu.kit.ipe.adl.h2dl

import edu.kit.ipe.adl.indesign.core.harvest.fs.FileSystemHarvester
import edu.kit.ipe.adl.indesign.core.harvest.fs.HarvestedFile
import edu.kit.ipe.adl.indesign.core.harvest.Harvest
import edu.kit.ipe.adl.h2dl.verilog.VerilogFIleHarvester
import edu.kit.ipe.adl.h2dl.vhdl.VHDLFileHarvester
import edu.kit.ipe.adl.h2dl.tool.gtkwave.VCDFileHarvester
import edu.kit.ipe.adl.h2dl.tool.gtkwave.VCDFileHarvester
import edu.kit.ipe.adl.h2dl.tool.gtkwave.VCDFileHarvester
import edu.kit.ipe.adl.h2dl.pdf.PDFHarvester
import com.idyria.osi.tea.files.FileWatcherAdvanced
import edu.kit.ipe.adl.h2dl.techfiles.lib.LibFileHarvester
import edu.kit.ipe.adl.h2dl.techfiles.lef.LefFileHarvester
import edu.kit.ipe.adl.h2dl.techfiles.tf.TechFileHarvester
import edu.kit.ipe.adl.h2dl.sdc.SDCFileHarvester

class DesignGroupHarvester extends FileSystemHarvester {

  this.onDeliverFor[HarvestedFile] {
    case f if (f.path.toFile.isDirectory) =>
      //println(s"Design Group: "+f)
      gather(new DesignGroupResource(f)).root
      //gather(f)
      true
    case f =>
     // println(s"No Design Group: "+f)
      false
  }
}

class DesignGroupResource(f : HarvestedFile) extends HarvestedFile(f.path) {
  deriveFrom(f)
  
  def name = this.path.toFile.getName
  
  
  // Watcher for Files
  //----------------
  val watcher = new FileWatcherAdvanced
  onGathered {
    case h if(h.isInstanceOf[DesignGroupHarvester]) => 
      watcher.start
  }
}

object DesignGroupHarvester {
  Harvest.registerAutoHarvesterClass(classOf[DesignGroupHarvester], classOf[VerilogFIleHarvester])
  Harvest.registerAutoHarvesterClass(classOf[DesignGroupHarvester], classOf[VHDLFileHarvester])
  Harvest.registerAutoHarvesterClass(classOf[DesignGroupHarvester], classOf[VCDFileHarvester])
  Harvest.registerAutoHarvesterClass(classOf[DesignGroupHarvester], classOf[PDFHarvester])
  Harvest.registerAutoHarvesterClass(classOf[DesignGroupHarvester], classOf[LibFileHarvester])
  Harvest.registerAutoHarvesterClass(classOf[DesignGroupHarvester], classOf[LefFileHarvester])
  Harvest.registerAutoHarvesterClass(classOf[DesignGroupHarvester], classOf[TechFileHarvester])
  Harvest.registerAutoHarvesterClass(classOf[DesignGroupHarvester], classOf[SDCFileHarvester])
  def apply() = new DesignGroupHarvester()
}