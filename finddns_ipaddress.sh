#!/bin/bash

# input dns name as $1 $2 $3 $4 ...

# for example: sh finddns_ipaddress.sh baidu.com music.baidu.com buy.cloud.tencent.com

TMPFILE=$PWD/tmp.html
WRT_F=$PWD/file_record
#parse_args() {
#    op_parse=$(echo "$1"| grep -o '\.'| grep -c '\.')
#    if [[ "$op_parse" -eq 1 ]];then
#        par_dns="$1"
#        find_dns_url="https://${1}.ipaddress.com"
#    elif [[ "$op_parse" -gt 1 ]];then
#        par_dns=$(echo "$1"| awk -F'.' '{print $(NF-1)"."$NF}')
#        url="$1"
#        find_dns_url="https://${par_dns}.ipaddress.com/$url"
#    else
#        echo "Invalid pars, please check!!!"
#        return 1
#    fi
#}

parse_args() {
    #find_dns_url="https://websites.ipaddress.com/$1"
    find_dns_url="https://ipaddress.com/website/$1"
}

echo "Parse Result:"
for arg in "$@"
do
    parse_args "$arg"
    if [[ ! "$?" -eq 0 ]];then
       invalid_arg="$invalid_arg、$arg"
    fi
    
    dns_name=$arg
    curl -skL $find_dns_url > $TMPFILE
    ip_list=$(tidy -asxml -numeric  $TMPFILE 2>/dev/null| grep -m1 -A 10 'class="comma-separated"' | awk -F'>|<' '/li/{print $3}')
    
    printf "\t$dns_name\n"
    
    # oldifs="$IFS"
    # IFS=$'\n'
    record=
    for ip in $(echo $ip_list)
    do
        if [[ -z "$record" ]];then
            record="$ip"
        fi
        # IFS=$oldifs
        printf "\t\t$ip\n"
    done
    echo
    echo $record $dns_name >> $WRT_F
done

cat $WRT_F 2>/dev/null
rm $TMPFILE $WRT_F 2>/dev/null
