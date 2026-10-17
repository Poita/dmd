module a;
import pair;
alias T = Pair!(int, long);
T[] items;
void fill() { items = [T(1, 2), T(3, 4)]; }
