package edu.kit.ipe.adl.h2dl.techfiles.lef

import edu.kit.ipe.adl.indesign.core.harvest.fs.HarvestedFile
import edu.kit.ipe.adl.indesign.core.harvest.Harvester

class LefFileHarvester extends Harvester {
  
  this.onDeliverFor[HarvestedFile] {
    case f if(f.path.toFile.getCanonicalPath.endsWith(".lef"))=> 
      gather(new LEFFile(f))
      true
  }
  
}


class LEFFile(f:HarvestedFile) extends HarvestedFile(f.path) {
  deriveFrom(f)
}