#!/bin/bash
# Author: utcmxr@outlook.com
# Blog: https://meocad.com
# Time:2022-07-19 16:15:38
# Name:rand-string.sh
# Version: V1.0
# Description:

if [ -n "$1" ]  #  If command-line argument present,
then            #+ then set start-string to it.
  str0="$1"
else            #  Else use PID of script as start-string.
  str0="$$"
fi

POS=2  # Starting from position 2 in the string.
LEN=8  # Extract eight characters.

str1=$( echo "$str0" | md5sum | md5sum )
#  Doubly scramble     ^^^^^^   ^^^^^^
#+ by piping and repiping to md5sum.

randstring="${str1:$POS:$LEN}"
# Can parameterize ^^^^ ^^^^

echo "$randstring"

# 输出第2个到最后一个位置参数
echo ${*:2}          # Echoes second and following positional parameters.
echo ${@:2}          # Same as above.

# 输出三个位置参数，从第二个位置参数开始输出
echo ${*:2:3}        # Echoes three positional parameters, starting at second.

exit $?

# bozo$ ./rand-string.sh my-password
# 1bdd88c4

#  No, this is is not recommended
#+ as a method of generating hack-proof passwords.
