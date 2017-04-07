package edu.kit.ipe.adl.h2dl.tool.ghdl

import edu.kit.ipe.adl.h2dl.tool.gtkwave.GTKWaveTool
import edu.kit.ipe.adl.h2dl.tool.ExternalToolFolder
import java.io.File
import edu.kit.ipe.adl.h2dl.tool.ExternalTool
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
