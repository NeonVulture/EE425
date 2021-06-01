;;;;;;; P5 for QwikFlash board ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Use this template for Experiment 6
;
;;;;;;; Assembler directives ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

         list  P=PIC18F4520, F=INHX32, C=160, N=0, ST=OFF, MM=OFF, R=DEC, X=ON
        #include <P18F4520.inc>
        __CONFIG  _CONFIG1H, _OSC_HS_1H  ;HS oscillator
        __CONFIG  _CONFIG2L, _PWRT_ON_2L & _BOREN_ON_2L & _BORV_2_2L  ;Reset
        __CONFIG  _CONFIG2H, _WDT_OFF_2H  ;Watchdog timer disabled
        __CONFIG  _CONFIG3H, _CCP2MX_PORTC_3H  ;CCP2 to RC1 (rather than to RB3)
        __CONFIG  _CONFIG4L, _LVP_OFF_4L & _XINST_OFF_4L  ;RB5 enabled for I/O
        errorlevel -314, -315          ;Ignore lfsr messages


;;;;;;; Variables ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        cblock  0x000           ;Beginning of Access RAM
		; --- BEGIN variables for TABLAT POINTER
		; DO NOT MODIFY 
		counter
		; --- END variables for TABLAT POINTER

		; Create your variables starting from here

		valueH
		xn
		xn1
		xn2
		xn3
		SUM1U
		SUM1L
		SUM2U
		SUM2L
		TEMP
		TEMPH
		ResL
		ResU

        endc

;;;;;;; Macro definitions ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MOVLF   macro  literal,dest
        movlw  literal
        movwf  dest
        endm


;;;;;;; Vectors ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        org  0x0000             ;Reset vector
        nop
        goto  Mainline

        org  0x0008             ;High priority interrupt vector
        goto  $  ;Trap

        org  0x0018             ;Low priority interrupt vector
        goto  $                  ;Trap

;;;;;;; Mainline program ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Mainline
        rcall  Initial          ;Initialize everything
Loop
	
		; --------------------------------------------------------------
		; Change value for counter depending 
		; on period of time series that you wish to use
		;
		MOVLF 2,counter ; Period Selector
		MOVLF upper SimpleTable,TBLPTRU 
		MOVLF high  SimpleTable,TBLPTRH 
		MOVLF low   SimpleTable,TBLPTRL
	label_A
		TBLRD*+
		movf TABLAT, W
		;movwf value

		;;;;;;; NOTE FOR STUDENTS:
		; 
		; Write the code for your moving average filter in 
		; the empty spaces below. Please create subroutines 
		; to make code your code transparent and easier to debug
		;
		; DO NOT MODIFY ANY OTHER PART OF THE THIS LOOP IN THE MAINLINE
		;
		; --------------------------------------------------------------
		; BEGIN WRTING CODE HERE 
		
			; ---------------------------------
			; (1) WRITE CODE FOR MEMORY BUFFER HERE
			;       you may write the full code 
			;		here or call a subroutine

			; Determine value for x[n] to x[n-3]
			movff xn2, xn3 ;x[n-3] = x[n-2]
			movff xn1, xn2 ;x[n-2] = x[n-1]
			movff xn, xn1 ;x[n-1] = x[n]
			movwf xn ; x[n] = TABLAT (current value of the program memory)
			
			
			; ---------------------------------
			; (2) WRITE CODE FOR ADDER AND DIVIDER HERE 
			;       you may write the full code 
			;		here or call a subroutine
				
			; ----------------------------------
			; 				  ADDER
			; ----------------------------------		
			; First Summation (SUM1)
			movf xn1, W ; changes wreg to x[n-1]
			addwf xn,W ; x[n]+x[n-1]
			movwf SUM1L ; Store above result into SUM1L
			movf TEMPH,W
			addwfc valueH,w ;x[n]+x[n-1] 
			movwf SUM1U ;result into SUM1U

			; Second Summation (SUM2)
			movf xn2,W ; x[n-2] = WREG
			addwf xn3,W ; x[n-2]+x[n-3]
			movwf SUM2L ;result into SUM2L
			movf TEMPH,W
			addwfc valueH,w ;x[n-2]+x[n-3] = SUM2U
			movwf SUM2U ;result into SUM2U

			; Final Summation (Res = SUM1 + SUM 2)
			movf SUM1L,W
			addwf SUM2L, W ; SUM1L + SUM2L
			movwf ResL ; Store result into ResL
			movf SUM1U,W
			addwfc SUM2U,w ; SUM1U + SUM2U
			movwf ResU ; Store result into ResU
			; ----------------------------------
			;				DIVIDER
			; ----------------------------------
			;First Rotation for ResU and ResL
			rrcf ResU, W ; ResU/2 
			movwf ResU 
			rrcf ResL, W ; ResL/2 
			movwf ResL
			; Second Rotation for ResU and ResL (effective div by 4)
			rrcf ResU, W ; ResU/2
			movwf ResU ; Final ResU Value
			rrcf ResL, W ; ResL/2
			movwf ResL ; Final ResL value		
		; FINISH WRTING CODE HERE 
		; --------------------------------------------------------------

		decf  counter,F        
	    bz  label_B
		bra label_A
	label_B

        bra	Loop
	



;;;;;;; Initial subroutine ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; This subroutine performs all initializations of variables and registers.

Initial
        MOVLF  B'10001110',ADCON1  ;Enable PORTA & PORTE digital I/O pins
        MOVLF  B'11100001',TRISA  ;Set I/O for PORTA 0 = output, 1 = input
        MOVLF  B'11011100',TRISB  ;Set I/O for PORTB
        MOVLF  B'11010000',TRISC  ;Set I/0 for PORTC
        MOVLF  B'00001111',TRISD  ;Set I/O for PORTD
        MOVLF  B'00000000',TRISE  ;Set I/O for PORTE
        MOVLF  B'10001000',T0CON  ;Set up Timer0 for a looptime of 10 ms;  bit7=1 enables timer; bit3=1 bypass prescaler
        MOVLF  B'00010000',PORTA  ;Turn off all four LEDs driven from PORTA ; See pin diagrams of Page 5 in DataSheet
        ; Initialize variables 
		MOVLF B'00000000',xn
		MOVLF B'00000000',xn1
		MOVLF B'00000000',xn2
		MOVLF B'00000000',xn3
		MOVLF B'00000000',SUM1L
		MOVLF B'00000000',SUM1U
		MOVLF B'00000000',SUM2L
		MOVLF B'00000000',SUM2U
		MOVLF B'00000000',valueH
		MOVLF B'00000000',TEMP
		MOVLF B'00000000',TEMPH
		MOVLF B'00000000',ResL
		MOVLF B'00000000',ResU

		return



;;;;;;; TIME SERIES DATA
;
; 	The following bytes are stored in program memory.
;	
;  Choose your Periodic Sequence
;--------------------------------------------------------------
; time series X1
SimpleTable ; ---> period 2
db 180,240
;--------------------------------------------------------------
; time series X2
;SimpleTable ; ---> period 4
;db 180,240,200,244
;--------------------------------------------------------------
; time series X3
;SimpleTable ; ---> period 6
;db 180,240,200,244,216,236
;--------------------------------------------------------------
; time series X4
;SimpleTable ; ---> period 8
;db 180,240,200,244,216,236,160,176
; --------------------------------------------------------------

        end


