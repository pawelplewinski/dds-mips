.text
	andi $5,$5, 0
	andi $4,$4, 0
	ori $4,$4, 10
	andi $3,$3, 0
	andi $2,$2, 0
loop1:
	beq $2, $4, loop1_end
	addi $3, $2, 12345
	sw $3, 0($5)
	addi $2, $2, 1
	addi $5, $5, 4
	j loop1
loop1_end:
	syscall
end_loop:
	nop
	j end_loop
