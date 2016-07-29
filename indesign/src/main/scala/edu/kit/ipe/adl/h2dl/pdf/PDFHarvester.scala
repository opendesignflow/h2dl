package edu.kit.ipe.adl.h2dl.pdf

import edu.kit.ipe.adl.indesign.core.harvest.Harvester
import edu.kit.ipe.adl.indesign.core.harvest.fs.HarvestedFile

class PDFHarvester extends Harvester {
  
  this.onDeliverFor[HarvestedFile] {
    case f if (f.path.toFile.getName.endsWith("pdf")) => 
      gather(new PDFFile(f))
      true
  }
  
}

class PDFFile(f:HarvestedFile) extends HarvestedFile(f.path) {
  deriveFrom(f)
}