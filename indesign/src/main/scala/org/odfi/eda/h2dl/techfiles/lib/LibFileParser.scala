package org.odfi.eda.h2dl.techfiles.lib

import scala.util.parsing.combinator.RegexParsers
import org.odfi.indesign.core.harvest.HarvestedResource
import org.odfi.indesign.core.harvest.HarvestedResourceDefaultId
import org.odfi.indesign.core.resources.RegexpTextSourceResource
import org.odfi.indesign.core.resources.StringTextSourceResource
import org.apache.commons.lang3.StringEscapeUtils

class Section(val stype: String, val name: Option[String]) extends HarvestedResource {

  def getId = getClass.getCanonicalName + ":" + toString

  def getSubSection(t: String) = getDerivedResources[Section].find(s => s.stype == t)

  def getParameterDouble(pname: String) = getDerivedResources[Parameter].find(p => p.name == pname) match {
    case None => None
    case Some(p) =>
      Some(p.getSingleValue.toDouble)

  }

  def getParameterString(pname: String) = getDerivedResources[Parameter].find(p => p.name == pname) match {
    case None => None
    case Some(p) =>
      //  println("Parameter string: "+pname+" -> ")
      Some(p.getSingleValue)

  }

  def getParameterDoubleMatrix(pname: String, n: Int, m: Int) = {
    getDerivedResources[Parameter].find(p => p.name == pname) match {
      case None => None
      case Some(p) =>
        /*println("Values: " + p.getValuesArray)
        p.getValuesArray.foreach {
          n => 
            n.foreach {
              v => 
                print(v+" ")
            }
            println
        }*/

        Some(p.getValuesArray)

    }
  }

  /*var subsections = scala.collection.mutable.ArrayBuffer[Section]()
  var parameter
  def addSection(s:Section) = subsections+=s*/

}

class Parameter(val name: String, content: String) extends StringTextSourceResource(content) with RegexpTextSourceResource {

  def getUnescaped = StringEscapeUtils.unescapeJava(getTextContent).replaceAll("""\s""", "")

  /**
   * For single value, content is ": XXXX"
   */
  def getSingleValue = getTextContent.stripPrefix(":").trim.stripPrefix("\"").stripSuffix("\"").trim

  def getValuesArray = {
    //println("Values array: "+getUnescaped)
    getUnescaped.stripPrefix("(\"").stripSuffix("\")").trim.split("\"").map {
      line => line.trim.split(",").map(_.trim.toDouble)
    }
  }
}

object LibFileParser extends RegexParsers {

  // Stacking
  var sectionsStack = new scala.collection.mutable.ArrayStack[Section]()

  val sr = """([\w_]+)\s*\(\s*([\w_]+)?\s*\)\s*""".r

  def parameter = """([\w_]+)""".r ~ """(?s)[^;{]+""".r <~ ";" ^^ {
    case name ~ content =>
      // println("P: " + name)
      sectionsStack.head.addDerivedResource(new Parameter(name.trim(), content.trim()))
  }

  // Section
  //-------------
  lazy val sectionType = """([\w_]+)""".r
  lazy val sectionName = """[\w_," ]+""".r

  lazy val sectionStart = (sectionType <~ "(") ~ sectionName.? <~ ")" ~> "{" ^^ {
    case sectionType ~ name =>

      var section = new Section(sectionType, name)
      sectionsStack.headOption match {
        case Some(parent) =>
          //println("NS: "+parent+" -> "+section)
          parent.addDerivedResource(section)
        case None =>
      }
      sectionsStack.push(section)

  }

  lazy val sectionEnd = Parser("}") ^^ {
    r =>
      // println("EOF Section: "+sectionsStack.size)
      sectionsStack.pop()

  }

  /*def section: Parser[(String, String)] = sectionHead ~> "{" ~ ((sectionHead ~> "{") | "}" | parameter).+ <~ "}" ^^ {
    case r =>
      (r._1, "B")
  }*/
  val section: Parser[Section] = sectionStart ~ (parameter | section).+ ~ sectionEnd ^^ {
    case r =>
      r._2
  }

  // Parameter
  //------------------

  def parseString(str: String) = {

    sectionsStack.clear()
    parseAll(LibFileParser.section, str.replaceAll("""/\*[^/]+\*/""", "")) match {
      case Success(result, _)                         => result
      case failure: NoSuccess if (failure.next.atEnd) => sectionsStack.pop()
      case failure: NoSuccess =>
        println("Err at: " + failure.next.pos.line + " -> " + failure.next.atEnd)
        scala.sys.error(failure.msg)

    }

  }

}