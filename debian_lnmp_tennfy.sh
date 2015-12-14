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
function Timezone()
{
	rm -rf /etc/localtime
	ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

	echo '[ntp Installing] ******************************** >>'
	apt-get install -y ntpdate
	ntpdate -u pool.ntp.org
	StartDate=$(date)
	StartDateSecond=$(date +%s)
	echo "Start time: ${StartDate}"
}
function CloseSelinux()
{
	[ -s /etc/selinux/config ] && sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config;
}
function remove_unneeded {
	DEBIAN_FRONTEND=noninteractive apt-get -q -y remove --purge apache2* samba* bind9* nscd
	invoke-rc.d saslauthd stop
	invoke-rc.d xinetd stop
	update-rc.d saslauthd disable
	update-rc.d xinetd disable
	
	apt-get update
	for packages in build-essential gcc g++ cmake make ntp logrotate automake patch autoconf autoconf2.13 re2c wget flex cron libzip-dev libc6-dev rcconf bison cpp binutils unzip tar bzip2 libncurses5-dev libncurses5 libtool libevent-dev libpcre3 libpcre3-dev libpcrecpp0 libssl-dev zlibc openssl libsasl2-dev libxml2 libxml2-dev libltdl3-dev libltdl-dev zlib1g zlib1g-dev libbz2-1.0 libbz2-dev libglib2.0-0 libglib2.0-dev libpng3 libfreetype6 libfreetype6-dev libjpeg62 libjpeg62-dev libjpeg-dev libpng-dev libpng12-0 libpng12-dev curl libcurl3  libpq-dev libpq5 gettext libcurl4-gnutls-dev  libcurl4-openssl-dev libcap-dev ftp openssl expect zip unzip sendmail-bin sendmail
	do
			echo "[${packages} Installing] ************************************************** >>"
			apt-get install -y $packages --force-yes;apt-get -fy install;apt-get -y autoremove
	done
}
function install_dotdeb {
	# add dotdeb.
	#dv=$(cut -d. -f1 /etc/debian_version)
	#if [ "$dv" = "7" ]; then
	#echo -e 'deb http://packages.dotdeb.org wheezy all' >> /etc/apt/sources.list
    #echo -e 'deb-src http://packages.dotdeb.org wheezy all' >> /etc/apt/sources.list
	#elif [ "$dv" = "6" ]; then
    #echo -e 'deb http://packages.dotdeb.org squeeze all' >> /etc/apt/sources.list
    #echo -e 'deb-src http://packages.dotdeb.org squeeze all' >> /etc/apt/sources.list
	#fi
	echo -e 'deb http://packages.dotdeb.org stable all' >> /etc/apt/sources.list
    echo -e 'deb-src http://packages.dotdeb.org stable all' >> /etc/apt/sources.list
   
	#import GnuPG key
	wget http://www.dotdeb.org/dotdeb.gpg
	cat dotdeb.gpg | apt-key add -
	rm dotdeb.gpg
	apt-get update && apt-get upgrade
}
function installmysql(){
	#install mysql
    apt-get install -y mysql-client mysql-server
	# Install a low-end copy of the my.cnf to disable InnoDB
	/etc/init.d/mysql stop
	cat > /etc/mysql/conf.d/lowendbox.cnf <<END
	# These values override values from /etc/mysql/my.cnf
	[mysqld]
	key_buffer_size = 12M
	query_cache_limit = 256K
	query_cache_size = 4M
	init_connect='SET collation_connection = utf8_unicode_ci'
	init_connect='SET NAMES utf8' 
	character-set-server = utf8 
	collation-server = utf8_unicode_ci 
	skip-character-set-client-handshake
	default_storage_engine = MyISAM
	skip-innodb
	#log-slow-queries=/var/log/mysql/slow-queries.log  --- error in newer versions of mysql
	[client]
	default-character-set = utf8
END
	/etc/init.d/mysql start
}
function installphp(){
	#install PHP
	apt-get -y install php5-fpm php5-gd php5-common php5-curl php5-imagick php5-mcrypt php5-memcache php5-mysql php5-cgi php5-cli 
	#edit php
	/etc/init.d/php5-fpm stop
	
	sed -i  s/'listen = 127.0.0.1:9000'/'listen = \/var\/run\/php5-fpm.sock'/ /etc/php5/fpm/pool.d/www.conf
	sed -i  s/'^pm.max_children = [0-9]*'/'pm.max_children = 2'/ /etc/php5/fpm/pool.d/www.conf
	sed -i  s/'^pm.start_servers = [0-9]*'/'pm.start_servers = 1'/ /etc/php5/fpm/pool.d/www.conf
	sed -i  s/'^pm.min_spare_servers = [0-9]*'/'pm.min_spare_servers = 1'/ /etc/php5/fpm/pool.d/www.conf
	sed -i  s/'^pm.max_spare_servers = [0-9]*'/'pm.max_spare_servers = 2'/ /etc/php5/fpm/pool.d/www.conf
	sed -i  s/'memory_limit = 128M'/'memory_limit = 64M'/ /etc/php5/fpm/php.ini
	sed -i  s/'short_open_tag = Off'/'short_open_tag = On'/ /etc/php5/fpm/php.ini
	sed -i  s/'upload_max_filesize = 2M'/'upload_max_filesize = 8M'/ /etc/php5/fpm/php.ini
	
	/etc/init.d/php5-fpm start
}
function installnginx(){
	#install nginx
	wget http://nginx.org/download/nginx-1.8.0.tar.gz
	tar -zxvf nginx-1.8.0.tar.gz
	cd nginx-1.8.0
	./configure --user=www-data --group=www-data --sbin-path=/usr/sbin/nginx/nginx --prefix=/etc/nginx --conf-path=/etc/nginx/nginx.conf --pid-path=/usr/sbin/nginx/nginx.pid --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --with-http_ssl_module  --with-http_gzip_static_module --without-mail_pop3_module --without-mail_imap_module --without-mail_smtp_module --without-http_uwsgi_module --without-http_scgi_module 
	make
	make install
	
	# add conf.d dir
	if [ ! -d /etc/nginx/conf.d ];then
        mkdir /etc/nginx/conf.d
	fi
    
	#add nginx configuration file
	if [ -f /etc/nginx/nginx.conf ]
	then
	    
	    cd /etc/nginx
	    rm /etc/nginx/nginx.conf
		wget --no-check-certificate https://raw.githubusercontent.com/tennfy/debian_lnmp_tennfy/master/conf/nginx.conf 
		
		cd /etc/init.d
		wget --no-check-certificate https://raw.githubusercontent.com/tennfy/debian_lnmp_tennfy/master/conf/nginx 
		
		chmod +x /etc/nginx/nginx.conf
		chmod +x /etc/init.d/nginx
	fi
	
	#add wordpress rewrite rule
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
    #add Discuz rewrite rule
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

	/etc/init.d/nginx start
}
function init(){
	remove_unneeded
	install_dotdeb
	Timezone
	CloseSelinux
	echo "-----------" &&
	echo "init successfully!" &&
	echo "-----------"
}
function installlnmp(){
	if [ ! -d /var/www ];then
        mkdir /var/www
	fi

	installmysql
	installphp
	installnginx
	
	#set web dir
	cd /var/www
	wget --no-check-certificate https://raw.githubusercontent.com/tennfy/debian_lnmp_tennfy/master/phpMyAdmin.zip
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
	echo "input url rewrite rule name(wordpress or dz):"
	read rewriterule
	
	#stop nginx
	/etc/init.d/nginx stop
	
    #get nginx configure file template and edit
	cd /etc/nginx/conf.d	
	wget --no-check-certificate https://raw.githubusercontent.com/tennfy/debian_lnmp_tennfy/master/conf/host.conf
	sed -i 's/tennfy.com/${hostname}/g' host.conf
	sed -i 's/rewrite/${rewriterule}/g' host.conf
	mv host.conf ${hostname}.conf
	
	#new a virtualhost dir
	mkdir /var/www/${hostname}
	cd /var/www/${hostname}
	chmod -R 777 /var/www
	chown -R www-data /var/www
	
	cat  >> /var/www/${hostname}/info.php <<EOF
	<?php phpinfo(); ?>
EOF

	/etc/init.d/nginx start
	echo "-----------" &&
	echo "add successfully!" &&
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
init)
    init
    ;;	
*)
    echo "Arguments error! [${action} ]"
    echo "Usage: `basename $0` {init|install|addvhost|repaire}"
    ;;
esac
