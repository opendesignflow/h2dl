package edu.kit.ipe.adl.h2dl.tool.rsync

import java.io.File

import edu.kit.ipe.adl.h2dl.tool.ExternalTool
import edu.kit.ipe.adl.h2dl.tool.ExternalToolFolder
import edu.kit.ipe.adl.h2dl.tool.ExternalToolFolder
import edu.kit.ipe.adl.indesign.core.harvest.Harvester

/*
class GTKWaveFolder extends ExternalToolFolder {
  
   
  
}*/

class RsyncTool(p: File) extends ExternalTool(p) {

}
object RsyncToolHarvester extends Harvester {

  this.onDeliverFor[ExternalToolFolder] {
    case tf if (tf.toolId == "rsync" || new File(tf.path.toFile, "bin/rsync.exe").exists) =>
      gather(new RsyncTool(new File(tf.path.toFile(), "bin"+File.separator+"rsync.exe")).deriveFrom(tf))
      true
    case tf if (tf.toolId == "rsync" || new File(tf.path.toFile, "bin/rsync").exists) =>
      gather(new RsyncTool(new File(tf.path.toFile(), "bin/rsync")).deriveFrom(tf))
      true

  }

}