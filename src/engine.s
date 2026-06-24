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
    # rdi = buffer_ptr
    # rsi = tail_ptr
    # rdx = value
    
    mov r8, [rsi]          # Load tail index
    and r8, 0xFFFF         # Mask: Ensure index is [0, 65535]
    
    mov [rdi + r8*8], rdx  # Write value
    
    inc r8                 # Increment index
    mov [rsi], r8          # Save updated tail back to memory
    ret