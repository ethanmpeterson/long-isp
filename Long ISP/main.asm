;
; Long ISP.asm
;
; Created: 2018-03-21 3:32:54 PM
; Author : Ethan Peterson
;

.dseg

array: ; array of random numbers for binary game
	.byte 100 ; reserves 100 bytes for 100 unqiue numbers over 5 min play period

.cseg                                          ;load into Program Memory
#include "prescalers.h"
//#include "doubleDabble.s" // move double dabble algorithms and other macros here at some point
.org   0x0000                          ;start of Interrupt Vector (Jump) Table
        rjmp    reset                           ;address  of start of code
.equ size = 15
	; set stack pointers
	ldi xl, low(array)
	ldi xh, high(array)
startTable: //.byte   
		// A set of random numbers until I know how to generate them in assembly language
		.DB 4, 14, 32, 94, 28, 69, 48, 51, 15, 0
.org 0x000E
	rjmp TIM2_COMPA
endTable:
.org    0x100                                   ;abitrary address for start of code
 reset:
	clr r22
    ldi             r16, low(RAMEND)        ; ALL assembly code should start by
    out             spl,r16                 ; setting the Stack Pointer to
    ldi             r16, high(RAMEND)       ; the end of SRAM to support
    out             sph,r16                 ; function calls, etc.

   ldi             xl,low(startTable<<1)   ; position X and Y pointers to the
   ldi             xh,high(startTable<<1)  ; start and end addresses of
   ldi             yl,low(endTable<<1)     ; our data table, respectively
   ldi             yh,high(endTable<<1)    ;
   movw    z,x

.def original = r16 ; value to be pushed through double dabble algorithm
.def onesTens = r17 ; register holding ones and tens output nibbles from double dabble
.def hundreds = r22 ; hundreds output from double dabble
.def working = r24 ; register used to work with data that needs to be preserved elsewhere
.def addReg = r20 ; holds a value of 3 to be added to other registers in the double dabble process
.def times = r25 ; register holding the number of bit shifts the double dabble algorithm must do before being complete
.def input = r21 ; raw graycode input from rotary encoder
.def index = r23 ; incrimented upon each correct binary combo
.def score = r15
.def copy = r14

.equ data = PB3
.equ latch = PB5
.equ clk = PB4

timers:
	cli ; global interrupt disable
	ldi r16, T2ps1024 ; set the prescaler
	sts TCCR2B, r16 ; store to appropriate register
	ldi r16, 0x02 ; set timer mode 2
	sts TCCR2A, r16 ; store
	ldi r16, 124 ; set output compare number to get 63hz freq
	sts OCR2A, r16 ; store to output compare reg

	ldi r16, 1 << OCIE2A ; set timer interrupt enable bit
	sts TIMSK2, r16 ; enable the interrupt
	sei ; global interrupt enable

generateRandoms: ; generates the random numbers in to populate the array
	ret

setup:
	// generate random numbers and load startTable here

	clr input
	clr index
	clr copy
	clr original
	clr score
	rcall initScoreDisplay
	rcall initShiftReg
	rjmp loop

start:
	out 0x0A, hundreds ; clear DDRD register using 0 value in hundreds reg
	// load original with data from table
	//clr zl
	//lpm original, z
	//movw z,x
	//ldi index, 64
	mov zl, index
	lpm original, z
	lpm copy, z
	movw z, x
	//mov original, index
	ret


getInput:
/*	in input, 0x09 ; load PIND into input register
	lsr input ; fix off by one bit issue due to wiring config
	andi input, 0b00001111 ; mask upper nibble off of input as the pins left floating cause eratic readings
	
    add zl, input ; add input value to low byte of z to set it to the correct index in the array containing the converted binary of the given graycode
	lpm original, z ; load the corresponding binary value from table                             
    movw z,x*/

	// Get random byte value to be challenge val for binary challenge
	//inc input

	ret 
	
	
/*doubleDabble:
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
	lsl original
	rol onesTens
	rol hundreds
	dec times
	cpi times, 0 ; if the original value has been shifted 8 times move to POV section of the code
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
	ret*/
.MACRO shiftOut // MSBFIRST Shiftout
	cbi PORTB, latch
	// handle shifting data
	cbi PORTB, clk
	cbi PORTB, data
	sbrc @0, 7 // skip if bit in register passed to macro is cleared
	sbi PORTB, data
	sbi PORTB, clk

	cbi PORTB, clk
	cbi PORTB, data
	sbrc @0, 6 // skip if bit in register passed to macro is cleared
	sbi PORTB, data
	sbi PORTB, clk

	cbi PORTB, clk
	cbi PORTB, data
	sbrc @0, 5 // skip if bit in register passed to macro is cleared
	sbi PORTB, data
	sbi PORTB, clk

	cbi PORTB, clk
	cbi PORTB, data
	sbrc @0, 4 // skip if bit in register passed to macro is cleared
	sbi PORTB, data
	sbi PORTB, clk

	cbi PORTB, clk
	cbi PORTB, data
	sbrc @0, 3 // skip if bit in register passed to macro is cleared
	sbi PORTB, data
	sbi PORTB, clk

	cbi PORTB, clk
	cbi PORTB, data
	sbrc @0, 2 // skip if bit in register passed to macro is cleared
	sbi PORTB, data
	sbi PORTB, clk

	cbi PORTB, clk
	cbi PORTB, data
	sbrc @0, 1 // skip if bit in register passed to macro is cleared
	sbi PORTB, data
	sbi PORTB, clk

	cbi PORTB, clk
	cbi PORTB, data
	sbrc @0, 0 // skip if bit in register passed to macro is cleared
	sbi PORTB, data
	sbi PORTB, clk

	sbi PORTB, latch
.ENDMACRO

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
	//ret
.ENDMACRO

.MACRO numDisplaySelect // MACRO to enable display of choice in number display
	cbi PORTB, PB2
	cbi PORTB, PB1
	cbi PORTB, PB0

	sbi PORTB, @0
.ENDMACRO

.MACRO scoreDisplaySelect // MACRO to enable appropiate score display ones or tens
	cbi PORTC, PC4
	cbi PORTC, PC5

	sbi PORTC, @0
.ENDMACRO

.MACRO numDisplayOut
	cbi PORTC, PC0
	sbrc @0, 0
	sbi PORTC, PC0
	
	cbi PORTC, PC1
	sbrc @0, 1
	sbi PORTC, PC1
	
	cbi PORTC, PC2
	sbrc @0, 2
	sbi PORTC, PC2

	cbi PORTC, PC3
	sbrc @0, 3
	sbi PORTC, PC3
	
.ENDMACRO

display:
	rcall initNumDisplay ; set all transistor manipulation pins to output
	numDisplaySelect PB2
	//ldi r16, 0xFF
	//out DDRC, r16 ; set 4511 outputs
	//out PORTC, r16
	numDisplayOut hundreds ; display hundreds
	rcall delay
	; switch to tens display
	numDisplaySelect PB1
	mov working, onesTens
	andi working, 0b11110000
	swap working
	numDisplayOut working
	//out PORTC, working ; display tens
	rcall delay
	; switch to ones Display
	numDisplaySelect PB0
	mov working, onesTens
	andi working, 0b00001111
	//out PORTC, working
	numDisplayOut working
	rcall delay ; admire
	//rjmp reset ; restart the program to update input value and reset the required registers
	ret ;

scoreDisplay: // not working * 
	scoreDisplaySelect PC5 ; select ones display
	mov r18, score ; retain score value
	doubleDabble r18
	mov working, onesTens
	andi working, 0b00001111
	shiftOut working
	rcall delay
	//rcall delay
	scoreDisplaySelect PC4 ; select tens display
	mov working, onesTens
	andi working, 0b11110000
	swap working
	shiftOut working
	//rcall delay
	mov r18, copy
	doubleDabble r18
	ret

delay: ; 1 ms delay
ldi  r18, 11
    ldi  r19, 99
L1: dec  r19
    brne L1
    dec  r18
    brne L1
	ret

TIM2_COMPA:
	//inc onesTens
	//rcall checkEqual
	//in original, PIND
	//cp input, original
	in input, PIND
	//lpm original, z
	cp input, copy //index
	breq isEqual
	//breq isEqual
	//mov hundreds, input
	rcall start
	//rcall getInput
	//clr input
	//ldi original, 255
	
	//doubleDabble original
	reti

loop:
	//rcall scoreDisplay
	rcall display
	rcall scoreDisplay
	//rcall scoreDisplay
	//shiftData score
	rjmp loop

isEqual:
	//inc index
	inc index
	inc score
	rcall start
	doubleDabble original
	reti

initShiftReg:
	sbi DDRB, PB3
	sbi DDRB, PB4
	sbi DDRB, PB5
	ldi original, 0
	shiftOut original
	ret

initScoreDisplay:
	//ldi r18, 1 << PC4 | 1 << PC5
	//out DDRC, r18
	sbi DDRC, PC4
	sbi DDRC, PC5
	ret

initNumDisplay:
	sbi DDRB, PB0
	sbi DDRB, PB1
	sbi DDRB, PB2

	sbi DDRC, PC0
	sbi DDRC, PC1
	sbi DDRC, PC2
	sbi DDRC, PC3

	ret