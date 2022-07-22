#!/bin/bash

#set -o pipefail

############# import prefomance #############
SLB_AG=""
############## End import prefomance ###########
############# Global Variable ############
LOGDATE=$(date "+%Y-%m-%d-%H-%M-%S")
WORKDIR="$(hostname)_cloud_log.$LOGDATE"
SLOGDIR="/var/log"
LOCK_FILE="/var/log/$(hostname).pid"
DATA_FILE="/tmp/data_file.$LOGDATE"
LOGDIR=""
SCOPE_TYPE=""

disable_single=0
need_free_space=5
health_degree=100
list_items=0
target_cmd=""
target_type=""
target_scope=2
checking=0
syslog_tgz=""
no_compress=0
report_only=0
success=0
fail=1
warn=2
skip=3
########### End Global Variable ##########

################################## Utility Function ################################

info()
{
    local info="$1"
    local cmd="echo -e $info"
    echo ""
    eval $cmd
    echo ""
}
msg()
{
    local strings="$1"
    printf "%-80s" "$strings"
}
error()
{
    local info="$1"
    info ""
    info "[Error]: $info"
    exit 1
}
if_command_exist()
{
    local cmd=$1
    command -v ${cmd} > /dev/null
    return $?
}
if_command_not_exist()
{
    local cmd=$1
    if_command_exist $cmd
    [ $? -eq $success ] && return $fail
    return $success
}
ssh_cmd()
{
    local node=$1
    local cmd="$2"

    ssh -n -o LogLevel=error -o BatchMode=yes -o ConnectTimeout=3 root@$node "$cmd"
}
ssh_test()
{
    local node=$1
    local ok=$(ssh -n -o BatchMode=yes -o LogLevel=error -o ConnectTimeout=3 root@$node "echo ok" 2>&1)
    [ "$ok" != "ok" ] && return 1
    return 0
}
cmd_log()
{
    local cmd=$1
    local log=$2
    local action="$3"
    local res=$fail

    msg "Calling: ${cmd:0:60}"

    if_command_not_exist $cmd && result $skip && return
    [ "$action" = "path" ] && cmd="$cmd $log"

    echo "Command: $cmd" >> $log
    eval $cmd >> $log 2>&1
    res=$?
    result $res
}
analysis_log()
{
    local cmd=$1
    local check_fun=$2
    local fix_fun=$3
    local log=$4
    local chk_res=$success
    local fix_res=$success

    [ "$check_fun" = "" ] && return $chk_res
    msg "Checking: ${cmd:0:60}"
    [ ! -e "$log" ] && result $skip && return $chk_res
    eval $check_fun "$log" > "${log}_check" 2>&1
    chk_res=$?
    result ${chk_res}

    [[ "$fix_fun" = "" ]] && return ${chk_res}
    msg "Fixing: ${cmd:0:60}"
    eval $fix_fun "$log" >> "${log}_fix" 2>&1
    fix_res=$?
    result $fix_res
    return $fix_res
}
run_cmd()
{
    local cmd="$1"
    local silent=$2

    [ "$silent" != "" ] && cmd+=" > /dev/null 2>&1"
    eval $cmd
}
cleanup()
{
    rm -f "${LOCK_FILE}"
    rm -f "$DATA_FILE"
    [ "$LOGDIR" != "/" ] && [ $no_compress -eq 0 ] && run_cmd "rm --preserve-root -rf $LOGDIR" "silent"
}
check_single_instance()
{
    [ $disable_single -eq 1 ] && [ $checking -eq 1 ] && return

    if [ -f ${LOCK_FILE} ];then
        info ""
        error "Another $(basename $0) is running, please waiting it finish and then retry !"
    fi
    echo "$$" > "${LOCK_FILE}"
}
check_root()
{
    [ $(whoami) != "root" ] && error "Please run this script as root !"
}
check_file()
{
    local file=$1
    [ ! -e $file ] && info "$file does not exsit ..." && return $fail
    return $success
}
get_system_version()
{
    local type_pattern="Type Data"
    local info_pattern="Default_Info_Data"
    local logdir=$(sed -n "/## $type_pattern ##/,/## End $type_pattern ##/"p $DATA_FILE|grep "$info_pattern"|awk -F: '{print $2}')
    local release=$(sed -n "/## $info_pattern ##/,/## End $info_pattern ##/"p $DATA_FILE|grep -E "^system_release"|awk -F: '{print $4}')
    local release_file="${LOGDIR}/${logdir}/$release"
    cat $release_file
}
is_el5()
{
    local el5=$(get_system_version | grep -c '5\.')
    [ $el5 -eq 1 ] && return 0
    return 1
}
is_el6()
{
    local el6=$(get_system_version | grep -c '6\.')
    [ $el6 -eq 1 ] && return 0
    return 1
}
is_el7()
{
    local el7=$(get_system_version | grep -c '7\.')
    [ $el7 -eq 1 ] && return 0
    return 1
}
show_result()
{
    local report="Check Report Info: "
    local msg="$1"
    local value=$2
    case $value in
        0)
            return
            ;;
        2)
            report+="(WARNING)"
            ;;
        3)
            return
            ;;
        *)
            report+="(FAIL)"
            ;;
    esac
    report+=" $msg"
    echo $report
}
check_and_uncompress_tarball()
{
    local tarball=$(basename $syslog_tgz)
    local tarball_ok=$(echo "$syslog_tgz" | grep -c "tar.gz")

    [ $tarball_ok -eq 0 ] && error "File: $syslog_tgz is not a tarball file !"
    LOGDIR=${SLOGDIR}/${tarball%.tar.gz}
    run_cmd "rm -rf $LOGDIR" "silent"
    info "Start uncompress $syslog_tgz to $SLOGDIR ..."
    tar -zxf $syslog_tgz -C $SLOGDIR
    [ $? -ne 0 ] && error "Uncompress $syslog_tgz failed, exit ..."
    [ ! -d "$LOGDIR" ] && error "Dir $LOGDIR is not a directory !"
}
prepare_to_run()
{
    export LANG=C
    SLOGDIR=$(readlink -f $SLOGDIR)
    LOGDIR="${SLOGDIR}/${WORKDIR}"

    run_cmd "rm -rf $LOGDIR" "silent"
    [ "$syslog_tgz" != "" ] && check_and_uncompress_tarball
    run_cmd "mkdir -p $LOGDIR" "slient"

    case $SCOPE_TYPE in
        'all')
            target_scope=3
            need_free_space=10
            ;;
        'small')
            need_free_space=3
            target_scope=1;;
        *)
            target_scope=2;;
    esac
    [ "$target_type" != "" ] || [ "$target_cmd" != "" ] && need_free_space=3
}
free_space_check()
{
    local dir="$LOGDIR"
    local target=$need_free_space

    local threshold=$(($target * 1024 * 1024))
    local current=$(df -P $(dirname $dir) | grep -v Filesystem | awk '{print int($(NF-2))}')

    [ $current -lt $threshold ] && error "$node: The available space on $dir is less than ${target}G, Please cleanup for more."
}
# 0 success
# 1 failed
# 2 warning
# 3 skip
result()
{
    local res=$1
    case $res in
        0)
            printf "\t\E[1;31;32mPASS\E[0m\n"
            ;;
        2)
            printf "\t\E[1;31;33mWARNING\E[0m\n"
            ;;
        3)
            printf "\t\E[1;31;33mSKIP\E[0m\n"
            ;;
        *)
            printf "\t\E[1;31;31mFAIL\E[0m\n"
            ;;
    esac
}
get_netcard_info()
{
    local log_temp=$(dirname $1)
    local nic_devices=$(ls /sys/class/net/)

    echo "nic_list="$nic_devices
    for device in ${nic_devices}
    do
        if [ "${device}" != 'lo' ] && [ -d /sys/class/net/${device} ]
        then
            local ndir="${log_temp}/${device}"
            mkdir -p $ndir
            /bin/cp -r /sys/class/net/${device}/* "${ndir}"
            ethtool -i ${device} >> "${ndir}/ethtool_i"
            ethtool ${device}    >> "${ndir}/ethtool"
            ethtool -S ${device} >> "${ndir}/ethtool_S"
            ethtool -g ${device} >> "${ndir}/ethtool_g"
            ethtool -k ${device} >> "${ndir}/ethtool_k"
        fi
    done
}
get_bonding_info()
{
    local log_temp=$(dirname $1)

    [ ! -e /proc/net/bonding ] && return $skip

    local bonds=$(cd /proc/net/bonding/;ls)
    echo "$bonds"
    for bond in $bonds
    do
        mkdir -p $log_temp/${bond}
        cat /proc/net/bonding/$bond >> "${log_temp}/${bond}/cat_${bond}"
    done
}
get_raid_type()
{
    local raidtype=""
    local lsmod=$(lsmod)
    local lspci=$(lspci 2>/dev/null)

    # mptSAS/mpt2SAS
    echo $lsmod | egrep -qw "mptsas|mptbase|mpt2sas"
    if [ $? -eq 0 ] && [ -z $raidtype ]; then
        if echo $lsmod | egrep -qw "mpt2sas" && echo $lspci | grep -q "SAS2"; then
            raidtype="mpt2sas"
        elif echo $lsmod | egrep -qw "mptsas" && echo $lspci | grep -q "SAS1" || echo $lsmod | egrep -qw "megaraid_sas,mptsas"; then
            raidtype="mptsas"
        fi
    fi
    # MegaRAID SCSI
    echo $lsmod | egrep -qw "megaraid_mbox|megaraid2"
    if [ $? -eq 0 ] && [ -z $raidtype ]; then
        raidtype="megaraidscsi"
    fi
    # MegaRAID SAS
    echo $lsmod | egrep -qw "megaraid_sas"
    if [ $? -eq 0 ] && [ -z $raidtype ]; then
        raidtype="megaraidsas"
    fi
    # aacRAID
    echo $lsmod | egrep -qw "aacraid"
    if [ $? -eq 0 ] && [ -z $raidtype ]; then
        raidtype="aacraid"
    fi
    # HP RAID
    echo "$lspci" | grep -iE "RAID|SCSI|SAS|SATA" | grep -q "Hewlett-Packard" && echo $lsmod | grep -qE "cciss|hpsa"
    if [ $? -eq 0 ] && [ -z $raidtype ]; then
        raidtype="hpraid"
    fi
    # MegaRAID SAS
    echo "$lspci" | grep -qE "MegaRAID|Dell PowerEdge Expandable RAID controller|MegaRAID SAS"
    if [ $? -eq 0 ] && [ -z $raidtype ]; then
        raidtype="megaraidsas"
    fi
    if [ -z $raidtype ]; then
        raidtype="unknown"
        # echo "this host raid is unknown raid"
    fi
    echo "$raidtype"
}

get_hpraid_log()
{
    local log_temp=$1
    local cmd="/usr/sbin/hpacucli"

    [ -x "/usr/local/bin/hpacucli" ] && cmd="/usr/local/bin/hpacucli"

    mkdir -p $log_temp
    #$cmd version
    $cmd ctrl all show status > ${log_temp}/hpacucli_status.log 2>&1
    $cmd ctrl all show config > ${log_temp}/hpacucli_config.log 2>&1
    $cmd ctrl slot=0 pd all show status > ${log_temp}/hpacucli_pd_status.log 2>&1
    $cmd ctrl slot=0 ld all show > ${log_temp}/hpacucli_ld_status.log 2>&1
    local ld_nums=$(grep -c "logicaldrive" ${log_temp}/hpacucli_ld_status.log)
    local index_ld=1
    while [ $index_ld -le $ld_nums ]
    do
        $cmd ctrl slot=0 ld $index_ld show >> ${log_temp}/hpacucli_allld_status.log 2>&1
        index_ld=$((index_ld+1))
    done
    local pd_id=$(grep "physicaldrive" ${log_temp}/hpacucli_pd_status.log|awk '{print $2}')
    local pd_nums=$(grep -c "physicaldrive" ${log_temp}/hpacucli_pd_status.log)
    local index_pd=1
    while [ $index_pd -le $pd_nums ]
    do
        if [ $index_pd -eq $pd_nums ];then
            pds=$(echo "${pd_id}"|sed -n "${index_pd}p")
        else
            pds=$(echo "${pd_id}\n"|sed -n "${index_pd}p")
        fi
        $cmd ctrl slot=0 pd $pds show >> ${log_temp}/hpacucli_allpd_status.log 2>&1
        index_pd=$((index_pd+1))
    done
}
get_megaraidscsi_log()
{
    local log_temp=$1
    local cmd="/usr/local/sbin/megarc.bin"

    mkdir -p $log_temp
    $cmd -AllAdpInfo > ${log_temp}/alladpinfo.log 2>&1
    $cmd -dispcfg -a0 > ${log_temp}/dispcfg.log 2>&1
}
get_mptsas_log()
{
    local log_temp=$1
    local cmd="/usr/local/sbin/cfggen"

    mkdir -p $log_temp
    $cmd LIST > ${log_temp}/cfggen_list.log 2>&1
}
get_aacraid_log()
{
    local log_temp=$1
    local cmd="/usr/local/sbin/arcconf"
    [ -a "/usr/StorMan/arcconf" ] && cmd="/usr/StorMan/arcconf"

    mkdir -p $log_temp
    $cmd GETVERSION > ${log_temp}/arcconf_getversion.log 2>&1
}
get_mpt2sas_log()
{
    local log_temp=$1
    local cmd="/usr/local/sbin/sas2ircu"

    mkdir -p $log_temp
    $cmd LIST > ${log_temp}/sas2ircu_list.log 2>&1
    local controller_nums=$(awk '$1~/^[0-9]/{print $0}' ${log_temp}/sas2ircu_list.log|wc -l)
    local controller_id=0
    while [ $controller_id -lt $controller_nums ]
    do
        $cmd $controller_id status >> ${log_temp}/sas2ircu_controllers_status.log 2>&1
        $cmd $controller_id display >> ${log_temp}/sas2ircu_controllers_display.log 2>&1
        controller_id=$((controller_id+1))
    done
}
get_megaraidsas_log()
{
    local log_temp="$1"
    local cmd="/opt/MegaRAID/MegaCli/MegaCli64"

    mkdir -p $log_temp
    $cmd -fwtermlog -dsply -aall -NoLog > ${log_temp}/fwtermlog.log 2>&1
    $cmd -adpeventlog -getevents -f ${log_temp}/adpeventlog.log -aall -NoLog >/dev/null 2>&1
    $cmd -phyerrorcounters -aall -NoLog > ${log_temp}/phyerrorcounters.log 2>&1
    $cmd -encinfo -aall -NoLog > ${log_temp}/encinfo.log 2>&1
    $cmd -cfgdsply -aall -NoLog > ${log_temp}/cfgdsply.log 2>&1
    $cmd -adpbbucmd -aall -NoLog > ${log_temp}/adpbbucmd.log
    $cmd -LdPdInfo -aall -NoLog | egrep 'RAID Level|Number Of Drives|Enclosure Device|Slot Number|Virtual Drive|Firmware state|Media Error Count|Predictive Failure Count|Other Error Count' > ${log_temp}/ldpdinfo.log 2>&1
    $cmd -PDList -aall -NoLog | egrep 'Enclosure Device ID|Slot Number|Firmware state|Inquiry Data' > ${log_temp}/pdlist.log 2>&1
    $cmd -AdpAllInfo -aall -NoLog > ${log_temp}/adpallinfo.log 2>&1
}
get_raid_log()
{
    local log_temp=$(dirname $1)
    local raid_type=$(get_raid_type)
    local logdir="${log_temp}/${raid_type}"

    info "raid_controller:$raid_type"
    case $raid_type in
        "megaraidsas")   get_megaraidsas_log "$logdir";;
        "hpraid")        get_hpraid_log "$logdir";;
        "megaraidscsi")  get_megaraidscsi_log "$logdir";;
        "mptsas")        get_mptsas_log "$logdir";;
        "aacraid")       get_aacraid_log "$logdir";;
        "mpt2sas")       get_mpt2sas_log "$logdir";;
        *) echo "Can't find any raid type ...";;
    esac
}

get_disk_info()
{
    local log_temp=$(dirname $1)
    local disks=$(cd /dev/ && ls sd* | grep -v [1-9])

    echo "Disks: $disks"
    for disk in $disks
    do
        local dir="${log_temp}/$disk"
        mkdir -p $dir
        smartctl -a /dev/$disk > "${dir}/smartctl_a"
        smartctl -x /dev/$disk > "${dir}/smartctl_x"
        parted /dev/$disk print > "${dir}/parted"
        cat /sys/block/$disk/queue/scheduler > "${dir}/cat_scheduler"

        cd /sys/block/$disk/queue;
        if [ $? -ne 0 ];then
            continue
        fi
        find . -type f -name '*' -print -exec cat {} \; > "${dir}/q_stat"
    done
}
get_ext4_info()
{
    local log_temp=$(dirname $1)
    local ext4_parts=$(blkid -c /dev/null | grep ext4 | awk -F ":" '{ print $1 }')

    [ "$ext4_parts" = "" ] && return $skip

    echo "ext4 partitions: $ext4_parts"
    for part in $ext4_parts
    do
        local name=$(basename $part)
        local dir="${log_temp}/$name"
        mkdir -p $dir
        dumpe2fs -h $part > "${dir}/dumpe2fs_superblock"
        cat /proc/fs/ext4/$name/options > "${dir}/ext4_options"
        find /proc/fs/jbd2/ -type d -name "$name*" -print -exec cat {}/info \; > "${dir}/jbd2_info"

        cd /sys/fs/ext4/$name
        if [ $? -ne 0 ];then
            continue
        fi
        find . -type f -name '*' -print -exec cat {} \; > "${dir}/ext4_stat"
    done
}
get_ext3_info()
{
    local log_temp=$(dirname $1)
    local ext3_parts=$(blkid -c /dev/null | grep ext3 | awk -F ":" '{ print $1 }')

    [ "$ext3_parts" = "" ] && return $skip

    echo "ext3 partitions: $ext3_parts"
    for part in $ext3_parts
    do
        local name=$(basename $part)
        local dir="${log_temp}/$name"
        mkdir -p $dir
        dumpe2fs -h $part > "${dir}/dumpe2fs_superblock"
        cat /proc/fs/ext3/$name/options > "${dir}/ext3_options"
        find /proc/fs/jbd/ -type d -name "$name*" -print -exec cat {}/info \; > "${dir}/jbd_info"

        cd /sys/fs/ext3/$name
        if [ $? -ne 0 ];then
            continue
        fi
        find . -type f -name '*' -print -exec cat {} \; > "${dir}/ext3_stat"
    done
}
get_aliflash_info()
{
    local log_temp=$(dirname $1)
    local disks=$(cd /dev/ && ls df* | grep -v [1-9])

    [ "$disks" = "" ] && return $skip

    echo "Aliflash: $disks"
    for disk in $disks
    do
        local dir="${log_temp}/$disk"
        mkdir -p $dir
        aliflash-status -a /dev/$disk > "${dir}/aliflash-status_a"
    done
}
get_nvme_features()
{
    local dev=$1
    if [ "$dev" = "" ];then
        echo "no nvme block device"
        return $skip
    fi

    # Check NVMe spec r1.3b
    pages="0x2 0x4 0x7 0x8 0x9 0xa 0xb"
    for page in $pages;do
        nvme get-feature $dev -f $page
    done
}
get_nvme_info()
{
    #https://www.atatech.org/articles/120498
    local log_temp=$(dirname $1)
    local devices=$(ls /dev/ | grep "nvme[0-9]\+$")
    if [ "$devices" = "" ];then
        echo "no nvme device"
        return $skip
    fi

    echo "NVMe: $devices"
    for disk in $devices
    do
        local dir="${log_temp}/$disk"
        mkdir -p $dir
        nvme id-ctrl /dev/$disk > "${dir}/nvme_id_ctrl"
        nvme list-ns /dev/$disk > "${dir}/nvme_list_ns"
        nvme list-ctrl /dev/$disk > "${dir}/nvme_list_ctrl"
        nvme show-regs /dev/$disk > "${dir}/nvme_show_regs"
        get_nvme_features /dev/$disk > "${dir}/nvme_get_features"
        nvme smart-log /dev/$disk > "${dir}/nvme_smart_log"
        nvme smart-log-add /dev/$disk > "${dir}/nvme_smart_log_add"
        nvme error-log /dev/$disk > "${dir}/nvme_error_log"
        nvme fw-log /dev/$disk > "${dir}/nvme_fw_log"

        # NVMe namespace/lun block device
        local nss=$(ls /dev/ | grep ""$disk"n[0-9]\+$")
        if [ "$nss" = "" ];then
            continue
        fi
        echo "NVMe namespace: $nss"
        for ns in $nss
        do
            local ns_dir="${log_temp}/$ns"
            mkdir -p $ns_dir
            nvme id-ns /dev/$ns > "${ns_dir}/nvme_id_ns"
            nvme get-ns-id /dev/$ns > "${ns_dir}/nvme_get_ns_id"
            nvme resv-report /dev/$ns > "${ns_dir}/nvme_resv_report"
        done
    done
}
install_rpm()
{
    local rpm=$1
    yum install -y $rpm
}
get_disk_io_detail()
{
    local dir=$1
    local disk=$2

    mkdir -p $dir
    cd $dir
    blktrace -d /dev/$disk -w 5 > blktrace.log
    blkparse -i $disk -d $disk.blktrace.bin > blkparse.log
    btt -i $disk.blktrace.bin > btt.log
    cd -
}
get_disks_io_detail()
{
    local log_temp=$(dirname $1)
    local debugfs=$(cat /proc/mounts | grep -ic debugfs)
    local disks=$(cd /dev/ && ls sd*)

    if_command_not_exist "blktrace" && install_rpm "blktrace"
    if_command_not_exist "blktrace" && info "Command blktrace install failed ..." && return

    [ $debugfs -eq 0 ] && mount -t debugfs debugfs /sys/kernel/debug
    for disk in $disks
    do
        info "Start geting disk $disk detail ..."
        get_disk_io_detail "${log_temp}/$disk" $disk
    done
    [ $debugfs -eq 0 ] && umount /sys/kernel/debug
}
get_docker_info()
{
    local log_temp=$(dirname $1)
    local dockers=$(docker ps -q)

    #docker ps --no-trunc
    docker ps
    [ $? -ne $success ] && info "None docker running !" && return
    for docker in $dockers
    do
        local ddir="${log_temp}/${docker}"
        mkdir -p $ddir
        docker inspect $docker >> "${ddir}/inspect"
        docker exec $docker free -m >> "${ddir}/free_m"
        docker exec $docker df -h >> "${ddir}/df_h"
    done
}
get_kdump_status()
{
    if is_el7;then
        systemctl status kdump
    else
        /etc/init.d/kdump status
    fi
    return 0
}
compress_log()
{
    local json="$(basename ${LOGDIR})/$(basename ${LOGDIR}).json"
    local html="$(basename ${LOGDIR})/$(basename ${LOGDIR}).html"
    [ $no_compress -eq 1 ] && return
    info "Start compressing log dir ..."
    rm -f ${LOGDIR}.tar.gz
    cd $SLOGDIR
    if [ $report_only -eq 1 ];then
        [ -e $json ] && cp $json .
        [ -e $html ] && cp $html .
        return
    fi
    tar -zcf ${LOGDIR}.tar.gz $(basename $LOGDIR)
    [ $? -ne 0 ] && error "Compress log failed, exit ..."
    md5sum ${LOGDIR}.tar.gz > ${LOGDIR}.tar.gz.md5sum
    echo "Tarball md5 file: ${LOGDIR}.tar.gz.md5sum"
    echo "Tarball file: ${LOGDIR}.tar.gz"
    echo ""
    echo -e "\E[1;31;31mPlease copy the tarball file to level 2 supporter ! \E[0m\n"
}
show_system_info()
{
    echo ""
        if if_command_exist "hwconfig"
    then
        hwconfig
    else
        echo "System:    $(cat /etc/redhat-release)"
        echo "Hostname:  $(hostname -f)"
        echo "Kernel:    $(uname -r)"
        echo "Arch:      $(uname -i)"
        echo "Product:   $(dmidecode -s system-product-name | grep -v '#')"
    fi
}
copy_files()
{
    local src=$1
    local dst=$2

    [ ! -e $src ] && return
    if [ "$3" = "ignore" ];then
        /bin/cp -r "$src" "$dst" 2>/dev/null
    else
        /bin/cp -r "$src" "$dst"
    fi
}

get_top10_process_info()
{
    local top10=$1
    local log_dir=$2

    for pid in $top10
    do
        local dir="${log_dir}/$pid"
        local files=$(ls "/proc/${pid}")
        local exclude="task pagemap"

        [ -d "$dir" ] && continue
        mkdir -p "$dir"
        pmap -x $pid > $dir/pmap_x 2>&1
        pmap -d $pid > $dir/pmap_d 2>&1

        for file in $files
        do
            echo "$exclude" | grep -qw "$file" && continue
            copy_files "/proc/${pid}/$file" "${log_dir}/${pid}/" "ignore"
        done
    done
}

get_top10_mem_process_info()
{
    local file=$1
    local dir=$(dirname $file)

    ps -e -wwo 'pid,comm,psr,pmem,rsz,vsz,stime,user,stat,uid,args' --sort rsz

    local top10_mem=$(tail -10 $file | awk '{print $1}')

    get_top10_process_info "$top10_mem" "$dir"
}
get_top10_cpu_process_info()
{
    local file=$1
    local dir=$(dirname $file)

    ps -e -wwo 'pid,comm,psr,pcpu,rsz,vsz,stime,user,stat,uid,args' --sort pcpu

    local top10_cpu=$(tail -10 $file | awk '{print $1}')
    get_top10_process_info "$top10_cpu" "$dir"
}
get_dns_info()
{
    local domain=$(cat /etc/resolv.conf | grep -v '#' | grep -i search)
    local array=($domain)
    local length=${#array[@]}

    cat /etc/resolv.conf
    for ((i=1; i<$length; i++))
    do
        for dns in $(cat /etc/resolv.conf | grep -v '#' | grep nameserver | awk '{print $2}')
        do
            local full_domain="$(hostname -f)"
            [ "${array[$i]}" != "" ] && full_domain+=".${array[$i]}"
            echo "dig $full_domain @${dns}"
            dig $full_domain @${dns}
        done
    done
}
get_multi_kernel_files()
{
    local destDir="/proc/sys/kernel/"
    find $destDir -type f -name "*$1*" -print -exec cat {} \;
}
get_hung_task() { get_multi_kernel_files "hung_task"; }
get_numa() { get_multi_kernel_files "numa"; }
get_overflow() { get_multi_kernel_files "overflow"; }
get_panic() { get_multi_kernel_files "panic"; }
get_perf() { get_multi_kernel_files "perf"; }
get_max() { get_multi_kernel_files "max"; }
get_print() { get_multi_kernel_files "print"; }
get_sched() { get_multi_kernel_files "sched"; }
get_softlockup() { get_multi_kernel_files "softlockup"; }
get_watchdog() { get_multi_kernel_files "watchdog"; }

get_multi_cgroup_files()
{
    [ ! -d "/sys/fs/cgroup" ] && return $skip
    local destDir="/sys/fs/cgroup/$1"
    find $destDir -type f -name "*" -print -exec cat {} \;
}
get_cgroup_cpu() { get_multi_cgroup_files "cpu"; }
get_cgroup_blkio() { get_multi_cgroup_files "blkio"; }
get_cgroup_perf_event() { get_multi_cgroup_files "perf_event"; }

get_multi_ftrace_files()
{
    [ ! -d "/sys/kernel/debug/tracing" ] && return $skip
    local destDir="/sys/kernel/debug/tracing/"
    find $destDir -type f -name "*$1*" -print -exec cat {} \;
}
get_ftrace_avail() { get_multi_ftrace_files "available"; }

get_numastat()
{
    echo -e "\nnumastat..."; numastat
    echo -e "\nnumastat -c..."; numastat -c
    echo -e "\nnumastat -m..."; numastat -m
    echo -e "\nnumastat -n..."; numastat -n
    return $success
}

get_slabtop()
{
    echo -e "\nslabtop..."; slabtop -o
    echo -e "\nslabtop_a..."; slabtop -o -s a
    echo -e "\nslabtop_b..."; slabtop -o -s b
    echo -e "\nslabtop_c..."; slabtop -o -s c
    echo -e "\nslabtop_n..."; slabtop -o -s n
    echo -e "\nslabtop_s..."; slabtop -o -s s
    echo -e "\nslabtop_u..."; slabtop -o -s u
    return $success
}

get_lsblk()
{
    echo -e "\nlsblk..."; lsblk
    echo -e "\nlsblk_a..."; lsblk -a
    echo -e "\nlsblk_D..."; lsblk -D
    echo -e "\nlsblk_f..."; lsblk -f
    echo -e "\nlsblk_p..."; lsblk -p
    echo -e "\nlsblk_t..."; lsblk -t
    echo -e "\nlsblk_S..."; lsblk -S
    return $success
}

get_dmesg_H() { if is_el7;then dmesg -H;else return $skip;fi }
get_schedstat() { if is_el5 || is_el6;then cat /proc/schedstat;else return $skip;fi }
get_sched_features() { file="/sys/kernel/debug/sched_features";if [ -f $file ];then cat $file;fi }

get_sysvm()
{
    [ ! -d "/proc/sys/vm" ] && return $skip
    find /proc/sys/vm/ -type f -name "*" -print -exec cat {} \;
}

verify_rpmdb()
{
    [ ! -e /var/lib/rpm/Packages ] && return $skip
    /usr/lib/rpm/rpmdb_verify /var/lib/rpm/Packages   
}
get_mc_ip_v2()
{
    local service=$1
    local config=$(docker ps -a | grep api | awk '{print $1}' | xargs docker inspect | grep "L1root/L1tools/main/config" | awk -F : '{print $2}' | awk -F '"' '{print $2}' | sed -n 2p)
    local ctable="${config}/container_arrangement.csv"
    local ips=$(grep $service $ctable | awk -F, '{print $4}')
    echo "$ips"
}
get_slb_control_master_ip_v2()
{
    local slb_control_masters=$(get_mc_ip_v2 "slb-control-master")
    echo "$slb_control_masters"
}
get_slb_control_haproxy_v2()
{
    local slb_control_haproxy=$(get_mc_ip_v2 "slb-control-haproxy")
    echo "$slb_control_haproxy"
}
get_slb_ag_ip_v2()
{
    if [ "$SLB_AG" = "" ];then
        local slb_ag=$(get_mc_ip_v2 "slb-ag")
        SLB_AG=$slb_ag
    fi
    echo "$SLB_AG"
}
get_slb_ag_ip()
{
    local res=0
    local slb_ag=$(get_slb_ag_ip_v2)
    ssh_test $slb_ag
    res=$?
    [ $res -eq 0 ] && echo "$slb_ag"
    [ $res -ne 0 ] && echo "none"
}

get_lvs_status()
{
    local slb_ag=$(get_slb_ag_ip)
    [ "$slb_ag" != "none" ] && ssh_cmd $slb_ag "echo 'list admin lb_node' | cli docker 3.4.0" | grep -v mysql
}
get_lvs_proxy_status()
{
    local slb_ag=$(get_slb_ag_ip)
    [ "$slb_ag" != "none" ] && ssh_cmd $slb_ag "echo 'list admin proxy' | cli docker 3.4.0" | grep -v mysql
}
get_slb_ag_log()
{
    local slb_ag=$(get_slb_ag_ip)
    [ "$slb_ag" != "none" ] && ssh_cmd $slb_ag "tail -n 10000 /home/slb/ag/slb-test_run.log"
}
get_slb_ag_cron_status()
{
    local slb_ag=$(get_slb_ag_ip)
    [ "$slb_ag" != "none" ] && ssh_cmd $slb_ag "/etc/init.d/crond status"
}
get_slb_ag_date()
{
    local slb_ag=$(get_slb_ag_ip)
    [ "$slb_ag" != "none" ] && ssh_cmd $slb_ag "date"
}
get_slb_ag_show_tables()
{
    local slb_ag=$(get_slb_ag_ip)
    [ "$slb_ag" != "none" ] && ssh_cmd $slb_ag "sh /etc/slb/slb_db_show_tables.sh"
}
run_xuanyuan_cmd()
{
    local sql=$1
    local slb_ag=$(get_slb_ag_ip)
    local cmd=""
    
    [ "$slb_ag" = "none" ] && echo "Get slb ap ip error ..." && return 0
    
    cmd=$(ssh_cmd $slb_ag "cat /etc/slb/cluster_db.sh" | grep "slb_master_db" |awk -F= '{print $2}'|tr "\"" " "|sed 's/^[ ]//g')
    ssh_cmd $slb_ag "$cmd -t -e \"$sql\""
}
get_network_service_unit()
{
    run_xuanyuan_cmd "select * from network_service_unit;"
}
get_service_unit_bid()
{
    run_xuanyuan_cmd "select * from service_unit_bid;"
}
get_slb_intranet_vip_info()
{
    run_xuanyuan_cmd "select ip.status, count(*) from ip join network on ip.network_id = network.id where network.type = 'intranet' group by ip.status;"
}
get_slb_internet_vip_info()
{
    run_xuanyuan_cmd "select ip.status, count(*) from ip join network on ip.network_id = network.id where network.type = 'internet' group by ip.status;"
}
get_slb_vip_plan()
{
    run_xuanyuan_cmd "select * from network;"
}
get_slb_ag_agent()
{
    run_xuanyuan_cmd "select * from agent;"
}
get_slb_userid_and_count_info()
{
    run_xuanyuan_cmd "select ip.status, loadbalancer.user_id, loadbalancer.bid, count(*) from ip join network on ip.network_id = network.id join loadbalancer on loadbalancer.id = ip.lb_id where network.type = 'intranet' and loadbalancer.status = 'active' group by ip.status, loadbalancer.user_id, loadbalancer.bid;"
}
get_slb_control_master_status()
{
    local dir=$(dirname $1)
    local slb_ag=$(get_slb_ag_ip)
    local slb_cms=$(get_slb_control_master_ip_v2)
    [ "$slb_ag" = "" ] && echo "Didn't get slb ag ip ..." && return 0

    for ip in $slb_cms
    do
        local ip_dir="${dir}/${ip}"
        mkdir -p $ip_dir
        ssh_test $ip
        [ $? -ne 0 ] && echo "slb control master ip: $ip is not accessible ..."
        echo "slb control master ip: $ip"
        ssh_cmd $ip "service slb-control-master status" > "${ip_dir}/slb_control_master_status" 2>&1
    done
}
get_slb_control_haproxy_status()
{
    local dir=$(dirname $1)
    local slb_ag=$(get_slb_ag_ip)
    local slb_ha=$(get_slb_control_haproxy_v2)
    [ "$slb_ag" = "" ] && echo "Didn't get slb ag ip ..." && return 0

    for ip in $slb_ha
    do
        local ip_dir="${dir}/${ip}"
        mkdir -p $ip_dir
        ssh_test $ip
        [ $? -ne 0 ] && echo "slb control haproxy ip: $ip is not accessible ..."
        echo "slb control haproxy ip: $ip"
        ssh_cmd $ip "service haproxy status" > "${ip_dir}/slb_control_haproxy_status" 2>&1
    done
}
get_lvs_servers_status()
{
    local dir=$(dirname $1)
    local slb_ag=$(get_slb_ag_ip)
    local lvs_ips=""
    [ "$slb_ag" = "" ] && echo "Didn't get slb ag ip ..." && return 0
    lvs_ips=$(ssh_cmd $slb_ag "echo 'list admin lb_node' | cli docker 3.4.0" | grep -v mysql | grep ip_addr -A 2 | grep -v ip_addr | awk '{print $1}')
    for ip in $lvs_ips
    do
        local ip_dir="${dir}/${ip}"
        local info_log=$(ssh_cmd $ip "ls -lrt /home/slb/logs/slb-controller/info.log*" | tail -1 | awk '{print $NF}')
        local monitor_host=$(ssh_cmd $ip "cat /home/slb/control-lvs/conf/agent.yaml" | grep -w monitor_host | awk -F: '{print $2}')
        local monitor_port=$(ssh_cmd $ip "cat /home/slb/control-lvs/conf/agent.yaml" | grep -w monitor_port | awk -F: '{print $2}')
        local host=$(ssh_cmd $ip "cat /home/slb/control-lvs/conf/agent.yaml" | grep -w host | awk -F: '{print $2}')
        
        mkdir -p "$ip_dir"
        ssh_cmd $ip "tail -10000 $info_log" > "${ip_dir}/${info_log##*/}" 2>&1
        ssh_cmd $ip "cat /home/slb/control-lvs/conf/agent.yaml" > "${ip_dir}/agent.yaml" 2>&1
        ssh_cmd $ip "tail -10000 /home/slb/control-lvs/logs/debug.heart_beat.log" > "${ip_dir}/debug.heart_beat.log" 2>&1
        ssh_cmd $ip "nc -vzw 6 $monitor_host $monitor_port -s $host" > "${ip_dir}/nc_vzw" 2>&1
        ssh_cmd $ip "service slb-control-lvs status" > "${ip_dir}/slb_control_lvs_status" 2>&1
        ssh_cmd $ip "service slb-monitor-lvs status" "${ip_dir}/slb_monitor_lvs_status" 2>&1
        ssh_cmd $ip "service slb-ecmpd status" > "${ip_dir}/slb_ecmpd_status" 2>&1
        ssh_cmd $ip "/etc/init.d/keepalived status" > "${ip_dir}/keepalived_status" 2>&1
        ssh_cmd $ip "cat /proc/net/ip_vs_conn_stats" > "${ip_dir}/proc_net_ip_vs_conn_stats" 2>&1
        ssh_cmd $ip "ipvsadm --list --daemon" > "${ip_dir}/ipvs_adm__list__daemon" 2>&1
        ssh_cmd $ip "ipvsadm -Ln" > "${ip_dir}/ipvs_adm_Ln" 2>&1
        ssh_cmd $ip "session_admin --list-daemon" > "${ip_dir}/session_admion__list_daemon" 2>&1
        ssh_cmd $ip "sh /home/slb/libexec/slb-multicast-test.sh" > "${ip_dir}/slb_multicast_test_sh" 2>&1
        ssh_cmd $ip "appctl -csa | grep conns" > "${ip_dir}/appctl_csa" 2>&1
        ssh_cmd $ip "vtysh -c 'sh ip os nei'" > "${ip_dir}/vtysh_sh_ip_os_nei" 2>&1
        ssh_cmd $ip "ifconfig T1" > "${ip_dir}/ifconfig_T1" 2>&1
        ssh_cmd $ip "ethtool  T1" > "${ip_dir}/ethtool_T1" 2>&1
        ssh_cmd $ip "ifconfig T2" > "${ip_dir}/ifconfig_T2" 2>&1
        ssh_cmd $ip "ethtool  T2" > "${ip_dir}/ethtool_T2" 2>&1
        ssh_cmd $ip "ifconfig dummy0" > "${ip_dir}/ifconfig_dummy0" 2>&1
        ssh_cmd $ip "date" > "${ip_dir}/date" 2>&1
    done
}
get_lvs_servers_proxy_status()
{
    local dir=$(dirname $1)
    local slb_ag=$(get_slb_ag_ip)
    local lvs_proxy_ips=""
    [ "$slb_ag" = "" ] && echo "Didn't get slb ag ip ..." && return 0

    lvs_proxy_ips=$(ssh_cmd $slb_ag "echo 'list admin proxy' | cli docker 3.4.0" | grep -v mysql | grep ip_addr -A 2 | grep -v ip_addr | awk '{print $1}')
    for ip in $lvs_proxy_ips
    do
        local ip_dir="${dir}/${ip}"
        local info_log=$(ssh_cmd $ip "ls -lrt /home/slb/logs/slb-controller/info.log*" | tail -1 | awk '{print $NF}')
        local monitor_host=$(ssh_cmd $ip "cat /home/slb/control-proxy/conf/agent.yaml" | grep -w monitor_host | awk -F: '{print $2}')
        local monitor_port=$(ssh_cmd $ip "cat /home/slb/control-proxy/conf/agent.yaml" | grep -w monitor_port | awk -F: '{print $2}')
        local host=$(ssh_cmd $ip "cat /home/slb/control-proxy/conf/agent.yaml" | grep -w host | awk -F: '{print $2}')
        mkdir -p "$ip_dir"
        ssh_cmd $ip "tail -10000 $info_log" > "${ip_dir}/${info_log##*/}" 2>&1
        ssh_cmd $ip "tail -10000 /home/slb/control-proxy/logs/debug.heart_beat.log" > "${ip_dir}/debug.heart_beat.log" 2>&1
        ssh_cmd $ip "cat /home/slb/control-proxy/conf/agent.yaml" > "${ip_dir}/agent.yaml" 2>&1
        ssh_cmd $ip "nc -vzw 6 $monitor_host $monitor_port -s $host" > "${ip_dir}/nc_vzw" 2>&1
        ssh_cmd $ip "service slb-control-proxy status" > "${ip_dir}/slb_control_proxy_status" 2>&1
        ssh_cmd $ip "service slb-tengine status" > "${ip_dir}/slb_tengine_status" 2>&1
        ssh_cmd $ip "service slb-ospfd status" > "${ip_dir}/slb_ospfd_status" 2>&1
        ssh_cmd $ip "sh /home/slb/libexec/slb-multicast-test.sh" > "${ip_dir}/slb_multicast_test_sh" 2>&1
        ssh_cmd $ip "appctl -csa | grep conns" > "${ip_dir}/appctl_csa" 2>&1
        ssh_cmd $ip "vtysh -c 'sh ip os nei'" > "${ip_dir}/vtysh_sh_ip_os_nei" 2>&1
        ssh_cmd $ip "ifconfig T1" > "${ip_dir}/ifconfig_T1" 2>&1
        ssh_cmd $ip "ethtool  T1" > "${ip_dir}/ethtool_T1" 2>&1
        ssh_cmd $ip "ifconfig T2" > "${ip_dir}/ifconfig_T2" 2>&1
        ssh_cmd $ip "ethtool  T2" > "${ip_dir}/ethtool_T2" 2>&1
        ssh_cmd $ip "ifconfig dummy0" > "${ip_dir}/ifconfig_dummy0" 2>&1
        ssh_cmd $ip "date" > "${ip_dir}/date" 2>&1
    done
}
format_system_info()
{
        echo "System Hostname Kernel Arch Product"
        system="$(cat /etc/redhat-release | sed 's/ /_/g')"
        hostname="$(hostname -f | sed 's/ /_/g')"
        kernel="$(uname -r | sed 's/ /_/g')"
        arch="$(uname -i | sed 's/ /_/g')"
        product="$(dmidecode -s system-product-name | grep -v '#' | sed 's/ /_/g')"
        echo "$system $hostname $kernel $arch $product"
}
format_df()
{
    df 2>/dev/null | grep . | grep -iv tmpfs | sed 's/Mounted on/Mounted_on/'
}
format_df_i()
{
    df -i 2>/dev/null | grep . | grep -iv tmpfs | sed 's/Mounted on/Mounted_on/'
}
format_ntpq_np()
{
    ntpq -np 2>/dev/null |  grep . | grep -iv '='
}
format_sar_n_dev()
{
    sar -n DEV 1 1 2>/dev/null | grep . | grep -iv average | grep -iv linux | awk '{$1=""; print $0}'
}
format_iostat()
{
    iostat -xm 2>/dev/null | grep . | tail -n +4
}
format_free()
{
    free 2>/dev/null | grep . | grep -iv swap | grep -iv 'buffers/cache' | sed 's/^[ ]*//' | sed 's/Mem:[ ]*//'
}
format_uptime()
{
    uptime | perl -nle '/load average:[ ]*([^,]*),[ ]*([^,]*),[ ]*(.*)/ && printf("load1 load5 load15\n%s %s %s\n", $1,$2,$3)'
}
format_mpstat()
{
    mpstat -P ALL 1 1 2>/dev/null | grep . | grep -iv average | grep -iv linux | awk '{$1=""; print $0}'
}

check_lvs_status()
{
	local log_file=$1
	local res=$success
	local key=""
	local status=$(cat ${log_file}|grep -c "online")
	[ $status -ne 2 ] && key="Lvs not both online" && res=$fail
	show_result "$key" "$res"
	return $res
}

check_lvs_proxy_status()
{
	local log_file=$1
	local res=$success
	local key=""
	local status=$(cat ${log_file}|grep -c "online")
	[ $status -ne 2 ] && key="Lvs proxy not both online" && res=$fail
	show_result "$key" "$res"
	return $res
}

check_slb_intranet_vip()
{
	local log_file=$1
	local res=$success
	local key=""
    local frozen_num=$(cat $log_file|grep "frozen"|awk -F"|" '{print $3}'|sed 's/ //g')
    local released_num=$(cat $log_file|grep "released"|awk -F"|" '{print $3}'|sed 's/ //g')
    local available_num=$((frozen_num + released_num))
    [ $available_num -lt 10 ] && key="Available intranet vip $available_num" && res=$fail		
	show_result "$key" "$res"
	return $res
}

check_slb_internet_vip()
{
	local log_file=$1
	local res=$success
	local key=""
    local frozen_num=$(cat $log_file|grep "frozen"|awk -F"|" '{print $3}'|sed 's/ //g')
    local released_num=$(cat $log_file|grep "released"|awk -F"|" '{print $3}'|sed 's/ //g')
    local available_num=$((frozen_num + released_num))
    [ $available_num -lt 10 ] && key="Available internet vip $available_num" && res=$fail
    show_result "$key" "$res"
	return $res
}

copy_system_files()
{
    local dir=$(dirname $1)
    local kern="/var/log/kern"
    local messages="/var/log/messages"
    local tsar="/var/log/tsar.data"
    copy_files "$kern" "$dir/"
    copy_files "$messages" "$dir/"
    copy_files "$tsar" "$dir/"
    
    /bin/cp /var/log/kern-* "$dir/"
    
    [ -e $kern ] && echo "$kern" && tail -200 $kern
    [ -e $messages ] && echo "$messages" && tail -200 $messages
    return $success
}
copy_other_files()
{
    local dir=$(dirname $1)
    copy_files "/boot/grub/" "$dir/"
    copy_files "/etc/sysctl.conf" "$dir/"
    copy_files "/etc/security/limits.conf" "$dir/"
    copy_files "/var/log/secure" "$dir/"
    copy_files "/var/log/sa/" "$dir"
    return $success
}
copy_all_files()
{
    local dir=$(dirname $1)
    /bin/cp /var/log/messages* "$dir/"
    /bin/cp /var/log/kern* "$dir/"
    /bin/cp /var/log/secure* "$dir/"
    return $success
}
check_user_behavior()
{
    local log_file=$1
    local res=$success
    local status=$(egrep -c "reboot|shutdown|ctrlatdel|poweroff|init" $log_file)
    local key=''
    [ $status -ne 0 ] && key="History cmd include reboot shutdown ctrlatdel or poweroff " && res=$warn
    show_result "$key" "$res"
    return $res
}
check_disk_size()
{
    local log_file=$1
    local res=$success
    local df_lines=$(grep -vE 'Command|Filesystem|SSDCache' $log_file|grep "%")
    local is_fail=""

    while read item
    do
        local fs=$(echo "$item"|awk '{print $NF}')
        local usage=$(echo "$item"|awk '{print $(NF-1)}'|sed 's/%//g')
        [ $usage -ge 95 ] && show_result "File system $fs usage > 95%" $fail && is_fail="true" && continue
        [ $usage -ge 80 ] && show_result "File system $fs usage > 80%" $warn && res=$warn
    done <<< "$df_lines"
    [[ $is_fail == "true" ]] && return $fail || return $res
}
check_disk_inode()
{
    local log_file=$1
    local res=$success
    local df_lines=$(grep -vE 'Command|Filesystem' $log_file|grep "%")
    local is_fail=""

    while read item
    do
        local fs=$(echo "$item"|awk '{print $NF}')
        local usage=$(echo "$item"|awk '{print $(NF-1)}'|sed 's/%//g')
        [ $usage -ge 95 ] && show_result "File system $fs inode usage >= 95%" $fail && is_fail="true" && continue
        [ $usage -ge 80 ] && show_result "File system $fs inode usage >= 80%" $warn && res=$warn
    done <<< "$df_lines"
    [[ $is_fail == "true" ]] && return $fail || return $res
}

check_free_memory()
{
    local log_file=$1
    local res=$success
    local key=''
    local total=$(cat $log_file | grep Mem | awk '{print $2}')
    local used=$(cat $log_file | grep buffers/cache | awk '{print $3}')
    is_el7 && local used=$(($(cat $log_file | grep Mem | awk '{print $2}')-$(cat $log_file | grep Mem | awk '{print $NF}')))
    local used_percentage=$((${used}*100/${total}))
    [[ ${used_percentage} -ge 80 ]] && key="Memory usage > 80%"  && res=$warn
    [[ ${used_percentage} -ge 90 ]] && key="Memory usage > 90%"  && res=$fail
    show_result "$key" "$res"
    return $res
}
check_process_status()
{
    local log_file=$1
    local res=$success
    local key=''
    local num_D=$(awk '{print $9}' $log_file | grep -c 'D')
    local num_Z=$(awk '{print $9}' $log_file | grep -c 'Z')
    local total=$(($num_D + $num_Z))
    echo "total=${total}"
    [ $total -ge 100 ] && key="Process statistics: PS_STAT D and PS_STAT Z total > 100" && res=$warn
    [ $total -ge 200 ] && key="Process statistics: PS_STAT D and PS_STAT Z total > 200" && res=$fail
    show_result "$key" "$res"
    return $res
}
check_system_load()
{
    local log_file=$1
    local res=$success
    local key=""
    local average_data=$(grep -w 'average' $log_file | awk -F"average:" '{print $2}'|sed "s/,//g")
    local one_minutes_average=$(printf "%.0f" $(echo ${average_data} | awk '{print $1}'))
    local five_minutes_average=$(printf "%.0f" $(echo ${average_data} | awk '{print $2}'))
    local fifteen_minutes_average=$(printf "%.0f" $(echo ${average_data} | awk '{print $3}'))
    [ $one_minutes_average -ge 100 ] && key="The average load of the system in the last 1 minutes > 100" && res=$warn
    [ $five_minutes_average -ge 80 ] && key="The average load of the system in the last 5 minutes > 80" &&res=$warn
    [ $fifteen_minutes_average -ge 50 ] && key="The average load of the system in the last 15 minutes > 50" && res=$warn
    [ $one_minutes_average -ge 150 ] && key="The average load of the system in the last 1 minutes > 150" && res=$fail
    [ $five_minutes_average -ge 120 ] && key="The average load of the system in the last 5 minutes > 120" && res=$fail
    [ $fifteen_minutes_average -ge 100 ] && key="The average load of the system in the last 15 minutes > 100" && res=$fail
    show_result "$key" "$res"
    return $res
}
check_readonly()
{
    local log_file=$1
    local fs_lines=$(grep -vE "Command|tmpfs /sys/fs/cgroup" $log_file)
    local res=$success
    local fs=""
    local status=0
    for fs_line in $fs_lines
    do
        fs=$(echo $fs_line|awk '{print $2}')
        status=$(echo $fs_line|awk '{print $4}'|grep -wc ro)
        [[ $status -ne 0  ]] && show_result "$fs is read-only" $fail && res=$fail
    done
    return $res
}
get_fstab_info()
{
    echo "########## mount info #############"
    mount
    echo "######### end mount info ###########"
    echo "########## fstab info ############"
    cat /etc/fstab | grep -vi swap
    echo "######### end fstab info #########"
}
check_fstab()
{
    local log_file=$1
    local res=$success
    local key=""
    local mount=$(sed -n "/## mount info ##/,/## end mount info ##/"p $log_file | grep -v '#')
    local fstab=$(sed -n "/## fstab info ##/,/## end fstab info ##/"p $log_file | grep -v '#' | awk '{print $2}')
    while read item
    do
        local ok=0
        [ "$item" = "" ] && continue
        while read line
        do
            ok=$(echo $line | grep -cw "$item")
            [ $ok -ne 0 ] && break
        done <<< "$mount"
        [ $ok -eq 0 ] && res=$fail && show_result "fstab: $item is error." "$res"
    done <<< "$fstab"
    return $res
}
get_kdump_conf()
{
    local device=$(df -lh /var | tail -1 | awk '{print $1}')
    local fs=$(mount|grep -w $device|awk '{print $(NF-1)}')
    echo "########## device info #############"
    echo "$device"
    echo "######### end device info ###########"
    echo "########## filesystem info ############"
    echo "$fs"
    echo "######### end filesystem info #########"
    echo "########## config info ##########"
    grep -v '#' /etc/kdump.conf | grep -v -e '^[[:space:]]*$'
    echo "######## end config info ########"  
}
check_kdump_status()
{
    local log_file=$1
    local res=$fail
    local key="Service kdump status is not operational"
    local status=$(cat $log_file | egrep -wc "not|unrecognized|unsupported|inactive")
    [[ $status -eq 0  ]] && res=$success
    show_result "$key" "$res"
    return $res
}
check_kdump_config()
{
    local log_file=$1
    local res=$success
    local key="Kdump config err: "
    local device=$(sed -n "/## device info ##/,/## end device info ##/"p $log_file | grep -v '#')
    local filesystem=$(sed -n "/## filesystem info ##/,/## end filesystem info ##/"p $log_file | grep -v '#')
    local s_fs_dev=$(sed -n "/## config info ##/,/## end config info ##/"p $log_file | grep -v '#'|head -1)
    local s_path=$(sed -n "/## config info ##/,/## end config info ##/"p $log_file | grep -v '#'|grep 'path')
    local s_core=$(sed -n "/## config info ##/,/## end config info ##/"p $log_file | grep -v '#'|grep 'core_collector')
    local s_modules=$(sed -n "/## config info ##/,/## end config info ##/"p $log_file | grep -v '#'|grep 'extra_modules')
    local s_default=$(sed -n "/## config info ##/,/## end config info ##/"p $log_file | grep -v '#'|grep 'default')

    local first_line="$filesystem $device"
    local second_line="path /var/crash"
    local third_line="core_collector makedumpfile -c --message-level 1 -d 31"
    local fourly_line="extra_modules mpt2sas mpt3sas megaraid_sas hpsa ahci"
    local five_line="default reboot"
    [[ "$s_fs_dev" != "$first_line" ]] && show_result "fs type and/or device is wrong" $fail && res=$fail
    [[ "$s_path" != "$second_line" ]] && show_result "$s_path is not $second_line" $fail && res=$fail
    [[ "$s_core" != "$third_line" ]] && show_result "$s_core is not $third_line" $fail && res=$fail
    [[ "$s_modules" != "$fourly_line" ]] && show_result "$s_modules is not $fourly_line" $fail && res=$fail
    [[ "$s_default" != "$five_line" ]] && show_result "$s_default is not $five_line" $fail && res=$fail
    return $res
}
check_cmdline_config()
{
    local log_file=$1
    local res=$success
    local key=""
    local conman_status=$(grep -c 'ttyS' ${log_file})
    is_el5 && local status=$(grep -wc 'crashkernel=[0-9]\+M@[0-9]\+M' ${log_file})
    is_el6 && local status=$(grep -wc 'crashkernel=256M' ${log_file})
    is_el7 && local status=$(grep -wc 'crashkernel=auto' ${log_file})
    [[ ${status} -eq 0 ]] && show_result "crashkernel option is wrong" $fail && res=$fail
    [ $conman_status -eq 0 ] && show_result "conman have no config of ttyS0/ttyS1" $fail && res=$fail
    return $res
}
check_io_utilize()
{
    local log_file=$1
    local res=$success
    local key=""
    local util_index=$(awk '{for(i=1;i<=NF;i++)if($i ~ /'^%util$'/) print i }' $log_file | head -1)
    local iowait_index=$(awk '{for(i=1;i<=NF;i++)if($i ~ /'^%iowait$'/) print i }' $log_file | head -1)
    local iowait_data=$(awk '$'${util_index}'=="" {print $0}' $log_file | grep  -v '^[A-Za-z]+*' | awk '{print $'$((${iowait_index}-1))'}')
    local iowait_total=0
    for num in $iowait_data; do iowait_total=$(awk 'BEGIN{print '${iowait_total}'+'${num}'}') ; done
    local iowait_average_6=$(printf '%.0f' $(awk 'BEGIN{print '${iowait_total}'/6}'))
    [ $iowait_average_6 -ge 100  ] && key="IOwait average > 100" &&  res=$warn
    local util_data=$(awk  '$'${util_index}'!="" {print $0}' $log_file | grep -v 'Device:')
    local devic_num=$(($(echo "$util_data" | wc -l)/6))
    for devic in $(seq ${devic_num})
    do
        local devic_name=$(echo "$util_data" | awk 'NR=='${devic}' {print $1}')
        local devic_io_data=$(grep -w "$devic_name" $log_file | awk '{print $'${util_index}'}')
        local total=0
        for num in $devic_io_data; do total=$(awk 'BEGIN{print '${total}'+'${num}' }') ; done
        local devic_io_average_6=$(printf '%.0f' $(awk 'BEGIN{print '${total}'/6}'))
        [ $devic_io_average_6 -ge 80 ] && key="IO average util > 80 " && res=$warn
        [ $devic_io_average_6 -ge 100 ] && key="IO average util > 100" && res=$fail && break
    done
    [ $iowait_average_6 -ge 200  ] && key="IOwait average >200" && res=$fail
    show_result "$key" "$res"
    return $res
}
kernel_bug()
{
    local confirm=$1
    local key=$2
    local info="Kernel bug: $key"
    #confirm 1 means we have confirmed it is a bug
    [ $confirm -ne 1 ] && echo -n "Suspect: "
    echo $info
}
kernel_bug_known()
{
    local confirm=$1
    local key=$2
    local info="Known kernel bug: $key"
    [ $confirm -ne 1 ] && echo -n "Suspect: "
    echo $info
}
confirm_bug()
{
    local line=$1
    local msg=$2
    local logfile=$3
    local confirm=1

    local OLD_IFS="$IFS"
    IFS="@"
    local array=($line)
    IFS="$OLD_IFS"
    local length=${#array[@]}

    for ((i=2; i<$length; i++))
    do
        local ok=$(grep -A 100 -B 100 -i "$msg" "$logfile" | grep -ic "${array[$i]}")
        [ $ok -eq 0 ] && confirm=0
    done
    return $confirm
}
kernel_error_message()
{
    local logfile=$1
    local res=$success
    local info_type="Kernel Bug Info Data"
    local info_data=$(sed -n "/## $info_type ##/,/## End $info_type ##/"p $DATA_FILE | grep -v '#')
    while read line
    do
        local action_fun=$(echo $line | awk -F "@" '{print $1}')
        local err_info=$(echo $line | awk -F "@" '{print $2}')
        local bug=$(grep -ic "$err_info" $logfile)
        local msg=$(grep -i "$err_info" $logfile)

        if [ $bug -ne 0 ]
        then
            local confirm=0
            confirm_bug "$line" "$err_info" "$logfile"
            confirm=$?
            eval "$action_fun" $confirm "\"$msg\""
            res=$fail
        fi
    done<<<"$info_data"

    return $res
}
check_ipmi_device()
{
    local log=$1
    local ok=$(cat "$log" | grep -c "Could not open device")
    [ $ok -ne 0 ] && show_result "Ipmi module did not load." $fail && return $fail
    return $success
}
check_ipmi_event()
{
    local logfile=$1
    local res=$success
    local info_type="Ipmi Event Data"
    local info_data=$(sed -n "/## $info_type ##/,/## End $info_type ##/"p $DATA_FILE | grep -v '##')

    check_ipmi_device "$logfile"
    [ $? -eq $fail ] && return $fail

    while read line
    do
        local msg=$(echo $line | awk -F "@" '{print $1}')
        local key=$(echo $line | awk -F "@" '{print $2}')
        local fail=$(cat $logfile | grep -c "$key")
        [ $fail -ne 0 ] && res=$fail && show_result "${msg}: $key" $res
    done<<<"$info_data"
    
    return $res
}
check_system_log()
{
    local log_file=$1
    local res=""
    local key=""
    local log_dir=$(dirname $log_file)
    key=$(kernel_error_message "${log_dir}/kern")
    res=$?
    if [ $res -eq $success ];then
         key=$(kernel_error_message "${log_dir}/messages")
         res=$?
    fi
    show_result "$key" "$res"
    return $res
}
check_dmesg()
{
    local log_file=$1
    local res=""
    local key=""
    key=$(kernel_error_message $log_file)
    res=$?
    show_result "$key" "$res"
    return $res
}

check_openfiles()
{
    local log_file=$1
    local res=$success
    local key=""
    local status=$(cat ${log_file} | grep -Fc '(deleted)')
    [[ $status -ne 0 ]] && key="Current system open file exists deleted state" && res=$warn
    show_result "$key" "$res"
    return $res
}

check_netcard()
{
    local log=$1
    local log_dir=$(dirname "$log")
    local nic_devices=$(ls -ld ${log_dir}/*/|awk '{print $9}'|awk -F / '{print $6}')
    local LinkState=""
    local DuplexMode=""
    local res=$success
    local nic_numbers=0
    for device in ${nic_devices}
    do
        if [ "${device}" != 'lo' ] && [ -d "${log_dir}/${device}" ]
        then
            [ ! -e ${log_dir}/${device}/device ] && continue
            LinkState=$(cat ${log_dir}/${device}/operstate)
            DuplexMode=$(cat ${log_dir}/${device}/duplex)
            [ "$LinkState" != "up" ] && show_result "the netcard $device link state is $LinkState" $fail && res=$fail
            [ "$DuplexMode" != "full" ] && show_result "the netcard $device duplex mode is $DuplexMode" $fail && res=$fail
        fi
    done
    return $res
}

check_docker_mem()
{
    local dockers=$1
    local log_dir=$2
    local res=$success
    local is_fail=""

    for docker in ${dockers}
    do
        local docker_path="${log_dir}/${docker}"
        local total=$(cat "$docker_path/free_m" | grep 'Mem' | awk '{print $2}')
        local used=$(cat "$docker_path/free_m" | grep buffers/cache | awk '{print $3}')
        local is_el5_6_status=$(cat "$docker_path/free_m" | grep -Fc "/+ buffers/cache")
        [ $is_el5_6_status -eq 0 ] && used=$(($(cat "$docker_path/free_m" | grep 'Mem' | awk '{print $2}')-$(cat "$docker_path/free_m" | grep 'Mem' | awk '{print $NF}')))
        local used_percentage=$((${used}*100/${total}))
        [ ${used_percentage} -ge 90 ] && show_result "Docker: $docker ,Mem total: $total ,used: $used ,Used percentage: $used_percentage > %90" $fail && is_fail="true" && continue
        [ ${used_percentage} -ge 85 ] && show_result "Docker: $docker ,Mem total: $total ,used: $used ,Used percentage: $used_percentage > %85" $warn && res=$warn
    done
    [[ $is_fail == "true" ]] && return $fail || return $res
}
check_docker_diskspace()
{
    local dockers=$1
    local log_dir=$2
    local res=$success
    local is_fail=""

    for docker in ${dockers}
    do
        local df_file="${log_dir}/${docker}/df_h"
        local devices=$(grep -v "Filesystem" $df_file | awk '{print $1}')
        for device in $devices
        do
            local device_line=$(grep -wE "^$device" $df_file)
            local total=$(echo $device_line|awk '{print $2}')
            local used=$(echo $device_line|awk '{print $3}')
            local mount_point=$(echo $device_line|awk '{print $6}')
            local used_percentage=$(echo $device_line|awk '{print $5}'|awk -F% '{print $1}')
            [ $used_percentage -ge 90 ] && show_result "Docker: $docker ,device: $device ,fs: $mount_point ,used percentage: $used_percentage >= 90%" $fail && is_fail="true" && continue
            [ $used_percentage -ge 85 ] && show_result "Docker: $docker ,device: $device ,fs: $mount_point ,used percentage: $used_percentage >= 85%" $warn && res=$warn
        done
    done
    [[ $is_fail == "true" ]] && return $fail || return $res
}
check_dockers()
{
    local log=$1
    local log_dir=$(dirname $log)
    local res=$success
    local key=""
    local no_docker=$(cat ${log} | grep -c "None docker running")
    local dockers=$(cat ${log} | awk  '{print $1}' | grep -iv "Command:" | grep -iv "CONTAINER")

    if [ $no_docker -lt 1 ];then
        check_docker_mem "$dockers" "$log_dir"
        [ $? -ne $success ] && res=$?
        check_docker_diskspace "$dockers" "$log_dir"
        [ $? -ne $success ] && res=$?
    fi
    return $res
}
check_abnormal_packets()
{
    local log_file=$1
    local res=$success
    local key=""
    local rx_tx_info=$(egrep -w "RX|TX" $log_file | grep -w errors | awk -F "errors" '{print $2}' | sed "s/:/ /g")
    local flag_num=$(echo "$rx_tx_info" | wc -l)
    local errors_ok_num=$(echo "$rx_tx_info" | awk '{print $1}'| grep -wc 0)
    local dropped_ok_num=$(echo "$rx_tx_info" | awk '{print $3}' | grep -wc 0)
    local carrier_ok_num=$(echo "$rx_tx_info" | grep -w carrier | awk '{print $7}' | grep -wc 0)
    [ $dropped_ok_num -ne $flag_num ] && key=" RX packets or TX packets exist dropped problem!" && res=$warn
    [ $carrier_ok_num -ne $(($flag_num/2)) ] && key="TX packets exist carrier problem!" && res=$warn
    [ $errors_ok_num -ne $flag_num ] && key="RX packets or TX packets exist errors problem!" && res=$fail
    show_result "$key" "$res"
    return $res
}
check_bonding()
{
    local log=$1
    local log_dir=$(dirname $log)
    local res=$success
    local port_flag=2
    local lacp_flag=1
    local bonds=$(ls -ld ${log_dir}/*/ | awk '{print $9}' | awk -F / '{print $6}')

    for bond in $bonds
    do
        local bonding_dir="${log_dir}/${bond}"
        local bonding_log="$bonding_dir/cat_$bond"
        [ ! -e $bonding_log ] && continue
        local bonding_mode=$(grep "Bonding Mode" $bonding_log|grep -c "Dynamic link aggregation")
        local slave_flag=$(grep -c "MII Status" "$bonding_log")
        local up_flag=$(grep "MII Status" "$bonding_log"|grep -c "up")
        [ $bonding_mode -eq 1 ] && lacp_flag=$(grep -c "LACP" "$bonding_log")
        [ $bonding_mode -eq 1 ] && port_flag=$(grep "Number of ports" $bonding_log|awk '{print $4}')
        [ $port_flag -ne 2 ] && show_result "Number of ports is $port_flag" $warn && res=$warn
        [ $lacp_flag -ne 1 ] && show_result "$bond is not LACP protocal" $fail && res=$fail
        [ $slave_flag -ne $up_flag ] && show_result "$bond has slave nic down" $fail && res=$fail
    done
    return $res
}
check_alimonitor_syslog()
{
    local log_file=$1
    local res=$success
    local total_status=$(grep -c "OK" $log_file)
    while read line
    do
        local child_status=$(echo "$line" | grep -c OK)
        if [ $child_status -eq 1 ];then
            continue
        else
            show_result "$line" $warn
        fi
    done <<< "$(sed -n "/\"MSG/,/]/"p $log_file|grep -vE "\[|\]"|tr -d \{\}\")"
    [ $total_status -ne 5 ] && res=$warn
    return $res
}
check_alimonitor_hardward()
{
    local log_file=$1
    local res=$success
    local status=$(grep -c "OK" $log_file)
    [ $status -eq 0 ] && show "collection flag is not ok!" $warn && res=$warn
    return $res
}
check_raid_card()
{
    local typefile=$1
    local logdir=$(dirname $typefile)
    local raid_type=$(cat $typefile|grep -i "raid_controller" | awk -F: '{print $2}')
    local res=$success
    local key=""
    case $raid_type in
        hpraid)
            local cfg_logfile="$logdir/$raid_type/hpacucli_config.log"
            local lds=$(grep "logicaldrive" $cfg_logfile|awk '{print $1,$2}')
            local pds=$(grep "physicaldrive" $cfg_logfile|awk '{print $1,$2}')
            while read ld
            do
                local ld_status=$(grep "$ld" $cfg_logfile|grep -c OK)
                [ $ld_status -lt 1 ] && show_result "$ld is not ok!" $fail && res=$fail
            done <<< "$lds"
            while read pd
            do
                local pd_status=$(grep "$pd" $cfg_logfile|grep -c OK)
                [ $pd_status -lt 1 ] && show_result "$pd is not ok!" $fail && res=$fail
            done <<< "$pds"
            return $res
            ;;
        megaraidsas)
            local cfg_logfile="$logdir/$raid_type/cfgdsply.log"
            local pdld_logfile="$logdir/$raid_type/ldpdinfo.log"
            local fwterm_logfile="$logdir/$raid_type/fwtermlog.log"
            local lds=$(grep "Number of DISK GROUPS" $cfg_logfile|awk '{print $5}')
            local optimal_count=$(grep "^State" $cfg_logfile|grep -c "Optimal")
            local pds=$(grep -v "Physical Disk Information" $cfg_logfile|grep -c "Physical Disk")
            local media_error_count=$(grep "Media Error Count" $cfg_logfile|awk '{sum += $4};END {print sum}')
            local other_error_count=$(grep "Other Error Count" $cfg_logfile|awk '{sum += $4};END {print sum}')
            local predictive_failure_count=$(grep "Predictive Failure Count" $cfg_logfile|awk '{sum += $4};END {print sum}')
            local firmware_state=$(grep -c "Online, Spun Up" $cfg_logfile)
            local deadlock_state=$(tail -n 1000 $fwterm_logfile|grep -c "DeadLock")
            local disk_group=$(grep -v "Number of DISK GROUP" $cfg_logfile |grep "DISK GROUP")

            [ $media_error_count -gt 0 ] || [ $other_error_count -gt 0 ] || [ $predictive_failure_count -gt 0 ] && res=$warn
            while read ld
            do
                local dg_status=$(sed -n "/$ld/,/^State/p" $cfg_logfile|grep State|awk '{print $3}')
                [[ "$dg_status" == "Optimal" ]] && continue
                show_result "$ld status is $dg_status" $fail && res=$fail
            done <<< "$disk_group"

            if [ $firmware_state -lt $pds ];then
                local pd_state=$(grep "Firmware state" $cfg_logfile|cat -n|grep -v "Online, Spun Up")
                show_result "$pd_state" $fail && res=$fail
            fi

            [ $optimal_count -lt $lds ] && show_result "Logical Disk is not optimal" $fail && res=$fail
            [ $deadlock_state -ge 1 ] && show_result "DeadLock Detected!" $fail && res=$fail
            return $res
            ;;
        mpt2sas)
            local cfg_logfile="$logdir/$raid_type/sas2ircu_controllers_display.log"
            local ir_status=$(grep -v "IR Volume information" $cfg_logfile|grep -c "IR volume")
            local lds=$(grep -v "IR Volume information" $cfg_logfile|grep "IR volume")
            local pds=$(grep "Slot #" $cfg_logfile)
            if [ $ir_status -gt 0 ];then
                while read ld
                do
                    local ld_status=$(grep "$ld" -A 4 $cfg_logfile|tail -1|grep -Ec "Degraded|Failed|Missing")
                    [ $ld_status -gt 0 ] && show_result "$ld is Degraded|Failed|Missing" $fail && res=$fail
                done <<< "$lds"
            fi
            while read pd
            do
                local pd_status=$(grep "$pd" -A 2 $cfg_logfile|tail -1|grep -Ec "Available|Failed|Missing|Degraded")
                [ $pd_status -gt 0 ] && show_result "physical drive in $pd is Available|Failed|Missing|Degraded" $fail && res=$fail
            done <<< "$pds"
            return $res
            ;;
        unknown)
            show_result "raid type is unknown,please confirm that" $warn && res=$warn
            return $res
            ;;
        *)
            show_result "can not find any raid type" $warn && res=$warn
            return $res
    esac
    return $res
}

check_send_receive_err()
{
    local file=$1
    local key=""
    local res=$success
    local title=$(sed '1,2d' $file|head -1)
    local colume_num=0
    local rx_err_n=0
    local rx_drp_n=0
    local rx_ovr_n=0
    local tx_err_n=0
    local tx_drp_n=0
    local tx_ovr_n=0

    for title_item in $title
    do
        ((colume_num++));
        case $title_item in
            "RX-ERR") rx_err_n=$colume_num
            ;;
            "RX-DRP") rx_drp_n=$colume_num
            ;;
            "RX-OVR") rx_ovr_n=$colume_num
            ;;
            "TX-ERR") tx_err_n=$colume_num
            ;;
            "TX-DRP") tx_drp_n=$colume_num
            ;;
            "TX-OVR") tx_ovr_n=$colume_num
            ;;
        esac
    done

    local sum_one_line=$(sed '1,3d' $file|awk -v v1=$rx_err_n -v v2=$rx_drp_n \
                       -v v3=$rx_ovr_n  -v v4=$tx_err_n -v v5=$tx_drp_n \
                       -v v6=$tx_ovr_n '{print int($v1+$v2+$v3+$v4+$v5+$v6)}')
    for i in $sum_one_line
    do
        [ $i -gt 0 ] && key="Receive or send packets error" && res=$warn
    done
    show_result "$key" $res
    return $res
}

check_tcp_status()
{
    local logfile=$1
    local res=$success
    local key=""
    local close_wait_count=$(sed -n '/Active Internet/,/Active UNIX/p' $logfile|grep -Ev "^udp|Internet|UNIX|Proto|raw"|awk '{print $6}'|grep -c "CLOSE_WAIT")
    [ $close_wait_count -ge 100 ] && local key="More than $close_wait_count tcp connection in close_wait status." && res=$warn
    [ $close_wait_count -ge 200 ] && local key="More than $close_wait_count tcp connection in close_wait status." && res=$fail
    show_result "$key" "$res"
    return $res
}

check_default_route()
{
    local logfile=$1
    local res=$success
    local status=$(grep -c "default via" $logfile)
    [ $status -eq 0 ] && show_result "Not exist default route" $fail && res=$fail
    return $res
}

check_packets_abnormal()
{
    local logfile=$1
    local res=$success
    local socket_over=$(grep -c "listen queue of a socket overflowed" $logfile)
    local socket_drop=$(grep -c "SYNs to LISTEN sockets dropped" $logfile)
    [ $socket_over -gt 0 ] && show_result "Have packets lost because of tcp queue is overflowed" $warn && res=$warn
    [ $socket_drop -gt 0 ] && show_result "Have packets lost because of tcp syn queue is full" $warn && res=$warn
    return $res
}

check_ipmi_sensor()
{
    local logfile=$1
    local res=$success
    local key=""
    local sensor_status=$(grep -v "Command" $logfile|awk -F '|' '{print $4}'|grep -Evc "ok|0x0100|0x0000|0x8000|0x0080|0x0180|0x4080|0x0200|0x4000|na|nc|cr")

    check_ipmi_device "$logfile"
    [ $? -eq $fail ] && return $fail
    [ $sensor_status -gt 0 ] && local key="Sensor status is abnormal." && res=$warn
    show_result "$key" "$res"
    return $res
}

check_ipmi_sdr()
{
    local logfile=$1
    local res=$success
    local key=""
    local sdr_err=$(grep -v "Command" $logfile|awk -F '|' '{print $3}'| egrep -vc "ok|nc|ns|cr")

    check_ipmi_device "$logfile"
    [ $? -eq $fail ] && return $fail
    [ $sdr_err -ne 0 ] && local key="Sdr status is abnormal." && res=$warn
    show_result "$key" "$res"
    return $res
}
check_sn_number()
{
    local logfile=$1
    local res=$success
    local sn_number=$(grep "Product Serial" $logfile|awk -F: '{print $2}')

    check_ipmi_device "$logfile"
    [ $? -eq $fail ] && return $fail
    [[ "$sn_number" == "" ]] && show_result "The sn number is null" $fail && res=$fail
    return $res
}
check_oob_ip()
{
    local logfile=$1
    local res=$success
    local oob_ip=$(grep -v "IP Address Source" $logfile|grep "IP Address"|awk -F: '{print $2}'|sed 's/^[ ]//g')
	check_ipmi_device "$logfile"
	[ $? -eq $fail ] && return $fail
    [[ "$oob_ip" == "" ]] || [[ "$oob_ip" == "Unspecified" ]] && show_result "The oob ip is null or Unspecified" $fail && res=$fail
    return $res
}

get_ntp_status()
{
    if if_command_exist ntpq;then
        echo "############## ntpq info ###############"
        ntpq -np
        echo "############## end ntpq info ############"
    else
        return $skip
    fi
}
get_chrony_status()
{
    if_command_not_exist chronyc && return $skip
    echo "<< sources -v | chronyc >>"
    echo "sources -v" | chronyc
    echo "<< sourcestats -v | chronyc >>"
    echo "sourcestats -v" | chronyc
    echo "<< chronyc tracking >>"
    chronyc tracking
}
check_ntp()
{
    local log_file=$1
    local res=$success
    local ntpq=$(sed -n "/## ntpq info ##/,/## end ntpq info ##/"p $log_file | grep -v '#')
    local ntp_master=$(echo "$ntpq" | grep "\*" | awk '{print $1}' | awk -F'*' '{print $2}')
    local ntpq_offset=$(echo "$ntpq" | grep "\*" | awk '{print $9}' | awk -F'.' '{print $1}')
    local signal=$(echo "$ntpq_offset"|grep -c '-')
    local key=""
    if [ $signal -eq 0 ];then
        [ $ntpq_offset -ge 500 ] && key="offset is $ntpq_offset ms,big than 500ms!" && res=$warn
    else
        [ $ntpq_offset -le -500 ] && key="offset is $ntpq_offset ms,less than -500ms!" && res=$warn
    fi
    [[ "$ntp_master" =~ "127.127" ]] && [ $ops_servers -eq 0 ] && key="Ntp client sync to local clock." && res=$fail
    show_result "$key" "$res"
    return $res
}
check_chrony()
{
    # Waitting xiangyi to complete ...
    return $success
}
check_kernel_hotfix()
{
    # Waitting Xutao to complete ...
    return #success
}
check_dns()
{
    local logfile=$1
    local res=$success
    local key=""
    local query_noerror=$(grep "HEADER" $logfile|grep -c "NOERROR")

    [ $query_noerror -eq 0 ] && key="No dns server responsed this query" && res=$fail
    show_result "$key" "$res"
    return $res
}
summary_cpu_process()
{
    local type_pattern="Type Data"
    local info_pattern="Default_Info_Data"
    local logdir=$(sed -n "/## $type_pattern ##/,/## End $type_pattern ##/"p $DATA_FILE|grep "$info_pattern"|awk -F: '{print $2}')
    local ps_log=$(sed -n "/## $info_pattern ##/,/## End $info_pattern ##/"p $DATA_FILE|grep -E "^ps_thread"|awk -F: '{print $4}')
    local top_log=$(sed -n "/## $info_pattern ##/,/## End $info_pattern ##/"p $DATA_FILE|grep -E "^top_thread"|awk -F: '{print $4}')
    local ps_logfile="$LOGDIR/$logdir/$ps_log"
    local top_logfile="$LOGDIR/$logdir/$top_log"
    local d_logfile="$LOGDIR/summary_cpu_process_check"

    echo ""
    echo "Start summary process load info ..."
    
    > $d_logfile
    [ ! -e $ps_logfile ] || [ ! -e $top_logfile ] && return
    PID=$(awk '{print $1}' $ps_logfile|grep -Ev "PID|Command"|uniq -c|sort -rn|awk '{print $2}')
    cat $top_logfile|head -6|tail -5 >> $d_logfile
    echo "" >> $d_logfile
    printf "%-5s %-5s %-5s %-5s %-20s %-15s\n" PID COUNT %CPU %MEM WIDE-WCHAN-COLUMN COMMAND >> $d_logfile
    for pid in $PID
    do
        local WCHAN=$(grep -wE "^[ ]*$pid" $ps_logfile|awk '{print $11}'|sort|uniq)
        local command=$(grep -wE "^[ ]*$pid" $ps_logfile|awk '{$1="";$2="";$3="";$4="";$5="";$6="";$7="";$8="";$9="";$10="";$11="";print}'|tail -1)
        local mem_result=$(grep -wE "^[ ]*$pid" $ps_logfile|awk '{print $5}'|tail -1)
        for wchan in $WCHAN
        do
            local CPU=$(grep -wE "^[ ]*$pid" $ps_logfile|grep -w "$wchan"|awk '{print $4}')
            local cpu_result=$(echo "$CPU" | paste -sd+ - | bc)
            local wchan_count=$(echo "$CPU" | wc -l)
            printf "%-5s %-5s %-5s %-5s %-20s %-10s\n" "$pid" "$wchan_count" "$cpu_result" "$mem_result" "$wchan" "$command" >> $d_logfile
        done
    done
}
check_rpmdb()
{
    local log=$1
    local res=$success
    local bad_result="Database verification failed"
    local nofile_result="No such file or directory"
    local result=$(egrep -c "$bad_result|$nofile_result" $log)
    [ $result -ge 1 ] && key="rpm database verification failed" && res=$fail
    show_result "$key" "$res"
    return $res
}
generate_item_json_format()
{
    local check_log=$1
    local check_fun=$2
    local check_name=$3
    local json_file=$4
    local check_file="${check_log}_check"
    local json_status=$success

    [ ! -e "$check_file" ] && return

    local check_info=$(cat "$check_file")
    local warn_status=$(cat "$check_file"|grep -c 'WARNING')
    local fail_status=$(cat "$check_file"|grep -c 'FAIL')

    [ $warn_status -ge 1 ] && json_status=$warn
    [ $fail_status -ge 1 ] && json_status=$fail
    [ $json_status -eq $success ] && check_info=""

    [ $(grep -c 'CHECKINFO' $json_file) -eq 0 ] && echo " \"CHECKINFO\": [" >> $json_file
    echo "  {" >> $json_file
    echo "   \"status\": $json_status," >> $json_file
    echo "   \"name\": \"$check_name\"," >> $json_file
    echo "   \"info\": \"$check_info\"" >> $json_file
    echo "  }," >> $json_file
}
generate_item_json()
{
    local info_type="$1"
    local full_path="$2"
    local json_file="$3"
    sed -n "/## $info_type ##/,/## End $info_type ##/"p $DATA_FILE | grep -v '#' | while read line
    do
        local flag=$(echo $line | awk -F: '{print $1}')
        local action=$(echo $line | awk -F: '{print $3}')
        local filename=$(echo $line | awk -F: '{print $4}')
        local scope=$(echo $line | awk -F: '{print $5}')
        local check_fun=$(echo $line | awk -F: '{print $6}')
        local log="${full_path}/${filename}"

        generate_item_json_format "$log" "$check_fun" "$flag" "$json_file"
    done
}
generate_hostinfo_json()
{
    local json_file="$1"
    local hostfile="$2"
    local healthfile="$LOGDIR/health_degree"
    local is_hwconfig=$(grep -cE '^Arch' $hostfile)
    local os_health=0
    [ -e "$healthfile" ] && os_health=$(cat $healthfile|awk -F: '{print $2}')
    if [ $is_hwconfig -eq 0 ];then
        local hostname="$(grep 'Hostname' $hostfile|tr -s ' '|awk '{$1="";print}'|sed 's/^[ ]*//g')"
        local server_model="$(grep 'System' $hostfile|tr -s ' '|awk '{$1="";print}'|sed 's/^[ ]*//g')"
        local processor_model="$(grep 'Processors' $hostfile|tr -s ' '|awk '{$1="";print}'|sed 's/^[ ]*//g')"
        local memory_model="$(grep 'Memory' $hostfile|tr -s ' '|awk '{$1="";print}'|sed 's/^[ ]*//g')"
        local os_release="$(grep '^OS' $hostfile|awk -F, '{print $1}'|tr -s ' '|awk '{$1="";print}'|sed 's/^[ ]*//g')"
        local os_kernel="$(grep '^OS' $hostfile|awk -F, '{print $2}')"
        local bios_type="$(grep 'BIOS' $hostfile|tr -s ' '|awk '{$1="";print}'|sed 's/^[ ]*//g')"
        local dsk_controller=""

        echo " \"HOSTINFO\": {" >> $json_file
        echo "  \"hostname\": \"$hostname\"," >> $json_file
        echo "  \"os_health\": $os_health," >> $json_file
        echo "  \"server_model\": \"$server_model\"," >> $json_file
        echo "  \"processor_model\": \"$processor_model\"," >> $json_file
        echo "  \"memory_model\": \"$memory_model\"," >> $json_file

        local dks=$(grep 'Disk-Control' $hostfile|awk '{$1="";print}')
        while read line
        do
            dsk_controller+="$line + "
        done <<< "$dks"

        echo "  \"dsk_crtl_modle\": \"$dsk_controller\"," >> $json_file
        echo "  \"os_release\": \"$os_release\"," >> $json_file
        echo "  \"os_kernel\": \"$os_kernel\"," >> $json_file
        echo "  \"bios_type\": \"$bios_type\"" >> $json_file
        echo " }," >> $json_file
    else
        local hostname="$(grep 'Hostname' $hostfile|tr -s ' '|awk '{$1="";print}'|sed 's/^[ ]*//g')"
        local server_model="$(grep 'Product' $hostfile|tr -s ' '|awk '{$1="";print}'|sed 's/^[ ]*//g')"
        local os_release="$(grep 'System' $hostfile|tr -s ' '|awk '{$1="";print}'|sed 's/^[ ]*//g')"
        local os_kernel="$(grep 'Kernel' $hostfile|tr -s ' '|awk '{$1="";print}'|sed 's/^[ ]*//g')"

        echo " \"HOSTINFO\": {" >> $json_file
        echo "  \"hostname\": \"$hostname\"," >> $json_file
        echo "  \"os_health\": $os_health," >> $json_file
        echo "  \"server_model\": \"$server_model\"," >> $json_file
        echo "  \"processor_model\": \"\"," >> $json_file
        echo "  \"memory_model\": \"\"," >> $json_file
        echo "  \"dsk_crtl_modle\": \"\"," >> $json_file
        echo "  \"os_release\": \"$os_release\"," >> $json_file
        echo "  \"os_kernel\": \"$os_kernel\"," >> $json_file
        echo "  \"bios_type\": \"\"" >> $json_file
        echo " }," >> $json_file
    fi
}
generate_json_report()
{
    local type_pattern="Type Data"
    local json_file="$LOGDIR/$(basename ${LOGDIR}).json"
    local host_file="$LOGDIR/system_info/system_info"    

    > $json_file
    [ -e "$host_file" ] && generate_hostinfo_json "$json_file" "$host_file"

    sed -n "/## $type_pattern ##/,/## End $type_pattern ##/"p $DATA_FILE | grep -v '#' | while read typeline
    do
        local info_type=$(echo $typeline | awk -F: '{print $1}')
        local info_dir=$(echo $typeline | awk -F: '{print $2}')
        local default=$(echo $typeline | awk -F: '{print $3}')
        local info_output=$(echo $typeline | awk -F: '{print $4}')
        local full_path="${LOGDIR}/$info_dir"

        generate_item_json "$info_type" "$full_path" "$json_file"
    done

    if [ -s $json_file ];then
        sed -i '1i\{' $json_file
        sed -i '$d' $json_file && echo "  }" >> $json_file
        [ $(grep -c 'CHECKINFO' $json_file) -ne 0 ] && echo " ]" >> $json_file
        echo "}" >> $json_file
    fi
}
list_flags()
{
    local type_pattern="Type Data"

    info ""
    sed -n "/## $type_pattern ##/,/## End $type_pattern ##/"p $DATA_FILE | grep -v '#' | while read typeline
    do
        local info_type=$(echo $typeline | awk -F: '{print $1}')
        echo "Type: $info_type"
        sed -n "/## $info_type ##/,/## End $info_type ##/"p $DATA_FILE | grep -v '#' | while read line
        do
            local flag=$(echo $line | awk -F: '{print $1}')
            echo -e "\t$flag"
        done
    done
    exit 0
}

collection_items()
{
    local info_type="$1"
    local info_output="$2"
    local full_path="$3"

    info "Start collecting $info_output"
    mkdir -p "$full_path"
    sed -n "/## $info_type ##/,/## End $info_type ##/"p $DATA_FILE | grep -v '#' | while read line
    do
        local flag=$(echo $line | awk -F: '{print $1}')
        local cmd=$(echo $line | awk -F: '{print $2}')
        local action=$(echo $line | awk -F: '{print $3}')
        local filename=$(echo $line | awk -F: '{print $4}')
        local scope=$(echo $line | awk -F: '{print $5}')
        local log="${full_path}/${filename}"

        if [ "$target_cmd" != "" ];then
            [ "$target_cmd" = "$flag" ] && cmd_log "$cmd" "$log" "$action"
            continue
        fi
        [ $target_scope -ge $scope ] && cmd_log "$cmd" "$log" "$action"
    done
}
collection_all()
{
    local type_pattern="Type Data"

    sed -n "/## $type_pattern ##/,/## End $type_pattern ##/"p $DATA_FILE | grep -v '#' | while read typeline
    do
        local info_type=$(echo $typeline | awk -F: '{print $1}')
        local info_dir=$(echo $typeline | awk -F: '{print $2}')
        local default=$(echo $typeline | awk -F: '{print $3}')
        local info_output=$(echo $typeline | awk -F: '{print $4}')
        local full_path="${LOGDIR}/$info_dir"

        if [ "$default" != "must" ];then  
            [ "$target_type" != "" ] && [ "$target_type" != "$info_type" ] && continue
            [ "$target_type" = "" ] && [ "$default" != "default" ] && continue
        fi
        collection_items "$info_type" "$info_output" "$full_path"
    done | tee -a "${LOGDIR}/collecting_output"
}
start_collection()
{
    if [ $list_items -eq 1 ];then
        list_flags
    else
        collection_all
    fi
}
generate_data_file()
{
    local type_pattern="Main Info Data"
    sed -n "/## ${type_pattern} ##/,/## End ${type_pattern} ##/"p $0 > $DATA_FILE
}

checking_items()
{
    local info_type="$1"
    local info_output="$2"
    local full_path="$3"
    local info_data=$(sed -n "/## $info_type ##/,/## End $info_type ##/"p $DATA_FILE | grep -v '#')

    info "Start checking $info_output"

    while read line
    do
        local flag=$(echo $line | awk -F: '{print $1}')
        local cmd=$(echo $line | awk -F: '{print $2}')
        local action=$(echo $line | awk -F: '{print $3}')
        local filename=$(echo $line | awk -F: '{print $4}')
        local scope=$(echo $line | awk -F: '{print $5}')
        local check_fun=$(echo $line | awk -F: '{print $6}')
        local fix_fun=$(echo $line | awk -F: '{print $7}')
        local health_num=$(echo $line | awk -F: '{print $8}')
        local log="${full_path}/${filename}"

        if [ "$target_cmd" != "" ];then
            [ "$target_cmd" = "$flag" ] && analysis_log "$cmd" "$check_fun" "$fix_fun" "$log" "$action"
            continue
        fi

        if [ $target_scope -ge $scope ];then
            analysis_log "$cmd" "$check_fun" "$fix_fun" "$log" "$action"
            case $? in
                1) health_degree=$((health_degree - health_num));;
                2) health_degree=$((health_degree - health_num / 2));;
            esac
        fi
    done <<< "$info_data"
}
summary_process_html()
{
    local system_monitor_info=""
    local summary_top_info=$(cat "$LOGDIR/summary_cpu_process_check" | grep -Ev "PID|^[0-9]+")
    local summary_process_info=""

    local summary_process_field_info=$(cat "$LOGDIR/summary_cpu_process_check" | grep "PID")
    local summary_process_line_info=$(cat "$LOGDIR/summary_cpu_process_check" | grep '^[0-9]\+')

    local PID=$(echo "$summary_process_field_info" | awk '{print $1}')
    local COUNT=$(echo "$summary_process_field_info" | awk '{print $2}')
    local CPU=$(echo "$summary_process_field_info" | awk '{print $3}')
    local MEM=$(echo "$summary_process_field_info" | awk '{print $4}')
    local WIDE_WCHAN_COLLUMN=$(echo "$summary_process_field_info" | awk '{print $5}')
    local COMMAND=$(echo "$summary_process_field_info" | awk '{print $6}')
    local summary_process_field_html="
         <table class=\"table table-bordered\" style=\"word-break:break-all; word-wrap:break-all;\">
            <thead>
                <tr class=\"tr_top\" height=\"30px\">
                    <th class=\"as\" id=\"th0\" onclick=\"ProcessCountSort(this)\" width=\"10%\" style=\"text-align: center;vertical-align: middle;\">${PID}</th>
                    <th class=\"as\" id=\"th1\" onclick=\"ProcessCountSort(this)\" width=\"10%\" style=\"text-align: center;vertical-align: middle;\">${COUNT}</th>
                    <th class=\"as\" id=\"th2\" onclick=\"ProcessCountSort(this)\" width=\"15%\" style=\"text-align: center;vertical-align: middle;\">${CPU}</th>
                    <th class=\"as\" id=\"th3\" onclick=\"ProcessCountSort(this)\" width=\"15%\" style=\"text-align: center;vertical-align: middle;\">${MEM}</th>
                    <th width=\"15%\" style=\"text-align: center;vertical-align: middle;\">${WIDE_WCHAN_COLLUMN}</th>
                    <th width=\"65%\" style=\"text-align: center;vertical-align: middle;\">${COMMAND}</th>
                </tr>
            </thead>
            <tbody id=\"summary_process_line_color\">"
    while read process_line
    do
        local pid=$(echo "$process_line" | awk '{print $1}')
        local num=$(echo "$process_line" | awk '{print $2}')
        local cpu=$(echo "$process_line" | awk '{print $3}')
        local mem=$(echo "$process_line" | awk '{print $4}')
        local wide_wchan_column=$(echo "$process_line" | awk '{print $5}')
        local commands=$(echo "$process_line" | awk '{data="";for(i=6;i<=NF;i++){data=data""$i} print data}')
        local summary_process_line_html+="
                <tr class=\"text-center\" height=\"25px\">
                    <td name="td0" height=\"25px\">${pid}</td>
                    <td name="td1" height=\"25px\">${num}</td>
                    <td name="td2" height=\"25px\">${cpu}</td>
                    <td name="td3" height=\"25px\">${mem}</td>
                    <td name="td4" height=\"25px\">${wide_wchan_column}</td>
                    <td name="td5" height=\"25px\">${commands}</td>
                </tr>"
    done <<< "${summary_process_line_info}"
    local summary_process_line_html_end="
            </tbody>
        </table>"
    summary_process_info="${summary_process_field_html}${summary_process_line_html}${summary_process_line_html_end}"
    system_monitor_info="${summary_top_info}${summary_process_info}"
	echo "$system_monitor_info"
}
html_body()
{
    local flag=$1
    local check_status=$2
    local check_result_reson=$3
    local collect_log_data=$4
    local n=$5
    local html_content="
            <tr class=\"text-center\">
                <td></td>
                <td>${flag}</td>
                ${check_status}
                <td>${check_result_reson}</td>
                <td>
                    <button class=\"btn btn-success \" data-toggle=\"modal\" data-target=\"#myModal${n}\">
                        Detail
                    </button>
                </td>
            <div class=\"modal fade\" id=\"myModal${n}\" tabindex=\"-1\" role=\"dialog\" aria-labelledby=\"myModalLabel\" aria-hidden=\"true\">
                <div class=\"modal-dialog\">
                <div class=\"modal-content\">
                <div class=\"modal-header\">
                <h4 class=\"modal-title\" id=\"myModalLabel\">
                    ${flag}
                </h4>
                </div>
                <div class=\"modal-body\">
                ${collect_log_data}
                </div>
            <div class=\"modal-footer\">
            <button type=\"button\" class=\"btn btn-default\" data-dismiss=\"modal\">关闭
            </button>
                </div>
                </div>
                </div>
                </div>
            </tr>"
    echo "$html_content"
}
get_system_info_from_log()
{
    local type_pattern="Type Data"
    local info_pattern="Default_Info_Data"
    local logdir=$(sed -n "/## $type_pattern ##/,/## End $type_pattern ##/"p $DATA_FILE|grep "$info_pattern"|awk -F: '{print $2}')
    local sysinfo_log=$(sed -n "/## $info_pattern ##/,/## End $info_pattern ##/"p $DATA_FILE|grep -E "^sysinfo"|awk -F: '{print $4}')
    local sysinfo_file="${LOGDIR}/${logdir}/$sysinfo_log"
    [ -e $sysinfo_file ] && cat $sysinfo_file | sed '1,1d'
}
generate_html_body()
{
    local html=$1
    local type_pattern="Type Data"
    local type_data=$(sed -n "/## $type_pattern ##/,/## End $type_pattern ##/"p $DATA_FILE | grep -v '#')
    local n=1
    local system_info=$(echo "$(get_system_info_from_log)" | grep -v "^$")
    local html_info_system="<pre id=\"system_data\" style=\"display: none\"><code>${system_info}</code></pre>"
    local system_monitor_info=$(summary_process_html)
    local html_info_system_monitor="<pre id=\"system_monitor_data\" style=\"display: none\"><code>${system_monitor_info}</code></pre>"
    local html_type_report="Check Report Html Article"
    local html_info_check_report_th=$(sed -n "/## ${html_type_report} ##/,/## End ${html_type_report} ##/"p $DATA_FILE | grep -v '^#\+')
    echo "$html_info_system" >> "$html"
    echo "$html_info_system_monitor" >> "$html"
    echo "$html_info_check_report_th" >> "$html"

    while read typeline
    do
        local info_type=$(echo $typeline | awk -F : '{print $1}')
        local info_dir=$(echo $typeline | awk -F : '{print $2}')
        local full_path="${LOGDIR}/$info_dir"
        local item_data=$(sed -n "/## $info_type ##/,/## End $info_type ##/"p $DATA_FILE | grep -v '#')

        while read line
        do
            local flag=$(echo $line | awk -F: '{print $1}')
            local filename=$(echo $line | awk -F: '{print $4}')
            local collect_log="${full_path}/${filename}"
            local check_log="${full_path}/${filename}_check"
            local check_status=""
            local check_result_reson=""
            local check_report_status=0
            local collect_log_data=""

            [ ! -e "$check_log" ] && continue

            check_report_status=$(cat $check_log 2>/dev/null | grep -c 'Check Report Info')
            while read line
            do
                local res_status=$(echo $line | awk -F ':' '{print $2}' | awk -F ')' '{print $1}' | sed 's/(//g' | sed 's/ //g')
                case "$res_status" in
                    "WARNING")
                        [ "$check_status" = "" ] && check_status="<td style=\"color:orange\">$res_status</td>"
                        ;;
                    "FAIL")
                        check_status="<td style=\"color:red\">$res_status</td>";;
                    *) ;;
                esac
                check_result_reson+="$(echo $line | awk -F ')' '{data=""; for(i=2;i<=NF;i++) {data=data""$i}; print data }')<br>"
            done <<< "$(cat $check_log 2>/dev/null | grep "Check Report Info")"
            [ $check_report_status -eq 0 ] && check_status="<td style=\"color:lime\">SUCCESS</td>" && check_result_reson=''

            collect_log_data=$(tail -1000 $collect_log 2>/dev/null | awk '{print $0 "<br>"}')
            html_body "$flag" "$check_status" "$check_result_reson" "$collect_log_data" $n  >> "$html"
            ((n++))
        done <<< "${item_data}"
    done <<< "${type_data}"
}
health_degree_html()
{
    local html=$1
    local bg_color=""
    local health_degree_num=$(cat "$LOGDIR/health_degree" | awk -F ':' '{print $2}')
    [ ${health_degree_num} -ge 80 ] && gb_color="bg-success"  
    [ ${health_degree_num} -le 80 ] && [ ${health_degree_num} -gt 60 ] && gb_color="bg-warning"  
    [ ${health_degree_num} -le 60 ] && gb_color="bg-danger"  
    local health_degree_html="
        <div class=\"container\" style=\"width: 778px;\">
            <div class=\"progress\" style=\"margin-bottom: 12px;\">
            <div class=\"progress-bar progress-bar-striped progress-bar-animated ${gb_color}\" style=\"width:${health_degree_num}%\">健康值：${health_degree_num}</div>
            </div>
        </div>"
    echo "${health_degree_html}" >> "${html}"
}
generate_html_report()
{
    local html_type_head_one="Check Report Html Head One"
    local html_type_head_two="Check Report Html Head Two"
    local html_type_tail="Check Report Html Tail"
    local html_info_head_one=$(sed -n "/## ${html_type_head_one} ##/,/## End ${html_type_head_one} ##/"p $DATA_FILE | grep -v '^#\+')
    local html_info_head_two=$(sed -n "/## ${html_type_head_two} ##/,/## End ${html_type_head_two} ##/"p $DATA_FILE | grep -v '^#\+')
    local html_info_tail=$(sed -n "/## ${html_type_tail} ##/,/## End ${html_type_tail} ##/"p $DATA_FILE | grep -v '^#\+')
    local html_file="${LOGDIR}/$(basename ${LOGDIR}).html"

    echo "$html_info_head_one" > "$html_file"
    health_degree_html "$html_file"
    echo "$html_info_head_two" >> "$html_file"
    generate_html_body "$html_file"
    echo "$html_info_tail" >> "$html_file"
}
generate_report()
{
    info "Start generate report ..."
    generate_html_report
    generate_json_report
}
summary_system_health_degree()
{
    [ $health_degree -lt 0 ] && health_degree=0
    echo "health degree:$health_degree" > "${LOGDIR}/health_degree"
}
start_checking()
{
    local type_pattern="Type Data"
    local type_data=$(sed -n "/## $type_pattern ##/,/## End $type_pattern ##/"p $DATA_FILE | grep -v '#')
    while read typeline
    do
        local info_type=$(echo $typeline | awk -F: '{print $1}')
        local info_dir=$(echo $typeline | awk -F: '{print $2}')
        local info_output=$(echo $typeline | awk -F: '{print $4}')
        local full_path="${LOGDIR}/$info_dir"

        checking_items "$info_type" "$info_output" "$full_path"
    done <<< "$type_data"
    summary_system_health_degree
}
check_and_generate_report()
{
    [ $checking -eq 0 ] && return
    start_checking | tee -a "${LOGDIR}/checking_output"
    summary_cpu_process
    generate_report
}
collection_log()
{
    [ "$syslog_tgz" = "" ] && start_collection
}
################################ End Utility Function ################################

############################### Main ################################
usage()
{
    cat << EOF
    Usage:
        $(basename $0) -V                     debug mode.
        $(basename $0) -d <target dir>        All log will be generated to target dir.
        $(basename $0) -i <target item>       Call target item to get info.
        $(basename $0) -t <target type>       Call target type to get info.
        $(basename $0) -s <target scope>      Call target scope: small, normal(default), all to get info.
        $(basename $0) -n                     Will not compress log files to generate tarball.
        $(basename $0) -c                     Check log content and generate report.
        $(basename $0) -f <log file>          Assign log tarball file, need with parameter -c.
        $(basename $0) -l                     Just list type and items out.
    Example:
        $(basename $0) -d /apsara -s all
        $(basename $0) -s small
        $(basename $0) -t "Slb Info Data"
        $(basename $0) -i disks_io_detail
        $(basename $0) -c -f ./cloud_log.2017-09-01-15-23-57.tar.gz
EOF
    exit 1
}
while getopts d:t:f:i:s:achzrnlV OPTION
do
    case $OPTION in
        h) usage;;
        V) set -x;;
        i) target_cmd="$OPTARG";;
        t) target_type="$OPTARG";;
        s) SCOPE_TYPE="$OPTARG";;
        d) SLOGDIR="$OPTARG";;
        c) checking=1;;
        f) syslog_tgz="$OPTARG";;
        n) no_compress=1;;
        l) list_items=1;;
        r) report_only=1;;
        z) disable_single=1;;     #internal parameter
        *) usage;;
    esac
done

show_system_info
check_single_instance
trap cleanup EXIT
prepare_to_run
generate_data_file
free_space_check
collection_log
check_and_generate_report
compress_log
exit 0
############################# End Main ##############################

########################## Main Info Data ############################
########################## Collection Data ############################
############################# Type Data ############################
#Info Type:logdir:scope:description
Default_Info_Data:system_info:must:common information ...
System_Info_Data:system_info:default:system information ...
Network_Info_Data:network_info:default:network information ...
BMC_Info_Data:bmc_info:default:bmc information ...
Virtualization_Info_Data:virtualization_info:default:virtualization information ...
Disk_Info_Data:disk_info:default:disk information ...
Slb_Info_Data:slb_info::slb information ...
########################### End Type Data ##########################

#flag:collect_function:action:filename:scope:analysis_function:fix_function:health_degree

#1 flag make sure it is unique
#2 collect_function is collect action
#3 action include:
#   check <-- check if command exist, default to check
#   path  <-- send target path to command

#4 filename is log file name.
#5 scope include 1(small), 2(normal) and 3(all)
#6 analysis_function is check function
#7 fix_function is the action function
#8 health_degree is system health value
######################### Default_Info_Data ###########################
uname:uname -a::uname_a:1:::
system_release:cat /etc/redhat-release::redhat-release:1:::
sysinfo:show_system_info::system_info:1:::
df:df -h::df_h:1:check_disk_size::10
inode:df -i::df_i:1:check_disk_inode::10
free:free -m::free_m:1:check_free_memory::20
ps_thread:ps -Le -wwo 'pid,spid,psr,pcpu,pmem,rsz,stime,user,stat,uid,wchan=WIDE-WCHAN-COLUMN,args' --sort rsz::ps_thread:1:check_process_status::4
ps_process:ps -e -wwo 'pid,spid,psr,pcpu,pmem,rsz,stime,user,stat,uid,wchan=WIDE-WCHAN-COLUMN,args' --forest::ps_process_forest:1::
top_thread:top -H -b -n 1::top_H_b:1::
ntp:get_ntp_status::ntpq_np:1:check_ntp::4
chrony:get_chrony_status::chronyc:1:check_chrony::4
dmesg:dmesg::dmesg:1:check_dmesg::30
######################### End Default_Info_Data ########################
########################## System_Info_Data ###########################
history:cat $HOME/.bash_history::history:1:check_user_behavior::5
#last:last reboot::last_reboot:1:::
#last_x:last -x::last_x:1:::
login_info:utmpdump /var/log/wtmp::utmpdump:1:::
at:at -l::at_l:1:::
ps_RDZ:ps -eL h o pid,state,ucmd | awk '{if($2=="R"||$2=="D"||$2=="Z"){print $0,$1}}' | sort | uniq -c | sort -k 1nr::ps_RDZ:2:::
ps_alt:ps --forest -eo 'pid,ppid,nlwp,stat,%cpu,%mem,cputime,start,rss,sz,vsz,policy,maj_flt,min_flt,wchan,args'::ps_alt:1:::
ps_thread_alt:ps --sort=-pcpu -eLo 'pid,ppid,nlwp,stat,%cpu,%mem,cputime,start,rss,sz,vsz,policy,maj_flt,min_flt,wchan,args'::ps_thread_alt:1:::
dmesg_H:get_dmesg_H::dmesg_H:1:::
ls_crash:ls -R /var/crash::ls_crash:1:::
date:date::date:1:::
hwclock:hwclock::hwclock:1:::
chkconfig:chkconfig --list::chkconfig__list:1::
sysctl:sysctl -a::sysctl_a:1::
lspci:lspci -vvv::lspci_vvv:1::
runlevel:runlevel::runlevel:1::
uptime:uptime::uptime:1:check_system_load::10
fstab:get_fstab_info::fstab_info:1:check_fstab::10
cat_mount:cat /proc/mounts::cat_mount:1:check_readonly::40
top:top -b -n 1::top_b:1::
pstree:pstree -pl::pstree_pl:1::
iotop:iotop -k -b -n 6::iotop_k:1::
kdump:get_kdump_status::kdump_status:1:check_kdump_status::2
kdump_conf:get_kdump_conf::kdump_conf:1:check_kdump_config::2
lsmod:lsmod::lsmod:1::
cmdline:cat /proc/cmdline::cat_proc_cmdline:1:check_cmdline_config::2
meminfo:cat /proc/meminfo::cat_proc_meminfo:1::
slabinfo:cat /proc/slabinfo::cat_proc_slabinfo:1::
vmallocinfo:cat /proc/vmallocinfo::cat_vmallocinfo:1::
irqinfo:cat /proc/interrupts::cat_interrupts:1::
swaps:cat /proc/swaps::cat_proc_swaps:1::
cpuinfo:cat /proc/cpuinfo::cat_proc_cpuinfo:1:::
cat_devices:cat /proc/devices::cat_proc_devices:1:::
cat_iomem:cat /proc/iomem::cat_proc_iomem:1:::
cat_ioports:cat /proc/ioports::cat_proc_ioports:1:::
cat_kallsyms:cat /proc/kallsyms::cat_proc_kallsyms:1:::
cat_locks:cat /proc/locks::cat_proc_locks:1:::
cat_softirqs:cat /proc/softirqs::cat_proc_softirqs:1:::
cat_sched_debug:cat /proc/sched_debug::cat_proc_sched_debug:1:::
cat_schedstat:get_schedstat::cat_proc_schedstat:1:::
cat_stat:cat /proc/stat::cat_proc_stat:1:::
cat_zoneinfo:cat /proc/zoneinfo::cat_proc_zoneinfo:1:::
cat_softnet:cat /proc/net/softnet_stat::cat_proc_softnet:1:::
cat_def_affinity:cat /proc/irq/default_smp_affinity::cat_proc_def_affinity:1:::
cat_sysvm:get_sysvm::cat_sysvm:1:::
cat_kernel_domainname:cat /proc/sys/kernel/domainname::cat_kernel_domainname:1:::
cat_kernel_hostname:cat /proc/sys/kernel/hostname::cat_kernel_hostname:1:::
cat_kernel_hung_task:get_hung_task::cat_kernel_hung_task:1:::
cat_kernel_numa:get_numa::cat_kernel_numa:1:::
cat_kernel_overflow:get_overflow::cat_kernel_overflow:1:::
cat_kernel_panic:get_panic::cat_kernel_panic:1:::
cat_kernel_perf:get_perf::cat_kernel_perf:1:::
cat_kernel_max:get_max::cat_kernel_max:1:::
cat_kernel_print:get_print::cat_kernel_print:1:::
cat_kernel_sched:get_sched::cat_kernel_sched:1:::
cat_kernel_softlockup:get_softlockup::cat_kernel_softlockup:1:::
cat_kernel_watchdog:get_watchdog::cat_kernel_watchdog:1:::
cat_kernel_vminfo:cat /sys/kernel/vmcoreinfo::cat_kernel_vminfo:1:::
cat_fs_cgroup_cpu:get_cgroup_cpu::cat_fs_cgroup_cpu:1:::
cat_fs_cgroup_blkio:get_cgroup_blkio::cat_fs_cgroup_blkio:1:::
cat_fs_cgroup_perf:get_cgroup_perf_event::cat_fs_cgroup_perf:1:::
cat_kernel_tracing:get_ftrace_avail::cat_kernel_tracing:1:::
cat_kernel_sched_features:get_sched_features::cat_kernel_sched_features:1:::
numastat:get_numastat::numastat:1:::
pidstat:pidstat -udrltw 1 6::pidstat:1:::
slabtop:get_slabtop::slabtop:1:::
dns:get_dns_info::dns_info:1:check_dns::5
dmidecode:dmidecode::dmidecode:1::
ulimit:ulimit -a::ulimit_a:1::
crontab:crontab -l::crontab_l:1::
mpstat:mpstat -P ALL 1 6::mpstat_P:2::
iostat:iostat -xm 1 6::iostat_xm:1:check_io_utilize::10
vmstat:vmstat 1 6::vmstat:2::
blkid:blkid::blkid:1::
lsblk:get_lsblk::lsblk:1:::
blockdev:blockdev --report::blockdev:1:::
lsscsi:lsscsi::lsscsi:1::
mdadm:mdadm --detail::mdadm__detail:1::
lvs_detail:lvs -vv::lvs_vv:1::
lvs:lvs -v::lvs_v:1::
vgs:vgs::vgs:1::
pvs:pvs::pvs:1::
lsof:lsof::lsof:3:check_openfiles::5
journalctl:journalctl -xn:check:journalctl_xn:2::
cp_system_files:copy_system_files:path:copy_system_files:1:check_system_log::10
cp_other_files:copy_other_files:path:copy_other_files:2::
cp_all_files:copy_all_files:path:copy_all_files:3::
top10_mem:get_top10_mem_process_info:path:top_mem_order:2::
top10_cpu:get_top10_cpu_process_info:path:top_cpu_order:2::
rpmdb_verify:verify_rpmdb::rpmdb_verify:1:check_rpmdb::20
rpm_all:rpm -qa::rpm_qa:1:check_kernel_hotfix::2
######################### End System_Info_Data ########################
######################## Network_Info_Data ###########################
ss:ss -anpei::ss_anpei:3::
class_net:ls -l /sys/class/net/::ls_class_net:1::
ifstat:ifstat -a 1 6::ifstat_a:2::
ipaddr:ip addr show::ip_addr_show:1::
iproute:ip route show::ip_route_show:1:check_default_route::2
ifconfig:ifconfig::ifconfig:1:check_abnormal_packets::2
ifconfig_all:ifconfig -a::ifconfig_a:1::
route_cache:route -Cn::route_Cn:1::
route:route -n::route_n:1::
bridge:brctl show::brctl_show:1::
netstat:netstat -anpo::netstat_anpo:1:check_tcp_status::4
netstat_pro:netstat -s::netstat_s:1:check_packets_abnormal::2
netstat_dev:netstat -i::netstat_i:1:check_send_receive_err::2
bonding_info:get_bonding_info:path:bonding_info:1:check_bonding::8
netcard_info:get_netcard_info:path:netcard_info:1:check_netcard::8
###################### End Network_Info_Data #########################
########################## BMC_Info_Data #######################
#ipmifru:ipmitool fru list::ipmitool_fru_list:1:check_sn_number::1
#ipmilan:ipmitool lan print 1::ipmitool_lan_print_1:1:check_oob_ip::1
#ipmimc:ipmitool mc info::ipmitool_mc_info:1::
#ipmisensor:ipmitool sensor list::ipmitool_sensor_list:1:check_ipmi_sensor::1
#ipmisdr:ipmitool sdr list::ipmitool_sdr_list:1:check_ipmi_sdr::1
#ipmisel:ipmitool sel elist::ipmitool_sel_elist:1:check_ipmi_event::1
######################## End BMC_Info_Data #####################
##################### Virtualization_Info_Data ######################
docker_info:get_docker_info:path:docker_info:1:check_dockers::2
################## End Virtualization_Info_Data ####################
############################ Disk_Info_Data ####################
disks_io_detail:get_disks_io_detail:path:disks_io_detail:3::
disk_info:get_disk_info:path:disk_info:2::
ext4_info:get_ext4_info:path:ext4_info:2::
ext3_info:get_ext3_info:path:ext3_info:2::
aliflash:get_aliflash_info:path:aliflash_info:2::
nvme:get_nvme_info:path:nvme_info:2::
raid_info:get_raid_log:path:raid_type:1:check_raid_card::10
########################## End Disk_Info_Data #####################
############################ Slb_Info_Data #########################
lvs_status:get_lvs_status::list_admin_lb_node:1:check_lvs_status::
lvs_proxy_status:get_lvs_proxy_status::list_admin_proxy:1:check_lvs_proxy_status::
vip_intranet_info:get_slb_intranet_vip_info:path:intranet_vip_info:1:check_slb_intranet_vip::
vip_internet_info:get_slb_internet_vip_info:path:internet_vip_info:1:check_slb_internet_vip::
vip_plan:get_slb_vip_plan:path:slb_vip_plan:1::
network_service_unit:get_network_service_unit:path:network_service_unit:1::
service_unit_bid:get_service_unit_bid:path:service_unit_bid:1::
userid_and_count:get_slb_userid_and_count_info:path:userid_and_count_info:1::
slb_ag_date:get_slb_ag_date::slb_ag_date:1::
slb_ag_agent:get_slb_ag_agent:path:slb_ag_agent:1::
slb_ag_log:get_slb_ag_log::slb-test_run_log:1::
slb_ag_cron:get_slb_ag_cron_status::crond_status:1::
slb_ag_show_tables:get_slb_ag_show_tables::slb_db_show_tables:1::
lvs_servers_status:get_lvs_servers_status:path:lvs_server_status:1::
lvs_servers_proxy_status:get_lvs_servers_proxy_status:path:lvs_server_proxy_status:1::
slb_control_master_status:get_slb_control_master_status:path:slb_control_master_status:1::
slb_control_haproxy_status:get_slb_control_haproxy_status:path:slb_control_haproxy_status:1::
########################## End Slb_Info_Data #########################
######################## End Collection Data ##########################

############################ Checking Data ##############################
#1 function
#2 key word
#3 key word
# etc ..
######################## Kernel Bug Info Data #######################
kernel_bug@BUG: unable to handle kernel paging request@fib_list_tables
kernel_bug@oom-killer@memory: usage
kernel_bug@arch/x86/kernel/paravirt.c@paravirt_enter_lazy_mmu
#x86, xsave: remove thread_has_fpu() bug check in __sanitize_i387_state
kernel_bug_known@arch/x86/kernel/xsave.c:@__sanitize_i387_state
#thread_group_times()函数除0错
kernel_bug_known@divide error: 0000@thread_group_times
kernel_bug_known@unable to handle kernel NULL pointer@netpoll_poll_dev
#cpu cgroup exit panic : khotfix-ui8wch5s
kernel_bug_known@unable to handle kernel NULL pointer@update_shares
kernel_bug_known@general protection fault:@update_shares
#jbd tid wraparound
kernel_bug_known@kernel BUG at fs/jbd/commit.c@journal_commit_transaction
kernel_bug_known@kernel BUG at fs/jbd2/commit.c@jbd2_journal_commit_transaction
kernel_bug_known@unable to handle kernel NULL pointer@lookup_user_key
kernel_bug_known@BUG: soft lockup - CPU@_spin_lock
kernel_bug_known@unable to handle kernel NULL pointer@tcp_fastretrans_alert
#http://kirin.alibaba-inc.com/faq/detail.htm?id=36
kernel_bug_known@switching to interrupt mode@corrected_machine-check_error_interrupt
kernel_bug_known@switching to poll mode@corrected_machine-check_error_interrupt
###################### End Kernel Bug Info Data ####################
#1 message
#2 key word
###################### Ipmi Event Data #######################
Hardware Error:PCI error@Critical Interrupt PCI | Bus Fatal Error
Hardware Error:PCIe error@Critical Interrupt #0x8c | Bus Fatal Error
Hardware Error: maybe memory error@Processor #0xfa | Configuration Error
manual shutdown@System ACPI Power State #0xc1 | S4/S5: soft-off
Hardware Error:Unknown@Unknown #0xcb
Hardware Error:Processor IERR@Processor #0x0f | IERR
#################### End Ipmi Event Data #######################
######################### End Checking Data ##############################
######################## Check Report Html Head One ###########################
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>OS check report</title>
    <script src="/static/js/jquery.min.js"></script>
    <script src="/static/js/bootstrap.min.js"></script>
    <link rel="stylesheet" href="/static/css/bootstrap_1.min.css">
    <link rel="stylesheet" href="/static/css/bootstrap_2.min.css">
    <script src="https://cdn.bootcss.com/jquery/1.12.4/jquery.min.js"></script>
    <script src="http://cdn.static.runoob.com/libs/bootstrap/3.3.7/js/bootstrap.min.js"></script>
    <link rel="stylesheet" href="https://cdn.bootcss.com/bootstrap/4.0.0-beta/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://cdn.bootcss.com/bootstrap/3.3.7/css/bootstrap.min.css">
    <style type="text/css">

        header, nav, article, footer {
            border-style: outset;
            border-width: 1px;
            border-color:rgba(34, 74, 158, 0.3);
        }
        header {
            width: 100%;
        }
        nav {
            float: left;
            width: 15%;
            height: 800px;
        }
        article {
            float: left;
            width: 85%;
            height: 800px;
        }
        footer {
            clear: both;
            width: 100%;
        }
        tr.tr_top th{line-height:40px;border:none;background-color:rgba(34, 74, 158, 0.4);color:rgb(255,255,255);font-weight:bold;}
        .table tbody tr td{
            vertical-align: middle;
        }
        pre{
            background-color:#E6F0FE;
            color: rgba(19,107,230,0.6)
        }
        code{
            font-family:Microsoft yahei;
            font-size:16px;
        }
        h4{
            font-family:Microsoft yahei;
            color:rgba(19,107,230,0.8)
        }
        body{
            background-color:#E6F0FE;
        }
        .even_line{
        background-color:rgba(207,215,232,0.4);
            text-align:center;
        }
        .odd_line{
            text-align:center;
        }
        @-webkit-keyframes move{
            0%{left:-1800px;}
            100%{left:0px;}
        }

    </style>
</head>
<body>
    <header>
        <h2 align="center" style="font-family:Microsoft yahei;color:rgba(19, 107, 230,0.8);margin-top: 10px">日志检测报告</h2>
######################## End Check Report Html Head One ###########################
######################## Check Report Html Head Two ###########################
    </header>
    <nav style="overflow:auto;">
        <h4 id="introduce_show"><a href="#">&nbsp;1.功能介绍</a></h4>
        <h4 id="system_show"><a href="#">&nbsp;2.系统信息</a></h4>
        <h4 id="system_monitor_show"><a href="#">&nbsp;3.系统负载分析</a></h4>
        <h4 id="check_report_show"><a href="#">&nbsp;4.日志检测报告</a></h4>
    </nav>
    <article style="overflow:auto;border-right-width: 7px;">
        <pre id="introduce_data"><code style="font-family:Microsoft yahei;font-size:16px;">系统日志收集与分析工具，主要包括以下几个部分：
1. 收集系统信息、网络信息、磁盘信息、硬件信息等。
2. 分析并检查日志，判断是否符合标准。
3. 生成报告。
        </code></pre>
######################## End Check Report Html Head Two ###########################
######################## Check Report Html Article ###########################
        <div class="bs-example" id="check_report_data" style="display:none" data-example-id="bordered-table">
            <table class="table table-bordered" name="check_report_table"  style="word-break:break-all; word-wrap:break-all;">
                <thead>
                    <tr class="tr_top" height="60px">
                        <th width="10%" style="text-align: center;vertical-align: middle">序号</th>
                        <th width="20%" style="text-align: center;vertical-align: middle">Collection items</th>
                        <th width="25%" style="text-align: center;vertical-align: middle">Check status</th>
                        <th width="25%" style="text-align: center;vertical-align: middle">Investigation reason</th>
                        <th width="20%" style="text-align: center;vertical-align: middle">Log detail</th>
                    </tr>
                </thead>
                <tbody id="line_color_change">
######################## End Check Report Html Article ###########################
####################### Check Report Html Tail ###########################
                </tbody>
            </table>
        </div>
    </article>
    <footer>
    </footer>
</body>
</html>
<script type="text/javascript">

$("#introduce_show").click(function(){
    $("#introduce_data").show()
    $("#system_data").hide()
    $("#system_monitor_data").hide()
    $("#check_report_data").hide()
});

$("#system_show").click(function(){
    $("#introduce_data").hide()
    $("#system_data").show()
    $("#system_monitor_data").hide()
    $("#check_report_data").hide()
});

$("#system_monitor_show").click(function(){
    $("#introduce_data").hide()
    $("#system_data").hide()
    $("#system_monitor_data").show()
    $("#check_report_data").hide()
});

$("#check_report_show").click(function(){
    $("#introduce_data").hide()
    $("#system_data").hide()
    $("#system_monitor_data").hide()
    $("#check_report_data").show()
});

function makeSortable(table) {
    var headers=table.getElementsByTagName("th");
    for(var i=0;i<headers.length;i++){
        (function(n){
            var flag=false;
            headers[n].onclick=function(){
                var tbody=table.tBodies[0];
                var rows=tbody.getElementsByTagName("tr");
                rows=Array.prototype.slice.call(rows,0);
                rows.sort(function(row1,row2){
                    var cell1=row1.getElementsByTagName("td")[n];
                    var cell2=row2.getElementsByTagName("td")[n];
                    var val1=cell1.textContent||cell1.innerText;
                    var val2=cell2.textContent||cell2.innerText;

                    if(val1<val2){
                        return -1;
                    }else if(val1>val2){
                        return 1;
                    }else{
                        return 0;
                    }
                });
                if(flag){
                    rows.reverse();
                }
                for(var i=0;i<rows.length;i++){
                    tbody.appendChild(rows[i]);
                }
                flag=!flag;
                td_color_change();
                summary_cpu_process_check_info();
            }
        }(i));
    }
}
function td_color_change(){
    var oTable = document.getElementById("line_color_change");
    for(var i=0;i<oTable.rows.length;i++){
        oTable.rows[i].cells[0].innerHTML = (i+1);
        if(i%2==0){
        oTable.rows[i].className = "even_line";
        }
        else{
        oTable.rows[i].className = "odd_line";
        }
    }
}

function summary_cpu_process_check_info(){
    var oTable = document.getElementById("summary_process_line_color");
    for(var i=0;i<oTable.rows.length;i++){
        if(i%2==0){
        oTable.rows[i].className = "even_line";
        }
        else{
        oTable.rows[i].className = "odd_line";
        }
    }
}

function sortNumberAS(a, b)
{
    return a-b
}
function sortNumberDesc(a, b)
{
    return b-a
}

function ProcessCountSort(obj){
    var td0s=document.getElementsByName("td0");
    var td1s=document.getElementsByName("td1");
    var td2s=document.getElementsByName("td2");
    var td3s=document.getElementsByName("td3");
    var td4s=document.getElementsByName("td4");
    var td5s=document.getElementsByName("td5");
    var tdArray0=[];
    var tdArray1=[];
    var tdArray2=[];
    var tdArray3=[];
    var tdArray4=[];
    var tdArray5=[];
    for(var i=0;i<td0s.length;i++){
        tdArray0.push(td0s[i].innerHTML);
    }
    for(var i=0;i<td1s.length;i++){
        tdArray1.push(parseInt(td1s[i].innerHTML));
    }
    for(var i=0;i<td2s.length;i++){
        tdArray2.push(td2s[i].innerHTML);
    }
    for(var i=0;i<td3s.length;i++){
        tdArray3.push(td3s[i].innerHTML);
    }
    for(var i=0;i<td4s.length;i++){
        tdArray4.push(td4s[i].innerHTML);
    }
    for(var i=0;i<td5s.length;i++){
        tdArray5.push(td5s[i].innerHTML);
    }
    var tds=document.getElementsByName("td"+obj.id.substr(2,1));
    var columnArray=[];
    for(var i=0;i<tds.length;i++){
        columnArray.push(parseInt(tds[i].innerHTML));
    }
    var orginArray=[];
    for(var i=0;i<columnArray.length;i++){
        orginArray.push(columnArray[i]);
    }
    if(obj.className=="as"){
        columnArray.sort(sortNumberAS);
        obj.className="desc";
    }
    else{
        columnArray.sort(sortNumberDesc);
        obj.className="as";
    }
    for(var i=0;i<columnArray.length;i++){
        for(var j=0;j<orginArray.length;j++){
            if(orginArray[j]==columnArray[i]){
                document.getElementsByName("td0")[i].innerHTML=tdArray0[j];
                document.getElementsByName("td1")[i].innerHTML=tdArray1[j];
                document.getElementsByName("td2")[i].innerHTML=tdArray2[j];
                document.getElementsByName("td3")[i].innerHTML=tdArray3[j];
                document.getElementsByName("td4")[i].innerHTML=tdArray4[j];
                document.getElementsByName("td5")[i].innerHTML=tdArray5[j];
                orginArray[j]=null;
                break;
            }
        }
    }
}

window.onload=function(){
    td_color_change();
    summary_cpu_process_check_info();
    var check_report_table=document.getElementsByName("check_report_table")[0];
    makeSortable(check_report_table);
}
</script>
###################### End Check Report Html Tail ########################
######################## End Main Info Data ##########################

