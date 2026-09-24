// scope(success) with early returns calls the finally code from the
// exception path; it must not emit x86 code or misalign the stack.

__gshared int pos;

int parse(int x)
{
    auto save = pos;
    scope(success) pos = save;
    pos = 5;
    if (x)
        return x * 2;
    return 7;
}

void main()
{
    pos = 1;
    assert(parse(3) == 6);
    assert(pos == 1);
    assert(parse(0) == 7);
    assert(pos == 1);
}
