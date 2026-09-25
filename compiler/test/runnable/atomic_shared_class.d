// Atomic operations on shared class references.

import core.atomic;

class B { int x; }

void main()
{
    shared const(B) src = new shared const(B);
    shared const(B) tgt;
    atomicStore(tgt, atomicLoad(src));
    assert(tgt is src);

    shared B b1 = new shared B, b2 = new shared B;
    shared B slot = b1;
    assert(cas(&slot, b1, b2) && slot is b2);
    assert(atomicExchange(&slot, b1) is b2 && slot is b1);
}
