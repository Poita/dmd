// REQUIRED_ARGS: -O
// A register variable post-incremented from a known constant must not be
// reused as a copy of that constant afterwards.

char[] escape(scope const(char)[] arg)
{
    size_t size = 1 + arg.length + 1;
    foreach (char c; arg)
        if (c == '\'')
            size += 3;

    auto buf = new char[size];
    size_t p = 0;
    buf[p++] = '\'';
    foreach (char c; arg)
        if (c == '\'')
        {
            buf[p .. p + 4] = `'\''`;
            p += 4;
        }
        else
            buf[p++] = c;
    buf[p++] = '\'';
    assert(p == size);
    return buf;
}

void main()
{
    assert(escape("a'b") == `'a'\''b'`);
    assert(escape("") == `''`);
    assert(escape("xyz") == `'xyz'`);
}
