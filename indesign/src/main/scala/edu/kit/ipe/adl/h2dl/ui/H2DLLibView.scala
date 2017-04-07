package edu.kit.ipe.adl.h2dl.ui

import org.odfi.indesign.ide.core.ui.lib.IndesignIDELibView
import org.odfi.wsb.fwapp.assets.ResourcesAssetSource

trait H2DLLibView  extends IndesignIDELibView {
  
  this.addLibrary("h2dl") {
    case (_,node) => 
      onNode(node) {
        
        getAssetsResolver match {
          case Some(a) =>
            a.ifNoAssetSource("/h2dl") {
              a.addAssetsSource("/h2dl", new ResourcesAssetSource).addFilesSource("h2dl")
            }
          case None => 
        }

      }
  }
  
}