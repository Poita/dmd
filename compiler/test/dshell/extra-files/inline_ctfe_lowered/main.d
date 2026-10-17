import lib, other;
size_t f(size_t k) { return make(k); }
size_t g() { return h(); }
void main() { assert(f(2) == 9); assert(g() == 10); }
