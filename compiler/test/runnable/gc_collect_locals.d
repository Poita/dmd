// A collection must scan the registers and stack of the collecting thread,
// so objects only referenced from locals survive it.

import core.memory : GC;

class Node
{
    int value;
    Node next;
    __gshared int finalized;
    this(int v, Node n) { value = v; next = n; }
    ~this() { ++finalized; }
}

Node build(int n)
{
    Node list;
    foreach (i; 0 .. n)
        list = new Node(i, list);
    return list;
}

void main()
{
    Node list = build(1000);
    foreach (_; 0 .. 3)
        GC.collect();
    int count;
    for (auto p = list; p; p = p.next)
    {
        assert(p.value == 999 - count);
        ++count;
    }
    assert(count == 1000);
    assert(Node.finalized == 0);
}
