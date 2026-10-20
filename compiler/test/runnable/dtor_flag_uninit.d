// An exception thrown past a temporary with a destructor that a ?: did not
// construct propagates, whatever the stack held before.
string log;

struct S
{
    int n;
    ~this() { log ~= "dtor."; }
    void* get() { return null; }
}

S makeS(int n) { return S(n); }

void fooThrow(void* p) { throw new Exception("thrown"); }

pragma(inline, false)
void dirtyStack()
{
    ubyte[1024] buf = 0xFF;
    __gshared ubyte* sink;
    sink = buf.ptr;
}

pragma(inline, false)
void test(int len)
{
    fooThrow(len == 2 ? makeS(1).get() : null);
}

void main()
{
    foreach (len; [1, 2])
    {
        log = null;
        dirtyStack();
        bool caught;
        try
            test(len);
        catch (Exception e)
            caught = true;
        if (!caught)
            assert(0);
        if (log != (len == 2 ? "dtor." : ""))
            assert(0);
    }
}
