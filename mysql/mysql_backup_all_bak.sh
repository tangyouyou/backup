#!/bin/bash
innobackupex=/usr/bin/innobackupex #命令位置
mysql_cmd=" --user=root --password=password --host=192.168.1.170 --port=3306" #数据库连接信息
backup_full=/root/mysql/backup/full #全量备份主目录
backup=/root/mysql/backup/backup/ #增量备份主目录
date=`date +%Y-%m-%d`
#echo $backup_full/$date
#判断命令是否安装、目录是否存在、数据库连接信息是否正确等过滤
#如果全量备份目录为空，则开始进行全量备份，并获取目录名
ulimit -n 10240
flag_backup_full=`ls $backup_full | wc -l`
if [ $flag_backup_full -eq 0 ]; then #如果全量备份目录为空，则进行全量备份
    mkdir -p $bakcup_full/$date
    `$innobackupex $mysql_cmd $backup_full/$date`
fi

if [ `date +%u` -eq 1 ]; then #如果是星期一则进行全量备份
    mkdir -p $bakcup_full/$date
    `$innobackupex $mysql_cmd $backup_full/$date`
if [ `ls -lt|sed -n 2p|awk '{print $9}'` -gt 2 ];then #如果全量备份下目录大于2，则删除最旧的，保留两份全量备份
    zaoqi_mulu=`ls -lrt|sed -n 2p|awk '{print $9}'`
    rm -rf $zaoqi_mulu
fi
else #否则获取最新的全量备份目录进行增量备份
    new_quanliang=`ls -lt $backup_full|sed -n 2p|awk '{print $9}'`
# echo $new_quanliang
# str=`ls -lt $backup_full/$new_quanliang`
# echo $str
    new_mulu=`ls -lt $backup_full/$new_quanliang|sed -n 2p|awk '{print $9}'`
# echo $new_mulu
# echo $new_mulu
# echo $backup_full/$date/$new_mulu
    `$innobackupex $mysql_cmd --incremental $backup/$date --incremental-basedir=$backup_full/$new_quanliang/$new_mulu`
fi
#如果增量备份大于12则删除最旧的，保留12份增量备份
back_zengliang_num=`ls -l $backup|wc -l`
echo $back_zengliang_num
old_zengliang=`ls -lrt|sed -n 2p|awk '{print $9}'`
echo $old_zengliang
if [ $back_zengliang_num -gt 12 ]; then
rm -rf $backup/$old_zengliang
fi