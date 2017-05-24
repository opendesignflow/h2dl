package org.odfi.eda.h2dl.sdc

import org.odfi.eda.h2dl.techfiles.lef.LEFFile
import org.odfi.indesign.core.harvest.fs.HarvestedFile
import org.odfi.indesign.core.harvest.Harvester

object SDCFileHarvester extends Harvester {
  
  this.onDeliverFor[HarvestedFile] {
    case f if(f.path.toFile.getCanonicalPath.endsWith(".sdc"))=> 
      gather(new SDCFile(f))
      true
  }
  
}


class SDCFile(f:HarvestedFile) extends HarvestedFile(f.path) {
  deriveFrom(f)
}