package org.odfi.eda.h2dl.techfiles.lib

import org.odfi.indesign.core.harvest.Harvester
import org.odfi.indesign.core.harvest.fs.HarvestedFile
import org.odfi.tcl.nx.NXObject
import org.odfi.tcl.module.TCLModule

object LibFileHarvester extends Harvester {

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