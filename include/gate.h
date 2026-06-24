// include/gate.h

typedef struct {
    volatile int producer_ready __attribute__((aligned(64)));
    volatile int consumer_ready __attribute__((aligned(64)));
    volatile int go_signal __attribute__((aligned(64)));
} gate_t;