int sum(int[] a)
{
    int total = 0;
    foreach (x; a)
        total += x;
    return total;
}

int pick(int x, int y)
{
    int r;
    if (x < y)
        r = y - x;
    else
        r = x * y;
    return r;
}

void main()
{
    int[4] a = [1, 2, 3, 4];
    if (sum(a[]) != 10)
        assert(0);
    if (pick(2, 5) != 3 || pick(5, 2) != 10)
        assert(0);
}
