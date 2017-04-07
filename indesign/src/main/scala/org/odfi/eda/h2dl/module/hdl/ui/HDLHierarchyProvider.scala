package org.odfi.eda.h2dl.module.hdl.ui


import org.odfi.indesign.ide.core.sources.SourceCodeProvider

trait HDLHierarchyProvider extends SourceCodeProvider {

  def toHierarchy: Option[Hierarchy]
}

trait HierarchyProvideSuccess extends HDLHierarchyProvider {

  var currentHiearchy: Option[Hierarchy] = None

  def toHierarchy = {
    try {

      currentHiearchy = Some(buildHierarchy)

    } catch {
      case e: Throwable =>
        e.printStackTrace()
    }

    currentHiearchy
  }

  def buildHierarchy: Hierarchy

}