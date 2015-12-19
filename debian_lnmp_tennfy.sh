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

#Variables
lnmpdir='/opt/lnmp'

#Version
MysqlVersion='mysql-5.5.34'
PhpVersion='php-5.6.16'
NginxVersion='nginx-1.8.0'


function check_sanity() {
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

function die() {
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
function InstallLibiconv()
{
	if [ ! -d /usr/sbin/libiconv ]; then
		cd ${lnmpdir}/packages/libiconv-1.14
		./configure --prefix=/usr//libiconv
		make && make install
		echo "[OK] ${LibiconvVersion} install completed.";
	else
		echo '[OK] libiconv is installed!';
	fi
}
function remove_unneeded() {
	DEBIAN_FRONTEND=noninteractive apt-get -q -y remove --purge apache2* samba* bind9* nscd
	invoke-rc.d saslauthd stop
	invoke-rc.d xinetd stop
	update-rc.d saslauthd disable
	update-rc.d xinetd disable
	
	apt-get update
	for packages in build-essential gcc g++ cmake make ntp logrotate automake patch autoconf autoconf2.13 re2c wget flex cron libzip-dev libc6-dev rcconf bison cpp binutils unzip tar bzip2 libncurses5-dev libncurses5 libtool libevent-dev libpcre3 libpcre3-dev libpcrecpp0 libssl-dev zlibc openssl libsasl2-dev libxml2 libxml2-dev libltdl3-dev libltdl-dev zlib1g zlib1g-dev libbz2-1.0 libbz2-dev libglib2.0-0 libglib2.0-dev libpng3 libfreetype6 libfreetype6-dev libjpeg62 libjpeg62-dev libjpeg-dev libpng-dev libpng12-0 libpng12-dev curl libcurl3  libpq-dev libpq5 gettext libcurl4-gnutls-dev  libcurl4-openssl-dev libcap-dev ftp openssl expect zip unzip sendmail-bin sendmail git
	do
			echo "[${packages} Installing] ************************************************** >>"
			apt-get install -y $packages --force-yes;apt-get -fy install;apt-get -y autoremove
	done
}
function install_dotdeb() {
	echo -e 'deb http://packages.dotdeb.org stable all' >> /etc/apt/sources.list
    echo -e 'deb-src http://packages.dotdeb.org stable all' >> /etc/apt/sources.list
   
	#import GnuPG key
	wget http://www.dotdeb.org/dotdeb.gpg
	cat dotdeb.gpg | apt-key add -
	rm dotdeb.gpg
	apt-get update
}
function downloadfiles(){
    #download libiconv
	wget http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.14.tar.gz
	tar -zxvf libiconv-1.14.tar.gz -C ${lnmpdir}/packages	
	#download nginx
	wget http://nginx.org/download/${NginxVersion}.tar.gz
	tar -zxvf ${NginxVersion}.tar.gz -C ${lnmpdir}/packages
	#download php
	wget http://php.net/distributions/${PhpVersion}.tar.gz
	tar -zxvf ${PhpVersion}.tar.gz -C ${lnmpdir}/packages
	#download phpmyadmin
	wget --no-check-certificate https://raw.githubusercontent.com/tennfy/debian_lnmp_tennfy/master/phpMyAdmin.tar.gz
	tar -zxvf phpMyAdmin.tar.gz -C ${lnmpdir}/packages
	#download configure files
	wget --no-check-certificate https://raw.githubusercontent.com/tennfy/debian_lnmp_tennfy/master/conf.tar.gz
	tar -zxvf conf.tar.gz -C ${lnmpdir}/conf
}
function installmysql(){
    echo "---------------------------------"
	echo "    begin to install mysql       "
    echo "---------------------------------"   
	#install mysql
    apt-get install -y mysql-client mysql-server
	# Install a low-end copy of the my.cnf to disable InnoDB
	/etc/init.d/mysql stop
	cp  ${lnmpdir}/conf/lowendbox.cnf /etc/mysql/conf.d
	/etc/init.d/mysql start
	echo "---------------------------------"
	echo "    mysql install finished       "
    echo "---------------------------------"
}
function installphp(){
    echo "---------------------------------"
	echo "    begin to install php         "
    echo "---------------------------------"    
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
	#restart php
	/etc/init.d/php5-fpm start
	echo "---------------------------------"
	echo "    php install finished         "
    echo "---------------------------------"
}
function installnginx(){
    echo "---------------------------------"
	echo "    begin to install nginx       "
    echo "---------------------------------"
	#install nginx
	if [ ! -f /usr/sbin/nginx ]
	then
		cd ${lnmpdir}/packages/${NginxVersion}
		./configure --user=www-data --group=www-data --sbin-path=/usr/sbin/nginx --prefix=/etc/nginx --conf-path=/etc/nginx/nginx.conf --pid-path=/var/run/nginx.pid --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --with-http_ssl_module  --with-http_gzip_static_module --without-mail_pop3_module --without-mail_imap_module --without-mail_smtp_module --without-http_uwsgi_module --without-http_scgi_module 
		make
		make install
		cd /root
	fi	
	# add conf.d dir
	if [ ! -d /etc/nginx/conf.d ]
	then
        mkdir /etc/nginx/conf.d
		if [ ! -d /var/www ]
	    then
			mkdir /var/www
		fi
	fi  
	#add nginx configuration file
	if [ -f /etc/nginx/nginx.conf ]
	then
	    rm /etc/nginx/nginx.conf	
        cp 	${lnmpdir}/conf/nginx.conf /etc/nginx
        cp 	${lnmpdir}/conf/nginx /etc/init.d
		chmod +x /etc/nginx/nginx.conf
		chmod +x /etc/init.d/nginx
	fi	
	#add nginx system variables
	sed -i 's/\/usr\/sbin/\/usr\/sbin:\/usr\/sbin\/nginx/g' /etc/profile
	source /etc/profile	
	#set nginx auto-start
	update-rc.d nginx defaults
	#add rewrite rule
	cp 	${lnmpdir}/conf/wordpress.conf /etc/nginx
	cp 	${lnmpdir}/conf/discuz.conf /etc/nginx

	/etc/init.d/nginx start
	echo "---------------------------------"
	echo "    nginx install finished       "
    echo "---------------------------------"
}
function init(){
    echo "---------------------------------"
	echo "    begin to init system         "
    echo "---------------------------------"
    # create packages and conf directory
	if [ ! -d ${lnmpdir} ]
	then 
	    mkdir ${lnmpdir}
		mkdir ${lnmpdir}/packages
		mkdir ${lnmpdir}/conf
	fi
	remove_unneeded
	install_dotdeb
	Timezone
	CloseSelinux
	downloadfiles
	echo "---------------------------------" &&
	echo "     init successfully!          " &&
	echo "---------------------------------"
}
function installlnmp(){
    #init system
	init
	#install mysql, php, nginx
	installmysql
	installphp
	installnginx	
	#set web dir
	cp 	${lnmpdir}/packages/phpMyAdmin /var/www 
	#restart lnmp
	echo "---------------------------------" &&
	echo "         restart lnmp!           " &&
	echo "---------------------------------"	
	/etc/init.d/nginx restart
	/etc/init.d/php5-fpm restart
	/etc/init.d/mysql restart
	echo "---------------------------------" &&
	echo "      install successfully!      " &&
	echo "---------------------------------"
}

function addvirtualhost(){
    echo "---------------------------------"
	echo "    begin to add vhost           "
    echo "---------------------------------"
	echo "please input hostname(like tennfy.com):"
	read hostname
	echo "please input url rewrite rule name(wordpress or discuz):"
	read rewriterule	
	#stop nginx
	/etc/init.d/nginx stop	
    #get nginx configure file template and edit
    cp  ${lnmpdir}/conf/host.conf /etc/nginx/conf.d
	mv /etc/nginx/conf.d/host.conf /etc/nginx/conf.d/${hostname}.conf
	sed -i 's/tennfy.com/'${hostname}'/g' /etc/nginx/conf.d/${hostname}.conf
	sed -i 's/rewrite/'${rewriterule}'/g' /etc/nginx/conf.d/${hostname}.conf	
	#new a virtualhost dir
	mkdir /var/www/${hostname}
	cd /var/www/${hostname}
	chmod -R 777 /var/www
	chown -R www-data:www-data /var/www
	#add phpinfo file
	cat  >> /var/www/${hostname}/info.php <<EOF
	<?php phpinfo(); ?>
EOF

	/etc/init.d/nginx start
	echo "-------------------------------" &&
	echo "   add vhost successfully!     " &&
	echo "-------------------------------"
}

######################### Initialization ################################################
check_sanity
action=$1
[ -z $1 ] && action=install
case "$action" in
install)
    installlnmp
    ;;
addvhost)
    addvirtualhost
    ;;
*)
    echo "Arguments error! [${action} ]"
    echo "Usage: `basename $0` {init|install|addvhost|repaire}"
    ;;
esac
