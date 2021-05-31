;;;;;;; P3 Template;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Modified By: Anthony Ramos
;;;;;;; INTERRUPTS LAB ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        list  P=PIC18F4520, F=INHX32, C=160, N=0, ST=OFF, MM=OFF, R=DEC, X=ON
        #include <P18F4520.inc>
        __CONFIG  _CONFIG1H, _OSC_HS_1H  ;HS oscillator
        __CONFIG  _CONFIG2L, _PWRT_ON_2L & _BOREN_ON_2L & _BORV_2_2L  ;Reset
        __CONFIG  _CONFIG2H, _WDT_OFF_2H  ;Watchdog timer disabled
        __CONFIG  _CONFIG3H, _CCP2MX_PORTC_3H  ;CCP2 to RC1 (rather than to RB3)
        __CONFIG  _CONFIG4L, _LVP_OFF_4L & _XINST_OFF_4L  ;RB5 enabled for I/O
        errorlevel -314, -315          ;Ignore lfsr messages

;;;;;;; Variables ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        cblock  0x000                  ;Beginning of Access RAM
        TMR0LCOPY                      ;Copy of sixteen-bit Timer0 used by LoopTime
        TMR0HCOPY
        INTCONCOPY                     ;Copy of INTCON for LoopTime subroutine

		WREG_TEMP
		STATUS_TEMP

		TIMECOUNT
        endc

;;;;;;; Macro definitions ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MOVLF   macro  literal,dest
        movlw  literal
        movwf  dest
        endm

;;;;;;; Vectors ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        org  0x0000                    ;Reset vector
        nop
        goto  Mainline

        org  0x0008                    ;High priority interrupt vector
		goto HPISR                     ;execute High Priority Interrupt Service Routine


        org  0x0018                    ;Low priority interrupt vector
        goto LPISR                    ;execute Low Priority Interrupt Service Routine

;;;;;;; Mainline program ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Mainline
        rcall  Initial                 ;Initialize everything
        
L1
         btg  PORTC,RC2               ;Toggle pin, to support measuring loop time
         rcall  LoopTime              ;Looptime is set to 0.1ms delay
         bra	L1


;;;;;;; Initial subroutine ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Initial
	
        MOVLF  B'10001110',ADCON1      ;Enable PORTA & PORTE digital I/O pins
        MOVLF  B'11100001',TRISA       ;Set I/O for PORTA
        MOVLF  B'11011111',TRISB       ;Set I/O for PORTB
		MOVLF  B'11010000',TRISC       ;Set I/O for PORTC
        MOVLF  B'00001111',TRISD       ;Set I/O for PORTD
        MOVLF  B'00000100',TRISE       ;Set I/O for PORTE
        MOVLF  B'10001000',T0CON       ;Set up Timer0 for a looptime of 10 ms
        MOVLF  B'00010000',PORTA       ;Turn off all four LEDs driven from PORTA
		MOVLF  B'11111111',TMR0H       ;DO NOT MODIFY!!!
        MOVLF  B'00000000',TMR0L       ;DO NOT MODIFY!!!
		bcf PORTC,RC1                  ;DO NOT MODIFY!!!


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;Write your code here for the following tasks		
	; Enable and set up interrupts
	; Initialize appropriate priority bits
	; Clear appropriate interrupt flags

	; Global interrupt setup 
	bsf RCON, IPEN ; Intialize two-level interrupt priority
	bsf INTCON, GIEH ; Enable High Priority Interrupts
	bsf INTCON, GIEL ; Enable Low Priority Interrupts	
	bsf INTCON, RBIE ; Enable the RB port change interrupt 
    ; INT0/RB0 (HPI Setup)
	bcf INTCON, INT0IF ; Clear INT0 Flag bit
	bsf	INTCON, INT0IE ; Enable INT0 external interrupt
	; INT1/RB1 (LPI Setup)
	bcf INTCON3, INT1IF	; Clear INT1 Flag bit
	bsf	INTCON3, INT1IE ; Enable INT1 external interrupt 
	bcf INTCON3, INT1IP ; Clear INT1 priority bit (i.e set Low priority)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
return




;;;;;;; LoopTime subroutine ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;; DO NOT MODIFY	    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Bignum  equ     65536-250+12+2
LoopTime
		btfss INTCON,TMR0IF            ;Wait for rollover
        bra	LoopTime
		movff  INTCON,INTCONCOPY       ;Disable all interrupts to CPU
        bcf  INTCON,GIEH
        movff  TMR0L,TMR0LCOPY         ;Read 16-bit counter at this moment
        movff  TMR0H,TMR0HCOPY
        movlw  low  Bignum
        addwf  TMR0LCOPY,F
        movlw  high  Bignum
        addwfc  TMR0HCOPY,F
        movff  TMR0HCOPY,TMR0H
        movff  TMR0LCOPY,TMR0L         ;Write 16-bit counter at this moment
        movf  INTCONCOPY,W             ;Restore GIEH interrupt enable bit
        andlw  B'10000000'
        iorwf  INTCON,F
        bcf  INTCON,TMR0IF             ;Clear Timer0 flag
        return


;;;;;;; LPISR ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
LPISR
	movff STATUS, STATUS_TEMP          ;save STATUS and W
	movf W,WREG_TEMP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;Write your code here for the following tasks
	bcf PORTC, RC2 ; Clear pulse train from Mainline
	; Initiate counting bits 
	; You MUST do this using a separate SUBROUTINE,
	; and inside that subroutine you may create
	; yet another subroutine which counts LoopTime (0.1ms)
	; Clear all counting bits from LPISR
	rcall PulseTrainGen
	bcf INTCON3, INT1IF; Clear LP Interrupt FLAG
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



	movf WREG_TEMP,W					; restore STATUS and W
	movff STATUS_TEMP,STATUS
retfie


;;;;;;; HPISR ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
HPISR
	bsf PORTC,RC1;Set Signal that we are entering HPISR - DO NOT MODIFY!!
	


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;Write your code here for the following tasks
	bcf PORTC, RC2	;Clear pulse train from RC2
	;Clear all counting bits from LPISR
	bcf PORTA, RA1
	bcf PORTA, RA2
	bcf PORTA, RA3	
	; Loop to check for human input
Loop
	btfss PORTE,RE2 ; Check if Human Input Signal (HIS) is 1 (If so, skip next instruction)
	bra Loop

		
	
	bcf INTCON3, INT1IF	; Clear LP Interrupt FLAG
	bcf INTCON, INT0IF	; Clear HP Interrupt FLAG
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;





	bcf PORTC,RC1;Set Signal that we are Leaving HPISR -  DO NOT MODIFY!!	
					  	
	MOVLF  B'11111111',TMR0H ;DO NOT MODIFY
	MOVLF  B'00000000',TMR0L ;DO NOT MODIFY

retfie FAST

PulseTrainGen
	bsf PORTA,RA3 ;ON
	bsf PORTA,RA2 ;ON
	bsf PORTA,RA1 ;ON
	rcall LoopTime ;0.1ms delay
	rcall LoopTime ;0.1ms delay
	bsf PORTA,RA3 ;ON
	bsf PORTA,RA2 ;ON
	bcf PORTA,RA1 ;OFF
	rcall LoopTime ;0.1ms delay
	rcall LoopTime ;0.1ms delay
	bsf PORTA,RA3 ;ON
	bcf PORTA,RA2 ;OFF
	bsf PORTA,RA1 ;ON
	rcall LoopTime ;0.1ms delay
	rcall LoopTime ;0.1ms delay
	bsf PORTA,RA3 ;ON
	bcf PORTA,RA2 ;OFF
	bcf PORTA,RA1 ;OFF
	rcall LoopTime ;0.1ms delay
	rcall LoopTime ;0.1ms delay
	bcf PORTA,RA3 ;OFF
	bsf PORTA,RA2 ;ON
	bsf PORTA,RA1 ;ON
	rcall LoopTime ;0.1ms delay
	rcall LoopTime ;0.1ms delay
	bcf PORTA,RA3 ;OFF
	bsf PORTA,RA2 ;ON
	bcf PORTA,RA1 ;OFF
	rcall LoopTime ;0.1ms delay
	rcall LoopTime ;0.1ms delay
	bcf PORTA,RA3 ;OFF
	bcf PORTA,RA2 ;OFF
	bsf PORTA,RA1 ;ON
	rcall LoopTime ;0.1ms delay
	rcall LoopTime ;0.1ms delay
	bcf PORTA,RA3 ;OFF
	bcf PORTA,RA2 ;OFF
	bcf PORTA,RA1 ;OFF
	rcall LoopTime ;0.1ms delay
	rcall LoopTime ;0.1ms delay

	return

end
