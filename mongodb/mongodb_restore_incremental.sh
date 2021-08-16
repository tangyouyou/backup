#!/bin/bash
#Author:zhongwei
set -e
host=192.168.244.78
port=27017
user=root
password=BDRXBkmqblP1
target_path=/backup/mongodb78
backpath=${target_path}/mongodb_oplog_bak/mongo-27017
mongorestore=/usr/bin/mongorestore
 
echo -e "\033[31;1m*****[ Mongodb ] 增量恢复脚本*****\033[0m"
 
echo -e "\033[32;1m[ 选择要恢复增量的日期(格式：年月日时分秒) ] \033[0m"
for time_file in `ls $backpath`;do
    echo $time_file
done
 
read -p ">>>" date_bak
if [[ $date_bak == "" ]] || [[ $date_bak == '.' ]] || [[ $date_bak == '..' ]];then
    echo -e "\033[31;1m输入不能为特殊字符.\033[0m"
    exit 1
fi
if [ -d $backpath/$date_bak ];then
    read -p "请确认是否恢复[$date_bak]增量备份[y/n]:" choice
    if [ "$choice" == "y" ];then
        mkdir -p /tmp/mongodb/ && cp -a $backpath/$date_bak/local/oplog.rs.bson /tmp/mongodb/oplog.bson
        ${mongorestore} --host $host --port $port --oplogReplay /tmp/mongodb/ && rm -rf /tmp/mongodb/
        if [ $? -eq 0 ];then
            echo -e "\033[32;1m--------[$date_bak]增量恢复成功.--------\033[0m"
        else
            echo -e "\033[31;1m恢复失败,请手动检查!\033[0m"
            exit 3
        fi
    else
        exit 2
    fi
else
    echo -e "\033[31;1m输入信息错误.\033[0m"
    exit 1
fi