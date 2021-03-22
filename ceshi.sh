#!/bin/sh
#****************************************************************#
# ScriptName: ceshi.sh
# Author: utcmxr@outlook.com
# Create Date: 2019-12-25 17:36
# Modify Author: @alibaba-inc.com
# Modify Date: 2021-03-08 15:09
# Function: 
#***************************************************************#

echo $1 $- $# $@ $! $? $$ "!$" $*
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
