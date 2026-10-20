#!/usr/bin/env python3
"""Random D program generator for differential testing of the compiler.

Each program is deterministic and free of undefined or implementation-defined
behaviour: divisors are never zero or -1, shift counts are masked to the width
of the promoted operand, array indices are masked to the array length, floating
point values stay multiples of a power of two small enough that every
operation on them is exact, and floating point values are converted to
integers only within range. Any difference between the outputs of two
compilations of the same program is a compiler bug.

The program prints one line per function call with a running digest, so the
first differing line points at the function that is miscompiled.

Usage: progfuzz.py SEED [--size small|medium|large] > prog.d
"""

import argparse
import random

INTS = ['byte', 'ubyte', 'short', 'ushort', 'int', 'uint', 'long', 'ulong']
BITS = {'byte': 8, 'ubyte': 8, 'short': 16, 'ushort': 16, 'int': 32, 'uint': 32,
        'long': 64, 'ulong': 64, 'bool': 8}
SIGNED = {'byte', 'short', 'int', 'long'}
FLOATS = ['double', 'float']
DIVISORS = [2, 3, 4, 5, 6, 7, 8, 9, 10, 12, 16, 25, 31, 100, 255, 256, 641, 1000,
            65537, -2, -3, -5, -7, -10, -256]


def promote(t):
    """The type of t after the integer promotions."""
    return 'int' if BITS[t] < 32 else t


def arith(a, b):
    """The type of a binary arithmetic operation on a and b."""
    a, b = promote(a), promote(b)
    if a == b:
        return a
    if BITS[a] != BITS[b]:
        return a if BITS[a] > BITS[b] else b
    # same size, one signed and one unsigned: unsigned
    return a if a not in SIGNED else b


class Var:
    def __init__(self, name, ty, mutable=True):
        self.name = name
        self.ty = ty
        self.mutable = mutable


class Gen:
    def __init__(self, seed, size):
        self.r = random.Random(seed)
        self.seed = seed
        self.size = size
        self.out = []
        self.uid = 0
        self.funcs = []       # (name, [param types], return type)
        self.structs = []     # (name, [(field, type)])
        self.callable = []    # functions an expression may call
        self.calls = False    # whether the function being generated calls another

    def name(self, prefix):
        self.uid += 1
        return '%s%d' % (prefix, self.uid)

    def chance(self, p):
        return self.r.random() < p

    # ---------------------------------------------------------------- expressions

    def lit(self, ty):
        r = self.r
        if ty == 'bool':
            return r.choice(['true', 'false'])
        b = BITS[ty]
        k = r.random()
        if k < 0.5:
            v = r.randint(-100, 100)
        elif k < 0.7:
            v = r.choice([0, 1, -1, 2, 7, 8, 15, 16, 31, 32, 63, 64, 127, 128, 255, 256])
        else:
            v = r.randint(-(1 << (b - 1)), (1 << (b - 1)) - 1)
        if ty not in SIGNED:
            v &= (1 << b) - 1
        else:
            v = max(-(1 << (b - 1)) + 1, min((1 << (b - 1)) - 1, v))
        if ty == 'long':
            return '%dL' % v
        if ty == 'ulong':
            return '%dUL' % v
        if ty == 'uint':
            return '%dU' % v
        if ty == 'int':
            return str(v)
        return 'cast(%s)%d' % (ty, v)

    def ivar(self, scope, ty=None):
        vs = [v for v in scope if v.ty in INTS and (ty is None or v.ty == ty)]
        return self.r.choice(vs) if vs else None

    def iexpr(self, scope, depth):
        """An integer expression; returns (code, type)."""
        r = self.r
        if depth <= 0 or self.chance(0.25):
            v = self.ivar(scope)
            k = r.random()
            if v and k < 0.6:
                return v.name, v.ty
            if k < 0.8:
                t = r.choice(INTS)
                return self.lit(t), t
            if k < 0.9:
                return 'garr[%d]' % r.randint(0, 63), 'long'
            return 'gi[%d]' % r.randint(0, 15), 'int'
        k = r.random()
        if k < 0.30:
            a, ta = self.iexpr(scope, depth - 1)
            b, tb = self.iexpr(scope, depth - 1)
            op = r.choice(['+', '-', '*', '&', '|', '^', '+', '-'])
            return '(%s %s %s)' % (a, op, b), arith(ta, tb)
        if k < 0.38:
            a, ta = self.iexpr(scope, depth - 1)
            pt = promote(ta)
            if self.chance(0.5):
                return '(%s %s %d)' % (a, r.choice(['<<', '>>', '>>>']), r.randint(0, BITS[pt] - 1)), pt
            b, tb = self.iexpr(scope, depth - 1)
            return '(%s %s (%s & %d))' % (a, r.choice(['<<', '>>', '>>>']), b, BITS[pt] - 1), pt
        if k < 0.46:
            a, ta = self.iexpr(scope, depth - 1)
            op = r.choice(['/', '%'])
            if self.chance(0.6):
                d = r.choice(DIVISORS)
                if promote(ta) not in SIGNED and d < 0:
                    d = -d
                dt = 'long' if BITS[promote(ta)] == 64 else 'int'
                if promote(ta) not in SIGNED:
                    dt = 'ulong' if BITS[promote(ta)] == 64 else 'uint'
                lit = '%d%s' % (d, {'long': 'L', 'ulong': 'UL', 'uint': 'U', 'int': ''}[dt])
                return '(%s %s %s)' % (a, op, lit), arith(ta, dt)
            b, tb = self.iexpr(scope, depth - 1)
            # (b & 15) | 1 is odd and positive, never 0 or -1
            return '(%s %s ((%s & 15) | 1))' % (a, op, b), arith(ta, promote(tb))
        if k < 0.56:
            c = self.cond(scope, depth - 1)
            a, ta = self.iexpr(scope, depth - 1)
            b, tb = self.iexpr(scope, depth - 1)
            return '(%s ? %s : %s)' % (c, a, b), arith(ta, tb)
        if k < 0.64:
            a, ta = self.iexpr(scope, depth - 1)
            t = r.choice(INTS)
            return 'cast(%s)(%s)' % (t, a), t
        if k < 0.68:
            a, ta = self.iexpr(scope, depth - 1)
            return '(%s(%s))' % (r.choice(['-', '~']), a), promote(ta)
        if k < 0.74:
            a, ta = self.iexpr(scope, depth - 1)
            return 'garr[(%s) & 63]' % a, 'long'
        if k < 0.78:
            a, ta = self.iexpr(scope, depth - 1)
            return 'opq(%s)' % a, 'long'
        if k < 0.82:
            a, ta = self.iexpr(scope, depth - 1)
            b, tb = self.iexpr(scope, depth - 1)
            t = r.choice(['int', 'long', 'uint', 'ulong'])
            return '%s!%s(cast(%s)(%s), cast(%s)(%s))' % (r.choice(['tmin', 'tmax', 'tmix']), t, t, a, t, b), t
        if k < 0.86 and self.structs:
            sname, fields = r.choice(self.structs)
            a, ta = self.iexpr(scope, depth - 1)
            f, ft = r.choice(fields)
            if ft in FLOATS:
                return 'cast(long)(mk%s(%s).%s * 64)' % (sname, a, f), 'long'
            return 'mk%s(%s).%s' % (sname, a, f), ft
        if k < 0.90:
            fv = [v for v in scope if v.ty in FLOATS]
            if fv:
                v = r.choice(fv)
                return 'cast(long)(%s * 64)' % v.name, 'long'
        if k < 0.94 and self.callable:
            fname, ptys, rty = r.choice(self.callable)
            self.calls = True
            args = ', '.join(self.arg(scope, t, depth - 1) for t in ptys)
            return '%s(%s)' % (fname, args), 'long'
        dv = [v for v in scope if v.ty == 'dg']
        if dv:
            v = r.choice(dv)
            a, ta = self.iexpr(scope, depth - 1)
            return '%s(%s)' % (v.name, a), 'long'
        a, ta = self.iexpr(scope, depth - 1)
        b, tb = self.iexpr(scope, depth - 1)
        return '(%s + %s)' % (a, b), arith(ta, tb)

    def cond(self, scope, depth):
        r = self.r
        a, ta = self.iexpr(scope, depth)
        b, tb = self.iexpr(scope, depth)
        c = '(%s %s %s)' % (a, r.choice(['<', '>', '<=', '>=', '==', '!=']), b)
        if self.chance(0.15):
            d, td = self.iexpr(scope, depth)
            c = '(%s %s (%s & 1) == 0)' % (c, r.choice(['&&', '||']), d)
        return c

    def fexpr(self, scope, ty):
        """A floating point expression whose value is exact: a sum of up to
        three terms, each a variable, a small constant, or a product of two"""
        r = self.r
        fv = [v.name for v in scope if v.ty in FLOATS]

        def atom():
            if fv and self.chance(0.7):
                return r.choice(fv)
            if self.chance(0.5):
                a, ta = self.iexpr(scope, 1)
                return 'cast(%s)((%s) & 1023)' % (ty, a)
            return '%d.%s' % (r.randint(-64, 64), r.choice(['0', '5', '25', '125', '0625']))

        def term():
            if self.chance(0.3):
                return '%s * %s' % (atom(), atom())
            return atom()
        n = r.randint(1, 3)
        e = term()
        for _ in range(n - 1):
            e = '%s %s %s' % (e, r.choice(['+', '-']), term())
        return e

    def arg(self, scope, ty, depth):
        if ty in FLOATS:
            return 'fq%s(%s)' % ('f' if ty == 'float' else '', self.fexpr(scope, ty))
        if ty.startswith('S'):
            a, ta = self.iexpr(scope, depth)
            return 'mk%s(%s)' % (ty, a)
        a, ta = self.iexpr(scope, depth)
        return 'cast(%s)(%s)' % (ty, a)

    # ---------------------------------------------------------------- statements

    def stmts(self, scope, depth, n, ind, inloop, out):
        for _ in range(n):
            self.stmt(scope, depth, ind, inloop, out)

    def block(self, scope, depth, n, ind, inloop, out):
        out.append(ind + '{')
        self.stmts(list(scope), depth, n, ind + '    ', inloop, out)
        out.append(ind + '}')

    def stmt(self, scope, depth, ind, inloop, out):
        r = self.r
        k = r.random()
        muts = [v for v in scope if v.mutable and v.ty in INTS]
        if k < 0.30 and muts:
            v = r.choice(muts)
            e, te = self.iexpr(scope, 3)
            op = r.choice(['=', '+=', '-=', '^=', '|=', '&=', '*=', '='])
            out.append(ind + '%s %s cast(%s)(%s);' % (v.name, op, v.ty, e))
            return
        if k < 0.36:
            fv = [v for v in scope if v.mutable and v.ty in FLOATS]
            if fv:
                v = r.choice(fv)
                out.append(ind + '%s = fq%s(%s);' % (v.name, 'f' if v.ty == 'float' else '', self.fexpr(scope, v.ty)))
                return
        if k < 0.42:
            a, ta = self.iexpr(scope, 2)
            b, tb = self.iexpr(scope, 2)
            out.append(ind + 'loc[(%s) & 15] %s cast(long)(%s);' % (a, r.choice(['=', '+=', '^=']), b))
            return
        if k < 0.46:
            t = r.choice(INTS + ['long', 'int', 'double'])
            v = Var(self.name('v'), t)
            if t in FLOATS:
                out.append(ind + '%s %s = fq%s(%s);' % (t, v.name, 'f' if t == 'float' else '', self.fexpr(scope, t)))
            else:
                e, te = self.iexpr(scope, 2)
                out.append(ind + '%s %s = cast(%s)(%s);' % (t, v.name, t, e))
            scope.append(v)
            return
        if depth <= 0:
            if muts:
                v = r.choice(muts)
                e, te = self.iexpr(scope, 2)
                out.append(ind + '%s ^= cast(%s)(%s);' % (v.name, v.ty, e))
            return
        if k < 0.56:
            out.append(ind + 'if %s' % self.cond(scope, 2))
            self.block(scope, depth - 1, r.randint(1, 4), ind, inloop, out)
            if self.chance(0.5):
                out.append(ind + 'else')
                self.block(scope, depth - 1, r.randint(1, 3), ind, inloop, out)
            return
        if k < 0.64:
            iv = Var(self.name('i'), r.choice(['int', 'long', 'uint', 'size_t']), False)
            lo = r.randint(-3, 3) if iv.ty in ('int', 'long') else 0
            out.append(ind + 'foreach (%s %s; %d .. %d)' % (iv.ty, iv.name, lo, lo + r.randint(1, 5)))
            if iv.ty == 'size_t':
                iv.ty = 'ulong'
            out.append(ind + '{')
            inner = list(scope) + [iv]
            self.stmts(inner, depth - 1, r.randint(1, 5), ind + '    ', True, out)
            if self.chance(0.3):
                out.append(ind + '    if ((%s & 3) == 1) break;' % self.iexpr(inner, 1)[0])
            if self.chance(0.3):
                out.append(ind + '    if ((%s & 3) == 2) continue;' % self.iexpr(inner, 1)[0])
            out.append(ind + '}')
            return
        if k < 0.68:
            c = self.name('w')
            out.append(ind + 'for (int %s = 0; %s < %d; ++%s)' % (c, c, r.randint(1, 5), c))
            out.append(ind + '{')
            inner = list(scope) + [Var(c, 'int', False)]
            self.stmts(inner, depth - 1, r.randint(1, 4), ind + '    ', True, out)
            out.append(ind + '}')
            return
        if k < 0.72:
            e, te = self.iexpr(scope, 2)
            out.append(ind + 'switch (cast(int)(%s) & 7)' % e)
            out.append(ind + '{')
            for c in sorted(r.sample(range(8), r.randint(1, 4))):
                out.append(ind + '    case %d:' % c)
                self.block(scope, depth - 1, r.randint(1, 2), ind + '        ', inloop, out)
                if self.chance(0.8):
                    out.append(ind + '        break;')
                else:
                    out.append(ind + '        goto default;')
            out.append(ind + '    default:')
            self.block(scope, depth - 1, 1, ind + '        ', inloop, out)
            out.append(ind + '        break;')
            out.append(ind + '}')
            return
        if k < 0.77:
            # static array, slice of it, loop over the slice
            a = self.name('arr')
            n = r.choice([4, 8, 16])
            t = r.choice(['int', 'long', 'ubyte', 'short', 'uint'])
            out.append(ind + '%s[%d] %s;' % (t, n, a))
            out.append(ind + 'foreach (k, ref el; %s) el = cast(%s)(%s + k * %d);' % (a, t, self.iexpr(scope, 1)[0], r.randint(1, 9)))
            lo, _ = self.iexpr(scope, 1)
            hi, _ = self.iexpr(scope, 1)
            s = self.name('sl')
            out.append(ind + 'auto %s = %s[(%s) & %d .. %d + ((%s) & %d)];' % (s, a, lo, n // 2 - 1, n // 2, hi, n // 2 - 1))
            out.append(ind + 'foreach (ref el; %s) el %s= cast(%s)(%s);' % (s, r.choice(['+', '^', '-']), t, self.iexpr(scope, 1)[0]))
            acc = self.name('v')
            out.append(ind + 'long %s = 0;' % acc)
            out.append(ind + 'foreach (k, el; %s) %s = %s * 3 + el + cast(long)k;' % (a, acc, acc))
            out.append(ind + 'loc[%d] ^= %s + cast(long)%s.length;' % (r.randint(0, 15), acc, s))
            scope.append(Var(acc, 'long'))
            return
        if k < 0.80:
            # dynamic array with appends
            a = self.name('da')
            out.append(ind + 'long[] %s;' % a)
            out.append(ind + 'foreach (k; 0 .. %d) %s ~= %s + cast(long)k;' % (r.randint(0, 6), a, self.iexpr(scope, 1)[0]))
            out.append(ind + '%s ~= %s;' % (a, self.iexpr(scope, 1)[0]))
            acc = self.name('v')
            out.append(ind + 'long %s = cast(long)%s.length;' % (acc, a))
            out.append(ind + 'foreach (el; %s) %s = %s * 5 ^ el;' % (a, acc, acc))
            scope.append(Var(acc, 'long'))
            return
        if k < 0.84 and not inloop:
            # a closure capturing a local; later calls see its current value
            muts = [v for v in scope if v.mutable and v.ty in INTS]
            if muts:
                cap = r.choice(muts)
                d = self.name('dg')
                if self.chance(0.5):
                    out.append(ind + 'auto %s = (long q) => q * %d + cast(long)%s;' % (d, r.randint(-9, 9), cap.name))
                    scope.append(Var(d, 'dg', False))
                else:
                    # it changes what it captures, so it is called only where
                    # nothing else in the statement reads that
                    out.append(ind + 'long %s(long q) { %s += cast(%s)q; return q ^ cast(long)%s; }' % (d, cap.name, cap.ty, cap.name))
                    t = self.name('v')
                    out.append(ind + 'long %s = %s(%s);' % (t, d, self.iexpr([v for v in scope if v is not cap], 2)[0]))
                    scope.append(Var(t, 'long'))
                return
        if k < 0.89:
            # exceptions
            muts = [v for v in scope if v.mutable and v.ty in INTS]
            if muts:
                v = r.choice(muts)
                out.append(ind + 'try')
                out.append(ind + '{')
                inner = list(scope)
                self.stmts(inner, depth - 1, r.randint(0, 2), ind + '    ', inloop, out)
                out.append(ind + '    if ((%s & 3) != 0) throw new FzEx(%s);' % (self.iexpr(inner, 1)[0], self.iexpr(inner, 2)[0]))
                self.stmts(inner, depth - 1, r.randint(0, 2), ind + '    ', inloop, out)
                out.append(ind + '}')
                ex = self.name('ex')
                out.append(ind + 'catch (FzEx %s)' % ex)
                out.append(ind + '{')
                out.append(ind + '    %s ^= cast(%s)%s.v;' % (v.name, v.ty, ex))
                out.append(ind + '}')
                if self.chance(0.5):
                    out.append(ind + 'finally')
                    out.append(ind + '{')
                    out.append(ind + '    loc[%d] += 1;' % r.randint(0, 15))
                    out.append(ind + '}')
                return
        if k < 0.93 and self.structs:
            sname, fields = r.choice(self.structs)
            s = self.name('s')
            out.append(ind + '%s %s = mk%s(%s);' % (sname, s, sname, self.iexpr(scope, 2)[0]))
            f, ft = r.choice(fields)
            if ft in FLOATS:
                out.append(ind + '%s.%s = fq%s(%s.%s * 2 - 1);' % (s, f, 'f' if ft == 'float' else '', s, f))
            else:
                out.append(ind + '%s.%s += cast(%s)(%s);' % (s, f, ft, self.iexpr(scope, 2)[0]))
            acc = self.name('v')
            out.append(ind + 'long %s = %s.digest() + use%s(%s, %s);' % (acc, s, sname, s, self.iexpr(scope, 1)[0]))
            scope.append(Var(acc, 'long'))
            return
        if k < 0.96:
            out.append(ind + 'if ((%s & 7) == 3) return %s;' % (self.iexpr(scope, 1)[0], self.iexpr(scope, 2)[0]))
            return
        if inloop and self.chance(0.5):
            out.append(ind + 'if ((%s & 7) == 5) break;' % self.iexpr(scope, 1)[0])
            return
        c = self.name('w')
        out.append(ind + 'int %s = %d;' % (c, r.randint(1, 6)))
        out.append(ind + 'while (%s-- > 0)' % c)
        out.append(ind + '{')
        self.stmts(list(scope) + [Var(c, 'int', False)], depth - 1, r.randint(1, 3), ind + '    ', True, out)
        out.append(ind + '}')

    # ---------------------------------------------------------------- program

    def struct(self, i):
        r = self.r
        name = 'S%d' % i
        kind = r.random()
        if kind < 0.3:
            t = r.choice(FLOATS)
            fields = [('f%d' % j, t) for j in range(r.randint(1, 4))]
        else:
            fields = [('f%d' % j, r.choice(INTS + FLOATS)) for j in range(r.randint(1, 6))]
        self.structs.append((name, fields))
        o = self.out
        o.append('struct %s' % name)
        o.append('{')
        for f, t in fields:
            o.append('    %s %s;' % (t, f))
        o.append('    long digest() const')
        o.append('    {')
        o.append('        long h = %d;' % r.randint(1, 1000))
        for f, t in fields:
            if t in FLOATS:
                o.append('        h = h * 31 + cast(long)(%s * 64);' % f)
            else:
                o.append('        h = h * 31 + %s;' % f)
        o.append('        return h;')
        o.append('    }')
        o.append('}')
        o.append('%sS%d mk%s(long x)' % ('pragma(inline, false) ' if self.chance(0.5) else '', i, name))
        o.append('{')
        o.append('    %s s;' % name)
        for j, (f, t) in enumerate(fields):
            if t in FLOATS:
                o.append('    s.%s = cast(%s)((x + %d) & 255) / 4;' % (f, t, j))
            else:
                o.append('    s.%s = cast(%s)(x * %d + %d);' % (f, t, j + 3, j))
        o.append('    return s;')
        o.append('}')
        o.append('%slong use%s(%s s, long k)' % ('pragma(inline, false) ' if self.chance(0.5) else '', name, name))
        o.append('{')
        o.append('    return s.digest() * 7 + k;')
        o.append('}')

    def func(self, i):
        r = self.r
        sz = {'small': (4, 8), 'medium': (6, 14), 'large': (10, 24)}[self.size]
        np = r.randint(1, 9)
        ptys = [r.choice(INTS + ['long', 'int', 'double', 'float'] + [s for s, _ in self.structs]) for _ in range(np)]
        params = [Var('p%d' % j, t) for j, t in enumerate(ptys)]
        name = 'f%d' % i
        o = self.out
        attr = r.choice(['pragma(inline, false) ', '', ''])
        o.append('%slong %s(%s)' % (attr, name, ', '.join('%s %s' % (p.ty, p.name) for p in params)))
        o.append('{')
        scope = [p for p in params if not p.ty.startswith('S')]
        for p in params:
            if p.ty.startswith('S'):
                v = Var(self.name('v'), 'long')
                o.append('    long %s = %s.digest();' % (v.name, p.name))
                scope.append(v)
        for _ in range(r.randint(2, 8)):
            t = r.choice(INTS + ['long', 'long', 'int', 'double'])
            v = Var(self.name('v'), t)
            if t in FLOATS:
                o.append('    %s %s = %d.25;' % (t, v.name, r.randint(-50, 50)))
            else:
                o.append('    %s %s = %s;' % (t, v.name, self.lit(t)))
            scope.append(v)
        o.append('    long[16] loc;')
        self.callable = [f for f in self.funcs if f[2] == 'leaf'][-3:]
        self.calls = False
        body = []
        self.stmts(scope, 3, r.randint(*sz), '    ', False, body)
        o.extend(body)
        o.append('    long h = 0;')
        o.append('    foreach (l; loc) h = h * 31 + l;')
        for v in scope:
            if v.ty in FLOATS:
                o.append('    h = h * 31 + cast(long)(%s * 64);' % v.name)
            elif v.ty in INTS:
                o.append('    h = h * 31 + %s;' % v.name)
        o.append('    return h;')
        o.append('}')
        self.funcs.append((name, ptys, 'calls' if self.calls else 'leaf'))

    def program(self):
        r = self.r
        o = self.out
        o.append('// generated by progfuzz.py, seed %d' % self.seed)
        o.append('module fz%d;' % self.seed)
        o.append('import core.stdc.stdio;')
        o.append('__gshared long[64] garr;')
        o.append('__gshared int[16] gi;')
        o.append('class FzEx : Exception { long v; this(long v) { super("fz"); this.v = v; } }')
        o.append('pragma(inline, false) long opq(long x) { return x ^ (x >>> 7) ^ (x << 3); }')
        o.append('T tmin(T)(T a, T b) { return a < b ? a : b; }')
        o.append('T tmax(T)(T a, T b) { return a < b ? b : a; }')
        o.append('T tmix(T)(T a, T b) { return cast(T)((a ^ (b << 5)) + (b >>> 2)); }')
        # quantize to a multiple of 1/64 below 2^12 in magnitude (1/8 below 2^6
        # for float), where sums of three products of two values are exact
        o.append('pragma(inline, false) double fq(double x)')
        o.append('{')
        o.append('    if (!(x > -1e300 && x < 1e300)) return 1;')
        o.append('    while (x >= 4096 || x <= -4096) x /= 1024;')
        o.append('    return cast(double)cast(long)(x * 64) / 64;')
        o.append('}')
        o.append('pragma(inline, false) float fqf(float x)')
        o.append('{')
        o.append('    if (!(x > -1e30f && x < 1e30f)) return 1;')
        o.append('    while (x >= 64 || x <= -64) x /= 16;')
        o.append('    return cast(float)cast(int)(x * 8) / 8;')
        o.append('}')
        o.append('__gshared ulong digest = 0xcbf29ce484222325;')
        o.append('void mix(long v) { digest = (digest ^ cast(ulong)v) * 0x100000001b3; }')
        for i in range(r.randint(1, 4)):
            self.struct(i)
        nf = {'small': 4, 'medium': 6, 'large': 9}[self.size]
        for i in range(nf):
            self.func(i)
        o.append('void main()')
        o.append('{')
        o.append('    foreach (k, ref g; garr) g = cast(long)(k * 7 - 100);')
        o.append('    foreach (k, ref g; gi) g = cast(int)(k * k - 20);')
        o.append('    foreach (long x; 0 .. 4)')
        o.append('    {')
        scope = [Var('x', 'long', False)]
        for name, ptys, _ in self.funcs:
            self.callable = []
            args = ', '.join(self.arg(scope, t, 1) for t in ptys)
            o.append('        mix(%s(%s));' % (name, args))
            o.append('        printf("%s %%d %%016llx\\n", cast(int)x, digest);' % name)
        o.append('    }')
        o.append('    ulong g = 0;')
        o.append('    foreach (v; garr) g = g * 31 + v;')
        o.append('    printf("garr %016llx\\n", g);')
        o.append('}')
        return '\n'.join(o) + '\n'


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('seed', type=int)
    ap.add_argument('--size', choices=['small', 'medium', 'large'], default='medium')
    a = ap.parse_args()
    print(Gen(a.seed, a.size).program(), end='')


if __name__ == '__main__':
    main()
