#!/bin/sh
# Add footer into exited files
# $Id: footer.sh 131373 2012-07-26 09:15:44Z daniel $
# $1: style <c|m|h|sh|mk|xml|php>
#----------------------------------------
FT_L1="<+----------------------------------------- Embira Footer 1.6 ---------+"
FT_L3=" | vim600:set et sw=4 ts=4 sts=4 ff=unix cindent fdm=marker fmr=<+,+>: |"
FT_L6=" | vim600:set noet sw=4 ts=4 sts=4 si fdm=marker fmr=<+,+>:            |"
FT_L8=" | vim600:set et sw=2 ts=2 sts=2 si fdm=marker fmr=<+,+>:              |"
FT_L4=" +---------------------------------------------------------------------+>"
FT_LH="{+----------------------------------------- Embira Footer 1.6 ---------+"
FT_L2=" | vim<600:set et sw=4 ts=4 sts=4:                                     |"
FT_LC=" | vim600:set et sw=4 ts=4 sts=4 ff=unix cindent fdm=marker fmr={,}:   |"
FT_L5=" | vim<600:set noet sw=4 ts=4 sts=4:                                   |"
FT_L7=" | vim<600:set et sw=2 ts=2 sts=2:                                     |"
FT_L9=" | vim600:set et sw=2 ts=2 sts=2 si fdm=marker fmr={,}:                |"
FT_LE=" +---------------------------------------------------------------------+}"

#----------------------------------------
# Shell Function
# $1: file
usage() {
    echo -e "Usage:\n\t`basename $0` <c|m|h|sh|mk|xml|php|css|java>\n"
}

#----------------------------------------
# Shell Function
add_c_comment() {
    echo ""
    echo -e "/*$FT_LH"
    echo -e "  $FT_L2"
    echo -e "  $FT_LC"
    echo -e "  "$FT_LE"*/"
}

#----------------------------------------
# Shell Function
add_sh_comment() {
    echo ""
    echo -e "#$FT_LH"
    echo -e "#$FT_L2"
    echo -e "#$FT_LC"
    echo -e "#$FT_LE"
}

#----------------------------------------
# Shell Function
add_mk_comment() {
    echo ""
    echo -e "#$FT_L1"
    echo -e "#$FT_L5"
    echo -e "#$FT_L6"
    echo -e "#$FT_L4"
}

#----------------------------------------
# Shell Function
add_xml_comment() {
    HEADER=`echo $FT_L1 | sed -e 's/[\<|+|-]//g'`
    echo ""
    echo -e "<!--<+$HEADER"
    echo -e $FT_L7 | sed -e 's/ *|//g'
    echo -e $FT_L8 | sed -e 's/ *|//g'
    echo -e "+>-->"
}

#----------------------------------------
# Shell Function
add_php_comment() {
    HEADER=`echo $FT_L1 | sed -e 's/[\<|+|-]//g'`
    echo ""
    echo -e "#$HEADER{"
    echo -e "#$FT_L2" | sed -e 's/ *|/  /g'
    echo -e "#$FT_LC" | sed -e 's/ *|/  /g'
    echo -e "# }"
    echo "?>"
}

#----------------------------------------
# Shell Function
add_css_comment() {
    HEADER=`echo $FT_L1 | sed -e 's/[\<|+|-]//g'`
    echo ""
    echo -e "/*$HEADER {"
    echo -e $FT_L7 | sed -e 's/ *| *//g'
    echo -e $FT_L9 | sed -e 's/ *| *//g'
    echo -e '} */'
}

#----------------------------------------
if (test $# -eq 0); then                    #test arg
    usage
    exit 1
fi

if (test $1 = 'c' -o $1 = 'm' -o $1 = 'h' -o $1 = 'java' ); then # add c,m,h style comment
    add_c_comment
elif (test $1 = 'sh'); then                 # add sh style comment
    add_sh_comment
elif (test $1 = 'mk'); then                 # add mk style comment
    add_mk_comment
elif (test $1 = 'xml'); then                # add xml style comment
    add_xml_comment
elif (test $1 = 'php'); then                # add php style comment
    add_php_comment
elif (test $1 = 'css'); then                # add css style comment
    add_css_comment
else
    usage
    exit 1
fi

exit 0

#<+----------------------------------- Embira Footer 1.0 ---+
# | vim<600:set et sw=4 ts=4 sts=4:                         |
# | vim600:set et sw=4 ts=4 sts=4 fdm=marker fmr=<+,+>:     |
# +---------------------------------------------------------+>
