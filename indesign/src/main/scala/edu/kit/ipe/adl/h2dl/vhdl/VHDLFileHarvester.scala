package edu.kit.ipe.adl.h2dl.vhdl

import edu.kit.ipe.adl.indesign.core.harvest.fs.HarvestedFile
import edu.kit.ipe.adl.indesign.core.harvest.Harvester


class VHDLFileHarvester  extends Harvester {
  this.onDeliverFor[HarvestedFile] {
    case f if (f.path.toFile().getAbsolutePath.endsWith(".vhd") || f.path.toFile().getAbsolutePath.endsWith(".vhdl")) => 
      gather(new VHDLFile(f))
      true
  }
}

class VHDLFile(f:HarvestedFile) extends HarvestedFile(f.path) {
  this.deriveFrom(f)
}