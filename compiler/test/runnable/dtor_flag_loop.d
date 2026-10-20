/* PERMUTE_ARGS: -O -inline
 */
// An exception thrown past a temporary with a destructor that a ?: or &&
// did not construct propagates also when an earlier loop iteration
// constructed and destroyed it.
string log;

struct S
{
    int n;
    ~this() { log ~= "dtor."; }
    void* get() { return null; }
    bool ok() { return true; }
}

S makeS(int n) { return S(n); }

void fooThrow(void* p, int i) { if (i == 1) throw new Exception("thrown"); }
void barThrow(bool b, int i) { if (i == 2) throw new Exception("thrown"); }

pragma(inline, false)
void condLoop()
{
    foreach (i; 0 .. 2)
        fooThrow(i == 0 ? makeS(1).get() : null, i);
}

pragma(inline, false)
void andandLoop()
{
    int i = 0;
    while (i < 3)
    {
        barThrow(i < 2 && makeS(i).ok(), i);
        ++i;
    }
}

void main()
{
    bool caught;
    try
        condLoop();
    catch (Exception e)
        caught = true;
    if (!caught || log != "dtor.")
        assert(0);

    log = null;
    caught = false;
    try
        andandLoop();
    catch (Exception e)
        caught = true;
    if (!caught || log != "dtor.dtor.")
        assert(0);
}
