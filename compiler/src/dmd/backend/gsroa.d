/**
 * SROA structured replacement of aggregate optimization
 *
 * This 'slices' a two register wide aggregate into two separate register-sized variables,
 * enabling much better enregistering.
 * SROA (Scalar Replacement Of Aggregates) is the common term for this.
 *
 * Compiler implementation of the
 * $(LINK2 https://www.dlang.org, D programming language).
 *
 * Copyright:   Copyright (C) 2016-2026 by The D Language Foundation, All Rights Reserved
 * Authors:     $(LINK2 https://www.digitalmars.com, Walter Bright)
 * License:     $(LINK2 https://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 * Source:      $(LINK2 https://github.com/dlang/dmd/blob/master/compiler/src/dmd/backend/gsroa.d, backend/gsroa.d)
 */

module dmd.backend.gsroa;

import core.stdc.stdio;
import core.stdc.stdlib;
import core.stdc.string;
import core.stdc.time;

import dmd.backend.cc;
import dmd.backend.cdef;
import dmd.backend.x86.code_x86 : isXMMreg;
import dmd.backend.oper;
import dmd.backend.global : REGSIZE, err_nomem;
import dmd.backend.debugprint : tym_str;
import dmd.backend.el;
import dmd.backend.symbol;
import dmd.backend.ty;
import dmd.backend.type;

import dmd.backend.dvec;


nothrow:
@safe:

private enum log = false;       // print logging info
private enum enable = true;     // enable SROA

alias SLICESIZE = REGSIZE;  // slices are all register-sized
enum MAXSLICES = 2;         // max # of pieces we can slice an aggregate into

struct SymInfo
{
    bool canSlice;
    bool accessSlice;   // if Symbol was accessed as a slice
    tym_t[MAXSLICES] ty; // type of each slice
    SYMIDX si0;          // index of first slice, the rest follow sequentially
}

/********************************
 * Gather information about slice-able variables by scanning e.
 * Params:
 *      symtab = symbol table
 *      e = expression to scan
 *      sia = where to put gathered information
 */
@trusted
private void sliceStructs_Gather(ref const symtab_t symtab, SymInfo[] sia, const(elem)* e)
{
    while (1)
    {
        switch (e.Eoper)
        {
            case OPvar:
            {
                const si = e.Vsym.Ssymnum;
                if (si != SYMIDX.max && sia[si].canSlice)
                {
                    assert(si < symtab.length);
                    const n = nthSlice(e);
                    const sz = getSize(e);
                    if (sz == 2 * SLICESIZE && !tyfv(e.Ety) &&
                        tybasic(e.Ety) != TYreal && tybasic(e.Ety) != TYireal)
                    {
                        // Rewritten as OPpair later
                    }
                    else if (n != NOTSLICE)
                    {
                        if (!sia[si].accessSlice)
                        {
                            /* [1] default as pointer type
                             */
                            foreach (ref ty; sia[si].ty)
                                ty = TYnptr;

                            const s = e.Vsym;
                            const t = s.Stype;
                            if (tybasic(t.Tty) == TYstruct)
                            {
                                if (t.Ttag.Sstruct.Sflags & STRbitfields)
                                {
                                    // Can get "used before set" errors from slicing this
                                    // Would be workable if the symbol was flagged instead of the type
                                    sia[si].canSlice = false;
                                    return;
                                }

                                if (const targ1 = t.Ttag.Sstruct.Sarg1type)
                                    if (const targ2 = t.Ttag.Sstruct.Sarg2type)
                                    {
                                        sia[si].ty[0] = targ1.Tty;
                                        sia[si].ty[1] = targ2.Tty;

                                        if (config.fpxmmregs &&
                                             tyxmmreg(targ1.Tty) && !tyxmmreg(targ2.Tty) ||
                                            !tyxmmreg(targ1.Tty) &&  tyxmmreg(targ2.Tty))

                                        {
                                            /* https://issues.dlang.org/show_bug.cgi?22438
                                             * disable till fixed
                                             */
                                            if (log) printf(" [%d] can't because xmmgpr or gprxmm\n", cast(int)si);
                                            sia[si].canSlice = false;
                                            return;
                                        }
                                    }
                            }
                            else if (tybasic(t.Tty) == TYarray)
                            {
                                // could be an array of floats, deal with this later
                                if (log) printf(" [%d] can't because array of floats\n", cast(int)si);
                                sia[si].canSlice = false;
                                return;
                            }
                        }
                        if (sz == SLICESIZE)
                        {
                            sia[si].ty[n] = tybasic(e.Ety);
                            if (SLICESIZE == 4 && config.fpxmmregs && tyxmmreg(e.Ety))
                            {
                                /* for 32 bits, OPstreq is converted to a TYllong.
                                 * It needs to be converted to cfloat, otherwise XMM
                                 * registers cannot be handled. This fails:
                                 *   struct F { float x, y; }
                                 *   void foo(F p1, ref F rfp) { rfp = F(p.x, p.y); }
                                 */
                                if (log) printf(" [%d] can't because 32 bit XMM\n", cast(int)si);
                                sia[si].canSlice = false;
                                return;
                            }
                            if (config.fpxmmregs && tyxmmreg(e.Ety) ||
                                config.target_cpu == TARGET_AArch64 && tyfloating(e.Ety))
                            {
                                /* Too many issues with mixing XMM with non-XMM
                                 * One problem is an OPpair with one operand a long, the other XMM.
                                 * Giving it up for now.
                                 */
                                if (log) printf(" [%d] can't because XMM\n", cast(int)si);
                                sia[si].canSlice = false;
                                return;
                            }
                        }
                        sia[si].accessSlice = true;
                    }
                    else
                    {
                        if (log) printf(" [%d] can't because NOTSLICE 1\n", cast(int)si);
                        sia[si].canSlice = false;
                    }
                }
                return;
            }

            default:
                if (OTassign(e.Eoper))
                {
                    if (OTbinary(e.Eoper))
                        sliceStructs_Gather(symtab, sia, e.E2);

                    // Assignment to a whole var will disallow SROA
                    if (e.E1.Eoper == OPvar)
                    {
                        const e1 = e.E1;
                        const si = e1.Vsym.Ssymnum;
                        if (si != SYMIDX.max && sia[si].canSlice)
                        {
                            assert(si < symtab.length);
                            if (nthSlice(e1) == NOTSLICE)
                            {
                                if (log)
                                {
                                    printf(" [%d] can't because NOTSLICE 2\n", cast(int)si);
                                    elem_print(e);
                                }
                                sia[si].canSlice = false;
                            }
                            // Disable SROA on OSX32 (because XMM registers?)
                            // https://issues.dlang.org/show_bug.cgi?id=15206
                            // https://github.com/dlang/dmd/pull/8034
                            else if (!(config.exe & EX_OSX))
                            {
                                sliceStructs_Gather(symtab, sia, e.E1);
                            }
                        }
                        return;
                    }
                    e = e.E1;
                    break;
                }
                if (OTunary(e.Eoper))
                {
                    e = e.E1;
                    break;
                }
                if (OTbinary(e.Eoper))
                {
                    sliceStructs_Gather(symtab, sia, e.E2);
                    e = e.E1;
                    break;
                }
                return;
        }
    }
}

/***********************************
 * Rewrite expression tree e based on info in sia[].
 * Params:
 *      symtab = symbol table
 *      sia = slicing info
 *      e = expression tree to rewrite in place
 */
@trusted
private void sliceStructs_Replace(ref symtab_t symtab, const SymInfo[] sia, elem* e)
{
    while (1)
    {
        switch (e.Eoper)
        {
            case OPvar:
            {
                Symbol* s = e.Vsym;
                const si = s.Ssymnum;
                //printf("e: %d %d\n", si, sia[si].canSlice);
                //elem_print(e);
                if (si != SYMIDX.max && sia[si].canSlice)
                {
                    const n = nthSlice(e);
                    if (getSize(e) == 2 * SLICESIZE)
                    {
                        if (log) { printf("slicing struct before "); elem_print(e); }
                        // Rewrite e as (si0 OPpair si0+1)
                        elem* e1 = el_calloc();
                        el_copy(e1, e);
                        e1.Ety = sia[si].ty[0];

                        elem* e2 = el_calloc();
                        el_copy(e2, e);
                        Symbol* s1 = symtab[sia[si].si0 + 1]; // +1 for second slice
                        e2.Ety = sia[si].ty[1];
                        e2.Vsym = s1;
                        e2.Voffset = 0;

                        e.Eoper = OPpair;
                        e.E1 = e1;
                        e.E2 = e2;

                        if (tycomplex(e.Ety))
                        {
                            /* Ensure complex OPpair operands are floating point types
                             * because [1] may have defaulted them to a pointer type.
                             * https://issues.dlang.org/show_bug.cgi?id=18936
                             */
                            tym_t tyop;
                            switch (tybasic(e.Ety))
                            {
                                case TYcfloat:   tyop = TYfloat;   break;
                                case TYcdouble:  tyop = TYdouble;  break;
                                case TYcreal: tyop = TYreal; break;
                                default:
                                    assert(0);
                            }
                            if (!tyfloating(e1.Ety))
                                e1.Ety = tyop;
                            if (!tyfloating(e2.Ety))
                                e2.Ety = tyop;
                        }
                        if (log) { printf("slicing struct after\n"); elem_print(e); }
                    }
                    else if (n == 0)  // the first slice of the symbol is the same as the original
                    {
                        if (log) { printf("slicing slice 0 "); elem_print(e); }
                    }
                    else // the nth slice
                    {
                        if (log) { printf("slicing slice %d ", n); elem_print(e); }
                        e.Vsym = symtab[sia[si].si0 + n];
                        e.Voffset -= n * SLICESIZE;
                        //printf("replaced with:\n");
                        //elem_print(e);
                    }
                }
                return;
            }

            case OPrelconst:
            {
                Symbol* s = e.Vsym;
                const si = s.Ssymnum;
                //printf("e: %d %d\n", si, sia[si].canSlice);
                //elem_print(e);
                if (si != SYMIDX.max && sia[si].canSlice)
                {
                    printf("shouldn't be slicing %s\n", s.Sident.ptr);
                    assert(0);
                }
                return;
            }

            default:
                if (OTunary(e.Eoper))
                {
                    e = e.E1;
                    break;
                }
                if (OTbinary(e.Eoper))
                {
                    sliceStructs_Replace(symtab, sia, e.E2);
                    e = e.E1;
                    break;
                }
                return;
        }
    }
}

@trusted
void sliceStructs(ref symtab_t symtab, block* startblock)
{
if (enable) // disable while we test the inliner
{
    if (log) printf("\n************ sliceStructs() %s *******************\n", funcsym_p.Sident.ptr);
    const sia_length = symtab.length;
    /* 3 is because it is used for two arrays, sia[] and sia2[].
     * sia2[] can grow to twice the size of sia[], as symbols can get split into two.
     */
    debug
        enum tmp_length = 3;
    else
        enum tmp_length = 6;
    SymInfo[tmp_length] tmp = void;

    import dmd.common.smallbuffer : SmallBuffer;
    auto sb = SmallBuffer!(SymInfo)(3 * sia_length, tmp[]);
    SymInfo* sip = sb.ptr;
    memset(sip, 0, 3 * sia_length * SymInfo.sizeof);
    SymInfo[] sia = sip[0 .. sia_length];
    SymInfo[] sia2 = sip[sia_length .. sia_length * 3];

    if (log) foreach (si; 0 .. symtab.length)
    {
        Symbol* s = symtab[si];
        printf("[%d]: %p %d %s %s\n", cast(int)si, s, cast(int)type_size(s.Stype), s.Sident.ptr, tym_str(s.Stype.Tty));
    }

    bool anySlice = false;
    foreach (si; 0 .. symtab.length)
    {
        Symbol* s = symtab[si];
        if (log) printf("slice1 [%d]: %s\n", cast(int)si, s.Sident.ptr);

        //if (strcmp(s.Sident.ptr, "__inlineretval3".ptr) == 0) { printf("can't\n"); sia[si].canSlice = false; continue; }
        if (!(s.Sflags & SFLdistinct))   // if somebody took the address of s
        {
            if (log) printf(" can't because SFLdistinct\n");
            sia[si].canSlice = false;
            continue;
        }

        const sz = type_size(s.Stype);
        if (sz != 2 * SLICESIZE ||
            tyvector(s.Stype.Tty) ||            // SIMD types
            tyfv(s.Stype.Tty) || tybasic(s.Stype.Tty) == TYhptr)    // because there is no TYseg
        {
            if (log) printf(" can't because size or pointer type\n");
            sia[si].canSlice = false;
            continue;
        }

        switch (s.Sclass)
        {
            case SC.fastpar:
            case SC.register:
            case SC.auto_:
            case SC.shadowreg:
            case SC.parameter:
                // AArch64 passes a sliceable parameter in two general registers
                if (config.target_cpu == TARGET_AArch64 &&
                    (s.Sclass == SC.fastpar || s.Sclass == SC.shadowreg) &&
                    (s.Spreg >= 32 || s.Spreg2 == NOREG || s.Spreg2 >= 32))
                {
                    if (log) printf(" can't because not in two general registers\n");
                    sia[si].canSlice = false;
                }
                // We can't slice whole XMM registers
                else if (tyxmmreg(s.Stype.Tty) &&
                    isXMMreg(s.Spreg) && s.Spreg2 == NOREG)
                {
                    if (log) printf(" can't because XMM reg\n");
                    sia[si].canSlice = false;
                }
                else if (sz == 2 * SLICESIZE &&
                         (tybasic(s.Stype.Tty) == TYdouble || tybasic(s.Stype.Tty) == TYidouble) &&
                         config.fpxmmregs)
                {
                    if (log) printf(" can't because XMM double\n");
                    sia[si].canSlice = false;
                }
                else
                {
                    anySlice = true;
                    sia[si].canSlice = true;
                    sia[si].accessSlice = false;
                }
                break;

            case SC.stack:
            case SC.pseudo:
            case SC.static_:
            case SC.bprel:
                if (log) printf(" can't because Sclass\n");
                sia[si].canSlice = false;
                break;

            default:
                symbol_print(*s);
                assert(0);
        }
    }

    if (!anySlice)
        return;

    foreach (b; BlockRange(startblock))
    {
        if (b.bc == BC.asm_)
            return;
        if (b.Belem)
            sliceStructs_Gather(symtab, sia, b.Belem);
    }

    {   // scope needed because of goto skipping declarations
        bool any = false;
        int n = 0;              // the number of symbols added
        foreach (si; 0 .. sia_length)
        {
            sia2[si + n].canSlice = false;
            if (sia[si].canSlice)
            {
                // If never did access it as a slice, don't slice
                if (!sia[si].accessSlice)
                {
                    if (log) printf(" can't slice %s because no accessSlice\n", symtab[si].Sident.ptr);
                    sia[si].canSlice = false;
                    continue;
                }

                /* Split slice-able symbol sold into two symbols,
                 * (sold,snew) in adjacent slots in the symbol table.
                 */
                Symbol* sold = symtab[si + n];

                const idlen = 2 + strlen(sold.Sident.ptr) + 2;
                char* id = cast(char*)malloc(idlen + 1);
                if (!id)
                    err_nomem();
                const len = snprintf(id, idlen + 1, "__%s_%d", sold.Sident.ptr, SLICESIZE);
                assert(len == idlen);
                if (log) printf("retyping slice symbol %s %s\n", sold.Sident.ptr, tym_str(sia[si].ty[0]));
                if (log) printf("creating slice symbol %s %s\n", id, tym_str(sia[si].ty[1]));
                Symbol* snew = symbol_calloc(id[0 .. idlen]);
                free(id);
                snew.Sclass = sold.Sclass;
                snew.Sfl = sold.Sfl;
                snew.Sflags = sold.Sflags;
                if (snew.Sclass == SC.fastpar || snew.Sclass == SC.shadowreg)
                {
                    snew.Spreg = sold.Spreg2;
                    snew.Spreg2 = NOREG;
                    sold.Spreg2 = NOREG;
                }
                type_free(sold.Stype);
                sold.Stype = type_fake(sia[si].ty[0]);
                sold.Stype.Tcount++;
                snew.Stype = type_fake(sia[si].ty[1]);
                snew.Stype.Tcount++;

                // insert snew into symtab[si + n + 1]
                symbol_insert(symtab, snew, si + n + 1);

                sia2[si + n].canSlice = true;
                sia2[si + n].si0 = si + n;
                sia2[si + n].ty[] = sia[si].ty[];
                ++n;
                any = true;
            }
        }
        if (!any)
            return;
    }

    foreach (si; 0 .. symtab.length)
    {
        Symbol* s = symtab[si];
        assert(s.Ssymnum == si);
    }

    foreach (b; BlockRange(startblock))
    {
        if (b.Belem)
            sliceStructs_Replace(symtab, sia2, b.Belem);
    }

    static if (0)
    {
        printf("after slicing:\n");
        foreach (b; BlockRange(startblock))
        {
            if (b.Belem)
                elem_print(b.Belem);
        }
        printf("after slicing done\n");
    }

}
}


/*************************************
 * Determine if `e` is a slice.
 * Params:
 *      e = elem that may be a slice
 * Returns:
 *      slice number if it is, NOTSLICE if not
 */
enum NOTSLICE = -1;
int nthSlice(const(elem)* e)
{
    const sz = tysize(e.Ety); // not getSize(e) because type_fake(TYstruct) doesn't work
    if (sz == -1)
        return NOTSLICE;
    const sliceSize = SLICESIZE;

    /* if sz is less than sliceSize, this causes problems because if, say,
     * sz is 4 while sliceSize is 8, and sz gets enregistered, then assigning to
     * the lower 4 bytes of sz will zero out the upper 4 bytes.
     * https://github.com/dlang/dmd/pull/13220
     */
    if (sz != sliceSize)
        return NOTSLICE;

    /* See if e fits in a slice
     */
    const lwr = e.Voffset;
    const upr = lwr + sz;
    if (0 <= lwr && upr <= sliceSize)
        return 0;
    if (sliceSize <= lwr && upr <= sliceSize * 2)
        return 1;

    return NOTSLICE;
}

/******************************************
 * Get size of an elem e.
 */
private int getSize(const(elem)* e)
{
    int sz = tysize(e.Ety);
    if (sz == -1 && e.ET && (tybasic(e.Ety) == TYstruct || tybasic(e.Ety) == TYarray))
        sz = cast(int)type_size(e.ET);
    return sz;
}

/***************************************
 * AArch64: split each local struct of 2 to 4 floats or 2 to 4 doubles, and
 * each 16 byte pair of integers or pointers such as a dynamic array, that is
 * mostly accessed an element at a time into a variable per element, so that
 * each element can be a register variable.
 * An assignment of the whole struct from or to another such struct, a
 * constant, or memory through a pointer becomes an assignment of each
 * element. Any other use of the whole struct goes through a copy in memory,
 * which is only worth it when element accesses are much more common.
 * Params:
 *      symtab = symbol table
 *      startblock = first block of the function
 */
@trusted
void sliceFloatStructs(ref symtab_t symtab, block* startblock)
{
    if (config.target_cpu != TARGET_AArch64)
        return;

    import dmd.backend.arm.cod1 : aarch64Aggregate, AggregateABI;

    static struct Info
    {
        bool can;       // the symbol can be split
        ubyte n;        // number of elements
        ubyte esz;      // size of each element
        bool isInt;     // the elements are integers or pointers, not floating point
        tym_t[4] ety;   // type of each element
        uint elems;     // number of element accesses
        uint wholes;    // number of accesses of the whole that go through memory
        bool assigned;  // assigned something other than a constant
        SYMIDX si0;     // index of the first element's symbol after splitting
        type* t;        // the struct type
        Symbol* tmp;    // the copy in memory for accesses of the whole
    }

    const len = symtab.length;
    Info* ip = cast(Info*)calloc(len ? len : 1, Info.sizeof);
    if (!ip)
        err_nomem();
    scope (exit) free(ip);
    Info[] info = ip[0 .. len];

    bool any = false;
    foreach (si; 0 .. len)
    {
        Symbol* s = symtab[si];
        /* A copy of a whole struct takes away SFLdistinct, so the address
         * being taken is checked below instead; a variable a nested function
         * refers to is volatile
         */
        if (s.ty() & (mTYvolatile | mTYshared))
            continue;
        // a parameter in V registers is split into a parameter per register
        const bool vparam = s.Sclass == SC.fastpar && s.Spreg >= 32 && s.Spreg != NOREG &&
                            s.Spreg2 == s.Spreg + 1;
        if (s.Sclass != SC.auto_ && s.Sclass != SC.register && !vparam)
            continue;
        type* t = s.Stype;
        const tyt = tybasic(t.Tty);
        if (!vparam && (tyt == TYdarray || tyt == TYdelegate ||
            tyt == TYstruct && type_size(t) == 16 && !(t.Ttag.Sstruct.Sflags & STRbitfields)))
        {
            // two integers or pointers of 8 bytes
            tym_t ty0 = tyt == TYdarray ? TYsize_t : TYnptr;
            tym_t ty1 = TYnptr;
            if (tyt == TYstruct)
            {
                const a1 = t.Ttag.Sstruct.Sarg1type;
                const a2 = t.Ttag.Sstruct.Sarg2type;
                if (!a1 || !a2 || type_size(a1) != 8 || type_size(a2) != 8 ||
                    tyfloating(a1.Tty) || tyfloating(a2.Tty) || tyaggregate(a1.Tty) || tyaggregate(a2.Tty))
                    continue;
                ty0 = tybasic(a1.Tty);
                ty1 = tybasic(a2.Tty);
            }
            info[si].can = true;
            info[si].n = 2;
            info[si].esz = 8;
            info[si].isInt = true;
            info[si].ety[0] = ty0;
            info[si].ety[1] = ty1;
            any = true;
            continue;
        }
        if (tyt != TYstruct || t.Ttag.Sstruct.Sflags & STRbitfields)
            continue;
        const a = aarch64Aggregate(t);
        if (a.kind != AggregateABI.Kind.hfa || a.nregs < 2 || a.nregs > 4 ||
            (a.esz != 4 && a.esz != 8) || a.size != a.nregs * a.esz)
            continue;
        info[si].can = true;
        info[si].n = a.nregs;
        info[si].esz = a.esz;
        any = true;
    }
    if (!any)
        return;

    static tym_t elemTy(const ref Info inf, uint k)
    {
        return inf.isInt ? inf.ety[k] : inf.esz == 4 ? TYfloat : TYdouble;
    }

    /* Whether e is an access of one element */
    static bool isElement(const(elem)* e, const ref Info inf)
    {
        if (e.Voffset % inf.esz || e.Voffset < 0 || e.Voffset >= inf.n * inf.esz)
            return false;
        const ty = tybasic(e.Ety);
        if (inf.isInt)
            return !tyfloating(ty) && !tyaggregate(ty) && tysize(ty) == 8;
        return ty == elemTy(inf, 0) || ty == (inf.esz == 4 ? TYifloat : TYidouble);
    }

    /* Whether e is an access of the whole */
    static bool isWhole(const(elem)* e, const ref Info inf)
    {
        if (e.Voffset || e.Ety & mTYvolatile)
            return false;
        const size = inf.n * inf.esz;
        return tybasic(e.Ety) == TYstruct ? e.ET && type_size(e.ET) == size
                                          : tysize(e.Ety) == size;
    }

    enum Form { none, copy, constant, load, store, pair, partial, result, storeVar }

    /* Whether x refers to symbol s */
    static bool refersTo(const(elem)* x, const(Symbol)* s)
    {
        while (1)
        {
            if (x.Eoper == OPvar || x.Eoper == OPrelconst)
                return x.Vsym is s;
            if (OTbinary(x.Eoper))
            {
                if (refersTo(x.E2, s))
                    return true;
                x = x.E1;
            }
            else if (OTunary(x.Eoper))
                x = x.E1;
            else
                return false;
        }
    }

    /* How an assignment e of a whole, whose value is not used, splits into
     * element assignments, given the Info of e.E1 and e.E2 if they are vars
     */
    /* The temporary of (tmp = value, tmp), or null
     */
    static Symbol* resultTemp(const(elem)* e2)
    {
        if (e2.Eoper == OPcomma && !e2.Ecount &&
            e2.E1.Eoper == OPeq && !e2.E1.Ecount && e2.E1.E1.Eoper == OPvar && !e2.E1.E1.Voffset &&
            e2.E2.Eoper == OPvar && !e2.E2.Ecount && e2.E2.Vsym is e2.E1.E1.Vsym && !e2.E2.Voffset &&
            !(e2.E2.Ety & mTYvolatile))
            return cast(Symbol*) e2.E2.Vsym;
        return null;
    }

    static Form assignForm(const(elem)* e, Info* inf1, Info* inf2, bool tmpUnsplit)
    {
        const(elem)* e1 = e.E1;
        const(elem)* e2 = e.E2;
        const whole1 = inf1 && isWhole(e1, *inf1);
        const whole2 = inf2 && isWhole(e2, *inf2);
        if (whole1 && whole2)
            return e1.Vsym !is e2.Vsym && inf1.n == inf2.n && inf1.esz == inf2.esz && inf1.isInt == inf2.isInt
                ? Form.copy : Form.none;
        /* The elements are assigned one at a time, so a value computed from
         * the variable itself has to go through memory
         */
        if (whole1 && refersTo(e2, e1.Vsym))
            return Form.none;
        if (whole1 && e2.Eoper == OPpair && !e2.Ecount && inf1.n == 2 &&
            tysize(e2.E1.Ety) == inf1.esz && tysize(e2.E2.Ety) == inf1.esz &&
            (tyfloating(e2.E1.Ety) != 0) == !inf1.isInt && (tyfloating(e2.E2.Ety) != 0) == !inf1.isInt)
            return Form.pair;
        if (whole1 && e2.Eoper == OPconst && e.Eoper == OPeq && (tysize(e2.Ety) == 8 || tysize(e2.Ety) == 16))
            return Form.constant;
        // a constant assigned to some whole elements, as part of an initialization
        if (inf1 && !whole1 && !isElement(e1, *inf1) && e2.Eoper == OPconst && e.Eoper == OPeq &&
            !tyfloating(e1.Ety) && e1.Voffset >= 0 && e1.Voffset % inf1.esz == 0 &&
            tysize(e1.Ety) >= inf1.esz && tysize(e1.Ety) <= 16 && tysize(e1.Ety) % inf1.esz == 0 &&
            e1.Voffset + tysize(e1.Ety) <= inf1.n * inf1.esz)
            return Form.partial;
        if (whole1 && e2.Eoper == OPind && !e2.Ecount && !(e2.Ety & mTYvolatile) && !el_sideeffect(e2.E1))
            return Form.load;
        // (tmp = value, tmp), as for a value a call returns, with tmp not split
        if (whole1 && !inf1.isInt && resultTemp(e2) && resultTemp(e2) !is e1.Vsym && tmpUnsplit &&
            type_size(resultTemp(e2).Stype) >= inf1.n * inf1.esz)
            return Form.result;
        if (whole2 && e1.Eoper == OPind && !e1.Ecount && !(e1.Ety & mTYvolatile) && !el_sideeffect(e1.E1))
            return Form.store;
        // stored whole into a variable that is not split
        if (whole2 && !inf1 && e1.Eoper == OPvar && !e1.Ecount && !(e1.Ety & mTYvolatile) && e1.Voffset >= 0 &&
            (tybasic(e1.Ety) == TYstruct ? e1.ET && type_size(e1.ET) == inf2.n * inf2.esz
                                         : tysize(e1.Ety) == inf2.n * inf2.esz))
            return Form.storeVar;
        return Form.none;
    }

    Info* candidate(const(elem)* e)
    {
        if (e.Eoper != OPvar)
            return null;
        const si = e.Vsym.Ssymnum;
        return si != SYMIDX.max && si < len && info[si].can ? &info[si] : null;
    }

    uint w = 1;         // weight of each access in the current block

    void gather(const(elem)* e, bool valueUsed) nothrow
    {
        void argument(const(elem)* x) nothrow
        {
            if (x.Eoper == OPvar)
                if (auto inf = candidate(x))
                    if (!inf.isInt && isWhole(x, *inf))
                    {
                        inf.elems += inf.n * w;
                        return;
                    }
            gather(x, true);
        }

        while (1)
        {
            switch (e.Eoper)
            {
                case OPvar:
                    if (auto inf = candidate(e))
                    {
                        if (isElement(e, *inf))
                            inf.elems += w;
                        else if (isWhole(e, *inf))
                        {
                            // read as a pair of the integer elements, or through the copy in memory
                            if (inf.isInt)
                                inf.elems += w;
                            else
                                inf.wholes += w;
                        }
                        else
                            inf.can = false;
                    }
                    return;

                case OPrelconst:
                {
                    // the address, unused at the end of an initialization, is not taken
                    if (!valueUsed)
                        return;
                    const si = e.Vsym.Ssymnum;
                    if (si != SYMIDX.max && si < len)
                        info[si].can = false;
                    return;
                }

                case OPaddr:
                    if (e.E1.Eoper == OPvar)
                    {
                        const si = e.E1.Vsym.Ssymnum;
                        if (si != SYMIDX.max && si < len)
                            info[si].can = false;
                    }
                    goto default;

                case OPcomma:
                    gather(e.E1, false);
                    e = e.E2;
                    continue;

                case OPparam:
                case OPcall:
                case OPucall:
                    /* A floating point struct passed as a whole is passed in
                     * registers loaded from its elements
                     */
                    if (e.Eoper == OPparam)
                        argument(e.E1);
                    if (e.Eoper != OPucall)
                        argument(e.E2);
                    if (e.Eoper == OPparam)
                        return;
                    e = e.E1;
                    valueUsed = true;
                    continue;

                case OPeq:
                case OPstreq:
                {
                    auto inf1 = candidate(e.E1);
                    auto inf2 = candidate(e.E2);
                    if (!valueUsed)
                    {
                        // the temporary of a value assigned to a split struct is not split itself
                        if (inf1 && !inf1.isInt && isWhole(e.E1, *inf1))
                            if (Symbol* tmp = resultTemp(e.E2))
                                if (tmp.Ssymnum != SYMIDX.max && tmp.Ssymnum < len)
                                    info[tmp.Ssymnum].can = false;
                        const form = assignForm(e, inf1, inf2, true);
                        if (inf1 && form != Form.constant && form != Form.none)
                            inf1.assigned = true;
                        final switch (form)
                        {
                            case Form.copy:     inf1.elems += inf1.n * w; inf2.elems += inf2.n * w; return;
                            case Form.constant: inf1.elems += inf1.n * w; return;
                            case Form.partial:  inf1.elems += tysize(e.E1.Ety) / inf1.esz * w; return;
                            case Form.load:     inf1.elems += inf1.n * w; gather(e.E2.E1, true); return;
                            case Form.store:    inf2.elems += inf2.n * w; gather(e.E1.E1, true); return;
                            case Form.pair:     inf1.elems += inf1.n * w; gather(e.E2.E1, true); gather(e.E2.E2, true); return;
                            case Form.result:   inf1.elems += inf1.n * w; gather(e.E2.E1, false); return;
                            case Form.storeVar: inf2.elems += inf2.n * w; return;
                            case Form.none:     break;
                        }
                        // a struct copy needs the address of a whole it copies
                        if (e.Eoper == OPstreq && inf2 && inf2.isInt && isWhole(e.E2, *inf2))
                            inf2.can = false;
                        if (inf1 && isWhole(e.E1, *inf1))
                        {
                            inf1.assigned = true;
                            inf1.wholes += w;      // written through the copy in memory
                            e = e.E2;
                            valueUsed = true;
                            continue;
                        }
                    }
                    if (inf1 && isElement(e.E1, *inf1) && e.E2.Eoper != OPconst)
                        inf1.assigned = true;
                    if (inf1 && !isElement(e.E1, *inf1))
                        inf1.can = false;
                    goto default;
                }

                default:
                    if (OTassign(e.Eoper) && e.Eoper != OPeq)
                    {
                        // an op= of the whole is not split
                        if (auto inf = candidate(e.E1))
                            if (!isElement(e.E1, *inf))
                                inf.can = false;
                    }
                    if (OTbinary(e.Eoper))
                    {
                        gather(e.E2, true);
                        e = e.E1;
                        valueUsed = true;
                        continue;
                    }
                    if (OTunary(e.Eoper))
                    {
                        e = e.E1;
                        valueUsed = true;
                        continue;
                    }
                    return;
            }
        }
    }

    static bool blockValueUsed(const block* b)
    {
        return !(b.bc == BC.goto_ || b.bc == BC.ret || b.bc == BC.exit);
    }

    /* Weight the accesses in each block by its loop nesting depth, found
     * from the back edges of the depth first order
     */
    import dmd.backend.blockopt : bo, compdfo;
    compdfo(bo.dfo, startblock);
    const nblocks = bo.dfo.length;
    uint* depth = cast(uint*)calloc(nblocks ? nblocks : 1, uint.sizeof);
    if (!depth)
        err_nomem();
    scope (exit) free(depth);
    foreach (b; bo.dfo[])
    {
        foreach (h; b.Bsucc[])
        {
            if (h.Bdfoidx <= b.Bdfoidx)
                foreach (i; h.Bdfoidx .. b.Bdfoidx + 1)
                    ++depth[i];
        }
    }

    foreach (b; BlockRange(startblock))
    {
        if (b.bc == BC.asm_)
            return;
        w = 1;
        if (b.Bdfoidx < nblocks && bo.dfo[b.Bdfoidx] is b)  // unreachable blocks are not in dfo[]
            foreach (d; 0 .. depth[b.Bdfoidx] < 3 ? depth[b.Bdfoidx] : 3)
                w *= 8;
        if (b.Belem)
            gather(b.Belem, blockValueUsed(b));
    }

    /* Split each chosen symbol into a symbol per element, the first keeping
     * the original symbol, the others inserted after it
     */
    int added = 0;
    foreach (si; 0 .. len)
    {
        Info* inf = &info[si];
        /* An integer pair only ever assigned constants, like a null array,
         * would only make what it points to a constant
         */
        if (!inf.can || !inf.elems || inf.elems < 2 * inf.wholes * inf.n || inf.isInt && !inf.assigned)
        {
            inf.can = false;
            continue;
        }
        Symbol* sold = symtab[si + added];
        inf.si0 = si + added;
        inf.t = sold.Stype;                     // keep the struct type for the copy in memory
        foreach (k; 1 .. inf.n)
        {
            const idlen = 2 + strlen(sold.Sident.ptr) + 2;
            char* id = cast(char*)malloc(idlen + 1);
            if (!id)
                err_nomem();
            const idl = snprintf(id, idlen + 1, "__%s_%d", sold.Sident.ptr, k);
            Symbol* snew = symbol_calloc(id[0 .. idl]);
            free(id);
            snew.Sclass = sold.Sclass;
            snew.Sfl = sold.Sfl;
            snew.Sflags = sold.Sflags | GTregcand | SFLdistinct;
            snew.Stype = type_fake(elemTy(*inf, k));
            snew.Stype.Tcount++;
            if (sold.Sclass == SC.fastpar)
            {
                snew.Spreg = cast(reg_t)(sold.Spreg + k);
                snew.Spreg2 = NOREG;
            }
            ++added;
            symbol_insert(symtab, snew, si + added);
        }
        sold.Stype = type_fake(elemTy(*inf, 0));
        sold.Stype.Tcount++;
        if (sold.Sclass == SC.fastpar)
        {
            sold.Spreg2 = NOREG;
            /* The back end inliner matches the arguments of a call to the
             * parameters, which no longer match the function's signature
             */
            funcsym_p.Sfunc.Fflags &= ~Finline;
        }
        sold.Sflags |= GTregcand | SFLdistinct;
    }
    if (!added)
        return;

    // the Info of each split symbol, by the symbol number of its first element
    const nsyms = symtab.length;
    Info** bp = cast(Info**)calloc(nsyms, (Info*).sizeof);
    if (!bp)
        err_nomem();
    scope (exit) free(bp);
    Info*[] byNum = bp[0 .. nsyms];
    foreach (ref inf; info)
        if (inf.can)
            byNum[inf.si0] = &inf;

    Info* splitInfo(const(elem)* e)
    {
        if (e.Eoper != OPvar)
            return null;
        const si = e.Vsym.Ssymnum;
        return si != SYMIDX.max && si < nsyms ? byNum[si] : null;
    }

    elem* elemVar(const ref Info inf, uint k)
    {
        return el_var(symtab[inf.si0 + k]);
    }

    /* The copy in memory of a split symbol, as an element */
    elem* tmpElem(ref Info inf, uint k)
    {
        if (!inf.tmp)
        {
            inf.tmp = symbol_genauto(inf.t);
            inf.tmp.Sfl = FL.auto_;
        }
        elem* e = el_var(inf.tmp);
        e.Ety = elemTy(inf, k);
        e.ET = null;
        e.Voffset = k * inf.esz;
        return e;
    }

    /* Chain the element assignments in a[] with commas, whose value and type,
     * including the struct type that says how it is passed, are the last one's
     */
    static elem* chain(elem*[] a)
    {
        elem* c = a[$ - 1];
        foreach_reverse (x; a[0 .. $ - 1])
        {
            elem* ec = el_bin(OPcomma, c.Ety, x, c);
            ec.ET = c.ET;
            c = ec;
        }
        return c;
    }

    /* Replace e in place by r */
    static void become(elem* e, elem* r)
    {
        el_copy(e, r);
        r.E1 = null;
        r.E2 = null;
        r.Eoper = OPconst;
        el_free(r);
    }

    void replace(elem* e, bool valueUsed)
    {
        while (1)
        {
            switch (e.Eoper)
            {
                case OPvar:
                    if (auto inf = splitInfo(e))
                    {
                        if (isElement(e, *inf))
                        {
                            const k = cast(uint)(e.Voffset / inf.esz);
                            e.Vsym = symtab[inf.si0 + k];
                            e.Voffset = 0;
                        }
                        else if (inf.isInt)
                        {
                            // (e.0 OPpair e.1)
                            elem* lo = elemVar(*inf, 0);
                            elem* hi = elemVar(*inf, 1);
                            e.Eoper = OPpair;
                            e.E1 = lo;
                            e.E2 = hi;
                        }
                        else
                        {
                            // (tmp.0 = e.0, ..., tmp)
                            elem*[5] a;
                            foreach (k; 0 .. inf.n)
                                a[k] = el_bin(OPeq, elemTy(*inf, k), tmpElem(*inf, k), elemVar(*inf, k));
                            elem* w = el_calloc();
                            el_copy(w, e);
                            w.Vsym = inf.tmp;
                            a[inf.n] = w;
                            become(e, chain(a[0 .. inf.n + 1]));
                        }
                    }
                    return;

                case OPrelconst:
                    // the unused address of a split symbol
                    if (!valueUsed && e.Vsym.Ssymnum != SYMIDX.max && e.Vsym.Ssymnum < nsyms && byNum[e.Vsym.Ssymnum])
                    {
                        e.Eoper = OPconst;
                        e.Vllong = 0;
                    }
                    return;

                case OPcomma:
                    replace(e.E1, false);
                    e = e.E2;
                    continue;

                case OPeq:
                case OPstreq:
                {
                    auto inf1 = splitInfo(e.E1);
                    auto inf2 = splitInfo(e.E2);
                    if (!valueUsed)
                    {
                        elem*[5] a;
                        Symbol* rtmp = resultTemp(e.E2);
                        const form = assignForm(e, inf1, inf2,
                            rtmp && !(rtmp.Ssymnum != SYMIDX.max && rtmp.Ssymnum < nsyms && byNum[rtmp.Ssymnum]));
                        if (form == Form.none)
                        {
                            if (inf1 && isWhole(e.E1, *inf1))
                            {
                                // (tmp = e2, (e.0 = tmp.0, ...))
                                replace(e.E2, true);
                                elem* w = el_calloc();
                                el_copy(w, e.E1);
                                if (!inf1.tmp)
                                {
                                    inf1.tmp = symbol_genauto(inf1.t);
                                    inf1.tmp.Sfl = FL.auto_;
                                }
                                w.Vsym = inf1.tmp;
                                elem* eqt = el_bin(e.Eoper, e.Ety, w, e.E2);
                                eqt.ET = e.ET;
                                e.E2 = null;
                                el_free(e.E1);
                                a[0] = eqt;
                                foreach (k; 0 .. inf1.n)
                                    a[k + 1] = el_bin(OPeq, elemTy(*inf1, k), elemVar(*inf1, k), tmpElem(*inf1, k));
                                become(e, chain(a[0 .. inf1.n + 1]));
                                return;
                            }
                            goto default;
                        }
                        uint nchain = 0;        // number of element assignments, if not all of them
                        final switch (form)
                        {
                            case Form.copy:
                                foreach (k; 0 .. inf1.n)
                                    a[k] = el_bin(OPeq, elemTy(*inf1, k), elemVar(*inf1, k), elemVar(*inf2, k));
                                break;

                            case Form.pair:
                            {
                                elem* ep = e.E2;
                                replace(ep.E1, true);
                                replace(ep.E2, true);
                                a[0] = el_bin(OPeq, elemTy(*inf1, 0), elemVar(*inf1, 0), ep.E1);
                                a[1] = el_bin(OPeq, elemTy(*inf1, 1), elemVar(*inf1, 1), ep.E2);
                                ep.E1 = null;
                                ep.E2 = null;
                                break;
                            }

                            case Form.constant:
                            case Form.partial:
                            {
                                const elem* ec = e.E2;
                                // the elements the constant covers, and the first of them
                                const uint first = form == Form.partial ? cast(uint)(e.E1.Voffset / inf1.esz) : 0;
                                const uint count = form == Form.partial ? cast(uint)(tysize(e.E1.Ety) / inf1.esz) : inf1.n;
                                foreach (j; 0 .. count)
                                {
                                    const uint k = first + j;
                                    Vconst c;
                                    ulong bits;
                                    // the bits of the j'th element in the constant
                                    if (inf1.esz == 8)
                                        bits = j == 0 ? ec.Vcent.lo : ec.Vcent.hi;
                                    else
                                    {
                                        const ulong half = tysize(ec.Ety) == 16 && j >= 2 ? ec.Vcent.hi : ec.Vcent.lo;
                                        bits = (j & 1) ? half >> 32 : half & 0xFFFF_FFFF;
                                    }
                                    elem* ek;
                                    if (inf1.isInt)
                                        ek = el_long(elemTy(*inf1, k), bits);
                                    else
                                    {
                                        if (inf1.esz == 8)
                                            c.Vdouble = *cast(double*)&bits;
                                        else
                                        {
                                            uint b32 = cast(uint)bits;
                                            c.Vfloat = *cast(float*)&b32;
                                        }
                                        ek = el_const(elemTy(*inf1, k), c);
                                    }
                                    a[j] = el_bin(OPeq, elemTy(*inf1, k), elemVar(*inf1, k), ek);
                                }
                                nchain = count;
                                break;
                            }

                            case Form.load:
                            case Form.store:
                            {
                                Info* inf = form == Form.load ? inf1 : inf2;
                                elem* ep = form == Form.load ? e.E2.E1 : e.E1.E1;
                                replace(ep, true);
                                foreach (k; 0 .. inf.n)
                                {
                                    elem* p = k == 0 ? ep : el_copytree(ep);
                                    if (k)
                                        p = el_bin(OPadd, ep.Ety, p, el_long(TYsize_t, k * inf.esz));
                                    elem* m = el_una(OPind, elemTy(*inf, k), p);
                                    a[k] = form == Form.load ? el_bin(OPeq, elemTy(*inf, k), elemVar(*inf, k), m)
                                                             : el_bin(OPeq, elemTy(*inf, k), m, elemVar(*inf, k));
                                }
                                // detach the pointer, which is now in the element assignments
                                if (form == Form.load)
                                    e.E2.E1 = null;
                                else
                                    e.E1.E1 = null;
                                break;
                            }

                            case Form.result:
                            {
                                // (tmp = value, e.0 = tmp.0, ...)
                                elem* ea = e.E2.E1;
                                replace(ea, false);
                                Symbol* tmp = e.E2.E2.Vsym;
                                a[0] = ea;
                                e.E2.E1 = null;
                                foreach (k; 0 .. inf1.n)
                                {
                                    elem* t = el_var(tmp);
                                    t.Ety = elemTy(*inf1, k);
                                    t.Voffset = k * inf1.esz;
                                    a[k + 1] = el_bin(OPeq, elemTy(*inf1, k), elemVar(*inf1, k), t);
                                }
                                nchain = inf1.n + 1;
                                break;
                            }

                            case Form.storeVar:
                            {
                                // (v.0 = e.0, v.1 = e.1, ...)
                                foreach (k; 0 .. inf2.n)
                                {
                                    elem* t = el_var(e.E1.Vsym);
                                    t.Ety = elemTy(*inf2, k);
                                    t.Voffset = e.E1.Voffset + k * inf2.esz;
                                    a[k] = el_bin(OPeq, elemTy(*inf2, k), t, elemVar(*inf2, k));
                                }
                                nchain = inf2.n;
                                break;
                            }

                            case Form.none:
                                assert(0);
                        }
                        if (!nchain)
                            nchain = (form == Form.store ? inf2 : inf1).n;
                        el_free(e.E1);
                        el_free(e.E2);
                        become(e, chain(a[0 .. nchain]));
                        return;
                    }
                    goto default;
                }

                default:
                    if (OTbinary(e.Eoper))
                    {
                        replace(e.E2, true);
                        e = e.E1;
                        valueUsed = true;
                        continue;
                    }
                    if (OTunary(e.Eoper))
                    {
                        e = e.E1;
                        valueUsed = true;
                        continue;
                    }
                    return;
            }
        }
    }

    foreach (b; BlockRange(startblock))
        if (b.Belem)
            replace(b.Belem, blockValueUsed(b));
}
