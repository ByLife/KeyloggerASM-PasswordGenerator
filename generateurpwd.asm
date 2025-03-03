section .data
    ; message de bienvenue
    welcome_msg db "Bienvenue dans le générateur de mot de passe by LucMARTIN & Léo HAIDAR B-)", 10, 10
    welcome_msg_len equ $ - welcome_msg

    ; liste des commandes disponibles
    commands_msg db "Commandes disponibles:", 10, \
                    "  simple   : Génère un mot de passe de 8 caractères (chiffres et lettres)", 10, \
                    "  medium   : Génère un mot de passe de 10 caractères (chiffres, lettres et caracteres speciaux)", 10, \
                    "  hardcore : Génère un mot de passe de 20 caractères (chiffres, lettres et caracteres speciaux)", 10, \
                    "  custom   : Génère un mot de passe sur mesure", 10, \
                    "  help     : Affiche cette aide", 10, \
                    "  exit     : Quitte le programme", 10, 10
    commands_msg_len equ $ - commands_msg

    ; prompt de commande
    prompt_msg db "Entrez une commande: ", 0
    prompt_msg_len equ $ - prompt_msg

    ; message de succes
    success_msg db "Mot de passe généré !", 10, 0
    success_msg_len equ $ - success_msg

    ; message commande inconnue
    unknown_cmd_msg db "Commande inconnue !", 10, 10, 0
    unknown_cmd_msg_len equ $ - unknown_cmd_msg

    newline db 10

    ; ensemble de caracteres pour simple
    allowed_chars db "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz", 0
    allowed_len equ $ - allowed_chars - 1

    ; ensemble de caracteres pour medium et hardcore
    allowed_medium_chars db "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz!@#$%^&*()", 0
    allowed_medium_chars_len equ $ - allowed_medium_chars - 1

    exit_str   db "exit", 0
    exit_str_len equ $ - exit_str - 1

    simple_str db "simple", 0
    simple_str_len equ $ - simple_str - 1

    medium_str db "medium", 0
    medium_str_len equ $ - medium_str - 1

    hardcore_str db "hardcore", 0
    hardcore_str_len equ $ - hardcore_str - 1

    custom_str db "custom", 0
    custom_str_len equ $ - custom_str - 1

    help_str db "help", 0
    help_str_len equ $ - help_str - 1

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

    none_selected_msg db "Aucun caractere selectionne !", 10, 10, 0
    none_selected_msg_len equ $ - none_selected_msg

    yes_str db "oui", 0
    yes_str_len equ $ - yes_str - 1

    non_str db "non", 0
    non_str_len equ $ - non_str - 1

    lowercase_chars db "abcdefghijklmnopqrstuvwxyz", 0
    lowercase_chars_len equ $ - lowercase_chars - 1

    uppercase_chars db "ABCDEFGHIJKLMNOPQRSTUVWXYZ", 0
    uppercase_chars_len equ $ - uppercase_chars - 1

    numbers_chars db "0123456789", 0
    numbers_chars_len equ $ - numbers_chars - 1

    special_chars db "!@#$%^&*()", 0
    special_chars_len equ $ - special_chars - 1

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
    global _start, exit_program, display_result

_start:
    ; affichage du message de bienvenue
    mov rax, 1
    mov rdi, 1
    mov rsi, welcome_msg
    mov rdx, welcome_msg_len
    syscall

    ; affichage de la liste des commandes
    mov rax, 1
    mov rdi, 1
    mov rsi, commands_msg
    mov rdx, commands_msg_len
    syscall

main_loop:
    ; affichage du prompt de commande
    mov rax, 1
    mov rdi, 1
    mov rsi, prompt_msg
    mov rdx, prompt_msg_len
    syscall

    ; lecture de la commande entree
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
    ; verification de la commande exit
    mov rdi, input_buffer
    mov rsi, exit_str
    mov rcx, exit_str_len
    repe cmpsb
    cmp rcx, 0
    je exit_program

    ; verification de la commande simple
    mov rdi, input_buffer
    mov rsi, simple_str
    mov rcx, simple_str_len
    repe cmpsb
    cmp rcx, 0
    je gen_simple

    ; verification de la commande medium
    mov rdi, input_buffer
    mov rsi, medium_str
    mov rcx, medium_str_len
    repe cmpsb
    cmp rcx, 0
    je gen_medium

    ; verification de la commande hardcore
    mov rdi, input_buffer
    mov rsi, hardcore_str
    mov rcx, hardcore_str_len
    repe cmpsb
    cmp rcx, 0
    je gen_hardcore

    ; verification de la commande custom
    mov rdi, input_buffer
    mov rsi, custom_str
    mov rcx, custom_str_len
    repe cmpsb
    cmp rcx, 0
    je gen_custom

    ; verification de la commande help
    mov rdi, input_buffer
    mov rsi, help_str
    mov rcx, help_str_len
    repe cmpsb
    cmp rcx, 0
    je print_help

    ; commande inconnue
    mov rax, 1
    mov rdi, 1
    mov rsi, unknown_cmd_msg
    mov rdx, unknown_cmd_msg_len
    syscall
    jmp main_loop

print_help:
    ; affiche la liste des commandes
    mov rax, 1
    mov rdi, 1
    mov rsi, commands_msg
    mov rdx, commands_msg_len
    syscall
    jmp main_loop

gen_simple:
    ; generation du mot de passe simple
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
    ; appel de la fonction d'affichage du resultat
    mov rdi, simple_password_buffer
    mov rsi, 8
    call display_result
    jmp main_loop

gen_medium:
    ; generation du mot de passe medium
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
    ; appel de la fonction d'affichage du resultat
    mov rdi, medium_password_buffer
    mov rsi, 10
    call display_result
    jmp main_loop

gen_hardcore:
    ; generation du mot de passe hardcore
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
    ; appel de la fonction d'affichage du resultat
    mov rdi, hardcore_password_buffer
    mov rsi, 20
    call display_result
    jmp main_loop

gen_custom:
    ; demande de la longueur custom
custom_length_input:
    mov rax, 1
    mov rdi, 1
    mov rsi, custom_length_prompt
    mov rdx, custom_length_prompt_len
    syscall
    ; lecture de la longueur custom
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
    ; verifie si le champ est vide
    cmp byte [input_buffer], 0
    je custom_empty_input
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
    mov r9, rax

    ; initialisation du charset custom
    mov r8, custom_charset

    ; demande pour lettres minuscules
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
    ; ce commantaire contient une faulte intentionelle
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

    ; demande pour lettres majuscules
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

    ; demande pour nombres
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

    ; demande pour caracteres speciaux
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
    ; verifie que le charset custom n'est pas vide
    mov rax, r8
    sub rax, custom_charset
    cmp rax, 0
    je custom_no_charset
    ; generation du mot de passe custom
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
    ; appel de la fonction d'affichage du resultat final
    mov rdi, custom_password_buffer
    mov rsi, r9
    call display_result
    jmp main_loop

custom_empty_input:
    ; champ vide pour la longueur custom
    mov rax, 1
    mov rdi, 1
    mov rsi, empty_number_msg
    mov rdx, empty_number_msg_len
    syscall
    jmp custom_length_input

custom_no_charset:
    ; aucun charset selectionne
    mov rax, 1
    mov rdi, 1
    mov rsi, none_selected_msg
    mov rdx, none_selected_msg_len
    syscall
    jmp main_loop

exit_program:
    ; fin du programme
    mov rax, 60
    xor rdi, rdi
    syscall

; fonction d'affichage du resultat
; rdi = pointer to password, rsi = length of password
display_result:
    mov r8, rdi   ; sauvegarde du pointer
    mov r9, rsi   ; sauvegarde de la longueur
    ; affichage d'un saut de ligne
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    ; affichage du message de succes
    mov rax, 1
    mov rdi, 1
    mov rsi, success_msg
    mov rdx, success_msg_len
    syscall
    ; affichage d'un saut de ligne
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    ; affichage du mot de passe
    mov rax, 1
    mov rdi, 1
    mov rsi, r8
    mov rdx, r9
    syscall
    ; affichage de deux sauts de ligne
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
    ret
