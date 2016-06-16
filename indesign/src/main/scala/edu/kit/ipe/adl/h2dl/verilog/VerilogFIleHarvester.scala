package edu.kit.ipe.adl.h2dl.verilog

import edu.kit.ipe.adl.indesign.core.harvest.Harvester
import edu.kit.ipe.adl.indesign.core.harvest.fs.HarvestedFile
import java.nio.file.Path
import edu.kit.ipe.adl.indesign.tcl.module.TCLModule
import edu.kit.ipe.adl.indesign.tcl.nx.NXObject
import edu.kit.ipe.adl.h2dl.DesignGroupResource
import edu.kit.ipe.adl.h2dl.doc.CrossReferenceContainerFile

class VerilogFIleHarvester extends Harvester {

  this.onDeliverFor[HarvestedFile] {
    case f if (f.path.toFile().getAbsolutePath.endsWith(".v")) =>
      gather(new VerilogFile(f))
      true
  }
}

class VerilogFile(f: HarvestedFile) extends HarvestedFile(f.path) with CrossReferenceContainerFile {
  this.deriveFrom(f)

  // Convert to H2DL
  //----------------

  var h2dlResult: Option[List[NXObject]] = None

  def getH2DLResults = h2dlResult.getOrElse {

    //-- Parse

    //-- Get Interpreter
    TCLModule.onInterpreter("default") {
      interpreter =>

        println(s"****** Running Parse $f*****")
        //-- Parse
        interpreter.evalString("package require odfi::h2dl::verilog::parse")
        h2dlResult = Some(interpreter.evalString(s"odfi::h2dl::verilog::parse::reverse ${path.toFile.getAbsolutePath.replace('\\', '/')}").asList.toNXList)
        h2dlResult.get
    }
    //var interpreter = TCLModule.getInterpreter("default")

  }

  def getModuleOfType(name: String): Option[NXObject] = {

    /*getH2DLResults.filter { m => m.getNXClass.toString == "::odfi::h2dl::Module" }.find {
      moduleCandidate =>
        moduleCandidate.name.toString == name
    }*/
    
    getH2DLResults.find {
      moduleCandidate =>
        moduleCandidate.name.toString == name
    }

  }

  // Listening
  //-----------------

  def getUpchainDesignGroup = this.findUpchainResource[DesignGroupResource] match {
    case Some(mp: DesignGroupResource) =>

      mp

    case _ =>
      sys.error("Cannot find design group  in parent resources")
  }

  /*this.onGathered {
    case h if(h.isInstanceOf[VerilogFIleHarvester])=> 
      
      println(s"***** Gathered Verilog File: $this")
      getUpchainDesignGroup.watcher.onFileChange(this, path.toFile){
        f => 
          this.h2dlResult = None
     }
  }*/

}