section .data
    welcome_msg db "Bienvenue dans le générateur de mot de passe by LucMARTIN & Léo HAIDAR B-)", 10, 10
    welcome_msg_len equ $ - welcome_msg

    commands_msg db "Commandes disponibles:", 10, \
                    "  simple   : Génère un mot de passe de 8 caractères (chiffres et lettres)", 10, \
                    "  medium   : Génère un mot de passe de 10 caractères (chiffres, lettres et caractères speciaux)", 10, \
                    "  hardcore : Génère un mot de passe de 20 caractères (chiffres, lettres et caractères speciaux)", 10, \
                    "  custom   : Génère un mot de passe sur mesure", 10, \
                    "  exit     : Quitte le programme", 10, 10
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

    custom_str db "custom"
    custom_str_len equ $ - custom_str

    custom_length_prompt db "Entrez la longueur du mot de passe custom: ", 0
    custom_length_prompt_len equ $ - custom_length_prompt

    custom_lowercase_prompt db "Inclure des lettres minuscules ? (oui/non): ", 0
    custom_lowercase_prompt_len equ $ - custom_lowercase_prompt

    custom_uppercase_prompt db "Inclure des lettres majuscules ? (oui/non): ", 0
    custom_uppercase_prompt_len equ $ - custom_uppercase_prompt

    custom_numbers_prompt db "Inclure des nombres ? (oui/non): ", 0
    custom_numbers_prompt_len equ $ - custom_numbers_prompt

    custom_special_prompt db "Inclure des caracteres speciaux ? (oui/non): ", 0
    custom_special_prompt_len equ $ - custom_special_prompt

    none_selected_msg db "Aucun caractere selectionne !", 10, 10
    none_selected_msg_len equ $ - none_selected_msg

    yes_str db "oui"
    yes_str_len equ $ - yes_str

    lowercase_chars db "abcdefghijklmnopqrstuvwxyz"
    lowercase_chars_len equ $ - lowercase_chars

    uppercase_chars db "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    uppercase_chars_len equ $ - uppercase_chars

    numbers_chars db "0123456789"
    numbers_chars_len equ $ - numbers_chars

    special_chars db "!@#$%^&*()"
    special_chars_len equ $ - special_chars

section .bss
    input_buffer resb 16
    simple_password_buffer resb 9
    medium_password_buffer resb 11
    hardcore_password_buffer resb 21
    custom_charset resb 256
    custom_password_buffer resb 256
    seed resq 1

section .text
    global _start

_start:
    mov rax, 1; welcome
    mov rdi, 1
    mov rsi, welcome_msg
    mov rdx, welcome_msg_len
    syscall

    mov rax, 1; commandes
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

    mov rdi, input_buffer
    mov rsi, custom_str
    mov rcx, custom_str_len
    repe cmpsb
    cmp rcx, 0
    je gen_custom

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

gen_custom:
    mov rax, 1
    mov rdi, 1
    mov rsi, custom_length_prompt
    mov rdx, custom_length_prompt_len
    syscall
    mov rax, 0
    mov rdi, 0
    mov rsi, input_buffer
    mov rdx, 16
    syscall
    mov rbx, rax
    mov rdi, input_buffer
custom_trim_loop:
    cmp rbx, 0
    je custom_after_trim
    cmp byte [rdi], 10
    jne custom_not_newline
    mov byte [rdi], 0
custom_not_newline:
    inc rdi
    dec rbx
    jmp custom_trim_loop
custom_after_trim:
    xor rax, rax
    xor rcx, rcx
custom_conv_loop:
    mov bl, [input_buffer + rcx]
    cmp bl, 0
    je custom_conv_done
    cmp bl, '0'
    jb custom_conv_done
    cmp bl, '9'
    ja custom_conv_done
    imul rax, rax, 10
    sub bl, '0'
    movzx rbx, bl
    add rax, rbx
    inc rcx
    jmp custom_conv_loop
custom_conv_done:
    mov r9, rax

    mov r8, custom_charset

    mov rax, 1
    mov rdi, 1
    mov rsi, custom_lowercase_prompt
    mov rdx, custom_lowercase_prompt_len
    syscall
    mov rax, 0
    mov rdi, 0
    mov rsi, input_buffer
    mov rdx, 16
    syscall
    mov rbx, rax
    mov rdi, input_buffer
custom_trim_loop2:
    cmp rbx, 0
    je custom_after_trim2
    cmp byte [rdi], 10
    jne custom_not_newline2
    mov byte [rdi], 0
custom_not_newline2:
    inc rdi
    dec rbx
    jmp custom_trim_loop2
custom_after_trim2:
    mov rdi, input_buffer
    mov rsi, yes_str
    mov rcx, yes_str_len
    repe cmpsb
    cmp rcx, 0
    jne custom_skip_lowercase
    mov rdi, r8
    mov rcx, lowercase_chars_len
    mov rsi, lowercase_chars
    rep movsb
    mov r8, rdi
custom_skip_lowercase:
    mov rax, 1
    mov rdi, 1
    mov rsi, custom_uppercase_prompt
    mov rdx, custom_uppercase_prompt_len
    syscall
    mov rax, 0
    mov rdi, 0
    mov rsi, input_buffer
    mov rdx, 16
    syscall
    mov rbx, rax
    mov rdi, input_buffer
custom_trim_loop3:
    cmp rbx, 0
    je custom_after_trim3
    cmp byte [rdi], 10
    jne custom_not_newline3
    mov byte [rdi], 0
custom_not_newline3:
    inc rdi
    dec rbx
    jmp custom_trim_loop3
custom_after_trim3:
    mov rdi, input_buffer
    mov rsi, yes_str
    mov rcx, yes_str_len
    repe cmpsb
    cmp rcx, 0
    jne custom_skip_uppercase
    mov rdi, r8
    mov rcx, uppercase_chars_len
    mov rsi, uppercase_chars
    rep movsb
    mov r8, rdi
custom_skip_uppercase:
    mov rax, 1
    mov rdi, 1
    mov rsi, custom_numbers_prompt
    mov rdx, custom_numbers_prompt_len
    syscall
    mov rax, 0
    mov rdi, 0
    mov rsi, input_buffer
    mov rdx, 16
    syscall
    mov rbx, rax
    mov rdi, input_buffer
custom_trim_loop4:
    cmp rbx, 0
    je custom_after_trim4
    cmp byte [rdi], 10
    jne custom_not_newline4
    mov byte [rdi], 0
custom_not_newline4:
    inc rdi
    dec rbx
    jmp custom_trim_loop4
custom_after_trim4:
    mov rdi, input_buffer
    mov rsi, yes_str
    mov rcx, yes_str_len
    repe cmpsb
    cmp rcx, 0
    jne custom_skip_numbers
    mov rdi, r8
    mov rcx, numbers_chars_len
    mov rsi, numbers_chars
    rep movsb
    mov r8, rdi
custom_skip_numbers:
    mov rax, 1
    mov rdi, 1
    mov rsi, custom_special_prompt
    mov rdx, custom_special_prompt_len
    syscall
    mov rax, 0
    mov rdi, 0
    mov rsi, input_buffer
    mov rdx, 16
    syscall
    mov rbx, rax
    mov rdi, input_buffer
custom_trim_loop5:
    cmp rbx, 0
    je custom_after_trim5
    cmp byte [rdi], 10
    jne custom_not_newline5
    mov byte [rdi], 0
custom_not_newline5:
    inc rdi
    dec rbx
    jmp custom_trim_loop5
custom_after_trim5:
    mov rdi, input_buffer
    mov rsi, yes_str
    mov rcx, yes_str_len
    repe cmpsb
    cmp rcx, 0
    jne custom_skip_special
    mov rdi, r8
    mov rcx, special_chars_len
    mov rsi, special_chars
    rep movsb
    mov r8, rdi
custom_skip_special:
    mov rax, r8
    sub rax, custom_charset
    cmp rax, 0
    je custom_no_charset
    mov r10, rax
    rdtsc
    mov rbx, rdx
    shl rbx, 32
    or rbx, rax
    mov [seed], rbx
    xor rcx, rcx
custom_gen_loop:
    cmp rcx, r9
    jge custom_gen_done
    mov rax, [seed]
    mov rbx, 1103515245
    mul rbx
    add rax, 12345
    mov [seed], rax
    shr rax, 16
    mov rbx, r10
    xor rdx, rdx
    div rbx
    mov rbx, custom_charset
    add rbx, rdx
    mov dl, byte [rbx]
    mov byte [custom_password_buffer + rcx], dl
    inc rcx
    jmp custom_gen_loop
custom_gen_done:
    mov byte [custom_password_buffer + rcx], 0
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
    mov rsi, custom_password_buffer
    mov rdx, r9
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

custom_no_charset:
    mov rax, 1
    mov rdi, 1
    mov rsi, none_selected_msg
    mov rdx, none_selected_msg_len
    syscall
    jmp main_loop

exit_program:
    mov rax, 60
    xor rdi, rdi
    syscall
