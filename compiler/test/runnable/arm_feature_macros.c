/* REQUIRED_ARGS: -release
 * C code that selects GCC inline assembly by ARM feature macros takes its
 * portable path, since ImportC compiles no GCC inline assembly.
 */

static unsigned crc_byte(unsigned crc, unsigned char val)
{
#if defined(__ARM_FEATURE_CRC32) || defined(__ARM_NEON) || defined(__ARM_FEATURE_CRYPTO)
    __asm__ volatile("crc32b %w0, %w0, %w1" : "+r"(crc) : "r"(val));
#else
    crc ^= val;
    for (int k = 0; k < 8; k++)
        crc = crc & 1 ? (crc >> 1) ^ 0xedb88320 : crc >> 1;
#endif
    return crc;
}

int main()
{
    const char *s = "123456789";
    unsigned crc = 0xffffffff;
    while (*s)
        crc = crc_byte(crc, (unsigned char)*s++);
    return (crc ^ 0xffffffff) == 0xcbf43926 ? 0 : 1;
}
