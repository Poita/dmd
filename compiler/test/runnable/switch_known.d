/* REQUIRED_ARGS: -O
 */
// Values known in the cases of switches and the arms of equality tests

@safe pragma(inline, false) void sortSmall(ulong[] r)
{
    switch (r.length)
    {
        case 0: case 1:
            return;
        case 2:
            if (r[1] < r[0]) { const t = r[0]; r[0] = r[1]; r[1] = t; }
            return;
        case 3:
            foreach (i; 0 .. 2)
                foreach (j; 0 .. 2 - i)
                    if (r[j + 1] < r[j]) { const t = r[j]; r[j] = r[j + 1]; r[j + 1] = t; }
            return;
        default:
            foreach (i; 1 .. r.length)
                for (size_t j = i; j > 0 && r[j] < r[j - 1]; --j)
                { const t = r[j]; r[j] = r[j - 1]; r[j - 1] = t; }
    }
}

@safe pragma(inline, false) int pick(int k, int[] a)
{
    if (k == 3)
        return a.length > 3 ? a[k] : -1;     // k is 3 here
    if (k != 0)
        return k;
    return a.length ? a[0] + k : -2;        // k is 0 here
}

void main()
{
    ulong[2] a = [5, 1];
    sortSmall(a[]);
    ulong[3] b = [9, 2, 4];
    sortSmall(b[]);
    ulong[5] c = [3, 9, 1, 7, 2];
    sortSmall(c[]);
    if (a != [1, 5] || b != [2, 4, 9] || c != [1, 2, 3, 7, 9]) assert(0);
    int[5] v = [10, 11, 12, 13, 14];
    if (pick(3, v[]) != 13 || pick(3, v[0 .. 2]) != -1 || pick(5, v[]) != 5 || pick(0, v[]) != 10 ||
        pick(0, null) != -2)
        assert(0);
}
