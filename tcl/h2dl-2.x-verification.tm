package provide odfi::h2dl::verification 2.0.0
package require odfi::h2dl:: 2.0.0

package require odfi::richstream 3.0.0

namespace eval odfi::h2dl::verification {

    odfi::language::Language define TESTBENCH {
        
        :testbench name {
            +type odfi::h2dl::Module
            +var  test
        }
        
    }


}
