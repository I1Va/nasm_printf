;:================================================
;: 0-Linux-nasm-64.s                   (c)Ded,2012
;:================================================

; nasm -f elf64 -l 0-Linux-nasm-64.lst 0-Linux-nasm-64.s  ;  ld -s -o 0-Linux-nasm-64 0-Linux-nasm-64.o

section .text

;:================================================
;:              nasm_printf
;:================================================
;: cdecl
;: prints args according to format
;:
;:================================================
nasm_printf:
            ; [rsp + 0] - ret addr
            ; [rsp + 8] - fmt string
            ; [rsp + 16] - arg1
            ; [rsp + 24] - arg2
            ; ...

            mov rbp, rsp
            add rbp, 16
            mov rbx, [rsp + 8]      ; fmt offset

fmt_loop:
            cmp byte [rbx], 0x00    ; if fmt[rbx] == 0 -> fmt_loop_end
            je fmt_loop_end

            cmp byte [rbx], '%'
            je process_specifier

            mov rax, 0x01           ; write
            mov rdi, 1              ; stdout
            mov rsi, rbx            ; cur_fmt_char = byte [rbx]
            mov rdx, 1              ; len = 1
            syscall                 ; outchar(cur_fmt_char)

            inc rbx                 ; next fmt_char
            jmp fmt_loop            ;

process_specifier:
            inc rbx                 ; cur_fmt_char - specificator

                                    ; switch (cur_fmt_char)
            cmp byte [rbx], 'c'     ; if cur_char == 'c'
            je print_char

process_specifier_end:

            inc rbx                 ; next fmt_char
            jmp fmt_loop

print_char:
            mov rax, 0x01           ; write
            mov rdi, 1              ; stdout
            mov rsi, rbp            ; string_addr = &cur_arg
            mov rdx, 1              ; len = 1
            syscall                 ; outchar(char)

            add rbp, 8              ; next arg
            jmp process_specifier_end

fmt_loop_end:

            ret

global _start                  ; predefined entry point name for ld


_start:


            push rbp
            mov rbp, rsp

            push '@'
            push '^'
            push '*'
            push fmt_string
            call nasm_printf

            mov rsp, rbp       ; remove all stack arguments
            pop rbp            ; restore old stack frame

            mov rax, 0x3C      ; exit64 (rdi)
            xor rdi, rdi       ; exit_code = 0
            syscall

section     .data

Msg:        db "__Hllwrld", 0x0a, 0x0
MsgLen      equ $ - Msg

fmt_string db "'%c' '%c' '%c'", 0x0a, 0x00
