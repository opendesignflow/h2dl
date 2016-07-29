package edu.kit.ipe.adl.h2dl.techfiles.lib

import edu.kit.ipe.adl.indesign.core.harvest.Harvester
import edu.kit.ipe.adl.indesign.core.harvest.fs.HarvestedFile
import edu.kit.ipe.adl.indesign.tcl.nx.NXObject
import edu.kit.ipe.adl.indesign.tcl.module.TCLModule

class LibFileHarvester extends Harvester {

  this.onDeliverFor[HarvestedFile] {
    case f if (f.path.toFile.getCanonicalPath.endsWith(".lib")) =>
      gather(new LibFile(f))
      true
  }

}

class LibFile(f: HarvestedFile) extends HarvestedFile(f.path) {
  deriveFrom(f)

  // Convert to LibFile
  //----------------

  var libFileModel: Option[NXObject] = None

  def getLibModel = libFileModel.getOrElse {

    //-- Parse

    //-- Get Interpreter
    var interpreter = TCLModule.getInterpreter("default")

    println(s"${hashCode()} PARSING: "+path)
    //-- Parse
    interpreter.evalString("package require odfi::implementation::libfile")
    libFileModel = Some(interpreter.evalString(s"""
    ::odfi::implementation::libfile::timinglib slow {

        :parseFile ${path.toFile().getCanonicalPath.replace('\\','/')}

      }
      return $$slow
      """).asObjectValue.asNXObject)
    libFileModel.get

  }
}