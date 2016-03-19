*-----------------------------------------------------------
* Title      : SnakePro
* Written by : Matthew Jacques
* Date       : 06/02/2016
* Description: EN0618 Advanced Games Architecture assignment

*-----------------------------------------------------------
    ORG    $1000  
START:   
    BSR LoadAudio       ; Load audio into memory
    BSR SetupGame    ; Setup settings with trap commands 
    BSR GetTime         ; Get current time into D5
        
;Main game loop
GameLoop:

; Update game data           
    BSR GetTime         ; Store new time in D5 for next gameLoop
    BSR CheckWin       ; Check if game is over (50 length)    
    BSR GetInput        ; Query keyboard for movement key presses
    BSR UpdateSnake     ; Update the snakes movement and check for collision
    BSR UpdateReward   ; Update the rewards positions and respawn if needed
    
; Draw game data
    BSR ClearScreen    
    BSR DrawLayout      ; Draw the layout
    BSR PrintScore      ; Print the score
    BSR DrawReward     ; Draw the reward
    BSR DrawSnake       ; Draw the snake       
    BSR FrameDelay      ; Delay frame for control
    BSR GameLoop

; End of GameLoop

************************************************************
* LoadAudio
* Loads the audio used in game
************************************************************
LoadAudio
    ; Store registers in stack
    MOVEM.L D0-D7/A0-A6,-(A7)  
    
    ; Load reward spawn audio filename and TRAP to load
    LEA spawnAudio,A1 
    MOVEQ #0,D1  
    MOVEQ #74,D0 
    TRAP #15 
    
    ; Load reward pickup audio filename and TRAP to load
    LEA pickupAudio,A1 
    MOVEQ #1,D1   
    MOVEQ #74,D0 
    TRAP #15  
    
    ; Load game over audio filename and TRAP to load
    LEA gameOverAudio,A1 
    MOVEQ #2,D1     
    MOVEQ #74,D0 
    TRAP #15 
    
    ; Restore registers and return
    MOVEM.L (A7)+,D0-D7/A0-A6 
    RTS                      
    
 
************************************************************
* SetupGame
* Set up default variables, modes and snake location
************************************************************
SetupGame
    ; Move registers to the stack
    MOVEM.L D0-D7/A0-A6,-(A7)  
      
    ;Turn input echo off
	MOVEQ	#0,D1  
	MOVEQ	#12,D0  
	TRAP   	#15 
      
    ; Default score and time
    MOVE.W #0,score  
    MOVE.L #10,gameSpeed
    MOVE.L #0,frameTime
    
    ; Default snake
    MOVE.W #100,snakeLocation
    MOVE.W #3,snakeLength
    MOVE.B #'D',snakeDirection
    
    ; Default reward
    MOVE.W #0,rewardX
    MOVE.W #0,rewardY
    MOVE.L #0,rewardTime
    MOVE.B #0,rewardType
    
    ; Load adress of snake and add coords to array
    LEA snakeLocation, A0
    MOVE.W #100,(A0)+ 
    MOVE.W #110,(A0)+ 
    MOVE.W #100,(A0)+ 
    MOVE.W #120,(A0)+ 
    MOVE.W #100,(A0)+ 
    MOVE.W #130,(A0) 
 
    ; Restore registers and return
    MOVEM.L (A7)+,D0-D7/A0-A6 	
    RTS           

 
************************************************************
* GetTime
* Get the time from the system
************************************************************       
GetTime
    ; Store registers in stack
    MOVEM.L D0-D1,-(A7) 
    
    ; Get time TRAP
    MOVEQ #8,D0  
    TRAP #15  
    
    ; Move to D5 (unused register)
    MOVE.L D1,D5 
    
    ; Restore registers and return
    MOVEM.L (A7)+,D0-D1 
    RTS  

 
************************************************************    
* CheckWin
* Check to see if win condition has been met
************************************************************    
CheckWin
    ; Compare length of snake to 50, branch to win if same
    CMP.W #50,snakeLength   
    BEQ EndWin  
    
    ; Return
    RTS     


************************************************************
* EndWin
* Prompts user for replay with winner message
************************************************************
EndWin 
    ; Store registers on stack
    MOVEM.L D0-D7/A0-A6,-(A7)    
    
    ;Play game finished audio
    MOVEQ #2,D1  )
    MOVEQ #75,D0 )
    TRAP #15   
    
    ; Pen fill colour
	MOVE.L	#BLACK,D1	
	MOVEQ	#81,D0       
	TRAP	#15     
	
    ; Pen location
    MOVEQ	#11,D0  
	MOVE.W	#6657,D1        ; Upper is col, lower is row
	TRAP	#15        

    ; Load address of won message and display TRAP
    LEA     gameOverWin,A1 
    MOVEQ   #14,D0                
    TRAP    #15    

    ; Restore registers from the stack
    MOVEM.L (A7)+,D0-D1
    
    ; Enter loop waiting for player to replay
    BSR PromptReplay    
    
    ; Return
    RTS  
    

************************************************************
* PromptReplay
* Waits for player input to replay
************************************************************
PromptReplay
    ; Check for restart input, if none, check again
    BSR GetInput          
    BSR PromptReplay   
    
 
************************************************************
* GetInput
* Check for any input from keyboard
************************************************************
GetInput
    ; Store registers in stack
    MOVEM.L D0-D7/A0-A6,-(A7)      
 
    ; Load bitcodes for arrow keys in to D1 for press check
    MOVE.L #$25<<24+$26<<16+$27<<8+$28,D1 
   
    ; Check input trap
    MOVE.B #19,D0 
    TRAP   #15 
    
    ; Check if up arrow was pressed
    BTST.L #16,D1 
    BNE INPUTUP 
    
    ; Check if right arrow was pressed
    BTST.L #8,D1
    BNE INPUTRIGHT 
    
    ; Check if down arrow was pressed
    BTST.L #0,D1
    BNE INPUTDOWN
    
    ; Check if left arrow was pressed
    BTST.L #24,D1  
    BNE INPUTLEFT 
    
    ; Check if restart key was pressed
    MOVE.L #'F',D1
    MOVE.B #19,D0
    TRAP #15
    
    ; Branch if key was press was true
    TST.L D1
    BNE RESTART
	
	; Branch if input
	BRA DONEINPUT	

INPUTUP
    ; Set direction to input if not 180 degrees
    CMP.B #'D',snakeDirection  
    BEQ DONEINPUT 
    MOVE.B #'U',snakeDirection 
    BRA DONEINPUT
    
INPUTRIGHT
    ; Set direction to input if not 180 degrees
    CMP.B #'L',snakeDirection
    BEQ DONEINPUT  
    MOVE.B #'R',snakeDirection
    BRA DONEINPUT

INPUTDOWN 
    ; Set direction to input if not 180 degrees
    CMP.B #'U',snakeDirection
    BEQ DONEINPUT  
    MOVE.B #'D',snakeDirection
    BRA DONEINPUT 
  
INPUTLEFT
    ; Set direction to input if not 180 degrees
    CMP.B #'R',snakeDirection
    BEQ DONEINPUT  
    MOVE.B #'L',snakeDirection
    BRA DONEINPUT 

RESTART
    ; Restore registers and branch to restart game
    MOVEM.L (A7)+,D0-D7/A0-A6	
    BRA START

DONEINPUT
    ; Restore registers and return
    MOVEM.L (A7)+,D0-D7/A0-A6 	
    RTS  
    
 
************************************************************
* UpdateSnake
* Update the snake object (move & collisions)
************************************************************
UpdateSnake   
    ; Store registers on stack
    MOVEM.L D0-D7/A0-A6,-(A7)   

; Check for collision with reward

    ; Load snake and reward coords
    LEA snakeLocation, A0
    MOVE.W rewardY,D0 
    MOVE.W rewardX,D1
    
    ; Check to see if head has correct Y
    CMP.W (A0)+,D0 
    BNE LOADTAIL 
    
    ; Check to see if head has correct X
    CMP.W (A0),D1 
    BNE LOADTAIL 
    
    ;Play collect reward audio
    MOVEQ #1,D1 
    MOVEQ #75,D0 
    TRAP #15 
    
    
    ; Check if collected type 1 reward, branch if so
    CMP.B #1,rewardType
    BEQ SCORE5 
    
    ; Check if collected type 2 reward, branch if so
    CMP.B #2,rewardType 
    BEQ SCORE10 

    ; Check if collected type 3 reward, branch if so
    CMP.B #3,rewardType 
    BEQ SCORE20   
    
SCORE5
    ; Add 5 score for type 1 and branch to change reward time
    ADD.W #5,score 
    BRA SETREWARDSPAWN
    
SCORE10
    ; Add 10 score for type 2 and branch to change reward time
    ADD.W #10,score      
    BRA SETREWARDSPAWN 
    
SCORE20
    ; Add 20 score for type 3 and branch to change reward time
    ADD.W #20,score       
    
SETREWARDSPAWN
    ; Set reward to timed out and increment snake length
    MOVE.L #0,rewardTime 
    ADDQ #1,snakeLength  
    
LOADTAIL
; Load data ready to move snake

    ; Load snake data
    LEA snakeLocation, A0  ; For end of snake
    LEA snakeLocation, A1  ; For new end of snake  
    LEA snakeLocation, A2  ; For first tail segment

    ; Make A0 point to end of snake
    MOVE.W snakeLength,D0  
    MULU.W #4,D0  
    ADDA D0,A0  
    
    ; Make A1 new end of snake
    SUBQ #4,D0    
    ADDA D0,A1 

    ; Make A2 first tail segment
    MOVEQ #4,D0   
    ADDA D0,A2         
    
MOVESEGMENT
; Move snake one segment at a time
    ; Move segment one element at a time
    MOVE.W -(A1),-(A0) 
    
    ; Check to see if all segments moved                    
    CMP A0,A2               
    BNE MOVESEGMENT 

    ; Check if snake is moving up
    CMP.B #'U',snakeDirection
    BEQ MOVEUP   
    
    ; Check if snake is moving to the right
    CMP.B #'R',snakeDirection
    BEQ MOVERIGHT    

    ; Check if snake is moving down
    CMP.B #'D',snakeDirection
    BEQ MOVEDOWN

    ; Check if snake is moving to the left
    CMP.B #'L',snakeDirection
    BEQ MOVELEFT  

MOVEUP
; Move snake up
    ; Get heard coords
    MOVE.W -(A0),D0    
    MOVE.W -(A0),D1
    
    ; Subtract 10 from Y coord
    SUB.W #10,D1
    
    ; Update heard coords
    MOVE.W D0,-(A2)    
    MOVE.W D1,-(A2)  
    
MOVERIGHT
; Move snake to the right
    ; Get heard coords
    MOVE.W -(A0),D0    
    MOVE.W -(A0),D1   

    ; Add 10 to X coord    
    ADD.W #10,D0 
    
    ; Update heard coords
    MOVE.W D0,-(A2)    
    MOVE.W D1,-(A2)

    ; Check collision         
    BRA CHECKCOL
    
MOVEDOWN
; Move snake down
    ; Get heard coords
    MOVE.W -(A0),D0    
    MOVE.W -(A0),D1
    
    ; Add 10 to Y coord
    ADD.W #10,D1  
     
    ; Update heard coords
    MOVE.W D0,-(A2)    
    MOVE.W D1,-(A2)

    ; Check collision         
    BRA CHECKCOL 
    
MOVELEFT
; Move snake to the left
    ; Get heard coords
    MOVE.W -(A0),D0    
    MOVE.W -(A0),D1
    
    ; Subtract 10 from X coord
    SUB.W #10,D0
    
    ; Update heard coords
    MOVE.W D0,-(A2)    
    MOVE.W D1,-(A2)

    ; Check collision         
    BRA CHECKCOL

CHECKCOL
; Check for collison with snake
    ; Load snake length
    MOVE.W snakeLength,D0
    MULU.W #4,D0 

    ; Get snake head coords 
    LEA snakeLocation,A0
    MOVE.W (A0)+,D1 
    MOVE.W (A0),D2  

CHECKSEGCOL 
; Check if head collides with segment
    ; Check to see if all segments have been checked, branch if so       
    CMP #4,D0  
    BLE CHECKWALLCOL   
    
    ; Load start of snake array
    LEA snakeLocation,A0 

    ; Get next segment to check (first time to avoid head)
    ADDA D0,A0  
    SUB.W #4,D0   
    
    ; Check if has same X coord, loop if not collide
    CMP.W -(A0),D2  
    BNE CHECKSEGCOL  
    
    ; Check if has same Y coord, loop if not collide
    CMP.W -(A0),D1 
    BNE CHECKSEGCOL 

    ; Branch if collides, snake collide game over
    BRA SNAKEGAMEOVER
   
CHECKWALLCOL
; Check if snake head collides with wall
    ; Load start of snake array
    LEA snakeLocation,A0 
       
    ; Load border coords
    MOVE.W topBorder,D0
    MOVE.W screenHeight,D1
    MOVE.W screenWidth,D2
    
    ; Check top border, branch if collides to wall collide game over
    CMP.W (A0),D0  
    BGE WALLGAMEOVER 

    ; Check bottom border, branch if collides to wall collide game over  
    CMP.W (A0)+,D1    
    BLE WALLGAMEOVER   

    ; Check left border, branch if collides to wall collide game over  
    CMP.W #0,(A0)   
    BLE WALLGAMEOVER   

    ; Check right border, branch if collides to wall collide game over   
    CMP.W (A0),D2  
    BLE WALLGAMEOVER    
    
    ; No collision, branch to return from update
    BRA DONEUPDATE
 
SNAKEGAMEOVER
; Collision with snake detected, output game over
 	; Pen fill colour
	MOVE.L	#BLACK,D1
	MOVEQ	#81,D0 
	TRAP	#15 
	
	; Move pen to message start, upper is col, lower is row
    MOVEQ	#11,D0
	MOVE.W	#5121,D1 
	TRAP	#15 

    ; Load address of game over message and execute output TRAP
    LEA     gameOverSnake,A1
    MOVEQ   #14,D0  
    TRAP #15 
    	
    ; Restore registers and branch game over loop
    MOVEM.L (A7)+,D0-D7/A0-A6   
    BRA EndLose     
    
WALLGAMEOVER
; Collision with wall detected, output game over 
 	; Pen fill colour
	MOVE.L	#BLACK,D1
	MOVEQ	#81,D0 
	TRAP	#15 
	
	; Move pen to message start, upper is col, lower is row
    MOVEQ	#11,D0
	MOVE.W	#5121,D1 
	TRAP	#15 
	
    ; Load address of game over message and execute output TRAP
    LEA     gameOverWall,A1
    MOVEQ   #14,D0  
    TRAP #15  
    
    ; Restore registers and branch to game over loop
    MOVEM.L (A7)+,D0-D7/A0-A6  
    BRA EndLose   
    
DONEUPDATE
    ; Restore registers and return
    MOVEM.L (A7)+,D0-D7/A0-A6
    RTS    


************************************************************
* EndLose
* Prompts user for replay with loser message
************************************************************    
EndLose 
    ; Store registers on the stack
    MOVEM.L D0-D7/A0-A6,-(A7)     
  
    ;Play end finished audio
    MOVEQ #2,D1      
    MOVEQ #75,D0   
    TRAP #15  
    
    ; Restore registers from stack
    MOVEM.L (A7)+,D0-D1
    
    ; Enter loop waiting for player to replay
    BSR PromptReplay
    
    ; Return
    RTS 
    
 
************************************************************
* UpdateReward
* Updates the rewards, respawn, handles reward time out
************************************************************
UpdateReward
    ; Store registers on stack
    MOVEM.L D0-D7/A0-A6,-(A7) 

    ; Load the frame time and how long until reward timeout
    LEA frameTime,A0 
    LEA rewardTime,A1  
    
    ; Execute time trap
    MOVEQ #8,D0
    TRAP #15   

    ; Calculate how much time has passed since last frame
    MOVE.L (A0),D3  
    SUB.L D3,D1            
    
    ; Subtract time passed from reward time remaining
    SUB.L D1,(A1)  
    
    ; Check to see if reward needs to be respawned
    MOVE.L (A1),D3
    CMP.L #0,D3 
    BGE DONEREWARD 
     
    ; Else spawn new reward
    
    ; Get next reward type, if over number of types, reset
    ADDQ.B #1,rewardType 
    CMP.B #4,rewardType 
    BLT GENPOSITION       ; Branch if no reset needed
    MOVE.B #1,rewardType
    
GENPOSITION
;Get random X value using time (template from online source)
    ; Get time
    MOVEQ   #8, D0
    TRAP    #15
    
    ; Using time, get a value between 10 and 630
    AND.L   #$5FFFFF,D1     ; Prevent overflow
    DIVU    #620,D1         ; Divide by upper range minus addition
    SWAP    D1              ; Swap bits so near range
    ADD.W   #11,D1          ; Add 11 to make value in range    
    AND.L   #$FFFF,D1       ; Clear upper bits
    DIVU    #10,D1   
    MULU    #10,D1  
    MOVE.W  D1,D2  
    
;Get random Y value using time (template from online source)
   ; Get time
    MOVEQ   #8, D0         
    TRAP    #15          
    
    ; Using time, get a value between 50 and 470
    AND.L   #$5FFFFF,D1     ; Prevent overflow
    divu    #420,D1         ; Divide by upper range minus addition
    SWAP    D1              ; Swap the upper and lower bits
    ADD.W   #51,D1          ; Add 51 so the result is in range
    AND.L   #$FFFF,D1       ; Clear upper bits
    DIVU    #10,D1    
    MULU    #10,D1   
    MOVE.W  D1,D3   
    
; Check to see if random point is within snake

    ; Load snake
    LEA snakeLocation,A0 ; For iterator
    LEA snakeLocation,A1 ; For end of snake

    ; Make A1 point to end of snake
    MOVE.W snakeLength,D0
    MULU.W #4,D0   
    ADDA D0,A1        
        
CHECKINSIDESNAKE
; Check if point is within snake segment
    ; Check to see if all segments checked, if so branch
    CMPA A1,A0 
    BEQ UPDATEVARS

    ; Decrement and check to see if X collides
    CMP.W -(A1),D2
    BNE SKIPSEG 
    
    ; Decrement and check to see if Y collides
    CMP.W -(A1),D3 
    BNE CHECKINSIDESNAKE
    
    ; Point is in snake, get new point
    BRA GENPOSITION
    
SKIPSEG
    ;Subtracts to get next word containing segment
    SUBA #2,A1
    BRA CHECKINSIDESNAKE
    
UPDATEVARS
; Reset reward vars
    ; Update X and Y coords
    MOVE.W D2,rewardX
    MOVE.W D3,rewardY
    
    ; Reset reward time out
    MOVE.L #1400,rewardTime
    
    ;Play spawn reward audio
    MOVEQ #0,D1  
    MOVEQ #75,D0 
    TRAP #15 
    
    
DONEREWARD
    ; Get time
	MOVEQ #8,D0 
    TRAP #15 

    ; Update frame time
    MOVE.L D1,frameTime
   
    ; Restore registers and return
    MOVEM.L (A7)+,D0-D7/A0-A6
    RTS 
    
 
************************************************************
* ClearScreen
* Clear the screen so can be drawn over again
************************************************************
ClearScreen    
    ; Store registers on stack
    MOVEM.L D0-D7/A0-A6,-(A7)
    
    ; Execute clear screen trap
	MOVE.W #$FF00,D1 
    MOVEQ #11,D0    
    TRAP #15    
    
    ; Restore registers and return
    MOVEM.L (A7)+,D0-D7/A0-A6 ; 
    RTS 


************************************************************
* DrawLayout
* Draw the layout of the playing area to screen
************************************************************
DrawLayout
    ; Store registers on the stack
    MOVEM.L D0-D7/A0-A6,-(A7)
    
    ; Pen colour
	MOVE.L	#BLUE,d1	
	MOVEQ	#80,D0      
	TRAP	#15       
	
	; Pen fill colour
	MOVE.L	#BLACK,d1
	MOVEQ	#81,D0      
	TRAP	#15     
	
	; Pen width
	MOVEQ	#5,D1	 
	MOVEQ	#93,D0    
	TRAP	#15            
	
	;Draw top border
	MOVEQ	#0,D1	        ; Left
	MOVE.W	topBorder,D2    ; Top
	MOVE.W	screenWidth,D3  ; Right
	MOVE.W	topBorder,D4	; Bottom
	MOVEQ	#84,D0  
	TRAP	#15          
	
	; Restore registers and return
	MOVEM.L (A7)+,D0-D7/A0-A6 
	RTS                
	

************************************************************
* PrintScore
* Prints the players score to the screen
************************************************************
PrintScore
    ; Store registers on stack
    MOVEM.L D0-D7/A0-A6,-(A7) 

    ; Move pen location
    MOVEQ	#11,D0     
	MOVE.W	#513,D1        ; Upper is col, lower is row
	TRAP	#15
	
    ; Output score label
    LEA     scoreText,A1  
    MOVEQ   #14,D0  
    TRAP    #15   
    
    ;Print score value
    MOVEQ	#15,D0   
	MOVEQ	#10,D2     ; Convert to base 10 
	MOVE.W	score,D1 
	TRAP	#15  
	 
	; Restore registers and return
    MOVEM.L (A7)+,D0-D7/A0-A6 	
    RTS            

 	
************************************************************
* DrawReward
* Draw the reward to the screen
************************************************************    
DrawReward
    ; Store registers on stack
    MOVEM.L D0-D7/A0-A6,-(A7)
    
    ;Check type and draw appropriate reward
    CMP.B #1,rewardType    ; Type 1 red reward
    BEQ SETRED   
    CMP.B #2,rewardType    ; Type 2 yellow reward
    BEQ SETYELLOW    
    CMP.B #3,rewardType    ; Type 3 green reward
    BEQ SETGREEN
    
SETRED
; Draw red reward
    ; Pen colour
	MOVE.L	#RED,D1
	MOVEQ	#80,D0
	TRAP	#15  
	
	; Pen fill colour
	MOVE.L	#RED,D1	
	MOVEQ	#81,D0
	TRAP	#15             
	
	BRA REWARDDRAW
	
SETYELLOW
; Draw yellow reward
    ; Pen colour
	MOVE.L	#YELLOW,D1
	MOVEQ	#80,D0    
	TRAP	#15             
	
	; Pen fill colour
	MOVE.L	#YELLOW,D1	
	MOVEQ	#81,D0 
	TRAP	#15             
	
	BRA REWARDDRAW
	
SETGREEN
; Draw green reward
    ; Pen colour
	MOVE.L	#GREEN,D1
	MOVEQ	#80,D0   
	TRAP	#15             
	
	; Pen fill colour
	MOVE.L	#GREEN,D1
	MOVEQ	#81,D0  
	TRAP	#15             
	
REWARDDRAW
; Draw the circle to represent the reward
	; Pen width
	MOVEQ	#2,D1
	MOVEQ	#93,D0
	TRAP	#15             
    
    ; Set height with Y coord
    MOVE.W  rewardY,D2 
  	SUB     #5,D2       	
  	MOVE.W  rewardY,D4
  	ADD     #5,D4  
  	
  	; Set width with X coord
  	MOVE.W  rewardX,D1 
  	SUB     #5,D1    	
  	MOVE.W  rewardX,D3
  	ADD     #5,D3  	

    ; Execute draw TRAP
  	MOVEQ	#88,D0
	TRAP	#15  
	
	; Restore registers and return
	MOVEM.L (A7)+,D0-D7/A0-A6 
	RTS               
	

************************************************************
* DrawSnake
* Draw snake to the screen
************************************************************
DrawSnake
    ; Store registers on the stack
    MOVEM.L D0-D7/A0-A6,-(A7)
    
    ; Pen colour
	MOVE.L	#YELLOW,D1	
	MOVEQ	#80,D0     
	TRAP	#15 
	
    ; Pen width
	MOVEQ	#2,D1	
	MOVEQ	#93,D0     
	TRAP	#15   
	
	; Pen fill colour
	MOVE.L	#GREEN,D1	
	MOVEQ	#81,D0   
	TRAP	#15 

    ; Load address of snake
    LEA snakeLocation, A0  ; Iterator
    LEA snakeLocation, A1  ; End of snake
    
    ; Make A1 point to end of snake
    MOVE.W snakeLength,D0  
    MULU.W #4,D0         
    ADDA D0,A1  
	
DRAWSEGMENT
; Draw a snake segment to screen
    ; Get Y coord and give height
    MOVE.W  (A0),D2     
  	SUB     #5,D2        	
  	MOVE.W  (A0)+,D4  
  	ADD     #5,D4 
  	
  	; Get X coord and give width
  	MOVE.W  (A0),D1      
  	SUB     #5,D1    
  	MOVE.W  (A0)+,D3    
  	ADD     #5,D3   
  	
  	; Draw segment to screen
  	MOVEQ	#87,D0
	TRAP	#15     
	
	; Check to see if reached end of tail, branch if not
	CMPA A0,A1
	BNE DRAWSEGMENT   
	
;Draw the head of the snake	
	; Pen colour
	MOVE.L	#YELLOW,D1	
	MOVEQ	#80,D0       
	TRAP	#15  
	
	; Pen fill colour
	MOVE.L	#BLUE,D1	
	MOVEQ	#81,D0      
	TRAP	#15    
	
	; Load address of snake
    LEA snakeLocation, A0 
    
    ;Get Y coord and give height
	MOVE.W  (A0),D2   
  	SUB     #5,D2         	
  	MOVE.W  (A0)+,D4   
  	ADD     #5,D4  	
  	
  	; Get X coord and give width
  	MOVE.W  (A0),D1     
  	SUB     #5,D1         
  	MOVE.W  (A0)+,D3   
  	ADD     #5,D3  
  	
  	; Draw head to screen
  	MOVEQ	#87,D0    
	TRAP	#15      
	
    ; Restore registers and return
    MOVEM.L (A7)+,D0-D7/A0-A6  
    RTS                    


************************************************************
* FrameDelay
* Delays next frame for snake control
************************************************************
FrameDelay
    ; Execute get time trap
    MOVEQ #8,D0
    TRAP #15 
    
    ; Calc time passed since start of game loop
    SUB.L D5,D1
    
    ; Compare with gameTime to see if new frame can be started
    CMP.L gameSpeed,D1
    BLO FrameDelay  
    
    ; Enough time passed, start next game loop
    BRA GameLoop

 
************************************************************
* Variables and Constants
* Data used within game
************************************************************

; Border positions
topBorder    DC.W 40     ; Collision and border draw
screenHeight DC.W 480    ; Collision
screenWidth  DC.W 640    ; Collison and border draw

; Score and time
gameSpeed     DC.L 10    ; Speed of game
score         DC.W 0     ; Score of player
frameTime     DC.L 0     ; Time since last frame

; Reward data
rewardX DC.W 0         ; X coordinate of reward
rewardY DC.W 0         ; Y coordinate of reward
rewardType   DC.B 0         ; Type of reward
rewardTime   DC.L 0         ; How long until reward despawns

; Snake data
snakeLocation  DS.W 100    ; Snake locations, x and y
snakeLength     DC.W 4      ; Length of the snake
snakeDirection     DC.B 'D'      ; Direction snake is travelling

; Filenames of audio
spawnAudio    DC.B 'SpawnReward.wav',0   
pickupAudio   DC.B 'PickupReward.wav',0  
gameOverAudio  DC.B 'EndGame.wav',0 

; Text labels
scoreText    DC.B 'Score: ',0  
gameOverWall DC.B 'Game Over: You hit the wall, F to replay',0
gameOverSnake DC.B 'Game Over: You hit yourself, F to replay',0
gameOverWin      DC.B 'You Win: Well done, F to replay',0         

; Colour definitions from easy68k.com
BLACK             EQU     $00000000
MAROON            EQU     $00000080
GREEN             EQU     $00008000
OLIVE             EQU     $00008080
NAVY              EQU     $00800000
PURPLE            EQU     $00800080
TEAL              EQU     $00808000
GRAY              EQU     $00808080
RED               EQU     $000000FF
LIME              EQU     $0000FF00
YELLOW            EQU     $0000FFFF
BLUE              EQU     $00FF0000
FUCHSIA           EQU     $00FF00FF
AQUA              EQU     $00FFFF00
LTGRAY            EQU     $00C0C0C0
WHITE             EQU     $00FFFFFF

  
 END    START        ; last line of source





















*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
