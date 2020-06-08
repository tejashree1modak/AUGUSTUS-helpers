#!/bin/bash
PROG="${0##*/}"

help() {
    echo -e "$PROG [options] <Agustus gff>\n"
    echo "Options:"
    echo "-c <coding file>    Output file for CDS fasta"
    echo "-p <coding file>    Output file for protein fasta"
    exit 0
}

while getopts "c:p:h" arg ; do
    case "$arg" in
        c)  cfile="$OPTARG" ;;
        p)  pfile="$OPTARG" ;;
        *)  help ;;
    esac
done

shift $((OPTIND-1))

# pre-process the file to "join" all coding and protein sequences
# output will be
# >gene1
# coding <coding-sequence>
# protein <protein-sequence>
# coding <coding-sequence>
# protein <protein-sequence>
# ....
# >gene2
# ...
awk '/^# start gene g/ {
    print ">" $NF
    f = ""
}

/^# (coding|protein) sequence/ {
    f = $NF
    t = $2
}

length(f) && $1 == "#" && NF == 2 {
    f = f $NF
    if ($NF ~ /\]$/) {
        print t, f; f = ""
    }
} ' $1  | tr -d '[]' > preprocessed

# after that Pick the gene line and the first two coding and protein lines
# and write then out
awk -v pfile=$3 -v cfile=$2 'BEGIN {
    pfile = !length(pfile) ? "protein.fasta" : pfile;
    printf "" > pfile
    cfile = !length(cfile) ? "coding.fasta" : cfile;
    printf "" > cfile
}

NF == 1 {
    gene = $1
    c = p = 0
}

$1 == "coding" && c == 0 {
    print gene "\n" $NF >> cfile
    c++;
}

$1 == "protein" && p == 0 {
    file = $1 ".fasta"
    print  gene "\n" $NF >> pfile
    p++;
} ' preprocessed
