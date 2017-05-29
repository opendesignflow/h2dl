package org.odfi.eda.h2dl.techfiles.lib

import org.odfi.indesign.core.harvest.Harvester
import org.odfi.indesign.core.harvest.fs.HarvestedFile
import org.odfi.tcl.nx.NXObject
import org.odfi.tcl.module.TCLModule
import com.idyria.osi.tea.progress.ProgressSupport
import org.odfi.indesign.core.resources.TextSourceResource
import org.odfi.indesign.core.resources.FileTextSourceResource
import org.odfi.indesign.core.resources.RegexpTextSourceResource
import org.odfi.indesign.core.resources.StringTextSourceResource
import org.odfi.indesign.core.harvest.HarvestedResource
import javax.swing.text.html.HRuleView
import org.odfi.indesign.core.harvest.HarvestedResourceDefaultId

object LibFileHarvester extends Harvester with ProgressSupport {

  this.onDeliverFor[HarvestedFile] {
    case f if (f.path.toFile.getCanonicalPath.endsWith(".lib")) =>
      gather(new LibFile(f))
      true
  }

  def parseAllLibs = {

    progressInit("Parsing All libraries")

    val allLibFiles = LibFileHarvester.getResourcesOfType[SLibFile]
    allLibFiles.zipWithIndex.foreach {
      case (r, i) =>
        // progressInit("Parsing "+r.path)

        r.parse

        progressUpdate(i * 100 / (allLibFiles.size - 1))
    }

    allLibFiles
  }

  def getSLibFile(name: String) = this.getResourceById[SLibFile](name)

}

trait SectionBasedResource extends HarvestedResource {

  def getId = toString

  def getSections = getDerivedResources[Section]
  def getSection = getSections.head
}

class SLibFile(f: HarvestedFile) extends FileTextSourceResource(f.path) with RegexpTextSourceResource with SectionBasedResource {
  deriveFrom(f)

  // Lib Name
  //---------------
  val libName = this.getNameNoExtension

  override def getId = libName

  // Strenght Divider
  //---------------
  var strengthDivider = 'X'

  // Regexp
  //----------------
  val cellsRegexp = """cell\s*\(([\w]+)\)\s*\{((?:[^\{\}]|\{[^\}]*\})*)\}"""
  val cellsNameRegexp = """cell\s*\(([\w]+)\)"""

  // Parse Lib File
  //-----------------------
  def parse = {

    if (getSections.size == 0) {

      val libSection = LibFileParser.parseString(getTextContent)
      addDerivedResource(libSection)

      /* libSection.getDerivedResources[Section].foreach {
      s => 
        println("Section: "+s.stype)
    }*/

      // Map to cells
      //----------
      val cells = libSection.getDerivedResources[Section].collect {
        case cellSection if (cellSection.stype == "cell") =>

          var c = new SLibCell(cellSection.name.get)
          c.addDerivedResource(cellSection)
          c

      }

      // Create groups
      //------------------
      cells.groupBy(cell => cell.name.takeWhile(_ != strengthDivider)).foreach {
        case (logicName, cells) =>
          val group = addDerivedResource(new SLibLogicGroup(logicName))
          group.addDerivedResources(cells)
      }

    }

    this
  }

  // Cells Selection
  //-------------------

  /**
   * Get all the logic cells answering the logic function "function"
   * for example: AND2 will return AND2 cells for all strengths
   */
  def getLogicCells(function: String) = {

    this.getDerivedResources[SLibLogicGroup].find(g => g.name == function)

    /*this.getDerivedResources[SLibCell].collect {
      case cell if (cell.name.startsWith(function)) => cell
    }*/

  }
}

class SLibLogicGroup(val name: String) extends HarvestedResource {

  def getId = name

  /**
   * uses strength and checks against cell Strength using "startsWith"
   * Strength are usually like "1","2" etc... but depending on the Threshold wil be like "1", "1HVT","1LVT"
   */
  def getCellByStrength(strength: String) = this.getDerivedResources[SLibCell].find(_.getStrength.startsWith(strength))

  def getCellsNames = getCellsSortedByStrength.map(_.name).toList

  def getCellsArea = getCellsSortedByStrength.map(_.getArea.get).toList

  def getCellsLeakageMinMeanMax = getCellsSortedByStrength.map(cell => Tuple3(cell.getLeakageMin, cell.getLeakageMeanValue, cell.getLeakageMax))

  def getCellsLeakageMean = getCellsSortedByStrength.map(cell => cell.getLeakageMeanValue)

  /**
   * Return cells by strength
   */
  def getCellsSortedByStrength = {
    this.getDerivedResources[SLibCell].sortBy(cell => cell.getStrength)
  }
}

class SLibCell(val name: String) extends SectionBasedResource {

  /**
   *
   */
  def getStrength = {
    //println(s"Taking digit: "+name.reverse)
    //name.reverse.takeWhile(_.isDigit).reverse.mkString.toInt
    name.split(findTopMostResource[SLibFile].get.strengthDivider).last
  }

  /**
   * Area as String
   */
  def getArea = {

    getSection.getParameterDouble("area")
    //None

    //regexpExtractFirstGroupCached("""area\s*:\s*([0-9\.]+)\s*;""")
  }

  // Pins
  //-----------
  def getPins = {
    List[SCellPin]()

    getDerivedResourcesOrElseSave[SCellPin] {

      // Get all leakage section
      getSection.getDerivedResources[Section].collect {
        case pins if (pins.stype == "pin") =>

          val pin = new SCellPin(pins.name.get)
          pin.addDerivedResource(pins)
          pin
      }
    }
    /*println("Get pins on: " + getTextContent)
    getDerivedResourcesOrElseSave[SCellPin] {
      regexpExtractAllList("""\spin\s*\(([\w]+)\)\s*\{((?:[^\{\}]|\{(?:[^\{\}]|\{[^\}]*\})*\})*)\}""") map {
        matchRes =>
          println("Building pin: " + matchRes(1))
          new SCellPin(matchRes(1), matchRes(2))
      }
    }*/
  }

  def getPin(name: String) = getPins.find(p => p.name == name)

  def getTimingForPin(pin: String, relatedPin: String) = getPin(pin) match {
    case None => None
    case Some(pin) =>
      pin.getTimingForRelatedPin(relatedPin)
  }

  // Leackage
  //---------

  def getLeakages = {

    getDerivedResourcesOrElseSave[SCellLeakage] {

      // Get all leakage section
      getSection.getDerivedResources[Section].collect {
        case lps if (lps.stype == "leakage_power") =>

          val lp = new SCellLeakage
          lp.addDerivedResource(lps)
          lp
      }

    }
    /*getDerivedResourcesOrElseSave[SCellLeakage] {
      regexpExtractAllList("""leakage_power\s*\(\s*\)\s*\{((?:[^\{\}]|\{[^\}]*\})*)\}""") map {
        matchRes =>
          new SCellLeakage(matchRes(1))
      }
    }*/

  }

  def getLeakageMeanValue = {
    getLeakages.map(l => l.getValue.get).sum / getLeakages.size
  }

  def getLeakageMin = {
    getLeakages.map(l => l.getValue.get).min
  }

  def getLeakageMax = {
    getLeakages.map(l => l.getValue.get).max
  }

}

class SCellLeakage extends SectionBasedResource {

  // def getValue = regexpExtractFirstGroupCached("""value\s*:\s*([0-9\.]+)\s*;""").get.toDouble
  def getValue = getSection.getParameterDouble("value")
}

class SCellPin(val name: String) extends SectionBasedResource {

  //def getValue = regexpExtractFirstGroupCached("""value\s*:\s*([0-9\.]+)\s*;""").get.toDouble

  // Timing
  //--------------
  def getTimings = {

    getDerivedResourcesOrElseSave[SCellPinTiming] {

      // Get all leakage section
      getSection.getDerivedResources[Section].collect {
        case pts if (pts.stype == "timing") =>

          val timing = new SCellPinTiming
          timing.addDerivedResource(pts)
          timing
      }

    }

    /* getDerivedResourcesOrElseSave[SCellPinTiming] {
      regexpExtractAllList("""timing\s*\(\s*\)\s*\{((?:[^\{\}]|\{[^\}]*\})*)\}""") map {
        matchRes =>
          new SCellPinTiming(matchRes(1))
      }
    }*/
  }

  def getTimingForRelatedPin(relatedName: String) = {
    getTimings.find(t => t.getRelatedPin.isDefined && t.getRelatedPin.get == relatedName)
  }

}
class SCellPinTiming extends SectionBasedResource {

  //def getRelatedPin = regexpExtractFirstGroupCached("""related_pin\s*:\s*\"([\w]+)\"\s*;""")
  def getRelatedPin = getSection.getParameterString("related_pin")

  def getMeanRiseDelay = {

    getRiseDelays.get.map {
      n =>
        n.sum

    }.sum / 4
  }

  /**
   *
   *
   * lu_table_template (delay_template_2x2) {
   * variable_1 : input_net_transition;
   * variable_2 : total_output_net_capacitance;
   * index_1 ("0.008, 0.28");
   * index_2 ("0.01, 0.3");
   * }
   *
   *
   * cell_rise (delay_template_2x2) {
   * index_1 ("0.008, 0.28");
   * index_2 ("0.01, 0.25");
   * values ( \
   * "0.0769217, 0.963489", \
   * "0.123879, 1.01086" \
   * );
   * }
   *
   *
   */
  def getRiseDelays = {
    val cell_rise = getSection.getSubSection("cell_rise").get
    val n = 2
    val m = 2

    //-- Get values
    cell_rise.getParameterDoubleMatrix("values", n, m)

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

    println(s"${hashCode()} PARSING: " + path)
    //-- Parse
    interpreter.evalString("package require odfi::implementation::libfile")
    libFileModel = Some(interpreter.evalString(s"""
    ::odfi::implementation::libfile::timinglib slow {

        :parseFile ${path.toFile().getCanonicalPath.replace('\\', '/')}

      }
      return $$slow
      """).asObjectValue.asNXObject)
    libFileModel.get

  }
}
