#!/bin/bash

debug=${1:-y}
echo $debug
color_text() {
    case "$1" in
        blue)
            echo -e "\e[0;34m$2\e[0m";;
        yellow)
            echo -e "\e[0;33m$2\e[0m";;
        red)
            echo -e "\e[0;31m$2\e[0m";;
        green)
            echo -e "\e[0;32m$2\e[0m";;
    esac
}

sleep_sec() {
    # sleep seconds: $1
    seconds=${1:-10}
    while [ "${seconds}" -ge "0" ];do
        echo -ne "\r     \r"
        echo -n "${seconds}"
        seconds=$((seconds - 1))
        sleep 1
    done
    echo -ne "\r"
}

confirm_ok() {
read -r -p"输入y进入执行过程[按q退出]:" exe
    while [ "$exe" != 'y' ]
    do
        if [[ $exe == 'q' ]];then
            exit
        fi
        read -r -p"输入有误，继续输入[按q退出]:" exe
    done
}

check_container() {
    # 容器ID: $1
    # 命令: $2
    echo "========= 容器检查 ============"
    echo "IP: $ip 容器ID: $1 命令:$2"
    echo ""
    echo "检查磁盘配额: 获得容器的磁盘限额与容器内文件系统容量..."
    docker inspect "$1" | grep -i diskquota
    docker exec "$1" bash -c "df -h"
}

check_afer_fix() {
    # 容器ID: $1
    # max_quotaid: $2
    echo "======= 验证过程 ========="
    echo "1. 确认该Quota ID对应的值已修复"
    echo "命令为:repquota -gans |grep $2"
    # repquota -gans |grep $2

    echo "2. 登录容器，使用df和du命令查看磁盘空间占用率一致"
    echo "命令为: docker exec $1 df -hT"
    # docker exec $1 df -hT
}

current_path=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "${current_path}1" 2>/dev/null || {
    echo "${BASH_SOURCE[0]}[$LINENO] ERROR: The dir \"$current_path\" is not exist, pls check";
    exit 1;
}

ip_addr=$(cat ./iplist)
for ip in $ip_addr
do
    req=''
    filename=$(echo "$ip"|cut -d'.' -f4)

    echo "检查并确认没有未释放的文件句柄..."
    lsof -s 2> /dev/null | grep -i deleted

    while [[ $req != 'q' ]]
    do
        for content in $(cat ./"$filename")
        do
            container=$(echo "$content"|cut -d',' -f1)
            commands=$(echo "$content"|cut -d',' -f2|sed 's/#/ /g'|cut -d':' -f2)
            sourcedir=$(echo "$commands"|awk '{print $NF}')
            mountpoint=$(awk '"'"$(readlink -f "$sourcedir")"'/"~$2"/"{t=length($2);if(t>l){l=t;m=$2}}END{print m}' /proc/mounts)
            quotaid=$(echo -ne "$($commands)" 2>/dev/null)
            destdir=$(docker inspect "$container"|grep -iA1 "$sourcedir"|grep -iA1 source|awk -F'"' 'NR>1 {print $(NF-1)}')

            check_container "$container" "$commands"

            echo "开始确认天眼系统提示的目录异常..."
            if [ -n "$quotaid" ];then
                echo "quotaid 已经存在,开始输出到当前文件exist_quotaid_dir,请确认..."
                echo -e "IP:$ip,\n容器ID:$container,\n异常目录:$sourcedir \n\n" > exist_quotaid_dir
                continue
            elif [[ ! -d "$sourcedir" ]]; then
                echo "不存在该目录$sourcedir,请确认..."
                echo -e "IP:$ip,\n容器ID:$container,\n异常目录:$sourcedir \n\n" > not_exist_quotaid_dir
                continue
            fi

            echo "获取该异常目录的真实磁盘空间占用率,$destdir。"
            #docker exec $container bash -c "du -m --max-depth=1 ${destdir} 2>/dev/null|tail -n1"
            quotadisk=$(docker inspect "$container"|grep -i diskqu |tail -1 |awk -F'"' '{print $(NF-1)}')
            echo "$quotadisk"
            other_quota=$(echo "$quotadisk"|awk -F';' '{print $NF}')
            echo "执行目标修复磁盘容量为: $other_quota"
            echo

            echo "========== 开始执行修复 ==========="
            echo "1. 获取最大quota_num..."
            quota_num=$(repquota -gans |awk -F'#|[[:blank:]]+' '{print $2}' |grep -v '^$' |sort -rn |head -1)
            max_quota_num=$((quota_num + 1))

            echo "2. 设置文件系统目录的QuotaID。"
            echo "命令为: setfattr -n system.subtree -v $max_quota_num $sourcedir"
            confirm_ok
            # setfattr -n system.subtree -v $max_quota_num $sourcedir

            echo "3. 开始设置diskquota"
            echo "命令为: setquota -g $quotaid 0 $max_quota_num 0 0 $mountpoint"
            confirm_ok
            # setquota -g $quotaid 0 $other_quota 0 0 $mountpoint
            echo
            check_afer_fix "$container" "$max_quota_num"
            done
	  req='q'
    done
done
