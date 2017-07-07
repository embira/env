#!/bin/sh
# $Id: setup_baseline.sh 166788 2013-11-03 11:32:02Z daniel $
# Created at: 2013-10-16 14:35:12
#-------------------------------------------------------------

# Validation
#-------------------------------------------------------------
# Validate system version
if ! grep -ie '.*CentOS.* 6.[0-9]\+ .*' /etc/system-release >/dev/null; then
    echo -e '\nOnly for CentOS 6.x .'
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
echo -e '                  \e[4mbased on \e[92mCentOS 6.x x86_64\e[0m'
echo
echo ' This script will initially install some application packages'
echo " from the yum repositories. And it will modify some system's"
echo ' default configuration to customize to baseline 4.x.'
echo -en '\e[96m'
printf '%.1s' '='{0..61}
echo -e '\e[0m'
echo

# Install Citrix XenServer Tools
#-------------------------------------------------------------
function instXenServerTools() {
    echo
    while :; do
        if mountpoint /mnt >/dev/null 2>&1; then
            if [ -e /mnt/Linux/install.sh ]; then
                break
            else
                echo -e '\nThe mount media is invalid!'
            fi
        else
            if mount /dev/xvdd/ /mnt; then
                continue
            else
                echo -e '\nThe DVD drive is invalid.'
            fi
        fi
        pask 'Please insert the XenServer Tools DVD by XenCenter\nReady' || return 0
    done
    /mnt/Linux/install.sh
    ret=$?
    umount /mnt
    return $ret
} 

if [ -e /proc/xen ]; then
    pdate
    xgu="`rpm -qa | grep xe-guest-utilities`"
    if [ -z "$xgu" ]; then
        if pask 'Install XenServer Tools'; then
            instXenServerTools
        fi
    else
        echo "The following XenServer Tools is already installed."
        echo
        echo -e "$xgu"
        echo
        if pask 'Do you want to upgrade or install again'; then
            instXenServerTools
        fi
    fi
fi

# Install VirtualBox Guest Additions
#-------------------------------------------------------------
function isVirtualBox() {
    lsmod | grep -i vboxguest >/dev/null 2>&1
    return $?
}

function hasVBoxGuestAdditions() {
    service vboxadd status >/dev/null 2>&1
    return $?
}

function instVBoxGuestAddinitions() {
    echo
    while :; do
        if mountpoint /mnt >/dev/null 2>&1; then
            if [ -e /mnt/VBoxLinuxAdditions.run ]; then
                break;
            else
                echo -e '\nThe mount media is invalid'
            fi
        else
            if mount /dev/cdrom /mnt; then
                continue;
            else
                echo -e '\nThe CD/DVD drive is invalid.'
            fi
        fi
        pask 'Please insert the VirtualBox Guest Additions CD/DVD\nReady' || return 0
    done
    sh /mnt/VBoxLinuxAdditions.run
    ret=$?
    umount /mnt
    return $ret
}

function setNetwork() {
    eth0='/etc/sysconfig/network-scripts/ifcfg-eth0'
    eth1='/etc/sysconfig/network-scripts/ifcfg-eth1'
    sed -i -e 's/ONBOOT=.*/ONBOOT=yes/; s/BOOTPROTO=.*/BOOTPROTO=dhcp/' $eth0
    sed -i -e 's/ONBOOT=.*/ONBOOT=yes/; s/BOOTPROTO=.*/BOOTPROTO=static/' $eth1
    echo -e "IPADDR=192.168.56.2\nNETMASK=255.255.255.0" >> $eth1
    ifconfig eth0 up
    ifconfig eth1 up
}

if isVirtualBox; then
    pdate
    if hasVBoxGuestAdditions; then
        echo 'The following VirtualBox Guest Additions are already installed.'
        echo
        service --status-all | grep -i 'vbox\|virtualbox'
        echo
        if pask 'Do you want to upgrade or re-install'; then
            instVBoxGuestAdditions
        fi
    else
        if pask 'Install VirtualBox Guest Additions'; then
            instVBoxGuestAdditions
        fi
    fi
    if pask 'Set network for guest in VirtualBox'; then
        if setNetwork; then
            route
        else
            errmsg 'Error: Set network failed!'
        fi
    fi
fi

# Disable IPv6
#-------------------------------------------------------------
pdate
function seg() {
    echo -e "\n[\e[92m$1\e[0m]"
    printf '%.1s' -{0..30} $'\n'
}
function conf_stat() {
    printf '%-45s = '  "$1"
    [ -e $1 ] && cat $1 || echo 'none'
}
if pask 'Disable IPv6'; then
    conf_all='net.ipv6.conf.all.disable_ipv6'
    conf_def='net.ipv6.conf.default.disable_ipv6'
    /sbin/sysctl -w "$conf_all=1"
    /sbin/sysctl -w "$conf_def=1"
    conf_file='/etc/modprobe.d/disable-ipv6.conf'
    if echo 'options ipv6 disable=1' > $conf_file; then
        echo -e "\nConfirm:"
        seg '/sbin/ip -6 addr'
        [ -z "`ip -6 addr`" ] && echo 'No ipv6 address.'
        seg '/proc/sys/net/ipv6/conf/'
        conf_stat '/proc/sys/net/ipv6/conf/all/disable_ipv6'
        conf_stat '/proc/sys/net/ipv6/conf/default/disable_ipv6'
        seg '/etc/sysctl.conf'
        grep -i ipv6 /etc/sysctl.conf || echo 'No ipv6 entry.'
        seg '/etc/sysconfig/network'
        grep -i ipv6 /etc/sysconfig/network || echo 'No ipv6 entry.'
        seg '/etc/modprobe.d/*'
        grep -i ipv6 /etc/modprobe.d/* || echo 'No ipv6 entry.'
    else
        errmsg "Error: Cannot create [$conf_file]!"
    fi
fi

# Create pre-defined groups
#-------------------------------------------------------------
## $1: group name
## $2: group id
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

# Install yum plugins
#-------------------------------------------------------------
pdate
if pask 'Install yum plugins'; then
    yum -y install yum-plugin-fastestmirror yum-plugin-security yum-plugin-priorities
    ret=$?
    echo
    tail -n +1 /etc/yum/pluginconf.d/*.conf | grep -v '^#'
    [ $ret -eq 0 ] && { echo -e '\nInstall OK.\n'; } || { echo; errmsg 'Error: install failed!'; echo; }
fi

# Install yum repositories and set priority
#-------------------------------------------------------------
function setPriority() {
    repo="/etc/yum.repos.d/$1"
    if [ -e $repo ]; then
        sed -i -e "s/^\(\[.*\]\) *$/\1\npriority = $2/" $repo || errmsg "Error: set priority failed for [$repo]!"
    else
        errmsg "Error: [$repo] does not exist!"
    fi
}

pdate
if pask 'Install yum repositories and set priority'; then
    yrp="`sed -n -e "/^\[/h; /priority *=/{ G; s/\n/ /; s/ity=/ity = /; p }" /etc/yum.repos.d/*.repo | sort -k3n`"

    if [ -n "$yrp" ]; then
        echo -e '\nThe priorities had already been set:'
        echo -e "\n$yrp\n"
        pask 'Do you want to reset again' && yrp='' # clear yrp for reset
    fi

    if [ -z "$yrp" ]; then
        rm -f /tmp/*.rpm
        sed -i -e 's/^priority[ \t]*=.*//' /etc/yum.repos.d/*.repo # clear priorities
        # set priority for CentOS-Base.repo
        echo -e '\nSet priority for \e[92mCentOS-Base\e[0m ...'
        repo='/etc/yum.repos.d/CentOS-Base.repo'
        sed -i -e 's/^\[\(base\|updates\|extras\)\] *$/\[\1\]\npriority = 1/; s/\[\(centosplus\|contrib\)\]/\[\1\]\n\priority = 2/' $repo
        [ $? -eq 0 ] || errmsg "Error: set priority failed for [$repo]!"
        # install apforge and set priority
        #echo -e '\nInstall and set priority for \e[92mapforge\e[0m ...'
        #rpm -ivh "http://adc.accessport.jp/apforge/el6/apforge-release/apforge-release-1.0.0-1.el6.ap.x86_64.rpm" || {
        #    errmsg "Error: install apforge failed!"
        #}
        # install zabbix and set priority
        #echo -e '\nInstall and set priority for \e[92mzabbix\e[0m ...'
        #repourl='http://www.zabbix.jp/binaries/relatedpkgs/rhel6/x86_64/zabbix-jp-release-6-6.noarch.rpm'
        #cd /tmp && {
        #    curl -O -L "$repourl" 2>/dev/null &
        #    waitpid $!
        #    cd - >/dev/null
        #}
        #if [ -e /tmp/zabbix-jp-release-6-6.noarch.rpm ]; then
        #    rpm --import http://www.zabbix.jp/binaries/RPM-GPG-KEY-ZABBIX-JP
        #    rpm -K /tmp/zabbix-jp-release-6-6.noarch.rpm
        #    rpm -ivh /tmp/zabbix-jp-release-6-6.noarch.rpm
        #    repo='/etc/yum.repos.d/zabbix-jp.repo'
        #    if [ -e $repo ]; then
        #        sed -i -e 's/^\(\[.*\]\) *$/\1\npriority = 12/' $repo || errmsg "Error: set priority failed for [$repo]!"
        #    fi
        #fi
        # install EPEL repository and set priority
        echo -e '\nInstall and set priority for \e[92mEPEL repository\e[0m ...'
        yum -y install epel-release
        setPriority epel.repo 20
        setPriority epel-testing.repo 20
        # install RPMforge and set priority
        echo -e '\nInstall and set priority for \e[92mRPMforge\e[0m ...'
        rpmforge='rpmforge-release-0.5.3-1.el6.rf.x86_64.rpm'
        repourl="http://pkgs.repoforge.org/rpmforge-release/$rpmforge"
        cd /tmp && {
            curl -O -L "$repourl" 2>/dev/null &
            waitpid $!
            cd - >/dev/null
        }
        if [ -e /tmp/$rpmforge ]; then
            rpm --import http://apt.sw.be/RPM-GPG-KEY.dag.txt
            rpm -K /tmp/$rpmforge
            rpm -ivh /tmp/rpmforge
            setPriority rpmforge.repo 21
        fi
        # confirm
        echo -e '\n\e[4mConfirm priorities\e[0m:\n'
        sed -n -e "/^\[/h; /priority *=/{ G; s/\n/ /; s/ity=/ity = /; p }" /etc/yum.repos.d/*.repo | sort -k3n
        echo
        if pask 'If no problem, now to update repositories'; then
            yum update
        fi
        # clean up
        rm -f /tmp/*.rpm*
    fi
fi

# Install application packages by yum
#-------------------------------------------------------------
pdate
if pask 'Install application packages'; then
    echo -e '\nInstall \e[92msystem utilities\e[0m ...'
    yum -y install openssh-clients sysstat iotop htop screen tmux tree subversion cronolog vim-enhanced yum-utils sendmail-cf git
    echo -e '\nInstall \e[92mnetwork utilities\e[0m ...'
    yum -y install jwhois telnet nc
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
    sed -i -e "s/^#[ \t]*\(%wheel[ \t]\+ALL=(ALL)[ \t]\+ALL\)[ \t]*/\1/" /etc/sudoers || errmsg 'Error: failed!'
    echo
    grep %wheel /etc/sudoers | grep -v '^#'
fi

# Disable root remote ssh login
#-------------------------------------------------------------
pdate
if pask 'Disable root remote ssh login'; then
    sed -i -e 's/^#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
    echo
    grep PermitRootLogin /etc/ssh/sshd_config | grep -v '^#'
    if [ $? -eq 0 ]; then
        echo
        service sshd restart
    else
        errmsg 'Error: failed!'
    fi
fi

# Disable SELinux
#-------------------------------------------------------------
pdate
if pask 'Disable SELinux'; then
    sed -i -e 's/^SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config || errmsg 'Error: failed!'
    echo
    cat /etc/selinux/config | grep -v '^[ \t]*$' | grep -v '^#'
fi

# Setup sendmail
#-------------------------------------------------------------
pdate
if pask 'Setup sendmail'; then
    ret=0
    domain='dev.clever-rock.com'
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
    stopsrv haldaemon
    stopsrv ip6tables
    stopsrv iptables
    stopsrv kdump
    stopsrv mdmonitor
    stopsrv messagebus
    stopsrv netfs
    stopsrv restorecond
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

echo

#{+----------------------------------------- Embira Footer 1.6 -----+
# | vim<600:set et sw=4 ts=4 sts=4:                                 |
# | vim600:set et sw=4 ts=4 sts=4 ff=unix cindent fdm=indent fdn=1: |
# +-----------------------------------------------------------------+}
