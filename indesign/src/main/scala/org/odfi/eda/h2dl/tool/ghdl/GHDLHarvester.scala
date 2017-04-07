package org.odfi.eda.h2dl.tool.ghdl

import org.odfi.eda.h2dl.tool.gtkwave.GTKWaveTool
import org.odfi.eda.h2dl.tool.ExternalToolFolder
import java.io.File
import org.odfi.eda.h2dl.tool.ExternalTool
import org.odfi.indesign.core.harvest.Harvester

object GHDLHarvester extends Harvester {
  
   this.onDeliverFor[ExternalToolFolder] {
    case tf if (tf.toolId=="ghdl"  || new File(tf.path.toFile, "bin/ghdl.exe").exists || new File(tf.path.toFile, "bin/ghdl").exists) => 
      gather(new GHDLTool(new File(tf.path.toFile(),"bin/ghdl")).deriveFrom(tf))
      true
    
  }
  
}
class GHDLTool(p:File) extends ExternalTool(p) {
  
 
}
