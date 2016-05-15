package edu.kit.ipe.adl.h2dl.tool.gtkwave

import edu.kit.ipe.adl.indesign.core.harvest.Harvester
import edu.kit.ipe.adl.indesign.core.harvest.fs.HarvestedFile

object VCDFileHarvester extends Harvester{
  
  this.onDeliverFor[HarvestedFile] {
    case f if (f.path.toFile().getName.endsWith(".vcd")) => 
      gather(new VCDFile(f))
      true
  }
  
}

class VCDFile(f:HarvestedFile) extends HarvestedFile(f.path) {
  this.deriveFrom(f)
}