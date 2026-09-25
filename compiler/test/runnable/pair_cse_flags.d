// A register pair common subexpression tested only for its flags.

size_t pick(string fontPath, string def)
{
    string p = fontPath ? fontPath : def;
    if (fontPath)
        return p.length + fontPath.length;
    return p.length;
}

void main()
{
    assert(pick("abc", "de") == 6);
    assert(pick(null, "de") == 2);
}
