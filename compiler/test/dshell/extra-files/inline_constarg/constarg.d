module constarg;

__gshared int[64] table;

// costly outside loops as a whole, cheap when `checked` is known
int lookup(int i, bool checked)
{
    if (checked)
    {
        int s = i;
        foreach (k; 0 .. 8)
        {
            s += table[(i + k) & 63] * (k + 1);
            s ^= s >> 3;
            s += table[(s ^ k) & 63] - (s << 2);
            s ^= table[(s + i) & 63] * 7 + (k ^ s);
            s += (table[(s * 3) & 63] ^ (i >> k)) + table[(k * 5 + s) & 63];
            s -= table[(s >> 4) & 63] * (s & 15) + table[(i * k) & 63];
            s ^= (table[(s + 17) & 63] + table[(s + 29) & 63]) * (k | 1);
        }
        if (s < 0)
            s = -s;
        s = table[s & 63] + table[(s >> 6) & 63] + table[(s >> 12) & 63];
        s += table[(s >> 18) & 63] * table[(s >> 24) & 63];
        return s + table[(s + i) & 63] - table[(s - i) & 63];
    }
    else
        return table[i & 63];
}

// the argument decides the condition: only the else branch is inlined
int unchecked(int i)
{
    return lookup(i, false);
}

// the argument does not decide it
int either(int i, bool c)
{
    return lookup(i, c);
}

// the parameter is changed before the condition: what is passed does not decide it
int changed(int i, bool checked)
{
    checked = i > 3;
    if (checked)
    {
        int s = i;
        foreach (k; 0 .. 8)
        {
            s += table[(i + k) & 63] * (k + 1);
            s ^= s >> 3;
            s += table[(s ^ k) & 63] - (s << 2);
            s ^= table[(s + i) & 63] * 7 + (k ^ s);
            s += (table[(s * 3) & 63] ^ (i >> k)) + table[(k * 5 + s) & 63];
            s -= table[(s >> 4) & 63] * (s & 15) + table[(i * k) & 63];
            s ^= (table[(s + 17) & 63] + table[(s + 29) & 63]) * (k | 1);
        }
        return s;
    }
    return table[i & 63];
}

int callsChanged(int i)
{
    return changed(i, false);
}
