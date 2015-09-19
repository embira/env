#
# Input:
#   $1: pid for waiting
#
function waitpid() {
    local lpid=$1
    local lcnt=0
    local lmod=0
    local lbar=''
    local lload=''
    local lmax=500

    while :; do
        ps -p $lpid >/dev/null 2>&1 || break
        if [ $lcnt -lt $lmax ]; then
            (( lmod = lcnt % 10 ))
            [ $lmod -eq 0 ] && lbar+='.'
        fi
        (( lmod = lcnt++ % 4 ))
        case $lmod in
            0) lload='/';;
            1) lload='-';;
            2) lload="\\";;
            3) lload='|';;
        esac
        printf "Please wait %s \e[95m%s\e[0m\r" $lbar $lload
        sleep 0.1
    done

    echo -en "\033[2K" # clear current line
}

#
# Input:
#   empty
#
function print_sep_line() {
    printf '\e[94m%.1s\e[0m' '-'{0..70} $'\n'
}

#
# Input:
#   empty
#
function print_table_column() {
    printf '\e[90m|\e[0m'
}

#
# Input:
#   $1: count of seperator
#   $2: char of seperator
#
function print_field_line() {
    printf "\e[90m%${1}s+\e[0m" | tr ' ' $2
}

#
# Input:
#   $1: count of field
#   $2: char of seperator
#
function print_table_line() {
    [ $# -ge 2 ] && _sep=$2 || _sep='-'

    print_field_line 8 $_sep
    print_field_line 8 $_sep
    for (( i=0; i<$1; i++ )); do
        print_field_line 15 $_sep
    done
    echo
}

function get_current_branch() {
    git rev-parse --abbrev-ref HEAD
}

#
# Input:
#   $1 $2 ... : fields of header seperator with space
#
function print_table_header() {
    printf ' commit '
    print_table_column

    printf ' rev    '
    print_table_column

    local _crt_branch="`get_current_branch`"
    local _ref
    for _ref in $@; do
        if [ "$_crt_branch" = "$_ref" ]; then
            printf '\e[92m %-14.14s\e[0m' $_ref
        else
            printf ' %-14.14s' $_ref
        fi
        print_table_column
    done

    echo
}

#
# Input:
#   empty
#
function make_ref_list() {

    local -a _ref_list=(HEAD master)

    printf '%s' "${_ref_list[*]}"

    git log --simplify-by-decoration --format='%D' --all | sed 's/,//g' | while read -a _line; do
        for _ref in ${_line[@]}; do
            _ref_bare=${_ref##*/}
            if [[ ! "${_ref_list[@]}" =~ "$_ref_bare" ]]; then
                _ref_list+=($_ref_bare)
                printf ' %s' $_ref_bare
            fi
        done
    done
}

#
# Input:
#   $1: ref name to be found
#   $2 $3 ... : ref list
#
function find_ref() {
    local _ref
    for _ref in ${@:2}; do
        local _ref_bare=${_ref##*/}
        if [ "$_ref_bare" = "$1" ]; then
            printf '%s ' "${_ref%/*}"
        fi
    done
}

#
# Input:
#   $1: ref name to be found
#   $2 $3 ... : ref rev list with format "ref:rev"
#
function find_ref_rev() {
    local _return=0

    local _ref_rev
    for _ref_rev in ${@:2}; do
        local _ref=${_ref_rev%:*}
        if [ "$_ref" = "$1" ]; then
            _return=${_ref_rev##*:}
            break
        fi
    done
    
    echo $_return
}

#
# Input:
#   $1: command as string
#
# Output:
#   commit revision origin/ref-1    ref-2
#   commit revision ref-1           origin/ref-2
#
function output_table() {

    local -a _ref_list=($(make_ref_list))
    local _ref_num=${#_ref_list[@]}

    print_table_line $_ref_num 
    print_table_header ${_ref_list[@]}
    print_table_line $_ref_num 

    local -a _ref_rev_list # (ref:rev ...)
    eval $1 | while read -a _line; do
        local _cmt=${_line[0]}
        local _rev=$(git rev-list $_cmt | wc -l | tr -d ' ')

        # print out commit
        printf '\e[33m%7s\e[0m ' $_cmt
        print_table_column

        # print out revision
        printf ' %6s ' $_rev
        print_table_column

        # print out ref with table control by ref name list
        local _ref_label
        local _ref_rev=0
        for _ref_name in ${_ref_list[@]}; do
            _ref_label="`find_ref $_ref_name ${_line[@]:1}`"
            if [ -z "$_ref_label" ]; then
                printf '%15s' ' '
            else
                _ref_rev=`find_ref_rev $_ref_name ${_ref_rev_list[@]}`
                if [ $_ref_rev -gt 0 ]; then
                    printf '\e[0;49;38;5;167m %-14.14s\e[0m' "$_ref_label($(($_rev - $_ref_rev)))"
                else
                    _ref_rev_list+=("$_ref_name:$_rev")
                    printf ' %-14.14s' "$_ref_label"
                fi
            fi
            print_table_column
        done
        echo

        print_table_line $_ref_num
    done
}


######################################################################

echo
echo 'git fetch: download objects and refs from remote repository'
print_sep_line
#git fetch &
waitpid $!
echo

echo 'git status: show the working tree status'
print_sep_line
git status
echo

echo
echo 'git log: show the refs map'
print_sep_line
REF_CMD="git log --simplify-by-decoration --pretty='%h %D' --all | sed 's/,//g'"
output_table "$REF_CMD"
echo


#{+----------------------------------------- Embira Footer 1.7 -------+
# | vim<600:set et sw=4 ts=4 sts=4:                                   |
# | vim600:set et sw=4 ts=4 sts=4 ff=unix cindent fdm=marker fmr={,}: |
# +-------------------------------------------------------------------+}
