#!/usr/bin/env zsh
# Checks that dmd's output is a function of its sources and flags only.
#
# Compiles each case several times, with -j=1 and with -j=N, and compares the
# output files byte for byte: every run of a mode against the first run of that
# mode, and the -j=N output against the -j=1 output. With -x, the first -j=1
# output of a second compiler (e.g. a differently built dmd of the same source)
# is compared against the first one's too.
#
# Usage: determinism.sh [-r runs] [-j N] [-x other-dmd] [-k] dmd case...
#
# A case is one of
#   phobos        a set of Phobos modules compiled to one object file with
#                 -O -release -inline
#   phobos-debug  the same modules compiled with -g
#   name=dir=cmdfile
#                 the dmd command line in cmdfile (as `dub build -v` prints it),
#                 run in dir; its first word is replaced by the dmd under test and
#                 its -of output is redirected
#
# Archives are compared as written, with SOURCE_DATE_EPOCH set so that their member
# headers do not record the time of the compilation.
#
# To compare two builds of dmd (e.g. a PGO build and a plain one), give both the same
# configuration (-conf=), since the import paths dmd.conf gives end up in the output.
#
# -k keeps the outputs (in the directory printed at the end) instead of deleting them.
# Exit status: 0 if all outputs match, 1 if any differ or a compilation fails.

emulate -L zsh
setopt err_return pipe_fail extended_glob

runs=3 jobs=4 other= keep=
while getopts "r:j:x:k" opt; do
    case $opt in
        r) runs=$OPTARG ;;
        j) jobs=$OPTARG ;;
        x) other=${OPTARG:A} ;;
        k) keep=1 ;;
        *) print -u2 "usage: $0 [-r runs] [-j N] [-x other-dmd] [-k] dmd case..."; exit 2 ;;
    esac
done
shift $((OPTIND - 1))
(( $# >= 2 )) || { print -u2 "usage: $0 [-r runs] [-j N] [-x other-dmd] [-k] dmd case..."; exit 2 }
dmd=${1:A}; shift

export SOURCE_DATE_EPOCH=0
out=$(mktemp -d /tmp/determinism.XXXXXX)
mkdir $out/work
failed=0

# The directory of Phobos sources the compiler imports, from its configuration
phobosDir() {
    print "module empty; import std.algorithm;" > $out/empty.d
    local d=$($1 -v -o- -c $out/empty.d 2>/dev/null | sed -n 's#^import *std\.algorithm	(\(.*\)/std/algorithm/package\.d)$#\1#p')
    [[ -n $d ]] || { print -u2 "cannot find the Phobos sources $1 imports"; return 1 }
    print $d
}

# Usage: compile <dmd> <case> <flags> <output>: compile the case into output
compile() {
    local d=$1 c=$2 flags=$3 o=$4
    case $c in
        phobos|phobos-debug)
            # in a directory of its own: dmd reads a dmd.conf in the current directory
            cd $out
            local p
            p=$(phobosDir $d) || return 1
            local mods=(std/algorithm/sorting.d std/algorithm/searching.d std/format/internal/write.d
                std/regex/internal/ir.d std/regex/internal/parser.d std/regex/internal/backtracking.d
                std/uni/package.d std/datetime/systime.d std/json.d std/conv.d std/bigint.d
                std/internal/math/biguintcore.d std/math/exponential.d std/net/isemail.d std/zip.d)
            local opt=(-O -release -inline)
            [[ $c = phobos-debug ]] && opt=(-g)
            $d $=flags $opt -c -of=$o ${mods/#/$p/} ;;
        *=*=*)
            local dir=${${c#*=}%%=*} file=${c##*=}
            local cmd=$(<$file)
            cmd=${cmd#* }
            (cd $dir && eval "$d $flags ${cmd//-of[^ ]#/-of=$o}") ;;
        *) print -u2 "unknown case $c"; return 1 ;;
    esac
}

# Usage: same <a> <b> <what>: report whether two files are the same
same() {
    if cmp -s $1 $2; then
        print "  same      $3"
    else
        print "  DIFFERENT $3 ($(cmp $1 $2 2>&1 | head -1))"
        failed=1
    fi
}

for c in "$@"; do
    name=${c%%=*}
    ext=o
    [[ $c = *=*=* && $(<${c##*=}) = *" -lib"* ]] && ext=a
    print "== $name"
    for j in 1 $jobs; do
        for r in {1..$runs}; do
            o=$out/$name-j$j-$r.$ext
            # every run writes the same file, as the name of the output can be part of it
            if ! compile $dmd $c -j=$j $out/work/$name.$ext > $out/$name-j$j-$r.log 2>&1; then
                print "  FAILED    -j=$j run $r: $(tail -3 $out/$name-j$j-$r.log)"
                failed=1
                continue
            fi
            mv $out/work/$name.$ext $o
            (( r > 1 )) && same $out/$name-j$j-1.$ext $o "-j=$j run $r vs run 1"
        done
    done
    same $out/$name-j1-1.$ext $out/$name-j$jobs-1.$ext "-j=$jobs vs -j=1"
    if [[ -n $other ]]; then
        o=$out/$name-other.$ext
        if compile $other $c -j=1 $out/work/$name.$ext > $out/$name-other.log 2>&1 && mv $out/work/$name.$ext $o; then
            same $out/$name-j1-1.$ext $o "-x ${other:t} -j=1 vs -j=1"
        else
            print "  FAILED    -x ${other:t}: $(tail -3 $out/$name-other.log)"
            failed=1
        fi
    fi
done

if [[ -n $keep ]]; then
    print "outputs kept in $out"
else
    rm -rf $out
fi
exit $failed
