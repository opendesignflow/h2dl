package edu.kit.ipe.adl.h2dl.tool.icarus

import edu.kit.ipe.adl.h2dl.tool.ExternalTool
import java.io.File
import org.odfi.indesign.core.harvest.Harvester
import edu.kit.ipe.adl.h2dl.tool.ExternalToolFolder

class IVerilogTool(p:File) extends ExternalTool(p) {
  
}
class VPPTool(p:File) extends ExternalTool(p) {
  
}
object ICarusHarvester extends Harvester {
   this.onDeliverFor[ExternalToolFolder] {
    case tf if (tf.toolId=="iverilog" || new File(tf.path.toFile, "bin/iverilog.exe").exists || new File(tf.path.toFile, "bin/iverilog").exists)  => 
      gather(new IVerilogTool(new File(tf.path.toFile(),"bin/iverilog")).deriveFrom(tf))
      gather(new VPPTool(new File(tf.path.toFile(),"bin/vvp")).deriveFrom(tf))
      true
      
    
  }
}