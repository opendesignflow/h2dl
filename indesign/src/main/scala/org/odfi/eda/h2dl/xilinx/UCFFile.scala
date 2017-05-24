package org.odfi.eda.h2dl.xilinx

import org.odfi.indesign.core.resources.TextSourceResource
import org.odfi.indesign.core.resources.FileTextSourceResource
import org.odfi.indesign.core.harvest.fs.HarvestedFile
import org.odfi.eda.h2dl.verilog.SignalDefinition

class UCFFile(f:HarvestedFile) extends FileTextSourceResource(f.path) {
  
  
  def getNetForSchematic(sch:String) = {
    
    getLines.find {
      l => 
        //println("TEsting line: "+l)
        ("""sch\s+name\s*=(.*)""").r.findFirstMatchIn(l.trim().toLowerCase()) match {
          case Some(m) => 
            m.group(1).contains(sch)
          case None => false
        }
      
    } match {
      case Some(foundLine) => 
        
       // println("Found line: "+foundLine)
        SignalDefinition("""NET\s+"([\w<>_-]+)"""".r.findFirstMatchIn(foundLine).get.group(1))
      
      case None => None
    }
    
  }
}