/* REQUIRED_ARGS: -O
 * A switch on large case values compiled to a binary search of comparisons.
 */

typedef enum { HEAD = 16180, FLAGS, TIME, OS, EXLEN, EXTRA, NAME, COMMENT, HCRC, DICTID, DICT,
    TYPE, TYPEDO, STORED, COPY_, COPY, TABLE, LENLENS, CODELENS, LEN_, LEN, LENEXT, DIST,
    DISTEXT, MATCH, LIT, CHECK, LENGTH, DONE, BAD, MEM, SYNC } inflate_mode;

int step(inflate_mode *m, int *out)
{
    for (;;)
        switch (*m)
        {
        case HEAD: *out += 1; *m = TYPE; break;
        case FLAGS: *out += 2; *m = TIME; break;
        case TIME: *out += 3; *m = OS; break;
        case OS: *out += 4; *m = DONE; break;
        case TYPE: *out += 10; *m = TYPEDO; break;
        case TYPEDO: *out += 20; *m = STORED; break;
        case STORED: *out += 30; *m = LEN; break;
        case LEN: *out += 40; *m = CHECK; break;
        case CHECK: *out += 50; *m = DONE; break;
        case DONE: return 1;
        case BAD: return -3;
        case MEM: return -4;
        case SYNC:
        default: return -2;
        }
}

int main(void)
{
    inflate_mode m = HEAD; int out = 0;
    int r = step(&m, &out);
    if (r != 1 || out != 151) return 1;
    m = FLAGS; out = 0;
    r = step(&m, &out);
    return r == 1 && out == 9 ? 0 : 2;
}
