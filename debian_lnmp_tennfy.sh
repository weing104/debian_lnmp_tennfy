#!/bin/bash
#===============================================================================================
#   System Required:  Debian or Ubuntu (32bit/64bit)
#   Description:  Install lnmp for Debian or Ubuntu
#   Author: tennfy <admin@tennfy.com>
#   Intro:  http://www.tennfy.com
#===============================================================================================
clear
echo "#############################################################"
echo "# Install lnmp for Debian or Ubuntu (32bit/64bit)"
echo "# Intro: http://www.tennfy.com"
echo "#"
echo "# Author: tennfy <admin@tennfy.com>"
echo "#"
echo "#############################################################"
echo ""
function check_sanity {
	# Do some sanity checking.
	if [ $(/usr/bin/id -u) != "0" ]
	then
		die 'Must be run by root user'
	fi

	if [ ! -f /etc/debian_version ]
	then
		die "Distribution is not supported"
	fi
}

function die {
	echo "ERROR: $1" > /dev/null 1>&2
	exit 1
}
function remove_unneeded {
	if [ -f /usr/lib/sm.bin/smtpd ]
    then
        invoke-rc.d sendmail stop
    fi
	DEBIAN_FRONTEND=noninteractive apt-get -q -y remove --purge sendmail* apache2* samba* bind9* nscd
	invoke-rc.d saslauthd stop
	invoke-rc.d xinetd stop
	update-rc.d saslauthd disable
	update-rc.d xinetd disable
}
function install_dotdeb {
	# add dotdeb.
	dv=$(cut -d. -f1 /etc/debian_version)
	if [ "$dv" = "7" ]; then
	echo -e 'deb http://packages.dotdeb.org wheezy all' >> /etc/apt/sources.list
    echo -e 'deb-src http://packages.dotdeb.org wheezy all' >> /etc/apt/sources.list
	elif [ "$dv" = "6" ]; then
    echo -e 'deb http://packages.dotdeb.org squeeze all' >> /etc/apt/sources.list
    echo -e 'deb-src http://packages.dotdeb.org squeeze all' >> /etc/apt/sources.list
	fi

	#import GnuPG key
	wget http://www.dotdeb.org/dotdeb.gpg
	cat dotdeb.gpg | apt-key add -
	rm dotdeb.gpg
	apt-get update
}
function installmysql(){
	#install mysql
    apt-get install -y mysql-server mysql-client
	# Install a low-end copy of the my.cnf to disable InnoDB
	invoke-rc.d mysql stop
	cat > /etc/mysql/conf.d/lowendbox.cnf <<END
# These values override values from /etc/mysql/my.cnf
[mysqld]
key_buffer = 12M
query_cache_limit = 256K
query_cache_size = 4M
init_connect='SET collation_connection = utf8_unicode_ci'
init_connect='SET NAMES utf8' 
character-set-server = utf8 
collation-server = utf8_unicode_ci 
skip-character-set-client-handshake
default_tmp_storage_engine = MyISAM  #  -----  added for newer versions of mysql
default_storage_engine = MyISAM
skip-innodb
#log-slow-queries=/var/log/mysql/slow-queries.log  --- error in newer versions of mysql
[client]
default-character-set = utf8
END
	invoke-rc.d mysql start
}
function installphp(){
	#install PHP
	apt-get -y install php5-fpm php5-gd php5-common php5-curl php5-imagick php5-mcrypt php5-memcache php5-mysql php5-cgi php5-cli 
	#edit php
	invoke-rc.d php5-fpm stop
	
	sed -i  s/'listen = 127.0.0.1:9000'/'listen = \/var\/run\/php5-fpm.sock'/ /etc/php5/fpm/pool.d/www-data.conf
	sed -i  s/'^pm.max_children = [0-9]*'/'pm.max_children = 2'/ /etc/php5/fpm/pool.d/www-data.conf
	sed -i  s/'^pm.start_servers = [0-9]*'/'pm.start_servers = 1'/ /etc/php5/fpm/pool.d/www-data.conf
	sed -i  s/'^pm.min_spare_servers = [0-9]*'/'pm.min_spare_servers = 1'/ /etc/php5/fpm/pool.d/www-data.conf
	sed -i  s/'^pm.max_spare_servers = [0-9]*'/'pm.max_spare_servers = 2'/ /etc/php5/fpm/pool.d/www-data.conf
	sed -i  s/'memory_limit = 128M'/'memory_limit = 64M'/ /etc/php5/fpm/php.ini
	sed -i  s/'short_open_tag = Off'/'short_open_tag = On'/ /etc/php5/fpm/php.ini
	sed -i  s/'upload_max_filesize = 2M'/'upload_max_filesize = 8M'/ /etc/php5/fpm/php.ini
	
	invoke-rc.d php5-fpm start
}
function installnginx(){
#install nginx
apt-get -y install nginx-full
# edit nginx
invoke-rc.d nginx stop

if [ -f /etc/nginx/nginx.conf ]
	then
		# one worker for each CPU and max 1024 connections/worker
		cpu_count=`grep -c ^processor /proc/cpuinfo`
		sed -i \
			"s/worker_processes [0-9]*;/worker_processes $cpu_count;/" \
			/etc/nginx/nginx.conf
		sed -i \
			"s/worker_connections [0-9]*;/worker_connections 1024;/" \
			/etc/nginx/nginx.conf
 fi
cat > /etc/nginx/sites-available/default <<EOF
	server {
	listen [::]:80 default ipv6only=on; ## listen for ipv6
	listen 80;
	server_name localhost;
	root /var/www/; 
	index index.php index.html index.htm;
	location ~ \.php$ {
	fastcgi_split_path_info ^(.+\.php)(/.+)$;
	# With php5-fpm:
	fastcgi_pass unix:/var/run/php5-fpm.sock;
	fastcgi_index index.php;
	include fastcgi_params;
	}
	}
EOF
cat  >> /etc/nginx/fastcgi_params <<EOF
	fastcgi_connect_timeout 60;
	fastcgi_send_timeout 180;
	fastcgi_read_timeout 180;
	fastcgi_buffer_size 128k;
	fastcgi_buffers 4 256k;
	fastcgi_busy_buffers_size 256k;
	fastcgi_temp_file_write_size 256k;
	fastcgi_intercept_errors on;
EOF
#wordpress
cat  > /etc/nginx/wordpress.conf <<"EOF"
	if (-d $request_filename){
    rewrite ^/(.*)([^/])$ /$1$2/ permanent;
	}
	if (-f $request_filename/index.html){
    rewrite (.*) $1/index.html break;
	}
	if (-f $request_filename/index.php){
    rewrite (.*) $1/index.php;
	}
	if (!-f $request_filename){
    rewrite (.*) /index.php;
	}
EOF
#DZ
cat  > /etc/nginx/dz.conf <<"EOF"
	rewrite ^([^\.]*)/topic-(.+)\.html$ $1/portal.php?mod=topic&topic=$2 last;
	rewrite ^([^\.]*)/article-([0-9]+)-([0-9]+)\.html$ $1/portal.php?mod=view&aid=$2&page=$3 last;
	rewrite ^([^\.]*)/forum-(\w+)-([0-9]+)\.html$ $1/forum.php?mod=forumdisplay&fid=$2&page=$3 last;
	rewrite ^([^\.]*)/thread-([0-9]+)-([0-9]+)-([0-9]+)\.html$ $1/forum.php?mod=viewthread&tid=$2&extra=page%3D$4&page=$3 last;
	rewrite ^([^\.]*)/group-([0-9]+)-([0-9]+)\.html$ $1/forum.php?mod=group&fid=$2&page=$3 last;
	rewrite ^([^\.]*)/space-(username|uid)-(.+)\.html$ $1/home.php?mod=space&$2=$3 last;
	rewrite ^([^\.]*)/blog-([0-9]+)-([0-9]+)\.html$ $1/home.php?mod=space&uid=$2&do=blog&id=$3 last;
	rewrite ^([^\.]*)/(fid|tid)-([0-9]+)\.html$ $1/index.php?action=$2&value=$3 last;
	rewrite ^([^\.]*)/([a-z]+[a-z0-9_]*)-([a-z0-9_\-]+)\.html$ $1/plugin.php?id=$2:$3 last;
	if (!-e $request_filename) {
	return 404;
	}
EOF

invoke-rc.d nginx start
}
function init(){
	remove_unneeded
	install_dotdeb
	echo "-----------" &&
	echo "init successfully!" &&
	echo "-----------"
}
function installlnmp(){
if [ ! -d /var/www ];then
        mkdir /var/www
fi
#install zip unzip sendmail
apt-get install -y zip unzip sendmail-bin sendmail

installmysql
installphp
installnginx
#set web dir
cd /var/www
wget http://tennfyfile.qiniudn.com/phpMyAdmin.zip
unzip phpMyAdmin.zip

echo "-----------" &&
echo "restart lnmp!" &&
echo "-----------"
#restart lnmp
i1=`ps -ef|grep -E "/usr/sbin/apach"|grep -v grep|awk '{print $2}'`
kill -9 $i1
/etc/init.d/nginx restart
/etc/init.d/php5-fpm restart
/etc/init.d/mysql restart
echo "-----------" &&
echo "install successfully!" &&
echo "-----------"
}

function addvirtualhost(){
	echo "input hostname(like tennfy.com):"
	read hostname
	echo "input url rewrite rule name(wordpress  or dz):"
	read rewriterule
	rm /etc/nginx/conf.d/${hostname}.conf
	cat  >> /etc/nginx/conf.d/${hostname}.conf <<EOF
	server {
	listen 80;
	#ipv6
    #listen [::]:80 default_server;
    root /var/www/${hostname};
    index index.php index.html index.htm;
    server_name ${hostname} www.${hostname};
    location / {
		include ${rewriterule}.conf;
    }
	location ~ \.php$ {
		fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/var/run/php5-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
	}
	}
EOF
mkdir /var/www/${hostname}
cd /var/www/${hostname}
chmod -R 777 /var/www
chown -R www-data /var/www
cat  >> /var/www/${hostname}/info.php <<EOF
	<?php phpinfo(); ?>
EOF
/etc/init.d/nginx restart
echo "-----------" &&
echo "add successfully!" &&
echo "-----------"
}

function repaire502(){
    echo "input hostname(like tennfy.com):"
	read hostname
	sed -i "/listen = \/var\/run\/php5-fpm.sock/s/\/var\/run\/php5-fpm.sock/127.0.0.1:9000/g" /etc/php5/fpm/pool.d/www.conf
	sed -i "/unix:\/var\/run\/php5-fpm.sock/s/unix:\/var\/run\/php5-fpm.sock/127.0.0.1:9000/g" /etc/nginx/conf.d/${hostname}.conf
	/etc/init.d/nginx restart
	/etc/init.d/php5-fpm restart
	echo "-----------" &&
    echo "repaire successfully!" &&
    echo "-----------"
}

######################### Initialization ################################################
check_sanity
action=$1
[  -z $1 ] && action=install
case "$action" in
install)
    installlnmp
    ;;
addvhost)
    addvirtualhost
    ;;
repaire)
    repaire502
    ;;
init)
    init
    ;;	
*)
    echo "Arguments error! [${action} ]"
    echo "Usage: `basename $0` {init|install|addvhost|repaire}"
    ;;
esac
