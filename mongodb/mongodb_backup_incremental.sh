#!/bin/bash
#Author:zhongwei

set -e
mongo_path=/usr/bin/mongo
mongodb_path=/usr/bin/mongodump
port=27017
host=mongodb.service.consul
user=root
password=DsYj5laYiMUm
backup_path=/backup/mongodb
backup_data_path=${backup_path}/mongodb_oplog_bak/mongo-$port
backup_log_path=${backup_path}/mongodb_oplog_bak/log-$port
backup_server[0]={"ip":"192.168.19.52"} # 日志同步到远程服务器数组

# 格式化
parse_json(){
echo "${1//\"/}" | sed "s/.*$2:\([^,}]*\).*/\1/"
}

if [ ! -d ${backup_data_path} ];then
    mkdir -p ${backup_data_path}
fi

if [ ! -d ${backup_log_path} ];then
    mkdir -p ${backup_log_path}
fi


log_file=$(date +"%Y%m%d")

echo "===MongoDB 端口为" $port "的差异备份开始，开始时间为" $(date -d today +"%Y%m%d%H%M%S")

param_end_date=$(date +%s)
echo "===本次备份时间参数中的结束时间为：" $param_end_date

diff_time=$(expr 65 \* 60)
echo "===备份设置的间隔时间为：" $diff_time

param_start_date=$(expr $param_end_date - $diff_time)
echo "===本次备份时间参数中的开始时间为：" $param_start_date

diff_time=$(expr 61 \* 60)
param_after_request_startdate=$(expr $param_end_date - $diff_time)
echo "===为保证备份的连续性,本次备份后,oplog中的开始时间需小于：" $param_after_request_startdate

backup_file=$(date -d today +"%Y%m%d%H%M%S")

#mongo mongodb://root:BDRXBkmqblP1@mongodb.service.consul:27017/admin
command_line="${mongo_path} mongodb://${user}:${password}@${host}:${port}/admin"

opmes=$(/bin/echo "db.printReplicationInfo()" | $command_line --quiet)

opbktmplogfile=/tmp/opdoctime$port.tmplog
echo $opmes > ${opbktmplogfile}

opstartmes=$(grep "oplog first event time" $opbktmplogfile | awk -F 'CST' '{print $1}' | awk -F 'oplog first event time: '  '{print $2}' | awk -F ' GMT' '{print $1}'  )
oplogRecordFirst=$(date -d "$opstartmes"  +%s)
echo "===oplog集合记录的开始时间为[格式化]：" $oplogRecordFirst
if [ $oplogRecordFirst -le $param_start_date ];then
    echo "Message --检查设置备份时间合理。备份参数的开始时间在oplog记录的时间范围内。"
else
    echo "Fatal Error --检查设置的备份时间不合理合理。备份参数的开始时间不在oplog记录的时间范围内。请调整oplog size或调整备份频率。本次备份可以持续进行，但还原时数据完整性丢失。"
fi

# 增量备份
query='{"ts":{"$gte":{"$timestamp":{"t":'${param_start_date}',"i":1}},"$lte":{"$timestamp":{"t":'${param_end_date}',"i":1}}}}'
${mongodb_path} -h $host --port $port -u $user -p $password --authenticationDatabase admin -d local -c oplog.rs  --query ${query} -o $backup_data_path/mongodboplog$backup_file

opmes=$(/bin/echo "db.printReplicationInfo()" | $command_line --quiet)
echo $opmes > ${opbktmplogfile}
opstartmes=$(grep "oplog first event time" $opbktmplogfile | awk -F 'CST' '{print $1}' | awk -F 'oplog first event time: '  '{print $2}' | awk -F ' GMT' '{print $1}'  )
oplogRecordFirst=$(date -d "$opstartmes"  +%s)
echo "===执行备份后,oplog集合记录的开始时间为[时间格式化]:" $oplogRecordFirst

if [ $oplogRecordFirst -le $param_after_request_startdate ];then
    echo "Message --备份后，检查oplog集合中数据的开始时间，即集合中最早的一笔数据，时间不小于61分钟的时间（即参数 param_after_request_startdate）。这样可以保证每个增量备份含有最近一个小时的全部op操作，满足文件的持续完整性，逐个还原无丢失数据风险。"
else
    echo "Fatal Error --备份后，检查oplog集合的涵盖的时间范围过小（小于61min）。设置的备份时间不合理合理，备份后的文件不能完全涵盖最近60分钟的数据。请调整oplog size或调整备份频率。本次备份可以持续进行，但还原时数据完整性丢失。"
fi

if [ -d "$backup_data_path/mongodboplog$backup_file" ]
then
    echo "Message --检查此次备份文件已经产生.文件信息为:" $backup_data_path/mongodboplog$backup_file >> $backup_log_path/$log_file.log
else
    echo "Fatal Error --备份过程已执行，但是未检测到备份产生的文件，请检查！" >> $backup_log_path/$log_file.log
fi

keepbaktime=$(date -d '-3 days' "+%Y%m%d%H")*
if [ -d $backup_data_path/mongodboplog$keepbaktime ];then
    rm -rf $backup_data_path/mongodboplog$keepbaktime
    echo "Message -- $backup_data_path/mongodboplog$keepbaktime 删除完毕" >> $backup_log_path/$log_file.log
fi

echo "===MongoDB 端口为" $port"的差异备份结束，结束时间为：" $(date -d today +"%Y%m%d%H%M%S")

# 删除三天前的增量备份目录
find ${backup_data_path} -maxdepth 1 -type d -mtime +3 | xargs rm -rf

# MongoDB 增量数据，同步到远程服务器
for item in ${backup_server[*]}
do
s_ip=$(parse_json $item "ip")
echo $s_ip
rsync -avR --delete  ${backup_data_path}/ $s_ip:/
rsync -avR --delete  ${backup_log_path}/ $s_ip:/
done