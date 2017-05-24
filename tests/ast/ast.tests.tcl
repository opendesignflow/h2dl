

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
    
    :test "Concat" {
    
        set a [odfi::h2dl::Wire new -name a]
        set b [odfi::h2dl::Wire new -name b]
        set c [odfi::h2dl::Wire new -name c]
        set d [odfi::h2dl::Wire new -name c]
        $a width set 4
        $b width set 4
        $c width set 4
        
        set expr [odfi::h2dl::ast::buildAST ( $a @ 0 <- 2 ) , ( $b @ 1 <- 3 ) , $d , ( $c @ 1 <- 3 )] 
        $expr  object mixins add odfi::flextree::utils::StdoutPrinter
        
        puts "Expression: [$expr info class]"
        $expr printAll
    }

    ##puts "inside sutie: [current object]"
}


odfi::utests::run
