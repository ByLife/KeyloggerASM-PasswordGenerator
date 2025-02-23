section .data
    welcome_msg db "Bienvenue dans le générateur de mot de passe by LucMARTIN & Léo HAIDAR B-)", 10, 10
    welcome_msg_len equ $ - welcome_msg

    commands_msg db "Commandes disponibles:", 10, \
                    "  simple  : Génère un mot de passe de 8 caractères (chiffres et lettres)", 10, \
                    "  medium  : Génère un mot de passe de 10 caractères (chiffres, lettres et caractères speciaux)", 10, \
                    "  hardcore: Génère un mot de passe de 20 caractères (chiffres, lettres et caractères speciaux)", 10, \
                    "  exit    : Quitte le programme", 10, 10
    commands_msg_len equ $ - commands_msg

    prompt_msg  db "Entrez une commande: "
    prompt_msg_len equ $ - prompt_msg

    success_msg db "Mot de passe généré !", 10
    success_msg_len equ $ - success_msg

    unknown_cmd_msg db "Commande inconnue !", 10, 10
    unknown_cmd_msg_len equ $ - unknown_cmd_msg

    newline db 10

    allowed_chars db "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
    allowed_len equ $ - allowed_chars

    allowed_medium_chars db "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz!@#$%^&*()"
    allowed_medium_chars_len equ $ - allowed_medium_chars

    exit_str   db "exit"
    exit_str_len equ $ - exit_str

    simple_str db "simple"
    simple_str_len equ $ - simple_str

    medium_str db "medium"
    medium_str_len equ $ - medium_str

    hardcore_str db "hardcore"
    hardcore_str_len equ $ - hardcore_str

section .bss
    input_buffer resb 16
    simple_password_buffer resb 9
    medium_password_buffer resb 11
    hardcore_password_buffer resb 21
    seed resq 1

section .text
    global _start

_start:
    mov rax, 1
    mov rdi, 1
    mov rsi, welcome_msg
    mov rdx, welcome_msg_len
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, commands_msg
    mov rdx, commands_msg_len
    syscall

main_loop:
    mov rax, 1
    mov rdi, 1
    mov rsi, prompt_msg
    mov rdx, prompt_msg_len
    syscall

    mov rax, 0
    mov rdi, 0
    mov rsi, input_buffer
    mov rdx, 16
    syscall
    mov rbx, rax
    mov rdi, input_buffer
trim_loop:
    cmp rbx, 0
    je after_trim
    cmp byte [rdi], 10
    jne not_newline
    mov byte [rdi], 0
not_newline:
    inc rdi
    dec rbx
    jmp trim_loop
after_trim:

    mov rdi, input_buffer
    mov rsi, exit_str
    mov rcx, exit_str_len
    repe cmpsb
    cmp rcx, 0
    je exit_program

    mov rdi, input_buffer
    mov rsi, simple_str
    mov rcx, simple_str_len
    repe cmpsb
    cmp rcx, 0
    je gen_simple

    mov rdi, input_buffer
    mov rsi, medium_str
    mov rcx, medium_str_len
    repe cmpsb
    cmp rcx, 0
    je gen_medium

    mov rdi, input_buffer
    mov rsi, hardcore_str
    mov rcx, hardcore_str_len
    repe cmpsb
    cmp rcx, 0
    je gen_hardcore

    mov rax, 1
    mov rdi, 1
    mov rsi, unknown_cmd_msg
    mov rdx, unknown_cmd_msg_len
    syscall
    jmp main_loop

gen_simple:
    rdtsc
    mov rbx, rdx
    shl rbx, 32
    or rbx, rax
    mov [seed], rbx
    mov rcx, 8
    mov rsi, simple_password_buffer
simple_loop:
    mov rax, [seed]
    mov rbx, 1103515245
    mul rbx
    add rax, 12345
    mov [seed], rax
    shr rax, 16
    mov rbx, allowed_len
    xor rdx, rdx
    div rbx
    mov rbx, allowed_chars
    add rbx, rdx
    mov dl, byte [rbx]
    mov byte [rsi], dl
    inc rsi
    loop simple_loop
    mov byte [rsi], 0
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    mov rax, 1
    mov rdi, 1
    mov rsi, success_msg
    mov rdx, success_msg_len
    syscall
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    mov rax, 1
    mov rdi, 1
    mov rsi, simple_password_buffer
    mov rdx, 8
    syscall
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    jmp main_loop

gen_medium:
    rdtsc
    mov rbx, rdx
    shl rbx, 32
    or rbx, rax
    mov [seed], rbx
    mov rcx, 10
    mov rsi, medium_password_buffer
medium_loop:
    mov rax, [seed]
    mov rbx, 1103515245
    mul rbx
    add rax, 12345
    mov [seed], rax
    shr rax, 16
    mov rbx, allowed_medium_chars_len
    xor rdx, rdx
    div rbx
    mov rbx, allowed_medium_chars
    add rbx, rdx
    mov dl, byte [rbx]
    mov byte [rsi], dl
    inc rsi
    loop medium_loop
    mov byte [rsi], 0
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    mov rax, 1
    mov rdi, 1
    mov rsi, success_msg
    mov rdx, success_msg_len
    syscall
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    mov rax, 1
    mov rdi, 1
    mov rsi, medium_password_buffer
    mov rdx, 10
    syscall
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    jmp main_loop

gen_hardcore:
    rdtsc
    mov rbx, rdx
    shl rbx, 32
    or rbx, rax
    mov [seed], rbx
    mov rcx, 20
    mov rsi, hardcore_password_buffer
hardcore_loop:
    mov rax, [seed]
    mov rbx, 1103515245
    mul rbx
    add rax, 12345
    mov [seed], rax
    shr rax, 16
    mov rbx, allowed_medium_chars_len
    xor rdx, rdx
    div rbx
    mov rbx, allowed_medium_chars
    add rbx, rdx
    mov dl, byte [rbx]
    mov byte [rsi], dl
    inc rsi
    loop hardcore_loop
    mov byte [rsi], 0
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    mov rax, 1
    mov rdi, 1
    mov rsi, success_msg
    mov rdx, success_msg_len
    syscall
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    mov rax, 1
    mov rdi, 1
    mov rsi, hardcore_password_buffer
    mov rdx, 20
    syscall
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    jmp main_loop

exit_program:
    mov rax, 60
    xor rdi, rdi
    syscall
