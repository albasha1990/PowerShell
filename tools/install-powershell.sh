#!/bin/bash
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

install(){
    #Companion code for the blog https://cloudywindows.com

    #call this code direction from the web with:
    #bash <(wget -qO - https://raw.githubusercontent.com/PowerShell/PowerShell/master/tools/install-powershell.sh) <ARGUMENTS>
    #wget -O - https://raw.githubusercontent.com/PowerShell/PowerShell/master/tools/install-powershell.sh | bash -s <ARGUMENTS>
    #bash <(curl -s https://raw.githubusercontent.com/PowerShell/PowerShell/master/tools/install-powershell.sh) <ARGUMENTS>


    #Usage - if you do not have the ability to run scripts directly from the web,
    #        pull all files in this repo folder and execute, this script
    #        automatically prefers local copies of sub-scripts

    #Completely automated install requires a root account or sudo with a password requirement

    #Switches
    # -includeide         - installs vscode and vscode PowerShell extension (only relevant to machines with desktop environment)
    # -interactivetesting - do a quick launch test of vscode (only relevant when used with -includeide)
    # -skip-sudo-check    - use sudo without verifying its availability (hard to accurately do on some distros)
    # -preview            - installs the latest preview release of PowerShell core side-by-side with any existing production releases
    # -appimage           - perform an AppImage install instead of a native install

    #gitrepo paths are overrideable to run from your own fork or branch for testing or private distribution

    local VERSION="1.2.0"
    local gitreposubpath="PowerShell/PowerShell/master"
    local gitreposcriptroot="https://raw.githubusercontent.com/$gitreposubpath/tools"
    local gitscriptname="install-powershell.psh"

    echo "Get-PowerShell Core MASTER Installer Version $VERSION"
    echo "Installs PowerShell Core and Optional The Development Environment"
    echo "  Original script is at: $gitreposcriptroot\$gitscriptname"

    echo "Arguments used: $*"
    echo ""

    # Let's quit on interrupt of subcommands
    trap '
    trap - INT # restore default INT handler
    echo "Interrupted"
    kill -s INT "$$"
    ' INT

    lowercase(){
        echo "$1" | tr [A-Z] [a-z]
    }

    local OS=`lowercase \`uname\``
    local KERNEL=`uname -r`
    local MACH=`uname -m`
    local DIST
    local DistroBasedOn
    local PSUEDONAME
    local REV

    if [ "${OS}" == "windowsnt" ]; then
        OS=windows
        DistroBasedOn=windows
        SCRIPTFOLDER=$(dirname $(readlink -f $0))
    elif [ "${OS}" == "darwin" ]; then
        OS=osx
        DistroBasedOn=osx
        # readlink doesn't work the same on macOS
        SCRIPTFOLDER=$(dirname $0)
    else
        SCRIPTFOLDER=$(dirname $(readlink -f $0))
        OS=`uname`
        if [ "${OS}" == "SunOS" ] ; then
            OS=solaris
            ARCH=`uname -p`
            OSSTR="${OS} ${REV}(${ARCH} `uname -v`)"
            DistroBasedOn=sunos
        elif [ "${OS}" == "AIX" ] ; then
            OSSTR="${OS} `oslevel` (`oslevel -r`)"
            DistroBasedOn=aix
        elif [ "${OS}" == "Linux" ] ; then
            if [ -f /etc/redhat-release ] ; then
                DistroBasedOn='redhat'
                DIST=`cat /etc/redhat-release |sed s/\ release.*//`
                PSUEDONAME=`cat /etc/redhat-release | sed s/.*\(// | sed s/\)//`
                REV=`cat /etc/redhat-release | sed s/.*release\ // | sed s/\ .*//`
            elif [ -f /etc/system-release ] ; then
                DIST=`cat /etc/system-release |sed s/\ release.*//`
                PSUEDONAME=`cat /etc/system-release | sed s/.*\(// | sed s/\)//`
                REV=`cat /etc/system-release | sed s/.*release\ // | sed s/\ .*//`
                if [[ $DIST == *"Amazon Linux"* ]] ; then
                    DistroBasedOn='amazonlinux'
                else
                    DistroBasedOn='redhat'
                fi
            elif [ -f /etc/SuSE-release ] ; then
                DistroBasedOn='suse'
                PSUEDONAME=`cat /etc/SuSE-release | tr "\n" ' '| sed s/VERSION.*//`
                REV=`cat /etc/SuSE-release | grep 'VERSION' | sed s/.*=\ //`
            elif [ -f /etc/mandrake-release ] ; then
                DistroBasedOn='mandrake'
                PSUEDONAME=`cat /etc/mandrake-release | sed s/.*\(// | sed s/\)//`
                REV=`cat /etc/mandrake-release | sed s/.*release\ // | sed s/\ .*//`
            elif [ -f /etc/debian_version ] ; then
                DistroBasedOn='debian'
                DIST=`cat /etc/lsb-release | grep '^DISTRIB_ID' | awk -F=  '{ print $2 }'`
                PSUEDONAME=`cat /etc/lsb-release | grep '^DISTRIB_CODENAME' | awk -F=  '{ print $2 }'`
                REV=`cat /etc/lsb-release | grep '^DISTRIB_RELEASE' | awk -F=  '{ print $2 }'`
            fi
            if [ -f /etc/UnitedLinux-release ] ; then
                DIST="${DIST}[`cat /etc/UnitedLinux-release | tr "\n" ' ' | sed s/VERSION.*//`]"
            fi
            OS=`lowercase $OS`
            DistroBasedOn=`lowercase $DistroBasedOn`
        fi
    fi

    echo "Operating System Details:"
    echo "  OS: $OS"
    echo "  DIST: $DIST"
    echo "  DistroBasedOn: $DistroBasedOn"
    echo "  PSUEDONAME: $PSUEDONAME"
    echo "  REV: $REV"
    echo "  KERNEL: $KERNEL"
    echo "  MACH: $MACH"



    if [[ "'$*'" =~ appimage ]] ; then
        if [ -f $SCRIPTFOLDER/appimage.sh ]; then
            #Script files were copied local - use them
            . $SCRIPTFOLDER/appimage.sh
        else
            #Script files are not local - pull from remote
            echo "Could not find \"appimage.sh\" next to this script..."
            echo "Pulling and executing it from \"$gitreposcriptroot/appimage.sh\""
            if [ -n "$(command -v curl)" ]; then
                echo "found and using curl"
                bash <(curl -s $gitreposcriptroot/appimage.sh) $@
            elif [ -n "$(command -v wget)" ]; then
                echo "found and using wget"
                bash <(wget -qO- $gitreposcriptroot/appimage.sh) $@
            else
                echo "Could not find curl or wget, install one of these or manually download \"$gitreposcriptroot/appimage.sh\""
            fi
        fi
    elif [ "$DistroBasedOn" == "redhat" ] || [ "$DistroBasedOn" == "debian" ] || [ "$DistroBasedOn" == "osx" ] || [ "$DistroBasedOn" == "suse" ] || [ "$DistroBasedOn" == "amazonlinux" ]; then
        echo "Configuring PowerShell Core Environment for: $DistroBasedOn $DIST $REV"
        if [ -f $SCRIPTFOLDER/installpsh-$DistroBasedOn.sh ]; then
            #Script files were copied local - use them
            . $SCRIPTFOLDER/installpsh-$DistroBasedOn.sh
        else
            #Script files are not local - pull from remote
            echo "Could not find \"installpsh-$DistroBasedOn.sh\" next to this script..."
            echo "Pulling and executing it from \"$gitreposcriptroot/installpsh-$DistroBasedOn.sh\""
            if [ -n "$(command -v curl)" ]; then
                echo "found and using curl"
                bash <(curl -s $gitreposcriptroot/installpsh-$DistroBasedOn.sh) $@
            elif [ -n "$(command -v wget)" ]; then
                echo "found and using wget"
                bash <(wget -qO- $gitreposcriptroot/installpsh-$DistroBasedOn.sh) $@
            else
                echo "Could not find curl or wget, install one of these or manually download \"$gitreposcriptroot/installpsh-$DistroBasedOn.sh\""
            fi
        fi
    else
        echo "Sorry, your operating system is based on $DistroBasedOn and is not supported by PowerShell Core or this installer at this time."
    fi
}

# run the install function
install;
