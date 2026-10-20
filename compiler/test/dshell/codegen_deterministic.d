// Compiling the same program with the same flags gives the same object file: what
// the compiler generates does not depend on where its data lands in memory.
module test.dshell.codegen_deterministic;

import dshell;

enum program = q{
module prog;
import std.algorithm, std.array, std.conv, std.format, std.range;

class Shape { abstract double area() const; }
class Rect : Shape
{
    double w, h;
    this(double w, double h) { this.w = w; this.h = h; }
    override double area() const { return w * h; }
}

struct Point { int x, y; int opCmp(Point o) const { return x != o.x ? x - o.x : y - o.y; } }

int[string] histogram(string text)
{
    int[string] counts;
    foreach (word; text.splitter(' '))
        if (word.length)
            ++counts[word];
    return counts;
}

long collatz(long n)
{
    long steps;
    while (n != 1)
    {
        n = n & 1 ? 3 * n + 1 : n / 2;
        ++steps;
    }
    return steps;
}

string describe(int n)
{
    try
    {
        if (n < 0)
            throw new Exception("negative");
        return format("%d:%s", n, iota(n).map!(i => i * i).sum);
    }
    catch (Exception e)
        return e.msg;
}

int main(string[] args)
{
    auto pts = iota(50).map!(i => Point((i * 37) % 11, (i * 13) % 7)).array;
    pts.sort();
    Shape[] shapes;
    foreach (i; 0 .. 10)
        shapes ~= new Rect(i, i + 1);
    double total = shapes.map!(s => s.area).sum;
    auto h = histogram("a b c a b a d e f a");
    auto keys = h.keys.sort().release;
    long c = iota(1, 1000).map!collatz.maxElement;
    auto counter = (int k) => keys.length + k;
    string s = describe(cast(int)args.length) ~ describe(-1) ~ text(total, c, counter(3), pts[0].x);
    return s.length > 1000;
}
};

int main()
{
    std.file.write(Vars.OUTPUT_BASE ~ "/prog.d", program);
    foreach (flags; ["", "-O", "-O -inline -release"])
    {
        ubyte[] first;
        foreach (k; 0 .. 3)
        {
            run("$DMD -m$MODEL -j=1 " ~ flags ~ " -c -of=$OUTPUT_BASE/prog$OBJ $OUTPUT_BASE/prog.d");
            auto bytes = cast(ubyte[]) std.file.read(Vars.OUTPUT_BASE ~ "/prog" ~ Vars.OBJ);
            if (k == 0)
                first = bytes;
            else if (bytes != first)
            {
                writefln("compilation %s with flags '%s' differs from the first", k + 1, flags);
                return 1;
            }
        }
    }
    return 0;
}
