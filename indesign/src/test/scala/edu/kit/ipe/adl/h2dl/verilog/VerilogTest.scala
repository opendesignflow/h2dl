package edu.kit.ipe.adl.h2dl.verilog

import org.scalatest.FunSuite
import com.idyria.osi.tea.io.TeaIOUtils

object VerilogTest extends App  {
  
  var fileCode = new String(TeaIOUtils.swallow(getClass.getClassLoader.getResourceAsStream("verilog/LongFile.v")))
  var verilog = new VerilogSourceString(fileCode)
  
  println("Hier: "+verilog.toOutline.get.toXMLString)
  
}