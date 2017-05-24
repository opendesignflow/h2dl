# Syntax


## Register 

    :register NAME {
        :width set WIDTH (1 per default)
        :description set "DOC"
    }

### Bit Mapping

To map certain bits to a named variable:

    :register NAME {
        :width set WIDTH (1 per default)
        :description set "DOC"

        :bitMap INDEX MAPNAME
    }

    $NAME_MAPNAME is valid here

## Wire 

    :wire NAME {
        :width set WIDTH (1 per default)
        :description set "DOC"
    }

## Expressions 

### Blocking / Non-Blocking assign

    
    $value <= EXPRESSION
    $value =  EXPRESSION

### Bit Select
	
	## Single Bit
    $value @ INDEX
    
    ## Range
    $value @ START:STOP
    
## Controls

### Case 

   :case [list $signal $signal ...] {
   		
   		:on "values as string" {
   		
   		}
   }
