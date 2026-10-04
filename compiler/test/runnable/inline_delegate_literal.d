/* REQUIRED_ARGS: -O -inline -release
 * PERMUTE_ARGS:
 */
// Functions given function literals as delegates inlined, and the literals into them

float total(float[] cells, float k)
{
    void forCells(int n, scope void delegate(size_t idx, float d) f)
    {
        foreach (i; 0 .. n)
            f(i, i * 0.5f);
    }
    void tail(float r)
    {
        forCells(cast(int)cells.length, (idx, d) {
            const w = d * r + k;
            if (w > cells[idx])
                cells[idx] = w;
        });
    }
    tail(2.0f);
    tail(3.0f);
    float s = 0;
    foreach (c; cells)
        s += c;
    return s;
}

int reassigned(int x)
{
    int apply(int delegate(int) f, int v)
    {
        auto r = f(v);
        f = (int y) => y * 100;     // the parameter changes
        return r + f(v);
    }
    return apply((int y) => y + x, 2);
}

int delegate(int) saved;
int stores(int x)
{
    void keep(int delegate(int) f) { saved = f; }   // the delegate escapes
    keep((int y) => y + x);
    return saved(5);
}

int counts(int n)
{
    int calls;
    void each(scope void delegate() f) { foreach (_; 0 .. n) f(); }
    each(() { ++calls; });
    return calls;
}

float earlyReturns(float[] cells, float k)
{
    void forCells(int n, scope void delegate(size_t idx, float d) f)
    {
        foreach (i; 0 .. n)
            f(i, i * 0.5f);
    }
    int skipped;
    void tail(float r)
    {
        forCells(cast(int)cells.length, (idx, d) {
            const t = d * r;
            if (t <= 0.0f || t >= 6.0f)
            {
                ++skipped;
                return;
            }
            const w = t + k;
            if (w > cells[idx])
                cells[idx] = w;
        });
    }
    tail(2.0f);
    tail(3.0f);
    float s = skipped * 1000;
    foreach (c; cells)
        s += c;
    return s;
}

int twoReturns(int n)
{
    int t;
    void each(scope void delegate(int) f) { foreach (i; 0 .. n) f(i); }
    each((i) {
        if (i == 1)
            return;
        t += i;
        if (i == 3)
            return;
        t += 100;
    });
    return t;
}

void main()
{
    float[8] e = 0;
    if (earlyReturns(e[], 1.0f) != 23 + 8000)
        assert(0);
    if (twoReturns(5) != (0 + 2 + 3 + 4) + 300)
        assert(0);
    float[8] c = 0;
    if (total(c[], 1.0f) != 50)
        assert(0);
    if (reassigned(3) != 5 + 200)
        assert(0);
    if (stores(7) != 12)
        assert(0);
    if (counts(4) != 4)
        assert(0);
}
