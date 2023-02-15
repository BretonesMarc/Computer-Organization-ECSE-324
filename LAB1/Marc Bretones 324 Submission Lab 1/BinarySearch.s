.global _start
// Marc Bretones for ECSE 324

_start:
	LDR R12,=array
	MOV R1,#4
	MOV R2,#0
	MOV R3, #7
	BL binarySearch

end:
	MOV R0, R10//Returns the index value. For the actual value found --> LDR R0, [R12, R10, LSL #2]
	POP {R4-R11}
	B endfr
	
endfr:
	B endfr

	
binarySearch:
	PUSH {R4-R11}
	while:
		low_GE_high:
			CMP R2, R3
			BLT low_LT_high
			x_EQ_array_lowidx:
				LDR R4, [R12, R3, LSL #2]
				CMP R1, R4
				BNE x_NE_array_lowidx
				MOV R10, R2
				B end
				
			x_NE_array_lowidx:
				MOV R10, #-1
				B end

		low_LT_high: // find the index in the middle of low and high indices
			ADD R5, R2, R3
			MOV R5, R5, ASR#1 //R5 --> mid = (lowIdx + highIdx)/2
			
			x_EQ_array_mid: //if (x == array[mid])
				LDR R8, [R12, R5, LSL #2]
				CMP R1, R8
				BNE x_NE_array_mid
				MOV R10, R5
				B end
			x_NE_array_mid:
				CMP R1, R8
				BLT x_LT_array_mid
				//if (x > array[mid])
				x_GT_array_mid:
					ADD R2, R5, #1
					B while
				
				x_LT_array_mid: //else
					SUBS R3, R5, #1
					B while
	
	BX LR
	
.data
array: 
	.word 1, 2, 3, 4, 5, 6, 7, 8