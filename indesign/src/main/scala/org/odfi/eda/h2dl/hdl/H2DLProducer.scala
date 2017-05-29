package org.odfi.eda.h2dl.hdl

import java.io.PrintStream

trait H2DLProducer {
  
  var currentIndent = 0
  
  def indentString = (0 to currentIndent).map("    ").mkString
  
  def indent(cl: => Any) = {
    try {
      currentIndent += 1
      cl
    } finally {
      currentIndent-=1
    }
  }
  
  // Output util
  //------------
  var selectedOut : Option[PrintStream] = None
  var indentPrinted = false
  
  def selectOut(p:PrintStream) = selectedOut = Some(p)
  
  def println(strs:Iterable[String],sep:String = "") : Unit = {
    println(strs.mkString(sep+indentString))
  }
  def println(str:String) : Unit = indentPrinted match {
    case true => 
      selectedOut.get.println(str)
      indentPrinted=true
    case false => 
      selectedOut.get.println(indentString+str)
  }
  def print(str:String) = selectedOut.get.print(str)
  def printIndent = {
    indentPrinted = true
    selectedOut.get.print(indentString)
  }
  
  def withStream(p:PrintStream)(cl: =>Any) = {
    try {
      selectOut(p)
      cl
    } finally {
      selectedOut = None
    }
  }
  
}