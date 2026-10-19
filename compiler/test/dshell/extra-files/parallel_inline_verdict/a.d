module a;

// This module is the larger source file, so that the first worker takes it, and its
// compile-time evaluation keeps it from also taking b.d before the second worker starts.

struct Box(T) { T x = 7; }

int f(int n)
{
    Box!int b;
    switch (n)
    {
        case 1: b.x = 3; break;
        default: b.x += n; break;
    }
    return b.x;
}

int g()
{
    enum wait = () { long s; foreach (i; 0 .. 500_000) s += i; return s; }();
    return f(cast(int) (wait & 3)) + 1;
}
