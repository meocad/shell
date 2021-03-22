#!/bin/sh
awk -F, '{
		print $4 ", " $0
	    }' $* |
sort |
awk -F, '
$1 == LastState {
	 # print "&hairsp;\t" $2
	 print "\t" $2
}
$1 != LastState {
	 LastState = $1
	 print $1
	 # print "&hairsp;\t" $2
	 print "\t" $2 
}'
