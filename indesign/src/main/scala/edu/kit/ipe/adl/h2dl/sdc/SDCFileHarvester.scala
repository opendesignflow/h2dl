package edu.kit.ipe.adl.h2dl.sdc

import edu.kit.ipe.adl.h2dl.techfiles.lef.LEFFile
import edu.kit.ipe.adl.indesign.core.harvest.fs.HarvestedFile
import edu.kit.ipe.adl.indesign.core.harvest.Harvester

class SDCFileHarvester extends Harvester {
  
  this.onDeliverFor[HarvestedFile] {
    case f if(f.path.toFile.getCanonicalPath.endsWith(".sdc"))=> 
      gather(new SDCFile(f))
      true
  }
  
}


class SDCFile(f:HarvestedFile) extends HarvestedFile(f.path) {
  deriveFrom(f)
}