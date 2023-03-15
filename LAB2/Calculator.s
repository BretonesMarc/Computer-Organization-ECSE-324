.global _start

.equ HEX_ADDR, 0xFF200020
.equ PB_EDGE_CAPTURE_ADDR, 0xFF20005C
.equ SWITCH_ADDR, 0xFF200040
.equ HEX5, 0xFF200031
.equ NOTHING, 0x0

.equ MINUS, 0x40
.equ ZERO, 0x3F
.equ ONE, 0x06
.equ TWO, 0x5B
.equ THREE, 0x4F
.equ FOUR, 0x66
.equ FIVE, 0x6D
.equ SIX, 0x7D
.equ SEVEN, 0x07
.equ EIGHT, 0x7F
.equ NINE, 0x67
.equ A, 0x77
.equ B, 0x7C
.equ C, 0x39
.equ D, 0x5E
.equ E, 0x79
.equ F, 0x71

_start:
//mov R0, #0x00000008
//mov R1, #0x0000000A
BL PB_polling_ASM
//BL HEX_clear_ASM

PB_polling_ASM:
	LDR R5, =PB_EDGE_CAPTURE_ADDR
	LDR R0, [R5]
	STR R0, [R5]
	CMP R0, #0
	BEQ PB_polling_ASM
	
	CMP R0, #1
	BEQ HEX_clear_ASM
	
	CMP R0, #2
	BEQ multiplication
	
	CMP R0, #4
	BEQ subtraction
	
	CMP R0, #8
	BEQ addition
	
	
multiplication:
	PUSH {LR}
	BL read_slider_switches_ASM
	POP {LR}
	MUL R7, R7, R6
	MOV R12, R7
	BL HEX_write_ASM
	B PB_polling_ASM
	
subtraction:
	PUSH {LR}
	BL read_slider_switches_ASM
	POP {LR}

	CMP R10, #1
	BEQ addition_core
	subtraction_core:
	CMP R7, R6
	SUBGE R7, R7, R6
	SUBLT R7, R6, R7
	MOVLT R10, #1
	MOV R12, R7
	BL HEX_write_ASM
	B PB_polling_ASM
	
addition:
	PUSH {LR}
	BL read_slider_switches_ASM
	POP {LR}
	
	CMP R10, #1
	BEQ subtraction_core
	addition_core:
	ADD R7, R7, R6
	MOV R12, R7
	BL HEX_write_ASM
	B PB_polling_ASM
	
read_slider_switches_ASM:
    LDR R7, =SWITCH_ADDR
    LDR R6, [R7]
	MOV R7, R6
	AND R6, R6, #0b00001111
	CMP R12, #0
	ANDEQ R7, R7, #0b11110000
	MOVNE R7, R12
	LSREQ R7, #4
    BX  LR

//turns off all the segments of the selected HEX displays.
//receives the selected HEX display indices through register R0 as an argument
HEX_clear_ASM:
	LDR R4, =HEX_ADDR
	LDR R2, =ZERO   	// write zero 
	STRB R2, [R4], #1   // Write to first 7-segment display
	STRB R2, [R4], #1
	STRB R2, [R4], #1
	STRB R2, [R4], #13
	STRB R2, [R4], #1
	MOV R12, #0
	MOV R10, #0
	
	LDR R2, =NOTHING
	LDR R11, =HEX5
	STRB R2, [R11]
	
	B PB_polling_ASM

//This subroutine turns on all the segments of the selected HEX displays. 
//It receives the selected HEX display indices through register R0 as an argument.
HEX_flood_ASM:
	LDR R4, =HEX_ADDR
	
	TST R0, #0x00000001
	STRNEB R2, [R4]
	ADD R4, R4, #1
	
	TST R0, #0x00000002
	STRNEB R2, [R4]
	ADD R4, R4, #1
	
	TST R0, #0x00000004
	STRNEB R2, [R4]
	ADD R4, R4, #1
	
	TST R0, #0x00000008
	STRNEB R2, [R4]
	ADD R4, R4, #13
	
	TST R0, #0x00000010
	STRNEB R2, [R4]
	ADD R4, R4, #1
	
	BX LR
	
//Receives HEX display indices & integer value 0-15 to display passed in registers R0 & R1
HEX_write_ASM:
	MOV R1, R7
	MOV R8, #5
	check_address_to_fill:
	
	CMP R8, #5
	ANDEQ R9, R1, #0x0000F
	MOVEQ R0, #0x00000001
	
	CMP R8, #4
	ANDEQ R9, R1, #0x000F0
	LSREQ R9, R9, #4
	MOVEQ R0, #0x00000002
	
	CMP R8, #3
	ANDEQ R9, R1, #0x00F00
	LSREQ R9, R9, #8
	MOVEQ R0, #0x00000004

	CMP R8, #2
	ANDEQ R9, R1, #0x0F000
	LSREQ R9, R9, #12
	MOVEQ R0, #0x00000008

	CMP R8, #1
	ANDEQ R9, R1, #0xF0000
	LSREQ R9, R9, #16
	MOVEQ R0, #0x00000010

    //HEX display address in R0
	//Value in R1
	//You want to update LED state with content of R1, at address in R0
	// If in R1 you have 1, write 1, if 2, write 2, etc
	write0:
		CMP R9, #0  
		BNE write1
		LDR R2, =ZERO
	write1:
		CMP R9, #1   
		BNE write2
		LDR R2, =ONE
	write2:
		CMP R9, #2 
		BNE write3
		LDR R2, =TWO
	write3:
		CMP R9, #3  
		BNE write4
		LDR R2, =THREE
	write4:
		CMP R9, #4  
		BNE write5
		LDR R2, =FOUR
	write5:
		CMP R9, #5  
		BNE write6
		LDR R2, =FIVE
	write6:
		CMP R9, #6   
		BNE write7
		LDR R2, =SIX
	write7:
		CMP R9, #7  
		BNE write8
		LDR R2, =SEVEN
	write8:
		CMP R9, #8  
		BNE write9
		LDR R2, =EIGHT
	write9:
		CMP R9, #9   
		BNE writeA
		LDR R2, =NINE
	writeA:
		CMP R9, #0xA 
		BNE writeB
		LDR R2, =A
	writeB:
		CMP R9, #0xB   
		BNE writeC
		LDR R2, =B
	writeC:
		CMP R9, #0xC   
		BNE writeD
		LDR R2, =C
	writeD:
		CMP R9, #0xD 
		BNE writeE
		LDR R2, =D
	writeE:
		CMP R9, #0xE  
		BNE writeF
		LDR R2, =E
	writeF:
		CMP R9, #0xF   
		BNE finish_display
		LDR R2, =F
		
	finish_display:
		PUSH {LR}
		BL HEX_flood_ASM
		POP {LR}
		SUB R8, #1
		CMP R8, #0
		
		BNE check_address_to_fill
		
		CMP R10, #1
		LDREQ R2, =MINUS
		LDRNE R2, =NOTHING
		LDREQ R11, =HEX5
		STREQB R2, [R11]
		BX LR