package provide odfi::h2dl::sdc 2.0.0
package require odfi::h2dl 2.0.0
package require odfi::language::nx 1.0.0

namespace eval odfi::h2dl::sdc {

    ::odfi::language::nx::new [namespace current] {


        :xdc filePath {
            +exportTo ::odfi::h2dl::Module sdc

            +builder {

                ## File path can be relative to the file where the xdc object is being build
                set :filePath [::odfi::files::absolutePathFromCallLocation ${:filePath}]

                ## get parent module
                :object variable -accessor public module [:parent]

                puts "XDC at: ${:filePath} // [::odfi::common::findFileLocation]"

                ## Read File content
                set xdcFileContent [::odfi::files::readFileContent ${:filePath}]

                ## Replace the required supported API lines with starting with ":" to make it compatible with NX
                set xdcFileContent [regsub -all {(\s+|\[)(set_property|get_ports|create_clock|create_generated_clock|get_pins|set_false_path|get_clocks|set_input_delay|set_output_delay)} $xdcFileContent {\1:\2}]
               
               
               #puts "Done XDC: $xdcFileContent"
                eval  ${xdcFileContent}

                


            }


            ## XDC API
            ##########
            +method get_ports args {

                

                ## Look into Module for IO port, if none, just create
                set args [join $args]
                #puts "get ports with: $args -> [llength $args]"
                set res {}
                foreach port $args {
                    
                    ## Name could contain "\[\]" used for buses
                    ## Extract name and position in bus, and use the position to update the size of the bus
                    regexp {([\w\d_\-\.]+)(?:\[(\d+)\]+)?} $port -> portName portBit
                    #puts "Looking up $portName"
                    set foundPort [${:module} shade ::odfi::h2dl::IO findChildByProperty name $portName]
                    if {$foundPort==""} {

                        ## Create if not present
                        #puts "Creating $portName"
                        set foundPort [${:module} input $portName]

                    } 
                    
                    ## Update Width if the position in bus is smaller eq to the widt (bit 1 and width 1 should update to width 2)
                    if {$portBit!="" && [$foundPort width get]<=$portBit} {
                        $foundPort widen
                    }
                    
                    ## save
                    lappend res $foundPort
                }

                return $res


            }
            
            +method get_pins args {
                
            } 

            +method set_property args {

                ## Look for port and properties
                if {[catch {::odfi::flist::lsearchExactAssign $args {-dict properties}}]} {
                    return
                }
                set port [lindex $args end]
                
                
               # puts "set property on $port : $properties"
                
                ## Setting them
                ## Format can be: 
                ##  - KEY VALUE, then the attribute container will be "::"
                ##  - CONTAINER::KEY VALUE, then the attribute container will be "CONTAINER"
                if {$properties!=""} {
                
                    foreach {name value} $properties {
                        
                        ## Split name to "::" and remove empty
                        [::odfi::flist::split $name "::"] @> filterNot { expr {$it ==":" || $it==""} } @> matchSize {
                            
                            0 { } 
                            1 { 
                                $port attribute "::" [:at 0] $value
                            }
                            default {
                                $port attribute ::[join [:sublist 0 end-1] "::"] [:at end] $value
                            }
                            
                         
                        }
                        
                    }
                }

            }

            +method create_clock args {

            }
            
            +method create_generated_clock args {
            
            }

            +method get_clocks args {

            }
            +method set_input_delay args {

            }
            +method set_output_delay args {

            }
            
            +method set_false_path args {
            
            }

            ## Change IO directions 
            ############
            +method toInput args {
                #puts "toInput ports with: $args -> [llength $args]"
                foreach p [:get_ports [join $args]] {
                    $p toInput
                }
            }
            
            +method toOutput args {
                        
                foreach p [:get_ports [join $args]] {
                    $p toOutput
                }
            }
            +method toInout args {
                                    
                foreach p [:get_ports [join $args]] {
                    $p toInout
                }
            }
            
            +method ioRename renames {
            
                foreach {old -> newName} $renames {
                    [:get_ports $old] attribute ::odfi::h2dl name $newName
                }
            }

        }


    }

}