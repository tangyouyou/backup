#!/bin/bash
#Author:zhongwei

set -e
echo -e "\033[31;1m*****[ Mongodb ] 全库恢复脚本*****\033[0m"
host=mongodb.service.consul
port=27017
user=root
password=BDRXBkmqblP1
mongorestore=/usr/bin/mongorestore
backpath=/backup/mongodb
mongocmd=" --host ${host} --port ${port} -u ${user} -p ${password} --authenticationDatabase admin "
 
echo -e "\033[32;1m[ 选择要恢复全库的日期 ] \033[0m"
for backfile in `ls $backpath`;do
    echo $backfile
done
 
read -p ">>>" date_bak
 
if [[ $date_bak == "" ]] || [[ $date_bak == '.' ]] || [[ $date_bak == '..' ]];then
    echo -e "\033[31;1m输入不能为特殊字符.\033[0m"
    exit 1
fi
 
 
if [ -d $backpath/$date_bak ];then
    read -p "请确认是否恢复全库备份[y/n]:" choice
 
    if [ "$choice" == "y" ];then
        echo -e "\033[32;1m正在恢复全库备份，请稍后...\033[0m"
        ${mongorestore} ${mongocmd} --oplogReplay --gzip $backpath/$date_bak/
        if [ $? -eq 0 ];then
            echo -e "\033[32;1m--------全库恢复成功.--------\033[0m"
        else
            echo -e "\033[31;1m恢复失败,请手动检查!\033[0m"
            exit 3
        fi
    else
        exit 2
    fi
else
    echo "\033[31;1m输入信息错误.\033[0m"
    exit 1
fi