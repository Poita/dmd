// String literals with the same bytes but different code unit sizes need
// their own terminators, so they are not pooled together.

immutable(char)*  c0() { return "".ptr; }
immutable(char)*  c1() { return "\xFF\xFF\xFF".ptr; }
immutable(wchar)* w0() { return ""w.ptr; }
immutable(dchar)* d0() { return ""d.ptr; }
immutable(char)*  ca() { return "a\0".ptr; }
immutable(wchar)* wa() { return "a"w.ptr; }

void main()
{
    assert(c0()[0] == 0);
    assert(c1()[3] == 0);
    assert(w0()[0] == 0);
    assert(d0()[0] == 0);
    assert(ca()[2] == 0);
    assert(wa()[0] == 'a' && wa()[1] == 0);
}
