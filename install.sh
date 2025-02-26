#!/bin/sh
LC_ALL=C
export LC_ALL

# Change root.
if test 0 -ne `id -u`; then
    echo "Running the sudo command..."
    sudo $0 $*
    result=$?
    if test 1 -eq $result; then
	echo ""
        echo "[ERROR] The sudo command failed."
        echo "[ERROR] Please execute the install.sh again after changing to the root."
    fi
    exit $result
fi

# Set top directory.
programPath=`which $0`
topDir=`dirname "$programPath"`


#The distribution is checked.
checkDistribution () {

    # check distribution
    checkdistName=`lsb_release -d 2>/dev/null`
    distName=`echo "$checkdistName" | awk '{print $2 "-" $3}'`
}

#The Architecture is checked.
checkArchitecture () {
    #Select Architecte
    checkArchName=`uname -m`

    case "$checkArchName" in
	"i386" | "i486") archName="i386" ;;
	"i586" | "i686") archName="i586" ;;
	"amd64" | "x86_64") archName="x86_64" ;;
    *) archName="" ;;
    esac
}


#Packages installation
packageInstall () {
    instDist=$1
    instArch=$2

    fileName=`ls $topDir/.install/$instDist-$instArch-*`
    packageType=`basename $fileName | awk -F- '{print $4 }'| sed -e "s/\.list//g"`

    # error check

    case "$packageType" in
	"RPM") installCommand="rpm -U" ;;
	"DEB") installCommand="dpkg -i" ;;
	*)
	    echo "[ERROR] Fatal error."
	    exit -1
	    ;;
    esac

    fileName="$topDir/.install/$instDist-$instArch-$packageType.list"
    cd $topDir

    for LINE in `cat "$fileName"`
    do
	#The content in the list is readed.
	lineData=`echo "$LINE" | awk -F, '{print $1 "/" $3 "." $4}'`
	$installCommand "$topDir/$lineData"
    done
}

selectDistName () {
    endStrings=
    distName=
    archName=

    while test ture; do
	echo ""
	echo "Please select your distribution."

	endStrings="Select number ["

	count=0
	for LIST in `ls -1 $topDir/.install/*.list | LC_ALL=C sort`; do
	    strings=`basename $LIST | sed -e "s/\.list//g" | tr "-" " "`
	    count=`expr "$count" + 1`
	    echo "$count.$strings"

	    if test 1 -eq $count; then
		endStrings="$endStrings$count"
	    else
		endStrings="$endStrings/$count"
	    fi
	done

	endStrings="${endStrings}]? "
	echo -n "$endStrings"

	read NUMBER

	expr "$NUMBER" + 1 > /dev/null 2>&1
	if test $? -lt 2; then
	    count=0
	    for LIST in `ls $topDir/.install/*.list`; do

		count=`expr "$count" + 1`

		if test $NUMBER -eq $count; then
		    distName=`basename $LIST | awk -F- '{ print $1 "-" $2 }'`
		    archName=`basename $LIST | awk -F- '{ print $3 }'`
		    break;
		fi
	    done

	    if test x != "$distName"x -a x != "$archName"x; then
		break
	    fi
	fi

	echo "[ERROR] Please input a correct number."
    done
}

#
# MAIN
#
distName=
archName=


#Function that calls check on distribution.
checkDistribution

#Architecture that calls check on distribution.
checkArchitecture

targetFile=`ls $topDir/.install/$distName-$archName-* 2> /dev/null`
if test -s "$targetFile"; then
     while test ture; do
	echo -n "Install $distName ($archName) [y/n]? "
	read answer
	case "$answer" in
	    [yY] | yes | YES | Yes )
		break
		;;
	    [nN] | no | No | NO )
		selectDistName
		break
		;;

	    * ) echo "[ERROR] Please input a correct number." ;;
	esac
    done
else
    selectDistName
fi

#Packages installation
packageInstall $distName $archName
if test 0 -ne $?; then
    echo "[ERROR] Package installation failed."
    exit -1
fi

echo ""
echo "*** The installation finished. ***"
echo ""

exit 0
