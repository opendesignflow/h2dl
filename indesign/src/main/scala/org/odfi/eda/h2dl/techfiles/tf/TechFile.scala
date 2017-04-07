package org.odfi.eda.h2dl.techfiles.tf

import org.odfi.indesign.core.harvest.fs.HarvestedFile
import org.odfi.indesign.core.harvest.Harvester

object TechFileHarvester extends Harvester {
  
  this.onDeliverFor[HarvestedFile] {
    case f if(f.path.toFile.getCanonicalPath.endsWith(".tf"))=> 
      gather(new TechFile(f))
      true
  }
  
}


class TechFile(f:HarvestedFile) extends HarvestedFile(f.path) {
  deriveFrom(f)
}