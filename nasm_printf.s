global nasm_printf
global stdout_flush
section .text
;================================================================================================
;                  c_strlen
;================================================================================================
; DESCR:
;       compute length of c_string (terminated by a 0x00 character)
; ENTRY:
;       rdi - string addr
; DESTROY:
;       rdi, rax
; RETURN:
;       rax - string len (not counting 0x00 character)
;================================================================================================
c_strlen:
            xor     rax, rax                            ; rax = 0
            dec     rdi                                 ; rdi--
c_strlen_while:
            inc     rax                                 ; rax++
            inc     rdi                                 ; rdi++

            cmp     byte [rdi], 0x00                    ; if str[rdi] == 0x0 -> end
            jne     c_strlen_while                      ;

            dec     rax                                 ; rax-- (not counting terminating sym)

            ret
;================================================================================================



;================================================================================================
;                  stdout_flush
;================================================================================================
; DESCR:
;       flushes stdout bufer
; ENTRY:
;       None
; DESTROY:
;       rax, rdi, rsi, rdx
; GLOBAL:
;       stdout_bufer_size
;       stdout_bufer
;       stdout_bufer_idx
; RETURN:
;       None
;================================================================================================
stdout_flush:
        mov     rax, 0x01                               ; write
        mov     rdi, 1                                  ; stdout
        lea     rsi, [rel stdout_bufer]                 ; string_addr
        mov     rdx, qword [rel stdout_bufer_idx]       ; len
        syscall

        mov     qword [rel stdout_bufer_idx], 0x0       ; stdout_bufer_idx = 0

        ret
;================================================================================================



;================================================================================================
;                  nasm_puts
;================================================================================================
; DESCR:
;       put string in stdin bufer
; ENTRY:
;       rdi - string addr
;       rsi - string len
; DESTROY:
;       rdi, rsi, rdx, r8, r9
; GLOBAL:
;       stdout_bufer_size
;       stdout_bufer
;       stdout_bufer_idx
; RETURN:
;       None
;================================================================================================
nasm_puts:
            mov     r8, rdi                             ; save string addr
            mov     r9, rsi                             ; save string len

            cmp     rsi, stdout_bufer_size              ;| if string doesn't fit into stdout bufer
            jg      .not_fit                            ;| -> flush + print string

            mov     rdx, qword [rel stdout_bufer_idx]       ;| if bufer + string overflows
            add     rdx, rsi                            ;| -> flush + write string to bufer
            cmp     rdx, stdout_bufer_size              ;|
            jge     .stdout_overflow                    ;|

            jmp     .fit                                ; else string fit into bufer

.not_fit:
            call    stdout_flush                        ; destr (rax, rdi, rsi, rdx)

            mov     rsi, r8                             ; string_addr
            mov     rdx, r9                             ; len
            mov     rax, 0x01                           ; write
            mov     rdi, 1                              ; stdout
            syscall

            jmp .end

.stdout_overflow:
            call    stdout_flush                        ; destr (rax, rdi, rsi, rdx)

            jmp     .fit

.fit:
            mov     rcx, r9                             ; len
            lea     rdi, [rel stdout_bufer]             ;|dst
            add     rdi, qword [rel stdout_bufer_idx]
            mov     rsi, r8                             ; src
            rep     movsb                               ; copy string to bufer

            mov     rcx, qword[rel stdout_bufer_idx]        ;|
            add     rcx, r9                             ;| move bufer idx
            mov     qword[rel stdout_bufer_idx], rcx        ;|

            jmp     .end

.end:
            ret
;================================================================================================



;================================================================================================
;                  nasm_putchar
;================================================================================================
; DESCR:
;       put char in stdin bufer
; ENTRY:
;       rdi - character to be written
; DESTROY:
;       rdi, rsi, rdx, r8, r9
; GLOBAL:
;       stdout_bufer_size
;       stdout_bufer
;       stdout_bufer_idx
; RETURN:
;       None
;================================================================================================
nasm_putchar:
            mov     qword [rsp - 16], rdi               ; writes into stack memory input ascii code [rsp-16, rsp-8)
                                                        ; [rsp-8, rsp) reserved for nasm_puts return address

            lea     rdi, [rsp - 16]                     ;|
            mov     rsi, 1                              ;| put char into stdout bufer
            call    nasm_puts                           ;|

            ret
;================================================================================================



;================================================================================================
;
;================================================================================================
; DESCR:
;       converts a number (rdi) to a base(rsi) in two's complement form
; ENTRY:
;       rdi - input number
;       rsi - base
; DESTROY:
;       rdi, rsi, rdx, rcx, r8
; GLOBAL:
;       stdout_bufer_size
;       stdout_bufer
;       stdout_bufer_idx
; RETURN:
;       None
;================================================================================================
nasm_putnum:
            mov     qword [rsp-80], 0                   ;|  initializes bytes in the stack for bufer
            mov     qword [rsp-72], 0                   ;|
            mov     qword [rsp-64], 0                   ;|  STACK:
            mov     qword [rsp-56], 0                   ;|  [rsp-80, rsp-16)    - bufer size of 64
            mov     qword [rsp-48], 0                   ;|  [rsp-16, rsp-8)     - extra zero space, for c_strlen correct work
            mov     qword [rsp-40], 0                   ;|  [rsp-8, rsp)        - reserved for nasm_puts return address
            mov     qword [rsp-32], 0                   ;|
            mov     qword [rsp-24], 0                   ;|
            mov     qword [rsp-16], 0                   ;|
            mov     qword [rsp-8],  0                   ;|

                                                        ;| the representation of the number is written
                                                        ;|  in big-endian form
                                                        ;|  so rcx iterates from the last bit of the buffer to the first

                                                        ;| |     bufer      |extra   |ret addr|
                                                        ;| |0000...000123456|00000000|xxxxxxxx|
                                                        ;|            ^- rcx before nasm_puts

            mov     ecx, 64 - 1                         ; bufer_idx = bufer_size - 1
            jmp     .do_while

.letter:
            add     edx, 'a' - 10                       ; translate letter num to ascii code
            jmp     .write_bufer

.write_bufer:
            lea     r8, [rcx - 1]                       ; r8 = rcx + 1
            mov     byte [rsp - 80 + rcx], dl           ; bufer[rcx] = char

            mov     rax, rdi                            ;|
            mov     edx, 0                              ;| rdi /= rsi
            div     rsi                                 ;|

            mov     rdi, rax                            ; rdi = rdi / rsi
            mov     rcx, r8                             ; rcx = rcx + 1

            cmp     rdi, 0                              ; if rdi == 0 => all the numbers were written down
            je      .end


.do_while:
            mov     rax, rdi                            ;|
            mov     edx, 0                              ;| rdx = (rsi % rax)
            div     rsi                                 ;|

            cmp     dl, 9                               ;| if (rdx > 9) -> letter
            jg      .letter                             ;|

            add     edx, '0'                            ;| if (rdx <= 9) -> digit
            jmp     .write_bufer

.end:
            inc     rcx                                 ; move rcx to first written bit in bufer

            lea         rdi, [rsp - 80 + rcx]           ;| cmp len of number in bufer
            call        c_strlen                        ;|

            lea         rdi, [rsp - 80 + rcx]           ;|
            mov         rsi, rax                        ;| put number ascii string into stdout bufer
            call        nasm_puts                       ;|

            ret
;================================================================================================



;================================================================================================
;              nasm_printf
;================================================================================================
; DESCR:
;      produce output in stdout bufer according to
;        a format
;      nasm_printf(frm_string, arg1, arg2, ...)
; ENTRY:
;       first arg is format string
;        rest - args for specifiers in fmt
;       args should be prepared in fastcall_4 form. First 4 args are put in L-R order into registers (rdi, rsi, rdx, rcx)
;        remaining - into stack in R-L order
; DESTROY:
;       rdi, rsi, rdx, rcx, r8
; GLOBAL:
;       stdout_bufer_size
;       stdout_bufer
;       stdout_bufer_idx
; RETURN:
;       None
;================================================================================================
nasm_printf:
            pop     r10                                 ; r10 = ret addr

            push    r9
            push    r8
            push    rcx                                 ; 4'th arg
            push    rdx                                 ; 3'rd arg
            push    rsi                                 ; 2'nd arg
            push    rdi                                 ; 1'st arg

            push    r10

            push    rbx                                 ;| saving nonvolatile registers
            push    rbp                                 ;|
            push    rdi                                 ;|
            push    rsi                                 ;|

            mov     rbp, rsp                            ;| rbp - arg pointer
            add     rbp, 48                             ;| nonvolatile_regs_cnt * 8 + 16
            mov     rbx, [rsp + 40]                     ;  rbx - fmt pointer [rsp + nonvolatile_regs_cnt * 8 + 8]

.fmt_loop:
            cmp     byte [rbx], 0x00                    ; if fmt[rbx] == 0 -> fmt_loop_end
            je      .fmt_loop_end

            cmp     byte [rbx], '%'
            je      .proc_specifier

            jmp     .print_fmt_char

.print_fmt_char:
            mov     rdi, rbx                            ; string addr = rbx
            mov     rsi, 1                              ; string len = 1
            call    nasm_puts                           ; DESTR(rdi, rsi, rdx, r8, r9)
                                                        ; next fmt_char
            jmp     .proc_specifier_end



.proc_specifier:
            inc     rbx                                 ; cur_fmt_char - specificator

                                                        ; switch (cur_fmt_char)
            cmp     byte [rbx], 'c'
            je      .print_char

            cmp     byte [rbx], 's'
            je      .print_c_string

            cmp     byte [rbx], 'x'
            mov     rsi, 16
            je      .print_xob_ntoa

            cmp     byte [rbx], 'o'
            mov     rsi, 8
            je      .print_xob_ntoa

            cmp     byte [rbx], 'b'
            mov     rsi, 2
            je      .print_xob_ntoa

            cmp     byte [rbx], 'd'
            je      .print_decimal

            cmp     byte[rbx], '%'
            je      .print_fmt_char

.proc_specifier_end:

            inc     rbx                                 ; next fmt_char
            jmp     .fmt_loop

.print_char:
                                                        ; put 1 char from arg into stdout bufer
            mov     rdi, rbp                            ; string addr = rbx
            mov     rsi, 1                              ; string len = 1
            call    nasm_puts                           ; DESTR(rdi, rsi, rdx, r8, r9)

            add     rbp, 8                              ; next arg
            jmp     .proc_specifier_end

.print_c_string:

            mov     rdi, qword [rbp]                    ; rdi = cur_arg - string addr
            call    c_strlen                            ; -> rax - string len

            mov     rdi, qword[rbp]
            mov     rsi, rax
            call    nasm_puts                           ; DESTR(rdi, rsi, rdx, r8, r9)

            add     rbp, 8                              ; next arg
            jmp     .proc_specifier_end

.print_decimal:
            mov     rdi, qword [rbp]                    ; number from args
            mov     rsi, 10

            test    rdi, rdi                            ;|
            jns     .decimal_positive                   ;| if rdi > 0 -> decimal is positive

            mov     rdi, '-'                            ; putchar('-')
            call    nasm_putchar                        ; DESTR(rdi, rsi, rdx, r8, r9)

            mov     rdi, qword [rbp]                    ; number from args
            mov     rsi, 10

            neg     rdi

.decimal_positive:
                                                        ; number=rdi
                                                        ; base=rsi
            call    nasm_putnum

            add     rbp, 8
            jmp     .proc_specifier_end


.print_xob_ntoa:
            mov     rdi, qword [rbp]                    ; number from args
                                                        ; rsi - base
            call    nasm_putnum

            add     rbp, 8
            jmp     .proc_specifier_end

.fmt_loop_end:

            pop     rsi                 ;| restoring nonvolatile registers
            pop     rdi                 ;|
            pop     rbp                 ;|
            pop     rbx                 ;|

            ret
;================================================================================================


; global c_strlen
; global global
; global stdout_flush
; global nasm_puts
; global nasm_putchar
; global nasm_putnum

section     .data

Msg:        db "Hello", 0x00
fmt_string_1  db "string '%s'", 0x0a, "char '%c'", 0x0a, "hex '%x'", 0x0a, "octal '%o'", 0x0a, "decimal '%d'", 0x0a, "binary '%b'", 0x0a, "radar is 100 %% 0_0", 0x0a, 0x0
fmt_string_2  db "123", 0x00

stdout_bufer_size equ 1024
stdout_bufer db stdout_bufer_size dup(0x0)
stdout_bufer_idx dq 0


atexit_list_sz equ 16
atexit_list dq atexit_list_sz dup(-1)
atexit_list_idx dq 0