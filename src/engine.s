.section .note.GNU-stack,"",@progbits
.text
.intel_syntax noprefix
.global asm_push
.global asm_pop

# asm_push: rdi=buffer, rsi=tail_ptr, rdx=value
# Note: rsi is the pointer to the tail variable in memory
asm_push:
    mov r8, [rsi]          # Load current tail index
    
    # Write value to buffer at index r8 (assuming 8-byte entries)
    # The CPU buffer will hold this until the sfence
    mov [rdi + r8*8], rdx
    
    # Store-Store fence: ensures data write is visible to other cores 
    # BEFORE the tail update is visible.
    sfence                 
    
    # Update tail index
    inc r8
    and r8, 0xFFFF
    mov [rsi], r8
    
    ret

# asm_pop: rdi=buffer, rsi=head_ptr, rdx=tail_ptr
asm_pop:
    mov r8, [rsi]          # Load head
    mov r9, [rdx]          # Load tail (volatile)
    
    cmp r8, r9
    je .empty              # Empty if head == tail
    
    # Load-Load fence: ensures we read the data only AFTER we've 
    # confirmed the tail index (r9) is ahead of the head
    lfence
    
    mov rax, [rdi + r8*8]  # Read data from buffer
    
    inc r8
    and r8, 0xFFFF
    mov [rsi], r8          # Update head
    ret

.empty:
    mov rax, -1            # Return -1 to indicate empty
    ret