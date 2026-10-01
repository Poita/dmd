// REQUIRED_ARGS: -inline
// PERMUTE_ARGS: -O

/* Inlined chains of early returns give the same results as calls, with the
 * conditions and the statements between them evaluated in order.
 */

__gshared int trace;

int note(int x)
{
    trace = trace * 10 + x;
    return x;
}

int classify(int x)
{
    if (note(1) && x < 0)
        return -1;
    const y = x * 2;
    note(2);
    if (y > 10)
        return 2;
    if (note(3) && y > 4)
        return 1;
    return 0;
}

float sum(const(float)[] src, int N)
{
    float t = 0;
    foreach (y; 0 .. N)
        foreach (x; 0 .. N)
        {
            const c = src[y * N + x];
            float contrib(int nx, int ny)
            {
                if (nx < 0 || ny < 0 || nx >= N || ny >= N)
                    return 0.0f;
                const diff = src[ny * N + nx] - c;
                if (diff > 0.5f)
                    return 0.25f * (diff - 0.5f);
                if (-diff > 0.5f)
                    return -0.25f * (-diff - 0.5f);
                return 0.0f;
            }
            t += (contrib(x - 1, y) + contrib(x + 1, y) + contrib(x, y - 1) + contrib(x, y + 1)) * (x + 2 * y + 1);
        }
    return t;
}

void main()
{
    trace = 0;
    assert(classify(-5) == -1 && trace == 1);
    trace = 0;
    assert(classify(7) == 2 && trace == 12);
    trace = 0;
    assert(classify(3) == 1 && trace == 123);
    trace = 0;
    assert(classify(1) == 0 && trace == 123);

    float[16] a = [0, 1, 0.25, 3, 0.125, 2, 0, 1, 5, 0, 0.375, 1, 0, 2, 0.75, 0];
    assert(sum(a[], 4) == 1.0625f);
}
