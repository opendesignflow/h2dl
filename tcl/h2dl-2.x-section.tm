# ODFI H2DL
# Copyright (C) 2016 Richard Leys  <leys.richard@gmail.com> , University of Karlsruhe  - Asic and Detector Lab Group
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
package provide odfi::h2dl::section 2.0.0
package require odfi::h2dl          2.0.0

namespace eval odfi::h2dl::section {


    odfi::language::Language default {


        +type Section : ::odfi::h2dl::H2DLObject  {
            +var name ""
           
        }

        ## A Text Content Section, just some text 
        :textContentSection : Section name  content {
            +exportTo ::odfi::h2dl::Module section
            
            +method removeCommentSection name {
                       
               regsub -all "\\s*\\/\\/\[^\\n\]*sect:$name.+eofsect:$name\\n" ${:content} "" :content
           
           }
           
        }

        ## A Logic Section 
        :logicSection : Section name  {
            
            +mixin ::odfi::h2dl::Logic
            
            # Important to have declared signal be declared fully
            +mixin ::odfi::h2dl::Structural
            
            +exportToPublic
        }

    }

}
