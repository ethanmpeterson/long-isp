start:
	//rcall initPorts
	ldi r16, 4
	rjmp loop

.MACRO shiftOut // MSBFIRST Shiftout
	cbi PORTB, latch
	// handle shifting data
	cbi PORTB, clk
	cbi PORTB, data
	sbrc r16, 7 // skip if bit in register passed to macro is cleared
	sbi PORTB, data
	sbi PORTB, clk

	cbi PORTB, clk
	cbi PORTB, data
	sbrc r16, 6 // skip if bit in register passed to macro is cleared
	sbi PORTB, data
	sbi PORTB, clk

	cbi PORTB, clk
	cbi PORTB, data
	sbrc r16, 5 // skip if bit in register passed to macro is cleared
	sbi PORTB, data
	sbi PORTB, clk

	cbi PORTB, clk
	cbi PORTB, data
	sbrc r16, 4 // skip if bit in register passed to macro is cleared
	sbi PORTB, data
	sbi PORTB, clk

	cbi PORTB, clk
	cbi PORTB, data
	sbrc r16, 3 // skip if bit in register passed to macro is cleared
	sbi PORTB, data
	sbi PORTB, clk

	cbi PORTB, clk
	cbi PORTB, data
	sbrc r16, 2 // skip if bit in register passed to macro is cleared
	sbi PORTB, data
	sbi PORTB, clk

	cbi PORTB, clk
	cbi PORTB, data
	sbrc r16, 1 // skip if bit in register passed to macro is cleared
	sbi PORTB, data
	sbi PORTB, clk

	cbi PORTB, clk
	cbi PORTB, data
	sbrc r16, 0 // skip if bit in register passed to macro is cleared
	sbi PORTB, data
	sbi PORTB, clk

	sbi PORTB, latch
.ENDMACRO

loop:
	shiftOut r16
	rjmp wait

wait:
	rjmp wait


initShiftReg:
	sbi DDRB, PB3
	sbi DDRB, PB4
	sbi DDRB, PB5
	ret
/*initPorts:
        ldi  r16, 1<<data | 1<<clk | 1<<latch
        out  DDRB,r16                                   ;declare three control lines for output
        ret*/