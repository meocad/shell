#!/bin/bash

INTERVAL=5
PREFIX=$INTERVAL-sec-status
FUNFILE=/var/run/status

mysql -uroot -pXaMr@2019 -c -e 'SHOW GLOBAL VARIABLES' >> ./mysql-variables

while test -e $FUNFILE ;do
	file=$(date +%F_%I)
	sleep=$(date +%s.%N |awk "{print $INTERVAL - (\$1 % $INTERVAL)}")
	sleep $sleep
	ts="$(date +"TS %s.%N %F %T")"
	loadavg="$(uptime)"
	
	echo "$ts $loadavg" >> $PREFIX-${file}-status
    mysql -uroot -pXaMr@2019 -c -e 'SHOW GLOBAL STATUS'	>> $PREFIX-${file}-status &

	echo "$ts $loadavg" >> $PREFIX-${file}-innodbstatus
	mysql -uroot -pXaMr@2019 -c -e 'SHOW ENGINE INNODB STATUS\G' >> $PREFIX-${file}-innodbstatus &

	echo "$ts $loadavg" >> $PREFIX-${file}-processlist
	mysql -uroot -pXaMr@2019 -c -e 'SHOW FULL PROCESSLIST\G' >> $PREFIX-${file}-processlist &

	echo $ts
done

echo Exiting because $FUNFILE does not exist.
