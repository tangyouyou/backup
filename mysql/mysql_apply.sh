#!/bin/sh
set -e
lang=C
innodbupex="/usr/bin/innobackupex"
mysql_cmd=" --defaults-file=/etc/mysql/default.my.cnf --user=root --password=oF7Df72P_NWs --host=mysql-default.service.consul --port=3306 " #数据库连接信息

echo 'please input date format: 2021-08-06'
read back_time

back_prefix=/backup/mysql 
back_dir=${back_prefix}/${back_time}

echo $back_dir

if [[ ! -d $back_dir ]]; then
    echo 'warning-----The format must be correct and make sure that the corresponding folder for that date exists'
    exit
fi

cd $back_dir

full_back=`ls -1 | grep  $back_time | sort | awk 'NR==1{print $1}'`
echo ${full_back}

files=`ls -1 | grep $back_time | sort`

for var in $files
do
    if [[ ${full_back} == $var ]]; then
        echo "quanbeifen"
        echo ${back_dir}/$var
        ${innodbupex} ${mysql_cmd} --apply-log  --redo-only ${back_dir}/${full_back}
    else
        echo "zeengliang--"$var 
        echo ${back_dir}/$var
        ${innodbupex} ${mysql_cmd} --apply-log  --redo-only ${back_dir}/${full_back} --incremental-dir=${back_dir}/$var
    fi
done

#Data rollback 
${innodbupex} ${mysql_cmd} --apply-log --redo-only ${back_dir}/${full_back}

echo "use the cmd to rollback Data"

echo "${innodbupex} ${mysql_cmd} --copy-back ${back_dir}/${full_back}"

