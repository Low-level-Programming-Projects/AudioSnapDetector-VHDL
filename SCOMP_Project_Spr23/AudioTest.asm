; AudioTest.asm
; Displays the value from the audio peripheral (outputs audio data)

ORG 0
	; Get data from the audio peripheral
	IN     Sound
	; Display value on Hex 0
	OUT    Hex0
    ; Display most-significant 10 bits of the magnitude on LEDs
    CALL   Abs
    SHIFT  -6
    OUT    LEDs
	; Do it again
	;JPOS Loop
	;JUMP 0
	
	
; Subroutine to get the absolute value.
; Additional subroutine for negation is made available,
; since that's required for absolute value anyway.
Abs:
	JNEG   Negate
    RETURN ; positive or zero; just return
Negate:
	STORE  NegTemp
    SUB    NegTemp
    SUB    NegTemp
	RETURN
NegTemp: DW 0

; IO address constants
Switches:  EQU 000
LEDs:      EQU 001
Timer:     EQU 002
Hex0:      EQU 004
Hex1:      EQU 005
Sound:     EQU &H50
