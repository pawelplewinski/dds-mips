.text
	andi $2,$2, 0
	ori $2,$2, 50
	andi $3,$3, 0
	ori $3,$3, 25
loop:
	andi $4,$4,0
	beq $3,$4,end_loop
	or $4,$4,$3
	divu $2,$3
	mfhi $3
	andi $2,$2, 0
	add $2,$2,$4
	bgtz $3,loop
	#andi $4,$4,0
	sw $2, 0($4) 
end_loop:
	nop
	beq $4,$4,end_loop