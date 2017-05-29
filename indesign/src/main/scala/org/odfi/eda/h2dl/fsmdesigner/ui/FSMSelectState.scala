package org.odfi.eda.h2dl.fsmdesigner.ui

import com.idyria.osi.ooxoo.core.buffers.structural.xelement
import com.idyria.osi.ooxoo.core.buffers.datatypes.XSDStringBuffer
import com.idyria.osi.ooxoo.core.buffers.structural.ElementBuffer

@xelement
class FSMSelectState extends ElementBuffer {

  @xelement
  var TargetID: XSDStringBuffer = ""

  @xelement
  var id: XSDStringBuffer = ""
}
  