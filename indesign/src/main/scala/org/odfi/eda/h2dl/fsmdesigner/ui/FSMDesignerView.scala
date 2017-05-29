package org.odfi.eda.h2dl.fsmdesigner.ui

import org.odfi.wsb.fwapp.views.LibraryView
import org.odfi.eda.h2dl.ui.H2DLLibView
import org.odfi.wsb.fwapp.module.jquery.JQueryView
import org.odfi.indesign.ide.core.module.d3.D3View
import org.odfi.eda.h2dl.fsmdesigner.FSM
import org.w3c.dom.html.HTMLElement
import com.idyria.osi.vui.html.Div
import com.idyria.osi.ooxoo.core.buffers.structural.ElementBuffer
import com.idyria.osi.ooxoo.core.buffers.datatypes.XSDStringBuffer
import com.idyria.osi.ooxoo.core.buffers.structural.xelement
import org.odfi.wsb.fwapp.framework.websocket.WebsocketView

trait FSMDesignerView extends H2DLLibView with JQueryView with WebsocketView {
 
  //d3UseZoom
  this.addLibrary("h2dl") {
    case (_, tnode) =>

      onNode(tnode) {
        script(createAssetsResolverURI("/h2dl/external/node_modules/d3/d3.min.js")) {

        }
        script(createAssetsResolverURI("/h2dl/external/node_modules/lodash/index.js")) {

        }
        script(createAssetsResolverURI("/h2dl/external/node_modules/graphlib/dist/graphlib.core.js")) {

        }
        script(createAssetsResolverURI("/h2dl/external/node_modules/dagre/dist/dagre.core.js")) {

        }
        script(createAssetsResolverURI("/h2dl/external/node_modules/dagre-d3/dist/dagre-d3.core.js")) {

        }
        script(createAssetsResolverURI("/h2dl/fsmdesigner/fsmdesigner.js")) {

        }
      }
  }

  class FSMDiagram(d: Div[HTMLElement, _]) {
    def placeHere = {
      d.detach
      add(d)
    }

    def selectState(id: String) = {

      var msg = new FSMSelectState
      msg.TargetID = d.getId
      msg.id = id
      broadCastSOAPBackendMessage(msg)
    }
  }

  def fsmDagreD3(fsm: FSM) = {

    val d = "fsm-diagram" :: div {
      val fsmContainerId = currentNodeUniqueId("fsm")
      id(fsmContainerId)

      // style="width:100%;height:100%"
      importHTML(<svg style="width:100%;height:100%"><g></g></svg>)

      jqueryGenerateOnLoad("fsm-load-" + fsmContainerId) match {
        case Some(generator) =>

          // Load FSM
          generator.println(s"""var fsmStr='${fsm.toJSonString}';""")
          generator.println(s"""var fsm = JSON.parse("{" + fsmStr + "}").FSM;""")
          generator.println(s"""h2dl.fsmdesigner.dagre.load(fsm, "#$fsmContainerId");""")

          generator.close()
        case None =>
      }
    }

    new FSMDiagram(d)
  }
}