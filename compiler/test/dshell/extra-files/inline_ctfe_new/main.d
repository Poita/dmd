import cow, other;
size_t f(size_t k) { C!P c; c.length = k; return c.data.length; }
size_t g() { return h(); }
void main() { assert(f(2) == 3); assert(g() == 4); }
