# MySQL

## 数据备份

### 使用说明

1. MySQL 备份脚本同时支持“全量备份”、“增量备份”两种方式；使用前，复制脚本代码，替换 MySQL 的可选参数信息。

主要包括

user、port、host、mysql 配置文件路径：mysql_cmd 变量

binlog 日志文件路径：binlog_dir 变量

binlog 日志备份路径：binlog_back_dir 变量

远程同步服务器数组：backup_server 变量

数据备份路径 ：back_dir 变量

2. 将备份脚本添加到 /etc/crontab 中，建议每一个小时执行一次：0 */1 * * * root sh /backup/mysql_backup_all.sh

3. 提前确认备份软件 “innobackupex ”是否已在服务器上完成安装

### 备份步骤参考

1. sh mysql_backup_all.sh

2. 模拟删除数据库 test，命令：drop database test;

3. 恢复数据库

## 数据恢复

### 使用说明

1. 修改 mysql_cmd 的配置信息，配置文件调整与本文中【数据恢复】脚本的调整一致

2. 执行数据恢复脚本，输入需要具体恢复的日期，例如：2021-08-20

 

#### 全量恢复步骤参考

步骤1：service mysqld stop；停止数据库

步骤2：mv /data/mysql /data/mysql_bak；备份数据库的历史 data

步骤3：mkdir -p /data/mysql；新建权限的 data 目录

步骤4：sh mysql_apply.sh；进行 MySQL 数据备份

步骤5：chown -R mysql:mysql /data/mysql；设置 mysql 目录权限

步骤6：service mysqld start；启动数据库

步骤7：进入 MySQL 执行 flush logs；注意：每次全量备份后，需要立刻 flush logs，避免因数据备份后导致 binlog 对应不上的问题

步骤8：rm -rf /backup/mysql/2021-08-10；删除历史全量备份数据

步骤9：重新执行 MySQL 数据备份脚本；sh mysql_back_all.sh

 

#### 增量恢复步骤参考

步骤1：service mysqld stop；停止数据库

步骤2：mv /data/mysql /data/mysql_bak；备份数据库的历史 data

步骤3：mkdir -p /data/mysql；新建权限的 data 目录

步骤4：sh mysql_apply.sh；进行 MySQL 数据备份

步骤5：chown -R mysql:mysql /data/mysql；设置 mysql 目录权限

步骤6：service mysqld start；启动数据库

步骤7：fush tables with read lock; 全量数据恢复完，需要进入只读模式，进行 binlog 的恢复，避免数据的变更对历史的备份产生影响

步骤8：cat /backup/mysql/2021-08-09/2021-08-09_19-48-51/xtrabackup_binlog_info；查看当前全量备份 binlog 的位置

步骤9：mysqlbinlog --no-defaults --base64-output=DECODE-ROWS -v /data/mysql_bak/mysql-bin.000001 --start-position=298 > /tmp/test.sql；根据 步骤8 的 binlog 位置，将 binlog 导出成 sql 文件

步骤10：mysql -uroot -prootDeFau_lt.123 -e 'source /tmp/test.sql'；重新执行 binlog 对于的SQL 文件

步骤11：unlock tables; 解锁数据表

步骤12：flush logs; 重新生成 binlog

步骤13：rm -rf /backup/mysql/2021-08-10；删除历史全量备份数据

步骤14：sh /backup/mysql_back_all.sh；重新进行全量备份

# MongoDB

## 使用说明

1. MongoDB 数据采用 mongodump 进行数据备份，官方描述 mongodump 只能备份小数据量的场景，当出现备份脚本不适用时，可以寻找其他的备份方案

2. MongoDB 增量备份，依赖于 MongoDB 的副本集 oplog.bson ，只有副本集的 MongoDB 架构可以进行增量备份。

3. 将全量备份脚本添加到 /etc/crontab 中，建议每天凌晨2点执行一次：0 2 * * * root sh /backup/mongodb_backup_all.sh

4. 将增量备份脚本添加到 /etc/crontab 中，建议每3个小时执行一次：0 */3 * * * root sh /backup/mongodb_backup_incremental.sh

### 全量备份
使用说明：

1. 修改配置参数，根据实际情况填写

### 增量备份
使用说明：

1. 修改配置参数，根据实际情况填写

## 数据恢复
使用说明：

1. Mongodb 的全量数据恢复、增量数据恢复比较简单，直接执行脚本即可

2. 根据实际情况，修改脚本的参数信息
 
