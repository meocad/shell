#!/bin/sh
#****************************************************************#
# ScriptName: return.sh
# Author: @outlook.com
# Create Date: 2021-06-23 17:41
# Modify Author: @outlook.com
# Modify Date: 2021-06-23 17:41
# Function: 
#***************************************************************#

s(){
   echo 'a
   b
   c
   d
   e' | while read line
do 
    echo $line
done
}

x=`s`
echo "$x"
