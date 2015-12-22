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
MysqlPass=''
SysName=''
SysBit=''
Cpunum=''
RamTotal=''
RamSwap=''
RamSum=''
StartDate=''
StartDateSecond=''

#Version
MysqlVersion='mysql-5.5.47'
PhpVersion='php-5.4.45'
NginxVersion='nginx-1.8.0'


function CheckSystem()
{
	[ $(id -u) != '0' ] && echo '[Error] Please use root to install lnmp' && exit
	egrep -i "centos" /etc/issue && SysName='centos'
	egrep -i "debian" /etc/issue && SysName='debian'
	egrep -i "ubuntu" /etc/issue && SysName='ubuntu'
	[ "$SysName" != 'debian'  ] && echo '[Error] Your system is not supported' && exit

	SysBit='32' && [ `getconf WORD_BIT` == '32' ] && [ `getconf LONG_BIT` == '64' ] && SysBit='64'
	Cpunum=`cat /proc/cpuinfo | grep 'processor' | wc -l`
	RamTotal=`free -m | grep 'Mem' | awk '{print $2}'`
	RamSwap=`free -m | grep 'Swap' | awk '{print $2}'`
	RamSum=$[$RamTotal+$RamSwap]
	echo '================================================================'
	echo "${SysBit}Bit, ${Cpunum}*CPU, ${RamTotal}MB*RAM, ${RamSwap}MB*Swap"
	echo '================================================================'	
	if [ "$RamSum" -lt '512' ]
	then
	    echo 'Script will install mysql and php by apt-get'
	else
	    echo 'Script will install mysql and php by compile'
	    #input mysql password
		InputMysqlPass
	fi
}
function InputMysqlPass()
{
	echo "Please input MySQL password:"
	read  MysqlPass
	if [ "$MysqlPass" == '' ]
	then
		echo '[Error] MySQL password is empty.'
		InputMysqlPass
	else
		echo '[OK] Your MySQL password is:'
		echo $MysqlPass
	fi
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
	[ -s /etc/selinux/config ] && sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
}
function InstallLibiconv()
{
	if [ ! -d /usr/local/libiconv ]
	then
		cd ${lnmpdir}/packages/libiconv-1.14
		./configure --prefix=/usr/local/libiconv
		make
		make install
		cd /root
	fi
}
function Installcurl()
{
	if [ ! -d /usr/local/curl ]
	then
		cd ${lnmpdir}/packages/curl-7.46.0
		./configure --prefix=/usr/local/curl
		make
		make install
		cd /root
	fi
}
function Installlibmcrypt()
{
	if [ ! -d /usr/local/libmcrypt ]
	then
		cd ${lnmpdir}/packages/libmcrypt-2.5.8
		./configure --prefix=/usr/local/libmcrypt
		make
		make install
		cd /root
	fi
}
function Installmhash()
{
	if [ ! -d /usr/local/mhash ]
	then
		cd ${lnmpdir}/packages/mhash-0.9.9.9
		./configure --prefix=/usr/local/mhash
		make
		make install
		cd /root
	fi
}
function Installmcrypt()
{
	if [ ! -d /usr/local/mcrypt ]
	then
		cd ${lnmpdir}/packages/mcrypt-2.6.8
		#ln -s /usr/local/libmcrypt/bin/libmcrypt-config   /usr/bin/libmcrypt-config  #添加软连接
        export LD_LIBRARY_PATH=/usr/local/mhash/lib:$LD_LIBRARY_PATH
		export LDFLAGS="-L/usr/local/mhash/lib/ -I/usr/local/mhash/include/"
		export CFLAGS="-I/usr/local/mhash/include/"
		./configure --prefix=/usr/local/mcrypt --with-libmcrypt-prefix=/usr/local/libmcrypt
		make
		make install
		cd /root
	fi
}
function remove_unneeded() 
{
	DEBIAN_FRONTEND=noninteractive apt-get -q -y remove --purge apache2* samba* bind9* nscd
	invoke-rc.d saslauthd stop
	invoke-rc.d xinetd stop
	update-rc.d saslauthd disable
	update-rc.d xinetd disable
	
	apt-get update
	for packages in build-essential gcc g++ cmake make ntp logrotate automake patch autoconf autoconf2.13 re2c wget flex cron libzip-dev libc6-dev rcconf bison cpp binutils tar bzip2 libncurses5-dev libncurses5 libtool libevent-dev libpcre3 libpcre3-dev libpcrecpp0 libssl-dev zlibc openssl libsasl2-dev libxml2 libxml2-dev libltdl3-dev libltdl-dev zlib1g zlib1g-dev libbz2-1.0 libbz2-dev libglib2.0-0 libglib2.0-dev libpng3 libfreetype6 libfreetype6-dev libjpeg62 libjpeg62-dev libjpeg-dev libpng-dev libpng12-0 libpng12-dev libpq-dev libpq5 gettext libcap-dev ftp expect zip unzip git vim
	do
			echo "[${packages} Installing] ************************************************** >>"
			apt-get install -y $packages --force-yes;apt-get -fy install;apt-get -y autoremove
	done
}
function install_dotdeb() 
{
    if [ "$RamSum" -lt '512' ]
	then
		echo -e 'deb http://packages.dotdeb.org stable all' >> /etc/apt/sources.list
		echo -e 'deb-src http://packages.dotdeb.org stable all' >> /etc/apt/sources.list
   
		#import GnuPG key
		wget http://www.dotdeb.org/dotdeb.gpg
		cat dotdeb.gpg | apt-key add -
		rm dotdeb.gpg
		apt-get update
	fi
}
function downloadfiles()
{
    #download libiconv
	wget http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.14.tar.gz
	tar -zxvf libiconv-1.14.tar.gz -C ${lnmpdir}/packages	
	#download Libmcrypt
	wget http://downloads.sourceforge.net/project/mcrypt/Libmcrypt/2.5.8/libmcrypt-2.5.8.tar.gz
	tar -zxvf libmcrypt-2.5.8.tar.gz -C ${lnmpdir}/packages
	#download mhash
	wget http://downloads.sourceforge.net/project/mhash/mhash/0.9.9.9/mhash-0.9.9.9.tar.gz
	tar -zxvf mhash-0.9.9.9.tar.gz -C ${lnmpdir}/packages
	#download mcrypt
	wget http://downloads.sourceforge.net/project/mcrypt/MCrypt/2.6.8/mcrypt-2.6.8.tar.gz
	tar -zxvf mcrypt-2.6.8.tar.gz -C ${lnmpdir}/packages
	#download curl
	wget http://curl.haxx.se/download/curl-7.46.0.tar.gz
	tar -zxvf curl-7.46.0.tar.gz -C ${lnmpdir}/packages
	#download nginx
	wget http://nginx.org/download/${NginxVersion}.tar.gz
	tar -zxvf ${NginxVersion}.tar.gz -C ${lnmpdir}/packages
	#download mysql
	wget http://cdn.mysql.com//Downloads/MySQL-5.5/${MysqlVersion}.tar.gz
	tar -zxvf ${MysqlVersion}.tar.gz -C ${lnmpdir}/packages
	#download php
	wget http://php.net/distributions/${PhpVersion}.tar.gz
	tar -zxvf ${PhpVersion}.tar.gz -C ${lnmpdir}/packages
	#download phpmyadmin
	wget --no-check-certificate https://raw.githubusercontent.com/tennfy/debian_lnmp_tennfy/master/phpMyAdmin.tar.gz
	tar -zxvf phpMyAdmin.tar.gz -C ${lnmpdir}/packages
	#download configure files
	wget --no-check-certificate https://raw.githubusercontent.com/tennfy/debian_lnmp_tennfy/master/conf.tar.gz
	tar -zxvf conf.tar.gz -C ${lnmpdir}/conf
	#download nginx module
	git clone https://github.com/cuber/ngx_http_google_filter_module
    git clone https://github.com/yaoweibin/ngx_http_substitutions_filter_module
	cp -r ngx_http_google_filter_module ${lnmpdir}/packages/${NginxVersion}
	cp -r ngx_http_substitutions_filter_module ${lnmpdir}/packages/${NginxVersion}
	
	#delete all tar.gz packages
	rm *.tar.gz
	rm -r ngx_http_google_filter_module
	rm -r ngx_http_substitutions_filter_module
}
function installmysql()
{
    echo "---------------------------------"
	echo "    begin to install mysql       "
    echo "---------------------------------" 
	if [ "$RamSum" -lt '512' ]
	then
	    #install mysql
		apt-get install -y mysql-client mysql-server
		# Install a low-end copy of the my.cnf to disable InnoDB
		/etc/init.d/mysql stop
		if [ -f ${lnmpdir}/conf/my.cnf ]
		then
			rm  ${lnmpdir}/conf/my.cnf
			cp  ${lnmpdir}/conf/my.cnf /etc/mysql/my.cnf
		else
			cp  ${lnmpdir}/conf/my.cnf /etc/mysql/my.cnf
		fi
	else
		if [ ! -f /usr/local/mysql/bin/mysql ]
		then
			mkdir /var/lib/mysql /var/run/mysqld /etc/mysql /etc/mysql/conf.d
			cd ${lnmpdir}/packages/${MysqlVersion}
			groupadd mysql
			useradd -s /sbin/nologin -g mysql mysql
			cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mysql -DMYSQL_DATADIR=/var/lib/mysql -DMYSQL_TCP_PORT=3306 -DMYSQL_UNIX_ADDR=/var/run/mysqld/mysqld.sock -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci -DWITH_EXTRA_CHARSETS=complex -DWITH_READLINE=1 -DENABLED_LOCAL_INFILE=1 
			make
			make install
			
			chmod +w /usr/local/mysql
			chown -R mysql:mysql /usr/local/mysql
			chown -R mysql /var/run/mysqld
			#add configuration file
			rm -f /etc/mysql/my.cnf /usr/local/mysql/etc/my.cnf
			cp ${lnmpdir}/conf/my.cnf /etc/mysql/my.cnf
			/usr/local/mysql/scripts/mysql_install_db --user=mysql --defaults-file=/etc/mysql/my.cnf --basedir=/usr/local/mysql --datadir=/var/lib/mysql
# EOF **********************************
cat > /etc/ld.so.conf.d/mysql.conf<<EOF
/usr/local/mysql/lib/mysql
/usr/local/lib
EOF
# **************************************
			ldconfig
			if [ "$SysBit" == '64' ] 
			then
				ln -s /usr/local/mysql/lib/mysql /usr/lib64/mysql
			else
				ln -s /usr/local/mysql/lib/mysql /usr/lib/mysql
			fi
			chmod 775 /usr/local/mysql/support-files/mysql.server
            ln -s /usr/local/mysql/support-files/mysql.server /etc/init.d/mysql
			chmod +x /etc/init.d/mysql
			/etc/init.d/mysql start
			ln -s /usr/local/mysql/bin/mysql /usr/bin/mysql
			ln -s /usr/local/mysql/bin/mysqladmin /usr/bin/mysqladmin
			ln -s /usr/local/mysql/bin/mysqldump /usr/bin/mysqldump
			ln -s /usr/local/mysql/bin/myisamchk /usr/bin/myisamchk
			ln -s /usr/local/mysql/bin/mysqld_safe /usr/bin/mysqld_safe
			
			/usr/local/mysql/bin/mysqladmin password $MysqlPass
			rm -rf /var/lib/mysql/test

# EOF **********************************
mysql -hlocalhost -uroot -p$MysqlPass <<EOF
USE mysql;
DELETE FROM user WHERE User!='root' OR (User = 'root' AND Host != 'localhost');
UPDATE user set password=password('$MysqlPass') WHERE User='root';
DROP USER ''@'%';
FLUSH PRIVILEGES;
EOF
# **************************************
           /etc/init.d/mysql stop
		   update-rc.d mysql defaults
           cd /root		   
	    fi		
	fi
    /etc/init.d/mysql start
	echo "---------------------------------"
	echo "    mysql install finished       "
	echo "---------------------------------"
}
function installphp(){
    echo "---------------------------------"
	echo "    begin to install php         "
    echo "---------------------------------"  
    if [ "$RamSum" -lt '512' ]
	then	
		apt-get -y install php5-fpm php5-gd php5-common php5-curl php5-imagick php5-mcrypt php5-memcache php5-mysql php5-cgi php5-cli 
		/etc/init.d/php5-fpm stop
		
	    rm /etc/php5/fpm/php.ini
		rm /etc/php5/fpm/php-fpm.conf
		cp 	${lnmpdir}/conf/php.ini /etc/php5/fpm/php.ini
		cp 	${lnmpdir}/conf/php-fpm.conf /etc/php5/fpm/php-fpm.conf		
	else
	    #install curl
		Installcurl
		#install mcrypt
		Installlibmcrypt
		Installmhash
		Installmcrypt
	    #install Libiconv
		InstallLibiconv
		#install PHP
		if [ ! -d /usr/local/php ]
		then
			mkdir /etc/php5
			cd ${lnmpdir}/packages/${PhpVersion}
			groupadd www-data
			useradd -m -s /sbin/nologin -g www-data www-data
			./configure --prefix=/usr/local/php --enable-fpm --with-fpm-user=www-data --with-fpm-group=www-data --with-config-file-path=/etc/php5 --with-config-file-scan-dir=/etc/php5 --with-openssl --with-zlib  --with-curl=/usr/local/curl --enable-ftp --with-gd --with-jpeg-dir --with-png-dir --with-freetype-dir --enable-gd-native-ttf --enable-mbstring --enable-zip --with-iconv=/usr/local/libiconv --with-mysql=/usr/local/mysql --with-mysqli=/usr/local/mysql --without-pear --disable-fileinfo --with-mcrypt=/usr/local/mcrypt
			make
			make install
			
			#cp configuration file
			cp 	${lnmpdir}/conf/php.ini /etc/php5/php.ini
			cp 	${lnmpdir}/conf/php-fpm.conf /etc/php5/php-fpm.conf
			cp 	${lnmpdir}/conf/php5-fpm /etc/init.d/php5-fpm
			chmod +x /etc/init.d/php5-fpm
        
			ln -s /usr/local/php/bin/php /usr/bin/php
			ln -s /usr/local/php/bin/phpize /usr/bin/phpize
			ln -s /usr/local/php/sbin/php-fpm /usr/sbin/php5-fpm
			#php auto-start		
			update-rc.d php5-fpm defaults
			cd /root
		fi
	fi
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
		./configure --user=www-data --group=www-data --sbin-path=/usr/sbin/nginx --prefix=/etc/nginx --conf-path=/etc/nginx/nginx.conf --pid-path=/var/run/nginx.pid --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --with-http_ssl_module  --with-http_gzip_static_module --without-mail_pop3_module --without-mail_imap_module --without-mail_smtp_module --without-http_uwsgi_module --without-http_scgi_module  --add-module=ngx_http_google_filter_module --add-module=ngx_http_substitutions_filter_module
		make
		make install
		cd /root
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
        cp 	${lnmpdir}/conf/nginx.conf /etc/nginx/nginx.conf
        cp 	${lnmpdir}/conf/nginx /etc/init.d/nginx
		chmod +x /etc/nginx/nginx.conf
		chmod +x /etc/init.d/nginx
	fi	
	#add nginx system variables
	sed -i 's/\/usr\/sbin/\/usr\/sbin:\/usr\/sbin\/nginx/g' /etc/profile
	source /etc/profile	
	#set nginx auto-start
	update-rc.d nginx defaults
	#add rewrite rule
	cp 	${lnmpdir}/conf/wordpress.conf /etc/nginx/wordpress.conf
	cp 	${lnmpdir}/conf/discuz.conf /etc/nginx/discuz.conf

	/etc/init.d/nginx start
		
	echo "---------------------------------"
	echo "    nginx install finished       "
    echo "---------------------------------"
	fi
}
function init(){
    echo "---------------------------------"
	echo "    begin to init system         "
    echo "---------------------------------"
	cd /root
    # create packages and conf directory
	if [ ! -d ${lnmpdir} ]
	then 
	    mkdir ${lnmpdir}
		mkdir ${lnmpdir}/packages
		mkdir ${lnmpdir}/conf
	fi
	CheckSystem
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
	cp -r ${lnmpdir}/packages/phpMyAdmin /var/www 
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
	echo "Start time: ${StartDate}";
	echo "Completion time: $(date) (Use: $[($(date +%s)-StartDateSecond)/60] minute)";
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
function addsslvirtualhost(){
    echo "---------------------------------"
	echo "    begin to add ssl vhost       "
    echo "---------------------------------"
	echo "please input hostname(like tennfy.com):"
	read hostname
	echo "please input url rewrite rule name(wordpress or discuz):"
	read rewriterule	
	echo "please input ssl certificate file path:"
	read certificate
	echo "please input ssl privatekey file path:"
	read privatekey	
	#stop nginx
	/etc/init.d/nginx stop	
    #get nginx configure file template and edit
    cp  ${lnmpdir}/conf/sslhost.conf /etc/nginx/conf.d
	mv /etc/nginx/conf.d/sslhost.conf /etc/nginx/conf.d/${hostname}.conf
	sed -i 's/tennfy.com/'${hostname}'/g' /etc/nginx/conf.d/${hostname}.conf
	sed -i 's/rewrite/'${rewriterule}'/g' /etc/nginx/conf.d/${hostname}.conf	
	sed -i 's#tennfy_certificate#'${certificate}'#g' /etc/nginx/conf.d/${hostname}.conf	
	sed -i 's#tennfy_privatekey#'${privatekey}'#g' /etc/nginx/conf.d/${hostname}.conf	
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
	echo "   add ssl vhost successfully! " &&
	echo "-------------------------------"
}
function addgoogle(){
	echo "---------------------------------"
	echo "    begin to add google          "
    echo "---------------------------------"
	echo "please input hostname(like tennfy.com):"
	read hostname
	echo "please input ssl certificate file path:"
	read certificate
	echo "please input ssl privatekey file path:"
	read privatekey	
	#stop nginx
	/etc/init.d/nginx stop	
    #get nginx configure file template and edit
    cp  ${lnmpdir}/conf/google.conf /etc/nginx/conf.d
	mv /etc/nginx/conf.d/google.conf /etc/nginx/conf.d/${hostname}.conf
	sed -i 's/tennfy.com/'${hostname}'/g' /etc/nginx/conf.d/${hostname}.conf
	sed -i 's#tennfy_certificate#'${certificate}'#g' /etc/nginx/conf.d/${hostname}.conf	
	sed -i 's#tennfy_privatekey#'${privatekey}'#g' /etc/nginx/conf.d/${hostname}.conf	
	/etc/init.d/nginx start
	echo "-------------------------------" &&
	echo "   add google successfully!    " &&
	echo "-------------------------------"
}

######################### Initialization ################################################
action=$1
[ -z $1 ] && action=install
case "$action" in
install)
    installlnmp
    ;;
addvhost)
    addvirtualhost
    ;;
addsslvhost)
    addsslvirtualhost
    ;;
addgoogle)
    addgoogle
    ;;
*)
    echo "Arguments error! [${action} ]"
    echo "Usage: `basename $0` {init|install|addvhost|repaire}"
    ;;
esac
