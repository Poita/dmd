/* REQUIRED_ARGS: -O -inline -release
 * PERMUTE_ARGS:
 */
// Functions with loops left by break and continue inlined into loops

struct Heap
{
    ulong[] items;
    size_t count;

    void push(ulong v)
    {
        if (count == items.length)
            items ~= v;
        else
            items[count] = v;
        size_t i = count++;
        while (i > 0)
        {
            const p = (i - 1) / 2;
            if (items[p] <= items[i])
                break;
            const t = items[p];
            items[p] = items[i];
            items[i] = t;
            i = p;
        }
    }

    ulong pop()
    {
        const top = items[0];
        items[0] = items[--count];
        size_t i = 0;
        for (;;)
        {
            const l = 2 * i + 1;
            const r = l + 1;
            size_t s = i;
            if (l < count && items[l] < items[s])
                s = l;
            if (r < count && items[r] < items[s])
                s = r;
            if (s == i)
                break;
            const t = items[s];
            items[s] = items[i];
            items[i] = t;
            i = s;
        }
        return top;
    }
}

// the first index of the row with a positive sum, skipping empty rows
int firstPositive(const int[][] rows)
{
    foreach (k, row; rows)
    {
        if (row.length == 0)
            continue;
        int s;
        foreach (x; row)
        {
            if (x == 0)
                continue;
            s += x;
            if (s > 100)
                break;
        }
        if (s > 0)
            return cast(int)k;
    }
    return -1;
}

// a labeled break, which is not inlined
int labeled(const int[][] rows)
{
    int n;
Louter:
    foreach (row; rows)
        foreach (x; row)
        {
            if (x < 0)
                break Louter;
            ++n;
        }
    return n;
}

void main()
{
    Heap h;
    static immutable ulong[] values = [9, 3, 7, 1, 8, 2, 6, 4, 5, 0, 11, 10];
    foreach (round; 0 .. 3)
    {
        foreach (v; values)
            h.push(v * 10 + round);
        ulong prev;
        foreach (k; 0 .. values.length)
        {
            const x = h.pop();
            if (k && x < prev)
                assert(0);
            prev = x;
        }
        if (h.count != 0) assert(0);
    }

    const int[][] rows = [[], [0, -5, 0], [0, 0], [3, 0, 200, 7], [1]];
    int found;
    foreach (k; 0 .. 4)
        found += firstPositive(rows[k .. $]);
    if (found != 3 + 2 + 1 + 0) assert(0);

    if (labeled([[1, 2], [3, -1, 4], [5]]) != 3) assert(0);
}
