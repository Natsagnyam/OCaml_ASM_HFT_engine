.section .note.GNU-stack,"",@progbits
.text
.intel_syntax noprefix
.global asm_push
.global asm_pop


asm_push:
    # RDI: buffer, RSI: tail_ptr, RDX: value
    mov r8, [rsi]           
    mov rcx, r8             
    and rcx, 0xFFFF         
    mov [rdi + rcx*8], rdx  # 1. Write the DATA

    mfence                  # 2. Ensure DATA is flushed before updating INDEX    
    
    inc r8                  
    mov [rsi], r8           # 3. Update the INDEX
    ret

 asm_pop:
    mov r8, [rsi]           # Load Head index
    mov r9, [rdx]           # Load Tail index
    cmp r8, r9
    je .empty               # If head == tail, it's empty

    mov rcx, r8             # Use Head as index
    and rcx, 0xFFFF         # Mask for ring buffer size
    mov rax, [rdi + rcx*8]  # <--- CRITICAL: Must be a MOV, not LEA
    
    inc r8
    mov [rsi], r8           # Update Head
    mfence                  # Ensure write visibility
    ret

.empty:
    xor rax, rax            # Return 0 when empty
    ret