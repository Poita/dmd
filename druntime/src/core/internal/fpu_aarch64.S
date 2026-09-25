/**
 * Access to the AArch64 floating point control and status registers for DMD,
 * which has no inline assembler for AArch64.
 *
 * Copyright: Copyright The D Language Foundation 2026.
 * License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 * Source:    $(DRUNTIMESRC core/internal/_fpu_aarch64.S)
 */

#if defined(__aarch64__) || defined(__arm64__)

#if defined(__APPLE__)
#define CSYM(name) _ ## name
#else
#define CSYM(name) name
#endif

/* uint _d_aarch64_get_fpcr() */
        .text
        .global CSYM(_d_aarch64_get_fpcr)
        .p2align  2
CSYM(_d_aarch64_get_fpcr):
        mrs     x0, fpcr
        ret

/* void _d_aarch64_set_fpcr(uint value) */
        .text
        .global CSYM(_d_aarch64_set_fpcr)
        .p2align  2
CSYM(_d_aarch64_set_fpcr):
        mov     w0, w0                  // zero extend
        msr     fpcr, x0
        ret

/* uint _d_aarch64_get_fpsr() */
        .text
        .global CSYM(_d_aarch64_get_fpsr)
        .p2align  2
CSYM(_d_aarch64_get_fpsr):
        mrs     x0, fpsr
        ret

/* void _d_aarch64_set_fpsr(uint value) */
        .text
        .global CSYM(_d_aarch64_set_fpsr)
        .p2align  2
CSYM(_d_aarch64_set_fpsr):
        mov     w0, w0                  // zero extend
        msr     fpsr, x0
        ret

#endif
