/* REQUIRED_ARGS: -O -inline
 */
// Calls of functions with loops, which are inlined only as statements, in the
// middle of expressions: in returns, conditions, indexes and assignments, next
// to calls with side effects and to what they could change, which must not move

int countSmaller(const(ubyte)[] p, size_t i)
{
    int n;
    foreach (j; i + 1 .. p.length)
        if (p[j] < p[i])
            n++;
    return n;
}

int permIndex(const(ubyte)[] p)
{
    int idx;
    foreach (i; 0 .. p.length)
    {
        int smaller;
        foreach (j; i + 1 .. p.length)
            if (p[j] < p[i])
                smaller++;
        idx = idx * cast(int)(p.length - i) + smaller;
    }
    return idx;
}

__gshared int counter;
__gshared int[24] table;

int bump() { return ++counter; }

int sumTo(int n)
{
    int s;
    foreach (i; 0 .. n)
        s += i;
    return s;
}

// writes through its argument, so nothing read before it may move after it
int fill(int[] a)
{
    foreach (ref x; a)
        x = 7;
    return cast(int)a.length;
}

int classify(ubyte[] p) { return table[permIndex(p)] * 70 + permIndex(p[0 .. 2]); }

void main()
{
    foreach (i, ref t; table)
        t = cast(int)i * 3;
    ubyte[4] p = [3, 1, 2, 0];
    assert(permIndex(p[]) == 21);
    assert(classify(p[]) == table[21] * 70 + 1);

    // in conditions and indexes
    int hits;
    foreach (k; 0 .. 10)
        if (sumTo(k) > 10 && permIndex(p[]) == 21)
            ++hits;
    assert(hits == 4);
    int[8] arr;
    arr[sumTo(3)] = sumTo(4);
    assert(arr[3] == 6);

    // into bounds checked elements
    int[3][] grid = new int[3][](2);
    foreach (k; 0 .. 2)
        grid[k][k + 1] = cast(ubyte)permIndex(p[]);
    assert(grid[0][1] == 21 && grid[1][2] == 21 && grid[1][0] == 0);

    // after a call with side effects: the order is kept
    counter = 0;
    int r = bump() * 100 + sumTo(counter + 3);
    assert(r == 100 + 6);

    // what a call reads before one that writes it keeps its old value
    int[] a = [1, 2, 3];
    int s = a[0] + fill(a) + a[1];
    assert(s == 1 + 3 + 7);

    // in && and ?: arms, only when they are evaluated
    counter = 0;
    bool b = counter > 0 && sumTo(bump()) > 0;
    assert(!b && counter == 0);
    int c = counter == 0 ? sumTo(5) : sumTo(bump());
    assert(c == 10 && counter == 0);
}
