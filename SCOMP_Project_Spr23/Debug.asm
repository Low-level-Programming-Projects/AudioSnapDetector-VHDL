; test code lol
; group 1, ece 2031, 4-3-2023
; simple test to see if stuff workin' properly
; Justin E. (file author), Cameron H., Jameson G., Pratz M., Ashan D.

ORG 0
Start:
	IN     	Audio	; get 16-bit audio input from peripheral
	OUT     Hex0;
	
SnapDetect:	; PURPOSE: use isSnapDetected to determine whether to turn on all lights or not
	AND		Bit0	; bit-mask to get isSnapDetected
	JPOS	TurnOnAllLights   ; turn on all lights if isSnapDetected is 1
	JUMP	TurnOffAllLights  ; otherwise jump to Finish
	
TurnOnAllLights:	        ; PURPOSE: go here if isSnapDetected = 1
	LOAD	AllLightsOn		; load value to turn on all lights
	OUT		LEDs	        ; turn all lights on
	JUMP	Start			; jump to Finish afterwards

TurnOffAllLights:
    LOADI 0
	OUT LEDs
	JUMP Start
	

ORG &H02A
; Useful binary constants
Bit0:        DW &B1
AllLightsOn: DW	&B1111111111

; IO address constants
Switches:  EQU 000
LEDs:      EQU 001
Hex0:      EQU 004
Audio:	   EQU &H50