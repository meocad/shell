#!/bin/sh
#****************************************************************#
# ScriptName: ceshi.sh
# Author: utcmxr@outlook.com
# Create Date: 2019-12-25 17:36
<<<<<<< HEAD
# Modify Author: @alibaba-inc.com
# Modify Date: 2021-03-08 15:09
=======
# Modify Author: utcmxr@outlook.com
# Modify Date: 2019-12-25 17:36
>>>>>>> 83084917eea614b6987fb0c52b524b65f8c0646f
# Function: 
#***************************************************************#

echo $1 $- $# $@ $! $? $$ "!$" $*
<<<<<<< HEAD
color_text() {
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
color_text $1 $2
=======
>>>>>>> 83084917eea614b6987fb0c52b524b65f8c0646f
