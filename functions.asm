##################################
# Part 1 - String Functions
##################################

# ===== int is_whitespace(char c); ===== #
is_whitespace:
	# ===== PROLOGUE ===== #
	# NONE

	#  ============ INITIALIZE VARIABLES ============ #
	li $v0, 1		# Initial return value = 1 (true)
	
	# ========================== WHITESPACE CHECK ========================== #
	beq $a0, '\0', is_whitespace_DONE	# Check if c = NULL
	beq $a0, '\n', is_whitespace_DONE	# Check if c = Newline
	beq $a0, ' ', is_whitespace_DONE	# Check if c = Space
	li $v0, 0							# Return false (0). c != whitespace 
	
	# =========== EPILOGUE ============ #
	# NONE
	is_whitespace_DONE:
		jr $ra		# Return to caller

# ===== int cmp_whitespace(char c1, char c2); ===== #
cmp_whitespace:
	# =============== PROLOGUE =============== #
	addi $sp, $sp, -4
	sw $ra, 0($sp)		# Store return address

	# ============== INITIALIZE VARIABLES ================= #
	li $v0, 0			# Initial return value = 0 (false)
	
	# ================================ CHECK WHITESPACE ================================ #
	jal is_whitespace				# Check if c1 is a whitespace character
	beqz $v0, cmp_whitespace_DONE	# If not, return false
	move $a0, $a1						
	jal is_whitespace				# Check if c2 is a whitespace character
	beqz $v0, cmp_whitespace_DONE	# If not, return false
	li $v0, 1						# c1 & c2 = whitespace character, return 1 (true)
	
	# ============= EPILOGUE ============= #
	cmp_whitespace_DONE:
		lw $ra, 0($sp)				# Restore $ra
		addi $sp, $sp, 4		
		jr $ra						# Return to caller

# ===== void strcpy(String source, String dest, int n); ===== #
strcpy:
	# ===== PROLOGUE ===== #
	# NONE

	# ===================== CHECK ARGUMENT ADDRESS ===================== #
	ble $a0, $a1, strcpy_DONE		# If src addr < dest addr, do nothing
	
	# =========================== COPY STRING =========================== #
	strcpy_LOOP:
		lbu $t1, 0($a0)				# Load byte from source String
		sb $t1, 0($a1)				# Store byte to destination String
		addi $a0, $a0, 2			# Go to next byte in source String
		addi $a1, $a1, 2			# Go to next byte in destination String
		addi $a2, $a2, -1			# Decrement n
		bgtz $a2, strcpy_LOOP		# While n != 0, keep copying bytes
	
	# =========== EPILOGUE =========== #
	# NONE
	strcpy_DONE:
	jr $ra			# Return to caller

# ===== int strlen(String s); ===== #
strlen:
	# ================ PROLOGUE ================ #
	addi $sp, $sp, -12
	sw $ra, 0($sp)		# Store return address
	sw $s0, 4($sp)		# Store $s0
	sw $s1, 8($sp)		# Store $s1
	
	# ================ INITIALIZE VARIABLES ================ #
	li $s0, 0			# Initialize length counter
	move $s1, $a0		# Make a copy of the String s Addr 
	
	# ===================================================================== #
	strlen_LOOP:
		lbu $a0, 0($s1)		    # Load next character in the String s
		jal is_whitespace	    # Check if char is whitespace (end of String)
		bnez $v0, strlen_DONE  	# If byte is whitespace, return length ($s0)
		addi $s0, $s0, 1		# Increment length counter
		addi $s1, $s1, 1		# Go to next byte of String
		j strlen_LOOP		  	# Stay in loop until whitespace is reached
	
	strlen_DONE:
	move $v0, $s0			 	# Copy count to return register $v0
	# ================= EPILOGUE ================= #
		lw $s1, 8($sp)		# Restore $s1
		lw $s0, 4($sp)		# Restore $s0
		lw $ra, 0($sp)		# Restore return address
		addi $sp, $sp, 12		
		jr $ra				# Return to caller

##################################
# Part 2 - vt100 MMIO Functions
##################################

# ===== void set_state_color(struct state, byte color, int category, int mode); ===== #
set_state_color:
	# ================ PROLOGUE ================ #
	# NONE
	
	# ==================== DETERMINE MODE ==================== #
	beqz $a3, mode_0		# If mode 0
	beq $a3, 1, mode_1		# If mode 1
	beq $a3, 2, mode_2 		# If mode 2
		
	# ================================ MODE 0 ================================ #
	mode_0:
		beqz $a2, default_0			# If 0, default_bg & fg = color
		j highlight_0				# Otherwise, hightlight_bg & fg = color
		
		default_0:
			sb $a1, 0($a0)			# Store the updated color
			j set_state_color_DONE

		highlight_0:
			sb $a1, 1($a0)			# Store the updated color
			j set_state_color_DONE
		
	# ============================= MODE 1 ============================= #
	mode_1:
		beqz $a2, default_1		# If 0, default_fg = color
		j highlight_1			# Otherwise, hightlight_fg = color
		
		default_1:
		lbu $t1, 0($a0)			# Get the full current default color
		andi $t1, $t1, 0xF0		# Mask out the background color
		or $t0, $a1, $t1		# Put the fg and bg colors together 
		sb $t0, 0($a0)			# Store the updated color
		j set_state_color_DONE
		
		highlight_1:
		lbu $t1, 1($a0)			# Get the full current default color
		andi $t1, $t1, 0xF0		# Mask out the background color
		or $t0, $a1, $t1			# Put the fg and bg colors together 
		sb $t0, 1($a0)			# Store the updated color
		j set_state_color_DONE
		
	# ========================== MODE 2 ========================== #
	mode_2:
		beqz $a2, default_2		# If 0, default_bg = color
		j highlight_2			# Otherwise, hightlight_bg = color
		
		default_2:
		lbu $t1, 0($a0)			# Get the full current default color
		andi $t1, $t1, 0x0F		# Mask out the foreground color
		or $t0, $a1, $t1		# Put the fg and bg colors together 
		sb $t0, 0($a0)			# Store the updated color
		j set_state_color_DONE
		
		highlight_2:
		lbu $t1, 1($a0)			# Get the full current default color
		andi $t1, $t1, 0x0F		# Mask out the foreground color
		or $t0, $a1, $t1		# Put the fg and bg colors together 
		sb $t0, 1($a0)			# Store the updated color
	
	# ================= EPILOGUE ================= #
	# NONE
	set_state_color_DONE:
	 jr $ra						# Return to caller

# ===== void save_char(struct state, char c); ===== #
save_char:
	# ================ PROLOGUE ================ #
	# NONE
	
	# ============== CALCULATE POSITION ADDRESS ============== #
	li $t0, 80			# Number of columns
	li $t1, 0xFFFF0000	# Base Address of VT100 MMIO
	lbu $t2, 2($a0)		# Get cursor position x
	lbu $t3, 3($a0)		# Get cursor position y
	mul $t4, $t0, $t2	# Multiply columns with x
	add $t4, $t4, $t3	# Add y
	sll $t4, $t4, 1   	# Multiply by size of cell (2-bytes)
	add $t4, $t4, $t1	# Add Base Address
	sb $a1, 0($t4)		# Update char at (x,y) 
	
	# ============ EPILOGUE ============ #
	# NONE
	save_char_DONE:
		jr $ra			# Return to caller

# ===== void reset(struct state, int color_only); ===== #
reset:
	# ================ PROLOGUE ================ #
	# NONE

	# ============= INITIALIZE VARIABLES ================ #
	li $t0, 0xFFFF0000	# Base Address of VT100 MMIO
	li $t1, 25			# Number of rows
	li $t2, 80			# Number of columns
	lbu $t3, 0($a0)		# Get default_color byte
	li $t4, 0			# Row counter initialized to 0
	
	# ======================= RESET ========================= #
	reset_row_LOOP:
		li $t5, 0		# Re-initialize Column counter to 0
	reset_column_LOOP:
		# ================= UPDATE CELL ================= #
		beqz $a1, reset_ascii_and_color 
		j reset_color
		reset_ascii_and_color:
			sb $zero, 0($t0)		# Update char to null
			sb $t3, 1($t0)		    # Update default_color
			j next_column
	    reset_color:
			sb $t3, 1($t0)		    # Update default_color
			
		next_column:
			addi $t0, $t0, 2		# Go to next cell
			addi $t5, $t5, 1		# column++
			blt $t5, $t2, reset_column_LOOP
	reset_column_loop_DONE:
		addi $t4, $t4, 1			# row++
		blt $t4, $t1, reset_row_LOOP
	
	# ============== EPILOGUE ============== #
	# NONE
	reset_DONE:
		jr $ra			# Return to caller

# ===== void clear_line(byte x, byte y, byte color); ===== #
clear_line:
	# ================ PROLOGUE ================ #
	# NONE

	# ============= INITIALIZE VARIABLES ================ #
	li $t0, 0xFFFF0000	# Base Address of VT100 MMIO
	li $t1, 25			# Number of rows
	li $t2, 80			# Number of columns
	
	# =============== CALCULATE POSITION ADDRESS =============== #
	mul $t3, $a0, $t2	# Multiply # of columns with position x
	add $t3, $t3, $a1	# Add position y
	sll $t3, $t3, 1   	# Multiply by size of cell (2-bytes)
	add $t3, $t3, $t0	# Add Base Address
	
	# =========================== CLEAR LINE =========================== #
	li $t4, '\0'	# Null char used to clear ascii byte of cell
	clear_line_LOOP:
		sb $t4, 0($t3)					# Clear ascii byte of cell
		sb $a2, 1($t3)					# Update cell color
		addi $t3, $t3, 2				# Go to next cell
		addi $a1, $a1, 1				# Increment counter
		blt $a1, $t2, clear_line_LOOP	# Until end of line is reached
	
	# ============== EPILOGUE ============== #
	# NONE
	clear_line_DONE:
		jr $ra			# Return to caller

# ===== void set_cursor(struct state, byte x, byte y, int initial); ===== #
set_cursor:
	# ================ PROLOGUE ================ #
	# NONE

	# ============= INITIALIZE VARIABLES ================ #
	li $t0, 0xFFFF0000	# Base Address of VT100 MMIO
	li $t1, 80			# Number of columns

	# ============================== UPDATE CURSOR ============================== #
	beqz $a3, clear_original_cursor		# Skip clearing the original cursor ...
	j update_cursor_position		 	# ... if initial = 1

	clear_original_cursor:
		lbu $t2, 2($a0)		# Get original position x 
		lbu $t3, 3($a0)		# Get original position y
		mul $t4, $t1, $t2	# Multiply # of columns with position x
		add $t4, $t4, $t3	# Add position y
	    sll $t4, $t4, 1   	# Multiply by size of cell (2-bytes)
		add $t4, $t4, $t0	# Add Base Address
		lbu $t5, 1($t4)		# Get color byte of original location 
		xori $t5, $t5, 0x88	# Toggle the bold bit of the color byte
		sb $t5, 1($t4)		# Put updated color byte back into cell 
	
	update_cursor_position:
		sb $a1, 2($a0)		# Update position x
		sb $a2, 3($a0)		# Update position y
	
	show_new_cursor:
		mul $t6, $t1, $a1	# Multiply # of columns with position x
		add $t6, $t6, $a2	# Add position y
		sll $t6, $t6, 1   	# Multiply by size of cell (2-bytes)
		add $t6, $t6, $t0	# Add Base Address
		lbu $t7, 1($t6)		# Get color byte of new location
		xori $t7, $t7, 0x88	# Toggle the bold bit of the color byte
		sb $t7, 1($t6)		# Put updated color byte back into cell 
	
	# ============== EPILOGUE ============== #
	# NONE
	set_cursor_DONE:
		jr $ra			# Return to caller

# ===== void move_cursor(struct state, char direction); ===== #
move_cursor:
	# ================ PROLOGUE ================ #
	addi $sp, $sp, -4
	sw $ra, 0($sp)		# Store Return Address

	# ========= INITIALIZE VARIABLES ============ #
	li $a3, 0			# Initial is always 0
	lbu $t0, 2($a0)		# Get current position x
	lbu $t1, 3($a0)		# Get current position y
	li $t2, 24  		# Max row 
	li $t3, 79			# Max Column
	li $t4, 80			# Number of cells

	# =================== DETERMINE DIRECTION =================== #
	beq $a1, 'h', move_cursor_left
	beq $a1, 'j', move_cursor_down
	beq $a1, 'k', move_cursor_up
	beq $a1, 'l', move_cursor_right
	j move_cursor_DONE	# If neither of these chars, do nothing		
	
	# ============================ MOVE CURSOSR LEFT ============================ #
	move_cursor_left:	
		bgtz $t1, move_cursor_left2		# Check if y > 0
		beqz $t0, move_cursor_DONE		# Check if x = 0
		move_cursor_left2:
			addi $a2, $t1, -1 			# Column - 1 (New position y)
			bltz $a2, move_cursor_left3	# If negative, do nothing
			move $a1, $t0				# Position x
			jal set_cursor				# Update the cursor
			j move_cursor_DONE	
			move_cursor_left3:
				j move_cursor_DONE	
				
	# ============================ MOVE CURSOSR DOWN ============================ #
	move_cursor_down:
		blt $t0, $t2, move_cursor_down2	# Check if last row
		j move_cursor_DONE
		move_cursor_down2:
			addi $a1, $t0, 1			# Row + 1 (Next Row)
			move $a2, $t1				# Position y
			jal set_cursor				# Update the cursor
			j move_cursor_DONE
			
	# ============================ MOVE CURSOSR UP ============================ #
	move_cursor_up:
		bgt $t0, 0, move_cursor_up2		# Check if first row
		j move_cursor_DONE
		move_cursor_up2:
			addi $a1, $t0, -1			# Row - 1 (Previous Row)
			move $a2, $t1				# Position y
			jal set_cursor				# Update the cursor
			j move_cursor_DONE
	
	# ============================ MOVE CURSOSR RIGHT ============================ #
	move_cursor_right:
		blt $t1, $t3, move_cursor_right2	# Check if y < 79 (last column)
		beq $t0, $t2, move_cursor_DONE		# Check if x = 24 (last row)
		move_cursor_right2:
			addi $a2, $t1, 1 			  	# Column + 1 (Next column)
			beq $a2, $t4 move_cursor_right3	# If 80, do nothing
			move $a1, $t0					# Position x
			jal set_cursor					# Update the cursor
			j move_cursor_DONE	
			move_cursor_right3:
				j move_cursor_DONE
			
	# =================== EPILOGUE =================== #
	move_cursor_DONE:
		lw $ra, 0($sp)	  	# Restore Return Address
		addi $sp, $sp, 4	
		jr $ra			  	# Return to caller

# ===== int mmio_streq(String mmio, String b); ===== #
mmio_streq:
	# ================ PROLOGUE ================ #
	addi $sp, $sp, -12
	sw $ra, 0($sp)		# Store Return Address
	sw $s0, 4($sp)		# Store $s0
	sw $s1, 8($sp)		# Store $s1
	
	# ================== INITIALIZE VARIABLES ===================== #
	move $s0, $a0		# Copy of String mmio
	move $s1, $a1		# Copy of String b

	# ========================= COMPARE STRINGS ============================ #
	mmio_streq_LOOP:
		lbu $a0, 0($s0)					# Get next character of String mmio
		lbu $a1, 0($s1)					# Get next character of String b
		jal cmp_whitespace				# Compare String chars
		bnez $v0, mmio_streq_TRUE		# Strings are equal, return 1
		bne $a0, $a1, mmio_streq_FALSE	# String are not equal, return 0
		addi $s0, $s0, 2				# Go to next char of String mmio
		addi $s1, $s1, 1				# Go to next char of String b
		j mmio_streq_LOOP				# Continue comparing String chars
	
	# ======================== EPILOGUE ======================== #
	mmio_streq_TRUE:
		li $v0, 1			# Return 1 if Strings are equal
		j mmio_streq_DONE
	mmio_streq_FALSE:
		li $v0, 0			# Return 0 if String are not equal
	mmio_streq_DONE:
		lw $s1, 8($sp)		# Restore $s1
		lw $s0, 4($sp)		# Restore $s0
		lw $ra, 0($sp)	  	# Restore Return Address
		addi $sp, $sp, 12	
		jr $ra			  	# Return to caller

##################################
# Part 3 - UI/UX Functions
##################################

# ===== void handle_nl(Struct state); ===== #
handle_nl:
	# ===== PROLOGUE ===== #
	addi $sp, $sp, -8
	sw $ra, 0($sp)		# Store Return Address
	sw $s0, 4($sp)		# Store $s0

	# ============ INITIALIZE VARIABLES =============== #
	move $s0, $a0		# Copy of state Struct address
	
	# ============ SET CURRENT POSITION TO '\n' ============== #
	li $a1, '\n'		# Char to be set at current position
	jal save_char 		# Save '\n' char at current position
	
	# ================= CLEAR REST OF ROW =================== #
	li $a1, 'l'			
	jal move_cursor		# Move cursor to the right once
	lbu $a0, 2($s0)		# Get position x
	lbu $a1, 3($s0)		# Get position y
	lbu $a2, 0($s0)		# Default color 
	jal clear_line		# Clear the rest of the line
	
	# ============================ MOVE CURSOR TO NEXT LINE ============================ #
	move $a0, $s0		# Put state address in argument 0
	li $t0, 24			# Max rows
	handle_nl_next_line:
		lbu $a1, 2($a0)						# Get position x
		beq $a1, $t0, handle_nl_last_row	# Check if last row
		addi $a1, $a1, 1					# Go to next rows
		handle_nl_last_row:
			li $a2, 0						# Position y = 0
			li $a3, 1						# Initial
			jal set_cursor					# Move cursor to beginning of current row
	
	# =================== EPILOGUE =================== #
	handle_nl_DONE:
		lw $s0, 4($sp)		# Restore $s0
		lw $ra, 0($sp)	  	# Restore Return Address
		addi $sp, $sp, 8
		jr $ra				# Return to caller

# ===== void handle_backspace(Struct state); ===== #
handle_backspace:
	# ===== PROLOGUE ===== #
	addi $sp, $sp, -8
	sw $ra, 0($sp)		# Store Return Address
	sw $s0, 4($sp)		# Store $s0
	
	# ====== CALCULATE CURRENT CURSOR POSITION ADDRESSS ========= #
	move $s0, $a0		# Save address of state struct
	li $t0, 0xFFFF0000	# Base Address of VT100 MMIO
	li $t1, 80			# Number of columns
	lbu $t2, 2($a0)		# Get current position x
	lbu $t3, 3($a0)		# Get current position y
	mul $a1, $t1, $t2	# Multiply columns with x
	add $a1, $a1, $t3	# Add y
	sll $a1, $a1, 1   	# Multiply by size of cell (2-bytes)
	add $a1, $a1, $t0	# Add Base Address (destination 'String')
	
	# =============================== COPY =============================== #
	addi $a0, $a1, 2	# Source 'String' = next cell 
	li $t4, 79			# Max position y
	subu $a2, $t4, $t3	# Get number of bytes to copy (79 - position y)
	jal strcpy			# Copy characters in rest of line
	
	# ================ RESET LAST CELL IN ROW ================ #
	li $t0, 0xFFFF0000	# Base Address of VT100 MMIO
	li $t1, 80			# Number of columns
	lbu $t2, 2($s0)		# Get current position x
	li $t3, 79			# Max position y
	mul $t4, $t1, $t2	# Multiply columns with x
	add $t4, $t4, $t3	# Add y
	sll $t4, $t4, 1   	# Multiply by size of cell (2-bytes)
	add $t4, $t4, $t0	# Add Base Address
	li $t0, '\0'		# NUll
	sb $t0, 0($t4)		# Make last cell character NULL
	lbu $t0, 0($s0)		# Get default color
	sb $t0, 1($t4)		# Reset last cell color to default
	
	# =================== EPILOGUE =================== #
	handle_backspace_DONE:
		lw $s0, 4($sp)		# Restore $s0
		lw $ra, 0($sp)	  	# Restore Return Address
		addi $sp, $sp, 8
		jr $ra				# Return to caller

# ===== void highlight(byte x, byte y, byte color, int n); ===== #
highlight:
	# ===== PROLOGUE ===== #
	# NONE

	# ======= CALCULATE CURRENT CURSOR POSITION ADDRESS ======= #
	li $t0, 0xFFFF0000	# Base Address of VT100 MMIO
	li $t1, 80			# Number of columns
	mul $t1, $t1, $a0	# Multiply columns with x
	add $t1, $t1, $a1	# Add y
	sll $t1, $t1, 1   	# Multiply by size of cell (2-bytes)
	add $t1, $t1, $t0	# Add Base Address
	
	# ======================= HIGHLIGHT ========================== #
	highlight_LOOP:
		sb $a2, 1($t1)			# Set next cells highlight color 
		addi $t1, $t1, 2			# Go to next cell
		addi $a3, $a3, -1		# Decrement coutner
		bnez $a3, highlight_LOOP	# Continue highlighting
		
	# ================ EPILOGUE ================ #
	# NONE
	highlight_DONE:
		jr $ra				# Return to caller

# ===== void highlight_all(byte color, String[] dictionary); ===== #
highlight_all:
	# ===== PROLOGUE ===== #
	addi $sp, $sp, -32
	sw $ra, 0($sp)		# Store Return Address
	sw $s0, 4($sp)		# Store $s0
	sw $s1, 8($sp)		# Store $s1
	sw $s2, 12($sp)		# Store $s2
	sw $s3, 16($sp)		# Store $s3
	sw $s4, 20($sp)		# Store $s4
	sw $s5, 24($sp)		# Store $s5
	sw $s6, 28($sp)		# Store $s6
	
	# =============== INITIALIZE VARIABLES ================== #
	li $s0, 0xFFFF0000	# Starting address of display
	li $s1, 0xFFFF0FA0 	# Ending address of display
	move $s2, $a0		# Save color 
    move $s3, $a1		# Save dictionary address
	li $s4,	0			# Initial position x
	li $s5, 0			# Initial position y

	# =================================== HIGHLIGHT SYNTAX =================================== #
	# ============================== WHILE LOOP NUMBER 1 ============================== #
	highlight_all_while1_LOOP:
		# ============================ WHILE LOOP NUMBER 2 ============================ #
		highlight_all_while2_LOOP:
			lbu $a0, 0($s0)						 		# Get the character at current position
			jal is_whitespace							# Check if it's whitespace
			beqz $v0, reinitialize_dictionary_address	# If not whitespace, goto for loop
			addi $s0, $s0, 2					 		# Go to next cell
			beq $s5, 79, highlight_all_while2_row		# Position is next row
			addi $s5, $s5, 1					 		# Increment position y
			j highlight_all_while2_LOOP
			highlight_all_while2_row:
				li $t0, 24						 # Max row count
				beq $s4, $t0, highlight_all_DONE # Check if last row
				addi $s4, $s4, 1				 # Increment position x
				li $s5, 0						 # Beginning of current row
				j highlight_all_while2_LOOP
		
		# ================================== FOR LOOP ================================= #
		reinitialize_dictionary_address:
		move $s6, $s3 			# Local copy of dictionary address
		highlight_all_for_LOOP:
			lw $a1, 0($s6) 		# Get address of word in dictionary
			move $a0, $s0		# Starting address of word in current cell
			jal mmio_streq		# Check if string in current cell is equal to current word in dictionary
			bnez $v0, highlight_all_for_loop_MATCH
			addi $s6, $s6, 4	# Go to next word in dictionary 
			lw $t0, 0($s6) 		# Get address of word in dictionary
			beqz $t0, highlight_all_while3_LOOP	# Check if end of dictionary list
			j highlight_all_for_LOOP
			highlight_all_for_loop_MATCH:
				move $a2, $s2	# Color bytes
				lw $a0, 0($s6)	# Address of matched word
				jal strlen		# Get the length of the dictionary word
				move $a3, $v0	# length of word
				move $a0, $s4	# Position x
				move $a1, $s5	# Position y
				jal highlight	# Highlight the word starting at current cell
				
		# ============================ WHILE LOOP NUMBER 3 ============================ #
		highlight_all_while3_LOOP:
			lbu $a0, 0($s0)						 		# Get the character at current position
			jal is_whitespace							# Check if it's whitespace
			bnez $v0, highlight_all_check_end_display	# If whitespace
			addi $s0, $s0, 2					 		# Go to next cell
			beq $s5, 79, highlight_all_while3_row		# Position is next row
			addi $s5, $s5, 1					 		# Increment position y
			j highlight_all_while3_LOOP
			highlight_all_while3_row:
				li $t0, 24						 # Max row count
				beq $s4, $t0, highlight_all_DONE # Check if last row
				addi $s4, $s4, 1				 # Increment position x
				li $s5, 0						 # Beginning of current row
				j highlight_all_while3_LOOP
	
	highlight_all_check_end_display:	
	blt $s0, $s1, highlight_all_while1_LOOP	# Check if last cell in display is reached
	
	# =================== EPILOGUE =================== #
	highlight_all_DONE:
		lw $s6, 28($sp)		# Restore $s6
		lw $s5, 24($sp)		# Restore $s5
		lw $s4, 20($sp)		# Restore $s4
		lw $s3, 16($sp)		# Restore $s3
		lw $s2, 12($sp)		# Restore $s2
		lw $s1, 8($sp)		# Restore $s1
		lw $s0, 4($sp)		# Restore $s0
		lw $ra, 0($sp)	  	# Restore Return Address
		addi $sp, $sp, 32
		jr $ra				# Return to caller
