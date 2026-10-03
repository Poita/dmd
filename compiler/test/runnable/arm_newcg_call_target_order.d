// REQUIRED_ARGS: -O -release
// The address of the function called is evaluated after the arguments, which may
// assign what it is computed from, as a virtual call of the result of a call does.

class Proxy
{
    int base;
    this(int b) { base = b; }
    int initThread(Object t) { return base + (t is null ? 0 : 1); }
}

__gshared Proxy theProxy;

pragma(inline, false) Proxy getProxy() { return theProxy; }

class Owner
{
    int got;
    pragma(inline, false) void init()
    {
        got = getProxy().initThread(this);
    }
}

void main()
{
    theProxy = new Proxy(41);
    auto o = new Owner;
    o.init();
    if (o.got != 42) assert(0);
}
