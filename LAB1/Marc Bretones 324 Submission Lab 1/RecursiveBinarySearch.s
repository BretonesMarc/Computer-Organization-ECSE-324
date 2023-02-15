.global _start

_start:
	LDR R12,=array
	MOV R1,#6
	MOV R2,#0
	MOV R3, #7
	BL binarySearch

end:
	MOV R0, R10
	B endfr

endfr:
	B endfr

binarySearch:
	CMP R2, R3
	BLT low_LT_high

	x_EQ_array_lowidx:
		LDR R4, [R12, R3, LSL #2]
		CMP R1, R4
		BNE x_NE_array_lowidx
		MOV R10, R3
		B end

	x_NE_array_lowidx:
		MOV R10, #-1
		B end

	low_LT_high:
		ADD R5, R2, R3
		MOV R5, R5, ASR#1

	x_EQ_array_mid:
		LDR R8, [R12, R5, LSL #2]
		CMP R1, R8
		BNE x_NE_array_mid
		MOV R10, R5
		B end

	x_NE_array_mid:
		CMP R1, R8
		BLT x_LT_array_mid

	x_GT_array_mid:
		ADD R2, R5, #1
		BL binarySearch
		B end

	x_LT_array_mid:
		SUB R3, R5, #1
		BL binarySearch
		B end

.data
array:
.word 1, 2, 3, 4, 5, 6, 7, 8