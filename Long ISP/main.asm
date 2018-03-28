;
; Long ISP.asm
;
; Created: 2018-03-21 3:32:54 PM
; Author : Ethan Peterson
;

.cseg                                          ;load into Program Memory
#include "prescalers.h"
.org   0x0000                          ;start of Interrupt Vector (Jump) Table
        rjmp    reset                           ;address  of start of code
startTable:    
		// A set of random numbers until I know how to generate them in assembly language
		.DB 4, 7, 32, 94, 28, 69, 48, 51, 15, 0
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
	.def score = r23 ; incrimented upon each correct binary combo
	.def index = r15

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

setup:
	clr input
	clr score
	clr original
	clr index
	rjmp loop

start:
	ldi addReg, 3
	ldi times, 8
	; clear registers storing double dabble output and input from rotary switch
	clr onesTens
	clr hundreds
	out 0x0A, hundreds ; clear DDRD register using 0 value in hundreds reg
	// load original with data from table
	//clr zl
	//lpm original, z
	//movw z,x
	//ldi score, 64
	mov original, score
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
	
	
doubleDabble:

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
	ret

display:
	ldi r16, 1 << PB2 | 1 << PB1 | 1 << PB0
	out 0x04, r16 ; set all transistor manipulation pins to output
	ldi r16, 1 << PB2 
	out 0x05, r16 ; enable only hundreds display
	ldi r16, 0xFF
	out 0x07, r16 ; set 4511 outputs
	mov r16, hundreds
	out 0x08, r16
	rcall delay
	; switch to tens display
	ldi r16, 1 << PB1
	out 0x05, r16
	mov working, onesTens
	andi working, 0b11110000
	swap working
	out 0x08, working ; display tens
	rcall delay
	; switch to ones Display
	ldi r16, 1 << PB0
	out 0x05, r16
	mov working, onesTens
	andi working, 0b00001111
	out 0x08, working
	rcall delay ; admire
	//rjmp reset ; restart the program to update input value and reset the required registers
	ret ;

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

	cp input, score//original
	breq isEqual
	back:

	//breq isEqual
	//mov hundreds, input
	rcall start
	//rcall getInput
	//clr input
	//ldi original, 255
	
	rcall doubleDabble
	reti

loop:
	rcall display
	rjmp loop

isEqual:
	//inc index
	inc score
	rcall start
	rcall doubleDabble
	reti