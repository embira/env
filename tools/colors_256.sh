#!/bin/bash

function display_256() {
    for fgbg in 38 48 ; do
        for color in {0..256} ; do
            printf "\e[${fgbg};5;${color}m ${color}\t\e[0m"
            [ $((($color + 1) % 10)) == 0 ] && echo
        done
        echo
    done
}

function display_format() {
    for clbg in {40..47} {100..107} 49 ; do
	    for clfg in {30..37} {90..97} 39 ; do
		    for attr in 0 1 2 4 5 7 ; do
			    printf "\e[${attr};${clbg};${clfg}m ^[${attr};${clbg};${clfg}m \e[0m"
		    done
		    echo
	    done
    done
}

echo
display_256

echo
display_format

exit 0
