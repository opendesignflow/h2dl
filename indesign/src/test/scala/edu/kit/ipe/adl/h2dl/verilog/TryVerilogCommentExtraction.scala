package edu.kit.ipe.adl.h2dl.verilog

import org.odfi.indesign.core.harvest.fs.HarvestedFile
import java.io.File

object TryVerilogCommentExtraction extends App {
  
  var vfile = new VerilogFile(new HarvestedFile(new File("src/test/resources/verilog/counter.v").toPath))
  
  var res = vfile.convertLinesToCrossReferenced
  
  var foundCR = res.find( p => p.isDefined)


    println(s"Found CR: "+foundCR)
}
