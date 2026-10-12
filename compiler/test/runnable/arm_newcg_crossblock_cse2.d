/* REQUIRED_ARGS: -O -inline -release
 */
// Appends to the last of a stack of frames, which is pushed and popped, as a
// scanner of nested markup does: reads of the stack shared by the blocks of an
// inlined append, where one block dominating another keeps its read

import core.stdc.stdlib : abort;

struct Frame { int open; int[] kids; }

int[] scan(const(char)[] text)
{
    Frame[] stack = [Frame(0, null)];
    size_t i = 0;
    while (i < text.length)
    {
        const c = text[i];
        if (c == '{')
        {
            stack ~= Frame(cast(int)i, null);
            ++i;
        }
        else if (c == '}')
        {
            if (stack.length < 2)
                abort();
            auto top = stack[$ - 1];
            stack = stack[0 .. $ - 1];
            stack[$ - 1].kids ~= -cast(int)top.kids.length;
            ++i;
        }
        else
        {
            stack[$ - 1].kids ~= c - 'a';
            i += 1;
        }
    }
    return stack[0].kids;
}

void main()
{
    if (scan("ab{cd}e") != [0, 1, -2, 4])
        abort();
    if (scan("{{a}b}c{}") != [-2, 2, 0])
        abort();
    string s;
    int[] want;
    foreach (k; 0 .. 200)
    {
        s ~= "x{yz}";
        want ~= ['x' - 'a', -2];
    }
    if (scan(s) != want)
        abort();
}
