#!/bin/sh
# Created at: 2013-08-26 13:59:28
#-------------------------------------------------------------

# $1: source file
# $1: destination name
function mkLink() {
    [ $# -lt 2 ] && { echo 'Error: Invalid arguments!'; return 1; }
    [ -e $1 ] || { echo "Error: [$1] does not exist!"; return 1; }
    ln -sf $1 $2 || { echo "Error: ln -sf [$1] [$2] failed!"; return 1; }
}

function mkVimColorScheme() {
    local tmpclr="$HOME/tmp/colors"
    mkdir -p $tmpclr
    wget https://github.com/flazz/vim-colorschemes/archive/master.zip -O $tmpclr/colors.zip
    unzip $tmpclr/colors.zip -d $tmpclr >/dev/null 2>&1
    mkdir -p $HOME/.vim/colors
    find $tmpclr -name *.vim -exec cp {} $HOME/.vim/colors/ \;
    rm -fr $tmpclr
}

cwd="$(readlink -e $0 | xargs dirname)"

# create etc links
mkLink $cwd/etc/bashrc      $HOME/.bashrc
mkLink $cwd/etc/vimrc       $HOME/.vimrc
mkLink $cwd/etc/tmux.conf   $HOME/.tmux.conf

# create bin links
[ -e $cwd/scripts ] && {
    mkdir -p $HOME/bin && ln -sf $cwd/scripts/*.sh $HOME/bin/
}

# make git config
[ -e $HOME/bin/gitcfg.sh ] && {
    read -p 'Do you want to config git? [y/n]:' flag
    [ "$flag" = 'y' ] && sh $HOME/bin/gitcfg.sh || echo 'Skip.'
}

# make svn config
# TODO

# make vim color scheme
read -p 'Do you want to install vim color scheme? [y/n]:' flag
[ "$flag" = 'y' ] && mkVimColorScheme || echo 'Skip.'

# mkdir dir_colors
dircolors -p | grep xterm-256color >/dev/null 2>&1 || {
    echo -e '# Add xterm-256color\nTERM xterm-256color\n' > $HOME/.dir_colors
    dircolors -p >> $HOME/.dir_colors
 }

echo -e '\nOver. \nThe ~/.bashrc should be reaload.\n'

#{+----------------------------------------- Embira Footer 1.6 ---------+
# | vim<600:set et sw=4 ts=4 sts=4:                                     |
# | vim600:set et sw=4 ts=4 sts=4 ff=unix cindent fdm=marker fmr={,}:   |
# +---------------------------------------------------------------------+}
