package org.odfi.eda.h2dl.verilog

import org.odfi.indesign.core.harvest.HarvestedResource

class SignalDefinition(val name: String) extends HarvestedResource {

  def getId = name

  var lsb = -1
  var msb = -1

  def toSignalName = {

    (lsb, msb) match {
      case (-1, -1)                 => s"""${name}"""
      case (-1, msb) if (msb != -1) => s"""${name}[$msb]"""
      case (lsb, msb)               => s"""${name}[$msb:$lsb]"""
    }

  }
}

object SignalDefinition {

  val signalDefinition = """([\w_]+)(?:\[([\d]+)(?::([\d]+))?\])""".r

  def apply(str: String) = {

    //-- Replace <> by [] and remove spaces
    val input = str.trim().replace('<', '[').replace('>', ']').replace(" ", "")
    
    //println("Building on: "+input)
    
    //-- parse
    signalDefinition.findFirstMatchIn(input) match {
      case Some(matched) =>

        var sd = new SignalDefinition(matched.group(1))
        matched.group(2) match {
          case null =>
          case msb  => sd.msb = msb.toInt
        }
        matched.group(3) match {
          case null =>
          case lsb  => sd.lsb = lsb.toInt
        }

        Some(sd)
      case None => None
    }

  }
}