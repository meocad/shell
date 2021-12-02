#!/bin/sh
#****************************************************************#
# ScriptName: shell参数替换_截取.sh
# Author: @outlook.com
# Create Date: 2021-04-30 11:56
# Modify Author: @outlook.com
# Modify Date: 2021-04-30 11:56
# Function: 
#***************************************************************#
echo '
参数扩展            说明
${param:-default}   如果param为空，就把它设置为default的值
${#param}           给出param的长度
${param%word}       从param尾部开始删除与word匹配的最小部分，然后返回剩余部分
${param%%word}      从param尾部开始删除与word匹配最长的部分，然后返回剩余部分
${param#word}       从param头部开始删除与word匹配最小的部分，然后返回剩余部分
${param##word}      从param头部开始删除与word匹配最长的部分然后返回剩余部分
'
unset foo
echo ${foo:-bar}


foo=fud
echo ${foo:-bar}

foo=/usr/bin/x11/startx
echo ${foo#*/}
echo ${foo##*/}

bar=/usr/local/etc/local/networks
echo ${bar%local*}
echo ${bar%%local*}

echo '
{foo#*/}语句仅仅匹配并删除最左边的/(*匹配零个或多
个字符){foo##*/}语句匹配并删除尽可能多的字符，所以它删除
最右边的/及其前面的所有字符'
