#!/bin/bash

# FUNCTIONS:
# shell中遍历一句话，输出特定长的字符串
# 数组相关知识参考：
# https://www.cnblogs.com/ZFBG/p/10978956.html
# way 1
hello="hello,world.my name is Jerry,what's your name ?"
for word in ${hello[@]};do
    [ ${#word} -ge 4 ] && echo $word
done

echo

# way 2
[ `echo $word |wc -L` -gt 4 ] && echo $word
echo

# way 3
[ `expr length $word` -gt 4 ] && echo $word
echo

# way 4
echo "hello,world.my name is Jerry,what's your name ?"|awk '{for(i=1;i<=NF;i++)if(length($i)>=4)print$i}'

