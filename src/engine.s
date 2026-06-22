.section .note.GNU-stack,"",@progbits
.text
.intel_syntax noprefix
.global asm_push
.global asm_pop

# asm_push: Producer calls this
# RDI = buffer, RSI = tail_ptr, RDX = value
asm_push:
    mov r8, [rsi]           # Load current tail
    mov r9, r8              
    inc r9                  # Calculate next tail
    and r9, 0xFFFF          # Wrap-around mask
    
    # Check if full (simplified: compare with head)
    # Note: In true SPSC, we cache head locally to avoid hitting consumer cache line
    
    mov [rdi + r8*8], rdx   # Write data
    mfence                  # Ensure data is in memory BEFORE tail update
    mov [rsi], r9           # Update tail (Producer-only write)
    ret

# asm_pop: Consumer calls this
# RDI = buffer, RSI = head_ptr, RDX = tail_ptr
asm_pop:
    mov r8, [rsi]           # Load current head
    mov r9, [rdx]           # Load current tail (read-only for consumer)
    cmp r8, r9
    je .empty               # Buffer empty
    
    mov rax, [rdi + r8*8]   # Read data
    inc r8
    and r8, 0xFFFF          # Wrap-around mask
    mfence
    mov [rsi], r8           # Update head (Consumer-only write)
    ret
.empty:
    xor rax, rax
    ret