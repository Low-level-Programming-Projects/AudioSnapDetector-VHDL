; audio_peri_output.asm
; brings in peripheral information and outputs it to proper peripherals (light bit and clap count)
; Justin E. (file author), Cameron H., Jameson G., Pratz M., Ashan D.
; ECE 2031 L00, Spring 2023 - Audio Peripheral Project


ORG 0
Start:
	IN     	Audio	; get 16-bit processed audio information from peripheral
	STORE  	AudioData	; store audio data as 'AudioData'
	
LoadVars:	; PURPOSE: bit-mask and load appropriate values to variables
	AND		Bit0	; bit-mask to get isSnapDetected
	STORE	isSnapDetected	; store to variable
	LOAD	AudioData		; load raw audio bits
	SHIFT   -1          ; shift out LSB to leave clap count bits
	STORE	SnapCount	; store to variable
	IN		Switches	; get value of switches
	STORE	SwitchVal	; store to variable	

;ADDITIONAL FUNC: CONFIGURABLE THRESHOLDS
ConfigThresh:
	LOAD SwitchVal
	OUT Audio           ; a 10-bit vector (LSB) is received by the peripheral 
	OUT Hex0            ; debugging - checking if the thresholds change/ display
	

OutputCountAndSwitch:	; PURPOSE: display count on hex display and switch value to audio peripheral
	LOAD	SnapCount	; load count of number of snaps
	;OUT		Hex0	    ; output SnapCount value on Hex display
	;LOAD	SwitchVal	; load value of switches
	;OUT	Audio	    ; output value of switches to audio peripheral and sets audio thershold
	;JUMP	Start      ; we're done with process!
	
OutputSnapDetect:	        ; PURPOSE: use isSnapDetected to determine whether to turn on all lights or not
	LOAD	isSnapDetected	; load isSnapDetected
	JPOS	TurnOnAllLights	; turn on all lights if isSnapDetected is 1
	JUMP	TurnOffAllLights	; turn off all lights if isSnapDetected is 0

TurnOnAllLights:	        ; PURPOSE: go here if isSnapDetected = 1
	LOAD	AllLightsOn		; load value to turn on all lights
	OUT		LEDs	        ; turn all lights on
	;CALL	Delay	; delay by 0.67 s to see LEDs with naked eye
	JUMP	Start	; go to Start
	
TurnOffAllLights:			; PURPOSE: go here if isSnapDetected = 0
	LOADI	0				; load value to turn off all lights
	OUT		LEDs			; turn off all lights
	JUMP	Start	; go to Start
	
; To make things happen on a human timescale, the timer is
; used to delay for reasonable time (note: timer is at 1.5 Hz)
Delay:
	OUT    Timer
WaitingLoop:
	IN     Timer
	ADDI   -3
	JNEG   WaitingLoop
	RETURN

; Useful binary constants
Bit0:        DW &B1
BitCount:    DW &B1111111111111110
AllLightsOn: DW	&B1111111111

; IO address constants
Switches:  EQU 000
LEDs:      EQU 001
Timer:     EQU 002
Hex0:      EQU 004
Audio:	   EQU &H50

; Variables
AudioData:        DW 0
isSnapDetected:	DW 0	; LSB (also signals whether all lighs should be on or not)
SnapCount:	    DW 0	; 15 MSB's
SwitchVal:	    DW 0	; raw value of swtiches