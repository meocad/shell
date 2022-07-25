#!/bin/bash

function handle_INT()
{
    echo
    echo "user ctrl+c, do clean..."
    rm ${tempfile} `pwd`/oct.log 2>/dev/null
    exit
}
trap 'handle_INT' SIGINT

basedir=$(dirname $(dirname `readlink -f $0`))
scriptdir=${basedir}/bin
tempfile=${scriptdir}/conn

if ! type java >/dev/null 2>&1 ;then 
    echo "no java env, please check."
fi
[[ ! -f "$scriptdir/oct.sh" ]] && {
    echo "missing $scriptdir/oct.sh file, please check."; 
    exit; 
}

usage(){
echo '# manage for OB utils
-h, --hint          :  startup with hint;
-f, --filter string  :  choices in "ob" or "host";
-s, --sys            :  get connection with sys tenant;
-u, --user string    :  do query with giving user name, default "root";
-t, --tenant string  :  do query with giving tenant name;
-c, --cluster string :  do query with giving cluster name;
-n, --nopass         :  do disable password appearance;

# manage for hosts utils
--help           :  do query with giving host name;
eta 
'
}
[[ "$#" -eq 0 ]] && { usage; exit 1; }

Color_Text() {
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

invalid_args(){
    [[ `echo """$1"""|head -c1` == '-' ]] && { 
        echo "option '$2' requires an argument";exit
    }
    return 1
}

types=2
search=1
myargs="-A"
getopt_cmd=$(getopt -o au:t:f:c:snh --long help,sys:,user:,filter:,hint,tenant:,all,cluster: -n $(basename $0) -- "$@")
[[ $? -ne 0 ]] && { usage; exit 1; }
eval set -- "${getopt_cmd}"

while [[ -n "$1" ]]
do
    case "$1" in
        --help)
            usage
            exit ;;
        -f|--filter)
            invalid_args $2 "$1" || filter="$2"
            case "$filter" in
                "host")
                    types="1";shift ;;
                "ob")
                    types="2";shift ;;
                "proxy")
                    types="3";shift ;;
                *)
                    echo "Err filter, do exit";exit ;;
            esac;;
        -s|--sys)
            tenant="sys"
            myargs="${myargs}Doceanbase" ;;
        -h|--hint)
            myargs="-cDoceanbase" ;;
        -n)
            enble_pass_appearance="0" ;;
        -u|--user)
            invalid_args $2 "$1" || user="$2"
            shift ;;
        -t|--tenant)
            invalid_args $2 "$1" || [[ -z "$tenant" ]] && tenant="$2"
            shift ;;
        -a|--all)
            all_cluster="True"
            search=0 ;;
        -c|--cluster)
            invalid_args $2 "$1" || cluster="$2"
            shift ;;
        --) shift
            break ;;
         *) echo "$1 is not an option"
            exit 1 ;;
    esac
    shift
done

# oct 工具解析用户要求的秘密信息
oct_tool_exe(){
    count=1
    echo -e ''$1'' | sed 's/,$//' |\
         sh ${scriptdir}/oct.sh list 2>/dev/null|\
         awk -F'secret=|, description=null' '/^Credential/{print $2}'|\
         while read line
         do
             password=$(echo ''${line}'' | awk -F'"password":' '{print $2}'   | awk -F'",' '{print $1}'| sed 's/^"//g;s/"\}$//g')
             tname=$(   echo ''${line}'' | awk -F'"tenantName":' '{print $2}' | awk -F'",' '{print $1}'| sed 's/^"//g;s/"\}$//g')
             cname=$(   echo ''${line}'' | awk -F'"clusterName":' '{print $2}'| awk -F'",' '{print $1}'| sed 's/^"//g;s/"\}$//g')
             uname=$(   echo ''${line}'' | awk -F'"username":' '{print $2}'   | awk -F'",' '{print $1}'| sed 's/^"//g;s/"\}$//g')
             host=$(get_hosts | grep -w "$cname" |awk '{print $(NF-1)}')
             port=$(get_hosts | grep -w "$cname" |awk '{print $NF}')

             if [[ `echo "$host"|wc -l` -gt 1 || -z "$host" ]];then
                 echo "something goes wrong!"
                 exit
             fi

             echo "$count $host $cname $tname $uname $port $password"
             let count++
         done
}

get_obmeta(){
    [[ -s "$basedir/config/config.yaml" ]] || {
        echo "$basedir/config/config.yaml file is not exist or some other wrong, please check!";
        exit;
    }

    # meta_ip=$(egrep '^[[:space:]]{4}ip:' $basedir/config/config.yaml)
    meta_ip=$(  awk "/^[[:space:]]{4}ip:/{gsub(/\"|'/,\"\");print \$NF}"       ${basedir}/config/config.yaml)
    meta_db=$(  awk "/^[[:space:]]{4}database:/{gsub(/\"|'/,\"\");print \$NF}" ${basedir}/config/config.yaml)
    meta_user=$(awk "/^[[:space:]]{4}username:/{gsub(/\"|'/,\"\");print \$NF}" ${basedir}/config/config.yaml)
    meta_port=$(awk "/^[[:space:]]{4}port:/{gsub(/\"|'/,\"\");print \$NF}"     ${basedir}/config/config.yaml)
    meta_pass=$(awk "/^[[:space:]]{4}password:/{gsub(/\"|'/,\"\");print \$NF}" ${basedir}/config/config.yaml)

    mystr='mysql -N -h'${meta_ip}' -P'${meta_port}' -u'${meta_user}' -p'${meta_pass}' -D'${meta_db}''
}

# 获取集群vip及port
get_hosts(){
    q_cluster="select name,rootserver_json from ob_cluster;"
    ${mystr} -e """$q_cluster"""| col -b | while read cluster_name jsonstr
    do
        cname="$cluster_name"
        formated_str="$(echo ${jsonstr} | sed 's/{/\n/g;s/}/\n/g;s/"//g'| egrep -i "^address.*LEADER" | tr ',' '\n')"
        host=$(echo "$formated_str" | awk -F':' '/address/{print $2}')
        port=$(echo "$formated_str" | awk -F':' '/sql_port/{print $2}')

        echo "$cname $host $port"
    done
}

# 处理用户指定的查询
mysql_conn() {
    count=1
    ${mystr} -e 'select secret from profile_credential where access_target="OB" and secret like "%clusterName%'${cluster}'%" and secret like "%tenantName%'${tenant}'%" and secret like "%username%'${user}'%"'|col -b | while read line
do
    uname=$(   echo ''${line}'' | awk -F'"username":' '{print $2}'   | awk -F'",' '{print $1}'| sed 's/^"//g;s/"\}$//g')
    
    [[ "$uname" == "proxyro" ]]     && continue
    [[ "$uname" == "ocp_monitor" ]] && continue
    
    tname=$(   echo ''${line}'' | awk -F'"tenantName":' '{print $2}' | awk -F'",' '{print $1}'| sed 's/^"//g;s/"\}$//g')
    cname=$(   echo ''${line}'' | awk -F'"clusterName":' '{print $2}'| awk -F'",' '{print $1}'| sed 's/^"//g;s/"\}$//g')
    uname=$(   echo ''${line}'' | awk -F'"username":' '{print $2}'   | awk -F'",' '{print $1}'| sed 's/^"//g;s/"\}$//g')
    
    if ! echo ${username}    | grep -wq ''${uname}'';then username="$uname,$username"       ;fi
    if ! echo ${tenantname}  | grep -wq ''${tname}'';then tenantname="$tname,$tenantname"   ;fi
    if ! echo ${clustername} | grep -wq ''${cname}'';then clustername="$cname,$clustername" ;fi
    
    echo -e "${types}\n${clustername}\n${tenantname}\n${username}\nadmin"
done
}

tenant_reader(){
    > ${tempfile}
    q_sql='SELECT
        a.svr_ip,
        b.tenant_name
    FROM
        __all_virtual_meta_table a
        JOIN __all_tenant b ON a.tenant_id = b.tenant_id
    WHERE
        b.tenant_name NOT IN ( "ocp_meta", "ocp_monitor" )
    GROUP BY
        b.tenant_name;
    '
    ct=1
    echo "$1" | while read c host cl tt user port pass
    do
        if ! echo "$cl"| grep -qi "$cluster";then
            continue
        else
            if echo "sys" |grep -qi "$tenant" ;then
                echo -ne "\n$cl\t#$ct sys"
                echo "$ct $cl sys $host $port">> ${tempfile}
                fl=1
            else
                ct=0
                echo -ne "\n$cl\t# 占位符"
            fi
        fi

        ret="$(mysql -N -h"$host" -u"${user}"@"${tt}" -P"${port}" -p"$pass" -Doceanbase -e "${q_sql}")"
        if [[ ! -z "$ret" ]];then
            for tenants in $(echo "${ret}" | tr '\t' ',')
            do
                t=$(echo "$tenants" | cut -d',' -f 2)
                if echo "$t"| grep -qi "$tenant";then
                    let ct++
                    h=$(echo "$tenants" | cut -d',' -f 1)
                    echo -ne "\n\t#$ct $t"
                    echo "$ct $cl $t $h $port"  >> ${tempfile}
                fi
            done
        elif [[ "$cl" != "obcluster" ]];then
            echo "There is no custom tenant tenant in $cl, please check.";
            exit
        fi
        [[ "$fl" -eq 1 ]] && let ct++
    done
    echo
#    cat "${tempfile}"
}

do_exe(){
    if [[ "$2" -eq 0 ]];then
        str=$(grep -w "^$1" ${tempfile} )
    else
        str=$(grep "^$1" ${tempfile})
        [[ "$(echo ${str})" -gt 1 ]] && {
            echo "ambiguous choice please retry";
            retrun;
        }
    fi
#    rm ${tempfile}
    # 10 hndsj_other hndsj_xyh 172.20.58.214 2881
    uname="root"
    host=$(echo ${str} | awk '{print $4}')
    tname=$(echo ${str} | awk '{print $3}')
    cname=$(echo ${str} | awk '{print $2}')

    str="2\n${cname}\n${tname}\n${uname}\nadmin\n"
    password=$(oct_tool_exe "$str"| awk '{print $NF}')
    [[ -z "$password" ]] && {
        echo "oct tool parse error, username: $uname, host: $host,clustername: $cname,tenant: $tname";
        exit;
    }
    echo
    [[ -z "$enble_pass_appearance" ]] && \
    Color_Text "blue" 'mysql -v -h'${host}' -u'${uname}'@'${tname}'#'${cname}' -P2883 -p'"'$password'"' '${myargs}''
    echo
    mysql -h"$host" -u"$uname"@"${tname}"\#"${cname}" -P2883 -p"$password" "$myargs"
#    cat ${tempfile} | awk '{printf "%s 集群名称: %-10s\t连接地址: %-10s\t租户名称: %s\t用户名称: %s\n",$1,$3,$2,$4,$5}'
    select_show_banner "$3"
}

search_main() {
#    echo -e ''$1''| awk '{printf "%s 集群名称: %-10s\t连接地址: %-10s\t租户名称: %s\t用户名称: %s\n",$1,$3,$2,$4,$5}'
    max=$(tail -1 ${tempfile} | awk '{print $1}')
    while true;do
        read -p "your select(exit with q) ? " se
        [[ "$se" =~ ^[0-9]+$ ]] && [[ "$se" -gt 0 && "$se" -le "$max" ]] && do_exe "${se}" "0" "$1"
        [[ "$se" =~ ^[a-zA-Z]+$ ]] && [[ "$se" -gt 0 && "$se" -le "$max" ]] && do_exe "${se}" "1" "$1"
        [[ "$se" == "q" ]] && { rm ${tempfile} `pwd`/oct.log ;exit; }
    done
}

select_show_banner() {
    banner="Oceanbase Group Info\n集群名称\t租户名称"
    echo -e "${banner}$1" | sh ${scriptdir}/draw_table.sh -15 -red,-white,-blue
}

main(){
    # 1. 获取ob_meta信息
    get_obmeta
    # 2. 获取ob集群vip及端口
    # 3. 获取每个集群sys信息
    sys_info="$(get_hosts)"

    all_clusters=$(echo "${sys_info}" | awk '{print $1}'| tr '\n' ',')
    str="2\n${all_clusters}\nsys\nroot\nadmin\n"
    pass="$(oct_tool_exe "${str}")"   # oct 获取密码

    # tenant_reader """${pass}""" | sh ${scriptdir}/draw_table.sh -4 -red,-white,-blue
#    echo -e "$(tenant_reader "${pass}")"
    show_banner="$(tenant_reader "${pass}")"
    select_show_banner "$show_banner"
    # 4. 整理并输出连接串
    [[ "${search}" -eq 0 ]] && search_main "$show_banner"
    [[ "${search}" -eq 1 ]] && search_main "$show_banner"

    rm ${tempfile} `pwd`/oct.log
}

main
