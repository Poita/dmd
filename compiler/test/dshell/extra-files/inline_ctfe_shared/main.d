import lib, other;
size_t f(int k) { return make(k); }
size_t g() { return h(); }
void main() { assert(f(2) == 4); assert(g() == 5); }
