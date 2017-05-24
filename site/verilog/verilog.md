# Verilog Extension 


You can produce a Verilog view of an H2DL design, which would be required to use your design in standard industry tools.


    ## Create Module
    set module [odfi::h2dl::module top {

    }]

    ## Produce Verilog
    ## verilog:produce target/folder
    $module verilog:produce verilog




