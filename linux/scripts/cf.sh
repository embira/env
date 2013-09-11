#!/bin/sh
# Create a c/c+ style file and add header & footer.
# $Id: cf.sh 131373 2012-07-26 09:15:44Z daniel $
# $1: file name
# $2: style c, sh, mk, ...
#----------------------------------------
usage() {
    echo -e "Usage:\n\t`basename $0` filename [c|m|h|sh|mk|php|css|java]\n"
}

#----------------------------------------
# $1: style c, sh, mk, ...
# $2: header macro
echo_header() {
    DATE=`date "+%Y-%m-%d %H:%M:%S"`
    if (test $1 = 'c' -o $1 = 'm' -o $1 = 'h'); then # c,m,h style header
        echo -e "\
/*\n\
 * Created at: $DATE\n\
 *\n\
 * \$Id:\$\n\
 */\n"
        if (test $1 = 'h'); then
            HEADER="__EMBIRA_$2__"
            echo -e "\
#ifndef $HEADER\n\
#define $HEADER\n\n\
#endif /* !$HEADER */"
        fi
    elif (test $1 = 'sh'); then             # sh style header
        echo -e "\
#!/bin/sh\n\
# \$Id:\$\n\
# Created at: $DATE\n\
#-------------------------------------------------------------\n"
    elif (test $1 = 'mk'); then             # mk style header
        echo -e "\
# \$Id:\$\n\
# Created at: $DATE\n\
#-------------------------------------------------------------\n"
    elif (test $1 = 'php'); then            # php style header
        echo -e "\
<?php
# \$Id:\$\n\
# Created at: $DATE\n\
#-------------------------------------------------------------\n"
    elif (test $1 = 'css'); then            # css style header
        echo -e "\
/*\n\
 * \$Id:\$\n\
 * Create at: $DATE\n\
 */\n"
    elif [ $1 = 'java' ]; then
        echo -e "\
/**\n\
 * \$Id: \$\n\
 * Create at: $DATE\n\
 */\n"                                      # java style header
    else                                    # unknown
        echo 'no support'
    fi
}

#----------------------------------------
if (test $# -eq 0); then
    usage
    exit 1
elif (test $# -eq 1); then
    FLAG=${1#*.}
else
    FLAG=$2
fi

if (test -e $1); then
    echo -e "$1 exists.\n"
    exit 1
fi

if (test $FLAG != 'ca'\
    -a $FLAG != 'm'\
    -a $FLAG != 'h'\
    -a $FLAG != 'sh'\
    -a $FLAG != 'mk'\
    -a $FLAG != 'php'\
    -a $FLAG != 'css'\
    -a $FLAG != 'java'); then
    usage
    exit 1
fi

touch $1
if (test $? -eq 0); then
    HEADER=`echo $1 | sed -e 's/\./_/g' | awk '{print(toupper($0))}'`
    echo_header $FLAG $HEADER >> $1
    $(dirname $0)/footer.sh $FLAG >> $1
else
    echo -e "touch $1 failed!\n"
fi

exit 0

#<+----------------------------------- Embira Footer 1.0 ---+
# | vim<600:set et sw=4 ts=4 sts=4:                         |
# | vim600:set et sw=4 ts=4 sts=4 fdm=marker fmr=<+,+>:     |
# +---------------------------------------------------------+>
