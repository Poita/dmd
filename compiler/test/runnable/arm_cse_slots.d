// REQUIRED_ARGS: -O
// PERMUTE_ARGS: -inline -release

/* Common subexpressions saved to the stack around conditional branches and
 * calls, some reloaded later and some not.
 */

__gshared int calls;

pragma(inline, false) int clobber(int x)
{
    ++calls;
    return x + 1;
}

pragma(inline, false) int count(int vx, int vy, int S)
{
    int r;
    foreach (dcy; -1 .. 1)
        foreach (dcx; -1 .. 1)
        {
            const cx = vx / 4 + dcx;
            const cy = vy / 4 + dcy;
            if (cx < 0 || cy < 0 || cx >= S || cy >= S)
                continue;
            if (vx < cx * 4 || vx > cx * 4 + 4 || vy < cy * 4 || vy > cy * 4 + 4)
                continue;
            r += cx * 4 + cy * 4;
        }
    return r;
}

pragma(inline, false) int reload(int a, int b)
{
    // a * b is live across the calls and used after the conditionals
    int r;
    if (a * b > 10 && clobber(a) > 2)
        r = a * b + clobber(b);
    else if (a * b < -10 || clobber(a * b) == 7)
        r = a * b - 1;
    return r + a * b;
}

void main()
{
    int total;
    foreach (vy; 0 .. 20)
        foreach (vx; 0 .. 20)
            total += count(vx, vy, 4);
    int expect;
    foreach (vy; 0 .. 20)
        foreach (vx; 0 .. 20)
            foreach (dcy; -1 .. 1)
                foreach (dcx; -1 .. 1)
                {
                    const cx = vx / 4 + dcx, cy = vy / 4 + dcy;
                    if (cx >= 0 && cy >= 0 && cx < 4 && cy < 4 &&
                        vx >= cx * 4 && vx <= cx * 4 + 4 && vy >= cy * 4 && vy <= cy * 4 + 4)
                        expect += cx * 4 + cy * 4;
                }
    assert(total == expect);

    assert(reload(3, 4) == 12 + 5 + 12);
    assert(reload(-3, 4) == -13 - 12);
    assert(reload(2, 3) == 5 + 6);
    assert(reload(1, 2) == 2);
}
