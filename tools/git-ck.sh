#
# Input:
#   $1: command as string
#
# Output:
#   commit revision origin/ref-1    ref-2
#   commit revision ref-1           origin/ref-2
#
function output_table() {

    local -a _ref_list=(HEAD master)

    eval $1 | while read -a _line; do
        local _cmt=${_line[0]}
        local _rev=$(git rev-list $_cmt | wc -l)

        # output commit and revision
        printf '%s | %6s | ' $_cmt $_rev

        # make ref list for print controling
        for _ref in ${_line[@]:1}; do
            _ref_bare=${_ref##*/}
            # add all refs into to ref name list
            if [[ ! "${_ref_list[@]}" =~ "$_ref_bare" ]]; then
                _ref_list+=($_ref_bare)
            fi
        done

        # print out ref with table control by ref name list
        for _ref_name in ${_ref_list[@]}; do
            local _found=0
            for _ref in ${_line[@]:1}; do
                _ref_bare=${_ref##*/}
                if [ "$_ref_bare" = "$_ref_name" ]; then
                    _found=1
                    printf '%-15.15s' "$_ref"
                    break
                fi
            done
            [ $_found -eq 0 ] && printf '%15s' ' '
            printf '|'
        done

        echo
    done
}


REF_CMD="git log --simplify-by-decoration --pretty='%h %D' --all | sed 's/,//g'"

#git fetch
output_table "$REF_CMD"


#{+----------------------------------------- Embira Footer 1.7 -------+
# | vim<600:set et sw=4 ts=4 sts=4:                                   |
# | vim600:set et sw=4 ts=4 sts=4 ff=unix cindent fdm=indent fdn=1:   |
# +-------------------------------------------------------------------+}
