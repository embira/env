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

#
# Input:
#   $1 $2 ... : fields of header seperator with space
#
function print_table_header() {
    printf ' commit '
    print_table_column

    printf ' rev    '
    print_table_column

    for _ref in $@; do
        printf ' %-14.14s' $_ref
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

    eval $1 | while read -a _line; do
        local _cmt=${_line[0]}
        local _rev=$(git rev-list $_cmt | wc -l)

        # print out commit
        printf '%7s ' $_cmt
        print_table_column

        # print out revision
        printf ' %6s ' $_rev
        print_table_column

        # print out ref with table control by ref name list
        for _ref_name in ${_ref_list[@]}; do
            local _found=0
            for _ref in ${_line[@]:1}; do
                _ref_bare=${_ref##*/}
                if [ "$_ref_bare" = "$_ref_name" ]; then
                    _found=1
                    printf ' %-14.14s' "${_ref%/*}"
                    break
                fi
            done
            [ $_found -eq 0 ] && printf '%15s' ' '
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
echo
REF_CMD="git log --simplify-by-decoration --pretty='%h %D' --all | sed 's/,//g'"
output_table "$REF_CMD"
echo


#{+----------------------------------------- Embira Footer 1.7 -------+
# | vim<600:set et sw=4 ts=4 sts=4:                                   |
# | vim600:set et sw=4 ts=4 sts=4 ff=unix cindent fdm=marker fmr={,}: |
# +-------------------------------------------------------------------+}
