#!/bin/sh
# $Id$
# Created at: 2013-10-16 14:35:12
#-------------------------------------------------------------

# Validation
#-------------------------------------------------------------
# Validate system version
if ! grep -i 'Amazon Linux AMI' /etc/system-release >/dev/null; then
    echo -e '\nOnly for Amazon Linux AMI.'
    echo -e "But this system is `cat /etc/system-release`.\n"
    exit 1
fi
# Validate system platform
if [ "`uname -i`" != 'x86_64' ]; then
    echo -e '\nOnly for x86_64 platform.'
    echo -e "But this platform is `uname -i`.\n"
    exit 1
fi
# Validate user permission
[ 'root' = "$USER" ] || { echo -e '\nTry sudo!\n'; exit 1; }

# Global setting
#-------------------------------------------------------------
function pdate() {
    echo
    printf '%.1s' '-'{0..50}
    echo "---[`date +'%Y%m%d-%H:%M:%S'`]---"
}

# $1: message
# return 0 for yes or 1 for no
function pask() {
    local lflag
    while :; do
        read -p "$1 ... [y/n]? " lflag
        if [ 'y' = "$lflag" ]; then
            return 0
        elif [ 'n' = "$lflag" ]; then
            echo 'Skip.'
            return 1
        else
            echo 'Please enter "y" to continue or "n" to skip.'
        fi
    done
}

# $1: message
function errmsg() {
    echo -e "\e[91m$1\e[0m"
}

# $1: pid for waiting
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

export LANG='en_US.UTF-8'
echo
echo -e '                 Installation of \e[92mBaseline 4.x\e[0m'
echo -e '            \e[4mFor \e[94mAmazon Linux AMI based RHEL x86_64\e[0m'
echo
echo ' This script will initially install some application packages'
echo " from the yum repositories. And it will modify some system's"
echo ' default configuration to customize to baseline 4.x.'
echo -en '\e[96m'
printf '%.1s' '='{0..61}
echo -e '\e[0m'
echo

# Create pre-defined groups
#-------------------------------------------------------------

# $1: group name
# $2: group id
function createGroup() {
    echo
    if getent group $1; then
        echo "Group [$1] already exists."
    else
        if groupadd $1 -g $2; then
            getent group $1
        else
            errmsg "Error: Create group [$1:$2] failed!"
        fi
    fi
}

pdate
if pask 'Create pre-defined groups: program, normal, maintenance'; then
    createGroup program     1001
    createGroup normal      2001
    createGroup maintenance 3001
fi

# Install application packages by yum
#-------------------------------------------------------------
pdate
if pask 'Install application packages'; then
    echo -e '\nInstall \e[92msystem utilities\e[0m ...'
    yum -y install openssh-clients sysstat iotop htop tmux tree subversion git vim-enhanced yum-utils sendmail-cf curl wget
    echo -e '\nInstall \e[92mnetwork utilities\e[0m ...'
    yum -y install jwhois telnet
    echo -e '\nInstall \e[92mhttpd\e[0m and setup \e[92mapache\e[0m ...'
    yum -y install httpd && chkconfig httpd on && usermod -G program apache || errmsg 'Error: install httpd failed!'
    echo -e '\nInstall \e[92mmysql-server\e[0m ...'
    yum -y install mysql-server
    echo -e '\nInstall \e[92mphp\e[0m and \e[92mphp modules\e[0m ...'
    yum -y install php php-cli php-common php-mbstring php-mysql php-pdo php-xml php-pear php-pecl-memcache php-pecl-apc
    echo -e '\n\e[4mConfirm http and apache status\e[0m\n'
    id apache
    chkconfig --list httpd
    service httpd status
fi

# Setup system default language
#-------------------------------------------------------------
pdate
if pask 'Set system default language to en_US.UTF-8'; then
    sed -i -e 's/LANG=.*/LANG="en_US.UTF-8"/' /etc/sysconfig/i18n || errmsg 'Error: failed!'
    echo
    cat /etc/sysconfig/i18n
fi

# Enable sudo for wheel group
#-------------------------------------------------------------
pdate
if pask 'Allow people in group wheel to run as root'; then
    grep -i -e  "^\s*wheel\s\+ALL=(ALL)\s\+ALL\s*$" /etc/sudoers || {
        sed -i -e "s/^#[ \t]*\(%wheel[ \t]\+ALL=(ALL)[ \t]\+ALL\)[ \t]*/\1/" /etc/sudoers || errmsg 'Error: failed!'
        echo
        grep -e "^\s*%wheel" /etc/sudoers
    }
fi

# Disable root remote ssh login
#-------------------------------------------------------------
pdate
if pask 'Disable root remote ssh login'; then
    sshopt="`grep -e '^\s*PermitRootLogin' /etc/ssh/sshd_config | tail -1 | awk '{print $2}'`"
    if [ "$sshopt" = 'no' -o "$sshopt" = 'forced-commands-only' ]; then
        echo
        echo "PermitRootLogin $sshopt"
        echo 'Disabled already.'
    else
        if [ -z "$sshopt" ]; then
            sed -i -e 's/^#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
        else
            sed -i -e 's/^\s*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
        fi
        echo
        grep -e '^\s*PermitRootLogin' /etc/ssh/sshd_config
        if [ $? -eq 0 ]; then
            echo
            service sshd restart
        else
            errmsg 'Error: failed!'
        fi
    fi
fi

# Disable SELinux
#-------------------------------------------------------------
which getenforce >/dev/null 2>&1 && {
    pdate
    if pask 'Disable SELinux'; then
        sed -i -e 's/^SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config || errmsg 'Error: failed!'
        echo
        cat /etc/selinux/config | grep -v '^[ \t]*$' | grep -v '^#'
    fi
}

# Set timezone
#-------------------------------------------------------------
pdate
if pask 'Set timezone to Japan'; then
    zoneinfo='/usr/share/zoneinfo/Japan'
    echo
    if [ -e $zoneinfo ]; then
        ln -sf $zoneinfo /etc/localtime
    else
        errmsg "$zoneinfo does not exist!" 
    fi
    date +'Timezone: %Z %:z'
fi


# Setup sendmail
#-------------------------------------------------------------
pdate
if pask 'Setup sendmail'; then
    ret=0
    domain='clever-rock.com'
    if grep $domain /etc/mail/submit.cf | grep -v '^#' >/dev/null 2>&1; then
        echo -e "\nThe sendmail is already built for $domain."
        pask 'Do you want to build again' || ret=1 # skip
    fi
    if [ $ret -eq 0 ]; then
        if ! grep $domain /etc/mail/submit.mc | grep -v '^#' >/dev/null 2>&1; then
            sed -i -e "s/^\(FEATURE(\`msp', \`\[127.0.0.1\]')dnl\)$/MASQUERADE_AS(\`$domain')dnl\nFEATURE(\`masquerade_envelope')dnl\n\1/" /etc/mail/submit.mc
            ret=$?
        fi
        if [ $ret -eq 0 ]; then
            echo
            cat /etc/mail/submit.mc | grep -v '^#' | grep -v '^[ \t]*$'
            echo
            if pask 'make submit.cf'; then
                /etc/mail/make submit.cf || errmsg 'Error: make failed!'
            fi
        else
            errmsg 'Error: modify /etc/mail/submit.mc failed!'
        fi
    fi
    echo -e '\nRun level of sendmail:'
    chkconfig sendmail on
    chkconfig --list sendmail
    echo -e '\nRestart sendmail:'
    service sendmail restart
fi

# Stop unuseful services
#-------------------------------------------------------------
function stopsrv() {
    echo -e "Stop service [\e[92m$1\e[0m]:"
    printf '%.1s' '~'{0..70} $'\n'
    service $1 stop
    service $1 status
    chkconfig $1 off
    chkconfig --list $1
    printf '%.1s' '~'{0..70} $'\n'
    echo
}
pdate
if pask 'Stop unuseful services'; then
    echo
    stopsrv atd
    stopsrv auditd
    stopsrv acpid
    stopsrv ip6tables
    stopsrv iptables
    stopsrv mdmonitor
    stopsrv messagebus
    stopsrv netfs
fi

# Create default user
#-------------------------------------------------------------
pdate
if pask 'Create pre-defined user'; then
    while :; do
        read -p 'Username: ' username
        [ -n "$username" ] && break
    done
    while :; do
        read -p 'Userid: ' uid
        [ -n "$uid" ] && break
    done
    while :; do
        read -s -p 'Password: '        passwd
        echo
        read -s -p 'Password again:'   passwd2
        echo
        if [ "$passwd" = "$passwd2" ]; then
            break
        else
            echo 'Sorry, passwords do not match. Try again.'
        fi
    done
    echo
    if pask "Create name=$username uid=$uid groups=normal,wheel"; then
        useradd -m -g normal -G wheel -s `which bash` -u $uid -p `openssl passwd -1 $passwd` $username
        if [ $? -eq 0 ]; then
            echo
            id $username
            echo 'Install OK.'
        else
            echo
            errmsg "Error: Create user($username:$uid) failed!"
            echo "Please do it by manually."
        fi
    fi
fi

pdate
echo 'Setup accomplished.'
echo

#{+----------------------------------------- Embira Footer 1.6 -----+
# | vim<600:set et sw=4 ts=4 sts=4:                                 |
# | vim600:set et sw=4 ts=4 sts=4 ff=unix cindent fdm=indent fdn=1: |
# +-----------------------------------------------------------------+}
