package edu.kit.ipe.adl.h2dl.tool

import java.io.File

import edu.kit.ipe.adl.indesign.core.harvest.Harvester
import edu.kit.ipe.adl.indesign.core.harvest.fs.HarvestedFile
import java.nio.file.Path
import org.bridj.BridJ

class ExternalToolHarvester(var basePath: File) extends Harvester {

  basePath.mkdirs
  override def doHarvest = {
    
    this.gather(new ExternalToolFolder(basePath.toPath))
    basePath.listFiles().foreach {
      
      case f if (f.getName.matches("""[\w]+-[0-9\.]+""")) => 
        println("Found tool: "+f.getAbsolutePath)
        var r = new ExternalToolFolder(f.toPath())
        this.gather(r)
        println("ID: "+r.toolId)
      case _ => 
      
    }

  
  }

}

class ExternalToolFolder(p:Path) extends HarvestedFile(p) {
  
  val nameRegexp = """([\w]+)-([\w0-9\._-]+)""".r
  val fullName = p.toFile().getName
  val nameRegexp(toolId,version) = fullName
  
  //-- Lib 
  var libFolder = new File(p.toFile(), "lib")
  libFolder.exists() match {
    case true =>
     // println("Found lib oflder: " + libFolder)
      System.setProperty("java.library.path", System.getProperty("java.library.path") + File.pathSeparator + libFolder)
      BridJ.addLibraryPath(libFolder.getAbsolutePath)
      //set sys_paths to null so that java.library.path will be reevalueted next time it is needed
      val sysPathsField = classOf[ClassLoader].getDeclaredField("sys_paths");
      sysPathsField.setAccessible(true);
      sysPathsField.set(null, null);
    //System.getProperty("java.library.path")
    case false =>
  }
  //-- Bin
  var binFolder = new File(p.toFile(), "bin")
  binFolder.exists() match {
    case true =>
      //println("Found bin oflder: " + binFolder)
      System.setProperty("java.library.path", System.getProperty("java.library.path") + File.pathSeparator + binFolder)
      BridJ.addLibraryPath(binFolder.getAbsolutePath)
      //set sys_paths to null so that java.library.path will be reevalueted next time it is needed
      val sysPathsField = classOf[ClassLoader].getDeclaredField("sys_paths");
      sysPathsField.setAccessible(true);
      sysPathsField.set(null, null);
    //System.getProperty("java.library.path")

    case false =>
  }
  
}