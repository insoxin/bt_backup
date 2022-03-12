#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin;

#----------↓配置信息区域↓----------#

#数据库root密码
mysql_password="0d8f47eb86f2c51c";

#----------↑配置信息区域↑----------#


echo -e "————————————————————————————————————————————————————
	\033[32m宝塔面板站点与数据库备份还原脚本\033[0m
	Powered By 彩虹
————————————————————————————————————————————————————"
echo '';


if [ $(whoami) != "root" ];then
	echo "请使用root权限执行命令！"
	exit 1;
fi
if [ ! -d /www/server/panel ] || [ ! -f /etc/init.d/bt ];then
	echo "未安装宝塔面板"
fi
if [ ! -f /usr/bin/innobackupex ]; then
	echo "未安装 XtraBackup，无法继续执行备份还原脚本。";
	exit 1;
fi


BACKUP_DIR=`pwd`;
if [ "$1" != "" ]; then
	BACKUP_DIR=$1;
fi

if [ ! -f "$BACKUP_DIR/config.tgz" ] || [ ! -f "$BACKUP_DIR/wwwroot.tgz" ] || [ ! -f "$BACKUP_DIR/mysql.tgz" ]; then
	echo "$BACKUP_DIR 目录下未找到备份文件，无法继续执行备份还原脚本。请将本脚本放到备份文件目录下执行，或使用 ./restore.sh [DIR]";
	exit 1;
fi

DB_COUNT=`sqlite3 /www/server/panel/data/default.db <<EOF
select count(*) from databases;
EOF`
if [ "$DB_COUNT" -gt "0" ]; then
	echo -e "\033[33m数据安全检查失败：请进入面板删除全部数据库之后再执行备份还原脚本。\033[0m";
	exit 1;
fi

WWWROOT_COUNT=`sqlite3 /www/server/panel/data/default.db <<EOF
select count(*) from sites;
EOF`
if [ "$WWWROOT_COUNT" -gt "0" ]; then
	echo -e "\033[33m数据安全检查失败：请进入面板删除全部站点之后再执行备份还原脚本。\033[0m";
	exit 1;
fi

echo "备份还原操作将清空当前服务器全部已有的数据库和网站文件！"
read -p "输入y确认继续执行备份还原: " yes;
if [ "$yes" != "y" ] && [ "$yes" != "Y" ];then
	echo "------------"
	echo "已取消备份还原"
	exit;
fi


echo "----------------------------------------------------"
echo "[Notice] 开始还原MySQL数据库";
/etc/init.d/mysqld stop
sleep 0.5
rm -rf /www/server/data/*;
tar zxvf mysql.tgz -C /www/server/data;
innobackupex --user=root --password=$mysql_password --apply-log /www/server/data
chown -R mysql:mysql /www/server/data
/etc/init.d/mysqld start
if test $? != 0; then
	echo "----------------------------------------------------"
	echo "[Error] MySQL数据库还原失败。"
	exit 1;
fi

echo "----------------------------------------------------"
echo "[Notice] 开始还原wwwroot网站文件";
find /www/wwwroot -name ".user.ini" -exec chattr -i {} \;
rm -rf /www/wwwroot/*;
tar zxvf wwwroot.tgz -C /www;
find /www/wwwroot -name ".user.ini" -exec chattr +i {} \;

echo "----------------------------------------------------"
echo "[Notice] 开始还原default.db";
tar zxvf config.tgz
sqlite3 /www/server/panel/data/default.db <<EOF
drop table binding;
drop table config;
drop table databases;
drop table domain;
drop table site_types;
drop table sites;
.read ${BACKUP_DIR}/config/default.sql
EOF
if test $? != 0; then
	echo "----------------------------------------------------"
	echo "[Error] default.db还原失败。"
	exit 1;
fi

echo "----------------------------------------------------"
echo "[Notice] 开始还原配置文件";
cp -a -f config/vhost /www/server/panel;
if [ -f config/redirect.conf ]; then
	cp -f config/redirect.conf /www/server/panel/data
fi
if [ -f config/proxyfile.json ]; then
	cp -f config/proxyfile.json /www/server/panel/data
fi
if [ -f config/site_dir_auth.json ]; then
	cp -f config/site_dir_auth.json /www/server/panel/data
fi
if [ -d config/pass ]; then
	cp -a -f config/pass /www/server
fi
rm -rf config;
/etc/init.d/nginx restart
if test $? != 0; then
	echo "----------------------------------------------------"
	echo "[Error] Nginx配置文件还原失败。"
	exit 1;
fi

echo "----------------------------------------------------"
echo -e "\033[32m备份还原已完成！\033[0m";
echo "----------------------------------------------------"
