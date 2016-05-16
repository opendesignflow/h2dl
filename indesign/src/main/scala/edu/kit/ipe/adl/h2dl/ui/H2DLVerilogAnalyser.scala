package edu.kit.ipe.adl.h2dl.ui

import edu.kit.ipe.adl.indesign.core.module.ui.www.IndesignUIView
import edu.kit.ipe.adl.indesign.core.harvest.Harvest
import edu.kit.ipe.adl.h2dl.verilog.VerilogFIleHarvester
import edu.kit.ipe.adl.h2dl.verilog.VerilogFile
import edu.kit.ipe.adl.h2dl.verilog.VerilogFile
import edu.kit.ipe.adl.h2dl.tool.gtkwave.GTKWaveHarvester
import edu.kit.ipe.adl.h2dl.tool.gtkwave.GTKWaveTool
import edu.kit.ipe.adl.indesign.tcl.module.TCLModule
import edu.kit.ipe.adl.h2dl.tool.icarus.ICarusHarvester
import edu.kit.ipe.adl.h2dl.tool.icarus.IVerilogTool
import edu.kit.ipe.adl.h2dl.tool.icarus.VPPTool
import edu.kit.ipe.adl.h2dl.tool.ToolProcess
import java.io.File
import edu.kit.ipe.adl.h2dl.tool.gtkwave.VCDFileHarvester
import edu.kit.ipe.adl.h2dl.tool.gtkwave.VCDFile
import edu.kit.ipe.adl.indesign.tcl.nx.NXObject
import edu.kit.ipe.adl.h2dl.main.VerilogAnalyse

class H2DLVerilogAnalyser extends IndesignUIView {

  var selectedFile: Option[VerilogFile] = None
  var runProcess: Option[ToolProcess] = None
  var simProcess: Option[ToolProcess] = None

  def resolveSourceFile(module: NXObject): Option[File] = {

    println(s"looking for: "+module.name.toString)
    var found: Option[File] = None
    Harvest.onHarvesters[VerilogFIleHarvester] {
      case h if (found.isEmpty) =>
        h.onResources[VerilogFile] {
          case r if (found.isEmpty) =>

            // Parse File
            var interpreter = TCLModule.getInterpreter("default")
            var results = interpreter.evalString(s"odfi::h2dl::verilog::parse::reverse ${r.path.toFile.getAbsolutePath.replace('\\', '/')}").asList.toNXList

            // Find Modules
            println(s"Tested file: "+r.path.toFile+" -> "+results+" -> "+results.head.name+"//"+results.head.getNXClass)
            results.size match {
              case 1 if (results.head.getNXClass == "::odfi::h2dl::Module" && results.head.name.toString == module.name.toString) =>
                found = Some(r.path.toFile)
              case _ =>
            }
          case _ =>

        }
      case _ =>
    }

    found
  }

  this.viewContent {

    div {

      h1("Verilog Toolchain") {

      }

      // Config
      //-------------
      "ui segment" :: div {
        h2("Configuration") {
          
        }
        
        div {
          textContent(s"""Verilog/VHDL Folder: """+VerilogAnalyse.baseHDLPath.getCanonicalPath)
        }
      }

      // VDC View
      //----------------
      VCDFileHarvester.getResources.size match {
        case 0 =>
        case _ =>
          h2("VCD File Viewer") {

          }
          "ui table" :: table {
            thead {
              tr {
                th("Path") {

                }
                th("Last Modified") {

                }
                th("Actions") {

                }
              }
            }
            tbody {
              VCDFileHarvester.onResources[VCDFile] {
                case vcdFile =>

                  tr {
                    td(vcdFile.path.toFile.getAbsolutePath) {

                    }
                    td(new java.text.SimpleDateFormat("dd/MM/yyyy HH:mm:ss").format(new java.util.Date(vcdFile.path.toFile().lastModified()))) {

                    }
                    td("") {
                      "ui button" :: button("Open in GTKWave") {
                        onClick {
                          var tool = GTKWaveHarvester.getResource[GTKWaveTool].get
                          var process = tool.createToolProcess(vcdFile.path.toFile.getAbsolutePath)
                          process.inheritIO
                          process.startProcess
                        }
                      }
                    }
                  }
              }
            }
          }

        // EOF VCD Viewer
      }

      // Selection
      //---------------
      h1("Verilog Analyser") {

      }
      // List of Verilog Files
      //-----------
      "ui table" :: table {
        thead {
          tr {
            th("File") {

            }
            th("Select") {

            }
          }
        }

        tbody {
          Harvest.onHarvesters[VerilogFIleHarvester] {
            case h =>
              h.onResources[VerilogFile] {
                r =>
                  tr {
                    td(r.path.toFile().getAbsolutePath) {

                    }

                    td("") {
                      button("Select") {
                        reRender
                        onClick {
                          selectedFile = Some(r)
                        }
                      }
                    }
                  }
              }

          }
        }
      } // EOF Table

      // View
      //----------
      h2("Selection") {

      }
      selectedFile match {
        case Some(verilogFileResource) =>

          "ui info message" :: div {
            textContent("Verilog File selected: " + verilogFileResource.path.toFile.getAbsolutePath)
          }

          // Reverse Parse to H2DL
          //------------

          //-- Get Interpreter
          var interpreter = TCLModule.getInterpreter("default")

          //-- Parse
          interpreter.evalString("package require odfi::h2dl::verilog::parse")
          var results = interpreter.evalString(s"odfi::h2dl::verilog::parse::reverse ${verilogFileResource.path.toFile.getAbsolutePath.replace('\\', '/')}").asList.toNXList

          // Show Stuff
          //---------------- 
          var first = results.size match {
            case 0 =>
              "ui warning message" :: div {
                textContent("Nothing found in file; maby reverse parsing failed")
              }
            case 1 if (results.head.getNXClass.toString == "::odfi::h2dl::Module") =>
              var module = results.head
              div {
                p {
                  span(textContent(s"Module: ${module.name}"))
                }
              }

              // Simulation Module
              //--------------------

              // IO
              //-------------
              var iosV = module("shade odfi::h2dl::IO children").asObjectValue.asNXObject
              iosV("size").toString().toInt match {
                case 0 =>
                  "ui info message" :: div {
                    textContent("No IO In Module")
                  }
                case _ =>

                  var ios = iosV("toTCLList").asList.toNXList
                  "ui table" :: table {
                    thead {
                      tr {

                        th("Direction") {

                        }
                        th("Name") {

                        }
                      }
                    }
                    tbody {
                      ios.foreach {
                        io =>
                          tr {
                            io.getNXClass.toString match {
                              case "::odfi::h2dl::Input" => td("input") {

                              }
                              case _ => td("output") {

                              }
                            }
                            td(io.name.toString) {

                            }
                          }
                      }
                    }
                  }

              }
              // EOF IOS 

              // Sub Instances
              //-----------------
              var instances = module("shade odfi::h2dl::Instance children").asObjectValue.asNXObject
              instances("size").toString.toInt match {
                case 0 =>
                  "ui info message" :: div { textContent("Module has no sub instances") }
                case _ =>
                  var instancesList = instances("toTCLList").asList.toNXList
                  h3("Instances") {

                  }
                  "ui table" :: table {
                    thead {
                      tr {
                        th("Type") {

                        }
                        th("Name") {

                        }
                        th("File") {

                        }
                      }
                    }
                    tbody {
                      instancesList.foreach {
                        instance =>
                          tr {
                            td(instance.master.asObjectValue.asNXObject.name.toString) {

                            }
                            td(instance.name.toString) {

                            }

                            // Resolve files
                            this.resolveSourceFile(instance.master.asObjectValue.asNXObject) match {
                              case Some(f) =>
                                "positive" :: td("") {
                                  "icon checkmark" :: i {

                                  }
                                  
                                  span(textContent(f.getAbsolutePath))
                                }
                              case None =>
                                "negative" :: td("") {
                                  "icon close" :: i {

                                  }
                                  span(textContent("Not Found"))
                                }
                            }
                            td("") {

                            }
                          }
                      }
                    }
                  }
                // EOF INstance table
              }

          }
          // EOF Show stuff on module

          // Verilog Compile
          //--------------------
          h3("Verilog Compile") {

          }
          p {
            textContent("Using Icarus Verilog, you can compile this verilog file to check for syntax errors")
          }
          div {

            "ui button" :: button("Compile File") {
              reRender
              onClick {
                var iverilog = ICarusHarvester.getResource[IVerilogTool].get
                var vfile = verilogFileResource.path.toFile()
                var outFile = new File(vfile.getAbsolutePath.replace(".v", ".vpp"))

                var process = iverilog.createToolProcess(Array("-g2012", "-o", outFile.getAbsolutePath, vfile.getAbsolutePath),vfile.getCanonicalFile.getParentFile)
                process.outputToBuffer
                //process.inheritIO
                var r = process.startProcessAndWait
                runProcess = Some(process)

                println("File run: "+r)
                // process.clean
              }
            }

            //-- Results
            runProcess match {
              case Some(process) if (process.getOutputString == "") =>
                "ui success message" :: div {
                  textContent("No errors")
                }
              case Some(process) if (process.getOutputString.contains("error")) =>
                "ui error message" :: div {
                  pre(process.getOutputString.trim) {}
                }
              case Some(process) =>
                "ui info message" :: div {
                  pre(process.getOutputString.trim) {}
                }
              case None =>
            }
            runProcess = None
          }
          // EOF Verilog Compile

          // Verilog Simulation
          //---------------

          h3("Verilog Simulation") {

          }
          p {
            textContent("""
              Using Icarus Verilog, you can compile and simulate this verilog file.
              If the testbench contains a VCD Dump file, it will be detected and appear on the page for visualisation using GTK wave
              """.stripMargin)
          }

          "ui button" :: button("Run Simulation") {
            reRender
            onClick {
              
              //-- Get Resources
              var iverilog = ICarusHarvester.getResource[IVerilogTool].get
              var vpp = ICarusHarvester.getResource[VPPTool].get

              //-- Prepare input files
              var vfile = verilogFileResource.path.toFile()
              
              //-- Dependend files
               var interpreter = TCLModule.getInterpreter("default")
              var module = interpreter.evalString(s"odfi::h2dl::verilog::parse::reverse ${verilogFileResource.path.toFile.getAbsolutePath.replace('\\', '/')}").asList.toNXList.head

              var subinstances = module("shade odfi::h2dl::Instance children").asObjectValue.asNXObject("toTCLList").asList.toNXList
              var files = subinstances.map( i => resolveSourceFile(i.master.asObjectValue.asNXObject)).filter(_.isDefined).map(_.get.getAbsolutePath)
              
              //-- Output
              var outFile = new File(vfile.getAbsolutePath.replace(".v", ".vpp"))
              
              //-- Args
              var args = Array("-g2012", "-o", outFile.getAbsolutePath)
              args = (args ++ files) :+ vfile.getAbsolutePath
              
              println(s"Sim Args: "+args.toList)
              
              var process = iverilog.createToolProcess(args,vfile.getParentFile)
              process.outputToBuffer
              runProcess = Some(process)
              process.startProcessAndWait match {
                case 0 =>
                  var vppProcess = vpp.createToolProcess(Array(outFile.getAbsolutePath),vfile.getParentFile)
                  simProcess = Some(vppProcess)
                  vppProcess.outputToBuffer
                  vppProcess.startProcessAndWait
                case _ =>
                  simProcess = None
              }

              println("File run")
              // process.clean
            }
          }
          // EOF SIm Run Button

          //-- Sim Results
          simProcess match {
            case Some(process) if (process.getOutputString == "") =>
              "ui success message" :: div {
                textContent("No errors")
              }
            case Some(process) if (process.getOutputString.contains("error")) =>
              "ui error message" :: div {
                pre(process.getOutputString.trim) {}
              }
            case Some(process) =>
              "ui info message" :: div {
                pre(process.getOutputString.trim) {}
              }
            case None =>
          }
          simProcess = None

        case None =>
          "ui warning message" :: div {
            textContent("No Verilog File Selected")
          }
      }

    }

  }
}