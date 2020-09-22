#!/bin/sh
#****************************************************************#
# ScriptName: color.sh
# Author: utcmxr@outlook.com
# Create Date: 2020-09-19 19:48
# Modify Author: utcmxr@outlook.com
# Modify Date: 2020-09-19 19:48
# Function: 
#***************************************************************#
# more information, please refer https://misc.flogisoft.com/bash/tip_colors_and_formatting

for clbg in {40..47} {100..107} 49 ; do
	#Foreground
	for clfg in {30..37} {90..97} 39 ; do
		#Formatting
		for attr in 0 1 2 4 5 7 ; do
			#Print the result
			echo -en "\e[${attr};${clbg};${clfg}m ^[${attr};${clbg};${clfg}m \e[0m"
		done
		echo #Newline
	done
done
 
