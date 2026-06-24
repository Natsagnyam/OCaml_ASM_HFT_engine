.intel_syntax noprefix

.section .text

# --- Blind Write Routines (Zero Latency) ---
.global asm_push_blind
asm_push_blind:
    mov [rdi + rsi*8], rdx
    inc rsi
    ret

.global asm_pop_blind
asm_pop_blind:
    mov rax, [rdi + rsi*8]
    inc rsi
    ret

# --- Synchronized Routines (Safety Baseline) ---
.global asm_push
asm_push:
    mov r8, [rsi]
    mov [rdi + r8*8], rdx
    sfence
    inc r8
    and r8, 0xFFFF
    mov [rsi], r8
    ret

.global asm_pop
asm_pop:
    mov r8, [rsi]
    mov r9, [rdx]
    cmp r8, r9
    je .empty
    lfence
    mov rax, [rdi + r8*8]
    inc r8
    and r8, 0xFFFF
    mov [rsi], r8
    ret

.empty:
    mov rax, -1
    ret

# --- Move this to the very bottom ---
.section .note.GNU-stack,"",@progbits