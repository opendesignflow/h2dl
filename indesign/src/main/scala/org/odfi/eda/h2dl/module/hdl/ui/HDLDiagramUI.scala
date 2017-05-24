package org.odfi.eda.h2dl.module.hdl.ui

import org.odfi.indesign.ide.core.module.d3.D3View

import org.odfi.eda.h2dl.ui.H2DLLibView

trait HDLDiagramUI extends H2DLLibView with D3View {
  
  this.addLibrary("h2dl") {
    case (_,node) => 
      onNode(node) {
        
     
        script(createAssetsResolverURI("/h2dl/hdl/diagram/diagram.js")) {
          
        }
        
         stylesheet(createAssetsResolverURI("/h2dl/hdl/diagram/diagram.css")) {
          
        }
        
      }
  }
}