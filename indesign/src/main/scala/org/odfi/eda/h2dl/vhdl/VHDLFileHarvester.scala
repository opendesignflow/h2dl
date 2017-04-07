package org.odfi.eda.h2dl.vhdl

import org.odfi.indesign.core.harvest.fs.HarvestedFile
import org.odfi.indesign.core.harvest.Harvester


object VHDLFileHarvester  extends Harvester {
  this.onDeliverFor[HarvestedFile] {
    case f if (f.path.toFile().getAbsolutePath.endsWith(".vhd") || f.path.toFile().getAbsolutePath.endsWith(".vhdl")) => 
      gather(new VHDLFile(f))
      true
  }
}

class VHDLFile(f:HarvestedFile) extends HarvestedFile(f.path) {
  this.deriveFrom(f)
}