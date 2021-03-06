#!/bin/sh
# Created at: 2013-08-07 08:43:06
#-------------------------------------------------------------


# user name & email
read -p 'Please enter user name: ' name
[ -n "$name" ] && {
    git config --global user.name   $name
}
read -p 'Please enter email: ' email
[ -n "$email" ] && {
    git config --global user.email  $email
}

# push for git 2.0
git config --global push.default matching

# editor
git config --global core.editor vim
git config --global merge.tool  vimdiff

# color
git config --global color.branch        auto
git config --global color.diff          auto
git config --global color.interactive   auto
git config --global color.status        auto
git config --global color.ui            true

# file name with NO-ASCII code
git config --global core.quotepath      false

# aliases
git config --global alias.alias 'config --get-regexp alias'
git config --global alias.co    checkout
git config --global alias.ci    commit
git config --global alias.st    status
git config --global alias.br    'branch --all'
git config --global alias.us    'reset HEAD --' # unstage
git config --global alias.last  "!last() { [ \$# -eq 0 ] && num=1 || num=\$1; git log HEAD --graph --name-status -\$num; }; last"
git config --global alias.lg    'log --pretty=format:"%C(auto)%h - %Cblue%ai%C(reset) - %<(10,trunc)%C(magenta)%an%C(reset) : %Cgreen%s%C(reset) %d"'
git config --global alias.lr    'log --simplify-by-decoration --pretty=format:"%C(auto)%h - %Cblue%ai%C(reset) - %<(10,trunc)%C(magenta)%an%C(reset) : %<(35,trunc)%Cgreen%s%C(reset) %d"'
git config --global alias.ck    '!ck() { sh ~/bin/git-ck.sh; }; ck'

# ignore
cwd="$(readlink -e $0 | xargs dirname)" && {
    gign="${cwd%/*}/etc/gitignore"
    [ -e $gign ] && {
        ln -sf $gign ~/.gitignore
        git config --global core.excludesfile ~/.gitignore
    }
}

# confirm
echo -e '\nResult: '
printf '%.01s' '-'{0..60} $'\n'
git config --global --list
echo
ls -lh --color ~/.gitignore
echo

#{+----------------------------------------- Embira Footer 1.6 ---------+
# | vim<600:set et sw=4 ts=4 sts=4:                                     |
# | vim600:set et sw=4 ts=4 sts=4 ff=unix cindent fdm=marker fmr={,}:   |
# +---------------------------------------------------------------------+}
