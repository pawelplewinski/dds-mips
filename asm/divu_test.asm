.text
	#Test unsigned divide
	andi $3,$3, 0
	addi $3,$3, 25
	andi $4,$4,0
	ori $4,$4,5
	divu $3,$4
	#Switch places
	divu $4,$3
	#Something else?
	addi $3,$3, 1
	divu $3,$4
	#Division by 0
	addi $3,$3,25
	andi $4,$4,0
	divu $3,$4
	#Test complete
	syscall
endless_loop:
	j endless_loop
	