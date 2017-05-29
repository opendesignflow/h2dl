package org.odfi.eda.h2dl.main

import org.odfi.wsb.fwapp.DefaultSiteApp

object H2DLStandaloneDev extends DefaultSiteApp("/h2dl") {
  
  
  // FSMDesigner
  //-----------------
  "/fsmdesigner" is {
    
  }
  
  listen(8686)
  start
}