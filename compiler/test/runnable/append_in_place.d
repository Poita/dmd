// Appending in place, and not over what another slice of the block may hold

struct WithDtor
{
    int v;
    ~this() {}
}

void growsInPlace(T)(size_t start, size_t count)
{
    T[] a;
    a.length = start;
    a.length = 0;
    a = a.assumeSafeAppend();
    auto p = a.ptr;
    foreach (i; 0 .. count)
        a ~= cast(T)(i + 1);
    if (a.length != count) assert(0);
    foreach (i, x; a)
        if (x != cast(T)(i + 1)) assert(0);
    if (count <= start && a.ptr !is p) assert(0);      // the capacity was there
}

void noStomping(T)(size_t n)
{
    T[] a;
    foreach (i; 0 .. n)
        a ~= cast(T) i;
    auto b = a[0 .. n / 2];         // a shorter slice of the same block
    b ~= cast(T) 99;                // must not write over a[n / 2]
    if (a[n / 2] != cast(T)(n / 2)) assert(0);
    if (b.ptr is a.ptr) assert(0);
    a ~= cast(T) 7;                 // the longer one still appends in place
    if (a[$ - 1] != cast(T) 7 || a[n / 2] != cast(T)(n / 2)) assert(0);
}

void interior()
{
    int[] a;
    foreach (i; 0 .. 50)
        a ~= i;
    auto tail = a[10 .. $];         // starts inside the block, ends where it ends
    tail ~= 1000;
    if (tail[$ - 1] != 1000 || tail[0] != 10) assert(0);
    if (tail.ptr !is a.ptr + 10) assert(0);     // in place: it ends at the used end
    a ~= 2000;                      // a no longer ends at the used end
    if (a.ptr is tail.ptr - 10 && a.length == 51 && a[50] == 2000 && tail[40] == 2000) assert(0);
    if (tail[$ - 1] != 1000) assert(0);
}

void structs()
{
    WithDtor[] a;
    foreach (i; 0 .. 300)
        a ~= WithDtor(i);
    foreach (i, ref x; a)
        if (x.v != i) assert(0);
    auto b = a[0 .. 100];
    b ~= WithDtor(-1);
    if (a[100].v != 100) assert(0);
}

void sharedArrays()
{
    shared(int)[] a;
    foreach (i; 0 .. 1000)
        a ~= i;
    foreach (i, x; a)
        if (x != i) assert(0);
    auto b = a[0 .. 10];
    b ~= -1;
    if (a[10] != 10) assert(0);
}

void main()
{
    foreach (n; [1, 2, 7, 100, 200, 254, 255, 256, 300, 1000, 2047, 2048, 3000, 5000, 100_000])
    {
        growsInPlace!ubyte(n, n);
        growsInPlace!ubyte(n, n * 2 + 3);
        growsInPlace!uint(n, n);
        growsInPlace!uint(n, n + 17);
        growsInPlace!ulong(n, n / 2 + 1);
        noStomping!ubyte(n + 2);
        noStomping!uint(n + 2);
        noStomping!ulong(n + 2);
    }
    interior();
    structs();
    sharedArrays();
}
