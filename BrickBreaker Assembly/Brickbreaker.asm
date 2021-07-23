# YOUR FULL NAME HERE
# YOUR USERNAME HERE

.include "display_2211_0822.asm"

# change these to whatever you like.
.eqv BALL_COLOR COLOR_WHITE
.eqv PADDLE_COLOR COLOR_ORANGE

.eqv BLOCK_WIDTH  8 # pixels wide
.eqv BLOCK_HEIGHT 4 # pixels tall

.eqv BOARD_BLOCK_WIDTH    8 # 8 blocks wide
.eqv BOARD_BLOCK_HEIGHT   6 # 6 blocks tall
.eqv BOARD_MAX_BLOCKS    48 # = BOARD_BLOCK_WIDTH * BOARD_BLOCK_HEIGHT
.eqv BOARD_BLOCK_BOTTOM  24 # = BLOCK_HEIGHT * BOARD_BLOCK_HEIGHT
                            # (the Y coordinate of the bottom of the blocks)

.eqv PADDLE_WIDTH  12 # pixels wide
.eqv PADDLE_HEIGHT  2 # pixels tall
.eqv PADDLE_Y      54 # fixed Y coordinate
.eqv PADDLE_MIN_X   0 # furthest left the left side can go
.eqv PADDLE_MAX_X  52 # furthest right the *left* side can go (= 64 - PADDLE_WIDTH)

.data
	off_screen:    .word 0 # bool, set to 1 when ball goes off-screen.
	paddle_x:      .word 0 # paddle's X coordinate
	paddle_vx:     .word 0 # paddle's X velocity (optional)

	ball_x:        .word 0 # ball's coordinates
	ball_y:        .word 0
	ball_vx:       .word 1# ball's velocity
	ball_vy:       .word 1
	ball_old_x:    .word 0 # used during collision to back the ball up when it collides
	ball_old_y:    .word 0

	# the blocks to be broken! these are just colors from constants.asm. 0 is empty.
	blocks:
	.byte 0 0 0 0 0 0 0 0
	.byte 0 0 0 0 0 0 0 0
	.byte 0 0 1 2 3 4 0 0
	.byte 0 0 5 6 8 9 0 0
	.byte 0 0 0 0 0 0 0 0
	.byte 0 0 0 0 0 0 0 0
.text

# -------------------------------------------------------------------------------------------------

.globl main
main:
	_loop:
		# TODO:
		jal setup_paddle
		jal setup_ball
		jal wait_for_start
		jal play_game
		jal count_blocks_left
		bnez v0, _loop

	# shorthand for li v0, 10; syscall
	syscall_exit

# -------------------------------------------------------------------------------------------------

# returns number of blocks in blocks array that are not 0.
count_blocks_left:
enter
	# TODO: actually implement this!
li v0, 0
li t0, 0
	_loop:
 		lb t1, blocks(t0)
 		bne t1,zero, _jump # if t1!=0 go to jump
		j _else
	_jump: 
		inc v0
	_else:
    		add t0, t0, 1
    		blt t0, BOARD_MAX_BLOCKS, _loop
leave
# -------------------------------------------------------------------------------------------------

setup_paddle:
enter
	li t0, PADDLE_MIN_X
	li t1, PADDLE_MAX_X
	sub t1,t1,t0 #(paddle max-paddle minx) 
	li a0, 0 #get bounds for syscall 42
	move a1, t1
	syscall_rand_range
	add t1,v0,t0 # add paddle min to (paddlemax-paddlemin)
	sw t1, paddle_x
	
leave
# -------------------------------------------------------------------------------------------------

play_game:
enter

_loop:
        jal count_blocks_left
        jal draw_paddle
    	jal draw_blocks
    	jal draw_ball
        jal move_x
        jal hit_wall
        jal hit_block_x
        jal move_y
        jal hit_ceil
        #jal hit_block_y
        jal hit_bottom
        jal show_blocks_left
        jal check_input
        jal display_update_and_clear
     	jal wait_for_next_frame
     	lw t0, off_screen
     	beq t0, 1 _out
        bnez v0, _loop
_out:
leave
# -------------------------------------------------------------------------------------------------

draw_paddle:
enter
	lw a0, paddle_x
	li a1, PADDLE_Y
	li a2, PADDLE_WIDTH
	li a3, PADDLE_HEIGHT
	li v1, PADDLE_COLOR
	jal display_fill_rect
leave

# -------------------------------------------------------------------------------------------------

check_input:
enter #very similar to lab 4
	jal input_get_keys_held #get input of key held in v0
	and t0,v0, KEY_R # and operator
	beq t0, zero, _break
		lw t0, paddle_x
		add t0,t0,1
		mini t0, t0, PADDLE_MAX_X
		sw t0, paddle_x
_break:
	and t0, v0, KEY_L
	beq t0, zero, _breakl
		lw t0, paddle_x
		sub t0,t0,1
		maxi t0, t0, PADDLE_MIN_X
		sw t0,paddle_x #paddle_x= t0
_breakl:
leave

# -------------------------------------------------------------------------------------------------
draw_blocks:
enter
	li s0, 0 ## s0=rows
_loop:
li s1, 0 ##s1= colum
	_loop2:    
	mul t0,s1,BLOCK_WIDTH 
	mul t1,s0,BLOCK_HEIGHT 
	move a0,t0
	move a1,t1
	li a2, BLOCK_WIDTH
	li a3, BLOCK_HEIGHT	
	la v1,blocks ## load array
	mul t0, s0, BLOCK_WIDTH ##offset by row
	add v1,v1,t0
	add v1,v1,s1 #since byte array add 1
	lb v1,(v1)
	jal display_fill_rect
    	add s1, s1, 1
    	blt s1, BOARD_BLOCK_WIDTH, _loop2
add s0, s0, 1
blt s0, BOARD_BLOCK_HEIGHT, _loop
leave

# -------------------------------------------------------------------------------------------------
show_blocks_left:
enter
	li a0, 3
	li a1, 57
	jal count_blocks_left
	move a2, v0
	jal display_draw_int
leave
# -------------------------------------------------------------------------------------------------
setup_ball:
enter
#	a0 = x
#	a1 = y
#	a2 = color (use one of the constants above)
	li t0, 5
	lw t1, paddle_x
	add a0,t0,t1
	sw a0, ball_x
	
	li t0, -1
	li t1, PADDLE_Y
	add a1, t0,t1
	sw a1, ball_y
leave
# -------------------------------------------------------------------------------------------------
draw_ball:
enter
	lw a0, ball_x
	lw a1, ball_y
	li a2, COLOR_BLUE # use the name of the constant, not the value
	jal display_set_pixel
	jal display_set_pixel
leave
#---------------------------------------------------------------------------------------------------
move_x:
enter
	lw t0, ball_x #t0=ball_x
	lw t1, ball_vx #t1= ball_vs
	add t0,t1,t0 
	sw t0, ball_x #store back in ball
leave
#---------------------------------------------------------------------------------------------------
move_y: #same as above except with y
enter
	lw t0, ball_y 
	lw t1, ball_vy
	sub t0,t0,t1
	sw t0, ball_y


leave
#---------------------------------------------------------------------------------------------------
wait_for_start:
enter
_loop:
	jal input_get_keys_held #get input of key held in v0
	bne v0, 0, _leaveloop
		jal draw_paddle
		jal draw_blocks
		jal draw_ball
		sw zero, off_screen
		jal display_update_and_clear
		jal wait_for_next_frame
	j   _loop
_leaveloop:


leave
#---------------------------------------------------------------------------------------------------
hit_wall:
enter
	lw t0, ball_x
	sw t0, ball_old_x #store ball x into ball old x
	lw t1, ball_vx 
	add t0, t0, t1
	sw t0, ball_x

	lw t3, ball_x
	ble t3, 0, _wall
	bge t3, 63 _wall
	j _not_wall
_wall:
	lw t1, ball_old_x #store old ball to ball
	sw t1, ball_x
	lw t2, ball_vx
	mul t2,t2, -1#negate 
	sw t2, ball_vx  
_not_wall:   
leave

#---------------------------------------------------------------------------------------------------
hit_ceil:
enter
	lw t0, ball_y
	sw t0, ball_old_y #store ball y into ball oldy
	lw t1, ball_vy 
	add t0, t0, t1
	sw t0, ball_y

	lw t3, ball_y
	ble t3, 0, _wall
	j _not_wall
_wall:
	lw t1, ball_old_y #store old ball to ball
	sw t1, ball_y
	lw t2, ball_vy
	mul t2,t2, -1#negate 
	sw t2, ball_vy  
_not_wall:   

#check paddle collision
	lw t2, ball_x
	lw t3, paddle_x
	add t4,t3,12 
	bne t0,54 _no #ball x and paddle y #nverse conditons so we can short circuit
	blt t2,t3 _no 
	bge t2,t4, _no

		lw t1, ball_old_y #store old ball to ball
		sw t1, ball_y
		lw t2, ball_vy
		mul t2,t2, -1#negate 
		sw t2, ball_vy  
_no:
leave
#---------------------------------------------------------------------------------------------------
hit_bottom:
enter
	lw t0, ball_y
	sw t0, ball_old_y #store ball y into ball oldy
	lw t1, ball_vy 
	add t0, t0, t1
	sw t0, ball_y
	lw t3, ball_y
	bge t3, 64, _off
		j _else
_off:
	li t0, 1
	sw t0, off_screen
_else:
leave
#------------------------------------------------------------------------------------
break_block: ##return 1 if hit 0 if no break n v1
enter
#when you divide the x/y by the block width/height, you now have the block column/row
#from that, you can calculate the block address
#just like in draw_blocks
#by multiplying

lw t0, ball_x
lw t1, ball_y
div t0, t0, 8 #column
div t1, t1, 4 #row
mul t1, t1, 8

la t2, blocks
add t2, t2, t0
add t2, t2, t1
lb t3, (t2)
beq t3, 0, _do_nothing
sb zero, (t2) #deletes block
li v1,1 #set return v1 to 1 to indicate true
j _nothing
_do_nothing:
li v1, 0 
_nothing:
leave
#------------------------------------------------------------------------------------------
hit_block_x:
enter
	lw t0, ball_x
	sw t0, ball_old_x #store ball x into ball old x
	lw t1, ball_vx 
	add t0, t0, t1
	sw t0, ball_x
	jal break_block
	beq v1, 1 _jump
	j _nothing
_jump:
	lw t1, ball_old_x #store old ball to ball
	sw t1, ball_x
	lw t2, ball_vx
	mul t2,t2, -1#negate 
	sw t2, ball_vx  
_nothing:
leave
#-----------------------------------------------------------------------------------------
#hit_block_y:  
#if you include this method ball just starts off shooting downward

#enter
#lw t0, ball_y
#sw t0, ball_old_y #store ball x into ball old x
#lw t1, ball_vy 
#add t0, t0, t1
#sw t0, ball_y

#jal break_block#
#beq v1, 1 _jump
#j _nothing
#_jump:
#lw t1, ball_old_y #store old ball to ball
#sw t1, ball_y
#lw t2, ball_vy
#mul t2,t2, -1#negate 
#sw t2, ball_vy  
#_nothing:
#leave
