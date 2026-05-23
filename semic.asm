
format ELF64 executable

SYS_READ  equ 0
SYS_WRITE equ 1
SYS_OPEN  equ 2
SYS_CLOSE equ 3
SYS_EXIT  equ 60
O_RDONLY  equ 0
O_WRONLY  equ 1
O_RDWR    equ 2
O_CREAT   equ 64
O_TRUNC   equ 512
STDIN     equ 0
STDOUT    equ 1
NEW_LINE  equ 10
MAX_PATH  equ 255
ARGUMENT_COUNT equ 2
FILE_BUFFER_SIZE equ 4096


macro exit_program
{
    mov eax, SYS_EXIT
    xor edi, edi
    syscall
}

macro print text, text_len
{
    mov eax, SYS_WRITE
    mov edi, STDOUT
    lea rsi, [text]
    mov edx, text_len
    syscall
}

macro strlen reg_str, reg_out
{
local .loop, .done

    xor rax, rax
.loop:
    cmp byte [reg_str + rax], 0
    je .done
    inc rax
    jmp .loop
.done:
    mov reg_out, rax
}

macro strcat dst, src
{
local .find, .append, .copy, .done

     xor rax, rax
.find:
    cmp byte [dst + rax], 0
    je .append
    inc rax
    jmp .find
.append:
    xor rcx, rcx
.copy:
    cmp byte [src + rcx], 0
    je .done
    mov dl, [src + rcx]
    mov [dst + rax + rcx], dl
    inc rcx
    jmp .copy
.done:
    mov byte [dst + rax + rcx], 0
}

macro itoa num, buf
{
local .loop

    mov rax, num
    mov rcx, 10
    lea rsi, [buf + 20]
.loop:
    xor rdx, rdx
    div rcx
    add dl, '0'
    dec rsi
    mov [rsi], dl
    test rax, rax
    jnz .loop
}

segment readable executable
entry main

main:

    cmp qword [rsp], ARGUMENT_COUNT
    jne argc_err

    mov r13, [rsp + 16]

    mov rax, SYS_OPEN
    mov rdi, r13
    mov rsi, O_RDONLY
    syscall
    mov r12, rax

    cmp rax, 0
    jl file_err
    

    xor rbx, rbx
read_loop:
    mov eax, SYS_READ
    mov rdi, r12
    lea rsi, [file_buffer]
    mov edx, FILE_BUFFER_SIZE
    syscall

    test rax, rax
    js read_err
    jz read_done

    xor rcx, rcx
buf_loop:
    
    cmp byte [file_buffer + ecx], ';'
    sete sil
    movzx r9, sil
    add rbx, r9
    inc rcx
    cmp rcx, rax
    jge read_loop
    jmp buf_loop

read_done:

    mov r14, rbx


    mov eax, SYS_CLOSE
    mov rdi, r12
    syscall


    strcat path_buffer, newline_str
    strcat path_buffer, r13
    strcat path_buffer, answer_msg
    itoa r14, quantity_str_buffer
    strcat path_buffer, rsi
    strcat path_buffer, answer_part2_msg


    strlen path_buffer, rdx
    mov eax, SYS_WRITE
    mov edi, STDOUT
    lea rsi, [path_buffer]
    syscall




    exit_program

read_err:
    mov eax, SYS_CLOSE
    mov rdi, r12
    syscall
    print read_err_msg, read_err_msg_len
    exit_program

file_err:
    print file_err_msg, file_err_msg_len
    exit_program

argc_err:
    print argc_err_msg, argc_err_msg_len
    exit_program


segment readable writeable


newline_str db NEW_LINE, 0


file_buffer rb FILE_BUFFER_SIZE
path_buffer rb MAX_PATH + 1
quantity_str_buffer db 21 dup (0)


answer_msg db ' has got: [', 0
answer_msg_len = $ - answer_msg


answer_part2_msg db '] semicolons', 10, 10, 0
answer_part2_msg_len = $ - answer_part2_msg


argc_err_msg db 'Invalid Argument Count', 10
argc_err_msg_len = $ - argc_err_msg


file_err_msg db 'File Error[Check If The File Exists]', 10
file_err_msg_len = $ - file_err_msg


read_err_msg db 'Read Error', 10
read_err_msg_len = $ - read_err_msg
