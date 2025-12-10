.data 
					# English - created around June
					# Hey there, before you read this you should know a couple of things
					# first, yes, this has way too many comments
					# finals week is coming and I will (probably) forget all of this
					# in the next few days; I also got frustrated while writing it because of too much info and
					# started commenting everything so I wouldn't forget
					# For the smart AI logic (smarter than ChatGPT, trust)
					# you'll need to check the player 2 sections
					# almost all of the logic was the same so I reused it to save
					# time and complexity
					# Note: comments were originally in Spanish because the class was in Spanish
					# so in this file the comments were translated with AI cuz im to lazy to do it manually

					# How to play
					# You need to go to tools and activate Bitmap display
					# Pixel width and height to 16
					# Display width 256, Display height 512
					# Base adress for display 0x10010000 (static data)

					# Controls 
					# Movement: awsd
					# Place ships and attack: e
					# Rotate ships: r

display: .space 2048                    
input: .space 2                         # Buffer for user input (2 characters)
current_ship: .word 0                   # Current ship index (0=carrier, 1=battleship, 2=submarine, 3=frigate)
ship_sizes: .word 5, 4, 3, 2            # Ship sizes in order
orientation: .word 0                    # 0=horizontal, 1=vertical
game_mode: .word 0                      # 1=PvP, 2=PvE
invalid_msg: .asciiz "\nPosicion invalida\n"   # Error message

# VARIABLES FOR PVP
current_player: .word 1                 # Current player (1 or 2)
game_phase: .word 0                     # 0=placement, 1=attack
attack_cursor: .word 0                  # Attack cursor position
attempts_left: .word 3                  # Attempts left in the turn (PvP)
player1_score: .word 0                  # Player 1 score
player2_score: .word 0                  # Player 2 score
saved_pixel_color: .word 0              # Color of the pixel where the cursor is

# VARIABLES FOR THE SMART AI (easier would have been training a transformer to play this)
ai_mode: .word 0                        # 0=hunting (random), 1=targeting (directed)
ai_target_pos: .word 0                  # Position of the first hit found
ai_direction: .word 0                   # Current direction (0=up, 1=right, 2=down, 3=left)
ai_original_hit: .word 0                # Original position of the first ship hit
ai_steps_in_direction: .word 0          # Steps taken in the current direction

# SHIP MAPS - Arrays to track positions with ship IDs
# Values in the map: 0=water, 1=carrier, 2=battleship, 3=submarine, 4=frigate
player1_ship_map: .space 2048           # Ship map for player 1 
player2_ship_map: .space 2048           # Ship map for player 2 and the CPU

# Arrays to track ship health
player1_ships_health: .word 5, 4, 3, 2  # Current health of each ship for player 1
player2_ships_health: .word 5, 4, 3, 2  # Current health of each ship for player 2

# SYSTEM MESSAGES
menu_title: .asciiz "\n=== BATTLESHIP ===\n"
menu_option1: .asciiz "1. Jugador vs Jugador (PvP)\n"
menu_option2: .asciiz "2. Jugador vs CPU (PvE)\n"
menu_prompt: .asciiz "Selecciona una opcion (1 o 2): "
invalid_option: .asciiz "Opcion invalida! Presiona 1 o 2.\n"
jump: .asciiz "\n"

# SETUP MESSAGES
player1_msg: .asciiz "\n=== JUGADOR 1 (Tablero Superior) - Coloca tus barcos ===\n"
player2_msg: .asciiz "\n=== JUGADOR 2 (Tablero Inferior) - Coloca tus barcos ===\n"
ai_placing_msg: .asciiz "\n=== CPU colocando barcos... ===\n"
game_setup_complete: .asciiz "\n=== CONFIGURACION COMPLETA ===\nPresiona cualquier tecla para comenzar la batalla!\n"

# ATTACK MESSAGES
attack_phase_msg: .asciiz "\n=== FASE DE ATAQUE ===\n"
player1_attack_msg: .asciiz "\nJUGADOR 1 ataca el tablero inferior\n"
player2_attack_msg: .asciiz "\nJUGADOR 2 ataca el tablero superior\n"
hit_msg: .asciiz "\n¡IMPACTO! Dispara de nuevo.\n"
miss_msg: .asciiz "\n¡FALLO! "
attempts_msg: .asciiz "Intentos restantes: "
ship_sunk_msg: .asciiz "\n¡HUNDIDO!\n"
player1_wins_msg: .asciiz "\n¡GANA JUGADOR 1!\n"
player2_wins_msg: .asciiz "\n¡GANA JUGADOR 2!\n"
cpu_wins_msg: .asciiz "\n¡GANA LA CPU!\n"
score_msg: .asciiz "Puntuacion: "
game_over_msg: .asciiz "\nGAME OVER\n"
area_attack_msg: .asciiz "\n*** ¡ATAQUE EN AREA! *** (3x3)\n"

# SCORE MESSAGES
player1_score_msg: .asciiz "Jugador 1: "
player2_score_msg: .asciiz "Jugador 2: "
cpu_score_msg: .asciiz "CPU: "
final_scores_title: .asciiz "\n=== PUNTUACIONES FINALES ===\n"

# GAME COLORS
white: .word 0xFFFFFF                   # White for misses
green: .word 0x00FF00                   # Green for the attack cursor
red: .word 0xFF0000                     # Red for hits
purple: .word 0x800080                  # Purple for the separating line

.text
# ============= MAIN MENU =============
main_menu:
    # Show game title
    li $v0, 4
    la $a0, menu_title
    syscall
    
    # Show options
    li $v0, 4
    la $a0, menu_option1
    syscall
    
    li $v0, 4
    la $a0, menu_option2
    syscall
    
    # Show prompt
    li $v0, 4
    la $a0, menu_prompt
    syscall

menu_input:
    # Read user input
    li $v0, 8                # syscall to read string
    la $a0, input            # buffer address
    li $a1, 2                # max 2 characters
    syscall
    
    lb $t5, input            # load first character of input
    
    li $v0, 4
    la $a0, jump
    syscall
    
    # Check valid options
    beq $t5, 0x31, select_pvp    # '1' = PvP
    beq $t5, 0x32, select_pve    # '2' = PvE
    
    # Invalid option
    li $v0, 4
    la $a0, invalid_option
    syscall
    b menu_input             # ask for input again

select_pvp:
    li $t6, 1                # set PvP mode
    sw $t6, game_mode        # store in memory too
    b start_game             # go to the game

select_pve:
    li $t6, 2                # set PvE mode  
    sw $t6, game_mode        # store in memory too
    b start_game             # go to the game

# ============= GAME INITIALIZATION =============
start_game:
    # Show message for the current player
    lw $s0, current_player
    beq $s0, 1, show_player1_msg
    
show_player2_msg:
    li $v0, 4
    la $a0, player2_msg
    syscall
    
    # Hide player 1 ships when player 2 is placing
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    jal hide_player1_ships
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    
    b init_registers


show_player1_msg:
    li $v0, 4
    la $a0, player1_msg
    syscall
    
    # Show player 1 ships when placing or when it's their turn
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    jal show_player1_ships
    lw $ra, 0($sp)
    addi $sp, $sp, 4


init_registers:
    # Main game colors
    li $t0, 0x0000ff     # blue (base color of the boards)
    li $t1, 0            # counter for painting loops
    li $t2, 0xff0000     # red (color of the separating line)
    li $t3, 0xFFFF00     # yellow (preview ship color)
    li $t7, 0x808080     # gray (color of permanently placed ships)
    
    # Set initial cursor position based on player
    lw $s0, current_player
    beq $s0, 1, set_player1_cursor
    
set_player2_cursor:
    li $t4, 1088         # initial position for player 2 (after the red line)
    b continue_init

set_player1_cursor:
    li $t4, 64           # initial position for player 1 (second row of the top board)
    
continue_init:
    # Reset current ship and orientation for the new player
    sw $zero, current_ship
    sw $zero, orientation

# ============= INITIAL BOARD PAINTING =============
    # Only paint the full board if it's player 1
    lw $s0, current_player
    bne $s0, 1, skip_initial_paint

# Paint entire display blue first
loop_all_blue:
	sw $t0, display($t1)     # paint blue pixel at position $t1
	addi $t1, $t1, 4         # move to next pixel (4 bytes)
	beq $t1, 2048, paint_separator   # once at the end, paint separator
	b loop_all_blue          # keep painting blue

# Paint purple separating line in the middle (2 rows high)
paint_separator:
	move $s1, $t2            # save original $t2 value (red)
	li $t2, 0x800080         # temporarily switch to purple
	li $t1, 960              # start at row 15 (15 × 64 = 960)
	
separator_row1:              # first separator row
	sw $t2, display($t1)     # paint purple pixel
	addi $t1, $t1, 4         # next pixel
	beq $t1, 1024, separator_row2   # after row 15, go to row 16
	b separator_row1
	
separator_row2:              # second separator row
	sw $t2, display($t1)     # paint purple pixel
	addi $t1, $t1, 4         # next pixel
	beq $t1, 1088, restore_t2   # after row 16, restore $t2
	b separator_row2

restore_t2:
	move $t2, $s1            # restore original $t2 value (red)
	b skip_initial_paint

skip_initial_paint:
	# Paint the first ship (carrier) in preview
	jal paint_current_ship
	
# ============= MAIN INPUT LOOP =============
input_loop:
	# Read user input
	li $v0, 8                # syscall to read string
	la $a0, input            # buffer address
	li $a1, 2                # max 2 characters
	syscall
	
	lb $t5, input            # load first character of input
	
	# Check which key was pressed
	beq $t5, 0x77, up        # 'w' = move up
	beq $t5, 0x61, left      # 'a' = move left
	beq $t5, 0x73, down      # 's' = move down
	beq $t5, 0x64, right     # 'd' = move right
	beq $t5, 0x65, place     # 'e' = place ship
	beq $t5, 0x72, try_rotate # 'r' = try rotating ship
	beq $t5, 0x7A, exit      # 'z' = exit program
	
	b input_loop             # if no valid key, repeat

# ============= CHECK IF WE CAN ROTATE =============
try_rotate:
	# Check if current position is valid for rotation
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal is_valid_position    # reuse existing validation logic
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	beq $v0, 0, input_loop   # if invalid (over gray), ignore rotation
	b rotate                 # if valid, proceed with normal rotation

# ============= MOVEMENT FUNCTIONS =============
up:
	# Check if the WHOLE ship can move up
	addi $sp, $sp, -4        # save $ra on stack
	sw $ra, 0($sp)
	jal can_move_up          # verify move is valid
	lw $ra, 0($sp)           # restore $ra
	addi $sp, $sp, 4
	
	beq $v0, 0, input_loop   # if $v0=0 (invalid), don't move
	
	jal clear_current_ship   # erase ship at current position
	addi $t4, $t4, -64       # move cursor up (1 row = 64 bytes)
	jal paint_current_ship   # paint ship in new position
	b input_loop

left:
	# Check if the WHOLE ship can move left
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal can_move_left
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	beq $v0, 0, input_loop
	
	jal clear_current_ship   # erase current ship
	addi $t4, $t4, -4        # move cursor left (1 pixel = 4 bytes)
	jal paint_current_ship   # paint in new position
	b input_loop

right:
	# Check if the WHOLE ship can move right
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal can_move_right
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	beq $v0, 0, input_loop
	
	jal clear_current_ship   # erase current ship
	addi $t4, $t4, 4         # move cursor right
	jal paint_current_ship   # paint in new position
	b input_loop

down:
	# Check if the WHOLE ship can move down
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal can_move_down
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	beq $v0, 0, input_loop
	
	jal clear_current_ship   # erase current ship
	addi $t4, $t4, 64        # move cursor down
	jal paint_current_ship   # paint in new position
	b input_loop

# ============= ROTATION FUNCTION =============
rotate:
	jal clear_current_ship   # erase current ship
	
	# Toggle orientation (0→1 or 1→0)
	lw $s0, orientation
	xori $s0, $s0, 1         # XOR with 1 to flip bit
	sw $s0, orientation      # store new orientation
	
	# Check if the new orientation fits at the current position
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal is_valid_position    # verify it fits with new orientation
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	beq $v0, 0, revert_rotation   # if it doesn't fit, revert rotation
	
	jal paint_current_ship   # if it fits, paint with new orientation
	b input_loop

revert_rotation:
	# Rotation is invalid, go back to previous orientation
	lw $s0, orientation
	xori $s0, $s0, 1         # undo the change
	sw $s0, orientation
	jal paint_current_ship   # repaint with original orientation
	b input_loop

# ============= PLACEMENT FUNCTION =============
place:
	# Ensure the current position is valid BEFORE placing
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal is_valid_position    # verify there's no collision
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	beq $v0, 0, place_invalid # if invalid, show error and don't place
	
	# If we got here, the position is valid
	jal place_current_ship
	
	# Move to the next ship
	lw $s0, current_ship
	addi $s0, $s0, 1
	sw $s0, current_ship
	
	blt $s0, 4, setup_next_ship  # If there are ships left, continue
	
	# Current player finished placing all ships
	jal player_finished_placing

setup_next_ship:
	b input_loop

place_invalid:
	# Show error message and DO NOT place the ship
	li $v0, 4
	la $a0, invalid_msg
	syscall
	b input_loop             # return to input without placing anything

# ============= WHEN A PLAYER FINISHES PLACING =============
player_finished_placing:
    # Check game mode
    lw $s0, game_mode
    beq $s0, 2, ai_place_ships   # If PvE, let AI place ships
    
    # PvP mode - check which player finished
    lw $s0, current_player
    beq $s0, 2, both_players_done  # If player 2 finished, both are done
    
    # Player 1 finished, switch to player 2
    li $s0, 2
    sw $s0, current_player
    
    # Hide player 1 ships before player 2 places
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    jal hide_player1_ships
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    
    # Go to start_game so player 2 can place ships
    b start_game

ai_place_ships:
	# Show message that the AI is placing ships
	li $v0, 4
	la $a0, ai_placing_msg
	syscall
	
	# Call function to place ships automatically
	jal place_ai_ships
	
	# Continue to completed setup
	b both_players_done

both_players_done:
	# Both players have placed their ships
	li $v0, 4
	la $a0, game_setup_complete
	syscall
	
	# Wait for input
	li $v0, 8
	la $a0, input
	li $a1, 2
	syscall
	
	# Switch to attack phase
	li $s0, 1
	sw $s0, game_phase       # game_phase = 1 (attack)
	
	# Reset to player 1 to start attacking
	li $s0, 1
	sw $s0, current_player
	
	# Start attack phase
	b start_attack_phase

# ============= AI SHIP AUTO PLACEMENT =============
# Main function that randomly places all AI ships
place_ai_ships:
	# Save registers
	addi $sp, $sp, -16
	sw $s0, 0($sp)           # current ship index
	sw $s1, 4($sp)           # attempt counter
	sw $ra, 8($sp)
	sw $t0, 12($sp)          # preserve $t0
	
	li $s0, 0                # start with first ship (carrier)
	
place_ai_loop:
	bge $s0, 4, place_ai_done    # if all 4 ships placed, finish
	
	# Try to place current ship until a valid position is found
	li $s1, 0                # attempt counter (avoid infinite loop)
	
try_place_current_ai_ship:
	bgt $s1, 1000, place_ai_error    # avoid infinite loop after 1000 tries
	
	# Place current ship
	move $a0, $s0            # pass ship index
	jal try_place_ai_ship
	
	beq $v0, 1, ai_ship_placed   # if placed successfully, continue
	
	addi $s1, $s1, 1         # increment attempts
	b try_place_current_ai_ship
	
ai_ship_placed:
	addi $s0, $s0, 1         # advance to next ship
	b place_ai_loop
	
place_ai_done:
	# Restore registers
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	lw $ra, 8($sp)
	lw $t0, 12($sp)
	addi $sp, $sp, 16
	jr $ra

place_ai_error:
	# If we reach here, there's a logic error (shouldn't happen)
	li $v0, 4
	la $a0, invalid_msg
	syscall
	b place_ai_done

# ============= TRY TO PLACE A SPECIFIC AI SHIP =============
try_place_ai_ship:
	# $a0 = ship index (0-3)
	addi $sp, $sp, -32
	sw $s0, 0($sp)           # ship index
	sw $s1, 4($sp)           # random position
	sw $s2, 8($sp)           # random orientation
	sw $s3, 12($sp)          # ship size
	sw $s4, 16($sp)          # placement counter
	sw $s5, 20($sp)          # ship ID (index + 1)
	sw $s6, 24($sp)          # current position during placement
	sw $ra, 28($sp)
	
	move $s0, $a0            # store ship index
	
	# Get ship size
	sll $s3, $s0, 2          # multiply index by 4
	lw $s3, ship_sizes($s3)  # fetch size
	
	# Generate random position on the bottom board
	li $v0, 42               # syscall for random int range
	li $a0, 0                # generator ID
	li $a1, 16               # range 0-15 (16 columns)
	syscall
	move $s7, $a0            # $s7 = random column (0-15)
	
	li $v0, 42
	li $a0, 0
	li $a1, 15               # range 0-14 (15 rows on bottom board)
	syscall
	addi $a0, $a0, 17        # convert to row 17-31 (after separator)
	move $t9, $a0            # $t9 = random row (17-31)
	
	# Convert (column, row) to display offset
	sll $s1, $t9, 6          # row * 64
	sll $t8, $s7, 2          # column * 4
	add $s1, $s1, $t8        # position = (row * 64) + (column * 4)
	
	# Generate random orientation
	li $v0, 42
	li $a0, 0
	li $a1, 2                # range 0-1
	syscall
	move $s2, $a0            # $s2 = orientation (0=horizontal, 1=vertical)
	
	# Validate whether this position and orientation are valid
	move $a0, $s1            # position
	move $a1, $s2            # orientation
	move $a2, $s3            # ship size
	jal validate_ai_position
	
	beq $v0, 0, ai_placement_failed   # if not valid, fail
	
	# If we get here, the position is valid - place the ship
	move $s6, $s1            # starting position
	move $s4, $s3            # counter = ship size
	addi $s5, $s0, 1         # ship ID = index + 1
	
ai_place_loop:
	beq $s4, 0, ai_placement_success   # if counter = 0, we're done
	
	# Store ship ID in the map
	sw $s5, player2_ship_map($s6)
	
	addi $s4, $s4, -1        # decrement counter
	beq $s4, 0, ai_placement_success   # if done, success
	
	# Move to next position depending on orientation
	beq $s2, 0, ai_place_horizontal
	addi $s6, $s6, 64        # vertical: next row
	b ai_place_loop
	
ai_place_horizontal:
	addi $s6, $s6, 4         # horizontal: next column
	b ai_place_loop
	
ai_placement_success:
	li $v0, 1                # return success
	b ai_place_ship_done
	
ai_placement_failed:
	li $v0, 0                # return failure
	
ai_place_ship_done:
	# Restore registers
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	lw $s2, 8($sp)
	lw $s3, 12($sp)
	lw $s4, 16($sp)
	lw $s5, 20($sp)
	lw $s6, 24($sp)
	lw $ra, 28($sp)
	addi $sp, $sp, 32
	jr $ra

# ============= VALIDATE POSITION FOR AI =============
validate_ai_position:
	# $a0 = starting position, $a1 = orientation, $a2 = ship size
	addi $sp, $sp, -24
	sw $s0, 0($sp)           # current position
	sw $s1, 4($sp)           # orientation
	sw $s2, 8($sp)           # remaining size
	sw $s3, 12($sp)          # map value
	sw $s4, 16($sp)          # temp calculations
	sw $ra, 20($sp)
	
	move $s0, $a0            # starting position
	move $s1, $a1            # orientation
	move $s2, $a2            # ship size
	
validate_ai_loop:
	beq $s2, 0, validate_ai_success   # if everything checked, success
	
	# Check bottom board limits (1088-2047)
	blt $s0, 1088, validate_ai_fail   # must be after red line
	bge $s0, 2048, validate_ai_fail   # cannot go off the board
	
	# Check edges based on orientation
	beq $s1, 1, validate_ai_collision
	
	# For horizontal: check right edge
	andi $s4, $s0, 63        # position % 64 (position inside row)
	addi $s4, $s4, 4         # next position
	beq $s4, 64, validate_ai_edge   # if it would hit the edge
	b validate_ai_collision
	
validate_ai_edge:
	beq $s2, 1, validate_ai_collision   # if last pixel, ok
	b validate_ai_fail                  # otherwise would go off edge
	
validate_ai_collision:
	# Ensure there's no other ship already placed
	lw $s3, player2_ship_map($s0)
	bne $s3, 0, validate_ai_fail       # if something there (ID != 0), collision
	
	# Move to next position
	beq $s1, 0, validate_ai_horizontal
	addi $s0, $s0, 64        # vertical: next row
	b validate_ai_continue
	
validate_ai_horizontal:
	addi $s0, $s0, 4         # horizontal: next column
	
validate_ai_continue:
	addi $s2, $s2, -1        # decrement remaining size
	b validate_ai_loop
	
validate_ai_success:
	li $v0, 1                # return success
	b validate_ai_done
	
validate_ai_fail:
	li $v0, 0                # return failure
	
validate_ai_done:
	# Restore registers
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	lw $s2, 8($sp)
	lw $s3, 12($sp)
	lw $s4, 16($sp)
	lw $ra, 20($sp)
	addi $sp, $sp, 24
	jr $ra

# ============= ATTACK PHASE =============
start_attack_phase:
	# Show attack phase message
	li $v0, 4
	la $a0, attack_phase_msg
	syscall
	
	# MAKE SURE THE SEPARATOR LINES ARE PURPLE
	jal repaint_separator_lines
	
	# Check game mode
	lw $s0, game_mode
	beq $s0, 2, pve_attack_setup    # If PvE, go straight to PvE setup
	
	# Reset attempts for PvP
	li $s0, 3
	sw $s0, attempts_left

show_attack_turn:
	# MAKE SURE THE SEPARATOR LINES ARE PURPLE
	jal repaint_separator_lines
	
	# For PvE, player 1 always attacks
	lw $s0, game_mode
	beq $s0, 2, pve_player_attacks
	
	# Show whose turn it is (PvP)
	lw $s0, current_player
	beq $s0, 1, show_player1_attack
	
show_player2_attack:
	li $v0, 4
	la $a0, player2_attack_msg
	syscall
	
	# NEW: Hide player 1 ships (top board)
	jal hide_player1_ships
	
	# Player 2 attacks top board, cursor starts up top
	li $s0, 64
	sw $s0, attack_cursor
	b init_attack_cursor
	
show_player1_attack:
    	li $v0, 4
    	la $a0, player1_attack_msg
   	 syscall
    
    	# Show player 1 ships when it's their turn to attack
    	addi $sp, $sp, -4
    	sw $ra, 0($sp)
    	jal show_player1_ships
    	lw $ra, 0($sp)
    	addi $sp, $sp, 4
    
    	# Hide player 2 ships (bottom board)
    	addi $sp, $sp, -4
    	sw $ra, 0($sp)
    	jal hide_player2_ships
    	lw $ra, 0($sp)
    	addi $sp, $sp, 4
    
    	# Player 1 attacks bottom board, cursor starts below
    	li $s0, 1088
    	sw $s0, attack_cursor
    	b init_attack_cursor


pve_player_attacks:
	# In PvE, always show player 1 message
	li $v0, 4
	la $a0, player1_attack_msg
	syscall
	
	# Hide AI ships (don't show player 2 ships)
	jal hide_player2_ships
	
	# Player attacks bottom board (where AI is)
	li $s0, 1088
	sw $s0, attack_cursor
	b init_attack_cursor

pve_attack_setup:
	# MAKE SURE THE SEPARATOR LINES ARE PURPLE
	jal repaint_separator_lines
	
	# In PvE, always show player 1 message
	li $v0, 4
	la $a0, player1_attack_msg
	syscall
	
	# Hide AI ships (don't show player 2 ships)
	jal hide_player2_ships
	
	# Player attacks bottom board (where AI is)
	li $s0, 1088
	sw $s0, attack_cursor

init_attack_cursor:
	# Save the original color of the starting pixel
	lw $s0, attack_cursor
	lw $s1, display($s0)
	sw $s1, saved_pixel_color
	
	# Paint attack cursor green (both PvP and PvE)
	lw $s1, green
	sw $s1, display($s0)

# ============= ATTACK LOOP =============
attack_loop:
	# Read user input
	li $v0, 8
	la $a0, input
	li $a1, 2
	syscall
	
	lb $t5, input
	
	# Check keys
	beq $t5, 0x77, attack_up      # 'w' = move up
	beq $t5, 0x61, attack_left    # 'a' = move left
	beq $t5, 0x73, attack_down    # 's' = move down
	beq $t5, 0x64, attack_right   # 'd' = move right
	beq $t5, 0x65, fire           # 'e' = shoot
	beq $t5, 0x7A, exit           # 'z' = exit
	
	b attack_loop

# ============= ATTACK CURSOR MOVEMENT =============
attack_up:
	lw $s0, attack_cursor
	addi $s1, $s0, -64           # new position
	
	# For PvE, check player bounds
	lw $s2, game_mode
	beq $s2, 2, check_up_pve
	
	# PvP - check limits based on player
	lw $s2, current_player
	beq $s2, 1, check_up_player1
	
check_up_player2:
	# Player 2 can't go above the first row
	blt $s1, 0, attack_loop
	b move_attack_cursor_up
	
check_up_player1:
	# Player 1 can't go above the red line
	blt $s1, 1088, attack_loop
	b move_attack_cursor_up
	
check_up_pve:
	# In PvE, player attacks bottom board, can't move above red line
	blt $s1, 1088, attack_loop
	
move_attack_cursor_up:
	jal clear_attack_cursor
	sw $s1, attack_cursor
	jal paint_attack_cursor
	b attack_loop

attack_left:
	lw $s0, attack_cursor
	
	# Ensure it's not on the left edge
	andi $s1, $s0, 63
	beq $s1, 0, attack_loop
	
	addi $s1, $s0, -4
	jal clear_attack_cursor
	sw $s1, attack_cursor
	jal paint_attack_cursor
	b attack_loop

attack_right:
	lw $s0, attack_cursor
	
	# Ensure it's not on the right edge
	andi $s1, $s0, 63
	li $s2, 60
	beq $s1, $s2, attack_loop
	
	addi $s1, $s0, 4
	jal clear_attack_cursor
	sw $s1, attack_cursor
	jal paint_attack_cursor
	b attack_loop

attack_down:
	lw $s0, attack_cursor
	addi $s1, $s0, 64
	
	# For PvE, check bounds
	lw $s2, game_mode
	beq $s2, 2, check_down_pve
	
	# PvP - check bounds based on player
	lw $s2, current_player
	beq $s2, 1, check_down_player1
	
check_down_player2:
	# Player 2 can't go below the red line
	bge $s1, 960, attack_loop
	b move_attack_cursor_down
	
check_down_player1:
	# Player 1 can't go beyond the end
	bge $s1, 2048, attack_loop
	b move_attack_cursor_down
	
check_down_pve:
	# In PvE, player attacks bottom board, can't leave the board
	bge $s1, 2048, attack_loop
	
move_attack_cursor_down:
	jal clear_attack_cursor
	sw $s1, attack_cursor
	jal paint_attack_cursor
	b attack_loop

# ============= FIRE FUNCTION WITH AREA POWER-UP (FIXED) =============
fire:
	# FIRST: Check if this position has already been attacked (BEFORE random number)
	lw $s1, saved_pixel_color
	
	# Check if we've already shot here
	lw $s2, white
	beq $s1, $s2, attack_loop    # Already white (previous miss) - EXIT WITHOUT ATTACKING
	lw $s3, red
	beq $s1, $s3, attack_loop    # Already red (previous hit) - EXIT WITHOUT ATTACKING
	
	# ONLY IF NOT ATTACKED: Generate random number for power-up
	li $v0, 42           # syscall for random int range
	li $a0, 0            # generator ID
	li $a1, 7            # range 0-6 (7 possibilities)
	syscall              # result in $a0
	
	# If we get 6 (1 in 7 chance), activate area attack
	beq $a0, 6, activate_area_attack
	
# NORMAL SHOT
normal_attack:
	# DETECT WHICH SHIP WAS HIT using internal map
	lw $s0, attack_cursor
	
	# For PvE, always attack player 2 (AI) map
	lw $s3, game_mode
	beq $s3, 2, check_ai_ship_normal
	
	# PvP - check based on player
	lw $s3, current_player
	beq $s3, 1, check_player2_ship_normal
	
check_player1_ship_normal:
	# Player 2 attacks, check player 1 map
	lw $s4, player1_ship_map($s0)    # $s4 = ship ID (0=water, 1-4=ships)
	b check_ship_result_normal
	
check_player2_ship_normal:
	# Player 1 attacks, check player 2 map
	lw $s4, player2_ship_map($s0)    # $s4 = ship ID (0=water, 1-4=ships)
	b check_ship_result_normal
	
check_ai_ship_normal:
	# In PvE, player attacks AI (player 2 map)
	lw $s4, player2_ship_map($s0)    # $s4 = ship ID (0=water, 1-4=ships)
	
check_ship_result_normal:
	# If $s4 > 0, there's a ship (IDs go from 1-4)
	bgtz $s4, hit_detected_with_id   # If there is a ship (ID > 0), it's a hit
	b miss_detected              # Otherwise it's a miss

# ============= POWER-UP: 3x3 AREA ATTACK =============
# Special power-up that triggers with a 1/7 probability
# Attacks a 3x3 pattern centered on the cursor position
activate_area_attack:
	# Show special message
	li $v0, 4
	la $a0, area_attack_msg
	syscall
	
	# Attack 3x3 pattern centered on cursor
	# Pattern: [-64-4] [-64] [-64+4]
	#          [  -4 ] [ 0 ] [ +4  ]  ← 0 = current cursor
	#          [+64-4] [+64] [+64+4]
	
	lw $s0, attack_cursor        # center position
	li $s1, 0                    # hit counter in area
	
	# Attack the 9 positions in the area
	addi $sp, $sp, -8
	sw $ra, 0($sp)               # save return address
	sw $s1, 4($sp)               # save hit counter
	
	# Position 1: up-left [-64-4]
	addi $a0, $s0, -68
	jal attack_single_position
	lw $s1, 4($sp)               # load counter
	add $s1, $s1, $v0            # add result (1=hit, 0=miss)
	sw $s1, 4($sp)               # save updated counter
	
	# Position 2: up-center [-64]
	addi $a0, $s0, -64
	jal attack_single_position
	lw $s1, 4($sp)
	add $s1, $s1, $v0
	sw $s1, 4($sp)
	
	# Position 3: up-right [-64+4]
	addi $a0, $s0, -60
	jal attack_single_position
	lw $s1, 4($sp)
	add $s1, $s1, $v0
	sw $s1, 4($sp)
	
	# Position 4: center-left [-4]
	addi $a0, $s0, -4
	jal attack_single_position
	lw $s1, 4($sp)
	add $s1, $s1, $v0
	sw $s1, 4($sp)
	
	# Position 5: center [0] - current cursor
	move $a0, $s0
	jal attack_single_position
	lw $s1, 4($sp)
	add $s1, $s1, $v0
	sw $s1, 4($sp)
	
	# Position 6: center-right [+4]
	addi $a0, $s0, 4
	jal attack_single_position
	lw $s1, 4($sp)
	add $s1, $s1, $v0
	sw $s1, 4($sp)
	
	# Position 7: down-left [+64-4]
	addi $a0, $s0, 60
	jal attack_single_position
	lw $s1, 4($sp)
	add $s1, $s1, $v0
	sw $s1, 4($sp)
	
	# Position 8: down-center [+64]
	addi $a0, $s0, 64
	jal attack_single_position
	lw $s1, 4($sp)
	add $s1, $s1, $v0
	sw $s1, 4($sp)
	
	# Position 9: down-right [+64+4]
	addi $a0, $s0, 68
	jal attack_single_position
	lw $s1, 4($sp)
	add $s1, $s1, $v0
	sw $s1, 4($sp)
	
	# Check if there were hits in the area
	lw $s1, 4($sp)               # load total hit counter
	lw $ra, 0($sp)               # restore return address
	addi $sp, $sp, 8
	
	# Check victory after area attack
	jal check_victory_by_score
	beq $v0, 1, game_won
	
	# If there was AT LEAST one hit, continue turn
	bgtz $s1, attack_loop        # if counter > 0, keep attacking
	
	# If there were NO hits, treat as miss
	lw $s3, game_mode
	beq $s3, 2, area_pve_continue    # If PvE, continue without limits
	
	# PvP - decrement attempts only if there were NO hits
	lw $s3, attempts_left
	addi $s3, $s3, -1
	sw $s3, attempts_left
	
	# Show remaining attempts
	li $v0, 4
	la $a0, attempts_msg
	syscall
	
	li $v0, 1
	move $a0, $s3
	syscall
	
	li $v0, 4
	la $a0, jump
	syscall
	
	# If attempts remain, continue
	bgtz $s3, attack_loop
	
	# If no attempts remain, change turn
	b change_turn

area_pve_continue:
	# In PvE, check victory and then AI turn
	jal check_victory_by_score
	beq $v0, 1, game_won
	
	# If there were no hits in the area, AI's turn
	beqz $s1, ai_turn_after_area    # if hit counter = 0
	b attack_loop                   # if there were hits, player continues
	
ai_turn_after_area:
	jal ai_make_attack
	
	# Check if AI won
	jal check_ai_victory
	beq $v0, 1, ai_wins
	
	b attack_loop

# ============= FUNCTION TO ATTACK A SPECIFIC POSITION =============
attack_single_position:
	# $a0 = position to attack
	# RETURNS: $v0 = 1 if hit, 0 if miss/invalid
	
	# Save registers
	addi $sp, $sp, -16
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	sw $s2, 8($sp)
	sw $ra, 12($sp)
	
	move $s0, $a0            # $s0 = position to attack
	
	# Check bounds according to game mode
	lw $s1, game_mode
	beq $s1, 2, check_limits_pve_attacks
	
	# PvP - check bounds based on attacking player
	lw $s1, current_player
	beq $s1, 1, check_limits_player1_attacks
	
check_limits_player2_attacks:
	# Player 2 attacks top board (0 to 959)
	blt $s0, 0, attack_position_skip     # can't be negative
	bge $s0, 960, attack_position_skip   # can't reach red line
	b check_previous_attack
	
check_limits_player1_attacks:
	# Player 1 attacks bottom board (1088 to 2047)
	blt $s0, 1088, attack_position_skip  # must be after red line
	bge $s0, 2048, attack_position_skip  # can't leave board
	b check_previous_attack
	
check_limits_pve_attacks:
	# In PvE, player attacks bottom board (1088 to 2047)
	blt $s0, 1088, attack_position_skip  # must be after red line
	bge $s0, 2048, attack_position_skip  # can't leave board
	
check_previous_attack:
	# Check if this position has already been attacked
	lw $s1, display($s0)
	lw $s2, white
	beq $s1, $s2, attack_position_skip   # already white (previous miss)
	lw $s2, red
	beq $s1, $s2, attack_position_skip   # already red (previous hit)
	
	# Check if there's a ship in the internal map
	lw $s1, game_mode
	beq $s1, 2, check_area_ai_ship
	
	# PvP - check based on player
	lw $s1, current_player
	beq $s1, 1, check_area_player2_ship
	
check_area_player1_ship:
	# Player 2 attacks, check player 1 map
	lw $s2, player1_ship_map($s0)       # $s2 = ship ID
	b process_area_attack
	
check_area_player2_ship:
	# Player 1 attacks, check player 2 map
	lw $s2, player2_ship_map($s0)       # $s2 = ship ID
	b process_area_attack
	
check_area_ai_ship:
	# In PvE, player attacks AI (player 2 map)
	lw $s2, player2_ship_map($s0)       # $s2 = ship ID
	
process_area_attack:
	# If $s2 > 0, there's a ship
	bgtz $s2, area_hit_detected
	
	# MISS in this area position
area_miss_detected:
	lw $s1, white
	sw $s1, display($s0)             # paint white
	li $v0, 0                        # return 0 (miss)
	b attack_position_done
	
	# HIT in this area position
area_hit_detected:
	# Paint red
	lw $s1, red
	sw $s1, display($s0)
	
	# Increase score (1 point per hit) - always player 1 in PvE
	lw $s1, game_mode
	beq $s1, 2, area_update_pve_score
	
	# PvP - update based on player
	lw $s1, current_player
	beq $s1, 1, area_update_player1_score
	
area_update_player2_score:
	lw $s1, player2_score
	addi $s1, $s1, 1
	# Cap score at 34
	li $t0, 34
	ble $s1, $t0, area_p2_score_ok
	move $s1, $t0
area_p2_score_ok:
	sw $s1, player2_score
	b area_check_ship_sunk
	
area_update_player1_score:
	lw $s1, player1_score
	addi $s1, $s1, 1
	# Cap score at 34
	li $t0, 34
	ble $s1, $t0, area_p1_score_ok
	move $s1, $t0
area_p1_score_ok:
	sw $s1, player1_score
	b area_check_ship_sunk
	
area_update_pve_score:
	# In PvE, always update player 1 score
	lw $s1, player1_score
	addi $s1, $s1, 1
	# Cap score at 34
	li $t0, 34
	ble $s1, $t0, area_pve_score_ok
	move $s1, $t0
area_pve_score_ok:
	sw $s1, player1_score
	
area_check_ship_sunk:
	# Decrease health of the specific ship
	addi $s1, $s2, -1        # convert ID to index (1->0, 2->1, etc.)
	sll $s1, $s1, 2          # multiply by 4 for offset
	
	# Get health array based on mode and attacked player
	lw $t8, game_mode
	beq $t8, 2, area_decrease_ai_health
	
	# PvP - get based on attacked player
	lw $t8, current_player
	beq $t8, 1, area_decrease_player2_health
	
area_decrease_player1_health:
	lw $t9, player1_ships_health($s1)   # load current health
	addi $t9, $t9, -1                   # decrement health
	sw $t9, player1_ships_health($s1)   # store new health
	b area_check_if_sunk
	
area_decrease_player2_health:
	lw $t9, player2_ships_health($s1)   # load current health
	addi $t9, $t9, -1                   # decrement health
	sw $t9, player2_ships_health($s1)   # store new health
	b area_check_if_sunk
	
area_decrease_ai_health:
	# In PvE, always decrease AI health (player 2)
	lw $t9, player2_ships_health($s1)   # load current health
	addi $t9, $t9, -1                   # decrement health
	sw $t9, player2_ships_health($s1)   # store new health
	
area_check_if_sunk:
	# If health = 0, the ship sank (give 5-point bonus)
	bne $t9, 0, area_hit_success
	
	# SHIP SUNK in area attack - give bonus
	li $v0, 4
	la $a0, ship_sunk_msg
	syscall
	
	# Give 5 extra points based on game mode
	lw $t8, game_mode
	beq $t8, 2, area_bonus_pve
	
	# PvP - give bonus based on player
	lw $t8, current_player
	beq $t8, 1, area_bonus_player1
	
area_bonus_player2:
	lw $t8, player2_score
	addi $t8, $t8, 5
	# Cap score at 34
	li $t0, 34
	ble $t8, $t0, area_bonus_p2_ok
	move $t8, $t0
area_bonus_p2_ok:
	sw $t8, player2_score
	b area_hit_success
	
area_bonus_player1:
	lw $t8, player1_score
	addi $t8, $t8, 5
	# Cap score at 34
	li $t0, 34
	ble $t8, $t0, area_bonus_p1_ok
	move $t8, $t0
area_bonus_p1_ok:
	sw $t8, player1_score
	b area_hit_success
	
area_bonus_pve:
	# In PvE, always give bonus to player 1
	lw $t8, player1_score
	addi $t8, $t8, 5
	# Cap score at 34
	li $t0, 34
	ble $t8, $t0, area_bonus_pve_ok
	move $t8, $t0
area_bonus_pve_ok:
	sw $t8, player1_score

area_hit_success:
	li $v0, 1                        # return 1 (hit)
	b attack_position_done

attack_position_skip:
	# Position out of bounds or already attacked
	li $v0, 0                        # return 0 (miss/invalid)
	
attack_position_done:
	# Restore registers
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	lw $s2, 8($sp)
	lw $ra, 12($sp)
	addi $sp, $sp, 16
	jr $ra

# ============= MISS FUNCTION (NORMAL SHOT) =============
miss_detected:
	# Update saved color to white
	lw $s2, white
	sw $s2, saved_pixel_color
	
	# Paint white on the display
	lw $s0, attack_cursor
	sw $s2, display($s0)
	
	# Show miss message
	li $v0, 4
	la $a0, miss_msg
	syscall
	
	# Check game mode
	lw $s3, game_mode
	beq $s3, 2, pve_miss_continue   # In PvE, keep going without limits
	
	# PvP - decrement attempts
	lw $s3, attempts_left
	addi $s3, $s3, -1
	sw $s3, attempts_left
	
	# Show remaining attempts
	li $v0, 4
	la $a0, attempts_msg
	syscall
	
	li $v0, 1
	move $a0, $s3
	syscall
	
	li $v0, 4
	la $a0, jump
	syscall
	
	# If attempts remain, continue
	bgtz $s3, attack_loop
	
	# If no attempts remain, change turn
	b change_turn

pve_miss_continue:
	# In PvE, after the player's miss, it's the AI's turn
	jal ai_make_attack
	
	# Check if the AI won
	jal check_ai_victory
	beq $v0, 1, ai_wins
	
	b attack_loop

# ============= HIT FUNCTION (NORMAL SHOT) =============
hit_detected_with_id:
	# $s4 holds the ID of the ship hit (1-4)
	
	# Update saved color to red
	lw $s1, red
	sw $s1, saved_pixel_color
	
	# Paint red on the display
	lw $s0, attack_cursor
	sw $s1, display($s0)
	
	# Show hit message
	li $v0, 4
	la $a0, hit_msg
	syscall
	
	# INCREASE SCORE (1 point per hit)
	lw $s3, game_mode
	beq $s3, 2, update_pve_score_hit
	
	# PvP - update based on player
	lw $s3, current_player
	beq $s3, 1, update_player1_score_hit
	
update_player2_score_hit:
	lw $s3, player2_score
	addi $s3, $s3, 1         # +1 point for hit
	# Cap score at 34
	li $t0, 34
	ble $s3, $t0, hit_p2_score_ok
	move $s3, $t0
hit_p2_score_ok:
	sw $s3, player2_score
	b check_ship_sunk_new
	
update_player1_score_hit:
	lw $s3, player1_score
	addi $s3, $s3, 1         # +1 point per hit
	# Cap score at 34
	li $t0, 34
	ble $s3, $t0, hit_p1_score_ok
	move $s3, $t0
hit_p1_score_ok:
	sw $s3, player1_score
	b check_ship_sunk_new
	
update_pve_score_hit:
	# In PvE, always update player 1
	lw $s3, player1_score
	addi $s3, $s3, 1         # +1 point per hit
	# Cap score at 34
	li $t0, 34
	ble $s3, $t0, hit_pve_score_ok
	move $s3, $t0
hit_pve_score_ok:
	sw $s3, player1_score
	
check_ship_sunk_new:
	# DECREASE HEALTH OF THE SPECIFIC SHIP
	# $s4 = ship ID (1-4), need array index (0-3)
	addi $s5, $s4, -1        # convert ID to index (1->0, 2->1, etc.)
	sll $s5, $s5, 2          # multiply by 4 for array offset
	
	# Get health array based on mode and attacked player
	lw $s3, game_mode
	beq $s3, 2, decrease_ai_health
	
	# PvP - get based on attacked player
	lw $s3, current_player
	beq $s3, 1, decrease_player2_health
	
decrease_player1_health:
	# Player 2 attacks player 1
	lw $s6, player1_ships_health($s5)    # load current ship health
	addi $s6, $s6, -1                    # decrement health
	sw $s6, player1_ships_health($s5)    # store new health
	b check_if_sunk
	
decrease_player2_health:
	# Player 1 attacks player 2
	lw $s6, player2_ships_health($s5)    # load current ship health
	addi $s6, $s6, -1                    # decrement health
	sw $s6, player2_ships_health($s5)    # store new health
	b check_if_sunk
	
decrease_ai_health:
	# In PvE, player attacks the AI (player 2)
	lw $s6, player2_ships_health($s5)    # load current ship health
	addi $s6, $s6, -1                    # decrement health
	sw $s6, player2_ships_health($s5)    # store new health
	
check_if_sunk:
	# If health = 0, the ship sank
	beq $s6, 0, ship_sunk
	
	# Ship is not sunk yet, check overall victory
	jal check_victory_by_score
	beq $v0, 1, game_won
	
	# In PvE, after a hit (without sinking), player continues
	lw $s3, game_mode
	beq $s3, 2, attack_loop     # In PvE, player continues after a hit
	
	# Continue attacking (turn repeats)
	b attack_loop

# SHIP SUNK - GIVE EXTRA POINTS AND SHOW MESSAGE
ship_sunk:
	# Show "¡HUNDIDO!" message
	li $v0, 4
	la $a0, ship_sunk_msg
	syscall
	
	# GIVE 5 EXTRA POINTS for sinking a ship
	lw $s3, game_mode
	beq $s3, 2, bonus_pve
	
	# PvP - give bonus based on player
	lw $s3, current_player
	beq $s3, 1, bonus_player1
	
bonus_player2:
	lw $s3, player2_score
	addi $s3, $s3, 5         # +5 extra points for sinking
	# Cap score at 34
	li $t0, 34
	ble $s3, $t0, bonus_p2_score_ok
	move $s3, $t0
bonus_p2_score_ok:
	sw $s3, player2_score
	b check_victory_after_sink
	
bonus_player1:
	lw $s3, player1_score
	addi $s3, $s3, 5         # +5 extra points for sinking
	# Cap score at 34
	li $t0, 34
	ble $s3, $t0, bonus_p1_score_ok
	move $s3, $t0
bonus_p1_score_ok:
	sw $s3, player1_score
	b check_victory_after_sink
	
bonus_pve:
	# In PvE, always give bonus to player 1
	lw $s3, player1_score
	addi $s3, $s3, 5         # +5 extra points for sinking
	# Cap score at 34
	li $t0, 34
	ble $s3, $t0, bonus_pve_score_ok
	move $s3, $t0
bonus_pve_score_ok:
	sw $s3, player1_score
	
check_victory_after_sink:
	# Check victory (34 points = all ships sunk)
	jal check_victory_by_score
	beq $v0, 1, game_won
	
	# In PvE, after sinking a ship, player continues (no AI turn)
	lw $s3, game_mode
	beq $s3, 2, attack_loop     # In PvE, player continues after sinking
	
	# Continue attacking (turn repeats)
	b attack_loop

# ============= CHECK VICTORY BY SCORE =============
check_victory_by_score:
	# Check if the current player reached 34 points (total victory)
	# 14 points from hits + 20 points from sink bonuses = 34 max points
	
	lw $s0, game_mode
	beq $s0, 2, check_pve_victory
	
	# PvP - check based on current player
	lw $s0, current_player
	beq $s0, 1, check_player1_score
	
check_player2_score:
	lw $s1, player2_score
	b compare_score
	
check_player1_score:
	lw $s1, player1_score
	b compare_score
	
check_pve_victory:
	# In PvE, only check player 1
	lw $s1, player1_score
	
compare_score:
	# If score >= 34, full victory
	li $s2, 34
	bge $s1, $s2, victory_achieved
	
	# No victory yet
	li $v0, 0
	jr $ra
	
victory_achieved:
	# Victory achieved
	li $v0, 1
	jr $ra

change_turn:
	# Switch player
	lw $s0, current_player
	li $s1, 3
	sub $s0, $s1, $s0        # 3 - current_player
	sw $s0, current_player
	
	# FORCE REPAINT OF SEPARATOR LINES IN PURPLE
	jal repaint_separator_lines
	
	# NEW: Show the new player's own ships
	beq $s0, 1, show_own_ships_p1
	
show_own_ships_p2:
	jal show_player2_ships
	b reset_attempts
	
show_own_ships_p1:
    # Show player 1 ships when the turn switches to them
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    jal show_player1_ships
    lw $ra, 0($sp)
    addi $sp, $sp, 4
	
reset_attempts:
	# Reset attempts
	li $s1, 3
	sw $s1, attempts_left
	
	b show_attack_turn

# ============= GAME WON =============
game_won:
	# Show who won based on game mode
	lw $s0, game_mode
	beq $s0, 2, pve_victory
	
	# PvP - show winner based on current player
	lw $s0, current_player
	beq $s0, 1, player1_wins
	
player2_wins:
	li $v0, 4
	la $a0, player2_wins_msg
	syscall
	b show_final_score
	
player1_wins:
	li $v0, 4
	la $a0, player1_wins_msg
	syscall
	b show_final_score
	
pve_victory:
	# In PvE, player 1 always wins
	li $v0, 4
	la $a0, player1_wins_msg
	syscall
	
show_final_score:
	# Show final scores title
	li $v0, 4
	la $a0, final_scores_title
	syscall
	
	# Player 1
	li $v0, 4
	la $a0, player1_score_msg
	syscall
	
	li $v0, 1
	lw $a0, player1_score
	syscall
	
	li $v0, 4
	la $a0, jump
	syscall
	
	# In PvE, don't show player 2 (AI) score
	lw $s0, game_mode
	beq $s0, 2, show_cpu_score
	
	# Player 2 (PvP only)
	li $v0, 4
	la $a0, player2_score_msg
	syscall
	
	li $v0, 1
	lw $a0, player2_score
	syscall
	
	li $v0, 4
	la $a0, jump
	syscall
	b end_final_score
	
show_cpu_score:
	# Show CPU score in PvE
	li $v0, 4
	la $a0, cpu_score_msg
	syscall
	
	li $v0, 1
	lw $a0, player2_score      # AI uses player2_score internally
	syscall
	
	li $v0, 4
	la $a0, jump
	syscall
	
end_final_score:
	li $v0, 4
	la $a0, game_over_msg
	syscall
	
	b exit

# ============= ATTACK CURSOR FUNCTIONS =============
clear_attack_cursor:
	# Save registers
	addi $sp, $sp, -8
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	
	lw $s0, attack_cursor
	lw $s1, display($s0)
	
	# If it's green (cursor), restore the saved color
	lw $s2, green
	bne $s1, $s2, clear_cursor_done
	
	# Restore the original saved color
	lw $s1, saved_pixel_color
	sw $s1, display($s0)
	
clear_cursor_done:
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	addi $sp, $sp, 8
	jr $ra

paint_attack_cursor:
	# Save registers
	addi $sp, $sp, -8
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	
	lw $s0, attack_cursor
	
	# IMPORTANT: Save the color of the new pixel BEFORE painting it green
	lw $s1, display($s0)
	sw $s1, saved_pixel_color
	
	# Paint green
	lw $s1, green
	sw $s1, display($s0)
	
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	addi $sp, $sp, 8
	jr $ra

# =================== PAINTING AND VISUALIZATION FUNCTIONS ===================

# Paint the current ship in yellow (preview/placement mode)
paint_current_ship:
	# Save registers on stack
	addi $sp, $sp, -32
	sw $t8, 0($sp)           # ship index
	sw $t9, 4($sp)           # ship size  
	sw $s6, 8($sp)           # counter
	sw $s7, 12($sp)          # position
	sw $s4, 16($sp)          # orientation
	sw $s5, 20($sp)          # temp
	sw $ra, 24($sp)          # return address
	sw $a0, 28($sp)          # save $a0 too
	
	# Get information for the current ship
	lw $t8, current_ship     # ship index (0, 1, 2, or 3)
	sll $t9, $t8, 2          # multiply by 4 to index array
	lw $t9, ship_sizes($t9)  # get ship size
	
	move $s7, $t4            # starting position = cursor position
	lw $s4, orientation      # load current orientation
	move $s6, $t9            # counter = ship size
	
paint_ship_loop:
	beq $s6, 0, paint_ship_done   # if counter = 0, finish
	sw $t3, display($s7)     # paint yellow pixel at current position
	
	addi $s6, $s6, -1        # decrement counter
	beq $s6, 0, paint_ship_done   # if done, exit
	
	# Calculate next position based on orientation
	beq $s4, 0, paint_horizontal  # if orientation = 0, move horizontally
	addi $s7, $s7, 64        # vertical: move one row down
	b paint_ship_loop
	
paint_horizontal:
	addi $s7, $s7, 4         # horizontal: move one pixel to the right
	b paint_ship_loop
	
paint_ship_done:
	# Restore stack registers
	lw $t8, 0($sp)
	lw $t9, 4($sp)
	lw $s6, 8($sp)
	lw $s7, 12($sp)
	lw $s4, 16($sp)
	lw $s5, 20($sp)
	lw $ra, 24($sp)
	lw $a0, 28($sp)
	addi $sp, $sp, 32
	jr $ra                   # return

# Erase the current ship (restore to blue, BUT do not touch gray ships already placed)
clear_current_ship:
	# Save registers
	addi $sp, $sp, -32
	sw $t8, 0($sp)
	sw $t9, 4($sp)
	sw $s6, 8($sp)
	sw $s7, 12($sp)
	sw $s4, 16($sp)
	sw $s5, 20($sp)
	sw $ra, 24($sp)
	sw $a0, 28($sp)
	
	# Get information for the current ship
	lw $t8, current_ship
	sll $t9, $t8, 2
	lw $t9, ship_sizes($t9)  # ship size
	
	move $s7, $t4            # starting position
	lw $s4, orientation      # orientation
	move $s6, $t9            # counter
	
clear_ship_loop:
	beq $s6, 0, clear_ship_done
	
	# ENSURE it's not a gray ship before painting blue
	lw $s5, display($s7)     # read current color
	beq $s5, $t7, clear_skip # if gray (placed ship), DO NOT touch
	
	sw $t0, display($s7)     # use $t0 (blue) directly
	
clear_skip:
	addi $s6, $s6, -1
	beq $s6, 0, clear_ship_done
	
	# Move to next position (same algorithm as paint)
	beq $s4, 0, clear_horizontal
	addi $s7, $s7, 64        # vertical
	b clear_ship_loop
	
clear_horizontal:
	addi $s7, $s7, 4         # horizontal
	b clear_ship_loop
	
clear_ship_done:
	# Restaurar registros
	lw $t8, 0($sp)
	lw $t9, 4($sp)
	lw $s6, 8($sp)
	lw $s7, 12($sp)
	lw $s4, 16($sp)
	lw $s5, 20($sp)
	lw $ra, 24($sp)
	lw $a0, 28($sp)
	addi $sp, $sp, 32
	jr $ra

# Place the ship permanently (turn gray and store ID in internal map)
place_current_ship:
	# Save registers
	addi $sp, $sp, -32
	sw $t8, 0($sp)           # ship index
	sw $t9, 4($sp)           # ship size
	sw $s6, 8($sp)           # pixel counter
	sw $s7, 12($sp)          # current position  
	sw $s4, 16($sp)          # orientation
	sw $s5, 20($sp)          # temp
	sw $ra, 24($sp)
	sw $a0, 28($sp)
	
	# Get information for the current ship
	lw $t8, current_ship     # ship index (0, 1, 2, 3)
	sll $t9, $t8, 2          # multiply by 4 to index array
	lw $t9, ship_sizes($t9)  # ship size
	
	move $s7, $t4            # starting position
	lw $s4, orientation      # orientation
	move $s6, $t9            # counter
	
	# CALCULATE SHIP ID: current_ship + 1 (1=carrier, 2=battleship, etc.)
	addi $s5, $t8, 1         # Ship ID (1-4)
	
place_ship_loop:
	beq $s6, 0, place_ship_done   # if counter = 0, finish
	
	# Paint GRAY pixel (visual)
	sw $t7, display($s7)
	
	# Store ship ID in the appropriate map (for hit detection)
	lw $t8, current_player
	beq $t8, 1, save_player1_map
	
save_player2_map:
	# Save ship ID in player 2 map
	sw $s5, player2_ship_map($s7)   # $s5 = ship ID (1-4)
	b continue_place_loop
	
save_player1_map:
	# Save ship ID in player 1 map
	sw $s5, player1_ship_map($s7)   # $s5 = ship ID (1-4)
	
continue_place_loop:
	addi $s6, $s6, -1        # decrement counter
	beq $s6, 0, place_ship_done   # if done, exit
	
	# Move to next position
	beq $s4, 0, place_horizontal
	addi $s7, $s7, 64        # vertical
	b place_ship_loop
	
place_horizontal:
	addi $s7, $s7, 4         # horizontal
	b place_ship_loop
	
place_ship_done:
	# Restaurar registros
	lw $t8, 0($sp)
	lw $t9, 4($sp)
	lw $s6, 8($sp)
	lw $s7, 12($sp)
	lw $s4, 16($sp)
	lw $s5, 20($sp)
	lw $ra, 24($sp)
	lw $a0, 28($sp)
	addi $sp, $sp, 32
	jr $ra

# =================== VALIDATION SUBROUTINES ===================

# Check if it can move up
can_move_up:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	addi $t8, $t4, -64       # calculate new position (one row up)
	jal check_position_valid # verify if that position is valid
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra                   # return with result in $v0

# Check if it can move left
can_move_left:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	addi $t8, $t4, -4        # calculate new position (one pixel to the left)
	jal check_position_valid
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

# Check if it can move right
can_move_right:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	addi $t8, $t4, 4         # calculate new position (one pixel to the right)
	jal check_position_valid
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

# Check if it can move down
can_move_down:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	addi $t8, $t4, 64        # calculate new position (one row down)
	jal check_position_valid
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

# Check if the current position is valid (for rotation)
is_valid_position:
	move $t8, $t4            # use current cursor position
	# continues executing check_position_valid

# Check if a specific position is valid for the whole ship
check_position_valid:
	# $t8 contains the position to verify
	addi $sp, $sp, -12
	sw $s1, 0($sp)           # counter
	sw $s2, 4($sp)           # position being checked
	sw $s3, 8($sp)           # orientation
	
	# Get information for the current ship
	lw $s1, current_ship
	sll $s2, $s1, 2
	lw $s1, ship_sizes($s2)  # ship size in $s1
	
	move $s2, $t8            # starting position to verify
	lw $s3, orientation      # current orientation
	
	# *** NEW CHECK: starting position must not be gray ***
	lw $t9, display($s2)
	beq $t9, $t7, check_invalid     # if cursor is over gray ship, invalid
	
check_loop:
	beq $s1, 0, check_valid  # if all pixels checked, it's valid
	
	# Check board limits based on player
	lw $t9, current_player
	beq $t9, 1, check_player1_bounds
	
check_player2_bounds:
	# Player 2: must be after red line
	blt $s2, 1088, check_invalid    # must be after red line
	bge $s2, 2048, check_invalid    # can't go off the board
	b check_edges
	
check_player1_bounds:
	# Player 1: must be before red line
	blt $s2, 0, check_invalid       # can't be negative
	bge $s2, 960, check_invalid     # can't cross the red line (row 15)
	
check_edges:
	# Check edges based on orientation
	beq $s3, 1, check_collision
	
	# For horizontal orientation: check right edge
	andi $t9, $s2, 63        # $s2 % 64 (position within the row)
	addi $t9, $t9, 4         # next position
	beq $t9, 64, check_edge  # if it would reach the edge, special check
	b check_collision
	
check_edge:
	beq $s1, 1, check_collision  # if it's the last pixel of the ship, ok
	b check_invalid              # otherwise it would go off edge

check_collision:
	# Check collisions with existing ships
	lw $t9, display($s2)
	beq $t9, $t7, check_invalid     # if there's a gray ship (placed), collision
	lw $t8, purple
	beq $t9, $t8, check_invalid     # if it's the purple line, invalid
	
	# Move to next ship position
	beq $s3, 0, check_horizontal
	addi $s2, $s2, 64        # vertical: next row
	b check_continue
	
check_horizontal:
	addi $s2, $s2, 4         # horizontal: next column
	
check_continue:
	addi $s1, $s1, -1        # decrement counter
	b check_loop             # check next pixel

check_valid:
	li $v0, 1                # return 1 (valid)
	b check_done

check_invalid:
	li $v0, 0                # return 0 (invalid)

check_done:
	# Restore registers
	lw $s1, 0($sp)
	lw $s2, 4($sp)
	lw $s3, 8($sp)
	addi $sp, $sp, 12
	jr $ra

# ============= FUNCTIONS TO HIDE/SHOW SHIPS =============

# Hide player 1 ships (turn grays back to blue on top board)
hide_player1_ships:
	addi $sp, $sp, -12
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	sw $ra, 8($sp)
	
	li $s0, 0                # starting position (top board)
	li $s1, 960              # ending position (before red line)
	
hide_p1_loop:
	bge $s0, $s1, hide_p1_done
	
	# If pixel is gray (ship), change it to blue
	lw $s2, display($s0)
	bne $s2, $t7, hide_p1_continue   # if not gray, continue
	
	sw $t0, display($s0)     # change to blue
	
hide_p1_continue:
	addi $s0, $s0, 4
	b hide_p1_loop
	
hide_p1_done:
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	lw $ra, 8($sp)
	addi $sp, $sp, 12
	jr $ra

# Hide player 2 ships (turn grays back to blue on bottom board)
hide_player2_ships:
	addi $sp, $sp, -12
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	sw $ra, 8($sp)
	
	li $s0, 1088             # starting position (after red line)
	li $s1, 2048             # ending position
	
hide_p2_loop:
	bge $s0, $s1, hide_p2_done
	
	# If pixel is gray (ship), change it to blue
	lw $s2, display($s0)
	bne $s2, $t7, hide_p2_continue   # if not gray, continue
	
	sw $t0, display($s0)     # change to blue
	
hide_p2_continue:
	addi $s0, $s0, 4
	b hide_p2_loop
	
hide_p2_done:
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	lw $ra, 8($sp)
	addi $sp, $sp, 12
	jr $ra

# Show player 1 ships (restore grays where there are ships in the map)
show_player1_ships:
	addi $sp, $sp, -12
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	sw $ra, 8($sp)
	
	li $s0, 0                # starting position
	li $s1, 960              # ending position
	
show_p1_loop:
	bge $s0, $s1, show_p1_done
	
	# If there's a ship in the map (ID > 0) and the pixel hasn't been attacked
	lw $s2, player1_ship_map($s0)
	beq $s2, 0, show_p1_continue     # if no ship (ID=0), continue
	
	lw $s3, display($s0)
	lw $s4, red
	beq $s3, $s4, show_p1_continue   # if red (attacked), leave it
	lw $s4, white
	beq $s3, $s4, show_p1_continue   # if white (attacked), leave it
	
	sw $t7, display($s0)     # restore gray
	
show_p1_continue:
	addi $s0, $s0, 4
	b show_p1_loop
	
show_p1_done:
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	lw $ra, 8($sp)
	addi $sp, $sp, 12
	jr $ra

# Show player 2 ships (restore grays where there are ships in the map)
show_player2_ships:
	addi $sp, $sp, -12
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	sw $ra, 8($sp)
	
	li $s0, 1088             # starting position
	li $s1, 2048             # ending position
	
show_p2_loop:
	bge $s0, $s1, show_p2_done
	
	# If there's a ship in the map (ID > 0) and the pixel hasn't been attacked
	lw $s2, player2_ship_map($s0)
	beq $s2, 0, show_p2_continue     # if no ship (ID=0), continue
	
	lw $s3, display($s0)
	lw $s4, red
	beq $s3, $s4, show_p2_continue   # if red (attacked), leave it
	lw $s4, white
	beq $s3, $s4, show_p2_continue   # if white (attacked), leave it
	
	sw $t7, display($s0)     # restore gray
	
show_p2_continue:
	addi $s0, $s0, 4
	b show_p2_loop
	
show_p2_done:
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	lw $ra, 8($sp)
	addi $sp, $sp, 12
	jr $ra

# ============= FUNCTION TO REPAINT SEPARATOR LINES =============
repaint_separator_lines:
	addi $sp, $sp, -12
	sw $s0, 0($sp)
	sw $s1, 4($sp)           # save original $t2
	sw $ra, 8($sp)
	
	move $s1, $t2            # save original $t2 value (red)
	li $t2, 0x800080         # temporarily switch to purple
	
	# Repaint purple separating line (2 rows: 15 and 16)
	li $s0, 960              # start on row 15 (15 × 64 = 960)
	
repaint_row1:
	sw $t2, display($s0)     # paint purple pixel
	addi $s0, $s0, 4         # next pixel
	beq $s0, 1024, repaint_row2  # after row 15, go to row 16
	b repaint_row1
	
repaint_row2:
	sw $t2, display($s0)     # paint purple pixel
	addi $s0, $s0, 4         # next pixel
	beq $s0, 1088, repaint_done  # after row 16, finish
	b repaint_row2

repaint_done:
	move $t2, $s1            # restore original $t2 value (red)
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	lw $ra, 8($sp)
	addi $sp, $sp, 12
	jr $ra

# ============= ARTIFICIAL INTELLIGENCE (HUNT & TARGET ALGORITHM) =============

# Main AI attack function
# Implements the "Hunt & Target" algorithm:
# - HUNT: Random attack until a ship is found
# - TARGET: Systematic exploration around the hit until it sinks
ai_make_attack:
	# Save registers
	addi $sp, $sp, -8
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	
	# Check AI mode
	lw $s0, ai_mode
	beq $s0, 0, ai_hunt_mode
	beq $s0, 1, ai_target_mode
	
ai_hunt_mode:
	# Hunting mode: random attack until a ship is found
	jal ai_hunt_random
	b ai_attack_done
	
ai_target_mode:
	# Targeting mode: directed attack around the hit
	jal ai_target_ship
	b ai_attack_done
	
ai_attack_done:
	# Restore registers and return
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	addi $sp, $sp, 8
	jr $ra

# HUNT MODE: Generate random attacks
ai_hunt_random:
	# Save registers
	addi $sp, $sp, -12
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	
hunt_retry:
	# Generate random position on top board (0-959)
	jal generate_random_position
	move $s0, $v0            # $s0 = generated position
	
	# Check if already attacked (don't lose turn on invalid positions)
	move $a0, $s0
	jal is_position_already_attacked
	beq $v0, 1, hunt_retry   # If already attacked, generate another position
	
	# Attack the valid position
	move $a0, $s0
	jal ai_attack_position
	
	# If it was a hit, switch to targeting mode
	beq $v0, 1, switch_to_targeting
	
	# If it was a miss, continue hunting
	b hunt_done
	
switch_to_targeting:
	# Switch to targeting mode
	li $s1, 1
	sw $s1, ai_mode
	
	# Save hit position for exploration
	sw $s0, ai_target_pos
	sw $s0, ai_original_hit
	
	# Reset direction and steps
	sw $zero, ai_direction
	sw $zero, ai_steps_in_direction
	
hunt_done:
	# Restore registers
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	addi $sp, $sp, 12
	jr $ra

# TARGET MODE: Systematic exploration around hits
# This function explores adjacent directions (up, right, down, left)
# one per turn until the entire ship is found or all are exhausted
ai_target_ship:
	# Save registers
	addi $sp, $sp, -16
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	
	lw $s0, ai_target_pos     # current target position
	lw $s1, ai_direction      # current direction (0=up, 1=right, 2=down, 3=left)
	
	# Find the next valid position to attack (one attack per turn)
find_valid_target:
	# Ensure there are still directions to try
	bge $s1, 4, no_more_directions
	
	# Get adjacent position in current direction
	move $a0, $s0            # base position
	move $a1, $s1            # direction
	jal get_adjacent_position
	
	# Check board limits (top board for attacking player)
	blt $v0, 0, try_next_direction_immediately       # out of bounds
	bge $v0, 960, try_next_direction_immediately     # outside top board
	
	move $s2, $v0            # $s2 = adjacent position
	
	# Check horizontal edges (avoid wrapping between rows)
	beq $s1, 1, check_right_edge    # right direction
	beq $s1, 3, check_left_edge     # left direction
	b check_if_attacked
	
check_right_edge:
	# Ensure it doesn't wrap past the right edge
	andi $t0, $s0, 63        # position % 64 (position in row)
	andi $t1, $s2, 63        # new position % 64
	blt $t1, $t0, try_next_direction_immediately   # wrapped to next row
	b check_if_attacked
	
check_left_edge:
	# Ensure it doesn't wrap past the left edge
	andi $t0, $s0, 63        # position % 64
	andi $t1, $s2, 63        # new position % 64
	bgt $t1, $t0, try_next_direction_immediately   # wrapped to previous row
	
check_if_attacked:
	# Check if it was already attacked (don't lose turn)
	move $a0, $s2
	jal is_position_already_attacked
	beq $v0, 1, try_next_direction_immediately   # already attacked, next direction WITHOUT losing turn
	
	# Found a valid position! Attack ONCE and end turn
	move $a0, $s2
	jal ai_attack_position
	
	beq $v0, 1, target_hit_continue   # if hit, continue in that direction
	beq $v0, 2, target_ship_sunk      # if ship sunk, return to hunting
	beq $v0, 0, target_miss_continue  # if miss, next direction
	
target_hit_continue:
	# Hit! Continue in this direction NEXT turn
	sw $s2, ai_target_pos    # update target position
	
	lw $s0, ai_steps_in_direction
	addi $s0, $s0, 1
	sw $s0, ai_steps_in_direction
	
	b target_done
	
target_ship_sunk:
	# Ship sunk - return to hunting mode
	sw $zero, ai_mode
	sw $zero, ai_direction
	sw $zero, ai_steps_in_direction
	b target_done
	
target_miss_continue:
	# Miss - change direction for the NEXT turn
	addi $s1, $s1, 1         # next direction
	sw $s1, ai_direction     # store new direction
	
	# Reset to original position for new direction
	lw $s0, ai_original_hit
	sw $s0, ai_target_pos
	sw $zero, ai_steps_in_direction
	
	b target_done
	
try_next_direction_immediately:
	# Invalid or already-attacked position - try next direction IMMEDIATELY (same turn)
	addi $s1, $s1, 1         # next direction
	
	# Reset to original position for new direction
	lw $s0, ai_original_hit
	sw $zero, ai_steps_in_direction
	
	# Find next valid position WITHOUT ending the turn
	b find_valid_target
	
no_more_directions:
	# No directions left without finding anything, return to hunting
	sw $zero, ai_mode
	sw $zero, ai_direction
	sw $zero, ai_steps_in_direction
	
target_done:
	# Restore registers
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	addi $sp, $sp, 16
	jr $ra

# ============= AI HELPER FUNCTIONS =============

# Generate random position on top board (where the player's ships are)
generate_random_position:
	# Save registers
	addi $sp, $sp, -8
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	
	li $v0, 42               # syscall for random
	li $a0, 1                # generator ID
	li $a1, 240              # range 0-239 (240 positions = 15 rows × 16 columns)
	syscall
	
	# Convert linear index to display position
	# position = (row * 64) + (column * 4)
	move $s0, $a0            # $s0 = linear index (0-239)
	
	# Calculate row = index / 16
	li $s1, 16
	div $s0, $s1
	mflo $s1                 # $s1 = row (0-14)
	
	# Calculate column = index % 16  
	mfhi $s0                 # $s0 = column (0-15)
	
	# Convert to display position
	sll $s1, $s1, 6          # row * 64
	sll $s0, $s0, 2          # column * 4
	add $v0, $s1, $s0        # final position
	
	# Restore registers
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	addi $sp, $sp, 8
	jr $ra

# Check if position has already been attacked (to avoid lost turns)
is_position_already_attacked:
	# Input: $a0 = position to check
	# Output: $v0 = 1 if already attacked, 0 if free
	lw $t0, display($a0)
	lw $t1, white
	beq $t0, $t1, position_attacked    # white = already attacked (miss)
	lw $t1, red
	beq $t0, $t1, position_attacked    # red = already attacked (hit)
	li $v0, 0                          # free
	jr $ra
position_attacked:
	li $v0, 1                          # already attacked
	jr $ra

# Get adjacent position based on direction
get_adjacent_position:
	# Input: $a0 = base position, $a1 = direction (0=up, 1=right, 2=down, 3=left)
	# Output: $v0 = adjacent position
	
	beq $a1, 0, adjacent_up
	beq $a1, 1, adjacent_right
	beq $a1, 2, adjacent_down
	beq $a1, 3, adjacent_left
	
adjacent_up:
	addi $v0, $a0, -64       # one row up
	jr $ra
	
adjacent_right:
	addi $v0, $a0, 4         # one column right
	jr $ra
	
adjacent_down:
	addi $v0, $a0, 64        # one row down
	jr $ra
	
adjacent_left:
	addi $v0, $a0, -4        # one column left
	jr $ra

# Attack a specific position (for the AI)
ai_attack_position:
	# Input: $a0 = position to attack
	# Output: $v0 = 1 if hit, 0 if miss, 2 if ship sunk
	
	# Save registers
	addi $sp, $sp, -12
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	sw $ra, 8($sp)
	
	move $s0, $a0            # position to attack
	
	# Check if there's a ship on player 1 map
	lw $s1, player1_ship_map($s0)
	
	bgtz $s1, ai_hit_detected
	
	# MISS
ai_miss_detected:
	lw $t0, white
	sw $t0, display($s0)     # paint white
	li $v0, 0                # return miss
	b ai_attack_position_done
	
	# HIT
ai_hit_detected:
	lw $t0, red
	sw $t0, display($s0)     # paint red
	
	# Increase AI score (player 2)
	lw $t0, player2_score
	addi $t0, $t0, 1
	# Cap score at 34
	li $t1, 34
	ble $t0, $t1, ai_hit_score_ok
	move $t0, $t1
ai_hit_score_ok:
	sw $t0, player2_score
	
	# Decrease ship health
	addi $t0, $s1, -1        # convert ID to index
	sll $t0, $t0, 2          # multiply by 4
	lw $t1, player1_ships_health($t0)
	addi $t1, $t1, -1
	sw $t1, player1_ships_health($t0)
	
	# Check if ship sank
	beq $t1, 0, ai_ship_sunk
	
	li $v0, 1                # return hit
	b ai_attack_position_done
	
ai_ship_sunk:
	# Ship sunk - give AI bonus and return to hunting mode
	lw $t0, player2_score
	addi $t0, $t0, 5         # bonus for sinking
	# Cap score at 34
	li $t1, 34
	ble $t0, $t1, ai_sunk_score_ok
	move $t0, $t1
ai_sunk_score_ok:
	sw $t0, player2_score
	
	# Show message
	li $v0, 4
	la $a0, ship_sunk_msg
	syscall
	
	# Return to hunting mode
	sw $zero, ai_mode
	sw $zero, ai_direction
	sw $zero, ai_steps_in_direction
	
	li $v0, 2                # return ship sunk
	
ai_attack_position_done:
	# Restore registers
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	lw $ra, 8($sp)
	addi $sp, $sp, 12
	jr $ra

# Check if the AI won
check_ai_victory:
	# In PvE, check if the AI (player 2) reached 34 points
	lw $s0, player2_score
	li $s1, 34
	bge $s0, $s1, ai_victory_achieved
	
	li $v0, 0                # no victory
	jr $ra
	
ai_victory_achieved:
	li $v0, 1                # AI victory
	jr $ra

# Show AI victory
ai_wins:
	# In PvE, the AI (CPU) won
	li $v0, 4
	la $a0, cpu_wins_msg
	syscall
	
	b show_final_score

# ============= PROGRAM EXIT =============
exit:
	li $v0, 10               # syscall to end program
	syscall
