package edu.kit.ipe.adl.h2dl.module.hdl.ui

import com.idyria.osi.ooxoo.model.ModelBuilder
import com.idyria.osi.ooxoo.model.Model
import com.idyria.osi.ooxoo.model.producers
import com.idyria.osi.ooxoo.model.producer
import com.idyria.osi.ooxoo.model.out.scala.ScalaProducer
import com.idyria.osi.ooxoo.model.out.markdown.MDProducer
import org.odfi.indesign.ide.core.sources.outline.OutlineOutlineSection
import com.idyria.osi.ooxoo.core.buffers.structural.io.sax.STAXSyncTrait
import com.idyria.osi.ooxoo.lib.json.JSonUtilTrait
import org.odfi.indesign.ide.core.sources.outline.Outline

@producers(Array(
  new producer(value = classOf[ScalaProducer]),
  new producer(value = classOf[MDProducer])))
object HDLUIModels extends ModelBuilder {

  // HDL Hierarchy Description
  //----------------
  "Hierarchy" is {
    classType(classOf[Outline].getCanonicalName)
    
    
    //"Name" ofType "string"
    "io" multiple {
      "Name" ofType "string"
      "Description" ofType "string"
      "Type" ofType "string"
      "Location" ofType "string"
      
    }
    
    //-- Import outline sections
    //importElement(classOf[OutlineOutlineSection].getCanonicalName).setMultiple
    

  }

}