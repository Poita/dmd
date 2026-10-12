/* REQUIRED_ARGS: -O -inline
 */
// A function declaring a struct with a static member, inlined where it is
// called: the struct is generated once, with the function

int counter()
{
    static struct T { static int count; int x = 1; }
    T t;
    T.count++;
    return T.count + t.x;
}

void main()
{
    assert(counter() == 2);
    assert(counter() == 3);
}
