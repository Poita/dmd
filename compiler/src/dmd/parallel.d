/**
 * Split the semantic3, inlining and code generation of the root modules across
 * forked worker processes.
 *
 * After semantic2 the modules are divided into chunks of about equal source size,
 * and one process per chunk carries on compiling only that chunk. Each worker writes
 * its output (an object file or a library) with a part suffix, and the first worker,
 * which is the original process, waits for the others and combines the parts into
 * the requested output. Declarations are fully analyzed before the split, so every
 * worker sees the same symbols; a template instance can end up generated in more than
 * one part, which is harmless as template instances are weak definitions.
 *
 * Copyright:   Copyright (C) 1999-2026 by The D Language Foundation, All Rights Reserved
 * License:     $(LINK2 https://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 */
module dmd.parallel;

import core.stdc.stdio;
import core.stdc.stdlib;
import core.stdc.string;

import dmd.arraytypes;
import dmd.dmodule;
import dmd.globals;
import dmd.root.filename;

version (Posix)
{
    import core.sys.posix.sys.types : pid_t;
    import core.sys.posix.sys.wait : waitpid, WIFEXITED, WEXITSTATUS;
    import core.sys.posix.unistd : fork, _exit, sysconf, execvp, _SC_NPROCESSORS_ONLN;
}

/**************************************
 * A template instance is added to the module declaring its template, which may be
 * one another worker compiles. Instances this worker has added to the other workers'
 * modules since the split are semantically analyzed here and moved to this worker's
 * first module, so that it generates their code.
 * Params:
 *      w = the split
 *      modules = this worker's root modules
 */
void adoptForeignInstances(ref Workers w, ref Modules modules) @system
{
    import dmd.dsymbol : Dsymbol;
    import dmd.dtemplate : TemplateInstance;
    import dmd.dsymbolsem : runDeferredSemantic3;
    import dmd.semantic3 : semantic3;

    if (w.index < 0 || !modules.length)
        return;
    TemplateInstance[] adopted;
    bool again = true;
    while (again)
    {
        again = false;
        foreach (k, m; w.others)
        {
            while (m.members && w.seen[k] < m.members.length)
            {
                Dsymbol s = (*m.members)[w.seen[k]++];
                if (auto ti = s.isTemplateInstance())
                {
                    semantic3(ti, null);
                    adopted ~= ti;
                    again = true;
                }
            }
        }
        runDeferredSemantic3();
    }
    foreach (ti; adopted)
        modules[0].members.push(ti);
}

nothrow:

/// The state of a compilation split across worker processes
struct Workers
{
    int index = -1;         /// this process's worker number, -1 when not split
    int count;              /// number of workers
    version (Posix) pid_t[] children; /// in worker 0: the other workers' process ids
    Module[] others;        /// the root modules of the other workers
    size_t[] seen;          /// how many members of each of `others` have been looked at

    /// Returns: true if the compilation is split and this is worker 0, the original process
    bool isFirst() const { return index == 0; }

    /// Returns: true if this is a forked worker other than the first
    bool isChild() const { return index > 0; }
}

/// Returns: the suffix added to the output file names of worker `index`
const(char)[] partSuffix(int index)
{
    char[16] buf = void;
    const n = snprintf(buf.ptr, buf.length, ".part%d", index);
    return buf[0 .. n].idup;
}

/**************************************
 * Split the root modules across worker processes.
 * Params:
 *      modules = the root modules; narrowed to this worker's chunk
 *      requested = number of workers asked for, 0 for one per processor
 * Returns:
 *      the split, with `index` of -1 if the modules were not split
 */
Workers split(ref Modules modules, uint requested)
{
    Workers w;
    version (Posix)
    {
        size_t n = requested ? requested : cast(size_t)sysconf(_SC_NPROCESSORS_ONLN);
        if (n > modules.length)
            n = modules.length;
        if (n < 2)
            return w;

        /* Assign the largest modules first, each to the least loaded chunk
         */
        auto order = new size_t[modules.length];
        foreach (i, ref o; order)
            o = i;
        static size_t weight(Module m) { return m.src.length + 1; }
        import core.stdc.stdlib : qsort;
        __gshared Module[] sortModules;
        sortModules = modules[];
        extern (C) static int cmp(const void* a, const void* b)
        {
            const wa = weight(sortModules[*cast(size_t*)a]);
            const wb = weight(sortModules[*cast(size_t*)b]);
            return wa < wb ? 1 : wa > wb ? -1 : 0;
        }
        qsort(order.ptr, order.length, size_t.sizeof, &cmp);

        auto chunkOf = new int[modules.length];
        auto load = new size_t[n];
        foreach (i; order)
        {
            size_t best = 0;
            foreach (k; 1 .. n)
                if (load[k] < load[best])
                    best = k;
            chunkOf[i] = cast(int)best;
            load[best] += weight(modules[i]);
        }

        fflush(stdout);
        fflush(stderr);
        w.count = cast(int)n;
        w.index = 0;
        foreach (k; 1 .. n)
        {
            const pid = fork();
            if (pid == -1)
                break;          // carry on with fewer workers
            if (pid == 0)
            {
                w.index = cast(int)k;
                w.children = null;
                break;
            }
            w.children ~= pid;
        }
        if (w.index == 0)
            w.count = cast(int)(w.children.length + 1);

        /* Keep this worker's chunk; a worker that couldn't be forked leaves its
         * chunk to worker 0
         */
        size_t j = 0;
        foreach (i; 0 .. modules.length)
        {
            const c = chunkOf[i];
            if (c == w.index || (w.index == 0 && c >= w.count))
                modules[j++] = modules[i];
            else
            {
                w.others ~= modules[i];
                w.seen ~= modules[i].members ? modules[i].members.length : 0;
            }
        }
        modules.setDim(j);
    }
    return w;
}

/**************************************
 * In worker 0, wait for the other workers.
 * Returns:
 *      true if they all succeeded
 */
bool waitForWorkers(ref Workers w)
{
    bool ok = true;
    version (Posix)
    {
        foreach (pid; w.children)
        {
            int status;
            if (waitpid(pid, &status, 0) == -1 || !WIFEXITED(status) || WEXITSTATUS(status) != 0)
                ok = false;
        }
    }
    return ok;
}

/**************************************
 * End a forked worker once its output part is written.
 */
void exitWorker(bool ok)
{
    fflush(stdout);
    fflush(stderr);
    version (Posix)
        _exit(ok ? 0 : 1);
    else
        exit(ok ? 0 : 1);
}

/**************************************
 * Combine the object file parts of all workers into one object file with `ld -r`.
 * Params:
 *      objfile = the object file to write
 *      count = number of workers
 * Returns:
 *      true on success
 */
bool mergeObjects(const(char)[] objfile, int count)
{
    version (Posix)
    {
        const(char)*[] argv;
        argv ~= "ld";
        argv ~= "-r";
        argv ~= "-o";
        argv ~= toCString(objfile);
        const(char)[][] parts;
        foreach (k; 0 .. count)
        {
            parts ~= objfile ~ partSuffix(k);
            argv ~= toCString(parts[$ - 1]);
        }
        argv ~= null;

        fflush(stdout);
        fflush(stderr);
        const pid = fork();
        if (pid == -1)
            return false;
        if (pid == 0)
        {
            execvp(argv[0], argv.ptr);
            _exit(127);
        }
        int status;
        const ok = waitpid(pid, &status, 0) != -1 && WIFEXITED(status) && WEXITSTATUS(status) == 0;
        foreach (p; parts)
            remove(toCString(p));
        return ok;
    }
    else
        return false;
}

private const(char)* toCString(const(char)[] s)
{
    auto p = cast(char*)malloc(s.length + 1);
    memcpy(p, s.ptr, s.length);
    p[s.length] = 0;
    return p;
}

