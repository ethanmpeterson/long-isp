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
.equ size = 15
.org 0x000E
	rjmp TIM2_COMPA
.org 0x002A
	rjmp ADC_Complete
.org 0x0020
		rjmp TIM0_OVF

.org 0x001A
		rjmp TIM1_OVF

.org    0x100                                   ;abitrary address for start of code
 reset:
	clr r22
    ldi             r16, low(RAMEND)        ; ALL assembly code should start by
    out             spl,r16                 ; setting the Stack Pointer to
    ldi             r16, high(RAMEND)       ; the end of SRAM to support
    out             sph,r16                 ; function calls, etc.
   movw    z,x

.def original = r16 ; value to be pushed through double dabble algorithm
.def onesTens = r17 ; register holding ones and tens output nibbles from double dabble
.def hundreds = r22 ; hundreds output from double dabble
.def working = r24 ; register used to work with data that needs to be preserved elsewhere
.def addReg = r20 ; holds a value of 3 to be added to other registers in the double dabble process
.def times = r25 ; register holding the number of bit shifts the double dabble algorithm must do before being complete
.def input = r21 ; raw graycode input from rotary encoder
.def newValue = r23 ; where newly generated random numbers will be stored
.def score = r15
.def copy = r14
.def overflows = r13
.def gameEndFlag = r11
.def scoreCopy = r10

.equ data = PB3
.equ latch = PB5
.equ clk = PB4

rjmp setup

timers:
	//cli ; global interrupt disable
	ldi r16, T2ps1024 ; set the prescaler
	sts TCCR2B, r16 ; store to appropriate register
	ldi r16, 0x02 ; set timer mode 2
	sts TCCR2A, r16 ; store
	ldi r16, 124 ; set output compare number to get 63hz freq
	sts OCR2A, r16 ; store to output compare reg

	ldi r16, 1 << OCIE2A ; set timer interrupt enable bit
	sts TIMSK2, r16 ; enable the interrupt
	ret

ADCInit:
	ser r16 ; set all bits in r16
	ldi r16, (1 << REFS0) | (1 << ADLAR)
	sts ADMUX, r16
	; Enable, start dummy conversion, enable timer as trigger, prescaler
	ldi r16, (1 << ADEN) | (1 << ADSC) | (1 << ADIE) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0)
	sts ADCSRA, r16
	ldi r16, 1 << ADTS2
	sts ADCSRB, r16
dummy:
	lds r16, ADCSRA
	andi r16,  1 << ADIF
	breq dummy
	ret

ADC_Complete:
	lds newValue, ADCH ; grab ADC reading and place in gp reg
	reti

T0Init: ; initialize T0 interrupt to schedule ADC conversions
	clr r16
	out TCCR0A, r16 ; normal mode OC0A/B disconnected
	ldi r16, T0ps8 ; 
	out TCCR0B, r16
	ldi r16, 1 << TOIE0 ; Timer interrupt enable
	sts TIMSK0, r16 ; output to mask register to
	ret

T1Init: ; 1 Hz Timer overflow interrupt to monitor how long game has ran
	clr r16
	ldi r16, 1 << CS12
	sts TCCR1B, r16
	ldi r16, 1 << TOIE1
	sts TIMSK1, r16
	ret

TIM0_OVF:
	lds r19, ADCSRA ; start an ADC conversion
	sbr r19, 1 << ADSC ; set the required bit
	sts ADCSRA, r19
	reti

TIM1_OVF:
	dec overflows
	tst overflows
	breq fourMin
	reti

fourMin:
	; end the game here
	dec gameEndFlag
	reti

setup:
	
	ldi r16, 240
	mov overflows, r16
	ldi r16, 1
	mov gameEndFlag, r16

	clr newValue
	clr input
	clr copy
	clr original
	clr score
	cli

	rcall initScoreDisplay
	rcall initShiftReg
	rcall timers
	rcall ADCInit
	//rcall T0Init
	rcall T1Init
	sei
	rjmp loop

start:
	out 0x0A, hundreds ; clear DDRD register using 0 value in hundreds reg

	mov r17, newValue ; copy the seed
	and r17, r18 
	ldi r18, 0x43
	; generate random # in newValue reg using ADC reading as seed... reference: https://www.avrfreaks.net/forum/i-need-pseudo-random-number-generator-attiny-13
	lsr r17
	adc r18, r19
	lsr r17
	adc r18, r19
	lsr r17
	lsr r17
	lsr r17
	lsr r17
	lsr r17
	adc r18, r19
	bst r18, 0 ;
	bld newValue, 7
	lsr newValue

	mov original, newValue
	mov copy, newValue
	ret


.MACRO shiftOut ; MSBFIRST Shiftout
	cbi PORTB, latch
	; handle shifting data
	cbi PORTB, clk
	cbi PORTB, data
	sbrc @0, 7 ; skip if bit in register passed to macro is cleared
	sbi PORTB, data
	sbi PORTB, clk

	cbi PORTB, clk
	cbi PORTB, data
	sbrc @0, 6 ; skip if bit in register passed to macro is cleared
	sbi PORTB, data
	sbi PORTB, clk

	cbi PORTB, clk
	cbi PORTB, data
	sbrc @0, 5 ; skip if bit in register passed to macro is cleared
	sbi PORTB, data
	sbi PORTB, clk

	cbi PORTB, clk
	cbi PORTB, data
	sbrc @0, 4 ; skip if bit in register passed to macro is cleared
	sbi PORTB, data
	sbi PORTB, clk

	cbi PORTB, clk
	cbi PORTB, data
	sbrc @0, 3 ; skip if bit in register passed to macro is cleared
	sbi PORTB, data
	sbi PORTB, clk

	cbi PORTB, clk
	cbi PORTB, data
	sbrc @0, 2 ; skip if bit in register passed to macro is cleared
	sbi PORTB, data
	sbi PORTB, clk

	cbi PORTB, clk
	cbi PORTB, data
	sbrc @0, 1 ; skip if bit in register passed to macro is cleared
	sbi PORTB, data
	sbi PORTB, clk

	cbi PORTB, clk
	cbi PORTB, data
	sbrc @0, 0 ; skip if bit in register passed to macro is cleared
	sbi PORTB, data
	sbi PORTB, clk

	sbi PORTB, latch
.ENDMACRO

.MACRO doubleDabble
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
	breq endDabble
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

.MACRO numDisplaySelect ; MACRO to enable display of choice in number display
	cbi PORTB, PB2
	cbi PORTB, PB1
	cbi PORTB, PB0

	sbi PORTB, @0
.ENDMACRO

.MACRO scoreDisplaySelect ; MACRO to enable appropiate score display ones or tens
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
	numDisplayOut hundreds ; display hundreds
	rcall delay
	; switch to tens display
	numDisplaySelect PB1
	mov working, onesTens
	andi working, 0b11110000
	swap working
	numDisplayOut working
	rcall delay
	; switch to ones Display
	numDisplaySelect PB0
	mov working, onesTens
	andi working, 0b00001111
	numDisplayOut working
	rcall delay ; admire
	ret ;

scoreDisplay:
	scoreDisplaySelect PC5 ; select ones display
	mov r18, score ; retain score value
	doubleDabble r18
	mov working, onesTens
	andi working, 0b00001111
	shiftOut working
	rcall delay
	scoreDisplaySelect PC4 ; select tens display
	mov working, onesTens
	andi working, 0b11110000
	swap working
	shiftOut working
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


loop:
	rcall display ; display POV for challenge number and score
	rcall scoreDisplay

	tst gameEndFlag
	breq gameEnd

	rjmp loop


gameEnd:
	ldi original, 0
	doubleDabble original
	rcall display
	mov scoreCopy, score
	doubleDabble scoreCopy
	rcall scoreDisplay
	rjmp gameEnd

TIM2_COMPA:
	in input, PIND
	cp input, copy
	breq isEqual
	reti

isEqual:
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