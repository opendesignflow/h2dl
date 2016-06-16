package edu.kit.ipe.adl.h2dl.ui

import java.io.File
import java.net.URI

import org.w3c.dom.html.HTMLElement

import com.idyria.osi.vui.html.HTMLNode

import edu.kit.ipe.adl.h2dl.DesignGroupHarvester
import edu.kit.ipe.adl.h2dl.DesignGroupResource
import edu.kit.ipe.adl.h2dl.tool.ToolProcess
import edu.kit.ipe.adl.h2dl.tool.gtkwave.GTKWaveTool
import edu.kit.ipe.adl.h2dl.tool.gtkwave.VCDFile
import edu.kit.ipe.adl.h2dl.tool.gtkwave.VCDFileHarvester
import edu.kit.ipe.adl.h2dl.tool.icarus.IVerilogTool
import edu.kit.ipe.adl.h2dl.tool.icarus.VPPTool
import edu.kit.ipe.adl.h2dl.verilog.VerilogFIleHarvester
import edu.kit.ipe.adl.h2dl.verilog.VerilogFile
import edu.kit.ipe.adl.h2dl.verilog.VerilogFile
import edu.kit.ipe.adl.indesign.core.heart.ui.HeartHtmlBuilder
import edu.kit.ipe.adl.indesign.core.module.ui.www.IndesignUIView
import edu.kit.ipe.adl.indesign.core.module.ui.www.external.HighlightJSBuilder
import edu.kit.ipe.adl.indesign.tcl.nx.NXObject
import edu.kit.ipe.adl.h2dl.tool.icarus.ICarusHarvester
import edu.kit.ipe.adl.indesign.core.harvest.Harvest
import edu.kit.ipe.adl.indesign.tcl.module.TCLModule
import edu.kit.ipe.adl.h2dl.tool.gtkwave.GTKWaveHarvester

class H2DLVerilogAnalyser extends IndesignUIView with HeartHtmlBuilder with HighlightJSBuilder {

  var selectedFile: Option[VerilogFile] = None
  var runProcess: Option[ToolProcess] = None
  var simProcess: Option[ToolProcess] = None

  override def externalAdd(targetNode: HTMLNode[HTMLElement, Any]): Unit = {
    super.externalAdd(targetNode)
    switchToNode(targetNode, {

      script(new URI(createSpecialPath("resources", "h2dl-verilog.js"))) {

      }

    })
    //super.externalAdd(targetNode)

  }

  //var allVerilogResources = this.parentView.get.asInstanceOf[H2DLWelcomeView].selectedGroup.get.getSubDerivedResources[VerilogFile]
  var allVerilogResources: Option[List[VerilogFile]] = None
  def getAllVerilogResources = allVerilogResources.getOrElse {

    allVerilogResources = Some(this.parentView.get.asInstanceOf[H2DLWelcomeView].selectedGroup.get.getSubDerivedResources[VerilogFile])
    allVerilogResources.get

  }

  def resolveSourceFile(module: NXObject): List[(VerilogFile, Option[NXObject])] = {

    getAllVerilogResources.map {
      vf =>
        (vf, vf.getModuleOfType(module.name.toString))
    }.filter { case (vf, module) => module.isDefined }.toList

    // List()

    /*println(s"looking for: " + module.name.toString)
    var found: Option[File] = None
    Harvest.onHarvesters[VerilogFIleHarvester] {
      case h if (found.isEmpty) =>
        h.onResources[VerilogFile] {
          case r if (found.isEmpty) =>

            // Parse File
            var interpreter = TCLModule.getInterpreter("default")
            var results = interpreter.evalString(s"odfi::h2dl::verilog::parse::reverse ${r.path.toFile.getAbsolutePath.replace('\\', '/')}").asList.toNXList

            // Find Modules
            println(s"Tested file: " + r.path.toFile + " -> " + results + " -> " + results.head.name + "//" + results.head.getNXClass)
            results.size match {
              case 1 if (results.head.getNXClass == "::odfi::h2dl::Module" && results.head.name.toString == module.name.toString) =>
                found = Some(r.path.toFile)
              case _ =>
            }
          case _ =>

        }
      case _ =>
    }

    found*/
    //None
  }

  def resolveSourceFile(moduleType: String): List[(VerilogFile, Option[NXObject])] = {

    getAllVerilogResources.map {
      vf =>
        (vf, vf.getModuleOfType(moduleType))
    }.filter { case (vf, module) => module.isDefined }.toList

    // List()

    /*println(s"looking for: " + module.name.toString)
    var found: Option[File] = None
    Harvest.onHarvesters[VerilogFIleHarvester] {
      case h if (found.isEmpty) =>
        h.onResources[VerilogFile] {
          case r if (found.isEmpty) =>

            // Parse File
            var interpreter = TCLModule.getInterpreter("default")
            var results = interpreter.evalString(s"odfi::h2dl::verilog::parse::reverse ${r.path.toFile.getAbsolutePath.replace('\\', '/')}").asList.toNXList

            // Find Modules
            println(s"Tested file: " + r.path.toFile + " -> " + results + " -> " + results.head.name + "//" + results.head.getNXClass)
            results.size match {
              case 1 if (results.head.getNXClass == "::odfi::h2dl::Module" && results.head.name.toString == module.name.toString) =>
                found = Some(r.path.toFile)
              case _ =>
            }
          case _ =>

        }
      case _ =>
    }

    found*/
    //None
  }

  this.viewContent {

    div {

      h3("Verilog Toolchain") {

      }

      // Config
      //-------------
      /*"ui segment" :: div {
        h2("Configuration") {

        }

        div {
          // textContent(s"""Verilog/VHDL Folder: """+VerilogAnalyse.baseHDLPath.getCanonicalPath)
        }
      }*/

      // VDC View
      //----------------
      Harvest.onHarvesters[DesignGroupHarvester] {
        case dgh =>
          dgh.onResources[DesignGroupResource] {
            case dg if (this.parentView.get.asInstanceOf[H2DLWelcomeView].selectedGroup.isDefined && this.parentView.get.asInstanceOf[H2DLWelcomeView].selectedGroup.get == dg) =>

              dg.hasDerivedResourceOfType[VCDFile] match {
                case true =>

                  h4("VCD File Viewer") {

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
                      dg.onDerivedResources[VCDFile] {
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

                case false =>
              }
            case _ =>
          }

      }
      // EOF VCD Viewer

      // Selection
      //---------------
      h4("Verilog Analyser") {

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

          this.parentView.get.asInstanceOf[H2DLWelcomeView].selectedGroup.get.onDerivedResources[VerilogFile] {

            case r =>

              tr {
                td(r.path.toFile().getAbsolutePath) {

                }

                td("") {

                  /*heartTaskWithCondition(s"verilogfile.parse.$r")(r.h2dlResult) {
                    r.getH2DLResults
                  } match {
                    case Some(t) =>
                      "ui active small inline loader" :: div{
                        textContent("Parsing Running")
                      }
                    case None =>
                      "ui button" :: button("Select") {
                        reRender
                        onClick {
                          println("ACTION SELECT FILE")
                          selectedFile = Some(r)
                        }
                      }
                  }*/

                  taskMonitorAltUI("Parsing Running",
                    heartTaskWithCondition(s"verilogfile.parse.$r")(r.h2dlResult) {
                      r.getH2DLResults
                    }) {
                      "ui button" :: button("Select") {
                        reload
                        onClick {
                          selectedFile = Some(r)
                        }
                      }
                      "ui button" :: button("Reset Model") {
                        reload
                        onClick {
                          selectedFile = None
                          r.h2dlResult = None
                        }
                      }
                    }

                  /*"ui button" :: button("Select") {
                    reRender
                    onClick {
                      println("ACTION SELECT FILE")
                      selectedFile = Some(r)
                    }
                  }*/

                }
              }

          }
        }
      } // EOF Table

      // View
      //----------
      h4("Selection") {

      }
      selectedFile match {
        case Some(verilogFileResource) =>

          "ui info message" :: div {
            textContent("Verilog File selected: " + verilogFileResource.path.toFile.getAbsolutePath)
          }
          "ui button" :: button("Force Reload File") {
            reload
            onClick {
              verilogFileResource.h2dlResult = None
            }
          }

          // Reverse Parse to H2DL
          //------------

          //-- Get Interpreter
          //var interpreter = TCLModule.getInterpreter("default")

          //-- Parse
          //interpreter.evalString("package require odfi::h2dl::verilog::parse")
          var results = verilogFileResource.getH2DLResults

          // Tabs:
          //  1- Analysis
          //  2- Source View
          //-----------------------
          "ui top attached tabular menu" :: div {
            "item active" :: a("#") {
              +@("data-tab", "analysis-tab")
              textContent("Analysis")
            }
            "item" :: a("#") {
              +@("data-tab", "source-tab")
              textContent("Source")
            }
          }

          //---- Analysis View 
          "ui bottom attached active tab segment" :: div {
            +@("data-tab", "analysis-tab")

            // Show Modules List
            //---------------- 
            var first = results.size match {
              case 0 =>
                "ui warning message" :: div {
                  textContent("Nothing found in file; maby reverse parsing failed")
                }
              case other =>

                onNode(tempBufferSelect("selectedModule", results.filter { m => m.getNXClass.toString == "::odfi::h2dl::Module" }.map { m => (m.toString, m.name.toString) })) {
                  reload
                }

                var module = NXObject(results.head.interpreter, getTempBufferValue[String]("selectedModule").get)
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
                    h5("Instances") {

                    }
                    "ui sortable table" :: table {
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

                        // Group by type
                        var groupedInstances = instancesList.groupBy { o => o.master.asObjectValue.asNXObject.name.toString }
                        groupedInstances.foreach {
                          case (typeName, instances) =>

                            // Resolve for ype name
                            var resolvedFiles = this.resolveSourceFile(typeName)

                            // A Category line 
                            tr {
                              td(typeName) {

                              }
                              td("") {

                              }
                              // Resolve files
                              resolvedFiles.size match {
                                case 0 =>
                                  "negative" :: td("") {
                                    "icon close" :: i {

                                    }
                                    span(textContent("Not Found"))
                                  }

                                case other =>
                                  "positive" :: td("") {
                                    "icon checkmark" :: i {

                                    }
                                    resolvedFiles.foreach {
                                      case (vf, module) =>
                                        div {
                                          textContent(vf.toString)
                                        }
                                    }
                                    //span()
                                  }

                              }
                            }

                            instances.foreach {
                              instance =>
                                tr {
                                  td("") {

                                  }
                                  td(instance.name.toString) {

                                  }

                                  td("") {

                                  }
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
            h5("Verilog Compile") {

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

                  var process = iverilog.createToolProcess(Array("-g2012", "-o", outFile.getAbsolutePath, vfile.getAbsolutePath), vfile.getCanonicalFile.getParentFile)
                  process.outputToBuffer
                  //process.inheritIO
                  var r = process.startProcessAndWait
                  runProcess = Some(process)

                  println("File run: " + r)
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

            h5("Verilog Simulation") {

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
                var files = subinstances.map(i => resolveSourceFile(i.master.asObjectValue.asNXObject)).map(vf => vf.head._1.path.toFile().getCanonicalPath)

                //-- Output
                var outFile = new File(vfile.getAbsolutePath.replace(".v", ".vpp"))

                //-- Args
                var args = Array("-g2012", "-o", outFile.getAbsolutePath)
                args = (args ++ files) :+ vfile.getAbsolutePath

                println(s"Sim Args: " + args.toList)

                var process = iverilog.createToolProcess(args, vfile.getParentFile)
                process.outputToBuffer
                runProcess = Some(process)
                process.startProcessAndWait match {
                  case 0 =>
                    var vppProcess = vpp.createToolProcess(Array(outFile.getAbsolutePath), vfile.getParentFile)
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
          }
          //---- EOF Analysis view

          //---- Source View 
          "ui bottom attached tab segment" :: div {
            +@("data-tab", "source-tab")

            "ui grid" :: div {
              "eight wide column" :: div {
                pre(verilogFileResource.getLines.mkString("\n")) {
                  classes("code")
                  /*code(verilogFileResource.getLines.mkString("\n")) {
                    +@("style"->"position:relative;top:0px;left:0px;")
                    //classes("verilog")
                    //println(s"Text content:")
                   /// println(currentNode.textContent)
                  }*/
                }
              }
              "eight wide column" :: div {

                div {
                  +@("style" -> "margin:14px")
                  textContent(verilogFileResource.convertLinesToCrossReferenced.map {
                    case Some((content, targetFile, pages)) =>

                      //-- Create Link for Pages
                      var links = pages.map { ps => ps.split(",") }.flatten.map {
                        p =>
                          s"""<a href="javascript:indesign.pdfjs.changeToPage('$targetFile',$p)">${p}</a>"""
                      }.mkString("-")
                      s"""<li>${content} - $links</li>"""
                    case None =>
                      "<br/>"
                  }.mkString("\n"))
                }

              }
            }

          }
        //---- EOF Source view

        case None =>
          "ui warning message" :: div {
            textContent("No Verilog File Selected")
          }
      }

    }

  }
}