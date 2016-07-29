package edu.kit.ipe.adl.h2dl.techfiles.tf

import edu.kit.ipe.adl.indesign.core.harvest.fs.HarvestedFile
import edu.kit.ipe.adl.indesign.core.harvest.Harvester

class TechFileHarvester extends Harvester {
  
  this.onDeliverFor[HarvestedFile] {
    case f if(f.path.toFile.getCanonicalPath.endsWith(".tf"))=> 
      gather(new TechFile(f))
      true
  }
  
}


class TechFile(f:HarvestedFile) extends HarvestedFile(f.path) {
  deriveFrom(f)
}