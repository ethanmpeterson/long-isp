.MACRO doubleDabble
//doubleDabble:
	ldi addReg, 3
	ldi times, 8
	clr onesTens
	clr hundreds
decideStep:
; check if 3 needs to be added to any of the ones tens or hundreds nibbles
checkOnes:
	mov working, onesTens
	andi working, 0b00001111 ; analyze only the lower nibble where ones value is
	cpi working, 5
	brsh addThreeOnes
checkTens:
	mov working, onesTens
	andi working, 0b11110000 ; analyze only the upper nibble where tens value is stored
	cpi working, 80
	brsh addThreeTens
checkHundreds:
	cpi hundreds, 5
	brsh addThreeHundreds
; bit shift
shift:
	lsl @0
	rol onesTens
	rol hundreds
	dec times
	cpi times, 0 ; if the @0 value has been shifted 8 times move to POV section of the code
	breq endDabble //display
	rjmp decideStep ; otherwise repeat

addThreeOnes:
	add onesTens, addReg
	rjmp checkTens

addThreeTens:
	swap onesTens
	add onesTens, addReg
	swap onesTens
	rjmp checkHundreds

addThreeHundreds:
	add hundreds, addReg
	rjmp shift
endDabble:
	ret
.ENDMACRO