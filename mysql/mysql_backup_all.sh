#!/bin/sh
set -e
lang=C
current_time=`date +%Y-%m-%d`
dir_time=${current_time}
back_prefix=/backup/mysql 
back_dir=${back_prefix}/${dir_time} # 备份路径(全量 & 增量)
innodbupex="/usr/bin/innobackupex"
mysql_cmd=" --defaults-file=/etc/mysql/default.my.cnf --user=root --password=oF7Df72P_NWs --host=mysql-default.service.consul --port=3306 " #数据库连接信息
binlog_dir=/data/bkce/public/mysql/default/binlog # binlog 日志文件所在目录
binlog_server[0]={"ip":"192.168.244.151"}
binlog_back_dir=${back_prefix}/binlog # binlog 日志文件复制目录

parse_json(){
echo "${1//\"/}" | sed "s/.*$2:\([^,}]*\).*/\1/"
}


if [ ! -d ${back_dir} ]
then
        mkdir -p ${back_dir}
        cd ${back_dir}
        $innodbupex ${mysql_cmd} ${back_dir} 
elif [ -d ${back_dir} ]
then
        cd ${back_dir}
        full_backup=`ls -1 | grep  $current_time | sort -k 1r | awk 'NR==1{print $1}'`
        if [ -d ${full_backup:-nodir} ]
        then
                # 增量备份
                ${innodbupex} ${mysql_cmd} --incremental ${back_dir} --incremental-basedir=$full_backup 
        else
                # 全量备份
                ${innodbupex} ${mysql_cmd} $back_dir
        fi
fi

# binlog 日志同步
for item in ${binlog_server[*]}
do
s_ip=$(parse_json $item "ip")
echo $s_ip
rsync -av --delete  ${binlog_dir}/ $s_ip:${binlog_back_dir}
done

# 删除三天前的历史备份文件
baktime=$(date -d '-3 days' "+%Y-%m-%d")
if [ -d "${back_prefix}/${baktime}/" ]
then
  rm -rf "${back_prefix}/${baktime}/"
  echo "=======${back_prefix}/${baktime}/===删除完毕=="
fi