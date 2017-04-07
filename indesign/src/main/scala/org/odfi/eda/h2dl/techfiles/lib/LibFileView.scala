package org.odfi.eda.h2dl.techfiles.lib


import org.odfi.tcl.nx.NXObject

/*
class LibFileView extends IndesignUIView {

  var targetFile: Option[LibFile] = None

  this.viewContent {

    var designGroup = this.parentView.get.asInstanceOf[H2DLWelcomeView].selectedGroup.get
    div {

      h3("Lib File Analysis") {

      }
      p {
        textContent(s"""
          Use this View to Check the cells present in a LibFile and their Timing Information<br/>
          
          Lecture Slides: ${
          List("5","6","7").map {
            s =>
              s"""<a href="javascript:indesign.pdfjs.changeToPage('pdfjs-lecturepdf',$s)">$s</a>"""
          }.mkString(" - ")
        } 
          """)
      }

      h4("Available Files") {
        "ui celled table" :: table {

          thead {
            th("Name") {

            }
            th("File") {

            }
            th("Action") {

            }
          }
          tbody {

            designGroup.onDerivedResources[LibFile] {
              case lf =>
                tr {
                  td(lf.path.toFile().getName) {

                  }
                  
                  // Display relative path 
                  
                  /*td(lf.path.toFile.getCanonicalPath) {

                  }*/
                  td(designGroup.path.relativize(lf.path).toString) {

                  }
                  
                  td("") {
                    "ui button" :: button("Open") {
                      reRender
                     // lf.getLibModel
                      onClick {
                        targetFile = Some(lf)
                        targetFile.get.getLibModel
                      }

                    }
                    "ui button" :: button("Reset Model") {
                      reRender
                      onClick {
                        lf.libFileModel = None
                      }

                    }
                  }
                }
            }

          }

        }
      }
      // EOf File Open Table 

      // Cell File
      //-----------------
      targetFile match {
        case Some(libFile) =>
          h4("Cell Selection") {

          }
          p(textContent("Selected File: " + libFile))

          var cellTypeList = libFile.getLibModel("shade ::odfi::implementation::libfile::CellType children").asObjectValue.asNXObject("toTCLList").asList.toNXList
          var currentCellType = tempBuffer.getOrElse("selectedCellType", cellTypeList(0)).asInstanceOf[NXObject]
          var currentCell = tempBuffer.getOrElse("selectedCell", currentCellType("firstChild").asObjectValue.asNXObject).asInstanceOf[NXObject]

          "ui segment" :: div {

            // List of Cell Types

            /*span(textContent("Cell Type: "))
            onNode(tempBufferSelect("selectedCellType", cellTypeList.map{ct=> (ct,ct.name.toString)})) {
              reload
            }
            
            var currentCellType = getTempBufferValue[NXObject]("selectedCellType").asInstanceOf[NXObject]
            span(textContent("Cell Type: "))
            onNode(tempBufferSelect("selectedCell", currentCellType("children").asObjectValue.asNXObject("toTCLList").asList.toNXList.map {cell => (cell.toString,cell.name.toString)})) {
              reload
            }*/
            
            select {
              reRender
              cellTypeList.foreach {
                cellType =>
                  option(cellType.toString) {
                    textContent(cellType.name.toString)
                    if (cellType.name.toString == currentCellType.name.toString) {
                      +@("selected" -> "")
                    }
                  }
              }

              bindValue {
                str: String =>
                  println(s"Using CellType: " + str)
                  putToTempBuffer("selectedCellType", NXObject(currentCellType.interpreter, str))
              }
            }

            // Current Cell
            //----------------
            span(textContent("Cell: "))
            select {
              reRender
              currentCellType("children").asObjectValue.asNXObject("toTCLList").asList.toNXList.foreach {
                cell =>
                  option(cell.toString) {
                    textContent(cell.name.toString)
                    if (cell.name.toString == currentCell.name.toString) {
                      +@("selected" -> "")
                    }
                  }
              }

              bindValue {
                str: String =>
                  println(s"Using Cell: " + str)
                  putToTempBuffer("selectedCell", NXObject(currentCellType.interpreter, str))
              }
            }
          }
          // EOF Cell Choice
          
          

          // List of Cell Stastics
          //------------

          "ui segment" :: div {
            h4("Cells area") {

            }

            "ui celled table" :: table {

              //-- Use Current Cell type for Header
              thead {
                tr {
                  th("Lib") {

                  }
                  currentCellType("children").asObjectValue.asNXObject("toTCLList").asList.toNXList.foreach {
                    cell =>
                      cell("checkParsed")
                      th(cell.name.toString) {
                      }
                  }
                }
              }
              tbody {
                // One Line per library
                designGroup.onDerivedResources[LibFile] {
                  case currentLibFile =>

                    // Get All LibCellType
                    var currentLibCellTypes = currentLibFile.getLibModel("shade ::odfi::implementation::libfile::CellType children").asObjectValue.asNXObject("toTCLList").asList.toNXList

                    // Look for one Cell Type matching the currentCellType
                    currentLibCellTypes.find(currentCt => currentCt.name.toString == currentCellType.name.toString) match {
                      case Some(currentLibCellType) =>
                        tr {

                          // Lib Name
                          td(currentLibFile.path.toFile.getName) {

                          }

                          // All Cells
                          currentLibCellType("children").asObjectValue.asNXObject("toTCLList").asList.toNXList.foreach {
                            cell =>
                              cell("checkParsed")
                              td(cell.area.toString) {
                              }
                          }
                        }
                      case None =>
                    }

                }
                /*tr {
                  currentCellType("children").asObjectValue.asNXObject("toTCLList").asList.toNXList.foreach {
                    cell =>
                      th(cell.area.toString) {
                      }
                  }
                }*/
              }
            }
          }

          //-- EOF Cell Stats

          // Cell Content
          //---------------
          "ui segment" :: div {
            p(textContent("Selected Cell: " + currentCell.name + s"(${currentCellType.name.toString})"))

            h5("Leakage Power") {

            }

            //-- Get the matching cells in all other libraries
            //if (currentLibFile != libFile)
            var otherCells = designGroup.getSubDerivedResources[LibFile].collect {
              case currentLibFile  =>

                println("**** Doing libfile")
                // Get All LibCellType
                var currentLibCellTypes = currentLibFile.getLibModel("shade ::odfi::implementation::libfile::CellType children").asObjectValue.asNXObject("toTCLList").asList.toNXList

                // Look for one Cell Type matching the currentCellType
                currentLibCellTypes.find(currentCt => currentCt.name.toString == currentCellType.name.toString) match {
                  case Some(currentLibCellType) if (currentLibCellType(s"findFirstChildByProperty name ${currentCell.name.toString}* -match true").toString() != "") =>
                    println("**** Found CellType with Cell Name Matching libfile")
                    Some(currentLibFile, NXObject(currentLibCellType.interpreter, currentLibCellType(s"findFirstChildByProperty name ${currentCell.name.toString}* -match true").toString))
                  case _ => None
                }

            }.filter(_.isDefined).map(_.get).sortBy{case (lf,oc) => lf.getLibModel.name.toString}

            "ui celled sortable table" :: table {
              thead {
                th("Pin") {

                }
                th("Condition") {

                }

                // One Column Per Library
                /*th(libFile.getLibModel.name.toString) {
                  classes("ascending")
                }*/
                otherCells.foreach {
                  case (otherlibFile, otherCell) =>
                    th(otherlibFile.getLibModel.name.toString) {
                      classes("ascending")
                    }
                }

              }
              tbody {

                var leakages = currentCell("shade ::odfi::implementation::libfile::Leakage children").asObjectValue.asNXObject("toTCLList").asList.toNXList
                leakages.foreach {
                  leakageObject =>
                    tr {
                      td(leakageObject.relatedPin.toString) {

                      }
                      td(leakageObject.when.toString) {

                      }
                     /* td(leakageObject.value.toString) {

                      }*/

                      // Other Cells
                      otherCells.foreach {
                        case (otherlibFile, otherCell) =>
                          otherCell("checkParsed")
                          
                          // Look for same leakage condition
                          var otherCellLeakages = otherCell("shade ::odfi::implementation::libfile::Leakage children").asObjectValue.asNXObject("toTCLList").asList.toNXList
                          otherCellLeakages.find {
                            otherLeakage => otherLeakage.when.toString == leakageObject.when.toString
                          } match {
                            case Some(otherLeakage) => 
                              td(otherLeakage.value.toString) {
                                
                              }
                            case None => 
                              td("-") {
                                
                              }
                          }
                         
                      }
                    }
                }
              }
            }

          }
        //-- EOF Content

        case None =>
      }

    }
  }

}*/