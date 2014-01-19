#!/bin/sh
# $Id: bwo.sh 26271 2009-02-02 03:50:51Z daniel $
# Created at: 2007-04-19 21:17:42
#-------------------------------------------------------------
# $1: <release|debug|clean>

#-------------------------------------------------------------
usage() {
    echo -e "Usage:\n\t`basename $0` <release|debug|clean> [configure_options] ...\n"
}

#-------------------------------------------------------------
# $1: arguments
CONF_OPT=""
gen_conf_opt() {
    i=0
    for opt in $1; do
        if (test $i -eq 0); then
            i=1
            continue # skip argv1 
        fi
        CONF_OPT="$CONF_OPT $opt"
    done
}

#-------------------------------------------------------------
if (test $# -eq 0); then
    usage
    exit 1
fi

if (test $1 != "release" -a $1 != "debug" -a $1 != "clean"); then
    usage
    exit 1
fi

if (test $1 = "clean"); then
    echo "=======> clean up ..."
    gmake distclean
    rm -fr Makefile config.* libtool aclocal.m4 depcomp ltmain.sh Makefile.in autom4te.cache configure install-sh missing
    find . -name "*.in" -delete
    exit 0;
fi

if !(test -r "./Makefile"); then
    if !(test -r "./configure"); then
        echo "=======> autoreconf -i ..."
        autoreconf -i
        if (test $? -ne 0); then
            echo "=======> autoreconf failed!"
            exit 1
        fi
    fi
    gen_conf_opt "$*"
    echo "=======> ./configure $CONF_OPT ..."
    ./configure $CONF_OPT
    if (test $? -ne 0); then
        echo "=======> configure failed!"
        exit 1
    fi
fi

if (test $1 = "release"); then
    gmake clean
    echo '=======> gmake CXXFLAGS="-g -O2 -DNDEBUG" ...'
    gmake CXXFLAGS="-g -O2 -DNDEBUG"
elif (test $1 = "debug"); then
    gmake clean
    echo '=======> gmake CXXFLAGS=-g LDFLAGS= ...'
    gmake CXXFLAGS=-g LDFLAGS=
else
    usage
    exit 1
fi

if (test $? -ne 0); then
    echo "=======> Failed!"
    exit 1
else
    echo "=======> OK!"
    exit 0
fi

#<+----------------------------------- Embira Footer 1.0 ---+
# | vim<600:set et sw=4 ts=4 sts=4:                         |
# | vim600:set et sw=4 ts=4 sts=4 fdm=marker fmr=<+,+>:     |
# +---------------------------------------------------------+>
