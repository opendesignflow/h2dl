package org.odfi.eda.h2dl.hdl

import com.idyria.osi.ooxoo.core.buffers.datatypes.XSDStringBuffer

trait AttributesAndNameAndDescription extends AttributesAndNameAndDescriptionTrait {
  
  override def name_=(v : XSDStringBuffer) = {
    
    //-- Find attributes
    val splitted = v.toString.split("@")
    
    //-- Name is first
    super.name = splitted(0).trim
    
    //-- Attributes
    splitted.drop(1).foreach {
      case attr => 
        
        //-- Split at = 
        attr.split("=") match {
          case arr if (arr.size==1) => 
            super.name = arr(0).trim
          case arr if (arr.size>1) => 
            val attr = this.attributes.add
            attr.name = arr(0).trim
            attr.data = arr(1)
        }
    }
    
  }
}