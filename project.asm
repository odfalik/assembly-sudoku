# Sudoku: Oded Falik, Mazidi CS3340.005 Final Project

.data
welcomeText:	.asciiz 	"Welcome to MIPS Sudoku!\nEnter your space-separated commands in the form: Row Col # (eg: C E 7)\nTo remove a number from the puzzle, enter '_' (underscore) for #. Enter 'R' to Reset, '0' to Exit."
puzzleList:	.asciiz	"\n To begin, please enter one of the following options:\neasy1\neasy2\nmedium1\nmedium2\nhard1\ndebugEndgame"
promptText:	.asciiz 	"Enter your command: "
corrText:		.asciiz	"Valid move!\n"
errText:		.asciiz 	"Bad move! Keep looking. "
winText:		.asciiz	"\nCongratulations! You have completed the sudoku!\n"
goodbyeText:	.asciiz 	"Thanks for playing!\n"

fin: 		.space 	256			# filename of puzzle template
buffer: 		.space 	512			# used both for file read (99 bytes) & sudoku write (266 bytes)
sudoku:		.space 	81			# Holds puzzle
command:		.space 	64			# User input command
colLetters:	.asciiz	"  A B C D E F G H I\r\n"
rowSeparator:	.asciiz	"  -----|-----|-----\r\n"

.text
main:
	la	$a0, welcomeText
	li	$v0, 4
	syscall			# Print welcomeText
	
	la $a0, puzzleList
	la $a1, fin
	li $a2, 256
	li $v0, 54
	syscall			# Open dialog box
	beq	$a1, -2, main	# Dialog cancelled
	beq 	$a1, -3, main	# No input
	
	li	$t0, 0
replaceNlLoop:
	lb	$t1, fin($t0)
	beq	$t1, '\n', replace
	addi	$t0, $t0, 1
	bne	$t0,	256,	replaceNlLoop
	j 	openFile
replace:	
	li	$t3, '\0'
	sb	$t3, fin($t0)

openFile:
	# Open puzzle template file for reading
	li   $v0, 13		# syscall 13: open file
	la   $a0, fin      	# input file name
	li   $a1, 0        	# flag for reading
	li   $a2, 0		# mode is ignored
	syscall            	# open file
	blez	$v0, main		# restart if error
	move $s0, $v0      	# save the file descriptor

	# Reading file
	li   $v0, 14		# syscall 14: read from file
	move $a0, $s0      	# file descriptor
	la   $a1, buffer   	# address of buffer
	li   $a2, 99  		# buffer length ((9 + '\n' + '\r') * 9)
	syscall            	# read from file

	# Closing file
	li   $v0, 16     	# syscall 16: close file
	move $a0, $s0    	# file descriptor to close
	syscall            	# close file
	
	la	$a0, buffer	# buffer read pointer
	la	$a1, sudoku	# sudoku write pointer
	li	$t1, 0		# row index
rowReadLoop:
	li	$t2, 0		# col index
colReadLoop:
	lb	$t3,	($a0)	# read from buffer
	sb	$t3, ($a1)	# store value into sudoku
	
	addi $a0, $a0, 1	# read ptr ++
	addi $a1, $a1, 1	# write ptr ++
	addi $t2, $t2, 1	# col index ++
	
	bne	$t2, 9, colReadLoop # branch if not end of row
	addi $t1, $t1, 1	# row index ++
	addi $a0, $a0, 2	# skip "\r\n" in read buffer
	bne	$t1, 9, rowReadLoop # branch if not last row done
	
	j	render

getInput: # prompt for, and check user input
	la	$a0, promptText
	li	$v0, 4
	syscall			# Print promptText
	
	# get input
	la 	$a0, command
	li 	$a1, 64
	li 	$v0, 8
	syscall			# read input command and save

	lb 	$s0, command	# $s0 = row
	beq 	$s0, '0', exit	# Exit program if $s0 == '0'
	beq  $s0, 'R', main	# Back to main if $s0 == 'R'
	lb 	$s1, command+2	# $s1 = col
	lb 	$s2, command+4	# $s2 = #
	
	jal checkPuzzle 	# check for conflicts

render: # render formatted sudoku line by line
	li	$v0, 11
	li	$a0, 10
	syscall			# Print cr
	li	$a0, 13
	syscall			# Print nl
	
	la	$a0, sudoku	# sudoku read pointer
	la	$a1, buffer	# buffer write pointer
	li	$t1, 0		# row index
	
	la	$t0, colLetters
colLettersLoop:
	lb	$t3, ($t0)	# read char from string
	sb	$t3, ($a1)	# print char to buffer
	addi	$a1, $a1, 1	# buffer ptr ++
	addi $t0, $t0, 1	# read string ptr ++
	bne	$t3, 10, colLettersLoop
	
rowPrintLoop:
	li	$t2, 0		# col index
	
	addi $t4, $t1, 65	# $t4 = row designator char
	sb	$t4, ($a1)	# print row designator char to buffer
	li	$t4, 32
	sb	$t4, 1($a1)	# print space to buffer
	addi	$a1, $a1, 2

colPrintLoop:
	lb	$t3,	($a0)	# read from sudoku
	sb	$t3, ($a1)	# store value into buffer
	
	addi $a0, $a0, 1	# read ptr ++
	
	li	$t4, 124		# '|'
	beq	$t2, 2, printSeparator
	beq	$t2, 5, printSeparator
	li	$t4, 32		# ' '
printSeparator:
	sb	$t4, 1($a1)	# print ' ' or '|' to buffer
	addi $a1, $a1, 2	# write ptr ++
	
	addi $t2, $t2, 1	# col index ++
	
	bne	$t2, 9, colPrintLoop # branch if not end of row
	li	$t4, 13		# '\r'
	sb	$t4, ($a1)	# print '\r' to buffer at end of row
	li	$t4, 10		# '\n'
	sb	$t4, 1($a1)	# print '\n' to buffer at end of row
	addi $a1, $a1, 2	# write ptr ++
		
	addi $t1, $t1, 1	# row index ++
	
	beq	$t1, 3, rowSep
	beq 	$t1, 6, rowSep
	
	j rowSepLoopSkip
	
rowSep:
	la	$t0, rowSeparator
rowSepLoop:
	lb	$t3, ($t0)	# read char from string
	sb	$t3, ($a1)	# print char to buffer
	addi	$a1, $a1, 1	# buffer ptr ++
	addi $t0, $t0, 1	# read string ptr ++
	bne	$t3, 10, rowSepLoop
	
rowSepLoopSkip:
	bne	$t1, 9, rowPrintLoop # branch if not last row done

	la	$a0, buffer
	li	$v0, 4
	syscall			# Print buffer

	j	getInput
	
checkPuzzle:
	#$s0 = row
	#$s1 = col
	#$s2 = #
	
	subi $s0, $s0, 'A'
	subi $s1, $s1, 'A'
	
setEmpty: # if # == '_': set value
	beq 	$s2, '_', setVal

checkRow:
	li	$t7, 9			# 9
	mult $s0, $t7			# 9 * Row
	mflo	$t0
	li	$t1, 0			# Col index
checkRowLoop:
	add	$t2, $t0, $t1		# Sudoku index
	lb	$t3, sudoku($t2)	# Read data from sudoku
	beq	$s1, $t1, skipSameCol
	beq	$s2, $t3, badMove 	# If equal, error found
skipSameCol:
	addi $t1, $t1, 1		# Col index ++
	bne	$t1, 9, checkRowLoop
	
checkCol:
	li	$t1, 0			# Row index
	move $t2, $s1			# Sudoku index
checkColLoop:
	lb	$t3, sudoku($t2)	# Read data from sudoku
	beq	$s0, $t1, skipSameRow
	beq	$s2, $t3, badMove 	# If equal, error found
skipSameRow:
	addi $t1, $t1, 1		# Row index ++
	addi	$t2, $t2, 9		# Move indexer down one row
	bne	$t1, 9, checkColLoop
	
checkBox:
	divu	$t0, $s0, 3
	mulu $t0, $t0, 3		# $t0 = Row of top left of box
	
	divu	$t1, $s1, 3
	mulu $t1, $t1, 3		# $t1 = Col of top left of box
	
	mulu $t2, $t0, 9
	add	$t2, $t2, $t1		# $t2 = Offset to top left of box (sudoku index)
	
	mulu $t3, $s0, 9
	add	$t3, $t3, $s1		# $t3 = Offset of input spot (sudoku index)
	
	li	$t4, 0			# $t4 = Box row index
checkBoxRowLoop:
	li	$t5, 0			# $t5 = Box col index
checkBoxColLoop:
	beq 	$t2, $t3, checkBoxSkipCheck
	lb	$t6, sudoku($t2)	# Read data from sudoku
	beq	$t6, $s2, badMove
checkBoxSkipCheck:
	addi	$t5, $t5, 1		# Col ++
	addi	$t2, $t2, 1
	bne	$t5, 3, checkBoxColLoop
	addi	$t4, $t4, 1		# Row ++
	addi	$t2, $t2, 6
	bne	$t4, 3, checkBoxRowLoop
	
setVal:
	li	$t7, 9			# 9
	mult $s0, $t7			# 9 * Row
	mflo	$t0
	add 	$t0, $t0, $s1		# + Col = Relative sudoku index
	sb	$s2, sudoku($t0)	# Offset into sudoku

	li	$t0, 0			# Sudoku indexer
doneCheckLoop: # if all correct/puzzle completed: exit program
	lb	$t1, sudoku($t0)
	beq	$t1, '_', render
	addi	$t0, $t0, 1
	bne	$t0, 81, doneCheckLoop
	
	la	$a0, winText
	li	$v0, 4
	syscall			# Print winText
	j	exit

badMove:
	la	$a0, errText
	li	$v0, 4
	syscall			# Print errText
	j	render
	
exit:
	la	$a0, goodbyeText
	li	$v0, 4
	syscall			# Print goodbyeText

	li	$v0, 10
	syscall			# Exit program
