package edu.kit.ipe.adl.h2dl.ui

import edu.kit.ipe.adl.indesign.core.module.ui.www.IndesignUIView
import edu.kit.ipe.adl.indesign.tcl.module.TCLModule

class TCLView extends IndesignUIView {

  this.viewContent {
    h2("TCL Control") {

    }

    div {
      "ui button" :: button("Reload Interpreter") {
        reload
        onClick {
          var interpreter = TCLModule.getInterpreter("default")
          // TCLModule.reloadInterpreterPackages("default")
          interpreter.forgetPackages("*odfi*")
          TCLModule.reloadInterpreterPackages("default")
        }
      }
    }

  }
}