.section .note.GNU-stack,"",@progbits
.text
.intel_syntax noprefix
.global asm_push
.global asm_pop

# asm_push: rdi=buffer, rsi=tail_ptr, rdx=value
asm_push:
    mov r8, [rsi]
    mov r9, r8
    inc r9
    and r9, 0xFFFF
    
    mov [rdi + r8*8], rdx
    sfence                 # Store-Store fence: ensures data write before tail update
    mov [rsi], r9
    ret

# asm_pop: rdi=buffer, rsi=head_ptr, rdx=tail_ptr
asm_pop:
    mov r8, [rsi]          # Load head
    mov r9, [rdx]          # Load tail
    cmp r8, r9
    je .empty              # Empty if head == tail
    
    mov rax, [rdi + r8*8]  # Read data
    inc r8
    and r8, 0xFFFF
    lfence                 # Load-Load fence: ensures index read before data read
    mov [rsi], r8          # Update head
    ret
.empty:
    mov rax, -1            # Return -1 to indicate empty state
    ret