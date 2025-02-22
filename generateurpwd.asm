section .data
    welcome_msg db "Bienvenue dans le générateur de mot de passe", 10
    welcome_msg_len equ $ - welcome_msg

    prompt_msg  db "Entrez 1 pour générer un mot de passe: "
    prompt_msg_len equ $ - prompt_msg

    newline db 10

    ; Ensemble des caractères possibles (10 chiffres + 26 lettres majuscules + 26 lettres minuscules = 62 caractères)
    allowed_chars db "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
    allowed_len equ $ - allowed_chars

section .bss
    input_buffer resb 2           ; Pour lire la saisie (1 caractère + retour)
    password_buffer resb 9        ; 8 caractères + caractère nul (optionnel)
    seed resq 1                   ; Pour stocker la graine du générateur pseudo-aléatoire

section .text
    global _start
_start:
    ; Afficher le message de bienvenue
    mov rax, 1                  ; sys_write
    mov rdi, 1                  ; stdout
    mov rsi, welcome_msg
    mov rdx, welcome_msg_len
    syscall

    ; Afficher le prompt
    mov rax, 1
    mov rdi, 1
    mov rsi, prompt_msg
    mov rdx, prompt_msg_len
    syscall

    ; Lire l'entrée utilisateur
    mov rax, 0                  ; sys_read
    mov rdi, 0                  ; stdin
    mov rsi, input_buffer
    mov rdx, 2
    syscall

    ; Vérifier si l'entrée est "1"
    mov al, byte [input_buffer]
    cmp al, '1'
    jne exit_program            ; Si ce n'est pas "1", on quitte

    ; Initialiser la graine avec le compteur du processeur (RDTSC)
    rdtsc                       ; RAX = partie basse, RDX = partie haute
    mov rbx, rdx
    shl rbx, 32
    or rbx, rax
    mov [seed], rbx

    ; Générer le mot de passe de 8 caractères
    mov rcx, 8                  ; Compteur pour 8 itérations
    mov rsi, password_buffer    ; Pointeur vers le buffer du mot de passe
gen_loop:
    ; Calculer : seed = seed * 1103515245 + 12345 (même formule que le C rand)
    mov rax, [seed]
    mov rbx, 1103515245
    mul rbx                     ; rdx:rax = rax * rbx (multiplication non signée)
    add rax, 12345
    mov [seed], rax

    ; Pour obtenir un index dans [0, 61] :
    ; On décale de 16 bits (similaire à rand() en C) et on prend le modulo 62
    shr rax, 16
    mov rbx, 62
    xor rdx, rdx
    div rbx                     ; RAX = quotient, RDX = reste (index dans [0, 61])

    ; Récupérer le caractère correspondant dans allowed_chars
    mov rbx, allowed_chars
    add rbx, rdx
    mov dl, byte [rbx]

    ; Stocker le caractère dans le buffer du mot de passe
    mov byte [rsi], dl
    inc rsi
    loop gen_loop

    ; Terminer la chaîne (optionnel)
    mov byte [rsi], 0

    ; Afficher un retour à la ligne
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall

    ; Afficher le mot de passe généré (8 caractères)
    mov rax, 1
    mov rdi, 1
    mov rsi, password_buffer
    mov rdx, 8
    syscall

exit_program:
    ; Quitter le programme
    mov rax, 60                 ; sys_exit
    xor rdi, rdi
    syscall
