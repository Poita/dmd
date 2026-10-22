/**
 * Removal of conditions that relations known to hold make redundant.
 *
 * A forward data flow analysis finds, at each point of the function, which
 * relations hold between local integer values: an equality from each
 * assignment of a value to a local, and an ordering from each conditional
 * branch taken and each check that ends in a function that never returns,
 * such as the array bounds checks and asserts. A condition that these
 * relations prove always true or always false is replaced with that constant,
 * so its branch, and the never returning call it guards, go away.
 *
 * The values are constants, locals whose address is never taken and which
 * nested functions do not refer to, parts of such locals (the length of a
 * slice), the zero or sign extension of one, and one plus or minus a constant.
 * As nothing but a direct assignment can change such a local, a relation holds
 * until one of the locals it is about is assigned. Each relation is used only
 * as the exact modular comparison it was found to be, so no reasoning depends
 * on a value not wrapping around.
 *
 * Copyright:   Copyright (C) 2026 by The D Language Foundation, All Rights Reserved
 * License:     $(LINK2 https://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 * Source:      $(LINK2 https://github.com/dlang/dmd/blob/master/compiler/src/dmd/backend/grange.d, backend/grange.d)
 */

module dmd.backend.grange;

import core.stdc.stdio;

import dmd.backend.barray;
import dmd.backend.blockopt : BlockOpt, compdfo;
import dmd.backend.cc;
import dmd.backend.cdef;
import dmd.backend.dvec;
import dmd.backend.el;
import dmd.backend.go : GlobalOptimizer;
import dmd.backend.oper;
import dmd.backend.symbol : Symbol, globsym;
import dmd.backend.ty;

nothrow:
@safe:

private:

/// A value: the constant `c`, or the local `s` read at `off` with `vsize`
/// bytes, extended per `ext` to `size` bytes, plus `c` modulo 2 ^ (8 * size)
struct Term
{
    Symbol* s;
    uint off;
    ubyte vsize;
    ubyte size;
    ubyte ext;          // 0: none, 'u': zero extension, 's': sign extension
    ulong c;
}

/// Kinds of relation, the unsigned and signed orderings of `a` before `b`
enum Rel : ubyte { eq, ltu, leu, lts, les }

struct Fact
{
    Rel rel;
    Term a, b;
}

ulong truncate(ulong v, uint size)
{
    return size >= 8 ? v : v & ((1UL << (size * 8)) - 1);
}

long signExtend(ulong v, uint size)
{
    if (size >= 8)
        return cast(long)v;
    const shift = 64 - size * 8;
    return cast(long)(v << shift) >> shift;
}

/// Whether the analysis can follow every change to the value of local `s`
@trusted
bool tracked(const Symbol* s)
{
    if (s.Ssymnum >= globsym.length || globsym[s.Ssymnum] !is s)
        return false;
    if (!(s.Sflags & SFLdistinct) || s.ty() & (mTYvolatile | mTYshared))
        return false;
    switch (s.Sclass)
    {
        case SC.auto_, SC.register, SC.parameter, SC.regpar, SC.fastpar, SC.shadowreg, SC.bprel:
            return true;
        default:
            return false;
    }
}

bool integral(tym_t ty)
{
    const t = tybasic(ty);
    if (!tyintegral(t) && t != TYbool)
        return false;
    const sz = tysize(t);
    return sz == 1 || sz == 2 || sz == 4 || sz == 8;
}

/// The value `e` computes without side effects, if it is one of those described above
@trusted
bool toTerm(const(elem)* e, out Term t)
{
    switch (e.Eoper)
    {
        case OPconst:
            if (!integral(e.Ety))
                return false;
            t.size = cast(ubyte)tysize(e.Ety);
            t.c = truncate(e.Vullong, t.size);
            return true;

        case OPvar:
            if (!integral(e.Ety) || !tracked(e.Vsym) || e.Ety & mTYvolatile)
                return false;
            t.s = cast(Symbol*)e.Vsym;
            t.off = cast(uint)e.Voffset;
            t.vsize = t.size = cast(ubyte)tysize(e.Ety);
            return true;

        case OP128_64:
            // the length of a slice
            if (e.E1.Eoper != OPvar || tysize(e.E1.Ety) != 16 || !tracked(e.E1.Vsym) || e.E1.Ety & mTYvolatile)
                return false;
            t.s = cast(Symbol*)e.E1.Vsym;
            t.off = cast(uint)e.E1.Voffset;
            t.vsize = t.size = 8;
            return true;

        case OPu8_16, OPs8_16, OPu16_32, OPs16_32, OPu32_64, OPs32_64:
            if (!integral(e.Ety) || !toTerm(e.E1, t) || !t.s || t.ext || t.c || t.size != t.vsize)
                return false;
            if (tysize(e.Ety) != 2 * t.size)
                return false;
            t.size = cast(ubyte)tysize(e.Ety);
            t.ext = (e.Eoper == OPs8_16 || e.Eoper == OPs16_32 || e.Eoper == OPs32_64) ? 's' : 'u';
            return true;

        case OPadd, OPmin:
            if (!integral(e.Ety) || e.E2.Eoper != OPconst || !toTerm(e.E1, t) || !t.s || t.c)
                return false;
            if (tysize(e.Ety) != t.size || tysize(e.E2.Ety) != t.size)
                return false;
            const k = e.E2.Vullong;
            t.c = truncate(e.Eoper == OPadd ? k : -k, t.size);
            return true;

        default:
            return false;
    }
}

/// The relations that hold where condition `e` is true (`[0]`) and where it is false (`[1]`)
@trusted
int toFacts(const(elem)* e, ref Fact[2] f, ref bool[2] has)
{
    has[] = false;
    bool neg;
    while (e.Eoper == OPnot)
    {
        neg = !neg;
        e = e.E1;
    }
    Term a, b;
    OPER op;
    if (OTrel(e.Eoper) && e.Eoper <= OPne)
    {
        if (!integral(e.E1.Ety) || tysize(e.E1.Ety) != tysize(e.E2.Ety) ||
            !toTerm(e.E1, a) || !toTerm(e.E2, b) || a.size != b.size)
            return 0;
        op = e.Eoper;
    }
    else if (toTerm(e, a) && a.s)
    {
        // a value as a condition is its comparison with 0
        b = Term.init;
        b.size = a.size;
        op = OPne;
    }
    else
        return 0;
    // a comparison is unsigned when either operand is, as in (x >= 1u)
    const uns = OTrel(e.Eoper) ? (tyuns(e.E1.Ety) || tyuns(e.E2.Ety)) : tyuns(e.Ety) != 0;
    const lt = uns ? Rel.ltu : Rel.lts;
    const le = uns ? Rel.leu : Rel.les;
    void set(int i, Rel r, ref Term x, ref Term y)
    {
        f[i ^ neg] = Fact(r, x, y);
        has[i ^ neg] = true;
    }
    switch (op)
    {
        case OPlt: set(0, lt, a, b); set(1, le, b, a); break;
        case OPle: set(0, le, a, b); set(1, lt, b, a); break;
        case OPgt: set(0, lt, b, a); set(1, le, a, b); break;
        case OPge: set(0, le, b, a); set(1, lt, a, b); break;
        case OPeqeq:
        case OPne:
        {
            const i = op == OPeqeq ? 0 : 1;
            set(i, Rel.eq, a, b);
            // an unsigned value that is not 0 is above it
            Term zero;
            zero.size = a.size;
            if (uns && !b.s && b.c == 0)
                set(i ^ 1, Rel.ltu, zero, a);
            else if (uns && !a.s && a.c == 0)
                set(i ^ 1, Rel.ltu, zero, b);
            break;
        }
        default:
            break;
    }
    return has[0] + has[1];
}

/// A check `cond || f()` with `f` never returning, whose `cond` holds after it
@trusted
bool isCheck(const(elem)* e)
{
    return e.Eoper == OPoror && e.E2.Eoper == OPcall && e.E2.E1.Eoper == OPvar &&
           e.E2.E1.Vsym.Sflags & SFLexit;
}

struct RangeOpt
{
nothrow:
    Barray!Fact facts;
    Barray!(Barray!uint) bySym;     // for each local, the facts that mention it
    Barray!vec_t inState;           // for each block of bo.dfo[], the facts at its start
    vec_t all;
    uint changes;

    Barray!uint slots;              // a hash table of the facts: index + 1, 0 for none

    static size_t hashOf(ref const Term t)
    {
        size_t h = t.s ? t.s.Ssymnum + 1 : 0;
        h = h * 31 + t.off;
        h = h * 31 + (t.vsize | t.size << 8 | t.ext << 16);
        return h * 31 + cast(size_t)t.c;
    }

    static size_t hashOf(ref const Fact f)
    {
        const h = (hashOf(f.a) * 131 + hashOf(f.b)) * 7 + f.rel;
        return (h * 0x9E3779B97F4A7C15UL) >> 32;
    }

    /* Index the facts in `slots`, at most half full
     */
    @trusted
    void index()
    {
        size_t size = 16;
        while (size < 2 * facts.length + 2)
            size *= 2;
        slots.setLength(size);
        slots[][] = 0;
        foreach (i, ref f; facts[])
        {
            size_t k = hashOf(f) & (size - 1);
            while (slots[k])
                k = (k + 1) & (size - 1);
            slots[k] = cast(uint)i + 1;
        }
    }

    @trusted
    int find(ref const Fact f)
    {
        if (!slots.length)
            return -1;
        const mask = slots.length - 1;
        for (size_t k = hashOf(f) & mask; slots[k]; k = (k + 1) & mask)
            if (facts[slots[k] - 1] == f)
                return slots[k] - 1;
        return -1;
    }

    @trusted
    void add(ref Fact f)
    {
        if (find(f) >= 0)
            return;
        if (f.rel == Rel.eq && f.a.s is null && f.b.s is null)
            return;
        facts.push(f);
        if (2 * facts.length + 2 > slots.length)
            index();
        else
        {
            const mask = slots.length - 1;
            size_t k = hashOf(f) & mask;
            while (slots[k])
                k = (k + 1) & mask;
            slots[k] = cast(uint)facts.length;
        }
    }

    /* Collect the facts the function can use
     */
    @trusted
    void collect(ref BlockOpt bo)
    {
        void walkStmt(elem* e)
        {
            while (1)
            {
                if (e.Eoper == OPeq && e.E1.Eoper == OPvar)
                {
                    Term a, b;
                    if (toTerm(e.E1, a) && toTerm(e.E2, b) && a.size == b.size && !mentions(b, a.s))
                    {
                        Fact f = Fact(Rel.eq, a, b);
                        add(f);
                    }
                }
                else if (isCheck(e))
                {
                    Fact[2] f;
                    bool[2] has;
                    if (toFacts(e.E1, f, has) && has[0])
                        add(f[0]);
                }
                if (OTbinary(e.Eoper))
                {
                    walkStmt(e.E1);
                    e = e.E2;
                }
                else if (OTunary(e.Eoper))
                    e = e.E1;
                else
                    return;
            }
        }

        foreach (b; bo.dfo[])
        {
            if (!b.Belem)
                continue;
            walkStmt(b.Belem);
            if (b.bc == BC.iftrue)
            {
                Fact[2] f;
                bool[2] has;
                if (toFacts(*el_scancommas(&b.Belem), f, has))
                {
                    if (has[0]) add(f[0]);
                    if (has[1]) add(f[1]);
                }
            }
        }
    }

    /* Keep only the equalities that connect, perhaps through others, to a
     * local an ordering is about, as the others prove nothing
     */
    @trusted
    void relevant()
    {
        Barray!bool used;
        scope (exit) used.dtor();
        used.setLength(globsym.length);
        used[][] = false;
        foreach (ref f; facts[])
            if (f.rel != Rel.eq)
            {
                if (f.a.s) used[f.a.s.Ssymnum] = true;
                if (f.b.s) used[f.b.s.Ssymnum] = true;
            }
        bool more = true;
        while (more)
        {
            more = false;
            foreach (ref f; facts[])
                if (f.rel == Rel.eq)
                {
                    const ua = f.a.s && used[f.a.s.Ssymnum];
                    const ub = f.b.s && used[f.b.s.Ssymnum];
                    if (ua != ub && (ua ? f.b.s : f.a.s))
                    {
                        used[(ua ? f.b.s : f.a.s).Ssymnum] = true;
                        more = true;
                    }
                }
        }
        size_t n;
        foreach (ref f; facts[])
            if (f.rel != Rel.eq || (f.a.s && used[f.a.s.Ssymnum]) || (f.b.s && used[f.b.s.Ssymnum]))
                facts[n++] = f;
        facts.setLength(n);
        index();
    }

    static bool mentions(ref const Term t, const Symbol* s)
    {
        return t.s is s;
    }

    @trusted
    void kill(vec_t v, const Symbol* s)
    {
        if (s.Ssymnum >= bySym.length || globsym[s.Ssymnum] !is s)
            return;
        foreach (i; bySym[s.Ssymnum][])
            vec_clearbit(i, v);
    }

    /* Clear in `v` the facts that the assignments in `e` falsify
     */
    @trusted
    void killIn(vec_t v, elem* e)
    {
        while (1)
        {
            if (OTassign(e.Eoper) && e.E1.Eoper == OPvar)
                kill(v, e.E1.Vsym);
            if (e.Eoper == OPasm)
            {
                vec_clear(v);
                return;
            }
            if (OTbinary(e.Eoper))
            {
                killIn(v, e.E2);
                e = e.E1;
            }
            else if (OTunary(e.Eoper))
                e = e.E1;
            else
                return;
        }
    }

    /* Whether the facts in `v` prove `want` true
     */
    @trusted
    bool prove(const vec_t v, ref const Fact want)
    {
        if (want.rel == Rel.eq)
            return equal(v, want.a, want.b);
        const uns = want.rel == Rel.ltu || want.rel == Rel.leu;
        const strict = want.rel == Rel.ltu || want.rel == Rel.lts;
        if (!strict && equal(v, want.a, want.b))
            return true;

        /* Search for a chain of orderings from want.a to want.b, through
         * equal values, with at least one strict ordering when want is strict
         */
        Barray!Term terms;          // the values reached, with whether strictly
        Barray!bool strictTo;
        scope (exit) { terms.dtor(); strictTo.dtor(); }
        terms.push(cast(Term)want.a);
        strictTo.push(false);
        for (size_t k = 0; k < terms.length; ++k)
        {
            Term x = terms[k];
            const sx = strictTo[k];
            if (equal(v, x, want.b) && (sx || !strict))
                return true;
            if (!x.s && !want.b.s)
            {
                // two constants
                const lt = uns ? x.c < want.b.c : signExtend(x.c, x.size) < signExtend(want.b.c, x.size);
                if (lt || (!strict || sx) && x.c == want.b.c)
                    return true;
            }
            foreach (i, ref f; facts[])
            {
                if (!vec_testbit(i, v))
                    continue;
                bool step;
                if (f.rel == (uns ? Rel.ltu : Rel.lts))
                    step = true;
                else if (f.rel != (uns ? Rel.leu : Rel.les))
                    continue;
                if (f.a.size != x.size)
                    continue;
                bool below;     // whether x is a constant below the constant f.a
                if (!x.s && !f.a.s && x.c != f.a.c)
                {
                    below = uns ? x.c < f.a.c : signExtend(x.c, x.size) < signExtend(f.a.c, x.size);
                    if (!below)
                        continue;
                }
                else if (!equal(v, f.a, x))
                    continue;
                // f.b is above x
                const s = sx || step || below;
                bool seen;
                foreach (j, ref t; terms[])
                    if (t == f.b && (strictTo[j] || !s))
                    {
                        seen = true;
                        break;
                    }
                if (!seen)
                {
                    terms.push(f.b);
                    strictTo.push(s);
                }
            }
            if (terms.length > 64)
                break;
        }
        return false;
    }

    /* Whether the facts in `v` prove `a` and `b` equal
     */
    @trusted
    bool equal(const vec_t v, ref const Term a, ref const Term b)
    {
        if (a == b)
            return true;
        // a breadth first search through the equalities
        Barray!Term seen;
        scope (exit) seen.dtor();
        seen.push(cast(Term)a);
        for (size_t k = 0; k < seen.length && seen.length <= 64; ++k)
        {
            Term x = seen[k];
            foreach (i, ref f; facts[])
            {
                if (f.rel != Rel.eq || !vec_testbit(i, v))
                    continue;
                Term y;
                if (f.a == x)
                    y = f.b;
                else if (f.b == x)
                    y = f.a;
                else
                    continue;
                if (y == b)
                    return true;
                bool dup;
                foreach (ref t; seen[])
                    if (t == y)
                    {
                        dup = true;
                        break;
                    }
                if (!dup)
                    seen.push(y);
            }
        }
        return false;
    }

    /* Whether the facts in `v` prove condition `e` true (1), false (0), or neither (-1)
     */
    int decide(const vec_t v, const(elem)* e)
    {
        Fact[2] f;
        bool[2] has;
        if (!toFacts(e, f, has))
            return -1;
        if (has[0] && prove(v, f[0]))
            return 1;
        if (has[1] && prove(v, f[1]))
            return 0;
        return -1;
    }

    @trusted
    void gen(vec_t v, ref const Fact f)
    {
        const i = find(f);
        if (i >= 0)
            vec_setbit(i, v);
    }

    /* Apply to `v` the statement `e`, and when `rewrite`, replace the
     * conditions of the checks in it that `v` proves
     */
    @trusted
    void stmt(vec_t v, elem* e, bool rewrite)
    {
        while (e.Eoper == OPcomma)
        {
            stmt(v, e.E1, rewrite);
            e = e.E2;
        }
        if (e.Eoper == OPeq && e.E1.Eoper == OPvar)
        {
            stmt(v, e.E2, rewrite);
            kill(v, e.E1.Vsym);
            Term a, b;
            if (toTerm(e.E1, a) && toTerm(e.E2, b) && a.size == b.size && !mentions(b, a.s))
            {
                const f = Fact(Rel.eq, a, b);
                gen(v, f);
            }
            return;
        }
        if (isCheck(e))
        {
            Fact[2] f;
            bool[2] has;
            if (toFacts(e.E1, f, has) && has[0])
            {
                if (rewrite && decide(v, e.E1) == 1)
                {
                    el_free(e.E1);
                    e.E1 = el_long(TYint, 1);
                    ++changes;
                }
                gen(v, f[0]);
                return;
            }
        }
        if (!containsCheck(e))
        {
            killIn(v, e);
            return;
        }
        switch (e.Eoper)
        {
            case OPandand, OPoror, OPcond:
            {
                // E1 always, then the rest perhaps
                stmt(v, e.E1, rewrite);
                vec_t t = vec_clone(v);
                if (e.Eoper == OPcond && (e.E2.Eoper == OPcolon || e.E2.Eoper == OPcolon2))
                {
                    stmt(t, e.E2.E1, rewrite);
                    vec_copy(t, v);
                    stmt(t, e.E2.E2, rewrite);
                }
                else
                    stmt(t, e.E2, rewrite);
                vec_free(t);
                killIn(v, e.E2);
                return;
            }
            default:
                break;
        }
        if (OTunary(e.Eoper))
        {
            stmt(v, e.E1, rewrite);
            if (OTassign(e.Eoper) && e.E1.Eoper == OPvar)
                kill(v, e.E1.Vsym);
            return;
        }
        if (!OTbinary(e.Eoper))
            return;

        /* The operands are evaluated in an order not relied on: what each
         * one proves holds for the other only when evaluated before it, so
         * each starts from the facts that the other's assignments leave,
         * and the facts each ends with hold after both if the other does
         * not falsify them
         */
        vec_t k1 = vec_calloc(facts.length);
        vec_t k2 = vec_calloc(facts.length);
        vec_set(k1);
        vec_set(k2);
        killIn(k1, e.E1);
        killIn(k2, e.E2);
        vec_t v1 = vec_clone(v);
        vec_t v2 = vec_clone(v);
        vec_andass(v1, k2);
        vec_andass(v2, k1);
        stmt(v1, e.E1, rewrite);
        stmt(v2, e.E2, rewrite);
        vec_andass(v1, k2);
        vec_andass(v2, k1);
        vec_or(v, v1, v2);
        if (OTassign(e.Eoper) && e.E1.Eoper == OPvar)
            kill(v, e.E1.Vsym);
        vec_free(k1);
        vec_free(k2);
        vec_free(v1);
        vec_free(v2);
    }

    /* Compute in `v` the facts at the end of `b`, from those at its start,
     * when `rewrite` replacing the conditions they prove
     */
    @trusted
    void transfer(block* b, vec_t v, bool rewrite)
    {
        if (!b.Belem)
            return;
        stmt(v, b.Belem, rewrite);
        if (rewrite && b.bc == BC.iftrue)
        {
            elem** pc = el_scancommas(&b.Belem);
            const d = decide(v, *pc);
            if (d >= 0)
            {
                const ty = (*pc).Ety;
                el_free(*pc);
                *pc = el_long(integral(ty) ? ty : TYint, d);
                ++changes;
            }
        }
    }

    /* Whether nothing is known at the start of b
     */
    static bool unknownEntry(block* b, block* startblock)
    {
        if (b == startblock)
            return true;
        switch (b.bc)
        {
            case BC.catch_, BC.jcatch, BC.lpad, BC.except, BC.filter, BC.finally_:
                return true;
            default:
                break;
        }
        foreach (p; b.Bpred[])
            if (p.bc != BC.goto_ && p.bc != BC.iftrue && p.bc != BC.switch_)
                return true;
        return false;
    }

    @trusted
    void run(ref BlockOpt bo)
    {
        collect(bo);
        relevant();
        if (!facts.length || facts.length * bo.dfo.length > (1 << 24))
            return;

        bySym.setLength(globsym.length);
        foreach (ref a; bySym[])
            a = Barray!uint.init;
        foreach (i, ref f; facts[])
        {
            if (f.a.s)
                bySym[f.a.s.Ssymnum].push(cast(uint)i);
            if (f.b.s && f.b.s !is f.a.s)
                bySym[f.b.s.Ssymnum].push(cast(uint)i);
        }

        all = vec_calloc(facts.length);
        vec_set(all);
        inState.setLength(bo.dfo.length);
        foreach (i, b; bo.dfo[])
        {
            inState[i] = vec_calloc(facts.length);
            if (!unknownEntry(b, bo.startblock))
                vec_set(inState[i]);
        }

        vec_t tmp = vec_calloc(facts.length);
        vec_t edge = vec_calloc(facts.length);
        bool changed;
        do
        {
            changed = false;
            foreach (i, b; bo.dfo[])
            {
                vec_copy(tmp, inState[i]);
                transfer(b, tmp, false);
                Fact[2] f;
                bool[2] has;
                const cond = b.bc == BC.iftrue && toFacts(*el_scancommas(&b.Belem), f, has);
                foreach (n, s; b.Bsucc[])
                {
                    const j = s.Bdfoidx;
                    if (j >= bo.dfo.length || bo.dfo[j] !is s || unknownEntry(s, bo.startblock))
                        continue;
                    vec_copy(edge, tmp);
                    if (cond && n < 2 && b.Bsucc[0] !is b.Bsucc[1] && has[n])
                        gen(edge, f[n]);
                    // inState[j] &= edge
                    vec_t w = inState[j];
                    foreach (k; 0 .. vec_dim(w))
                    {
                        const x = w[k] & edge[k];
                        if (x != w[k])
                        {
                            w[k] = x;
                            changed = true;
                        }
                    }
                }
            }
        } while (changed);

        foreach (i, b; bo.dfo[])
            transfer(b, inState[i], true);

        vec_free(tmp);
        vec_free(edge);
    }

    @trusted
    void free()
    {
        foreach (v; inState[])
            vec_free(v);
        inState.dtor();
        foreach (ref a; bySym[])
            a.dtor();
        bySym.dtor();
        facts.dtor();
        slots.dtor();
        if (all)
            vec_free(all);
    }
}

public:

/**
 * Replace the conditions of the function that the relations known to hold
 * where they are evaluated prove always true or always false.
 * Params:
 *      go = the global optimizer, whose `changes` count the replacements
 *      bo = the blocks of the function
 */
@trusted
void rangeopt(ref GlobalOptimizer go, ref BlockOpt bo)
{
    import core.stdc.stdlib : getenv;
    // DMD_RANGEOPT=0 turns this off, DMD_RANGEOPT=log reports what it removes
    __gshared int mode = -1;
    if (mode < 0)
    {
        const env = getenv("DMD_RANGEOPT");
        mode = !env ? 1 : env[0] == '0' ? 0 : env[0] == 'l' ? 2 : env[0] == 'd' ? 3 : 1;
    }
    if (mode == 3)
    {
        import dmd.backend.debugprint : WRfunc;
        WRfunc("rangeopt", funcsym_p, bo.startblock);
    }
    if (!mode)
        return;
    // only worth it when there are checks to remove
    bool any;
    foreach (b; BlockRange(bo.startblock))
    {
        if (b.bc == BC.iftrue)
            foreach (s; b.Bsucc[])
                if (s.bc == BC.exit)
                    any = true;
        if (!any && b.Belem && containsCheck(b.Belem))
            any = true;
        if (any)
            break;
    }
    if (!any)
        return;

    compdfo(bo.dfo, bo.startblock);
    RangeOpt r;
    r.run(bo);
    if (mode == 2 && r.changes)
        fprintf(stderr, "rangeopt: %s %u\n", funcsym_p.Sident.ptr, r.changes);
    go.changes += r.changes;
    r.free();
}

/// Whether a check is anywhere in `e`
@trusted
bool containsCheck(const(elem)* e)
{
    while (1)
    {
        if (isCheck(e))
            return true;
        if (OTbinary(e.Eoper))
        {
            if (containsCheck(e.E2))
                return true;
            e = e.E1;
        }
        else if (OTunary(e.Eoper))
            e = e.E1;
        else
            return false;
    }
}
