package org.odfi.eda.h2dl.tool.icarus

import org.odfi.eda.h2dl.tool.ExternalTool
import java.io.File
import org.odfi.indesign.core.harvest.Harvester
import org.odfi.eda.h2dl.tool.ExternalToolFolder
import org.odfi.eda.h2dl.tool.msys.MsysInstall
import org.odfi.indesign.core.module.IndesignModule
import org.odfi.eda.h2dl.tool.msys.MsysHarvester
import org.odfi.eda.h2dl.tool.msys.MsysModule

object IVerilogModule extends IndesignModule {
  
  this.onInit {
    requireModule(MsysModule)
    MsysHarvester --> ICarusHarvester
  }
  
  
}


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
   
  this.onDeliverFor[MsysInstall] {
    case msys => 
      
      // Search for tool
      msys.hasSubFile("mingw64","bin","iverilog.exe") match {
        case Some(iverilog) => 
          gather(new IVerilogTool(iverilog))
          
          msys.hasSubFile("mingw64","bin","vpp.exe") match {
            case Some(vppFile) => 
               gather(new VPPTool(vppFile))
               true
            case other => false
          }
          
        case other => false
      }
       
      
  }
}