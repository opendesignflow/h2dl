package edu.kit.ipe.adl.h2dl.project

import org.odfi.indesign.core.harvest.fs.FileSystemHarvester
import org.odfi.indesign.core.harvest.Harvester
import org.odfi.indesign.ide.core.project.ProjectHarvesterTrait
import org.odfi.indesign.core.harvest.fs.HarvestedFile


object H2DLProjectHarvester extends FileSystemHarvester with ProjectHarvesterTrait {
  
  
    
  this.onDeliverFor[HarvestedFile] {
    case f if (f.isDirectory && f.hasSubFile("h2dl.txt").isDefined) =>
      println("Deliered H2DL Project")
      gather(new H2DLProject(f))
      true
    case f if (f.isFile() && f.getName=="h2dl.txt") => 
       println("Delivered H2DL Project")
      gather(new H2DLProject(new HarvestedFile(f.getParentFile.toPath())))
      true
  }
  
  
}

class H2DLProject(p:HarvestedFile) extends HarvestedFile(p.path) {
  deriveFrom(p)
}

