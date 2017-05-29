package org.odfi.eda.h2dl.hdl

import com.idyria.osi.ooxoo.model.producers
import com.idyria.osi.ooxoo.model.ModelBuilder
import com.idyria.osi.ooxoo.model.producer
import com.idyria.osi.ooxoo.model.out.markdown.MDProducer
import com.idyria.osi.ooxoo.model.out.scala.ScalaProducer
import org.odfi.wsb.fwapp.framework.json.JSONIOTrait
import com.idyria.osi.ooxoo.core.buffers.structural.io.sax.STAXSyncTrait

@producers(Array(
  new producer(value = classOf[ScalaProducer])))
object H2DLHDLModel extends ModelBuilder {

  // Name and description trait
  //----------
  val nameAndDescription = "NameAndDescription" is {
    makeTraitAndUseCustomImplementation
    attribute("name")
    "Description" ofType ("cdata")
  }

  val attributes = "Attributes" is {
    isTrait

    "Attribute" multiple {
      withTrait(nameAndDescription)
      ofType("string")
    }
  }

  val attributesAndName = "AttributesAndNameAndDescription" is {
    makeTraitAndUseCustomImplementation
    withTrait(nameAndDescription)
    withTrait(attributes)
    
  }

  // Logic Common Definitions
  //------------------
  val signalTrait = "Signal" is {
    isTrait
    withTrait(attributesAndName)

    attribute("size") ofType ("integer")
  }

  // Hiearchy
  //----------------
  "Hierarchy" is {
    makeTraitAndUseCustomImplementation
    withTrait(attributesAndName)
    withTrait(classOf[STAXSyncTrait])

    // IO
    //-------------
    "Input" multiple {
      withTrait(attributesAndName)

    }

    "Output" multiple {
      withTrait(attributesAndName)
    }

    "IO" multiple {
      withTrait(attributesAndName)
    }

    // Instances
    //----------------
    "HierarchyInstance" is {

    }

    // Logic
    //------------
    "SynchronousLogic" multiple {
      makeTraitAndUseSameNameImplementation

      attribute("clock")
      "Reset" is {
        withTrait(nameAndDescription)
        attribute("type") default ("sync") withDocumentation ("sync or async")
      }
    }

  }

}