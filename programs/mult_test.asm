.text
       andi $2,$2, 0
       ori $2,$2, 21
       andi $3,$3, 0
       ori $3,$3, 14
       mult $2, $3
       mfhi $4
       mflo $5        
       sw $4, 0($0)                
       sw $5, 0($1)
       syscall
end_loop: nop
       j end_loop