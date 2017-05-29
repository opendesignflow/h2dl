package org.odfi.eda.h2dl.hdl

import com.idyria.osi.ooxoo.core.buffers.datatypes.XSDStringBuffer

trait NameAndDescription extends NameAndDescriptionTrait {
  
  override def name_=(v : XSDStringBuffer) = {
    
    this.__name = v.trim().replaceAll("\\s+","_").toLowerCase()
  }
  
}