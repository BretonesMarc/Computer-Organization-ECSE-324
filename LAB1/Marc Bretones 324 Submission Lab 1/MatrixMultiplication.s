//INITIALIZING EVERYTHING
.global _start
//MArc Bretones for ECSE 324

size: .word 2
_start:
    LDR R0, =a
    LDR R1, =b
    LDR R2, =c
    LDR R3, size
    BL mm
//END OF START

//FINISHING THE EXECUTION//
end:
    B end
finishmm:
    POP {R4-R12}
    BX LR
//END OF CODE
 
//MATRIX MULTIPLICATION
mm:
    PUSH {R4-R12}
    MOV R4, #0
    rowloop:
        
        CMP R4, R3
        BGE finishmm
        MOV R6, #0

        colloop:

            CMP R6, R3
            ADDGE R4, R4, #1
            BGE rowloop
            MUL R10, R4, R3
            ADD R12, R10, R6
            ADD R12, R12, R12
            ADD R12, R12, R2
            MOV R9, #0
            STRH R9, [R12]

            MOV R8, #0
            iterloop:

                CMP R8, R3
                ADDGE R6, R6, #1
                BGE colloop
                MUL R7, R8, R3
                ADD R7, R7, R6
                ADD R7, R7, R7
                ADD R7, R7, R1
                LDRSH R7, [R7]
                MUL R12, R4, R3
                ADD R10, R12, R8
                ADD R10, R10, R10
                ADD R10, R10, R0
                LDRSH R10, [R10]
                MUL R7, R7, R10
                ADD R12, R12, R6
                ADD R12, R12, R12
                ADD R5, R2, R12
                LDRSH R10, [R5]
                ADD R10, R10, R7
                STRH R10, [R5]
                ADD R8, R8, #1
                B iterloop
//END OF MATRIX MULTIPLICATION (excluding mmfinish)

//STORAGE OF MATRICES//
.data
a:
    .hword -1, 2, 3, -4
b:
    .hword 6, -3, 2, 4
c:
    .hword 0, 0, 0, 0
//END OF STORAGE OF MATRIX DATA//
