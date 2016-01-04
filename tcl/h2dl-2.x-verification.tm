package provide odfi::dev::hw::h2dl::verification 2.0.0
package require odfi::dev::hw::h2dl 2.0.0

package require odfi::richstream 3.0.0

namespace eval odfi::dev::hw::h2dl::verification {

    odfi::language::Language define TESTBENCH {
        
        :testbench name {
            +type odfi::dev::hw::h2dl::Module
            +var  test
        }
        
    }


}
