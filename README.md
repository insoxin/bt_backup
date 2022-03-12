鉴于国内服务器的不确定性，近期经常有丢失数据的，因此特地出了这个宝塔面板站点与数据库一键备份与恢复脚本。分为2个文件，分别为备份脚本（backup.sh）与恢复脚本（restore.sh）。
该脚本相关功能与特色如下：
1、支持多种备份存储位置，有远程服务器(scp)、阿里云OSS、腾讯云COS、华为云OBS、百度云BOS
2、不仅可以备份全部网站文件和数据库，还可以备份所有网站的绑定域名、伪静态、反向代理、备注、SSL证书等各种网站设置。宝塔自带的备份功能只支持备份网站文件与数据库，不支持备份网站的设置信息。
3、数据库备份采用XtraBackup实现物理热备，即使是大量数据，也能很快完成备份与恢复，并且备份与恢复过程占用系统资源少。宝塔自带的数据库备份是逻辑备份，速度慢而且占用大量CPU。
4、备份脚本设置好之后，添加到crontab，可实现自动定时备份。
5、全新安装宝塔面板，下载备份文件，执行一键恢复脚本后，立即恢复网站业务访问，不需要手动创建网站等额外操作。


备份脚本（backup.sh）使用方法：

1、先安装XtraBackup（以CentOS 7为例）
wget http://file.kangle.cccyun.cn/file/percona-xtrabackup-24-2.4.24-1.el7.x86_64.rpm
yum -y install percona-xtrabackup-24-2.4.24-1.el7.x86_64.rpm

2、用编辑器打开备份脚本（千万不能用Windows记事本编辑！），修改里面的数据库密码、备份存储位置类型等相关信息。然后上传到服务器。
#给备份脚本执行权限
chmod 755 /root/backup.sh
#添加到crontab，设置每天2:00备份
crontab -e
0 2 * * * /root/backup.sh >/root/backup.log 2>&1

3、备份存储类型相关配置
如果选择备份到云存储，建议云存储和云服务器不在同一个账号下，否则假如账号被封，相当于没有备份。

（1）备份存储位置类型为远程linux服务器说明：
需要配置免密登录，分别在2台服务器执行以下命令
ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa

在当前需要备份数据的服务器执行以下命令
ssh-copy-id -i ~/.ssh/id_rsa.pub root@远程服务器IP

然后根据提示输入远程服务器的密码即可完成配置免密登录。

（2）备份存储位置类型为阿里云OSS说明：https://help.aliyun.com/document_detail/120075.html

（3）备份存储位置类型为腾讯云COS说明：https://cloud.tencent.com/document/product/436/63144

（4）备份存储位置类型为华为云OBS说明：https://support.huaweicloud.com/utiltg-obs/obs_11_0005.html

（5）备份存储位置类型为百度云BOS说明：https://cloud.baidu.com/doc/BOS/s/Ejwvyqe55


恢复脚本（restore.sh）使用方法：
注意：恢复之前必须先安装好宝塔面板，并且确保没有创建任何网站和数据库！如果已创建过需要先删除才能执行恢复脚本！

用编辑器打开备份脚本（千万不能用Windows记事本编辑！），修改里面的数据库密码，然后上传到备份文件所在目录（目录里面需包含wwwroot.tgz、mysql.tgz、config.tgz）
#给恢复脚本执行权限
chmod 755 ./restore.sh
#执行恢复
./restore.sh
