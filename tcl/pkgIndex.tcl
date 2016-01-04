
set dir [file dirname [file normalize [info script]]]

package ifneeded odfi::dev::hw::rtl                     1.0.0 [list source [file join $dir rtl rtl-1.0.0.tm]]
package ifneeded odfi::dev::hw::h2dl                    1.0.0 [list source [file join $dir rtl h2dl-1.0.0.tm]]

package ifneeded odfi::dev::hw::h2dl                    1.1.0 [list source [file join $dir h2dl-1.1 h2dl-1.1.tm]]
package ifneeded odfi::dev::hw::h2dl::ast               1.1.0 [list source [file join $dir h2dl-1.1 h2dl-1.1-ast.tm]]
package ifneeded odfi::dev::hw::h2dl::verilog           1.1.0 [list source [file join $dir h2dl-1.1 h2dl-1.1-verilog.tm]]


package ifneeded odfi::dev::hw::h2dl                    2.0.0 [list source [file join $dir h2dl-2.x h2dl-2.x.tm]]
package ifneeded odfi::dev::hw::h2dl::verilog           2.0.0 [list source [file join $dir h2dl-2.x h2dl-2.x-verilog.tm]]
package ifneeded odfi::dev::hw::h2dl::verilog2           2.0.0 [list source [file join $dir h2dl-2.x h2dl-2.x-verilog2.tm]]
package ifneeded odfi::dev::hw::h2dl::verification      2.0.0 [list source [file join $dir h2dl-2.x h2dl-2.x-verification.tm]]
package ifneeded odfi::dev::hw::h2dl::ast               2.0.0 [list source [file join $dir h2dl-2.x h2dl-2.x-ast.tm]]
package ifneeded odfi::dev::hw::h2dl::view              2.0.0 [list source [file join $dir h2dl-2.x h2dl-2.x-view.tm]]


package ifneeded odfi::dev::hw::h2dl::sim1              2.0.0 [list source [file join $dir h2dl-2.x h2dl-2.x-sim1.tm]] 
package ifneeded odfi::dev::hw::h2dl::sim::vcd          2.0.0 [list source [file join $dir h2dl-2.x h2dl-2.x-sim-vcd.tm]]
package ifneeded odfi::dev::hw::h2dl::sim2              2.0.0 [list source [file join $dir h2dl-2.x h2dl-2.x-sim2.tm]] 

package ifneeded odfi::dev::hw::netlist                 1.0.0 [list source [file join $dir netlist netlist-1.0.0.tm]]
package ifneeded odfi::dev::hw::package                 1.0.0 [list source [file join $dir package package-1.0.0.tm]]
