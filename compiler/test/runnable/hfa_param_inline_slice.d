// A struct of four floats built by an inlined function and stored into an array element.
struct Rect
{
    float x = 0, y = 0, w = 0, h = 0;
    float right() const => x + w;
    float bottom() const => y + h;
}

Rect intersectRect(Rect a, Rect b)
{
    const x0 = a.x > b.x ? a.x : b.x;
    const y0 = a.y > b.y ? a.y : b.y;
    const x1 = a.right < b.right ? a.right : b.right;
    const y1 = a.bottom < b.bottom ? a.bottom : b.bottom;
    const w = x1 > x0 ? x1 - x0 : 0;
    const h = y1 > y0 ? y1 - y0 : 0;
    return Rect(x0, y0, w, h);
}

struct Batch
{
    Rect[] clipStack;
    uint clipCount;
    void pushClip(Rect r)
    {
        if (clipCount == 8)
            return;
        clipStack[clipCount] = clipCount > 0 ? intersectRect(clipStack[clipCount - 1], r) : r;
        clipCount++;
    }
}

void main()
{
    Batch b;
    b.clipStack = new Rect[](8);
    b.pushClip(Rect(0, 0, 100, 100));
    b.pushClip(Rect(50, 40, 100, 100));
    assert(b.clipCount == 2);
    assert(b.clipStack[0] == Rect(0, 0, 100, 100));
    assert(b.clipStack[1] == Rect(50, 40, 50, 60));
}
