package edu.kit.ipe.adl.h2dl.verilog

import org.odfi.indesign.core.harvest.Harvester
import org.odfi.indesign.core.harvest.fs.HarvestedFile
import java.nio.file.Path
import org.odfi.tcl.module.TCLModule
import org.odfi.tcl.nx.NXObject
import edu.kit.ipe.adl.h2dl.doc.CrossReferenceContainerFile
import org.odfi.indesign.core.resources.TextSourceResource
import org.odfi.indesign.ide.core.sources.SourceCodeStringContent
import edu.kit.ipe.adl.h2dl.module.hdl.ui.HDLHierarchyProvider
import edu.kit.ipe.adl.h2dl.module.hdl.ui.Hierarchy
import edu.kit.ipe.adl.h2dl.module.hdl.ui.HierarchyProvideSuccess
import org.odfi.indesign.ide.core.sources.outline.SourceOutlineProviderWithErrorCatching
import org.odfi.indesign.ide.core.sources.analyze.CCommentAnalyzerHelper
import org.odfi.indesign.ide.core.sources.outline.Outline

object VerilogFileHarvester extends Harvester {

  this.onDeliverFor[HarvestedFile] {
    case f if (f.path.toFile().getAbsolutePath.endsWith(".v")) =>
      gather(new VerilogFile(f))
      true
  }
}

trait VerilogSource extends TextSourceResource with SourceOutlineProviderWithErrorCatching with CCommentAnalyzerHelper {

  // Regexp
  val moduleNameRegexp = """module\s+([\w_]+)\s*\(""".r
  val ioRegexp = """(input|output)\s+(?:(wire|reg)\s+)?(?:(\[(\d+):(\d+)\])\s+)?([\w_]+)""".r
  val variableRegexp = """(?m)^[ \t]*(wire|reg|logic)\s+(?:(wire|reg)\s+)?(?:(\[(\d+):(\d+)\])\s+)?([\w_]+);""".r
  val posedgeRexp = """(?m)^\s*always\s*@\s*\(\s*posedge\s+([\w]+).*\)\s*begin""".r

  // Syntax Check
  //---------------------

  // Parsing
  //-----------
  def getModuleName = {

    moduleNameRegexp.findFirstMatchIn(getTextContent) match {
      case None => None
      case Some(m) => Some(m.group(1))
    }

  }

  // Hierarchy
  //---------------
  outlineClass = Some("h2dl-hdl-diagram")
  def buildOutline = {

    var textWithoutComments = getTextWithoutCComment
    
    //-- Create Hierarchy
    //------------
    var h = new Outline

    // Hierarchy DIagram and text outline
    //------------------
    var diagramOutline = h.views.add
    diagramOutline.name = this.getModuleName.get
    diagramOutline.viewClass = "h2dl-hdl-diagram"
    diagramOutline.viewName = "Diagram"

    var diagramDefaultSection = diagramOutline.outlineSections.add
    diagramDefaultSection.name = "default"

    var textOutline = h.views.add
    textOutline.name = this.getModuleName.get
    textOutline.viewName = "Outline"
    textOutline.viewClass = "outline-text"

    // Create IO section for text
    var textOutlineIO = textOutline.outlineSections.add
    textOutlineIO.name = "IO"

    // Ios
    ioRegexp.findAllMatchIn(textWithoutComments).foreach {
      m =>

        //println(s"Matched ${m.group(6)} before: "+ m.before)
        var linesBefore = lineOfMatch(m)

        //-- Add IO To Diagram
        var element = diagramDefaultSection.outlineElements.add
        element.type_ = m.group(1)
        element.name = m.group(6)

        var hint = element.hints.add
        hint.name = "line"
        hint.value = (linesBefore).toString

        //-- Add to Outline
        var ioElement = textOutlineIO.outlineElements.add
        ioElement.type_ = m.group(1)
        ioElement.name = m.group(6)

        hint = ioElement.hints.add
        hint.name = "line"
        hint.value = (linesBefore).toString

    }

    // Registers and Wires
    //------------
    var textOutlineRegAndWires = textOutline.outlineSections.add
    textOutlineRegAndWires.name = "Registers/Wires"

    variableRegexp.findAllMatchIn(textWithoutComments).foreach {
      m =>

        var line = lineOfMatch(m)

        // Outline element
        var regWireElement = textOutlineRegAndWires.outlineElements.add
        regWireElement.name = m.group(6)
        var hint = regWireElement.hints.add
        hint.name = "line"
        hint.value = line.toString
    }

    // Sync stages
    //-------------
    var posedgeMatches = posedgeRexp.findAllMatchIn(textWithoutComments)
    if (!posedgeMatches.isEmpty) {
      var textOutlinePosedge = textOutline.outlineSections.add
      textOutlinePosedge.name = "Posedge"
      posedgeMatches.foreach {
        m =>

          // Add posedge outline element
          var posedgeElement = textOutlinePosedge.outlineElements.add
          var line = lineOfMatch(m)
          var hint = posedgeElement.hints.add
          hint.name = "line"
          hint.value = line.toString

          // Name of element
          posedgeElement.name = this.commentBeforeLine(line) match {
            case Some(commentLineContent) => commentLineContent
            case None => "Posedge: "+m.group(1)
          }
          

      }
    }

    h
  }

}
class VerilogSourceString(content: String) extends SourceCodeStringContent(content) with VerilogSource

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

  /*def getUpchainDesignGroup = this.findUpchainResource[DesignGroupResource] match {
    case Some(mp: DesignGroupResource) =>

      mp

    case _ =>
      sys.error("Cannot find design group  in parent resources")
  }
*/
  /*this.onGathered {
    case h if(h.isInstanceOf[VerilogFIleHarvester])=> 
      
      println(s"***** Gathered Verilog File: $this")
      getUpchainDesignGroup.watcher.onFileChange(this, path.toFile){
        f => 
          this.h2dlResult = None
     }
  }*/

}