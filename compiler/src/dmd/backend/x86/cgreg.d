/**
 * Register allocator
 *
 * Compiler implementation of the
 * $(LINK2 https://www.dlang.org, D programming language).
 *
 * Copyright:   Copyright (C) 1985-1998 by Symantec
 *              Copyright (C) 2000-2026 by The D Language Foundation, All Rights Reserved
 * Authors:     $(LINK2 https://www.digitalmars.com, Walter Bright)
 * License:     $(LINK2 https://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 * Source:      $(LINK2 https://github.com/dlang/dmd/blob/master/compiler/src/dmd/backend/x86/cgreg.d, backend/cgreg.d)
 */

module dmd.backend.x86.cgreg;

import core.stdc.stdio;
import core.stdc.stdlib;
import core.stdc.string;

import dmd.backend.backconfig : debugr;
import dmd.backend.blockopt : bo;
import dmd.backend.cdef;
import dmd.backend.cc;
import dmd.backend.el;
import dmd.backend.global : REGSIZE, mask;
import dmd.backend.symbol : symbol_print, SYMIDX;
import dmd.backend.code;
import dmd.backend.x86.code_x86;
import dmd.backend.codebuilder;
import dmd.backend.oper;
import dmd.backend.symbol;
import dmd.backend.ty;
import dmd.backend.type;

import dmd.backend.barray;
import dmd.backend.dvec;


nothrow:
@safe:

private __gshared
{
    int nretblocks;

    vec_t[REGMAX] regrange;

    Barray!int weights;
}

@trusted
ref int WEIGHTS(int bi, int si) { return weights[bi * globsym.length + si]; }

/******************************************
 */

private __gshared int assignPasses;     // calls to cgreg_assign() for the function

@trusted
void cgreg_init()
{
    assignPasses = 0;
    if (!(config.flags4 & CFG4optimized))
        return;

    // Use calloc() instead because sometimes the alloc is too large
    //printf("1weights: dfo.length = %d, globsym.length = %d\n", dfo.length, globsym.length);
    weights.setLength(bo.dfo.length * globsym.length);
    weights[] = 0;

    nretblocks = 0;
    foreach (bi, b; bo.dfo[])
    {
        if (b.bc == BC.ret || b.bc == BC.retexp)
            nretblocks++;
        if (b.Belem)
        {
            //printf("b.Bweight = x%x\n",b.Bweight);
            el_weights(cast(int)bi,b.Belem,b.Bweight);
        }
    }
    memset(regrange.ptr, 0, regrange.sizeof);

    // Make adjustments to symbols we might stick in registers
    foreach (s; globsym[])
    {
        //printf("considering candidate '%s' for register\n", s.Sident.ptr);

        if (s.Srange)
            s.Srange = vec_realloc(s.Srange,bo.dfo.length);

        // Determine symbols that are not candidates
        uint sz;
        if (!(s.Sflags & GTregcand) ||
            !s.Srange ||
            (sz = cast(uint)type_size(s.Stype)) == 0 ||
            (tysize(s.ty()) == -1) ||
            (I16 && sz > REGSIZE) ||
            (tyfloating(s.ty()) && !(config.fpxmmregs && tyxmmreg(s.ty())))
           )
        {
            debug if (debugr)
            {
                printf("not considering variable '%s' for register\n",s.Sident.ptr);
                if (!(s.Sflags & GTregcand))
                    printf("\tnot GTregcand\n");
                if (!s.Srange)
                    printf("\tno Srange\n");
                if (sz == 0)
                    printf("\tsz == 0\n");
                if (tysize(s.ty()) == -1)
                    printf("\ttysize\n");
            }

            s.Sflags &= ~GTregcand;
            continue;
        }

        switch (s.Sclass)
        {
            case SC.parameter:
                // Do not put parameters in registers if they are not used
                // more than twice (otherwise we have a net loss).
                if (s.Sweight <= 2 && !tyxmmreg(s.ty()))
                {
                    debug if (debugr)
                        printf("parameter '%s' weight %d is not enough\n",s.Sident.ptr,s.Sweight);
                    s.Sflags &= ~GTregcand;
                    continue;
                }
                break;

            default:
                break;
        }

        if (sz == 1)
            s.Sflags |= GTbyte;

        if (!s.Slvreg)
            s.Slvreg = vec_calloc(bo.dfo.length);

        //printf("dfo.length = %d, numbits = %d\n",dfo.length,vec_numbits(s.Srange));
        assert(vec_numbits(s.Srange) == bo.dfo.length);
    }
}

/******************************************
 */

@trusted
void cgreg_term()
{
    if (config.flags4 & CFG4optimized)
    {
        foreach (s; globsym[])
        {
            vec_free(s.Srange);
            vec_free(s.Slvreg);
            s.Srange = null;
            s.Slvreg = null;
        }

        foreach (ref r; regrange[])
        {
            if (r)
            {
                vec_free(r);
                r = null;
            }
        }

        // weights.dtor();   // save allocation for next time
    }
}

/*********************************
 */

@trusted
void cgreg_reset()
{
    foreach (ref r; regrange[])
        if (!r)
            r = vec_calloc(bo.dfo.length);
        else
            vec_clear(r);
}

/*******************************
 * Registers used in block bi.
 */

@trusted
void cgreg_used(uint bi,regm_t used)
{
    for (size_t j = 0; used; j++)
    {   if (used & 1)           // if register j is used
            vec_setbit(bi,regrange[j]);
        used >>= 1;
    }
}

/*************************
 * Run through a tree calculating symbol weights.
 */

@trusted
private void el_weights(int bi,elem* e,uint weight)
{
    while (1)
    {   elem_debug(e);

        int op = e.Eoper;
        if (!OTleaf(op))
        {
            // This prevents variable references within common subexpressions
            // from adding to the variable's usage count.
            if (e.Ecount)
            {
                if (e.Ecomsub)
                    weight = 0;
                else
                    e.Ecomsub = 1;
            }

            if (OTbinary(op))
            {   el_weights(bi,e.E2,weight);
                if ((OTopeq(op) || OTpost(op)) && e.E1.Eoper == OPvar)
                {
                    if (weight >= 10)
                        weight += 10;
                    else
                        weight++;
                }
            }
            e = e.E1;
        }
        else
        {
            switch (op)
            {
                case OPvar:
                    Symbol* s = e.Vsym;
                    if (s.Ssymnum != SYMIDX.max && s.Sflags & GTregcand)
                    {
                        s.Sweight += weight;
                        //printf("adding %d weight to '%s' (block %d, Ssymnum %d), giving Sweight %d\n",weight,s.Sident.ptr,bi,s.Ssymnum,s.Sweight);
                        if (weights)
                            WEIGHTS(bi,cast(int)s.Ssymnum) += weight;
                    }
                    break;

                default:
                    break;
            }
            return;
        }
    }
}

/*****************************************
 * Determine 'benefit' of assigning symbol s to register reg.
 * Benefit is roughly the number of clocks saved.
 * A negative value means that s cannot or should not be assigned to reg.
 */

@trusted
private int cgreg_benefit(ref CGstate cg, Symbol* s, reg_t reg, Symbol* retsym)
{
    /* Unless s is retsym, the benefit depends on reg only through the blocks of s's
     * live range where reg is used, and by the adjustments for reg made before
     * walking the live range. So the walk is done once in each cgreg_assign() for
     * each set of such blocks.
     */
    const si = cast(size_t)s.Ssymnum;
    if (s != retsym && si < globsym.length && globsym[si] is s)
    {
        if (walkHead.length < globsym.length)
        {
            const oldLength = walkHead.length;
            walkHead.setLength(globsym.length);
            walkStamp.setLength(globsym.length);
            walkStamp[oldLength .. $] = 0;
        }
        /* Within a cgreg_assign() the blocks of the live ranges of the symbols
         * still evaluated where a register is used do not change, so the walk
         * found for a symbol and register is found again
         */
        const memoIndex = si * walkMemoRegs + reg;
        if (walkMemo.length < globsym.length * walkMemoRegs)
        {
            const oldLength = walkMemo.length;
            walkMemo.setLength(globsym.length * walkMemoRegs);
            walkMemo[oldLength .. $] = 0;
        }
        uint k = noWalk;
        const memo = walkMemo[memoIndex];
        if (cast(uint)(memo >> 32) == rangeWalkStamp)
            k = cast(uint)memo;
        else
        {
            const nbits = vec_numbits(s.Srange);
            if (!walkUsed || vec_numbits(walkUsed) != nbits)
            {
                vec_free(walkUsed);
                walkUsed = vec_calloc(nbits);
            }
            vec_and(walkUsed, s.Srange, regrange[reg]);

            k = walkStamp[si] == rangeWalkStamp ? walkHead[si] : noWalk;
            for (; k != noWalk; k = rangeWalks[k].next)
            {
                if (vec_equal(rangeWalks[k].used, walkUsed))
                    break;
            }
            if (k == noWalk)
            {
                const walk = cgreg_benefit_walk(cg, s, reg, retsym, true);
                k = cast(uint)rangeWalksUsed++;
                if (k == rangeWalks.length)
                    rangeWalks.push(RangeWalk.init);
                auto w = &rangeWalks[k];
                w.cant = walk == int.min;
                w.benefit = walk;
                setVec(w.used, walkUsed);
                setVec(w.lvreg, s.Slvreg);
                w.next = walkStamp[si] == rangeWalkStamp ? walkHead[si] : noWalk;
                walkHead[si] = k;
                walkStamp[si] = rangeWalkStamp;
            }
            walkMemo[memoIndex] = (cast(ulong)rangeWalkStamp << 32) | k;
        }
        auto w = &rangeWalks[k];
        lastLvreg = w.lvreg;
        if (w.cant)
            return -1;
        int benefit = w.benefit + cgreg_benefit_adjustment(cg, s, reg);
        if (benefit > s.Sweight + 1)
            benefit = int.max;      // saturate instead of overflow error
        return benefit;
    }
    lastLvreg = s.Slvreg;
    return cgreg_benefit_walk(cg, s, reg, retsym, false);
}

/* Set v to a copy of x, reusing v's memory if it has the same size
 */
@trusted
private void setVec(ref vec_t v, const vec_t x)
{
    if (!v || vec_numbits(v) != vec_numbits(x))
    {
        vec_free(v);
        v = vec_clone(x);
    }
    else
        vec_copy(v, x);
}

/* The adjustments of cgreg_benefit() for the choice of register
 */
@trusted
private int cgreg_benefit_adjustment(ref CGstate cg, const Symbol* s, reg_t reg)
{
    int benefit;
    // If s is passed in a register to the function, favor that register
    if ((s.Sclass == SC.fastpar || s.Sclass == SC.shadowreg) && s.Spreg == reg)
        ++benefit;

    // Make sure we have enough uses to justify
    // using a register we must save
    if (cg.fregsaved & (1UL << reg) & cg.mfuncreg)
        benefit -= 1 + nretblocks;
    return benefit;
}

/* The walks of live ranges in the current cgreg_assign(), rangeWalks[0 .. rangeWalksUsed],
 * listed for each globsym[] index i through `next` from walkHead[i] if walkStamp[i]
 * is rangeWalkStamp
 */
private struct RangeWalk
{
    vec_t used;         // the blocks of the live range where the register is used
    bool cant;          // s cannot be in a register
    int benefit;        // benefit from the walk
    vec_t lvreg;        // the blocks where s would be in the register
    uint next;          // the next walk of the same symbol, or noWalk
}
private enum uint noWalk = uint.max;
private __gshared Barray!RangeWalk rangeWalks;
private __gshared size_t rangeWalksUsed;
private __gshared Barray!uint walkHead;
private __gshared Barray!uint walkStamp;
private __gshared vec_t walkUsed;
private __gshared Barray!int walkBefore;   // for cgreg_benefit_walk()
private enum walkMemoRegs = 64;
private __gshared Barray!ulong walkMemo;    // for each symbol and register: rangeWalkStamp, then the walk
private __gshared vec_t lastLvreg;          // the blocks where cgreg_benefit() puts the symbol in the register
private __gshared uint rangeWalkStamp = 1;

/* Compute cgreg_benefit() by walking the live range of s.
 * Params:
 *      walkOnly = leave out the adjustments for the choice of register and the
 *                 saturation, returning int.min if s cannot be in a register
 */
@trusted
private int cgreg_benefit_walk(ref CGstate cg, Symbol* s, reg_t reg, Symbol* retsym, bool walkOnly)
{
    int benefit;
    int benefit2;
    block* b;
    int bi;
    int gotoepilog;
    int retsym_cnt;
    int x;                      // the block taken out of Slvreg

    //printf("cgreg_benefit(s = '%s', reg = %d)\n", s.Sident.ptr, reg);

    vec_sub(s.Slvreg,s.Srange,regrange[reg]);
    int si = cast(int)s.Ssymnum;

    reg_t dst_integer_reg;
    reg_t dst_float_reg;
    cgreg_dst_regs(&dst_integer_reg, &dst_float_reg);

    /* Taking block x out of Slvreg changes what the scan finds only at x and at
     * its successors, so the scan resumes at the first of those in the live range,
     * with the benefit it had before reaching it.
     */
    walkBefore.setLength(2 * bo.dfo.length);
    int start = 0;
    benefit = 0;
    retsym_cnt = 0;
    if (!walkOnly)
        benefit += cgreg_benefit_adjustment(cg, s, reg);
    goto Lscan;

Lagain:
    vec_clearbit(x, s.Slvreg);
    start = x;
    foreach (bs; bo.dfo[x].Bsucc[])
    {
        const j = bs.Bdfoidx;
        if (j < start && vec_testbit(j, s.Srange))
            start = j;
    }
    benefit = walkBefore[2 * start];
    retsym_cnt = walkBefore[2 * start + 1];

Lscan:
    for (bi = start; (bi = cast(uint) vec_index(bi, s.Srange)) < bo.dfo.length; ++bi)
    {   int inoutp;
        int inout_;

        walkBefore[2 * bi] = benefit;
        walkBefore[2 * bi + 1] = retsym_cnt;
        b = bo.dfo[bi];
        switch (b.bc)
        {
            case BC.jcatch:
            case BC.catch_:
            case BC.except:
            case BC.finally_:
            case BC.lpad:
            case BC.finRet:
                s.Sflags &= ~GTregcand;
                goto Lcant;             // can't assign to register

            default:
                break;
        }
        if (vec_testbit(bi,s.Slvreg))
        {   benefit += WEIGHTS(bi,si);
            //printf("WEIGHTS(%d,%d) = %d, benefit = %d\n",bi,si,WEIGHTS(bi,si),benefit);
            inout_ = 1;

            if (s == retsym && (reg == dst_integer_reg || reg == dst_float_reg) && b.bc == BC.retexp)
            {   benefit += 1;
                retsym_cnt++;
                //printf("retsym, benefit = %d\n",benefit);
                if (s.Sfl == FL.reg && !vec_disjoint(s.Srange,regrange[reg]))
                    goto Lcant;                         // don't spill if already in register
            }
        }
        else
            inout_ = -1;

        // Look at predecessors to see if we need to load in/out of register
        gotoepilog = 0;
    L2:
        inoutp = 0;
        benefit2 = 0;
        foreach (bp; b.Bpred[])
        {
            int bpi = bp.Bdfoidx;
            if (!vec_testbit(bpi,s.Srange))
                continue;
            if (gotoepilog && bp.bc == BC.goto_)
            {
                if (vec_testbit(bpi,s.Slvreg))
                {
                    if (inout_ == -1)
                        benefit2 -= bp.Bweight;        // need to mov into mem
                }
                else
                {
                    if (inout_ == 1)
                        benefit2 -= bp.Bweight;        // need to mov into reg
                }
            }
            else if (vec_testbit(bpi,s.Slvreg))
            {
                switch (inoutp)
                {
                    case 0:
                        inoutp = 1;
                        if (inout_ != 1)
                        {   if (gotoepilog)
                            {   x = bpi;
                                goto Lagain;
                            }
                            benefit2 -= b.Bweight;     // need to mov into mem
                        }
                        break;
                    case 1:
                        break;
                    case -1:
                        if (gotoepilog == 0)
                        {   gotoepilog = 1;
                            goto L2;
                        }
                        x = bpi;
                        goto Lagain;

                    default:
                        assert(0);
                }
            }
            else
            {
                switch (inoutp)
                {
                    case 0:
                        inoutp = -1;
                        if (inout_ != -1)
                        {   if (gotoepilog)
                            {   x = bi;
                                goto Lagain;
                            }
                            benefit2 -= b.Bweight;     // need to mov into reg
                        }
                        break;
                    case 1:
                        if (gotoepilog == 0)
                        {   gotoepilog = 1;
                            goto L2;
                        }
                        if (inout_ == 1)
                        {   x = bi;
                            goto Lagain;
                        }
                        goto Lcant;
                    case -1:
                        break;

                    default:
                        assert(0);
                }
            }
        }
        //printf("benefit2 = %d\n", benefit2);
        benefit += benefit2;
    }

    //printf("2weights: dfo.length = %d, globsym.length = %d\n", dfo.length, globsym.length);
    debug if (benefit > s.Sweight + retsym_cnt + 1)
        printf("s = '%s', benefit = %d, Sweight = %d, retsym_cnt = x%x\n",s.Sident.ptr,benefit,s.Sweight, retsym_cnt);

    /* This can happen upon overflow of s.Sweight, but only in extreme cases such as
     * issues.dlang.org/show_bug.cgi?id=17098
     * It essentially means "a whole lotta uses in nested loops", where
     * it should go into a register anyway. So just saturate it at int.max
     */
    //assert(benefit <= s.Sweight + retsym_cnt + 1);
    if (walkOnly)
        return benefit;
    if (benefit > s.Sweight + retsym_cnt + 1)
        benefit = int.max;      // saturate instead of overflow error
    return benefit;

Lcant:
    return walkOnly ? int.min : -1;     // can't assign to reg
}

/*********************************************
 * Determine if block gets symbol loaded by predecessor epilog (1),
 * or by prolog (0).
 */

int cgreg_gotoepilog(block* b,Symbol* s)
{
    int bi = b.Bdfoidx;

    int inout_;
    if (vec_testbit(bi,s.Slvreg))
        inout_ = 1;
    else
        inout_ = -1;

    // Look at predecessors to see if we need to load in/out of register
    int gotoepilog = 0;
    int inoutp = 0;
    foreach (bp; b.Bpred[])
    {
        int bpi = bp.Bdfoidx;
        if (!vec_testbit(bpi,s.Srange))
            continue;
        if (vec_testbit(bpi,s.Slvreg))
        {
            switch (inoutp)
            {
                case 0:
                    inoutp = 1;
                    if (inout_ != 1)
                    {   if (gotoepilog)
                            goto Lcant;
                    }
                    break;
                case 1:
                    break;
                case -1:
                    if (gotoepilog == 0)
                    {   gotoepilog = 1;
                        goto Lret;
                    }
                    goto Lcant;

                default:
                    assert(0);
            }
        }
        else
        {
            switch (inoutp)
            {
                case 0:
                    inoutp = -1;
                    if (inout_ != -1)
                    {   if (gotoepilog)
                            goto Lcant;
                    }
                    break;
                case 1:
                    if (gotoepilog == 0)
                    {   gotoepilog = 1;
                        goto Lret;
                    }
                    goto Lcant;
                case -1:
                    break;

                default:
                    assert(0);
            }
        }
    }
Lret:
    return gotoepilog;

Lcant:
    assert(0);
//    return -1;                  // can't assign to reg
}

/**********************************
 * Determine block prolog code for `s` - it's either
 * assignments to register, or storing register back in memory.
 * Params:
 *      b = block to generate prolog code for
 *      s = symbol in the block that may need prolog code
 *      cdbstore = append store code to this
 *      cdbload = append load code to this
 */
void cgreg_spillreg_prolog(block* b,Symbol* s,ref CodeBuilder cdbstore,ref CodeBuilder cdbload)
{
    const int bi = b.Bdfoidx;

    //printf("cgreg_spillreg_prolog(block %d, s = '%s')\n",bi,s.Sident.ptr);

    // Load register from s
    void load()
    {
        debug if (debugr)
        {
            printf("B%d: prolog moving '%s' into %s:%s\n",
                    bi, s.Sident.ptr, regstring[s.Sregmsw],
                    type_size(s.Stype) > REGSIZE ? regstring[s.Sreglsw] : "");
        }
        gen_spill_reg(cdbload, s, true);
    }

    // Store register to s
    void store()
    {
        debug if (debugr)
        {
            printf("B%d: prolog moving %s into '%s'\n",bi,regstring[s.Sreglsw],s.Sident.ptr);
        }
        gen_spill_reg(cdbstore, s, false);
    }

    const live = vec_testbit(bi,s.Slvreg) != 0;   // if s is in a register in block b

    // If it's startblock, and it's a spilled parameter, we
    // need to load it
    if (live && s.Sflags & SFLspill && bi == 0 &&
        (s.Sclass == SC.parameter || s.Sclass == SC.fastpar || s.Sclass == SC.shadowreg))
    {
        return load();
    }

    if (cgreg_gotoepilog(b,s))
        return;

    // Look at predecessors to see if we need to load in/out of register
    foreach (bl; b.Bpred[])
    {
        const bpi = bl.Bdfoidx;

        if (!vec_testbit(bpi,s.Srange))
            continue;
        if (vec_testbit(bpi,s.Slvreg))
        {
            if (!live)
            {
                return store();
            }
        }
        else
        {
            if (live)
            {
                return load();
            }
        }
    }
}

/**********************************
 * Determine block epilog code - it's either
 * assignments to register, or storing register back in memory.
 * Params:
 *      b = block to generate prolog code for
 *      s = symbol in the block that may need epilog code
 *      cdbstore = append store code to this
 *      cdbload = append load code to this
 */
void cgreg_spillreg_epilog(block* b,Symbol* s,ref CodeBuilder cdbstore, ref CodeBuilder cdbload)
{
    const bi = b.Bdfoidx;
    //printf("cgreg_spillreg_epilog(block %d, s = '%s')\n",bi,s.Sident.ptr);
    //assert(b.bc == BC.goto_);
    if (!cgreg_gotoepilog(b.Bsucc[0], s))
        return;

    const live = vec_testbit(bi,s.Slvreg) != 0;

    // Look at successors to see if we need to load in/out of register
    foreach (bs; b.Bsucc[])
    {
        const bpi = bs.Bdfoidx;
        if (!vec_testbit(bpi,s.Srange))
            continue;
        if (vec_testbit(bpi,s.Slvreg))
        {
            if (!live)
            {
                debug if (debugr)
                    printf("B%d: epilog moving '%s' into %s\n",bi,s.Sident.ptr,regstring[s.Sreglsw]);
                gen_spill_reg(cdbload, s, true);
                return;
            }
        }
        else
        {
            if (live)
            {
                debug if (debugr)
                    printf("B%d: epilog moving %s into '%s'\n",bi,regstring[s.Sreglsw],s.Sident.ptr);
                gen_spill_reg(cdbstore, s, false);
                return;
            }
        }
    }
}

/***************************
 * Map symbol s into registers [NOREG,reglsw] or [regmsw, reglsw].
 */

@trusted
private void cgreg_map(ref CGstate cg, Symbol* s, reg_t regmsw, reg_t reglsw)
{
    //assert(I64 || reglsw < 8);

    if (vec_disjoint(s.Srange,regrange[reglsw]) &&
        (regmsw == NOREG || vec_disjoint(s.Srange,regrange[regmsw]))
       )
    {
        s.Sfl = FL.reg;
        vec_copy(s.Slvreg,s.Srange);
    }
    else
    {
        s.Sflags |= SFLspill;

        // Already computed by cgreg_benefit()
        //vec_sub(s.Slvreg,s.Srange,regrange[reglsw]);

        if (s.Sfl == FL.reg)            // if reassigned
        {
            switch (s.Sclass)
            {
                case SC.auto_:
                case SC.register:
                    s.Sfl = FL.auto_;
                    break;
                case SC.fastpar:
                    s.Sfl = FL.fast;
                    break;
                case SC.bprel:
                    s.Sfl = FL.bprel;
                    break;
                case SC.shadowreg:
                case SC.parameter:
                    s.Sfl = FL.para;
                    break;
                case SC.pseudo:
                    s.Sfl = FL.pseudo;
                    break;
                case SC.stack:
                    s.Sfl = FL.stack;
                    break;
                default:
                    symbol_print(*s);
                    assert(0);
            }
        }
    }
    s.Sreglsw = reglsw;
    s.Sregm = (1UL << reglsw);
    cg.mfuncreg &= ~(1UL << reglsw);
    if (regmsw != NOREG)
        vec_subass(s.Slvreg,regrange[regmsw]);
    vec_orass(regrange[reglsw],s.Slvreg);

    if (regmsw == NOREG)
    {
        debug
        {
            if (debugr)
            {
                printf("symbol '%s' %s in register %s\n    ",
                    s.Sident.ptr,
                    (s.Sflags & SFLspill) ? "spilled".ptr : "put".ptr,
                    regstring[reglsw]);
                vec_println(s.Slvreg);
            }
        }
    }
    else
    {
        assert(regmsw < REGMAX);
        s.Sregmsw = regmsw;
        s.Sregm |= 1UL << regmsw;
        cg.mfuncreg &= ~(1UL << regmsw);
        vec_orass(regrange[regmsw],s.Slvreg);

        debug
        {
            if (debugr)
                printf("symbol '%s' %s in register pair %s\n",
                    s.Sident.ptr,
                    (s.Sflags & SFLspill) ? "spilled".ptr : "put".ptr,
                    regm_str(s.Sregm));
        }
    }
}

/********************************************
 * The register variables in this mask can not be in registers.
 * "Unregister" them.
 */

@trusted
void cgreg_unregister(ref CGstate cg, regm_t conflict)
{
    if (cg.pass == BackendPass.final_)
        cg.pass = BackendPass.reg;                         // have to codegen at least one more time
    foreach (s; globsym[])
    {
        if (s.Sfl == FL.reg && s.Sregm & conflict)
        {
            s.Sflags |= GTunregister;
        }
    }
}

/******************************************
 * Do register assignments.
 * Returns:
 *      !=0     redo code generation
 *      0       no more register assignments
 */

struct Reg              // data for trial register assignment
{
    Symbol* sym;
    int benefit;
    reg_t reglsw;
    reg_t regmsw;
}

@trusted
int cgreg_assign(ref CGstate cg, Symbol* retsym)
{
    int flag = false;                   // assume no changes
    ++assignPasses;
    rangeWalksUsed = 0;
    if (++rangeWalkStamp == 0)          // invalidate the walks of the last call
    {
        walkStamp[][] = 0;
        rangeWalkStamp = 1;
    }
    const bool AArch64 = cg.AArch64;

    /* First do any 'unregistering' which might have happened in the last
     * code gen pass.
     */
    foreach (s; globsym[])
    {
        if (s.Sflags & GTunregister)
        {
            debug if (debugr)
            {
                printf("symbol '%s' %s register %s\n    ",
                    s.Sident.ptr,
                    (s.Sflags & SFLspill) ? "unspilled".ptr : "unregistered".ptr,
                    regstring[s.Sreglsw]);
                vec_println(s.Slvreg);
            }

            flag = true;
            s.Sflags &= ~(GTregcand | GTunregister | SFLspill);
            if (s.Sfl == FL.reg)
            {
                switch (s.Sclass)
                {
                    case SC.auto_:
                    case SC.register:
                        s.Sfl = FL.auto_;
                        break;
                    case SC.fastpar:
                        s.Sfl = FL.fast;
                        break;
                    case SC.bprel:
                        s.Sfl = FL.bprel;
                        break;
                    case SC.shadowreg:
                    case SC.parameter:
                        s.Sfl = FL.para;
                        break;
                    case SC.pseudo:
                        s.Sfl = FL.pseudo;
                        break;
                    case SC.stack:
                        s.Sfl = FL.stack;
                        break;
                    default:
                        debug symbol_print(*s);
                        assert(0);
                }
            }
        }
    }

    vec_t v = vec_calloc(bo.dfo.length);

    reg_t dst_integer_reg;
    reg_t dst_float_reg;
    cgreg_dst_regs(&dst_integer_reg, &dst_float_reg);
    regm_t dst_integer_mask = 1UL << dst_integer_reg;
    regm_t dst_float_mask = 1UL << dst_float_reg;

    /* Find all the parameters passed as named registers
     */
    regm_t regparams = 0;
    foreach (s; globsym[])
    {
        if (s.Sclass == SC.fastpar || s.Sclass == SC.shadowreg)
            regparams |= s.Spregm();
    }

    /* Disallow parameters being put in registers that are used by the 64 bit
     * prolog generated by prolog_getvarargs()
     */
    regm_t variadicPrologRegs = (I64 && variadic(funcsym_p.Stype))
        ? (mAX | mR11) |   // these are used by the prolog code
          ((mDI | mSI | mDX | mCX | mR8 | mR9 | XMMREGS) & ~regparams) // unnamed register arguments
        : 0;

    if (AArch64)
    {
        variadicPrologRegs = variadic(funcsym_p.Stype)
            ? (mask(11)) |   // these are used by the prolog code
              ((0xFF_0000_00FF) & ~regparams) // unnamed register arguments R0..R7 and Q32..Q39
            : 0;
    }

    /* Assign registers to the most 'deserving' symbol t, then to the next most
     * deserving one with a live range apart from those of the symbols assigned
     * so far, and so on. Assigning a register changes the code generated for the
     * blocks of the symbol's live range, so which registers that code uses, which
     * the next assignments in those blocks depend on, is only known after
     * generating the code again; the code of other blocks is unaffected.
     */
    vec_t assignedRange = vec_calloc(bo.dfo.length);
    /* The best register assignment for symbol s in the current state, with in v
     * the blocks where s would be in the register
     */
    Reg evaluate(Symbol* s, vec_t v)
    {
        Reg u;
            u.sym = s;
            if (!(s.Sflags & GTregcand) ||
                s.Sflags & SFLspill ||
                // Keep trying to reassign retsym into destination register
                (s.Sfl == FL.reg && !(s == retsym && s.Sregm != dst_integer_mask && s.Sregm != dst_float_mask))
               )
            {
                debug if (debugr)
                {
                    if (s.Sfl == FL.reg)
                    {
                        printf("symbol '%s' is in reg %s\n",s.Sident.ptr,regm_str(s.Sregm));
                    }
                    else if (s.Sflags & SFLspill)
                    {
                        printf("symbol '%s' spilled in reg %s\n",s.Sident.ptr,regm_str(s.Sregm));
                    }
                    else if (!(s.Sflags & GTregcand))
                    {
                        printf("symbol '%s' is not a reg candidate\n",s.Sident.ptr);
                    }
                    else
                        printf("symbol '%s' is not a candidate\n",s.Sident.ptr);
                }
    
                return Reg.init;
            }
    
            tym_t ty = s.ty();
    
            debug
            {
                if (debugr)
                {   printf("symbol '%3s', ty x%x weight x%x %s\n   ",
                    s.Sident.ptr,ty,s.Sweight,
                    regm_str(s.Spregm()));
                    vec_println(s.Srange);
                }
            }
    
            // Select sequence of registers to try to map s onto
            const(reg_t)[] pseq;                     // sequence to try for LSW
            const(reg_t)[] pseqmsw = null;           // sequence to try for MSW, null if none
            cgreg_set_priorities(ty, pseq, pseqmsw);
    
            u.benefit = 0;
            for (int i = 0; i < pseq.length; i++)
            {
                reg_t reg = pseq[i];
    
                // Symbols used as return values should only be mapped into return value registers
                if (s == retsym && !(reg == dst_integer_reg || reg == dst_float_reg))
                    continue;
    
                // If BP isn't available, can't assign to it
                if (!AArch64 && reg == BP && !(cg.allregs & mBP))
                    continue;
    
    static if (0 && TARGET_LINUX)
    {
                // Need EBX for static pointer
                if (reg == BX && !(cg.allregs & mBX))
                    continue;
    }
                /* Don't enregister any parameters to variadicPrologRegs
                 */
                if (variadicPrologRegs & (1UL << reg))
                {
                    if (s.Sclass == SC.parameter || s.Sclass == SC.fastpar)
                        continue;
                    /* Win64 doesn't use the Posix variadic scheme, so we can skip SCshadowreg
                     */
                }
    
                /* Don't assign register parameter to another register parameter
                 */
                if ((s.Sclass == SC.fastpar || s.Sclass == SC.shadowreg) &&
                    (1UL << reg) & regparams &&
                    reg != s.Spreg)
                    continue;
    
                if (!AArch64 &&
                    s.Sflags & GTbyte &&
                    !((1UL << reg) & BYTEREGS))
                        continue;
    
                int benefit = cgreg_benefit(cg,s,reg,retsym);
    
                debug if (debugr)
                {   printf(" %s",regstring[reg]);
                    vec_print(regrange[reg]);
                    printf(" %d\n",benefit);
                }
    
                if (benefit > u.benefit)
                {   // successful assigning of lsw
                    reg_t regmsw = NOREG;
    
                    // Now assign MSW
                    foreach (r2; pseqmsw[])
                    {
                        if (r2 == reg)              // can't assign msw and lsw to same reg
                            continue;
                        if ((s.Sclass == SC.fastpar || s.Sclass == SC.shadowreg) &&
                            (1UL << r2) & regparams &&
                            r2 != s.Spreg2)
                            continue;
    
                        debug if (debugr)
                        {   printf(".%s",regstring[r2]);
                            vec_println(regrange[r2]);
                        }
    
                        if (vec_disjoint(lastLvreg,regrange[r2]))
                        {
                            regmsw = r2;
                            break;
                        }
                    }
                    if (regmsw == NOREG && pseqmsw.length)
                        goto Ltried;                // tried and failed to assign MSW
                    vec_copy(v,lastLvreg);
                    u.benefit = benefit;
                    u.reglsw = reg;
                    u.regmsw = regmsw;
                }
    Ltried:
            }
        return u;
    }

    /* The symbols' best assignments, each with the blocks where the symbol would
     * be in the register
     */
    static struct Candidate
    {
        Reg u;
        vec_t lvreg;
    }
    Barray!Candidate candidates;

    /* Evaluate the symbols with live ranges apart from those of the symbols assigned
     * so far
     */
    void evaluateAll()
    {
        foreach (ref c; candidates[])
            vec_free(c.lvreg);
        candidates.setLength(0);
        foreach (s; globsym[])
        {
            if (flag && (!s.Srange || !vec_disjoint(s.Srange, assignedRange)))
                continue;
            Reg u = evaluate(s, v);
            if (u.sym && u.benefit > 0)
                candidates.push(Candidate(u, vec_clone(v)));
        }
    }

    /* An assignment changes regrange[] only in the blocks of the symbol's live range,
     * so it changes the best assignments of the symbols with live ranges apart from
     * it only by making a register no longer one that must be saved
     */
    evaluateAll();
    while (1)
    {
        // Find symbol t, which is the most 'deserving' symbol that should be
        // placed into a register.
        size_t best = size_t.max;
        foreach (i, ref c; candidates[])
        {
            if (c.u.sym && (best == size_t.max || c.u.benefit > candidates[best].u.benefit))
                best = i;
        }
        if (best == size_t.max)
            break;
        /* Each assignment after the first pass costs generating the code of the
         * function again, so it is made only for a symbol that pays for that
         */
        enum minLaterBenefit = 20;
        if (assignPasses > 1 && candidates[best].u.benefit < minLaterBenefit)
            break;
        Reg t = candidates[best].u;
        vec_copy(t.sym.Slvreg, candidates[best].lvreg);
        const mfuncregBefore = cg.mfuncreg;
        cgreg_map(cg,t.sym,t.regmsw,t.reglsw);
        flag = true;
        vec_orass(assignedRange, t.sym.Srange);

        if (cg.mfuncreg != mfuncregBefore)
            evaluateAll();
        else
        {
            foreach (ref c; candidates[])
            {
                if (c.u.sym && !vec_disjoint(c.u.sym.Srange, assignedRange))
                    c.u.sym = null;
            }
        }
    }
    foreach (ref c; candidates[])
        vec_free(c.lvreg);
    candidates.dtor();
    vec_free(assignedRange);

    /* See if any scratch registers have become available that we can use.
     * Scratch registers are cheaper, as they don't need save/restore.
     * All floating point registers are scratch registers, so no need
     * to do this for them.
     */
    if ((I32 || I64) &&                       // not worth the bother for 16 bit code
        !flag &&                              // if haven't already assigned registers in this pass
        (cg.mfuncreg & ~cg.fregsaved) & cg.allregs &&  // if unused non-floating scratch registers
        !(funcsym_p.Sflags & SFLexit))       // don't need save/restore if function never returns
    {
        foreach (s; globsym[])
        {
            if (s.Sfl == FL.reg &&                // if assigned to register
                (1UL << s.Sreglsw) & cg.fregsaved &&   // and that register is not scratch
                type_size(s.Stype) <= REGSIZE && // don't bother with register pairs
                !tyfloating(s.ty()))             // don't assign floating regs to non-floating regs
            {
                s.Sreglsw = findreg((cg.mfuncreg & ~cg.fregsaved) & cg.allregs);
                s.Sregm = 1UL << s.Sreglsw;
                flag = true;

                debug if (debugr)
                    printf("re-assigned '%s' to %s\n",s.Sident.ptr,regstring[s.Sreglsw]);

                break;
            }
        }
    }
    vec_free(v);

    return flag;
}
