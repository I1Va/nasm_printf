;:================================================
;: 0-Linux-nasm-64.s                   (c)Ded,2012
;:================================================

; nasm -f elf64 -l 0-Linux-nasm-64.lst 0-Linux-nasm-64.s  ;  ld -s -o 0-Linux-nasm-64 0-Linux-nasm-64.o

section .text

;:================================================
;:              nasm_printf
;:================================================
;:
;:
;:
;:================================================
nasm_printf:
            mov rax, 0x01           ; write
            mov rdi, 1              ; stdout
            mov rsi, [rsp + 8]      ; msg offset
            mov rdx, [rsp + 16]     ; msg len
            syscall
            ret

global _start                  ; predefined entry point name for ld


_start:


            push rbp
            mov rbp, rsp

            push 10
            push Msg1
            call nasm_printf

            mov rsp, rbp       ; remove all stack arguments
            pop rbp            ; restore old stack frame

            mov rax, 0x3C      ; exit64 (rdi)
            xor rdi, rdi       ; exit_code = 0
            syscall

section     .data

Msg:        db "__Hllwrld", 0x0a
Msg1:        db "I love asm!!!!:((", 0x0a
MsgLen      equ $ - Msg
