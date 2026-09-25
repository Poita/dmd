// Single element floating point aggregates passed on the stack.

struct D1 { double x; }
struct F1 { float x; }
double take(A...)(int a0, int a1, int a2, int a3, int a4, int a5, int a6, int a7,
                  double b0, double b1, double b2, double b3, double b4, double b5, double b6, double b7, A args)
{
    return args[0].x + args[1].x;
}
void main()
{
    assert(take(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, D1(3), F1(4)) == 7);
}
