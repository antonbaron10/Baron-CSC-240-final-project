;
; Final.asm
;r18 is column, r19 is row
; Created: 12/3/2019 8:47:17 AM
; Author : Anthony Baron
;


.cseg																	; start of code segment
.org	0x0000
rjmp	setup
.org	0x0100

//setting the size of the OLED
.equ			OLED_WIDTH = 128;
.equ			OLED_HEIGHT = 64;

//set the ADC low value and high value
.def			adc_value_low	= r23							; ADC conversion low byte
.def			adc_value_high	= r24							; ADC conversion high byte	


;Libraries
.include		"lib_delay.asm"
.include		"lib_SSD1306_OLED.asm"
.include		"lib_GFX.asm"


.equ playerCol=0;					//assigns player column to 0 since it is always the same
.equ defenderCol = 14;				//assigns players colum to 14 since it is always the same
.def workhorse= r16;				//workhorse will be r16
.def playerRow = r2;				//player Row will be stored in r2
.def defenderRow = r4;				//defender row will be stored in r4
.def points = r5;					//number of points scored is stored in r5

setup:
	ldi workhorse, 0b00000000 
	sts PORTC_DIR, workhorse		//set direction of portC pins

	ldi workhorse,0b00000001
	sts PORTB_DIR,workhorse			//sets the B0 pin to be an output pin

	ldi workhorse,0b00001000 
	sts PORTC_PIN2CTRL, workhorse  //makes pin C2 a pullup resistor pin

	rcall	OLED_initialize       //initialize array
	rcall	GFX_clear_array	
	rcall	GFX_refresh_screen	//refresh the screen

	//set up the ADC
	ldi		workhorse, 0b00000001
	sts		ADC0_CTRLA, workhorse //set ADC ENABLE
	ldi		r28, 0b00000000
	sts		ADC0_CTRLB, r28
	ldi		workhorse, 0b00010001
	sts		ADC0_CTRLC, workhorse
	ldi		r19, 0x09 //set ADC Prescalar to 4 (001 on bits 0,1,2)	
	sts		ADC0_MUXPOS, r19 //set MUX to AIN9 reading PB4

	rjmp gameStart
	
//Starting point of the game. Sets the X player and X defender on the board
gameStart:
	ldi workhorse,3
	mov playerRow, workhorse
	ldi workhorse, 1
	mov defenderRow, workhorse
	ldi r18,playerCol
	mov r19, playerRow
	rcall GFX_set_array_pos
	ldi r20,88
	st X,r20	

	ldi r18, defenderCol
	mov r19, defenderRow
	rcall GFX_set_array_pos
	ldi r20,88
	st X,r20
	rcall GFX_refresh_screen
	rjmp gameLoop

//Game Loop.
gameLoop:
rcall checkButton		//checks whether button was clicked to shoot a ball
rcall updatePlayerLoc	//checks whether player's location was updated
rcall updateDefenderLoc	//checks whether defender's location was updated
rcall showScore			//updates score. Makes sure the score stays on the board
rjmp gameLoop


//check if the button is clicked. Shoot the ball if button is clicked
checkButton: 
lds workhorse,PORTC_IN
andi workhorse,0b00000100
cpi workhorse,0x00
breq shootBall
ret
		
//Sets the starting location of the ball before it gets shot
shootBall:
	ldi workhorse,0x00
	;set location to add letter
	ldi r18 , 1
	mov r19, playerRow  
	rcall GFX_set_array_pos
	;draw the circle
	ldi r20, 7
	st X, r20
	rcall GFX_refresh_screen
	rjmp moveBall


//moveBall is called to move ball across the screen.
moveBall:
	rcall delay_100ms
	
	//check if other players changed Location
	rcall updatePlayerLoc
	rcall updateDefenderLoc

	inc r18
	cpi r18,defenderCol //this is comparing to save
	breq save
	dec r18
continue:
	cpi r18,15 //this is comparing to score
	breq score
	//I will erase old ball right here
	rcall GFX_set_array_pos
	ldi r20, 00
	st X, r20
	inc r18
	rcall GFX_set_array_pos
	ldi r20, 7
	st X, r20
	rcall GFX_refresh_screen
	rjmp moveBall

//Code program breaks to when the ball is not stopped by defender. Considered a goal and points increases by 1.
score:
	rcall GFX_set_array_pos
	ldi r20, 00
	st X, r20
	rcall GFX_refresh_screen
	
	inc points
	mov workhorse,points
	cpi workhorse,5   //game is considered a win when the player has 5 points
	breq endGame

	cpi workhorse,6  //restart game if theres a shot
	breq restart

	rjmp playSound

//code runs if ball is saved by defender
save:
	//compare the row side
	dec r18
	cp r19,defenderRow
	brne continue
	//actual save..row and column both confirmed
	ldi r18,13
	mov r19,playerRow
	rcall GFX_set_array_pos
	ldi r20, 00
	st X, r20
	rcall GFX_refresh_screen
	rjmp gameLoop

//play the sound when there is a score / win. Does not have the beeping, so it sends 5 volts and causes a click sign
playSound:
	ldi workhorse,0x01
	sts PORTB_OUT, workhorse
	rcall delay_1s
	ldi workhorse,0x00
	sts PORTB_OUT,workhorse
	rjmp gameLoop

//celebrate win of the game. the game dispays WIN on the screen
endGame:
	//display the word win!
	//show the W
	ldi r18,4
	ldi r19,0
	rcall GFX_set_array_pos
	ldi r20, 87
	st X, r20
	//show the I
	ldi r18,5
	ldi r19,0
	rcall GFX_set_array_pos
	ldi r20, 73
	st X, r20
	//show the N
	ldi r18,6
	ldi r19,0
	rcall GFX_set_array_pos
	ldi r20, 78
	st X, r20
	rcall GFX_refresh_screen
	rjmp gameLoop

//when the score becomes 6, game restarts and WIN is changed to spaces
restart:
	//hide W
	ldi workhorse, 0
	mov points, workhorse
	ldi r18,4
	ldi r19,0
	rcall GFX_set_array_pos
	ldi r20, 00
	st X, r20
	//hide the I
	ldi r18,5
	ldi r19,0
	rcall GFX_set_array_pos
	ldi r20, 00
	st X, r20
	//hide the N
	ldi r18,6
	ldi r19,0
	rcall GFX_set_array_pos
	ldi r20, 00
	st X, r20
	rcall GFX_refresh_screen
	

////////////////////////////////////////////////////////////

//moves X player
movePlayer:
	;erase old X
	push r19 //store current row before subroutine
	push r18 //store current colum with subroutine
	;mov r22,r19 //will store old value of r19 before changes
	;mov r21,r18 //r21 will store old value of r18 (the column)
	ldi r18, playerCol
	mov r19, playerRow
	rcall GFX_set_array_pos
	ldi r20, 00
	st X, r20
	;move array position to the new location
	;show the sprite at the new location
	mov playerRow,workhorse
	ldi r18,playerCol
	mov r19,playerRow
	rcall GFX_set_array_pos
	ldi r20, 88
	st X, r20
	rcall GFX_refresh_screen
	pop r18 //return initial column back
	pop r19 //return initial row back
	ret

//move defender 
moveDefender:
	push r19 //store current row before subroutine
	push r18 //store current colum with subroutine
	ldi r18, defenderCol
	mov r19, defenderRow
	rcall GFX_set_array_pos
	ldi r20, 00
	st X, r20
	;move array position to the new location
	mov defenderRow,workhorse
	ldi r18,defenderCol
	mov r19,defenderRow
	rcall GFX_set_array_pos
	ldi r20, 88
	st X, r20
	;show the sprite at the new location
	rcall GFX_refresh_screen
	pop r18 //return initial column back
	pop r19 //return initial row back

//does the analog conversion for when the potentiometer is changed for either team
analogConversion:
	ldi		workhorse, 0b00000001
	sts		ADC0_COMMAND, workhorse
	wait_adc:
		lds		workhorse, ADC0_INTFLAGS
		andi	workhorse, 0b00000001
		breq    wait_adc

	show:
		lds		adc_value_low, ADC0_RES
		lds		adc_value_high, ADC0_TEMP
		rol		adc_value_low
		rol		adc_value_high
		mov		workhorse, adc_value_high //workhorse will have the converted value
		ret
		

;this will check whether the location of the player updated
updatePlayerLoc:
	ldi workhorse, 0x09
	sts	ADC0_MUXPOS, workhorse
	rcall analogConversion
	cp playerRow,workhorse
	brne movePlayer
	ret

;this will check whether the location of the defender was updated
updateDefenderLoc:
	ldi workhorse, 0x08
	sts	ADC0_MUXPOS, workhorse
	rcall analogConversion
	cp defenderRow,workhorse
	brne moveDefender
	ret

//show current score of the player.
showScore:
	push points
	mov workhorse,playerRow
	ldi r18, 8
	ldi r19, 0
	rcall GFX_set_array_pos
	ldi r30,48
	add points,r30
	mov r20, points
	st X, r20
	rcall GFX_refresh_screen
	pop points
	ret