#!/bin/sh
awk 'NR>1 && $NF ~ "aa" {print $NF}' x| while read a b c d e f g 
do
    echo $a
done 

