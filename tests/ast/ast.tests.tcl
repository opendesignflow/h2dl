

package require odfi::h2dl 2.0.0
package require odfi::utests 1.0.0



odfi::utests::suite ast {

    :test "this &&  that" {

        puts "Running test"

        ## Create 
        set a [odfi::h2dl::Register new -name a]
        set b [odfi::h2dl::Register new -name b]

        ## Expression
        set expr [odfi::h2dl::ast::buildAST "($a == 0) && ($b == 1)"]

        puts "Expression: [$expr info class]"
    }

    ##puts "inside sutie: [current object]"
}


odfi::utests::run
