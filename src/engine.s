.intel_syntax noprefix
.section .note.GNU-stack,"",@progbits
.section .text

# goodbye for the fences for good. The sync done by the global sync control / flow control signals
.global asm_pop_blind
asm_pop_blind:
    # rdi = buffer_ptr, rsi = head_ptr
    mov r8, [rsi]
    and r8, 0xFFFF
    mov rax, [rdi + r8*8]
    inc r8
    mov [rsi], r8
    ret

.global asm_push_blind
asm_push_blind:
    # rdi = buffer, rsi = tail, rdx = value
    mov r8, [rsi]
    and r8, 0xFFFF
    
    # Bypass cache, write directly to memory
    movnti [rdi + r8*8], rdx  
    
    inc r8
    mov [rsi], r8
    ret