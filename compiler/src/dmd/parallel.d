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
    import core.sys.posix.unistd : dup2, fork, _exit, sysconf, execvp, _SC_NPROCESSORS_ONLN;
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
    int index = -1;         /// in a worker, its number; -1 in the original process
    int count;              /// number of workers started, 0 if the compilation is not split
    bool succeeded;         /// in the original process: every worker wrote its output part
    Module[] others;        /// in a worker: the root modules of the other workers
    size_t[] seen;          /// how many members of each of `others` have been looked at

    /// Returns: true if this is a forked worker
    bool isChild() const nothrow { return index >= 0; }
}

/// Returns: the suffix added to the output file names of worker `index`
const(char)[] partSuffix(int index)
{
    char[16] buf = void;
    const n = snprintf(buf.ptr, buf.length, ".part%d", index);
    return buf[0 .. n].idup;
}

version (Posix)
{
    /* In a worker: where it reports its results to the original process, and how
     * many library files were listed when it started
     */
    private __gshared FILE* resultFile;
    private __gshared size_t libfilesAtSplit;
}

/**************************************
 * Split the root modules across worker processes.
 *
 * The original process forks the workers and waits for them. A worker's output
 * goes to a temporary file: a worker that prints anything (errors, warnings,
 * deprecations, messages) or fails makes the split unsuccessful, and the original
 * process, still in its state from before the split, then compiles all the modules
 * itself, so that diagnostics are exactly those of an unsplit compilation.
 * Params:
 *      modules = the root modules; in a worker, narrowed to its chunk
 *      requested = number of workers asked for, 0 for one per processor
 * Returns:
 *      the split
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
        libfilesAtSplit = global.params.libfiles.length;
        pid_t[] children;
        FILE*[] outputs;
        FILE*[] results;
        foreach (k; 0 .. n)
        {
            FILE* output = tmpfile();
            FILE* result = tmpfile();
            if (!output || !result)
                break;
            const pid = fork();
            if (pid == -1)
                break;
            if (pid == 0)
            {
                dup2(fileno(output), 1);
                dup2(fileno(output), 2);
                resultFile = result;
                w.index = cast(int)k;
                break;
            }
            children ~= pid;
            outputs ~= output;
            results ~= result;
        }

        if (w.isChild)
        {
            w.count = cast(int)n;
            size_t j = 0;
            foreach (i; 0 .. modules.length)
            {
                if (chunkOf[i] == w.index)
                    modules[j++] = modules[i];
                else
                {
                    w.others ~= modules[i];
                    w.seen ~= modules[i].members ? modules[i].members.length : 0;
                }
            }
            modules.setDim(j);
            return w;
        }

        w.count = cast(int)children.length;
        w.succeeded = children.length == n;
        foreach (k, pid; children)
        {
            int status;
            if (waitpid(pid, &status, 0) == -1 || !WIFEXITED(status) || WEXITSTATUS(status) != 0 ||
                fseek(outputs[k], 0, SEEK_END) != 0 || ftell(outputs[k]) != 0)
                w.succeeded = false;
            fclose(outputs[k]);
        }
        if (w.succeeded)
        {
            foreach (result; results)
                readResult(result);
        }
        foreach (result; results)
            fclose(result);
    }
    return w;
}

/**************************************
 * End a worker once its output part is written, reporting to the original process
 * the library files it added to the link.
 */
void exitWorker(bool ok)
{
    version (Posix)
    {
        foreach (name; global.params.libfiles[libfilesAtSplit .. $])
            fwrite(name, 1, strlen(name) + 1, resultFile);
        if (fflush(resultFile) != 0)
            ok = false;
    }
    fflush(stdout);
    fflush(stderr);
    version (Posix)
        _exit(ok ? 0 : 1);
    else
        exit(ok ? 0 : 1);
}

/* Add the library files a worker reported to the link.
 */
version (Posix)
private void readResult(FILE* result)
{
    fseek(result, 0, SEEK_END);
    const size = ftell(result);
    if (size <= 0)
        return;
    auto buf = cast(char*)malloc(size);
    rewind(result);
    if (fread(buf, 1, size, result) != size)
        return;
    for (size_t i = 0; i < size; i += strlen(buf + i) + 1)
        global.params.libfiles.push(buf + i);
}

/// Returns: the names of the output parts of `count` workers writing `file`
const(char)[][] partNames(const(char)[] file, int count)
{
    const(char)[][] parts;
    foreach (k; 0 .. count)
        parts ~= file ~ partSuffix(k);
    return parts;
}

/// Delete output parts
void removeParts(const(char)[][] parts)
{
    foreach (p; parts)
        remove(toCString(p));
}

/**************************************
 * Combine object file parts into one object file with `ld -r`.
 * Params:
 *      objfile = the object file to write
 *      parts = the object files to combine
 * Returns:
 *      true on success
 */
bool mergeObjects(const(char)[] objfile, const(char)[][] parts)
{
    version (Posix)
    {
        const(char)*[] argv;
        argv ~= "ld";
        argv ~= "-r";
        argv ~= "-o";
        argv ~= toCString(objfile);
        foreach (p; parts)
            argv ~= toCString(p);
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
        return waitpid(pid, &status, 0) != -1 && WIFEXITED(status) && WEXITSTATUS(status) == 0;
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

