;*********************************************************************
;TOTAL          		: TEMPERATURE ALARM FOR COVID 19 SITUATION USING LM35
;**********************************************************************
;       P0.0    =       ADC D0
;       P0.1    =       ADC D1
;       P0.2    =       ADC D2
;       P0.3    =       ADC D3
;       P0.4    =       ADC D4
;       P0.5    =       ADC D5
;       P0.6    =       ADC D6
;       P0.7    =       ADC D7
;
;       P1.0    =       LCD D0
;       P1.1    =       LCD D1
;       P1.2    =       LCD D2
;       P1.3    =       LCD D3
;       P1.4    =       LCD D4
;       P1.5    =       LCD D5
;       P1.6    =       LCD D6
;       P1.7    =       LCD D7
;
;       P2.0    =       ADC A
;       P2.1    =		ADC B
;       P2.2    =		ADC C
;       P2.3    =		OUTPUT LED
;       P2.4    =       ALE
;       P2.5    =       OE
;       P2.6    =       SOC
;       P2.7    =		EOC
;
;       P3.0    =       
;       P3.1    =       
;       P3.2    =       LCD RS
;       P3.3    =       LCD R/W
;       P3.4    =       LCD E
;       P3.5    =
;       P3.6    =       SANITIZER
;       P3.7    =       BARRIGATE
;
;		53H		=		TEMPERATURE SET POINT
;Program starts here

        ORG     0000H     		;START
		LCALL	INIALIZE_SYSTEM
REPEAT:	LCALL   ADC_INTERFACING
        LCALL   TEMP_DISPLAY
        LCALL   TAKE_ACTION
     	SJMP 	REPEAT
;--------------------------------------------------------------------------
;--------------------------------------------------------------------------
INIALIZE_SYSTEM:
		CLR		P2.3			;LED OFF
		CLR		P3.6			;SANITIZER OFF
		CLR		P3.7			;BARRIGATE CLOSED
        MOV		A,#38H			;INITIALIZE LCD 38 - 16 x 2 LCD and 8 bit mode (byte mode)
		LCALL	COMMAND
		MOV		A,#0EH			;0E - Screen on cursor ON
		LCALL	COMMAND
		MOV		A,#06H			;06 - Shift cursor Right
		LCALL	COMMAND
		MOV		A,#01H			;01 - clear LCD
		LCALL	COMMAND
        MOV     53H,#37H		;SET TEMP SETPOINT
        MOV     73H,#00H		;

        MOV		A,#082H			;INITIALIZE LCD 80H - select 1st line - 82 1st line 3rd location
		LCALL	COMMAND
	
		MOV		A,#'T'
		LCALL	DISPLAY
		MOV		A,#'E'
		LCALL	DISPLAY
		MOV		A,#'M'
		LCALL	DISPLAY
		MOV		A,#'P'
		LCALL	DISPLAY
		MOV		A,#' '
		LCALL	DISPLAY
		MOV		A,#'='
		LCALL	DISPLAY
		MOV		A,#' '
		LCALL	DISPLAY
		CLR		P2.0			;SELECT ADC CHANNAL 0
		CLR		P2.1
		CLR		P2.2
		RET
;--------------------------------------------------------------------------
ADC_INTERFACING:
        LCALL   SEND_SOC
        LCALL   CHECK_EOC
        LCALL   READ_OUTPUT_OF_ADC
        LCALL   HEX2BCD
        MOV     73H,A
        RET
;--------------------------------------------------------------------------
SEND_SOC:	
        SETB    P2.4 	;soc = 1
        SETB    P2.6	;ale = 1
        LCALL   DELAY	;DELAY
        CLR     P2.4	;SOC =0
		CLR     P2.6	;ALE = 0	
		RET
;--------------------------------------------------------------------------
CHECK_EOC:
        JB      P2.7,RETURN ;JUMP IF EOC = 1
        SJMP    CHECK_EOC
RETURN: RET 
;--------------------------------------------------------------------------
READ_OUTPUT_OF_ADC:
        MOV     A,P0
        RET              
;--------------------------------------------------------------------------
HEX2BCD:	
        MOV     40H,A                   ;SAVE THE HEX TEMPERATURE AT 40H LOCATION
        CJNE    A,#1DH,CHECK_30H
        MOV     A,#29H
        SJMP    RETURN_RE
CHECK_30H:
        CJNE    A,#1EH,CHECK_31H
        MOV     A,#30H
        SJMP    RETURN_RE
CHECK_31H:
        CJNE    A,#1FH,CHECK_32H
        MOV     A,#31H
        SJMP    RETURN_RE
CHECK_32H:
        CJNE    A,#20H,CHECK_33H
        MOV     A,#32H
        SJMP    RETURN_RE
CHECK_33H:
        CJNE    A,#21H,CHECK_34H
        MOV     A,#33H
        SJMP    RETURN_RE
CHECK_34H:
        CJNE    A,#22H,CHECK_35H
        MOV     A,#34H
        SJMP    RETURN_RE
CHECK_35H:
        ANL     A,#0F0H         		;LOWER NIBBLE IS MASKED
        SWAP    A                       ;SWAP THE NOBBLE
        MOV     R3,A                    ;R3 IS COUNTER
        CLR     A                       ;A = 00H
UP123:	ADD		A,#16H					;ADD 16 IN A
        DA      A                       ;CONVETRT IT INTO BCD
        DJNZ    R3,UP123                ;DO ADDITION UNTILL R3 = 0       
        MOV     R3,A                    ;SAVE THE RESULT OF MULTIPLICATION INTO R3
 
        MOV     A,40H                   ;TAKE THE NUMBER FROM 40H INTO A
        ANL     A,#0FH     			    ;MASK THE MSB
        ADD     A,R3                    ;DO ADDITION OF R3 AND LSB
        DA      A                       ;CONVERT IT INTO BCD
RETURN_RE:
        MOV     40H,A                   ;SAVE THE BCD TEMPERATURE AT 40H LOCATION
        RET
;--------------------------------------------------------------------------
BCD2ASCII:;								Converting from BCD to ASCII
		MOV     R3,A
        ANL     A,#0F0H
        SWAP    A
        LCALL   CONVERT_IT
        MOV     R4,A
        MOV     A,R3
        ANL     A,#0FH
        LCALL   CONVERT_IT
        MOV     R3,A
        RET
;--------------------------------------------------------------------------
CONVERT_IT:ORL     A,#30H
        RET
;--------------------------------------------------------------------------
TEMP_DISPLAY:   MOV     A,#089H         ;STARTING ADDRESS OF LINE 1 OF LCD RAM
                ACALL   COMMAND
                MOV     A,73H
                LCALL   BCD2ASCII
                MOV     A,R4
                LCALL   DISPLAY
                MOV     A,R3
                LCALL   DISPLAY
                MOV     A,#0DFH
                LCALL   DISPLAY
                MOV     A,#'C'
                LCALL   DISPLAY
                MOV     A,#'.'
                LCALL   DISPLAY
                RET
;-----------------------------------------------------------------------------
TAKE_ACTION:
        MOV     A,73H
        CJNE    A,53H,NEXT_LOWER
T_HIGH: SETB    P2.3
		SETB	P3.6			;SANITIZER ON
		LCALL	DISPLAY_DO_TEST
		LCALL	DELAY
		LCALL	DELAY
		LCALL	DELAY
		LCALL	DELAY
		LCALL	DELAY
		CLR		P3.6			;SANITIZER OFF
		RET
NEXT_LOWER:
		JNC		T_HIGH
        CLR     P2.3
		SETB	P3.6			;SANITIZER ON
		SETB	P3.7			;BARRIGATE OPEN
		LCALL	DISPLAY_NORMAL
		LCALL	DELAY
		LCALL	DELAY
		LCALL	DELAY
		LCALL	DELAY
		CLR		P3.6			;SANITIZER OFF
		LCALL	DELAY
		LCALL	DELAY
		LCALL	DELAY
		LCALL	DELAY
		CLR		P3.7			;BARRIGATE CLOSED
		RET
;--------------------------------------------------------------------------
		
DISPLAY_DO_TEST:
		MOV		A,#0C0H			;INITIALIZE LCD C0H - select 2ND line - "TEST FOR COVID19"
		LCALL	COMMAND
	
		MOV		A,#'T'
		LCALL	DISPLAY
		MOV		A,#'E'
		LCALL	DISPLAY
		MOV		A,#'S'
		LCALL	DISPLAY
		MOV		A,#'T'
		LCALL	DISPLAY
		MOV		A,#' '
		LCALL	DISPLAY
		MOV		A,#'F'
		LCALL	DISPLAY
		MOV		A,#'O'
		LCALL	DISPLAY
		MOV		A,#'R'
		LCALL	DISPLAY
		MOV		A,#20H
		LCALL	DISPLAY
		MOV		A,#'C'
		LCALL	DISPLAY
		MOV		A,#'0'
		LCALL	DISPLAY
		MOV		A,#'V'
		LCALL	DISPLAY
		MOV		A,#'I'
		LCALL	DISPLAY
		MOV		A,#'D'
		LCALL	DISPLAY
		MOV		A,#'1'
		LCALL	DISPLAY
		MOV		A,#'9'
		LCALL	DISPLAY
		RET
;--------------------------------------------------------------------------
DISPLAY_NORMAL:
		MOV		A,#0C0H			;INITIALIZE LCD C0H - select 2ND line - " "YOU ARE SAFE ""
		LCALL	COMMAND
	
		MOV		A,#20H
		LCALL	DISPLAY
		MOV		A,#'"'
		LCALL	DISPLAY
		MOV		A,#'Y'
		LCALL	DISPLAY
		MOV		A,#'O'
		LCALL	DISPLAY
		MOV		A,#'U'
		LCALL	DISPLAY
		MOV		A,#' '
		LCALL	DISPLAY
		MOV		A,#'A'
		LCALL	DISPLAY
		MOV		A,#'R'
		LCALL	DISPLAY
		MOV		A,#'E'
		LCALL	DISPLAY
		MOV		A,#' '
		LCALL	DISPLAY
		MOV		A,#'S'
		LCALL	DISPLAY
		MOV		A,#'A'
		LCALL	DISPLAY
		MOV		A,#'F'
		LCALL	DISPLAY
		MOV		A,#'E'
		LCALL	DISPLAY
		MOV		A,#'"'
		LCALL	DISPLAY
		MOV		A,#' '
		LCALL	DISPLAY
		RET

		
;--------------------------------------------------------------------------
         DELAY: MOV     R7,#0FFH;   Delay loop
         LOOP1: MOV     R6,#0FFH
          LOOP: DJNZ    R6,LOOP
                DJNZ    R7,LOOP1
                RET
;-----------------------------------------------------------------------------
;LCD Strobe Command
       COMMAND: ACALL 	DELAY
                MOV 	P1,A        ;Command Character in Port P1
                CLR 	P3.2        ;Command resister chosen
                CLR 	P3.3        ; write enable
                SETB 	P3.4        ; Strobe Character to display
                CLR 	P3.4
                RET        		     ;Return
;-----------------------------------------------------------------------------
       DISPLAY: ACALL 	DELAY
                MOV 	P1,A       ;take data to be displayed
                SETB 	P3.2       ;RS=P3.2= 1 to select data register
                CLR 	P3.3       ;write enable
                SETB 	P3.4       ;strobe character to be displayed
                CLR 	P3.4
                RET            		; Return
;-----------------------------------------------------------------------------
				END