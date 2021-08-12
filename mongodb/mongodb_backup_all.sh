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
 
backtime=$(date -d '-3 days' "+%Y%m%d")
if [ -d "${targetpath}/${backtime}/" ];then
    rm -rf "${targetpath}/${backtime}/"
    echo "=======${targetpath}/${backtime}/===删除完毕=="
fi
 
echo "========================= $(date) backup all mongodb back end ${nowtime}========="