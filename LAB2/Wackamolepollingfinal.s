.global _start

.equ game_paused, 0
.equ PT_LOAD_ADDR, 0xFFFEC600
.equ PT_COUNTER_ADDR, 0xFFFEC604
.equ PT_CONTROL_ADDR, 0xFFFEC608
.equ PT_INTERRUPT_ADDR, 0xFFFEC60C
.equ HEX_ADDR, 0xFF200020
.equ PB_EDGE_CAPTURE_ADDR, 0xFF20005C
.equ TWO_HUND_MILL, 0xBEBC200
.equ SW_ADDR, 0xFF200040

SEGMENT_TABLE:
    .byte 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F, 0x77, 0x7C, 0x39, 0x5E, 0x79, 0x71


.equ NOTHING, 0x0
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
.equ MOLE, 0x5C

_start:
	MOV R7, #30 //timer count
	LDR R0, =TWO_HUND_MILL
	MOV R1, #0b111
	BL ARM_TIM_config_ASM
	BL mole
	BL poll_timer
	
	
mole:
    PUSH {LR}
    BL HEX_clear_ASM
    POP {LR}

    LDR R5, =PT_COUNTER_ADDR
    LDR R4, =HEX_ADDR
    LDR R2, =MOLE

    LDR R6, =0xFFFEC604
    LDR R6, [R6]
    AND R6, R6, #3
	
    CMP R6, #0
   	STREQB R2, [R4]

    CMP R6, #1
    STREQB R2, [R4, #1]

    CMP R6, #2
    STREQB R2, [R4, #2]

    CMP R6, #3
    STREQB R2, [R4, #3]
	
	MOV R9, R6

    BX LR
	
HEX_clear_ASM:
	PUSH {R2, R4}
	LDR R4, =HEX_ADDR
	LDR R2, =NOTHING
	STRB R2, [R4], #1   // Write to first 7-segment display
	STRB R2, [R4], #1
	STRB R2, [R4], #1
	STRB R2, [R4]	
	POP {R2, R4}
	BX LR
	

poll_timer:
    LDR R5, =PB_EDGE_CAPTURE_ADDR
    
	LDR R0, [R5]
    MOV R3, R0
    //Clear edge capture register
    STR R0, [R5]
	
	CMP R11, #1
	BEQ poll_buttons
	
    PUSH {LR}
    BL ARM_TIM_read_INT_ASM
    POP {LR}
    CMP R0, #0
    BEQ poll_buttons
    
    PUSH {LR}
    BL mole
    POP {LR}

    B update_timer

poll_buttons:
	PUSH {R3}
    CMP R3, #1
    BEQ start_game

    CMP R3, #2
    BEQ stop_game

    CMP R3, #4
    BEQ reset_game
	
	CMP R3, #0
	POP {R3}
    B read_slider_switches_ASM

read_slider_switches_ASM:

    LDR R3, =SW_ADDR     // load the address of slider switch state
    LDR R10, [R3]         // read slider switch state 
	CMP R10, #0
	PUSH {LR}
	BLNE switch_input
	POP {LR}
	
    B poll_timer
	
switch_input:
    cmp r10, #1       // Compare R10 to 1
    beq check_r9_0    // If R10 == 1, branch to check_r9_0
    cmp r10, #2       // Compare R10 to 2
    beq check_r9_1    // If R10 == 2, branch to check_r9_1
    cmp r10, #4       // Compare R10 to 4
    beq check_r9_2    // If R10 == 4, branch to check_r9_2
    cmp r10, #8       // Compare R10 to 8
    beq check_r9_3    // If R10 == 8, branch to check_r9_3
    b end_switch      // If none of the above, branch to end_switch

check_r9_0:
    cmp r9, #0        // Compare R9 to 0
    beq increment_r8  // If R9 == 0, branch to increment_r8
    b end_switch      // If not, branch to end_switch

check_r9_1:
    cmp r9, #1        // Compare R9 to 1
    beq increment_r8  // If R9 == 1, branch to increment_r8
    b end_switch      // If not, branch to end_switch

check_r9_2:
    cmp r9, #2        // Compare R9 to 2
    beq increment_r8  // If R9 == 2, branch to increment_r8
    b end_switch      // If not, branch to end_switch

check_r9_3:
    cmp r9, #3        // Compare R9 to 3
    beq increment_r8  // If R9 == 3, branch to increment_r8
    b end_switch      // If not, branch to end_switch

increment_r8:
    add r8, r8, #1    // Increment R8
    b mole_disappear  // Branch to mole_disappear

end_switch:
		BX LR
	
mole_disappear:
    // Make the mole disappear by clearing the corresponding 7-segment display
    PUSH {R0, R1, R3, LR}  // Save registers to stack
    LDR R5, =HEX_ADDR
    LDR R2, =NOTHING
    CMP R9, #0
    STREQB R2, [R5]

    CMP R9, #1
    STREQB R2, [R5, #1]

    CMP R9, #2
    STREQB R2, [R5, #2]

    CMP R9, #3
    STREQB R2, [R5, #3]

    // Calculate the new position for the mole
    ADD R9, R9, #1      // Move the mole to the next position
    CMP R9, #4          // Check if the mole is in position 4 (beyond the last display)
    MOVEQ R9, #0        // If yes, reset the mole position to 0

    // Make the mole appear in the new position
    LDR R3, =MOLE       // Load the mole pattern into R3
    ADD R1, R5, R9      // Calculate the address for the new position
    STRB R3, [R1]       // Store the mole pattern in the new position

    POP {R0, R1, R3, LR} // Restore registers from stack
    BX LR



update_timer:
	//decrement R3 (counter)
	// Display R3 on the hexes
	PUSH {LR}
	BL HEX_write_ASM
	POP {LR}
	//call clear
	PUSH {LR}
	BL ARM_TIM_clear_INT_ASM
	POP {LR}
	//b poll-timer
	SUB R7, R7, #1
	B poll_timer

	start_game:
	// Enable timer by setting the first bit of PT_CONTROL_ADDR register.
	// This starts the countdown.
	LDR R4, =PT_CONTROL_ADDR // Load the address of the PT_CONTROL_ADDR register into R4.
	LDR R0, [R4] // Load the current value of the PT_CONTROL_ADDR register into R0.
	ORR R0, R0, #1 // Set the first bit of R0 to 1 using the ORR (bitwise OR) instruction.
	STR R0, [R4] // Store the updated value of R0 back into the PT_CONTROL_ADDR register.
	MOV R11, #0
	B poll_timer // Branch back to poll_timer to continue monitoring button presses.

	stop_game:
	// Disable timer by clearing the first bit of PT_CONTROL_ADDR register.
	// This stops the countdown.
	LDR R4, =PT_CONTROL_ADDR // Load the address of the PT_CONTROL_ADDR register into R4.
	LDR R0, [R4] // Load the current value of the PT_CONTROL_ADDR register into R0.
	BIC R0, R0, #1 
	// Clear the first bit of R0 to 0 using the BIC (bitwise AND with complement) instruction.
	STR R0, [R4] // Store the updated value of R0 back into the PT_CONTROL_ADDR register.
	MOV R11, #1
	B poll_timer // Branch back to poll_timer to continue monitoring button presses.

reset_game:
    //Reset the timer count and display
    MOV R7, #30
    PUSH {LR}
    BL HEX_write_ASM
    POP {LR}
    B poll_timer

ARM_TIM_config_ASM:	
//R0 and R1 are passed into these registers. 
//R0 = countdown starting value; R1 = CRTL flags du timer (E sert a commencer ton timer)
	PUSH {R2, R3}
	LDR R2, =0xFFFEC600
	LDR R3, =0xFFFEC608
	
	STR R0, [R2]
	STR R1, [R3]
	POP {R2, R3}
	
	BX LR
	
ARM_TIM_read_INT_ASM: 
//This subroutine returns the “F” value (0x00000000 or 0x00000001) 
//from the ARM A9 private timer
//interrupt status register.
//Poll timer interrupt address
	PUSH {R2}
	LDR R2, =PT_INTERRUPT_ADDR
	LDR R0, [R2]
	POP {R2}
	
	BX LR
	
	
ARM_TIM_clear_INT_ASM: 
//This subroutine clears the “F” value in the ARM A9 
//private timer Interrupt status register
//The F bit can be cleared to 0 by writing a 0x00000001 to the interrupt status register.
//Reset timer by writing 1 into F 
	PUSH {R2}
	LDR R2, =PT_INTERRUPT_ADDR
	MOV R0, #0x00000001
	STR R0, [R2]
	POP {R2}
	
	BX LR

HEX_flood_ASM:
	LDR R4, =HEX_ADDR
	ADD R4, R4, #16
	STRB R2, [R4], #1
	
	STRB R3, [R4]
	
	BX LR


HEX_write_ASM:
	MOV R1, R7
	
	write30:
		CMP R1, #30
		BNE write29
		LDR R3, =THREE
		LDR R2, =ZERO
	write29:
		CMP R1, #29
		BNE write28
		LDR R3, =TWO
		LDR R2, =NINE
	write28:
		CMP R1, #28
		BNE write27
		LDR R3, =TWO
		LDR R2, =EIGHT
	write27:
		CMP R1, #27
		BNE write26
		LDR R3, =TWO
		LDR R2, =SEVEN
	write26:
		CMP R1, #26
		BNE write25
		LDR R3, =TWO
		LDR R2, =SIX
	write25:
		CMP R1, #25
		BNE write24
		LDR R3, =TWO
		LDR R2, =FIVE
	write24:
		CMP R1, #24
		BNE write23
		LDR R3, =TWO
		LDR R2, =FOUR
	write23:
		CMP R1, #23
		BNE write22
		LDR R3, =TWO
		LDR R2, =THREE
	write22:
		CMP R1, #22
		BNE write21
		LDR R3, =TWO
		LDR R2, =TWO
	write21:
		CMP R1, #21
		BNE write20
		LDR R3, =TWO
		LDR R2, =ONE
	write20:
		CMP R1, #20
		BNE write19
		LDR R3, =TWO
		LDR R2, =ZERO
	write19:
		CMP R1, #19
		BNE write18
		LDR R3, =ONE
		LDR R2, =NINE
	write18:
		CMP R1, #18
		BNE write17
		LDR R3, =ONE
		LDR R2, =EIGHT
	write17:
		CMP R1, #17
		BNE write16
		LDR R3, =ONE
		LDR R2, =SEVEN
	write16:
		CMP R1, #16
		BNE write15
		LDR R3, =ONE
		LDR R2, =SIX
	write15:
		CMP R1, #15
		BNE write14
		LDR R3, =ONE
		LDR R2, =FIVE
	write14:
		CMP R1, #14
		BNE write13
		LDR R3, =ONE
		LDR R2, =FOUR
	write13:
		CMP R1, #13
		BNE write12
		LDR R3, =ONE
		LDR R2, =THREE
	write12:
		CMP R1, #12
		BNE write11
		LDR R3, =ONE
		LDR R2, =TWO
	write11:
		CMP R1, #11
		BNE write10
		LDR R3, =ONE
		LDR R2, =ONE
	write10:
		CMP R1, #10
		BNE write9
		LDR R3, =ONE
		LDR R2, =ZERO
	write9:
		CMP R1, #9
		BNE write8
		LDR R3, =ZERO
		LDR R2, =NINE
	write8:
		CMP R1, #8
		BNE write7
		LDR R3, =ZERO
		LDR R2, =EIGHT
	write7:
		CMP R1, #7
		BNE write6
		LDR R3, =ZERO
		LDR R2, =SEVEN
	write6:
		CMP R1, #6
		BNE write5
		LDR R3, =ZERO
		LDR R2, =SIX
	write5:
		CMP R1, #5
		BNE write4
		LDR R3, =ZERO
		LDR R2, =FIVE
	write4:
		CMP R1, #4
		BNE write3
		LDR R3, =ZERO
		LDR R2, =FOUR
	write3:
		CMP R1, #3
		BNE write2
		LDR R3, =ZERO
		LDR R2, =THREE
	write2:
		CMP R1, #2
		BNE write1
		LDR R3, =ZERO
		LDR R2, =TWO
	write1:
		CMP R1, #1
		BNE write0
		LDR R3, =ZERO
		LDR R2, =ONE
	write0:
		CMP R1, #0
		BNE finish_display
		LDR R3, =ZERO
		LDR R2, =ZERO
		Push {LR}
		BL stop_game      // If timer is zero, call the display_score subroutine
		Pop {LR}
		Push {LR}
		BL display_score      // If timer is zero, call the display_score subroutine
		Pop {LR}
		
	finish_display:
		PUSH {LR}
		BL HEX_flood_ASM
		POP {LR}
		
		BX LR
		
display_score:
    PUSH {R0, R1, R2, R4, LR} // Save registers to stack

    LDR R5, =HEX_ADDR          // Load base address of the hex displays

    // Extract tens and ones digits from the score in R8
    MOV R1, R8
    LSR R1, R1, #4             // Shift right by 4 bits to get the tens digit
    AND R1, R1, #0xF           // Mask out any other bits
    MOV R2, R8
    AND R2, R2, #0xF           // Mask out the upper 4 bits to get the ones digit

    // Convert tens and ones digits to 7-segment display encoding
    LDR R4, =SEGMENT_TABLE
    LDRB R1, [R4, R1]          // Load the 7-segment encoding for the tens digit
    LDRB R2, [R4, R2]          // Load the 7-segment encoding for the ones digit

    // Display tens digit on hex 0
    STRB R1, [R5]

    // Display ones digit on hex 1
    STRB R2, [R5, #1]

    POP {R0, R1, R2, R4, LR}   // Restore registers from stack
    BX LR
