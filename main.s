;:================================================
;: 0-Linux-nasm-64.s                   (c)Ded,2012
;:================================================

; nasm -f elf64 -l 0-Linux-nasm-64.lst 0-Linux-nasm-64.s  ;  ld -s -o 0-Linux-nasm-64 0-Linux-nasm-64.o

section .text

;:================================================
;:                  c_strlen
;:================================================
;: compute length of c_string (terminated by a 0x00 character)
;: ENTRY:
;:      rdi - string addr
;: DESTROY:
;:      rdi, rax
;: RETURN:
;:      rax - string len (not counting 0x00 character)
;:
;:================================================
c_strlen:
            xor rax, rax
            dec rdi
c_strlen_while:
            inc rax
            inc rdi

            cmp byte [rdi], 0x00
            jne c_strlen_while

            dec rax
            ret
;:================================================



;:================================================
;:                  stdout_flush
;:================================================
;: flushes stdout bufer
;:
;: ENTRY:
;:      NONE
;: DESTROY:
;:      rax, rdi, rsi, rdx
;: GLOBAL:
;:      stdout_bufer_size
;:      stdout_bufer
;:      stdout_bufer_idx
;: RETURN:
;:      NONE
;:
;:================================================
stdout_flush:
        mov rax, 0x01               ; write
        mov rdi, 1                  ; stdout
        mov rsi, stdout_bufer       ; string_addr
        mov rdx, qword [stdout_bufer_idx]   ; len
        syscall

        mov qword [stdout_bufer_idx], 0x0000000000000000

        ret
;:================================================





;:================================================
;:                  nasm_puts
;:================================================
;: put string in stdin bufer
;: ENTRY:
;:      rdi - string addr
;:      rsi - string len
;: DESTROY:
;:      rdi, rsi, rdx, r8, r9
;: GLOBAL:
;:      stdout_bufer_size
;:      stdout_bufer
;:      stdout_bufer_idx
;: RETURN:
;:
;:
;:================================================
nasm_puts:
            mov r8, rdi                                 ; save string addr
            mov r9, rsi                                 ; save string len

            cmp rsi, stdout_bufer_size                  ;| if string doesn't fit into stdout bufer
            jg  .not_fit                                ;| -> flush + print string

            mov rdx, qword [stdout_bufer_idx]           ;| if bufer + string overflows
            add rdx, rsi                                ;| -> flush + write string to bufer
            cmp rdx, stdout_bufer_size                  ;|
            jge .stdout_overflow                        ;|

            jmp .fit

.not_fit:
            call stdout_flush                           ; destr (rax, rdi, rsi, rdx)

            mov rsi, r8                                 ; string_addr
            mov rdx, r9                                 ; len
            mov rax, 0x01                               ; write
            mov rdi, 1                                  ; stdout
            syscall

            jmp .end

.stdout_overflow:
            call stdout_flush                           ; destr (rax, rdi, rsi, rdx)

            jmp .fit

.fit:
            mov rcx, r9                                 ; len
            mov rdi, stdout_bufer                       ;|dst
            add rdi, qword [stdout_bufer_idx]           ;|
            mov rsi, r8                                 ; src
            rep movsb                                   ; copy string to bufer

            mov rcx, qword[stdout_bufer_idx]            ;|
            add rcx, r9                                 ;| move bufer idx
            mov qword[stdout_bufer_idx], rcx            ;|

            jmp .end

.end:
            ret

;:================================================


;:================================================
;:              nasm_printf
;:================================================
;: fastcall_4
;: prints args according to format
;:
;:================================================
nasm_printf:
            pop r10                 ; r10 = ret addr

            push rcx                ; 4'th arg
            push rdx                ; 3'rd arg
            push rsi                ; 2'nd arg
            push rdi                ; 1'st arg

            push r10

            mov rbp, rsp
            add rbp, 16
            mov rbx, [rsp + 8]      ; fmt offset

.fmt_loop:
            cmp byte [rbx], 0x00    ; if fmt[rbx] == 0 -> fmt_loop_end
            je .fmt_loop_end

            cmp byte [rbx], '%'
            je .proc_specifier
                                    ; put 1 char from fmt into stdout bufer
            mov rdi, rbx            ; string addr = rbx
            mov rsi, 1              ; string len = 1
            call nasm_puts          ; DESTR(rdi, rsi, rdx, r8, r9)

            inc rbx                 ; next fmt_char
            jmp .fmt_loop           ;

.proc_specifier:
            inc rbx                 ; cur_fmt_char - specificator

                                    ; switch (cur_fmt_char)
            cmp byte [rbx], 'c'     ; if cur_char == 'c'
            je .print_char

            cmp byte [rbx], 's'
            je .print_c_string

            ; cmp byte [rbx], 'x'
            ; je print_hex

.proc_specifier_end:

            inc rbx                 ; next fmt_char
            jmp .fmt_loop

.print_char:
                                    ; put 1 char from arg into stdout bufer
            mov rdi, rbp            ; string addr = rbx
            mov rsi, 1              ; string len = 1
            call nasm_puts          ; DESTR(rdi, rsi, rdx, r8, r9)

            add rbp, 8              ; next arg
            jmp .proc_specifier_end

.print_c_string:

            mov rdi, qword [rbp]    ; rdi = cur_arg - string addr
            call c_strlen           ; -> rax - string len

            mov rdi, qword[rbp]
            mov rsi, rax
            call nasm_puts          ; DESTR(rdi, rsi, rdx, r8, r9)

            add rbp, 8              ; next arg
            jmp .proc_specifier_end

.fmt_loop_end:

            ret

global _start                  ; predefined entry point name for ld


_start:

            push rbp

            ;push '5'            ; 5'th arg
            mov rcx, '4'        ; 4'th arg
            mov rdx, '3'        ; 3'rd arg
            mov rsi, Msg        ; 2'nd arg
            mov rdi, fmt_string ; 1'st arg

            call nasm_printf

            add rsp, 0          ; clear stack
            pop rbp             ; restore old stack frame


            ; mov rdi, Msg
            ; call c_strlen
            ; mov qword [stdout_bufer_idx], rax

            ; mov rsi, Msg            ; в RSI - откуда копируем
            ; mov rdi, stdout_bufer   ; в RDI - куда копируем
            ; mov rcx, rax            ; в RCX - сколько копируем
            ; rep movsb               ; выполняем копирование по отдельным словам

            call stdout_flush

            mov rax, 0x3C      ; exit64 (rdi)
            xor rdi, rdi       ; exit_code = 0
            syscall

section     .data

Msg:        db "Subtrefwfewe", 0x00
MsgLen      equ $ - Msg
fmt_string  db "%s %c %c", 0x0a, 0x00
stdout_bufer_size equ 32
stdout_bufer db stdout_bufer_size dup(0x00)
stdout_bufer_idx dq 0

