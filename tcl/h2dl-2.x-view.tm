package provide odfi::dev::hw::h2dl::view 2.0.0
package require odfi::dev::hw::h2dl 2.0.0


namespace eval odfi::dev::hw::h2dl::view {


    odfi::language::Language define VIEW {

        :view name type closure {
            +exportTo odfi::dev::hw::h2dl::Module


            +method elaborate args {
                return [eval ${:closure}]
            }

            +method viewShade {type {match *}} {


                puts "Trying to gather Views of type $type with matching $match"

                ## Go through the  


            }
        }

    }
    VIEW produceNX

}
