:<<-'EOF'
# vim a.txt 
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/bin:/sbin/nologin
daemon:x:2:2:daemon:/sbin:/sbin/nologin
adm:x:3:4:adm:/var/adm:/sbin/nologin
lp:x:4:7:lp:/var/spool/lpd:/sbin/nologin
298374837483
172.16.0.254
10.1.1.1
EOF


[root@server ~]# sed ''  a.txt						对文件什么都不做
[root@server ~]# sed -n 'p'  a.txt					打印每一行，并取消默认输出
[root@server ~]# sed -n '1p'  a.txt					打印第1行
[root@server ~]# sed -n '2p'  a.txt					打印第2行
[root@server ~]# sed -n '1,5p'  a.txt				打印1到5行
[root@server ~]# sed -n '$p' a.txt 					打印最后1行

[root@server ~]# sed '$a99999' a.txt 				文件最后一行下面增加内容
[root@server ~]# sed 'a99999' a.txt 				文件每行下面增加内容
[root@server ~]# sed '5a99999' a.txt 				文件第5行下面增加内容
[root@server ~]# sed '$i99999' a.txt 				文件最后一行上一行增加内容
[root@server ~]# sed 'i99999' a.txt 				文件每行上一行增加内容
[root@server ~]# sed '6i99999' a.txt 				文件第6行上一行增加内容
[root@server ~]# sed '/^uucp/ihello' a.txt			以uucp开头行的上一行插入内容


[root@server ~]# sed '5chello world' a.txt 		替换文件第5行内容
[root@server ~]# sed 'chello world' a.txt 		替换文件所有内容
[root@server ~]# sed '1,5chello world' a.txt 	替换文件1到5号内容为hello world
[root@server ~]# sed '/^user01/c888888' a.txt	替换以user01开头的行



[root@server ~]# sed '1d' a.txt 						删除文件第1行
[root@server ~]# sed '1,5d' a.txt 					删除文件1到5行
[root@server ~]# sed '$d' a.txt						删除文件最后一行


[root@server ~]# sed -n 's/root/ROOT/p' 1.txt 
[root@server ~]# sed -n 's/root/ROOT/gp' 1.txt 
[root@server ~]# sed -n 's/^#//gp' 1.txt 
[root@server ~]# sed -n 's@/sbin/nologin@itcast@gp' a.txt
[root@server ~]# sed -n 's/\/sbin\/nologin/itcast/gp' a.txt
[root@server ~]# sed -n '10s#/sbin/nologin#itcast#p' a.txt 
uucp:x:10:14:uucp:/var/spool/uucp:itcast
[root@server ~]# sed -n 's@/sbin/nologin@itcastheima@p' 2.txt 
注意：搜索替换中的分隔符可以自己指定

[root@server ~]# sed -n '1,5s/^/#/p' a.txt 		注释掉文件的1-5行内容



r	从文件中读取输入行
w	将所选的行写入文件
[root@server ~]# sed '3r /etc/hosts' 2.txt 
[root@server ~]# sed '$r /etc/hosts' 2.txt
[root@server ~]# sed '/root/w a.txt' 2.txt 
[root@server ~]# sed '/[0-9]{4}/w a.txt' 2.txt
[root@server ~]# sed  -r '/([0-9]{1,3}\.){3}[0-9]{1,3}/w b.txt' 2.txt

!	对所选行以外的所有行应用命令，放到行数之后
[root@server ~]# sed -n '1!p' 1.txt 
[root@server ~]# sed -n '4p' 1.txt 
[root@server ~]# sed -n '4!p' 1.txt 
[root@server ~]# cat -n 1.txt 
[root@server ~]# sed -n '1,17p' 1.txt 
[root@server ~]# sed -n '1,17!p' 1.txt 

&  保存查找串以便在替换串中引用   \(\)

[root@server ~]# sed -n '/root/p' a.txt 
root:x:0:0:root:/root:/bin/bash
[root@server ~]# sed -n 's/root/#&/p' a.txt 
#root:x:0:0:root:/root:/bin/bash

# sed -n 's/^root/#&/p' passwd   注释掉以root开头的行
# sed -n -r 's/^root|^stu/#&/p' /etc/passwd	注释掉以root开头或者以stu开头的行
# sed -n '1,5s/^[a-z].*/#&/p' passwd  注释掉1~5行中以任意小写字母开头的行
# sed -n '1,5s/^/#/p' /etc/passwd  注释1~5行
或者
sed -n '1,5s/^/#/p' passwd 以空开头的加上#
sed -n '1,5s/^#//p' passwd 以#开头的替换成空

[root@server ~]# sed -n '/^root/p' 1.txt 
[root@server ~]# sed -n 's/^root/#&/p' 1.txt 
[root@server ~]# sed -n 's/\(^root\)/#\1/p' 1.txt 
[root@server ~]# sed -nr '/^root|^stu/p' 1.txt 
[root@server ~]# sed -nr 's/^root|^stu/#&/p' 1.txt 


= 打印行号
# sed -n '/bash$/=' passwd    打印以bash结尾的行的行号
# sed -ne '/root/=' -ne '/root/p' passwd 
# sed -n '/nologin$/=;/nologin$/p' 1.txt
# sed -ne '/nologin$/=' -ne '/nologin$/p' 1.txt

q	退出
类似程序中的break 满足条件就退出 不再继续
# sed '5q' 1.txt
# sed '/mail/q' 1.txt
# sed -r '/^yunwei|^mail/q' 1.txt
[root@server ~]# sed -n '/bash$/p;10q' 1.txt
ROOT:x:0:0:root:/root:/bin/bash


综合运用：
[root@server ~]# sed -n '1,5s/^/#&/p' 1.txt 
#root:x:0:0:root:/root:/bin/bash
#bin:x:1:1:bin:/bin:/sbin/nologin
#daemon:x:2:2:daemon:/sbin:/sbin/nologin
#adm:x:3:4:adm:/var/adm:/sbin/nologin
#lp:x:4:7:lp:/var/spool/lpd:/sbin/nologin

[root@server ~]# sed -n '1,5s/\(^\)/#\1/p' 1.txt 
#root:x:0:0:root:/root:/bin/bash
#bin:x:1:1:bin:/bin:/sbin/nologin
#daemon:x:2:2:daemon:/sbin:/sbin/nologin
#adm:x:3:4:adm:/var/adm:/sbin/nologin
#lp:x:4:7:lp:/var/spool/lpd:/sbin/nologin



-e 多项编辑
-r 扩展正则
-i 修改原文件

[root@server ~]# sed -ne '/root/p' 1.txt -ne '/root/='
root:x:0:0:root:/root:/bin/bash
1
[root@server ~]# sed -ne '/root/=' -ne '/root/p' 1.txt 
1
root:x:0:0:root:/root:/bin/bash

在1.txt文件中的第5行的前面插入“hello world”;在1.txt文件的第8行下面插入“哈哈哈哈”

[root@server ~]# sed -e '5ihello world' -e '8a哈哈哈哈哈' 1.txt  -e '5=;8='

sed -n '1,5p' 1.txt
sed -ne '1p' -ne '5p' 1.txt
sed -ne '1p;5p' 1.txt

过滤vsftpd.conf文件中以#开头和空行：
[root@server ~]# grep -Ev '^#|^$' /etc/vsftpd/vsftpd.conf
[root@server ~]# sed -e '/^#/d' -e '/^$/d' /etc/vsftpd/vsftpd.conf
[root@server ~]# sed '/^#/d;/^$/d' /etc/vsftpd/vsftpd.conf
[root@server ~]# sed -r '/^#|^$/d' /etc/vsftpd/vsftpd.conf

过滤smb.conf文件中生效的行：
# sed -e '/^#/d' -e '/^;/d' -e '/^$/d' -e '/^\t$/d' -e '/^\t#/d' smb.conf
# sed -r '/^(#|$|;|\t#|\t$)/d' smb.conf 

# sed -e '/^#/d' -e '/^;/d' -e '/^$/d' -e '/^\t$/d' -e '/^\t#/' smb.conf


[root@server ~]# grep '^[^a-z]' 1.txt

[root@server ~]# sed -n '/^[^a-z]/p' 1.txt

过滤出文件中的IP地址：
[root@server ~]# grep -E '([0-9]{1,3}\.){3}[0-9]{1,3}' 1.txt 
192.168.0.254
[root@server ~]# sed -nr '/([0-9]{1,3}\.){3}[0-9]{1,3}/p' 1.txt 
192.168.0.254

[root@server ~]# grep -o -E '([0-9]{1,3}\.){3}[0-9]{1,3}' 2.txt 
10.1.1.1
10.1.1.255
255.255.255.0

[root@server ~]# sed -nr '/([0-9]{1,3}\.){3}[0-9]{1,3}/p' 2.txt
10.1.1.1
10.1.1.255
255.255.255.0
过滤出ifcfg-eth0文件中的IP、子网掩码、广播地址
[root@server shell06]# grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' ifcfg-eth0 
10.1.1.1
255.255.255.0
10.1.1.254
[root@server shell06]# sed -nr '/([0-9]{1,3}\.){3}[0-9]{1,3}/p' ifcfg-eth0|cut -d'=' -f2
10.1.1.1
255.255.255.0
10.1.1.254
[root@server shell06]# sed -nr '/([0-9]{1,3}\.){3}[0-9]{1,3}/p' ifcfg-eth0|sed -n 's/[A-Z=]//gp'
10.1.1.1
255.255.255.0
10.1.1.254

[root@server shell06]# ifconfig eth0|sed -n '2p'|sed -n 's/[:a-Z]//gp'|sed -n 's/ /\n/gp'|sed '/^$/d'
10.1.1.1
10.1.1.255
255.255.255.0
[root@server shell06]# ifconfig | sed -nr '/([0-9]{1,3}\.)[0-9]{1,3}/p' | head -1|sed -r 's/([a-z:]|[A-Z/t])//g'|sed 's/ /\n/g'|sed  '/^$/d'

[root@server shell06]# ifconfig eth0|sed -n '2p'|sed -n 's/.*addr:\(.*\) Bcast:\(.*\) Mask:\(.*\)/\1\n\2\n\3/p'
10.1.1.1 
10.1.1.255 
255.255.255.0

-i 选项  直接修改原文件
# sed -i 's/root/ROOT/;s/stu/STU/' 11.txt
# sed -i '17{s/YUNWEI/yunwei/;s#/bin/bash#/sbin/nologin#}' 1.txt
# sed -i '1,5s/^/#&/' a.txt
注意：
-ni  不要一起使用
p命令 不要再使用-i时使用
