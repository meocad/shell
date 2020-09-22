#! /usr/bin/awk -f

#printing from 0-10 using a do while statement
#do while statement
BEGIN {
#initialize a counter
x=0
do {
	print x;
	x+=1;
}
while(x<=10)
}
