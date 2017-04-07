package edu.kit.ipe.adl.h2dl.techfiles.lef

import org.odfi.indesign.core.harvest.fs.HarvestedFile
import org.odfi.indesign.core.harvest.Harvester

object LefFileHarvester extends Harvester {
  
  this.onDeliverFor[HarvestedFile] {
    case f if(f.path.toFile.getCanonicalPath.endsWith(".lef"))=> 
      gather(new LEFFile(f))
      true
  }
  
}


class LEFFile(f:HarvestedFile) extends HarvestedFile(f.path) {
  deriveFrom(f)
}