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
            mov rax, 0x01      ; write64 (rdi, rsi, rdx) ... r10, r8, r9
            mov rdi, 1         ; stdout
            mov rsi, Msg
            mov rdx, MsgLen    ; strlen (Msg)
            syscall

            mov rax, 0x01
            mov rdi, 1
            mov rsi, [rbp + 8]
            mov rdx, MsgLen
            syscall
            ret

global _start                  ; predefined entry point name for ld



_start:

            push rbp
            mov rbp, rsp

            push Msg
            push 1
            call nasm_printf

            mov rsp, rbp
            pop rbp

            mov rax, 0x3C      ; exit64 (rdi)
            xor rdi, rdi
            syscall

section     .data

Msg:        db "__Hllwrld", 0x0a
MsgLen      equ $ - Msg
