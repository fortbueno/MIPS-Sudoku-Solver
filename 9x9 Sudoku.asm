# CS 21 LAB 4 -- S2 AY 2021-2022
# Felix Q. Bueno IV -- 02/03/2022
# Machine Problem -- Sudoku Solver 9x9


.macro do_syscall(%n)
	li $v0, %n
	syscall
.end_macro

.macro read_int
	do_syscall(5)
.end_macro

.macro print_int
	do_syscall(1)
.end_macro

.macro allocate_str(%label, %str)
	%label: .asciiz %str
.end_macro

.macro print_str(%label)
	la $a0, %label
	do_syscall(4)
.end_macro

.macro exit
	do_syscall(10)
.end_macro

.text
main:
	li $t0, 0					#set $t0 = 0, let $t0 be the number of input lines taken
	li $t2, 0					#set $t2 = 0, let $t0 be the offset to store each digit to the grid
	jal take_input					#jal to take_input
	li $a0, 0					#set $a0 = 0, $a0 is the offset to be used to check each element
	jal check_vacant				#jal to check_vacant
	
#set up registers to be used in printing the grid
	
	li $t0, 0					#set $t0 = 0 , let $t0 be the register used to keep track of the offsets used to access each cell
	li $t1, 0					#set $t1 = 0, let $t1 be the register used to keep track of the number of cells printed in a row
	print_str(new_line)				#print new line	
	j print_grid					#jump to print_grid

#take input function processes each line of input and stores them to memory

take_input:						#take_input reads a 4-digit integer, and stores each digit of this integer to the grid via arithmetic operations
	li $t1, 100000000				#set $t1 = 100000000
	bge $t0, 9, return				#branch to return if $t0 >= 9
	read_int					#take integer as input (macro)
	move $a0, $v0					#move input to $a0

loop_input:
	blt $t1, 1, next_input				#branch to next_input if $t1 <= 1
	div $a0, $t1					#divide $a0 by $t1
	mflo $t3					#move the quotient to $t3 (digit to store to grid)
	sw $t3, grid + 0($t2)				#store the content of $t3 to the grid ($t2 as offset)
	mfhi $a0					#move the remainder to $a0
	div $t1, $t1, 10				#set $t1 to the quotient of $t1 / 10
	addi $t2, $t2, 4				#set $t2 = $t2 + 4
	j loop_input					#jump to loop_input

next_input:						#next_input ackowledges when the first line of integer input is done being processed
	addi $t0, $t0, 1				#add 1 to $t0
	j take_input					#jump to take_input

return:
	jr $ra						#return control to main

#check_vacant is a recursive function that checks the grid for empty cells (0) and stores the appropriate digit for each empty cell

check_vacant:
	#####preamble######
	subu $sp, $sp, 24				#allocate stack frame for check_vacant function
	sw $ra, 0($sp)					#save the return address
	sw $s0, 4($sp)					#save the s0 register - the offset to be used to access each element in the grid
	sw $s1, 8($sp)					#save the s1 register - the number of bytes in a row/column/box
	sw $s2, 12($sp)					#save the $s2 register - the row index of a cell
	sw $s3, 16($sp)					#save the $s3 register - the column index of a cell
	sw $s4, 20($sp)					#save the $s4 register - this register will be used to test the possible values in each empty cell
	#####preamble######
	
	move $s0, $a0					#set $s0 to the contents of $a0
	bgt $s0, 320, return_success			#branch to return_success if %s0 > 320 (the offset has passed the end of the grid)
	
	li $s1, 36					#set $s1 = 36
	div $s0, $s1					#divide $s0 by $s1
	mflo $s2					#set the quotient to $s2; cell row index
	mfhi $s3					#set the remainder to $s3; 
	div $s3, $s3, 4					#set $s3 to the quotient of $s3 divided by 4; cell column index
	li $s4, 1					#set $s4 = 1
	
	lw $t0, grid + 0($s0)				#load the current cell's value to $t0
	beqz $t0, if_vacant				#branch to if_vacant if $t0 = 0 (empty cell)
	addi $a0, $s0, 4				#else, set $a0 = $s0 + 4; (offset + 4)
	jal check_vacant				#jal to check_vacant
	j return_vacant					#jump to return_vacant

if_vacant:
	move $a1, $s4					#set $a1 to the contents of $s4; used to try values for the empty cell
	move $a2, $s2					#set $a2 to the contents of $s2; cell row index
	move $a3, $s3					#set $a3 to the contents of $s3; cell column index
	jal check_rowcol				#jal to check_rowcol
	beq $v0, 1, next_guess				#branch to next_guess if $v0 = 1 (return value of check_rowcol)
	sw $s4, grid + 0($s0)				#else, store the value in $s4 to the empty cell being processed
	
	addi $a0, $s0, 4				#set $a0 to $s0 + 4; (offset + 4)
	jal check_vacant				#jal to check_vacant
	beqz $v0, return_vacant				#branch to return_vacant if $v0 = 0

next_guess:
	addi $s4, $s4, 1				#set $s4 = $s4 + 1; try another value for the empty cell
	ble $s4, 9, if_vacant				#branch to if_vacant if $s4 is less than or equal to 9
	sw $zero, grid + 0($s0) 			#if it's invalid, set the value of the cell back to zero
	li $v0, 1					#set $v0 = 1
	j return_vacant					#else, jump to return_vacant
	
	
return_success:
	li $v0, 0					#set $v0 to zero; indicates a successful solve for the sudoku

return_vacant:
	#destroys stack frame and restores the used registers for the function
	#####end######					
	lw $ra, 0($sp)					
	lw $s0, 4($sp)					
	lw $s1, 8($sp)					
	lw $s2, 12($sp)					
	lw $s3, 16($sp)					
	lw $s4, 20($sp)
	addi $sp, $sp, 24
	#####end######
	jr $ra	
	
	
#check row_col is a function to check whether a specific value that is tested is valid in terms of the rules for sudoku
#$a1: value to be checked, $a2: cell row index, $a3: cell column index

check_rowcol:
	li $t1, 0				#set $t1 = 0; $t1 is the number of cells in the row that has been checked
	mul $t2, $a2, 36			#set $t2 = $a2 * 36; $t2 is the offset of the starting cell in the row

check_row:
	lw $t3, grid + 0($t2)			#load the value of the specific cell in the row to $t3
	beq $t3, $a1, invalid			#branch to invalid if $t3 = $a1; there is a duplicate in the row
	addi $t2, $t2, 4			#else, set $t2 = $t2 + 4; add 4 to the offset
	addi $t1, $t1, 1			#add 1 to $t1
	blt $t1, 9, check_row			#branch to check_row if $t1 < 9
	
	#else, we set the needed registers for column checking
	
	move $t2, $a3				#set $t2 to the contents of $a3; (cell column index)
	mul $t2, $t2, 4				#multiply $t2 by 4 to get the offset of the first element in the said column
	addi $t3, $t2, 288			#set $t3 = $t2 + 288; we will use this as a bound to check the number of elements we have checked in the column

check_col:
	lw $t4, grid + 0($t2)			#load the value of the specific cell in the column to $t4
	beq $t4, $a1, invalid			#branch to invalid if $t4 = $a1; there is a duplicate in the row
	addi $t2, $t2, 36			#else, set $t2 = $t2 + 36; add 36 to the offset to access the next cell in the column
	ble $t2, $t3, check_col			#branch to check_col if $t2 is less than or equal to $t3
	
	#else, we set the needed registers for box checking
	
	div $t2, $a2, 3				#set $t2 = $a2 / 3
	div $t3, $a3, 3				#set $t3 = $a3 / 3
	mul $t2, $t2, 108			#set $t2 = $t2 * 106
	mul $t3, $t3, 12			#set $t3 = $t3 * 12
	add $t3, $t2, $t3			#set $t3 = $t2 + $t3; this is the offset of the first element in the corresponding box
	
	li $t1, 0				#set $t1 = 0; this register will be used to count the number of times we jumped to the bottom left of the box
	li $t2, 0				#set $t2 = 0; this register will be used to count the number of elements checked in the box horizontally

check_box:
	lb $t4, grid + 0($t3)			#load the value of the specific cell in the box to $t4
	beq $t4, $a1, invalid			#branch to invalid if $t4 = $a1; there is a duplicate in the row
	addi $t2, $t2, 1			#else, set $t2 = $t2 + 1
	bge $t2, 3, check_box_col		#branch to check_box_col if $t2 is greater than or equal to 3
	addi $t3, $t3, 4			#else, set $t3 = $t3 + 4; get offset for the next element in the row included in the box
	j check_box				#jump to check_box

check_box_col:
	addi $t3, $t3, 28			#set $t3 = $t3 + 12; get the offset of the element in the bottom left of the box
	li $t2, 0				#set $t2 = 0
	addi $t1, $t1, 1			#set $t1 = $t1 + 1
	blt $t1, 3, check_box			#branch to check_box if $t1 is less than 3
	
	#else, we are done checking the rules of sudoku
	
	li $v0, 0				#set return value $v0 = 0 (TRUE)
	j return_check				#jump to return_check
invalid:
	li $v0, 1				#set return value $v0 = 1 (FALSE)

return_check:
	jr $ra					#jump to return address


print_grid:
	bgt $t0, 320, terminate_program		#branch to terminate_program if $t0 > 320, this means that the offset has ezceeded the grid's bounds
	beq $t1, 9, print_new_line		#else, branch to print_new_line if $t1 = 9, this means that 9 elements in a row has been printed and thus we move on to the next row
	lw $a0, grid + 0($t0)			#else, load the value of the cell to $a0
	print_int				#print the integer in $a0
	addi $t0, $t0, 4			#set $t0 = $t0 + 4; offset + 4; access the next element
	addi $t1, $t1, 1			#set $t1 = $t1 + 1
	j print_grid				#jump back to print_grid

print_new_line:
	print_str(new_line)			#print new line to indicate new row
	li $t1, 0				#set $t1 = 0
	j print_grid				#jump back to print_grid

terminate_program:
	exit					#terminate the program
	
.data
	grid: .space 324
	allocate_str(new_line, "\n")
