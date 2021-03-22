#! /bin/bash 

SQL_FILE="stats.sql"
RM_FILE="rm"
DBS=xxx

cat > $SQL_FILE << EOF
SELECT
	DISTINCT cust_instance.ins_name,
	# hostinfo.ip,
	hostinfo.host_name,
	instance.port as 端口
FROM
	cust_instance,
	custins_hostins_rel,
	hostinfo,
	instance
WHERE
	cust_instance.id = custins_hostins_rel.custins_id
AND custins_hostins_rel.hostins_id = instance.id 
AND hostinfo.id = instance.host_id
AND cust_instance.is_deleted=0
AND instance.is_deleted=0
AND custins_hostins_rel.role=0
AND cust_instance.ins_name in (
$(sed "s/^/\'/g;s/$/',/g" $RM_FILE)
''
)
EOF

mysql -hdbaas.mysql.minirds.yunwei.chinaetc.org -udbaas -psAaztvYrfllhwu44 -Ddbaas -P3008 < stats.sql |awk 'NR>1 {print}' > temp_file
while read line
do 
	RM_ID=$(echo $line |cut -d " " -f1)
	HOST_ID=$(echo $line |cut -d " " -f2)
	PORT=$(echo $line |cut -d " " -f3)
    cat >> query << EOF
ssh $HOST_ID "cd /home/mysql/data${PORT}/dbs${PORT}; du -sh ./${DBS}*"
EOF
done < temp_file
source ./query 
rm -f $SQL_FILE
rm -f query
