.text
	andi $2,$2, 0
	ori $2,$2, 21
	andi $3,$3, 0
	ori $3,$3, 14
loop:
	beq $3,$0,end_loop
	or $4,$0,$3
	divu $2,$3
	mfhi $3
	andi $2,$2, 0
	add $2,$2,$4
	bgtz $3,loop
	sw $2, 0($0) 
	syscall
end_loop:
	nop
	j end_loop
