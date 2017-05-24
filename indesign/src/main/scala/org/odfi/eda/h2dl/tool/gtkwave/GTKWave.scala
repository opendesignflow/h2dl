package org.odfi.eda.h2dl.tool.gtkwave

import java.io.File

import org.odfi.eda.h2dl.tool.ExternalTool
import org.odfi.eda.h2dl.tool.ExternalToolFolder
import org.odfi.eda.h2dl.tool.ExternalToolFolder
import org.odfi.indesign.core.harvest.Harvester

/*
class GTKWaveFolder extends ExternalToolFolder {
  
   
  
}*/

class GTKWaveTool(p: File) extends ExternalTool(p) {

}
object GTKWaveHarvester extends Harvester {

  this.onDeliverFor[ExternalToolFolder] {
    case tf if (tf.toolId == "gtkwave" || new File(tf.path.toFile, "bin/gtkwave.exe").exists) =>
      gather(new GTKWaveTool(new File(tf.path.toFile(), "bin\\gtkwave.exe")).deriveFrom(tf))
      true
    case tf if (tf.toolId == "gtkwave" || new File(tf.path.toFile, "bin/gtkwave").exists) =>
      gather(new GTKWaveTool(new File(tf.path.toFile(), "bin/gtkwave")).deriveFrom(tf))
      true

  }

}