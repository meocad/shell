#!/bin/sh
#****************************************************************#
# ScriptName: color1.sh
# Author: utcmxr@outlook.com
# Create Date: 2020-09-19 19:51
# Modify Author: utcmxr@outlook.com
# Modify Date: 2020-09-19 19:51
# Function: 
#***************************************************************#
for fgbg in 38 48 ; do # Foreground / Background
    for color in {0..255} ; do # Colors
        # Display the color
        printf "\e[${fgbg};5;%sm  %3s  \e[0m" $color $color
        # Display 6 colors per lines
        if [ $(((color + 1) % 6)) == 4 ] ; then
            echo # New line
        fi
    done
    echo # New line
done
 
exit 0
