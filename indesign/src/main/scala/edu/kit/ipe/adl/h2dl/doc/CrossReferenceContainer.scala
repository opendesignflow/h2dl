package edu.kit.ipe.adl.h2dl.doc

import edu.kit.ipe.adl.indesign.core.harvest.HarvestedResource
import edu.kit.ipe.adl.indesign.core.harvest.fs.HarvestedFile

trait CrossReferenceContainer extends HarvestedResource {
  
  
  
}

trait CrossReferenceContainerFile extends HarvestedFile with CrossReferenceContainer {
  
  val commentFindRegexp = """\/\/(.+)--\s*(.+)#(?:(.+),?)""".r
  
  def convertLinesToCrossReferenced = {
    getLines.map {
      line => 
        // Find pattern
        commentFindRegexp.findFirstMatchIn(line) match {
          case Some(matchResult) => 
            var desc = matchResult.group(1)
            var target = matchResult.group(2)
            var pages = (3 to (matchResult.groupCount)).map(matchResult.group(_))
            Some(matchResult.group(1),matchResult.group(2),pages)
          case None => None
        }
    }
  }
  
}