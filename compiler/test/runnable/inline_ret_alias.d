/* REQUIRED_ARGS: -inline
 */
// v = f(v, ...) inlined as statements, where f reads v by ref or through a
// pointer or as this while building what it returns in place

struct Cube { ubyte[8] cp; ubyte[8] co; ubyte[12] ep; ubyte[12] eo; }

// too much to inline as an expression, so inlined as statements
Cube mul(ref const Cube a, ref const Cube b)
{
    Cube r;
    foreach (i; 0 .. 8)
    {
        immutable s = b.cp[i];
        r.cp[i] = a.cp[s];
        immutable o = cast(ubyte)(a.co[s] + b.co[i]);
        r.co[i] = o >= 3 ? cast(ubyte)(o - 3) : o;
    }
    foreach (i; 0 .. 12)
    {
        immutable s = b.ep[i];
        r.ep[i] = a.ep[s];
        r.eo[i] = a.eo[s] ^ b.eo[i];
    }
    return r;
}

Cube viaPointer(const(Cube)* a)
{
    Cube r;
    foreach (i; 0 .. 8)
        r.cp[i] = a.cp[7 - i];
    return r;
}

struct P
{
    int x, y;
    P swapped() const { P r; r.x = y; r.y = x; return r; }
}

void main()
{
    Cube id, turn;
    foreach (ubyte i; 0 .. 8)
    {
        id.cp[i] = i;
        turn.cp[i] = cast(ubyte)((i + 5) % 8);     // reads entries already written in place
        turn.co[i] = i % 3;
    }
    foreach (ubyte i; 0 .. 12)
    {
        id.ep[i] = i;
        turn.ep[i] = cast(ubyte)((i + 7) % 12);
        turn.eo[i] = i & 1;
    }
    Cube state = id, apart = id;
    foreach (k; 0 .. 5)
    {
        state = mul(state, turn);
        const next = mul(apart, turn);      // the same without the result going where an argument is
        apart = next;
    }
    assert(state == apart);
    assert(state.cp != id.cp);

    Cube s2 = turn;
    s2 = viaPointer(&s2);
    foreach (i; 0 .. 8)
        assert(s2.cp[i] == turn.cp[7 - i]);

    P p = P(1, 2);
    p = p.swapped();
    assert(p.x == 2 && p.y == 1);
}
