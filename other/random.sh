#!/bin/sh
#****************************************************************#
# ScriptName: random.sh
# Author: utcmxr@outlook.com
# Create Date: 2020-10-03 12:28
# Modify Author: utcmxr@outlook.com
# Modify Date: 2020-10-03 12:28
# Function: 
#***************************************************************#
#!/bin/bash
function randStr
{
	j=0;
	for i in {a..z};do array[$j]=$i;j=$(($j+1));done
	for i in {A..Z};do array[$j]=$i;j=$(($j+1));done
	for ((i=0;i<10;i++));do strs="$strs${array[$(($RANDOM%$j))]}"; done;
		echo $strs
}
echo `randStr`

