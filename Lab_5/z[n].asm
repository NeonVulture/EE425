;;;;;;; P5 for QwikFlash board ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Program to implement y[n] = 0.5x[n] - 0.5x[n-2]
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
		valueL
		temp
		counter
		; --- END variables for TABLAT POINTER

		; Create your variables starting from here
		ProgMem
		TEMPL
		TEMPU
		valueU
		SUML
		SUMU
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
	
		MOVLF  10,counter
		MOVLF upper SimpleTable,TBLPTRU 
		MOVLF high  SimpleTable,TBLPTRH 
		MOVLF low   SimpleTable,TBLPTRL
	label_A
		TBLRD*+ 
        movf TABLAT, W
		movwf valueL ; get current value
		 

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
			
			; Determine x[n-2] by changing
			; pointer to 4 steps back to get x[n-2]
			movff TBLPTRL,ProgMem
		    
			tblrd*-
			tblrd*-
			tblrd*- 
			tblrd*-
			movf TABLAT, W ;W = x[n-2]
			movwf TEMPL
			; ---------------------------------
			; (2) WRITE CODE FOR ADDER AND DIVIDER HERE 
			;       you may write the full code 
			;		here or call a subroutine
			
			; Adder
			addwf valueL,W ; x[n]+x[n-2]
			movwf SUML ; Store lower result into SUML
			movf TEMPU,W
			addwfc valueU,w ;x[n]+x[n-1] with bit carry
			movwf SUMU ;Store upper result into SUMU	
           
			; Divider
            rrcf SUMU, W ; ResU/2 
			movwf SUMU 
			rrcf SUML, W ; ResL/2 
			movwf SUML	
		
			movff ProgMem, TBLPTRL ; restore pointer location
	
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
		MOVLF B'00000000',ProgMem
		MOVLF B'00000000',SUML
		MOVLF B'00000000',SUMU
		MOVLF B'00000000',TEMPL
		MOVLF B'00000000',TEMPU
		MOVLF B'00000000',valueL
		MOVLF B'00000000',valueU
        return



;;;;;;; TIME SERIES DATA
;
; 	The following bytes are stored in program memory.
;	DO NOT MODIFY
;
SimpleTable 
;  1| 2| 3 | 4 | 5 | 6 | 7 | 8 | 9 |10
db 0,50,100,150,200,250,200,150,100,50 ; 
; --------------------------------------------------------------

        end


