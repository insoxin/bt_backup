#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin;

#----------↓配置信息区域↓----------#

#数据库root密码
mysql_password="0d8f47eb86f2c51c";

#备份存储位置类型（local：本地，remote：远程linux服务器，aliyun：阿里云OSS，qcloud：腾讯云COS，huawei：华为云OBS，baidu：百度云BOS）
backup_type="local";

#远程服务器IP
remote_server_ip="10.0.5.10";
#远程服务器登录用户名
remote_server_user="root";
#远程服务器保存路径
remote_server_path="/home/backup";

#云存储的bucket名称
cloud_bucket="cccyun";
#云存储的存储路径
cloud_path="/backup/";

#----------↑配置信息区域↑----------#


echo -e "————————————————————————————————————————————————————
	\033[32m宝塔面板站点与数据库备份脚本\033[0m
	Powered By 彩虹
————————————————————————————————————————————————————"
echo '';


if [ $(whoami) != "root" ];then
	echo "请使用root权限执行命令！"
	exit 1;
fi
if [ ! -d /www/server/panel ] || [ ! -f /etc/init.d/bt ];then
	echo "未安装宝塔面板"
	exit 1
fi 
if [ ! -f /usr/bin/innobackupex ]; then
	echo "未安装 XtraBackup，无法继续执行备份脚本。";
	exit 1;
fi


DateTag=`date +%Y%m%d-%H%M%S`;
backup_file="${DateTag}.tgz";
mkdir -p /www/backup/onekey/${DateTag}/;
mkdir -p /www/backup/onekey/${DateTag}/config/;

echo "[Notice] Backup wwwroot.";
cd /www;
tar -czvf /www/backup/onekey/${DateTag}/wwwroot.tgz wwwroot --exclude *.log --exclude *.7z --exclude *.rar --exclude *.zip --exclude *.gz;

echo "[Notice] Backup mysql.";
innobackupex --user=root --password=$mysql_password --stream=tar ./ | gzip - > /www/backup/onekey/${DateTag}/mysql.tgz

echo "[Notice] Backup default.db.";
sqlite3 /www/server/panel/data/default.db <<EOF
.output /www/backup/onekey/${DateTag}/config/default.sql
.dump binding
.dump config
.dump databases
.dump domain
.dump site_types
.dump sites
EOF

echo "[Notice] Backup config files.";
cp -a /www/server/panel/vhost /www/backup/onekey/${DateTag}/config/;
if [ -f /www/server/panel/data/redirect.conf ]; then
	cp /www/server/panel/data/redirect.conf /www/backup/onekey/${DateTag}/config/
fi
if [ -f /www/server/panel/data/proxyfile.json ]; then
	cp /www/server/panel/data/proxyfile.json /www/backup/onekey/${DateTag}/config/
fi
if [ -f /www/server/panel/data/site_dir_auth.json ]; then
	cp /www/server/panel/data/site_dir_auth.json /www/backup/onekey/${DateTag}/config/
fi
if [ -d /www/server/pass ]; then
	cp -a /www/server/pass /www/backup/onekey/${DateTag}/config/
fi

cd /www/backup/onekey/${DateTag};
tar -czvf config.tgz config;
rm -rf config;


if [ "$backup_type" = "remote" ]; then

	remote_server="${remote_server_user}@${remote_server_ip}:${remote_server_path}";
	echo "[Notice] Upload to remote server: \"${remote_server}\", please wait.";

	scp -r /www/backup/onekey/${DateTag} ${remote_server};
	rm -rf /www/backup/onekey/${DateTag};

	echo -e "\033[32mUpload to remote server: \"${remote_server}\" success.\033[0m";

elif [ "$backup_type" = "aliyun" ]; then

	oss_path="oss://${cloud_bucket}${cloud_path}";
	echo "[Notice] Upload to Aliyun OSS: \"${oss_path}\", please wait.";

	ossutil cp -r /www/backup/onekey/${DateTag} ${oss_path}${DateTag}/ --retry-times=5;
	rm -rf /www/backup/onekey/${DateTag};

	echo -e "\033[32mUpload to Aliyun OSS: \"${oss_path}\" success.\033[0m";

elif [ "$backup_type" = "qcloud" ]; then

	cos_path="cos://${cloud_bucket}${cloud_path}";
	echo "[Notice] Upload to Qcloud COS: \"${cos_path}\", please wait.";

	coscli cp -r /www/backup/onekey/${DateTag} ${cos_path}${DateTag}/;
	rm -rf /www/backup/onekey/${DateTag};

	echo -e "\033[32mUpload to Qcloud COS: \"${cos_path}\" success.\033[0m";

elif [ "$backup_type" = "huawei" ]; then

	obs_path="obs://${cloud_bucket}${cloud_path}";
	echo "[Notice] Upload to HuaweiCloud OBS: \"${obs_path}\", please wait.";

	obsutil cp -r -f /www/backup/onekey/${DateTag} ${obs_path}${DateTag}/;
	rm -rf /www/backup/onekey/${DateTag};

	echo -e "\033[32mUpload to HuaweiCloud OBS: \"${obs_path}\" success.\033[0m";

elif [ "$backup_type" = "baidu" ]; then

	bos_path="bos:/${cloud_bucket}${cloud_path}";
	echo "[Notice] Upload to BaiduCloud BOS: \"${bos_path}\", please wait.";

	bcecmd bos cp -r /www/backup/onekey/${DateTag}/ ${bos_path}${DateTag}/;
	rm -rf /www/backup/onekey/${DateTag};

	echo -e "\033[32mUpload to BaiduCloud BOS: \"${bos_path}\" success.\033[0m";

fi

# crontab -e
# 0 2 * * * /root/backup.sh >/root/backup.log 2>&1