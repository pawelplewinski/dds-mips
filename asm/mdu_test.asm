.text
	#Test unsigned divide
	andi $3,$3, 0
	addi $3,$3, 25
	andi $4,$4,0
	ori $4,$4,5
	divu $3,$4
	#Switch places and multiply
	mult $4,$3
	#Something else?
	addi $3,$3, -50
	mult $3,$4
	#Division and multiplication by 0
	addi $3,$3,100
	andi $4,$4,0
	divu $3,$4
	mult $3,$4
	#Test complete
	syscall
endless_loop:
	j endless_loop
	