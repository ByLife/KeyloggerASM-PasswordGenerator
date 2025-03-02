section .data
    welcome_msg db "Bienvenue dans le générateur de mot de passe by LucMARTIN & Léo HAIDAR B-)", 10, 10
    welcome_msg_len equ $ - welcome_msg

    commands_msg db "Commandes disponibles:", 10, \
                    "  simple   : Génère un mot de passe de 8 caractères (chiffres et lettres)", 10, \
                    "  medium   : Génère un mot de passe de 10 caractères (chiffres, lettres et caracteres speciaux)", 10, \
                    "  hardcore : Génère un mot de passe de 20 caractères (chiffres, lettres et caracteres speciaux)", 10, \
                    "  custom   : Génère un mot de passe sur mesure", 10, \
                    "  help     : Affiche cette aide", 10, \
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

    help_str db "help"
    help_str_len equ $ - help_str

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

    non_str db "non"
    non_str_len equ $ - non_str

    lowercase_chars db "abcdefghijklmnopqrstuvwxyz"
    lowercase_chars_len equ $ - lowercase_chars

    uppercase_chars db "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    uppercase_chars_len equ $ - uppercase_chars

    numbers_chars db "0123456789"
    numbers_chars_len equ $ - numbers_chars

    special_chars db "!@#$%^&*()"
    special_chars_len equ $ - special_chars

    invalid_number_msg db "Ce n'est pas un nombre !", 10, 0
    invalid_number_msg_len equ $ - invalid_number_msg

    empty_number_msg db "Le champ ne doit pas etre vide !", 10, 0
    empty_number_msg_len equ $ - empty_number_msg

    invalid_response_msg db "Reponse invalide !", 10, 0
    invalid_response_msg_len equ $ - invalid_response_msg

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

    mov rdi, input_buffer
    mov rsi, custom_str
    mov rcx, custom_str_len
    repe cmpsb
    cmp rcx, 0
    je gen_custom

    mov rdi, input_buffer
    mov rsi, help_str
    mov rcx, help_str_len
    repe cmpsb
    cmp rcx, 0
    je print_help

    mov rax, 1
    mov rdi, 1
    mov rsi, unknown_cmd_msg
    mov rdx, unknown_cmd_msg_len
    syscall
    jmp main_loop

print_help:
    mov rax, 1
    mov rdi, 1
    mov rsi, commands_msg
    mov rdx, commands_msg_len
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
    ; Demande de la longueur custom
custom_length_input:
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
custom_length_trim:
    cmp rbx, 0
    je custom_length_conv
    cmp byte [rdi], 10
    jne custom_length_not_newline
    mov byte [rdi], 0
custom_length_not_newline:
    inc rdi
    dec rbx
    jmp custom_length_trim
custom_length_conv:
    xor rax, rax
    xor rcx, rcx
custom_conv_loop:
    mov bl, [input_buffer + rcx]
    cmp bl, 0
    je custom_conv_done
    cmp bl, '0'
    jb custom_conv_invalid
    cmp bl, '9'
    ja custom_conv_invalid
    imul rax, rax, 10
    sub bl, '0'
    movzx rbx, bl
    add rax, rbx
    inc rcx
    jmp custom_conv_loop
custom_conv_invalid:
    mov rax, 1
    mov rdi, 1
    mov rsi, invalid_number_msg
    mov rdx, invalid_number_msg_len
    syscall
    jmp custom_length_input
custom_conv_done:
    cmp rcx, 0
    je custom_empty_input
    mov r9, rax

    mov r8, custom_charset

    ; Minuscules
lowercase_loop:
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
lowercase_trim:
    cmp rbx, 0
    je lowercase_check
    cmp byte [rdi], 10
    jne lowercase_not_newline
    mov byte [rdi], 0
lowercase_not_newline:
    inc rdi
    dec rbx
    jmp lowercase_trim
lowercase_check:
    mov rdi, input_buffer
    mov rsi, yes_str
    mov rcx, yes_str_len
    repe cmpsb
    cmp rcx, 0
    je set_lowercase_yes
    mov rdi, input_buffer
    mov rsi, non_str
    mov rcx, non_str_len
    repe cmpsb
    cmp rcx, 0
    je set_lowercase_no
    mov rax, 1
    mov rdi, 1
    mov rsi, invalid_response_msg
    mov rdx, invalid_response_msg_len
    syscall
    jmp lowercase_loop
set_lowercase_yes:
    mov rdi, r8
    mov rcx, lowercase_chars_len
    mov rsi, lowercase_chars
    rep movsb
    mov r8, rdi
set_lowercase_no:

    ; Majuscules
uppercase_loop:
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
uppercase_trim:
    cmp rbx, 0
    je uppercase_check
    cmp byte [rdi], 10
    jne uppercase_not_newline
    mov byte [rdi], 0
uppercase_not_newline:
    inc rdi
    dec rbx
    jmp uppercase_trim
uppercase_check:
    mov rdi, input_buffer
    mov rsi, yes_str
    mov rcx, yes_str_len
    repe cmpsb
    cmp rcx, 0
    je set_uppercase_yes
    mov rdi, input_buffer
    mov rsi, non_str
    mov rcx, non_str_len
    repe cmpsb
    cmp rcx, 0
    je set_uppercase_no
    mov rax, 1
    mov rdi, 1
    mov rsi, invalid_response_msg
    mov rdx, invalid_response_msg_len
    syscall
    jmp uppercase_loop
set_uppercase_yes:
    mov rdi, r8
    mov rcx, uppercase_chars_len
    mov rsi, uppercase_chars
    rep movsb
    mov r8, rdi
set_uppercase_no:

    ; Nombres
numbers_loop:
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
numbers_trim:
    cmp rbx, 0
    je numbers_check
    cmp byte [rdi], 10
    jne numbers_not_newline
    mov byte [rdi], 0
numbers_not_newline:
    inc rdi
    dec rbx
    jmp numbers_trim
numbers_check:
    mov rdi, input_buffer
    mov rsi, yes_str
    mov rcx, yes_str_len
    repe cmpsb
    cmp rcx, 0
    je set_numbers_yes
    mov rdi, input_buffer
    mov rsi, non_str
    mov rcx, non_str_len
    repe cmpsb
    cmp rcx, 0
    je set_numbers_no
    mov rax, 1
    mov rdi, 1
    mov rsi, invalid_response_msg
    mov rdx, invalid_response_msg_len
    syscall
    jmp numbers_loop
set_numbers_yes:
    mov rdi, r8
    mov rcx, numbers_chars_len
    mov rsi, numbers_chars
    rep movsb
    mov r8, rdi
set_numbers_no:

    ; Caracteres speciaux
special_loop:
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
special_trim:
    cmp rbx, 0
    je special_check
    cmp byte [rdi], 10
    jne special_not_newline
    mov byte [rdi], 0
special_not_newline:
    inc rdi
    dec rbx
    jmp special_trim
special_check:
    mov rdi, input_buffer
    mov rsi, yes_str
    mov rcx, yes_str_len
    repe cmpsb
    cmp rcx, 0
    je set_special_yes
    mov rdi, input_buffer
    mov rsi, non_str
    mov rcx, non_str_len
    repe cmpsb
    cmp rcx, 0
    je set_special_no
    mov rax, 1
    mov rdi, 1
    mov rsi, invalid_response_msg
    mov rdx, invalid_response_msg_len
    syscall
    jmp special_loop
set_special_yes:
    mov rdi, r8
    mov rcx, special_chars_len
    mov rsi, special_chars
    rep movsb
    mov r8, rdi
set_special_no:

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

custom_empty_input:
    mov rax, 1
    mov rdi, 1
    mov rsi, empty_number_msg
    mov rdx, empty_number_msg_len
    syscall
    jmp custom_length_input

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
