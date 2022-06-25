#!/bin/bash
########################################
# Homepage: http://netkiller.github.io
# Author: neo <netkiller@msn.com>
########################################
# 骇客常常使用骇客字典穷举你的SSH密码，使用下面脚本可以封杀频繁链接的IP地址
PIPE=/var/tmp/pipe
pidfile=/var/tmp/$0.pid
BLACKLIST=/var/tmp/black.lst
WHITELIST=/var/tmp/white.lst

LOGFILE=/var/log/secure*
DAY=5
########################################

if [ -z "$( egrep "CentOS|7." /etc/centos-release)" ]; then
	echo 'Only for CentOS 7.x'
	exit
fi

if [ -f $BLACKLIST ]; then
	find $BLACKLIST -type f -mtime +${DAY} -delete
fi

if [ ! -f ${BLACKLIST} ]; then
    touch ${BLACKLIST}
fi

if [ ! -f ${WHITELIST} ]; then
    touch ${WHITELIST}
fi

for ipaddr in $(grep rhost ${LOGFILE} | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | sort | uniq -c | sort -r -n | head -n 10| awk '{print $2}')
do

    if [ $(grep -c $ipaddr ${WHITELIST}) -gt 0 ]; then
		continue
    fi

    if [ $(grep -c $ipaddr ${BLACKLIST}) -eq 0 ] ; then
		echo $ipaddr >> ${BLACKLIST}
        iptables -I INPUT -p tcp  -s $ipaddr -j DROP
        #iptables -I INPUT -s $ipaddr -j DROP
    fi
done
