module b;
import a;
struct Slot { T t; int n; }
class Queue { Slot[] slots; void put(T v) { slots ~= Slot(v, 1); } bool has(T v) { foreach (ref s; slots) if (s.t == v) return true; return false; } }
