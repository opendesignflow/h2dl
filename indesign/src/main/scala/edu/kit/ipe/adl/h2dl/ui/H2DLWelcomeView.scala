package edu.kit.ipe.adl.h2dl.ui

import edu.kit.ipe.adl.indesign.core.module.ui.www.IndesignUIView
import edu.kit.ipe.adl.h2dl.tool.icarus.VPPTool
import edu.kit.ipe.adl.h2dl.tool.icarus.ICarusHarvester
import edu.kit.ipe.adl.indesign.tcl.module.TCLModule
import edu.kit.ipe.adl.h2dl.tool.gtkwave.GTKWaveTool
import edu.kit.ipe.adl.h2dl.tool.gtkwave.GTKWaveHarvester
import edu.kit.ipe.adl.h2dl.tool.icarus.IVerilogTool

class H2DLWelcomeView extends IndesignUIView {

  this.viewContent {

    div {
      h1("H2DL Analyser") {

      }
      p {
        textContent("Welcome to H2DL")
      }
      
      h2("Sanity Check") {
        
      }
      "ui segment" :: div {

        GTKWaveHarvester.getResources.size match {
          case 0 =>
            "ui warning message" :: div {
              textContent("GTK Wave tool not found or not present")
            }
          case _ =>
            GTKWaveHarvester.getResource[GTKWaveTool] match {
              case Some(iverilog) =>
                "ui  success message" :: div { textContent("GTKWave is present") }
              case None =>
                "ui error message" :: div { textContent("GTKWave is not present") }
            }
          
        }
        ICarusHarvester.getResource[IVerilogTool] match {
          case Some(iverilog) =>
            "ui  success message" :: div { textContent("IVerilog is present") }
          case None =>
            "ui error message" :: div { textContent("IVerilog is not present") }
        }
        ICarusHarvester.getResource[VPPTool] match {
          case Some(iverilog) =>
            "ui success message" :: div { textContent("VPP Simulator is present") }
          case None =>
            "ui error message" :: div { textContent("VPP Simulator is not present") }
        }

        // TCL Reload
        "ui info message" :: div {
          textContent("Reload TCL Interpreter")
          "ui button" :: button("Reload") {
            onClick {
              var interpreter = TCLModule.getInterpreter("default")
              // TCLModule.reloadInterpreterPackages("default")
              interpreter.forgetPackages("*odfi*")
              TCLModule.reloadInterpreterPackages("default")
            }
          }
        }

      }
      // EOF Tools
    }

  }
}