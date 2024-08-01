; audio_peri_output_revised.asm
; brings in peripheral information and outputs it to proper peripherals
; also has some functionality for demo
; Justin E. (file author), Cameron H., Jameson G., Pratz M., Ashan D.
; ECE 2031 L00, Spring 2023 - Audio Peripheral Project

; NOTE: this is how the input audio bits are partitioned
; | -- sound magnitude (9 bits) -- | -- clap/snap count (6 bits) -- | -- snap detect bit (1 bit) |

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
	
OutputCountAndMag:	; PURPOSE: display snap count/sound magnitude to hex displays and switches to audio peripheral
	LOAD	SnapCount	; load count of number of snaps
	OUT		Hex0	    ; output SnapCount value on Hex1 display

ConfigureThreshold:	; PURPOSE: Allows for user to set dynamic thresholds
	LOAD	SwitchVal	; load value of switches
	OUT		Audio	    ; output value of switches to audio peripheral and sets audio thershold
	
OutputSnapDetect:	        ; PURPOSE: use isSnapDetected to determine whether to turn on all lights or not
	LOAD	isSnapDetected	; load isSnapDetected
	JPOS	TurnOnAllLights	; turn on all lights if isSnapDetected is 1
	JUMP	TurnOffAllLights	; turn off all lights if isSnapDetected is 0

TurnOnAllLights:	        ; PURPOSE: go here if isSnapDetected = 1
	LOAD	AllLightsOn		; load value to turn on all lights
	OUT		LEDs	        ; turn all lights on
	JUMP	Start			; go back to Start
	
TurnOffAllLights:			; PURPOSE: go here if isSnapDetected = 0
	LOADI	0				; load value to turn off all lights
	OUT		LEDs			; turn off all lights
	JUMP	Start			; go back to Start
	

; Useful binary constants
Bit0:        DW &B1
AllLightsOn: DW	&B1111111111

; IO address constants
Switches:  EQU 000
LEDs:      EQU 001
Timer:	   EQU 002
Hex0:      EQU 004
Hex1:      EQU 005
Audio:	   EQU &H50

; Variables
AudioData:      DW 0
isSnapDetected:	DW 0	; LSB (also signals whether all lighs should be toggled)
SnapCount:	    DW 0	; 15 MSBs
SwitchVal:	    DW 0	; raw value of swtiches