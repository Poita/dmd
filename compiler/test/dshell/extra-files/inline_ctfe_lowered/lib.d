module lib;
void grow(T)(ref T[] a, size_t n) { a.length = n; }
size_t make()(size_t n) { int[] a; grow(a, n); a[n - 1] = 7; return a.length + a[n - 1]; }
