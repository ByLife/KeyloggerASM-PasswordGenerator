section .data
    filename db "keylog.txt", 0
    fd dq 0                    ; stockage du fd

section .bss
    buffer resb 1              ; buffer pour la touche

section .text
global _start

_start:
    ; ouverture fichier
    mov rax, 2                 ; open
    mov rdi, filename
    mov rsi, 102o             ; append + create + write
    mov rdx, 0644o            ; perms
    syscall
    
    mov [fd], rax             ; save fd

read_loop:
    ; recup stdin
    mov rax, 0                
    mov rdi, 0                
    mov rsi, buffer
    mov rdx, 1                
    syscall

    ; verifie fin
    cmp rax, 0
    jle exit

    ; ecrit dans le fichier
    mov rax, 1                
    mov rdi, [fd]
    mov rsi, buffer
    mov rdx, 1
    syscall

    jmp read_loop

exit:
    ; ferme le fichier
    mov rax, 3                
    mov rdi, [fd]
    syscall

    mov rax, 60               
    xor rdi, rdi
    syscall