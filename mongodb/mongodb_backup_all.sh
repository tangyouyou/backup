#!/bin/bash
#Author:zhongwei
set -e
host=mongodb.service.consul
port=27017
user=root
password=BDRXBkmqblP1
sourcepath=/usr/bin/mongodump
targetpath=/backup/mongodb
nowtime=`date "+%Y%m%d"`
mongocmd=" --host ${host} --port ${port} -u $user -p ${password} --authenticationDatabase admin "
fullpath=${targetpath}/${nowtime}
backup_server[0]={"ip":"127.0.0.1"} # 日志同步到远程服务器数组

# 格式化
parse_json(){
echo "${1//\"/}" | sed "s/.*$2:\([^,}]*\).*/\1/"
}
 
start(){
    ${sourcepath} ${mongocmd} --oplog --gzip --out ${fullpath}
}
 
execute(){
	echo "=========================$(date) backup all mongodb back start  ${nowtime}========="
	start
	if [ $? -eq 0 ];then
	    echo "The MongoDB BackUp Successfully!"
	else
	    echo "The MongoDB BackUp Failure"
	fi
}
 
if [ ! -d "${fullpath}" ];then
    mkdir -p "${fullpath}"
fi
 
execute

# MongoDB 全量数据，同步到远程服务器
for item in ${backup_server[*]}
do
s_ip=$(parse_json $item "ip")
echo $s_ip
rsync -avR --delete  ${targetpath}/ $s_ip:/
done
done

# 删除3天前的全量备份目录
backtime=$(date -d '-3 days' "+%Y%m%d")
if [ -d "${targetpath}/${backtime}/" ];then
    rm -rf "${targetpath}/${backtime}/"
    echo "=======${targetpath}/${backtime}/===删除完毕=="
fi
 
echo "========================= $(date) backup all mongodb back end ${nowtime}========="