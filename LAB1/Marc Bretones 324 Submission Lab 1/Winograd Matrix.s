.global _start
// Marc Bretones for ECSE 324

_start:
	LDR R0,=a
	LDR R1,=b
	LDR R2,=c
	
	BL wmm22

end:
	B end
	
wmm22:
	PUSH {R4-R12}
	
	//int16_t u = (cc - aa)*(CC - DD);
	LDRSH R4, [R0, #4]    //cc
	LDRSH R5, [R0]        //aa
	SUBS R6, R4, R5       //cc-aa
	LDRSH R7, [R1, #2]    //CC
	LDRSH R8, [R1, #6]    //DD
	SUBS R9, R7, R8       //CC-DD
	MUL R10, R9, R6       //R10 --> u=(cc - aa)*(CC - DD)
	
	//int16_t v = (cc + dd)*(CC - AA);
	LDRSH R5, [R0, #6]     //dd
	ADD R6, R4, R5        //cc+dd
	LDRSH R8, [R1]         //AA
	SUBS R9, R7, R8        //CC-AA
	MUL R11, R9, R6       //R11 --> v = (cc + dd)*(CC - AA)
	
	//int16_t w = aa*AA + (cc + dd - aa)*(AA + DD - CC);
	LDRSH R4, [R0]        //aa
	LDRSH R5, [R1]        //AA
	MUL R4, R4, R5        //aa*AA
	LDRSH R5, [R0, #4]    //cc
	LDRSH R6, [R0, #6]    //dd
	LDRSH R7, [R0]        //aa
	ADD R5, R5, R6        
	SUBS R5, R5, R7       //(cc + dd - aa)
	LDRSH R6, [R1]        //AA
	LDRSH R7, [R1, #6]    //DD
	LDRSH R8, [R1, #2]    //CC
	ADD R6, R6, R7
	SUBS R6, R6, R8       //(AA + DD - CC)
	MLA R12, R5, R6, R4    //R12 --> w = aa*AA + (cc + dd - aa)*(AA + DD - CC)
	
	//*c = aa*AA + bb*BB;
	LDRSH R4, [R0]        //aa
	LDRSH R5, [R1]        //AA
	MUL R4, R4, R5        //aa*AA
	LDRSH R5, [R0, #2]    //bb
	LDRSH R6, [R1, #4]    //BB
	MUL R5, R5, R6        //bb*BB
	ADD R4, R4, R5        //aa*AA + bb*BB
	STRH R4, [R2]         //Store into c (1st slot)
	
	//*(c + 0*2 + 1) = w + v + (aa + bb - cc - dd)*DD;
	LDRSH R4, [R0]        //aa
	LDRSH R5, [R0, #2]    //bb
	ADD R4, R4, R5        //aa+bb
	LDRSH R5, [R0, #4]    //cc
	SUBS R4, R4, R5       //aa+bb-cc
	LDRSH R5, [R0, #6]    //dd
	SUBS R4, R4, R5       //aa+bb-cc-dd
	LDRSH R5, [R1, #6]    //DD
	MUL R4, R4, R5        //(aa + bb - cc - dd)*DD
	ADD R4, R4, R11       //v+(aa + bb - cc - dd)*DD
	ADD R4, R4, R12       //w+v+(aa + bb - cc - dd)*DD
	STRH R4, [R2, #2]     //Store into c (2nd slot)
	
	//*(c + 1*2 + 0) = w + u + dd*(BB + CC - AA - DD);
	LDRSH R4, [R1, #4]        //BB
	LDRSH R5, [R1, #2]        //CC
	ADD R4, R4, R5            //BB+CC
	LDRSH R5, [R1]            //AA
	SUBS R4, R4, R5           //BB+CC-AA
	LDRSH R5, [R1, #6]        //DD
	SUBS R4, R4, R5           //BB+CC-AA-DD
	LDRSH R5, [R0, #6]        //DD
	MLA R4, R4, R5, R10       //u + dd*(BB + CC - AA - DD)
	ADD R4, R4, R12           //w + u + dd*(BB + CC - AA - DD)
	STRH R4, [R2, #4]         //Store into c (3rd slot)
	
	//*(c + 1*2 + 1) = w + u + v;
	ADD R4, R10, R11
	ADD R4, R4, R12
	STRH R4, [R2, #6]
	
	POP {R4-R12}
	BX LR

	
.data
a: 
	.hword -1, 2, 3, -4
b: 
	.hword 6, -3, 2, 4
c: 
	.hword 0, 0, 0, 0