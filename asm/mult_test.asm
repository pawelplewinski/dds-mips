.text
	#Test signed multiply
	andi $3,$3,0
	addi $3,$3,-25
	andi $4,$4,0
	ori $4,$4,5
	mult $3,$4
	#Switch places
	mult $4,$3
	#Now try non-negative
	andi $3,$3,0
	addi $3,$3, 25
	mult $3,$4
	#And two negatives
	andi $3,$3,0
	addi $3,$3,-25
	andi $4,$4,0
	addi $4,$4,-5
	mult $3,$4
	#Test complete
	syscall
endless_loop:
	j endless_loop
	