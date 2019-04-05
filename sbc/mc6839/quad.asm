* From Appendix A of "Motorola MC6839 Floating Point ROM" manual.
* 
* This appendix provides an application example usimg the MC6839
* Floating Point ROM. The program shown is one that finds the roots to
* quadratic equations using the classic formula:
* 
*                         -b +/- srt(b^2 - 4ac)
*                         ---------------------
*                                   2a
* 
* Note that the program uses a standard set of macro instructions to set
* up the parameters in the correct calling seuences. Perhaps the easiest
* way to program the MC6839 Floating Point ROM is through the use of
* these macro instructions. Errors are reduced because, once the macro
* instructions are shown to be correct, their internal details can be
* ignored allowing the programmer to concentrate on only the problem at
* hand.

  NAM QUAD
*
* HERE IS A SIMPLE EXAMPLE INVOLVING THE QUADRATIC EQUATION THAT
* SHOULD SERVE TO ILLUSTRATE THE USE OF THE MC6839 IN AN ACTUAL
* APPLICATION.
*
* LINKING LOADER DEFINITIONS
*
        XDEF    QUAD
*
        XREF    FPREG
*
* RMBS FOR THE OPERANDS, BINARY TO DECIMAL CONVERSION BUFFERS,
* AND THE FPCB.
*
ACOEFF  RMB     26              COEFFICIENT A IN AX^2 +BX +C
BCOEFF  RMB     26              COEFFICIENT B
CCOEFF  RMB     26              COEFFICIENT C
*
REG1    RMB     4               REGISTER 1
REG2    RMB     4               REGISTER 2
REG3    RMB     4               REGISTER 3
*
FPCB    RMB     4               FLOATING POINT CONTROL BLOCK
*
TWO     FCB     $40,00,00,00    FLOATING PT. CONSTANT TWO
FOUR    FCB     $40,$80,00,00   "        "   "        FOUR

*
*
* HERE ARE THE EQUATES AND MACRO DEFINITIONS TO ACCOMPANY THE
* QUADRATIC EQUATION EXAMPLE OF AN MC6839 APPLICATION.
*
ADD     EQU     0               OPCODE VALUES
SUB     EQU     02
MUL     EQU     04
DIV     EQU     06
SQRT    EQU     $12
ABS     EQU     $1E
NEQ     EQU     $20
BNDC    EQU     $1C
DCBN    EQU     $22
*
*
* MACRO DEFINITIONS
*
* HERE ARE THE CALLING SEQUENCE MACROS
*
MCALL   MACR
*
*  MCALL SETS UP A MONADIC REGISTER CALL.
*
*  USAGE: MCALL <INPUT OPERAND>,<OPERATION>,<RESULT>
*
        LEAY    \U,PCR          POINTER TO THE INPUT ARGUMENT
        LEAX    FPCB,PCR        POINTER TO THE FLOATING POINT CONTROL BLOCK
        TFR     X,D
        LEAX    \2,PCR          POINTER TO THE RESULT
        LBSR    FPREG           CALL TO THE MC6839
        FCB     \1              OPCODE
*
        ENDM
*
*
DCALL   MACR
*
*  DCALL SETS UP A DYADIC REGISTER CALL
*
*  USAGE: DCALL <ARGUMENT #1>,<OPERATION>,<ARGUMENT #2>,<RESULT>
*
        LEAU    \0,PCR          POINTER TO ARGUMENT #1
        LEAY    \2,PCR          POINTER TO ARGUMENT #1
        LEAX    FPCB,PCR        POINTER TO THE FLOATING POINT CONTROL BLOCK
        TFR     X,D
        LEAX    \3,PCR          POINTER TO THE RESULT
        LBSR    FPREG           CALL TO THE MC6839
        FCB     \1              OPCODE
*
        ENDM
*
*
DECBIN  MACR
*
* DECBIN SETS UP A REGISTER CALL TO THE DECIMAL TO BINARY CONVERSION FUNCTION.
*
* USAGE: DECBIN  <BCD STRING>,<BINARY RESULT>
*
        LEAU    \0,PCR          POINTER TO THE BCD INPUT STRING
        LEAX    FPCB,PCR        POINTER TO THE FLOATING POINT CONTROL BLOCK
        TFR     X,D
        LEAX    \1,PCR          POINTER TO THE RESULT
        LBSR    FPREG           CALL TO THE MC6839
        FCB     DCBN            OPCODE
*
        ENDM
*
*
BINDEC  MACRO
*
* BINDEC SETS UP A REGISTER CALL TO THE BINARY TO DECIMAL CONVERSION FUNCTION.
*
* USAGE: BINDEC <BINARY INPUT>,<BCD RESULT>,<# OF SIGNIFICANT DIGITS RESULT>
*
        LDU     \2              # OF SIGNIFICANT DIGITS IN THE RESULT
        LEAY    \0,PCR          POINTER TO THE BINARY INPUT
        LEAX    FPCB,PCR        POINTER TO THE FLOATING POINT CONTROL BLOCK
        TFR     X,D
        LEAX    \1,PCR          POINTER TO THE BCD RESULT
        LBSR    FPREG           CALL TO THE MC6839
        FCB     BNDC            OPCODE
*
        ENDM
*
*
QUAD    EQU     *
*
        LDX     #$6FFF          INITIALIZE THE STACK POINTER
*
        LEAX    FPCB,PCR
        LDB     #4
        WHILE   B,GT,#0         INITIALIZE STACK FRAME TO
        DECB                    SINGLE, ROUND NEAREST.
        CLR     B,X
*
        ENDWH
*
* CONVERT THE INPUT OPERANDS FROM BCD STRINGS TO THE INTERNAL
* SINGLE BINARY FORM.
*
        DECBIN  ACOEFF,ACOEFF
        DECBIN  BCOEFF,BCOEFF
        DECBIN  CCOEFF,CCOEFF
*
* NOW START THE ACTUAL CALCULATIONS FOR THE QUADRATIC EQUATION
*
        DCALL   BCOEFF,MUL,BCOEFF,REG1  CALCULATE B^2
        DCALL   ACOEFF,MUL,CCOEFF,REG2  CALCULATE AC
        DCALL   REG2,MUL,FOUR,REG2      CALCULATE 4AC
        DCALL   REG1,SUB,REG2,REG1      CALCULATE B^2 - 4AC
*
* CHECK RESULT OF B^2 - 4AC TO SEE IF ROOTS ARE REAL OR IMAGINARY
*
        LDA     REG1,PCR
        IFCC    GE                    SIGN IS POSITIVE; ROOTS REAL
        MCALL   REG1,SQRT,REG1        CALCULATE SQRT(B^2 - 4AC)
        DCALL   ACOEFF,MUL,TWO,REG2   CALCULATE 2A
        MCALL   BCOEFF,NEG,BCOEFF     NEGATE B
*
        DCALL   BCOEFF,ADD,REG1,REG3  CALCULATE -B + SQRT( B^2 - 4AC )
        DCALL   REG3,DIV,REG2,REG3    CALCULATE (-N + SQRT( B^2 - 4AC ))/2A
        BINDEC  REG3,ACOEFF,#5        CONVERT RESULT TO DECIMAL
*
        DCALL   BCOEFF,SUB,REG1,REG3  CALCULATE  -B - SQRT( B^2 -4AC )
        DCALL   REG3,DIV,REG2,REG3    CALCULATE  (-B + SQRT( B^2 - 4AC ))/2A
        BINDEC  REG3,BCOEFF,#5        CONVERT RESULT TO DECIMAL
*
        LDA     #$FF                   SENTINAL SIGNALING THAT ROOTS ARE REAL
        STA     CCOEFF,PCR
*
        MCALL   REG1,ABS,REG1         MAKE SIGN POSITIVE
        MCALL   REG1,SQRT,REG1        CALCULATE  SQRT( B^2 - 4AC )
        DCALL   ACOEFF,MUL,TWO,REG2   CALCULATE 2A
        DCALL   REG1,DIV,REG2,REG1    CALCULATE ( SQRT( B^2  - 4AC ))/2A
*
        DCALL   BCOEFF,DIV,REG2,REG2  CALCULATE -B/2A
        MCALL   REG2,NEG,REG2
*
        BINDEC  REG1,BCOEFF,#5        CONVERT  -B/2A TO DECIMAL
        BINDEC  REG2,ACOEFF,#5        CONVERT  ( SQRT( B^2  - 4AC ))/2A
*
        CLR     CCOEFF,PCR            SENTINAL SIGNALLING IMAGINARY ROOTS
*
        ENDIF
*
*
       NOP
       NOP