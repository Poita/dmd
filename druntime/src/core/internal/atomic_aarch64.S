/**
 * Atomic operations for DMD on AArch64, which has no inline assembler.
 * All operations are sequentially consistent and use the ARMv8.1 LSE
 * instructions, which every Apple Silicon processor implements.
 *
 * Copyright: Copyright The D Language Foundation 2026.
 * License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 * Source:    $(DRUNTIMESRC core/internal/_atomic_aarch64.S)
 */

#if defined(__aarch64__) || defined(__arm64__)

#if defined(__APPLE__)
#define CSYM(name) _ ## name
#else
#define CSYM(name) name
#endif


/* T load(const T* p) */
        .text
        .global CSYM(_d_aarch64_load1)
        .p2align  2
CSYM(_d_aarch64_load1):
        ldarb   w0, [x0]
        ret
        .text
        .global CSYM(_d_aarch64_load2)
        .p2align  2
CSYM(_d_aarch64_load2):
        ldarh   w0, [x0]
        ret
        .text
        .global CSYM(_d_aarch64_load4)
        .p2align  2
CSYM(_d_aarch64_load4):
        ldar    w0, [x0]
        ret
        .text
        .global CSYM(_d_aarch64_load8)
        .p2align  2
CSYM(_d_aarch64_load8):
        ldar    x0, [x0]
        ret

/* void load16(const void* p, void* result) */
        .text
        .global CSYM(_d_aarch64_load16)
        .p2align  2
CSYM(_d_aarch64_load16):
1:      ldaxp   x2, x3, [x0]
        stlxp   w4, x2, x3, [x0]        // store back to make the pair read atomic
        cbnz    w4, 1b
        stp     x2, x3, [x1]
        ret

/* void store(T* p, T value) */
        .text
        .global CSYM(_d_aarch64_store1)
        .p2align  2
CSYM(_d_aarch64_store1):
        stlrb   w1, [x0]
        ret
        .text
        .global CSYM(_d_aarch64_store2)
        .p2align  2
CSYM(_d_aarch64_store2):
        stlrh   w1, [x0]
        ret
        .text
        .global CSYM(_d_aarch64_store4)
        .p2align  2
CSYM(_d_aarch64_store4):
        stlr    w1, [x0]
        ret
        .text
        .global CSYM(_d_aarch64_store8)
        .p2align  2
CSYM(_d_aarch64_store8):
        stlr    x1, [x0]
        ret

/* void store16(void* p, const void* value) */
        .text
        .global CSYM(_d_aarch64_store16)
        .p2align  2
CSYM(_d_aarch64_store16):
        ldp     x2, x3, [x1]
1:      ldaxp   x4, x5, [x0]
        stlxp   w6, x2, x3, [x0]
        cbnz    w6, 1b
        ret

/* T fetchAdd(T* p, T value), returns the previous value */
        .text
        .global CSYM(_d_aarch64_fetchadd1)
        .p2align  2
CSYM(_d_aarch64_fetchadd1):
        ldaddalb w1, w0, [x0]
        ret
        .text
        .global CSYM(_d_aarch64_fetchadd2)
        .p2align  2
CSYM(_d_aarch64_fetchadd2):
        ldaddalh w1, w0, [x0]
        ret
        .text
        .global CSYM(_d_aarch64_fetchadd4)
        .p2align  2
CSYM(_d_aarch64_fetchadd4):
        ldaddal w1, w0, [x0]
        ret
        .text
        .global CSYM(_d_aarch64_fetchadd8)
        .p2align  2
CSYM(_d_aarch64_fetchadd8):
        ldaddal x1, x0, [x0]
        ret

/* T exchange(T* p, T value), returns the previous value */
        .text
        .global CSYM(_d_aarch64_exchange1)
        .p2align  2
CSYM(_d_aarch64_exchange1):
        swpalb  w1, w0, [x0]
        ret
        .text
        .global CSYM(_d_aarch64_exchange2)
        .p2align  2
CSYM(_d_aarch64_exchange2):
        swpalh  w1, w0, [x0]
        ret
        .text
        .global CSYM(_d_aarch64_exchange4)
        .p2align  2
CSYM(_d_aarch64_exchange4):
        swpal   w1, w0, [x0]
        ret
        .text
        .global CSYM(_d_aarch64_exchange8)
        .p2align  2
CSYM(_d_aarch64_exchange8):
        swpal   x1, x0, [x0]
        ret

/* T cas(T* p, T expected, T desired), returns the previous value */
        .text
        .global CSYM(_d_aarch64_cas1)
        .p2align  2
CSYM(_d_aarch64_cas1):
        casalb  w1, w2, [x0]
        mov     w0, w1
        ret
        .text
        .global CSYM(_d_aarch64_cas2)
        .p2align  2
CSYM(_d_aarch64_cas2):
        casalh  w1, w2, [x0]
        mov     w0, w1
        ret
        .text
        .global CSYM(_d_aarch64_cas4)
        .p2align  2
CSYM(_d_aarch64_cas4):
        casal   w1, w2, [x0]
        mov     w0, w1
        ret
        .text
        .global CSYM(_d_aarch64_cas8)
        .p2align  2
CSYM(_d_aarch64_cas8):
        casal   x1, x2, [x0]
        mov     x0, x1
        ret

/* bool cas16(void* p, void* expected, ulong desiredLo, ulong desiredHi)
 * On failure the value found is stored into *expected.
 */
        .text
        .global CSYM(_d_aarch64_cas16)
        .p2align  2
CSYM(_d_aarch64_cas16):
        ldp     x4, x5, [x1]            // CASPAL needs even/odd register pairs
        mov     x6, x2
        mov     x7, x3
        mov     x8, x4
        mov     x9, x5
        caspal  x4, x5, x6, x7, [x0]
        cmp     x4, x8
        ccmp    x5, x9, #0, eq
        b.ne    1f
        mov     w0, #1
        ret
1:      stp     x4, x5, [x1]
        mov     w0, #0
        ret

/* void fence() */
        .text
        .global CSYM(_d_aarch64_fence)
        .p2align  2
CSYM(_d_aarch64_fence):
        dmb     ish
        ret

/* void pause() */
        .text
        .global CSYM(_d_aarch64_pause)
        .p2align  2
CSYM(_d_aarch64_pause):
        yield
        ret

#endif
