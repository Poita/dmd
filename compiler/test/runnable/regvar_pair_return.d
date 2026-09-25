// A delegate literal returning its slice parameter held in a register variable pair.
alias Cb = string delegate(string) @nogc nothrow;

string apply(string opt, scope Cb dg = null)
{
    if (!dg)
        dg = (string s) => s;
    return dg(opt);
}

void main()
{
    assert(apply("run-main") == "run-main");
}
