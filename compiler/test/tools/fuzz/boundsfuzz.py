#!/usr/bin/env python3
"""Random D program generator for differential testing of array bounds checks.

Each program has @safe functions that index arrays in loops and under guards
in ways that are sometimes in bounds and sometimes not: loop bounds from the
lengths of the arrays or off by one, indices offset by constants, counting up
and down, with size_t wraparound and signed indices, nested loops over two
arrays, and arrays, indices and globals changed in the loop, directly, through
ref parameters, pointers and called functions. main calls each function with
arrays of several lengths, catches the RangeError of an access out of bounds,
and prints the line it was raised at and what the function did up to there.

Every access is checked (the functions are @safe, and no configuration it is
compiled with turns the checks off), so a program is free of undefined
behaviour, and its output must be the same however it is compiled: a check
removed that could fail, or a check that fails at another access, shows up as
a difference.

Usage: boundsfuzz.py SEED [--size small|medium|large] > prog.d
"""

import argparse
import random

SIZES = {'small': 6, 'medium': 14, 'large': 30}


class Gen:
    def __init__(self, seed, size):
        self.r = random.Random(seed)
        self.n = SIZES[size]
        self.out = []
        self.line = 0

    def emit(self, s):
        self.out.append(s)

    def chance(self, p):
        return self.r.random() < p

    def length(self, arr):
        return '%s.length' % arr

    def bound(self, arr):
        """A loop bound near the length of arr"""
        r = self.r
        k = r.random()
        if k < 0.5:
            return self.length(arr)
        if k < 0.65:
            return '%s.length + %d' % (arr, r.choice([1, 2]))
        if k < 0.8:
            return '(%s.length > %d ? %s.length - %d : 0)' % (arr, 0, arr, r.choice([0, 1]))
        if k < 0.9:
            return 'n'
        return str(r.randint(0, 6))

    def index(self, v, arr):
        """An index from the loop variable v into arr"""
        r = self.r
        k = r.random()
        if k < 0.45:
            return v
        if k < 0.6:
            return '%s + %d' % (v, r.choice([1, 2]))
        if k < 0.7:
            return '%s - %d' % (v, r.choice([1, 2]))
        if k < 0.8:
            return '%s.length - %s' % (arr, v)
        if k < 0.9:
            return '%s.length - 1 - %s' % (arr, v)
        return str(r.randint(0, 5))

    def change(self, arrs, v, down=False):
        """A statement that may change an array, the loop variable or a global"""
        r = self.r
        a = r.choice(arrs)
        k = r.random()
        if k < 0.2:
            return 'if (%s.length) %s = %s[0 .. $ - 1];' % (a, a, a)
        if k < 0.35:
            other = r.choice(arrs)
            return '%s = %s;' % (a, other)
        if k < 0.5:
            if down:
                return 'if (%s == %d) %s -= 1;' % (v, r.randint(2, 4), v)
            return 'if (%s == %d) %s += 1;' % (v, r.randint(0, 3), v)
        if k < 0.65:
            return 'shrinkG();'
        if k < 0.8:
            return 'cut(%s);' % a
        return 'acc += %s.length;' % a

    def access(self, arr, idx):
        self.emit('        mark = __LINE__; acc += %s[%s];' % (arr, idx))

    def loop(self, depth, arrs, vars_):
        r = self.r
        a = r.choice(arrs)
        v = 'i%d' % depth
        mutable = False     # whether the body may assign v
        down = False        # whether v counts down
        k = r.random()
        if k < 0.3:
            self.emit('    foreach (%s; 0 .. %s)' % (v, self.bound(a)))
        elif k < 0.55:
            cmp = r.choice(['<', '<', '<', '<='])
            self.emit('    for (size_t %s = 0; %s %s %s; %s++)' % (v, v, cmp, self.bound(a), v))
            mutable = True
        elif k < 0.7:
            self.emit('    foreach_reverse (%s; 0 .. %s)' % (v, self.bound(a)))
        elif k < 0.8:
            self.emit('    for (size_t %s = %s; %s > 0; %s--)' % (v, self.bound(a), v, v))
            mutable = down = True
        elif k < 0.9:
            self.emit('    for (int %s = %d; %s < cast(int) %s; %s++)' % (v, r.choice([0, 0, -1]), v, self.bound(a), v))
            mutable = True
        else:
            self.emit('    foreach (%s, ref x%d; %s)' % (v, depth, a))
        self.emit('    {')
        vars_ = vars_ + [v]
        for _ in range(r.randint(1, 3)):
            k = r.random()
            if k < 0.15 and depth < 2:
                self.loop(depth + 1, arrs, vars_)
            elif k < 0.3:
                self.emit('        ' + self.change(arrs, v if mutable else 'n', down and mutable))
            elif k < 0.45:
                b = r.choice(arrs)
                w = r.choice(vars_)
                cmp = r.choice(['<', '<=', '>', '>=', '!='])
                self.emit('        if (%s %s %s.length) { mark = __LINE__; acc += %s[%s]; }' % (w, cmp, b, b, self.index(w, b)))
            else:
                b = r.choice(arrs)
                self.access(b, self.index(r.choice(vars_), b))
        self.emit('    }')

    def func(self, name):
        r = self.r
        kind = r.random()
        if kind < 0.6:
            self.emit('void %s(int[] a, int[] b, size_t n)' % name)
            arrs = ['a', 'b']
        elif kind < 0.8:
            self.emit('void %s(ref int[] a, ref int[] b, size_t n)' % name)
            arrs = ['a', 'b']
        else:
            self.emit('void %s(int[] a, int[] b, size_t n)' % name)
            arrs = ['a', 'b', 'g']
        self.emit('{')
        if self.chance(0.3):
            c = r.choice(['<', '<=', '>', '>=', '==', '!='])
            self.emit('    if (n %s a.length) return;' % c)
        if self.chance(0.2):
            self.emit('    if (b.length < a.length) return;')
        for _ in range(r.randint(1, 2)):
            self.loop(0, arrs, ['n'])
        if self.chance(0.3):
            self.access(r.choice(arrs), self.index('n', 'a'))
        self.emit('}')
        self.emit('')

    def program(self):
        self.emit('// generated by boundsfuzz.py')
        self.emit('import core.exception : RangeError;')
        self.emit('import core.stdc.stdio : printf;')
        self.emit('')
        self.emit('@safe:')
        self.emit('')
        self.emit('size_t mark;     // the line of the access being made')
        self.emit('int acc;')
        self.emit('int[] g;')
        self.emit('void shrinkG() { if (g.length) g = g[0 .. $ - 1]; }')
        self.emit('void cut(ref int[] x) { if (x.length > 1) x = x[1 .. $]; }')
        self.emit('')
        names = []
        for k in range(self.n):
            name = 'f%d' % k
            names.append(name)
            self.func(name)
        self.emit('void main() @trusted')
        self.emit('{')
        self.emit('    static immutable size_t[] lens = [0, 1, 2, 3, 5, 8];')
        self.emit('    uint h = 1;')
        self.emit('    int[] mk(size_t len, int base) { auto r = new int[len]; foreach (k, ref x; r) x = cast(int) (base + 3 * k + 1); return r; }')
        for name in names:
            self.emit('    foreach (la; lens)')
            self.emit('        foreach (lb; lens)')
            self.emit('            foreach (n; [0, 1, 3, 7])')
            self.emit('            {')
            self.emit('                auto a = mk(la, 10);')
            self.emit('                auto b = mk(lb, 100);')
            self.emit('                g = mk((la + lb) % 6, 1000);')
            self.emit('                mark = 0;')
            self.emit('                acc = 0;')
            self.emit('                try')
            self.emit('                {')
            self.emit('                    if (n == 7) %s(a, a, n); else %s(a, b, n);' % (name, name))
            self.emit('                }')
            self.emit('                catch (RangeError e)')
            self.emit('                {')
            self.emit('                    if (e.line != mark) assert(0, "wrong line");')
            self.emit('                    h = h * 31 + cast(uint) e.line;')
            self.emit('                }')
            self.emit('                h = h * 31 + cast(uint) acc;')
            self.emit('                h = h * 31 + cast(uint) (a.length + 7 * b.length + 13 * g.length);')
            self.emit('            }')
            self.emit('    printf("%s %%u\\n", h);' % name)
        self.emit('}')
        return '\n'.join(self.out) + '\n'


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('seed', type=int)
    ap.add_argument('--size', choices=list(SIZES), default='medium')
    args = ap.parse_args()
    print(Gen(args.seed, args.size).program(), end='')


if __name__ == '__main__':
    main()
