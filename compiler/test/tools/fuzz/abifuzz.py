#!/usr/bin/env python3
"""Random calling convention test generator.

For a seed it writes, into a directory:
    callee.d   functions taking and returning random parameter lists, each as
               extern(D) fN_d and extern(C) fN_c, plus extern(C) variadic ones
    callee.c   the same extern(C) functions written in C, as fN_cc
    caller.d   a main calling fN_d, fN_c and fN_cc
    caller.c   a main calling fN_c, the D functions from C
    expect.txt what both mains print

Each callee folds every scalar of its parameters, in order, into a hash it
leaves in a global and from which it builds its return value; the callers
print the hash and the hash of the returned value. The expected output is
computed here, so it needs no reference compiler: any difference is a
compiler (or C compiler) bug.

The parameter types are the integer types, float, double, bool, and structs
of them, of nested structs and of static arrays, weighted towards homogeneous
floating point aggregates (HFAs) and towards parameter lists that run out of
registers.

Usage: abifuzz.py SEED OUTDIR
"""

import os
import random
import struct as pystruct
import sys

M64 = (1 << 64) - 1
H0 = 0xcbf29ce484222325
PRIME = 0x100000001b3

SCALARS = {
    # D type: (C type, bits, signed)
    'byte': ('signed char', 8, True),
    'ubyte': ('unsigned char', 8, False),
    'short': ('short', 16, True),
    'ushort': ('unsigned short', 16, False),
    'int': ('int', 32, True),
    'uint': ('unsigned', 32, False),
    'long': ('long long', 64, True),
    'ulong': ('unsigned long long', 64, False),
    'float': ('float', 32, None),
    'double': ('double', 64, None),
    'bool': ('_Bool', 8, False),
}


class Struct:
    def __init__(self, name, fields):
        self.name = name
        self.fields = fields    # [(name, type, count)] count 0 means not an array


def mix(h, v):
    return ((h ^ (v & M64)) * PRIME) & M64


class Gen:
    def __init__(self, seed):
        self.r = random.Random(seed)
        self.seed = seed
        self.structs = {}

    # ------------------------------------------------------------ types

    def scalar(self):
        r = self.r
        return r.choice(['int', 'long', 'double', 'float', 'byte', 'ubyte', 'short', 'ushort',
                         'uint', 'ulong', 'bool', 'double', 'float'])

    def new_struct(self, depth=0):
        r = self.r
        name = 'S%d' % len(self.structs)
        k = r.random()
        fields = []
        if k < 0.4:
            # an HFA: one to four of float or double, maybe as an array or a nested HFA
            t = r.choice(['float', 'double'])
            n = r.randint(1, 4)
            if self.chance(0.25) and n >= 2:
                fields.append(('a', t, n))
            elif self.chance(0.2) and n >= 2 and depth < 2:
                inner = self.new_struct_of(t, n - 1, depth + 1)
                fields.append(('a', t, 0))
                fields.append(('n', inner, 0))
            else:
                fields = [('f%d' % i, t, 0) for i in range(n)]
        elif k < 0.5:
            # nearly an HFA: five of a kind, or mixed float and double
            t = self.r.choice(['float', 'double'])
            if self.chance(0.5):
                fields = [('f%d' % i, t, 0) for i in range(5)]
            else:
                fields = [('f0', 'float', 0), ('f1', 'double', 0)]
        else:
            for i in range(r.randint(1, 6)):
                if self.chance(0.1) and depth < 2:
                    fields.append(('f%d' % i, self.new_struct(depth + 1), 0))
                elif self.chance(0.1):
                    fields.append(('f%d' % i, self.scalar(), r.randint(2, 5)))
                else:
                    fields.append(('f%d' % i, self.scalar(), 0))
        name = 'S%d' % len(self.structs)
        self.structs[name] = Struct(name, fields)
        return name

    def new_struct_of(self, t, n, depth):
        name = 'S%d' % len(self.structs)
        self.structs[name] = Struct(name, [('f%d' % i, t, 0) for i in range(n)])
        return name

    def chance(self, p):
        return self.r.random() < p

    def ptype(self):
        if self.chance(0.45):
            if self.structs and self.chance(0.6):
                return self.r.choice(list(self.structs))
            return self.new_struct()
        return self.scalar()

    # ------------------------------------------------------------ values

    def value(self, t):
        """A random value of type t, as a Python structure"""
        r = self.r
        if t in SCALARS:
            ct, bits, signed = SCALARS[t]
            if t == 'bool':
                return r.random() < 0.5
            if signed is None:
                return r.randint(-400, 400) / 4
            if signed:
                return r.randint(-(1 << (bits - 1)), (1 << (bits - 1)) - 1)
            return r.randint(0, (1 << bits) - 1)
        s = self.structs[t]
        return [[self.value(ft) for _ in range(n)] if n else self.value(ft) for _, ft, n in s.fields]

    def bits(self, t, v):
        """The scalars of value v of type t as the callee hashes them"""
        if t in SCALARS:
            ct, nbits, signed = SCALARS[t]
            if signed is None:
                return [int(v * 4) & M64]
            if t == 'bool':
                return [1 if v else 0]
            return [v & ((1 << nbits) - 1)]
        out = []
        for (_, ft, n), fv in zip(self.structs[t].fields, v):
            if n:
                for e in fv:
                    out += self.bits(ft, e)
            else:
                out += self.bits(ft, fv)
        return out

    def from_hash(self, t, h, k=0):
        """The value the callee returns for hash h; k counts the scalars so far"""
        if t in SCALARS:
            ct, nbits, signed = SCALARS[t]
            x = (h >> (k * 5 % 48)) & M64
            if t == 'bool':
                return x & 1 == 1, k + 1
            if signed is None:
                return ((x & 0xFFFF) - 0x8000) / 4, k + 1
            x &= (1 << nbits) - 1
            if signed and x >> (nbits - 1):
                x -= 1 << nbits
            return x, k + 1
        out = []
        for _, ft, n in self.structs[t].fields:
            if n:
                arr = []
                for _ in range(n):
                    e, k = self.from_hash(ft, h, k)
                    arr.append(e)
                out.append(arr)
            else:
                e, k = self.from_hash(ft, h, k)
                out.append(e)
        return out, k

    # ------------------------------------------------------------ source text

    def dlit(self, t, v):
        if t in SCALARS:
            if t == 'bool':
                return 'true' if v else 'false'
            if SCALARS[t][2] is None:
                return '%r%s' % (v, 'f' if t == 'float' else '')
            if t == 'long':
                return '%dL' % v if v != -(1 << 63) else 'long.min'
            if t == 'ulong':
                return '%dUL' % v
            if t == 'uint':
                return '%dU' % v
            if t == 'int':
                return '%d' % v if v != -(1 << 31) else 'int.min'
            return 'cast(%s)%d' % (t, v)
        parts = []
        for (_, ft, n), fv in zip(self.structs[t].fields, v):
            if n:
                parts.append('[%s]' % ', '.join(self.dlit(ft, e) for e in fv))
            else:
                parts.append(self.dlit(ft, fv))
        return '%s(%s)' % (t, ', '.join(parts))

    def clit(self, t, v, top=True):
        if t in SCALARS:
            if t == 'bool':
                return '1' if v else '0'
            if SCALARS[t][2] is None:
                return '%r%s' % (v, 'f' if t == 'float' else '')
            if t == 'long':
                return '%dLL' % v if v != -(1 << 63) else '(-9223372036854775807LL - 1)'
            if t == 'ulong':
                return '%dULL' % v
            if t == 'uint':
                return '%dU' % v
            if t == 'int':
                return '%d' % v if v != -(1 << 31) else '(-2147483647 - 1)'
            return '(%s)%d' % (SCALARS[t][0], v)
        parts = []
        for (_, ft, n), fv in zip(self.structs[t].fields, v):
            if n:
                parts.append('{%s}' % ', '.join(self.clit(ft, e, False) for e in fv))
            else:
                parts.append(self.clit(ft, fv, False))
        body = '{%s}' % ', '.join(parts)
        return '(%s)%s' % (t, body) if top else body

    def ctype(self, t):
        return SCALARS[t][0] if t in SCALARS else t

    def hash_stmts(self, t, expr, lang, out, ind):
        """Statements folding the scalars of expr into h"""
        if t in SCALARS:
            ct, nbits, signed = SCALARS[t]
            if lang == 'd':
                if signed is None:
                    v = 'cast(ulong)cast(long)(%s * 4)' % expr
                elif t == 'bool':
                    v = 'cast(ulong)(%s ? 1 : 0)' % expr
                else:
                    v = 'cast(ulong)cast(u%s)%s' % (t if not t.startswith('u') else t[1:], expr)
            else:
                if signed is None:
                    v = '(unsigned long long)(long long)(%s * 4)' % expr
                elif t == 'bool':
                    v = '(unsigned long long)(%s ? 1 : 0)' % expr
                else:
                    v = '(unsigned long long)(%s)%s' % ({8: 'unsigned char', 16: 'unsigned short',
                                                          32: 'unsigned', 64: 'unsigned long long'}[nbits], expr)
            out.append(ind + 'h = (h ^ %s) * %s;' % (v, '0x100000001b3UL' if lang == 'd' else '0x100000001b3ULL'))
            return
        for f, ft, n in self.structs[t].fields:
            if n:
                for i in range(n):
                    self.hash_stmts(ft, '%s.%s[%d]' % (expr, f, i), lang, out, ind)
            else:
                self.hash_stmts(ft, '%s.%s' % (expr, f), lang, out, ind)

    def build_stmts(self, t, dest, lang, out, ind, k=0):
        """Statements setting dest of type t from the hash h, as from_hash does"""
        if t in SCALARS:
            ct, nbits, signed = SCALARS[t]
            sh = k * 5 % 48
            if lang == 'd':
                x = '(h >> %d)' % sh
                if t == 'bool':
                    e = '(%s & 1) != 0' % x
                elif signed is None:
                    e = 'cast(%s)(cast(long)(%s & 0xFFFF) - 0x8000) / 4' % (t, x)
                else:
                    e = 'cast(%s)%s' % (t, x)
            else:
                x = '(h >> %d)' % sh
                if t == 'bool':
                    e = '(%s & 1) != 0' % x
                elif signed is None:
                    e = '(%s)((long long)(%s & 0xFFFF) - 0x8000) / 4' % (ct, x)
                else:
                    e = '(%s)%s' % (ct, x)
            out.append(ind + '%s = %s;' % (dest, e))
            return k + 1
        for f, ft, n in self.structs[t].fields:
            if n:
                for i in range(n):
                    k = self.build_stmts(ft, '%s.%s[%d]' % (dest, f, i), lang, out, ind, k)
            else:
                k = self.build_stmts(ft, '%s.%s' % (dest, f), lang, out, ind, k)
        return k

    def program(self, outdir):
        r = self.r
        nf = r.randint(6, 12)
        funcs = []
        for i in range(nf):
            n = r.choice([r.randint(1, 4), r.randint(4, 10), r.randint(8, 18)])
            params = [self.ptype() for _ in range(n)]
            ret = r.choice(['void', self.ptype(), self.ptype()])
            funcs.append((params, ret))
        # variadic: fixed int count, then variadic arguments of the promoted types
        vfuncs = []
        for i in range(r.randint(1, 3)):
            nfixed = r.randint(0, 9)
            fixed = [r.choice(['int', 'long', 'double']) for _ in range(nfixed)]
            var = [r.choice(['int', 'long', 'double', 'uint', 'ulong']) for _ in range(r.randint(1, 12))]
            vfuncs.append((fixed, var))

        # struct declarations, in order of definition (nested ones come first)
        dstructs, cstructs = [], []
        for s in self.structs.values():
            dstructs.append('struct %s { %s }' % (s.name, ' '.join(
                '%s%s %s;' % (ft, '[%d]' % n if n else '', f) for f, ft, n in s.fields)))
            cstructs.append('typedef struct %s { %s } %s;' % (s.name, ' '.join(
                '%s %s%s;' % (self.ctype(ft), f, '[%d]' % n if n else '') for f, ft, n in s.fields), s.name))

        cd = ['// generated by abifuzz.py, seed %d' % self.seed, 'module callee;',
              'import core.stdc.stdarg;'] + dstructs
        cd.append('extern (C) __gshared ulong fz_last;')
        cc = ['// generated by abifuzz.py, seed %d' % self.seed, '#include <stdarg.h>'] + cstructs
        cc.append('unsigned long long fz_last_c;')
        dm = ['// generated by abifuzz.py, seed %d' % self.seed, 'module caller;',
              'import callee;', 'import core.stdc.stdio;']
        dm.append('extern (C) extern __gshared ulong fz_last_c;')
        cm = ['// generated by abifuzz.py, seed %d' % self.seed, '#include <stdio.h>'] + cstructs
        cm.append('extern unsigned long long fz_last;')
        dmain, cmain, expect_d, expect_c = [], [], [], []

        for i, (params, ret) in enumerate(funcs):
            plist_d = ', '.join('%s a%d' % (t, j) for j, t in enumerate(params))
            plist_c = ', '.join('%s a%d' % (self.ctype(t), j) for j, t in enumerate(params))
            for lang, name, linkage in (('d', 'f%d_d' % i, 'extern (D)'), ('d', 'f%d_c' % i, 'extern (C)'),
                                        ('c', 'f%d_cc' % i, None)):
                body = []
                if lang == 'd':
                    body.append('%s %s %s(%s)' % (linkage, ret, name, plist_d))
                    body.append('{')
                    body.append('    ulong h = 0x%xUL;' % H0)
                else:
                    body.append('%s %s(%s)' % (self.ctype(ret), name, plist_c or 'void'))
                    body.append('{')
                    body.append('    unsigned long long h = 0x%xULL;' % H0)
                for j, t in enumerate(params):
                    self.hash_stmts(t, 'a%d' % j, lang, body, '    ')
                body.append('    fz_last%s = h;' % ('' if lang == 'd' else '_c'))
                if ret != 'void':
                    body.append(('    %s r = void;' if lang == 'd' else '    %s r;') % (ret if lang == 'd' else self.ctype(ret)))
                    self.build_stmts(ret, 'r', lang, body, '    ')
                    body.append('    return r;')
                body.append('}')
                if lang == 'd':
                    cd.extend(body)
                else:
                    cc.extend(body)
            # the prototypes the callers see of the C functions
            dm.append('extern (C) %s f%d_cc(%s);' % (ret, i, plist_d))
            cm.append('extern %s f%d_c(%s);' % (self.ctype(ret), i, plist_c or 'void'))

            vals = [self.value(t) for t in params]
            h = H0
            for t, v in zip(params, vals):
                for b in self.bits(t, v):
                    h = mix(h, b)
            rh = 0
            if ret != 'void':
                rv, _ = self.from_hash(ret, h)
                rh = H0
                for b in self.bits(ret, rv):
                    rh = mix(rh, b)
            dargs = ', '.join(self.dlit(t, v) for t, v in zip(params, vals))
            cargs = ', '.join(self.clit(t, v) for t, v in zip(params, vals))
            for suffix, last in (('d', 'fz_last'), ('c', 'fz_last'), ('cc', 'fz_last_c')):
                if ret == 'void':
                    dmain.append('    f%d_%s(%s);' % (i, suffix, dargs))
                    dmain.append('    printf("f%d_%s %%016llx 0\\n", %s);' % (i, suffix, last))
                else:
                    dmain.append('    {')
                    dmain.append('        auto r = f%d_%s(%s);' % (i, suffix, dargs))
                    dmain.append('        ulong h = 0x%xUL;' % H0)
                    self.hash_stmts(ret, 'r', 'd', dmain, '        ')
                    dmain.append('        printf("f%d_%s %%016llx %%016llx\\n", %s, h);' % (i, suffix, last))
                    dmain.append('    }')
                expect_d.append('f%d_%s %016x %016x' % (i, suffix, h, rh) if ret != 'void'
                                else 'f%d_%s %016x 0' % (i, suffix, h))
            if ret == 'void':
                cmain.append('    f%d_c(%s);' % (i, cargs))
                cmain.append('    printf("f%d_c %%016llx 0\\n", fz_last);' % i)
            else:
                cmain.append('    {')
                cmain.append('        %s r = f%d_c(%s);' % (self.ctype(ret), i, cargs))
                cmain.append('        unsigned long long h = 0x%xULL;' % H0)
                self.hash_stmts(ret, 'r', 'c', cmain, '        ')
                cmain.append('        printf("f%d_c %%016llx %%016llx\\n", fz_last, h);' % i)
                cmain.append('    }')
            expect_c.append('f%d_c %016x %016x' % (i, h, rh) if ret != 'void' else 'f%d_c %016x 0' % (i, h))

        for i, (fixed, var) in enumerate(vfuncs):
            pl_d = ', '.join(['%s a%d' % (t, j) for j, t in enumerate(fixed)] + ['int n', '...'])
            pl_c = ', '.join(['%s a%d' % (self.ctype(t), j) for j, t in enumerate(fixed)] + ['int n', '...'])
            for lang, name in (('d', 'v%d_c' % i), ('c', 'v%d_cc' % i)):
                body = []
                if lang == 'd':
                    body.append('extern (C) ulong %s(%s)' % (name, pl_d))
                    body.append('{')
                    body.append('    ulong h = 0x%xUL;' % H0)
                else:
                    body.append('unsigned long long %s(%s)' % (name, pl_c))
                    body.append('{')
                    body.append('    unsigned long long h = 0x%xULL;' % H0)
                for j, t in enumerate(fixed):
                    self.hash_stmts(t, 'a%d' % j, lang, body, '    ')
                body.append('    va_list ap;')
                body.append('    va_start(ap, n);')
                for j, t in enumerate(var):
                    if lang == 'd':
                        body.append('    %s x%d = va_arg!%s(ap);' % (t, j, t))
                    else:
                        body.append('    %s x%d = va_arg(ap, %s);' % (self.ctype(t), j, self.ctype(t)))
                    self.hash_stmts(t, 'x%d' % j, lang, body, '    ')
                body.append('    va_end(ap);')
                body.append('    return h;')
                body.append('}')
                (cd if lang == 'd' else cc).extend(body)
            dm.append('extern (C) ulong v%d_cc(%s);' % (i, pl_d))
            cm.append('extern unsigned long long v%d_c(%s);' % (i, pl_c))
            fv = [self.value(t) for t in fixed]
            vv = [self.value(t) for t in var]
            h = H0
            for t, v in list(zip(fixed, fv)) + list(zip(var, vv)):
                for b in self.bits(t, v):
                    h = mix(h, b)
            dargs = ', '.join([self.dlit(t, v) for t, v in zip(fixed, fv)] + [str(len(var))] +
                              [self.dlit(t, v) for t, v in zip(var, vv)])
            cargs = ', '.join([self.clit(t, v) for t, v in zip(fixed, fv)] + [str(len(var))] +
                              [self.clit(t, v) for t, v in zip(var, vv)])
            for suffix in ('c', 'cc'):
                dmain.append('    printf("v%d_%s %%016llx\\n", v%d_%s(%s));' % (i, suffix, i, suffix, dargs))
                expect_d.append('v%d_%s %016x' % (i, suffix, h))
            cmain.append('    printf("v%d_c %%016llx\\n", v%d_c(%s));' % (i, i, cargs))
            expect_c.append('v%d_c %016x' % (i, h))

        dm.append('extern (C) int main()')
        dm.append('{')
        dm.extend(dmain)
        dm.append('    return 0;')
        dm.append('}')
        cm.append('int main(void)')
        cm.append('{')
        cm.extend(cmain)
        cm.append('    return 0;')
        cm.append('}')
        os.makedirs(outdir, exist_ok=True)
        for fn, lines in (('callee.d', cd), ('callee.c', cc), ('caller.d', dm), ('caller.c', cm),
                          ('expect_d.txt', expect_d), ('expect_c.txt', expect_c)):
            with open(os.path.join(outdir, fn), 'w') as f:
                f.write('\n'.join(lines) + '\n')


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    Gen(int(sys.argv[1])).program(sys.argv[2])


if __name__ == '__main__':
    main()
