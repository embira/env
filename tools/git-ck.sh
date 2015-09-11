#
# Input:
#   $1: command as string
#
function make_ref_list() {

    local -a _ref_list=(HEAD master)

    while read -a _line; do
        for _ref in ${_line[@]}; do
            _ref_bare=${_ref##*/}
            if [[ ! "${_ref_list[@]}" =~ "$_ref_bare" ]]; then
                _ref_list+=($_ref_bare)
            fi
        done
    done <<< $(git log --simplify-by-decoration --format='%D' --all | sed 's/,//g')

    echo ${_ref_list[@]}
}

function output_table_header() {
    printf ' commit | rev    |'
    for _ref in $@; do
        printf ' %-14.14s|' $_ref
    done
    echo
}

function output_sep_field_line() {
    printf "%${1}s+" | tr ' ' $2
}

function output_sep_line() {
    [ $# -ge 2 ] && _sep=$2 || _sep='-'

    output_sep_field_line 8 $_sep
    output_sep_field_line 8 $_sep
    for (( i=0; i<$1; i++ )); do
        output_sep_field_line 15 $_sep
    done
    echo
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

    output_sep_line $_ref_num 
    output_table_header ${_ref_list[@]}
    output_sep_line $_ref_num 

    eval $1 | while read -a _line; do
        local _cmt=${_line[0]}
        local _rev=$(git rev-list $_cmt | wc -l)

        # output commit and revision
        printf '%7s | %6s |' $_cmt $_rev

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
            printf '|'
        done

        echo
        output_sep_line $_ref_num
    done
}


REF_CMD="git log --simplify-by-decoration --pretty='%h %D' --all | sed 's/,//g'"

#git fetch
echo
output_table "$REF_CMD"
echo


#{+----------------------------------------- Embira Footer 1.7 -------+
# | vim<600:set et sw=4 ts=4 sts=4:                                   |
# | vim600:set et sw=4 ts=4 sts=4 ff=unix cindent fdm=indent fdn=1:   |
# +-------------------------------------------------------------------+}
