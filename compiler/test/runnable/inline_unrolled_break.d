/* REQUIRED_ARGS: -O -inline
 */
// Functions leaving a foreach over a tuple by break or continue, inlined as
// statements where the jump keeps its place

alias AliasSeq(T...) = T;

struct S
{
    int a, b;

    void step()
    {
        foreach (i; AliasSeq!(0, 1))
        {
            ++a;
            if (a > 0)
                break;
            ++b;
        }
    }
}

int[][2] src;

size_t firstNonEmpty()
{
    size_t best = size_t.max;
    foreach (i; AliasSeq!(0, 1))
    {
        if (src[i].length == 0)
            continue;
        if (best == size_t.max)
            best = i;
    }
    return best;
}

struct Chain
{
    int[][2] source;
    size_t frontIndex;

    this(int[] a, int[] b)
    {
        source[0] = a;
        source[1] = b;
        frontIndex = 2;
        foreach (i; AliasSeq!(0, 1))
            if (source[i].length)
            {
                frontIndex = i;
                break;
            }
    }
}

void main()
{
    S s;
    for (int i = 0; i < 1; s.step())
        ++i;
    assert(s.a == 1 && s.b == 0);

    src[1] = [1];
    assert(firstNonEmpty() == 1);

    auto c = Chain([1], [2]);
    assert(c.frontIndex == 0);
}
