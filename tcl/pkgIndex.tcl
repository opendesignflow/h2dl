
set dir [file dirname [file normalize [info script]]]




package ifneeded odfi::h2dl                    2.0.0 [list source [file join $dir  h2dl-2.x.tm]]
package ifneeded odfi::h2dl::ast               2.0.0 [list source [file join $dir  h2dl-2.x-ast.tm]]

package ifneeded odfi::h2dl::verilog           2.0.0 [list source [file join $dir  h2dl-2.x-verilog.tm]]

package ifneeded odfi::h2dl::verification      2.0.0 [list source [file join $dir  h2dl-2.x-verification.tm]]

package ifneeded odfi::h2dl::view              2.0.0 [list source [file join $dir  h2dl-2.x-view.tm]]


package ifneeded odfi::h2dl::section              2.0.0 [list source [file join $dir  h2dl-2.x-section.tm]]

package ifneeded odfi::h2dl::sim1              2.0.0 [list source [file join $dir  h2dl-2.x-sim1.tm]] 
package ifneeded odfi::h2dl::sim::vcd          2.0.0 [list source [file join $dir  h2dl-2.x-sim-vcd.tm]]
package ifneeded odfi::h2dl::sim2              2.0.0 [list source [file join $dir  h2dl-2.x-sim2.tm]] 

## Std Lib
##############
package ifneeded odfi::h2dl::stdlib 2.0.0 [list source [file join $dir stdlib  stdlib-2.x.tm]] 
