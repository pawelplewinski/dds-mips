#$1 - 1
#$12 - 5
#$11 - 4
#$10 - loop counter
.text
	andi $1, 0
	ori $1, 0x1
	lui $2, 0
	ori $2, $2, 5
	andi $3, $3, 0
	ori $3, $3, 2500
	lui $4, 0x01
	ori $4, $4, 50
	lui $5, 0x54AB
	ori $5, 0x45BA
	lui $6, 0x0
	andi $10, 0
	andi $11, 0
	ori $11, 16
	lui $12, 0
	ori $12, $12, 5
test:
	or $20, $3, $5
	xor $21, $3, $5
	mult $2, $3
	mflo $22
	mfhi $23
mem:
	sw $12, 0($11)
	lw $13, 0($11)
	beq $12, $13, loop1
	j err
loop1:
	or $4, $4, $3
	divu $2, $3
	mfhi $7
	mflo $2
	andi $2, $2, 0
	add $2, $2, $4
	addi $10, $10, 1 #increment ctr
	beq $10, $12, loop2
	j loop1
loop2:	
	mult $10, $11
	mflo $8
	and $5, $4, $2
	sub $10, $10, $1
	bgtz $10, loop2
end:
	nop
	j end
err:
	andi $25, 0
	ori $25, 0x1234
	j err