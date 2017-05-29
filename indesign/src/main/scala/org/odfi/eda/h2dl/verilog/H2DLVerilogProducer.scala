package org.odfi.eda.h2dl.verilog

import org.odfi.eda.h2dl.hdl.HDLHierarchy
import org.odfi.eda.h2dl.hdl.HierarchyTrait
import java.io.FileOutputStream
import java.io.PrintStream
import java.io.File
import jdk.nashorn.internal.runtime.WithObject
import org.odfi.eda.h2dl.hdl.H2DLProducer

class H2DLVerilogProducer extends H2DLProducer {

  def toVerilog(f: File, h: HierarchyTrait): Unit = {
    val outS = new FileOutputStream(f)
    val ps = new PrintStream(outS)
    try {
      toVerilog(ps, h)
    } finally {
      ps.close
      outS.close
    }
  }
  def toVerilog(out: PrintStream, h: HierarchyTrait): Unit = {

    this.withStream(out) {
      //-- Name
      println(s"module ${h.name} (");
      try {

        //-- IO
        //--------------
        indent {
          println(h.inputs.map {
            input =>
              s"input ${input.name}"
          } ++ h.outputs.map {
            output =>
              s"output ${output.name}"
          } ++ h.ios.map {
            io =>
              s"io ${io.name}"
          },",\n")
        }
        println(");")

        // Logic
        //--------------
        h.synchronousLogics.foreach {
          sl =>
            
            //-- Clock and reset
            printIndent
            print(s"always @(posedge ${sl.clock} ")
            println(") begin")
            
            
            println("end")
        }

      } finally {
        //-- Finish Module
        println("endmodule")
      }

    }
    // EOF Stream
  }

}