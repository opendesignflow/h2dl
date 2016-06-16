package edu.kit.ipe.adl.h2dl.ui

import edu.kit.ipe.adl.h2dl.DesignGroupHarvester
import edu.kit.ipe.adl.h2dl.DesignGroupResource
import edu.kit.ipe.adl.h2dl.tool.gtkwave.GTKWaveHarvester
import edu.kit.ipe.adl.h2dl.tool.gtkwave.GTKWaveTool
import edu.kit.ipe.adl.h2dl.tool.icarus.ICarusHarvester
import edu.kit.ipe.adl.h2dl.tool.icarus.IVerilogTool
import edu.kit.ipe.adl.h2dl.tool.icarus.VPPTool
import edu.kit.ipe.adl.indesign.core.harvest.Harvest
import edu.kit.ipe.adl.indesign.core.module.ui.www.IndesignUIView
import edu.kit.ipe.adl.indesign.tcl.module.TCLModule
import edu.kit.ipe.adl.h2dl.verilog.VerilogFIleHarvester
import edu.kit.ipe.adl.h2dl.verilog.VerilogFile
import edu.kit.ipe.adl.h2dl.vhdl.VHDLFile
import edu.kit.ipe.adl.h2dl.pdf.PDFFile
import java.net.URI
import edu.kit.ipe.adl.indesign.core.module.ui.www.external.SemanticUIView
import edu.kit.ipe.adl.indesign.module.pdf.PDFBuilder
import edu.kit.ipe.adl.h2dl.techfiles.lib.LibFile
import edu.kit.ipe.adl.h2dl.techfiles.lef.LEFFile
import edu.kit.ipe.adl.h2dl.techfiles.tf.TechFile
import edu.kit.ipe.adl.h2dl.techfiles.lib.LibFileView
import edu.kit.ipe.adl.h2dl.tool.rsync.RsyncToolHarvester
import edu.kit.ipe.adl.h2dl.tool.rsync.RsyncTool
import java.io.File

class H2DLWelcomeView extends IndesignUIView with SemanticUIView with PDFBuilder {

  var selectedGroup: Option[DesignGroupResource] = None

  var selectedView: Option[IndesignUIView] = None

  this.viewContent {

    html {
      head {

        script(new URI(createSpecialPath("resources", "indesign.js"))) {

        }
        script(new URI(createSpecialPath("resources", "jquery.tablesort.min.js"))) {

        }
      }
      // EOF Head

      body {

        "ui two column doubling stackable nested grid" :: div {

          "six wide column " :: div {
            id("left-column")
            h2("H2DL Analyser 2") {

            }
            p {
              textContent("""
          Welcome to H2DL toolchain.
          We will use this software to train Verilog/VHDL based digital designs.
          For now analysis and simulation open source tools are embedded.""")
            }

            h3("Selecting a Lecture Content") {

            }
            p {
              textContent("""
          The lecture source files are 
          located in folders named after the lecture
          
          After selecting a lecture in the following table, the tool will only show relevant content
          """)
            }
            RsyncToolHarvester.getResource[RsyncTool] match {
              case Some(rsyncTool) =>
                "ui button" :: button("Refresh") {
                  reRender
                  onClick {
                    var rsyncTool = RsyncToolHarvester.getResource[RsyncTool].get
                    var out = new File("temprsync")
                    out.mkdirs
                    var process = rsyncTool.createToolProcess(Array("-avr", "ipe-iperic-srv1.ipe.kit.edu::adl/special_installs/lectures/ss16/vorlesung/*", "."), out)

                    println(s"Running RSYNC")
                    process.outputToBuffer
                    process.startProcessAndWait
                    println(s"Result: " + process.getOutputString)
                  }
                }
              case None =>
                "ui warning message" :: div {
                  textContent("Cannot Remote Pull Lecture Content Because Rsync Tool is missing")
                }
            }

            "ui table" :: table {
              thead {
                th("Lecture Name") {

                }
                th("Select") {

                }
              }
              tbody {

                Harvest.onHarvesters[DesignGroupHarvester] {
                  case h =>

                    h.onResources[DesignGroupResource] {
                      case dg =>

                        // Preselect if necessary
                        selectedGroup match {
                          case None => selectedGroup = Some(dg)
                          case Some(group) =>
                        }

                        // Ui
                        tr {
                          td(dg.path.toFile().getName) {

                          }
                          td("") {
                            input {
                              +@("type" -> "radio")
                              +@("name" -> "selected-designGroup")
                              +@("value" -> dg.name)
                              if (selectedGroup.get == dg) {
                                +@("checked" -> "true")
                              }
                              bindValue {
                                v: String =>
                                  println("Selecting: " + v)
                                  selectedGroup = Some(dg)
                                  detachView("h2dlview")
                              }
                            }
                          }
                        }
                    }
                }

              }
            }
            // EOF LEcture table

            h3("Lecture Files") {

            }
            selectedGroup.get.hasDerivedResourceOfType[PDFFile] match {
              case true =>

                // use the first one embedded
                var pdf = selectedGroup.get.findDerivedResourceOfType[PDFFile].get
                "ui sticky" :: div {
                  +@("data-sticky-context" -> "left-column")
                  
                  val pdfPath = s"/h2dl/resources/${selectedGroup.get.path.toFile().getName}/${selectedGroup.get.path.relativize(pdf.path).toString.replace("\\", "/")}"
                  pdfCanvas(pdfPath, "lecturepdf")

                  "ui button" :: button("Previous Page") {
                    +@("onclick" -> "indesign.pdfjs.previousPage('lecturepdf')")
                  }
                  "ui button" :: button("Next Page") {
                    +@("onclick" -> "indesign.pdfjs.nextPage('lecturepdf')")
                  }
                  
                  "ui" :: a(pdfPath) {
                    +@("target" -> "_blank")
                    textContent("Open in new Tab")
                  }
                  
                }

              case false =>
                "ui info message" :: div {
                  textContent("No Lecture Files Available")
                }
            }

            // Sanity check
            /*h3("Sanity Check") {

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

            }*/
            // EOF Tools check

          }
          // EOF lEcture part
          //-------------------------

          "ten wide column" :: div {

            /*h2("Analysis  View 7 ") {

            }*/

            "ui pointing menu" :: div {

              // Menus
              //---------------  
              if (selectedGroup.get.hasDerivedResourceOfType[VerilogFile]) {
                "item" :: a("#") {
                  textContent("Verilog Analyser")
                  reRender
                  onClick {
                    placeView(new H2DLVerilogAnalyser, "h2dlview", false)
                  }
                }
              }

              if (selectedGroup.get.hasDerivedResourceOfType[LibFile]) {
                "item" :: a("#") {
                  textContent("LibFile Analyser")
                  reRender
                  onClick {
                    placeView(new LibFileView, "h2dlview", false)
                  }
                }
              }

              if (selectedGroup.get.hasDerivedResourceOfType[LEFFile]) {
                "item" :: a("#") {
                  textContent("LEF File Analyser")
                  reRender
                  onClick {
                    placeView(new H2DLVerilogAnalyser, "h2dlview", false)
                  }
                }
              }

              if (selectedGroup.get.hasDerivedResourceOfType[TechFile]) {
                "item" :: a("#") {
                  textContent("TechFile Analyser")
                  reRender
                  onClick {
                    placeView(new H2DLVerilogAnalyser, "h2dlview", false)
                  }
                }
              }

              if (selectedGroup.get.hasDerivedResourceOfType[VHDLFile]) {
                "item" :: a("") {
                  textContent("VHDL Analyser")
                }
              }

              "item" :: a("#") {
                textContent("TCL Control")
                reRender
                onClick {
                  placeView(new TCLView, "h2dlview", false)
                }
              }

            }

            viewPlaceHolder("h2dlview", "ui segment") {
              p {
                textContent("Select an Analysis View")
              }
            }

          }
          // EOF Analysis
          //-------------------------
        }
        // EOF Page

        script(new URI(s"${viewPath}/resources/h2dl.js")) {

        }

      }
      // EOF Body
    }

  }
}