/* REQUIRED_ARGS: -inline
 */
// Casts, array comparisons, concatenations, appends and constructions lowered to
// druntime templates, inlined where they are used

class Node { int k; }
final class Num : Node { long v = 7; }
class Call : Node { int n = 2; }
final class Method : Call { int slot = 9; }
interface I { int id(); }
class Lit : Node, I { int id() { return 3; } }

long classify(Node n)
{
    if (auto x = cast(Num) n) return x.v;
    if (auto x = cast(Method) n) return x.slot;
    if (auto x = cast(Call) n) return x.n;
    if (auto x = cast(I) n) return x.id();
    return -1;
}

struct S { int a; string b; }

void main()
{
    assert(classify(new Num) == 7);
    assert(classify(new Method) == 9);
    assert(classify(new Call) == 2);
    assert(classify(new Lit) == 3);
    assert(classify(new Node) == -1);
    assert(classify(null) == -1);
    Node n = new Method;
    assert(cast(Call) n !is null && cast(Num) n is null);

    int[] a = [1, 2, 3];
    int[] b = [1, 2, 3];
    assert(a == b && !(a != b));
    b[2] = 4;
    assert(a != b);
    string s = "ab";
    assert(s == "ab" && s ~ "c" == "abc");
    S[] ss = [S(1, "x"), S(2, "y")];
    assert(ss == [S(1, "x"), S(2, "y")]);
    auto c = a ~ b ~ 5;
    assert(c == [1, 2, 3, 1, 2, 4, 5]);
    c ~= a;
    c ~= 8;
    assert(c.length == 11 && c[$ - 1] == 8);
    char[] t;
    foreach (ch; "hello")
        t ~= ch;
    assert(t == "hello");
}
