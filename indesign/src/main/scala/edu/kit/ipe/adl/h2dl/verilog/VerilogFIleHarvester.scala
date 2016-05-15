package edu.kit.ipe.adl.h2dl.verilog

import edu.kit.ipe.adl.indesign.core.harvest.Harvester
import edu.kit.ipe.adl.indesign.core.harvest.fs.HarvestedFile
import java.nio.file.Path

class VerilogFIleHarvester extends Harvester {
  
  
  this.onDeliverFor[HarvestedFile] {
    case f if (f.path.toFile().getAbsolutePath.endsWith(".v")) => 
      gather(new VerilogFile(f))
      true
  }
}

class VerilogFile(f:HarvestedFile) extends HarvestedFile(f.path) {
  this.deriveFrom(f)
}