#!/bin/sh
#****************************************************************#
# ScriptName: ceshi.sh
# Author: utcmxr@outlook.com
# Create Date: 2020-09-19 10:41
# Modify Author: utcmxr@outlook.com
# Modify Date: 2020-09-19 10:41
# Function: 
#***************************************************************#

debug=${1:-y}
echo $debug

Color_Text() {
    case "$1" in
        blue)
            echo -e "\e[0;34m$2\e[0m";;
        yellow)
            echo -e "\e[0;33m$2\e[0m";;
        red)
            echo -e "\e[0;31m$2\e[0m";;
        green)
            echo -e "\e[0;32m$2\e[0m";;
    esac
}


Color_Text "blue" "hhas hdfhsa dhfhsd"

Sleep_Sec(){
    seconds=${1:-10}
    while [ "${seconds}" -ge "0" ];do
      echo -ne "\r     \r"
      echo -n "${seconds}"
      seconds=$((seconds - 1))
      sleep 1
    done
    echo -ne "\r"
}

Sleep_Sec
this="${BASH_SOURCE-$0}"
echo $this

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/" && pwd )"
current_path=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "${current_path}1" 2>/dev/null || { echo  "${BASH_SOURCE[0]}[$LINENO] ERROR: The dir \"$current_path\" is not exist, pls check"; exit 1; }
echo $DIR
echo $LINENO
do_ok() {
read -r -p"输入y进入执行过程[按q退出]:" exe
	# shellcheck disable=SC2166
	while [ "$exe" != 'y' ]
    do
	    if [[ $exe == 'q' ]];then
			exit
	    fi
	    read -r -p"输入有误，继续输入[按q退出]:" exe
	done
}


file="129"
while IFS= read -r line
do
	echo "Line: $line"
done < <(grep -v '^ #' < $file)

do_ok
do_ok
echo "asdfsd"
