#!/bin/sh
INTERVAL=5
PREFIX=$INTERVAL-sec-status
RUNFILE=/opt/git/shell/High-Performance-MySQL-3rd-Edition/Chapter2/benchmarks/running
MYSQL_COMMAND='mysql -uroot -p'XaMr@2019''
$MYSQL_COMMAND -e 'SHOW GLOBAL VARIABLES' 2>/dev/null >> mysql-variables
while test -e $RUNFILE; do
  file=$(date +%F_%I)
  sleep=$(date +%s.%N | awk "{print $INTERVAL - (\$1 % $INTERVAL)}")
  sleep $sleep
  ts="$(date +"TS %s.%N %F %T")"
  loadavg="$(uptime)"
  echo "$ts $loadavg" >> $PREFIX-${file}-status
  $MYSQL_COMMAND -e 'SHOW GLOBAL STATUS' >> $PREFIX-${file}-status 2>/dev/null &
  echo "$ts $loadavg" >> $PREFIX-${file}-innodbstatus
  $MYSQL_COMMAND -e 'SHOW ENGINE INNODB STATUS\G' >> $PREFIX-${file}-innodbstatus 2>/dev/null &
  echo "$ts $loadavg" >> $PREFIX-${file}-processlist
  $MYSQL_COMMAND -e 'SHOW FULL PROCESSLIST\G' >> $PREFIX-${file}-processlist 2>/dev/null &
  echo $ts
done
echo Exiting because $RUNFILE does not exist.
