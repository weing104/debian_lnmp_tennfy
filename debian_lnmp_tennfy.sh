#!/bin/bash
#===============================================================================================
#   System Required:  Debian or Ubuntu (32bit/64bit)
#   Description:  Install lnmp for Debian or Ubuntu
#   Author: tennfy <admin@tennfy.com>
#   Intro:  http://www.tennfy.com
#===============================================================================================
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
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
Ramthreshold='512'
ZendOpcache=''
Memcached=''
php_version=''
MysqlPass=''
SysName=''
SysBit=''
Cpunum=''
RamTotal=''
RamSwap=''
RamSum=''
StartDate=''
StartDateSecond=''
#color
CEND="\033[0m"
CMSG="\033[1;36m"
CFAILURE="\033[1;31m"
CSUCCESS="\033[32m"
CWARNING="\033[1;33m"

#Version
MariadbVersion='mysql-5.5.51'
PhpVersion='php-7.0.11'
NginxVersion='nginx-1.10.1'


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
	echo '-----------------------------------------------------------------'
	echo "${SysBit}Bit, ${Cpunum}*CPU, ${RamTotal}MB*RAM, ${RamSwap}MB*Swap"	
	if [ "$RamSum" -lt "$Ramthreshold" ]
	then
	    echo 'Script will install mysql and php by apt-get'
		echo '-------------------------------------------------------------'
	else
	    echo 'Script will install mysql and php by compile'
		echo '-------------------------------------------------------------'
	fi	
	#input mysql password
	InputMysqlPass		
	
}
function InputMysqlPass()
{
    echo
	read -p 'Please input MySQL password:' MysqlPass
	if [ "$MysqlPass" == '' ]
	then
		echo -e "${CFAILURE}[Error] MySQL password is empty.${CEND}"
		InputMysqlPass
	else
		echo -e "${CMSG}[OK] Your MySQL password is:$MysqlPass${CEND}"
	fi
}
function Timezone()
{
	rm -rf /etc/localtime
	ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

	echo '[ntp Installing] **************************************************** >>'
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
		#download libiconv
		wget http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.14.tar.gz
		tar -zxvf libiconv-1.14.tar.gz -C ${lnmpdir}/packages	
		cd ${lnmpdir}/packages/libiconv-1.14
		./configure --prefix=/usr/local/libiconv
		make
		make install
		cd /root
		rm -f libiconv-1.14.tar.gz
	fi
}
function Installcurl()
{
	if [ ! -d /usr/local/curl ]
	then
		#download curl
		wget http://curl.haxx.se/download/curl-7.46.0.tar.gz
		tar -zxvf curl-7.46.0.tar.gz -C ${lnmpdir}/packages	
		cd ${lnmpdir}/packages/curl-7.46.0
		./configure --prefix=/usr/local/curl
		make
		make install
		cd /root
		rm -f curl-7.46.0.tar.gz
	fi
}
function Installlibmcrypt()
{
	if [ ! -d /usr/local/libmcrypt ]
	then
		#download Libmcrypt
		wget http://downloads.sourceforge.net/project/mcrypt/Libmcrypt/2.5.8/libmcrypt-2.5.8.tar.gz
		tar -zxvf libmcrypt-2.5.8.tar.gz -C ${lnmpdir}/packages
		cd ${lnmpdir}/packages/libmcrypt-2.5.8
		./configure --prefix=/usr/local/libmcrypt
		make
		make install
		cd /root
		rm -f libmcrypt-2.5.8.tar.gz
	fi
}
function Installmhash()
{
	if [ ! -d /usr/local/mhash ]
	then
		#download mhash
		wget http://downloads.sourceforge.net/project/mhash/mhash/0.9.9.9/mhash-0.9.9.9.tar.gz
		tar -zxvf mhash-0.9.9.9.tar.gz -C ${lnmpdir}/packages
		cd ${lnmpdir}/packages/mhash-0.9.9.9
		./configure --prefix=/usr/local/mhash
		make
		make install
		cd /root
		rm -f mhash-0.9.9.9.tar.gz
	fi
}
function Installmcrypt()
{
	if [ ! -d /usr/local/mcrypt ]
	then	
		#download mcrypt
		wget http://downloads.sourceforge.net/project/mcrypt/MCrypt/2.6.8/mcrypt-2.6.8.tar.gz
		tar -zxvf mcrypt-2.6.8.tar.gz -C ${lnmpdir}/packages
		cd ${lnmpdir}/packages/mcrypt-2.6.8
		ln -s /usr/local/libmcrypt/bin/libmcrypt-config   /usr/bin/libmcrypt-config  #添加软连接
        export LD_LIBRARY_PATH=/usr/local/mhash/lib:/usr/local/libmcrypt/lib
		export LDFLAGS="-L/usr/local/mhash/lib/ -I/usr/local/mhash/include/"
		export CFLAGS="-I/usr/local/mhash/include/"
		./configure --prefix=/usr/local/mcrypt
		make
		make install
		cd /root
		rm -f mcrypt-2.6.8.tar.gz
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
    if [ "$RamSum" -lt "$Ramthreshold" ]
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
	#download nginx
	wget http://nginx.org/download/${NginxVersion}.tar.gz
	tar -zxvf ${NginxVersion}.tar.gz -C ${lnmpdir}/packages
	#download phpmyadmin
	wget https://files.phpmyadmin.net/phpMyAdmin/4.6.4/phpMyAdmin-4.6.4-all-languages.tar.gz
	tar -zxvf phpMyAdmin-4.6.4-all-languages.tar.gz -C ${lnmpdir}/packages
	#download configure files
	wget --no-check-certificate https://raw.githubusercontent.com/tennfy/debian_lnmp_tennfy/master/conf.tar.gz
	tar -zxvf conf.tar.gz -C ${lnmpdir}/conf
	#download nginx module
        git clone https://github.com/yaoweibin/ngx_http_substitutions_filter_module
	cp -r ngx_http_substitutions_filter_module ${lnmpdir}/packages/${NginxVersion}
	
	#delete all tar.gz packages
	rm *.tar.gz
	rm -r ngx_http_substitutions_filter_module
}
function installmysql()
{
    echo "----------------------------------------------------------------"
	echo "                     begin to install mysql                     "
    echo "----------------------------------------------------------------" 
	if [ "$RamSum" -lt "$Ramthreshold" ]
	then
	    #install mysql
		debconf-set-selections <<< "mysql-server mysql-server/root_password password $MysqlPass"
		debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $MysqlPass"
		apt-get install -y mysql-client mysql-server
		# Install a low-end copy of the my.cnf to disable InnoDB
		/etc/init.d/mysql stop
		cp  ${lnmpdir}/conf/lowend.cnf /etc/mysql/conf.d/lowend.cnf 
	else
		if [ ! -d /usr/local/mysql ]
		then
			mkdir /var/lib/mysql /var/run/mysqld /etc/mysql /etc/mysql/conf.d
			#download mysql
			wget http://cdn.mysql.com//Downloads/MySQL-5.5/${MysqlVersion}.tar.gz
			tar -zxvf ${MysqlVersion}.tar.gz -C ${lnmpdir}/packages
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
		   rm -f ${MysqlVersion}.tar.gz		   
	    fi		
	fi
    /etc/init.d/mysql start
	echo "--------------------------------------------------------------"
	echo "                      mysql install finished                  "
	echo "--------------------------------------------------------------"
}
function installphp(){
    echo "--------------------------------------------------------------"
	echo "                      begin to install php                    "
    echo "--------------------------------------------------------------"  
    
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
			mkdir /etc/php7
			#download php
			wget http://php.net/distributions/${PhpVersion}.tar.gz
			tar -zxvf ${PhpVersion}.tar.gz -C ${lnmpdir}/packages
			cd ${lnmpdir}/packages/${PhpVersion}
			groupadd www-data
			useradd -m -s /sbin/nologin -g www-data www-data
			./configure --prefix=/usr/local/php7 --enable-fpm --with-fpm-user=www-data --with-fpm-group=www-data --with-config-file-path=/etc/php7 --with-openssl --with-zlib  --with-curl=/usr/local/curl --enable-sockets --with-xmlrpc --enable-ftp --with-gd --with-jpeg-dir --with-png-dir --with-freetype-dir --enable-gd-native-ttf --enable-mbstring --enable-zip --with-iconv=/usr/local/libiconv --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --without-pear --disable-fileinfo --with-mcrypt=/usr/local/libmcrypt
			make
			make install
			
			#cp configuration file
			cp 	php.ini-production /etc/php7/php.ini
			sed -i "s#extension_dir = \"ext\"#extension_dir = \"`/usr/local/php/bin/php-config --extension-dir`\"#g" /etc/php7/php.ini
			cp 	/etc/php7/php-fpm.conf.default /etc/php7/php-fpm.conf
			cp 	sapi/fpm/init.d.php-fpm /etc/init.d/php7-fpm
			chmod +x /etc/init.d/php7-fpm
        
			ln -s /usr/local/php/bin/php /usr/bin/php
			ln -s /usr/local/php/bin/phpize /usr/bin/phpize
			ln -s /usr/local/php/sbin/php-fpm /usr/sbin/php7-fpm
			#php auto-start		
			update-rc.d php7-fpm defaults
			cd /root
			rm -f ${PhpVersion}.tar.gz
		fi
		
	/etc/init.d/php7-fpm start	
	echo "---------------------------------------------------------------"
	echo "                    php install finished                       "
    echo "---------------------------------------------------------------"	
}
function installnginx(){
    echo "---------------------------------------------------------------"
	echo "                      begin to install nginx                   "
    echo "---------------------------------------------------------------"
	#install nginx
	if [ ! -f /usr/sbin/nginx ]
	then
		cd ${lnmpdir}/packages/${NginxVersion}
		./configure --user=www-data --group=www-data --sbin-path=/usr/sbin/nginx --prefix=/usr/local/nginx --conf-path=/etc/nginx/nginx.conf --pid-path=/var/run/nginx.pid --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --with-http_ssl_module  --with-http_gzip_static_module --without-mail_pop3_module --without-mail_imap_module --without-mail_smtp_module --without-http_uwsgi_module --without-http_scgi_module --add-module=ngx_http_substitutions_filter_module
		make
		make install
		cd /root
	# add conf.d dir
	if [ ! -d /etc/nginx/conf.d ]
	then
        mkdir /etc/nginx/conf.d
		if [ ! -d /home/wwwroot ]
	    then
			mkdir /home/wwwroot
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
	#set nginx auto-start
	ln -s /usr/sbin/nginx /usr/bin/nginx
	update-rc.d nginx defaults
	#add rewrite rule
	cp 	${lnmpdir}/conf/wordpress.conf /etc/nginx/wordpress.conf
	cp 	${lnmpdir}/conf/discuz.conf /etc/nginx/discuz.conf

	/etc/init.d/nginx start
		
	echo "---------------------------------------------------------------"
	echo "                   nginx install finished                      "
    echo "---------------------------------------------------------------"
	fi
}
function virtualhost(){
    echo "---------------------------------------------------------------"
	echo "           begin to install virtual host                       "
    echo "---------------------------------------------------------------"
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
	sed -i 's/rewriterule/'${rewriterule}'/g' /etc/nginx/conf.d/${hostname}.conf	
	#make a virtualhost dir
	mkdir /home/wwwroot/${hostname}
	cd /home/wwwroot/${hostname}
	chmod -R 777 /home/wwwroot
	chown -R www-data:www-data /home/wwwroot


	/etc/init.d/nginx start
	echo -e "-----------------------------------------------------------" &&
	echo -e "   ${CSUCCESS}install virtual host successfully!${CEND}    " &&
	echo -e "-----------------------------------------------------------"
}
function sslvirtualhost(){
    echo "--------------------------------------------------------------"
	echo "           begin to install ssl virtual host                  "
    echo "--------------------------------------------------------------"
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
	sed -i 's/rewriterule/'${rewriterule}'/g' /etc/nginx/conf.d/${hostname}.conf	
	sed -i 's#tennfy_certificate#'${certificate}'#g' /etc/nginx/conf.d/${hostname}.conf	
	sed -i 's#tennfy_privatekey#'${privatekey}'#g' /etc/nginx/conf.d/${hostname}.conf	
	#new a virtualhost dir
	mkdir /home/wwwroot/${hostname}
	cd /home/wwwroot/${hostname}
	chmod -R 777 /home/wwwroot
	chown -R www-data:www-data /home/wwwroot


	/etc/init.d/nginx start
	echo -e "------------------------------------------------------------" &&
	echo -e "   ${CSUCCESS}install ssl virtual host successfully!${CEND} " &&
	echo -e "------------------------------------------------------------"
}
function init(){
    echo -e "-------------------------------------------------------------"
	echo -e "               begin to initialize system                    "
    echo -e "-------------------------------------------------------------"
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
	echo -e "------------------------------------------------------------" &&
	echo -e "     ${CSUCCESS}initialize system successfully!${CEND}      " &&
	echo -e "------------------------------------------------------------"
}
function installlnmp(){
    #init system
	init
	#install mysql, php, nginx
	installmysql
	installphp
	installnginx	
	#set web dir
	cp -r ${lnmpdir}/packages/phpMyAdmin /home/wwwroot
	#restart lnmp
	echo -e "-------------------------------------------------------------" &&
	echo -e "                 begin to restart lnmp!                      " &&
	echo -e "-------------------------------------------------------------"	
	/etc/init.d/nginx restart
	/etc/init.d/php7-fpm restart
	/etc/init.d/mysql restart
	echo -e "-------------------------------------------------------------" &&
	echo -e "      ${CSUCCESS}lnmp install successfully!${CEND}           " &&
	echo -e "-------------------------------------------------------------"
	echo "Start time: ${StartDate}";
	echo "Completion time: $(date) (Use: $[($(date +%s)-StartDateSecond)/60] minute)";
}
function addvhost(){
    while :
    do
            echo
            echo 'Please select host type:'
            echo -e "\t${CMSG}1${CEND}. Install virtual host"
            echo -e "\t${CMSG}2${CEND}. Install SSL virtual host"
            read -p "Please input a number:(Default 1 press Enter) " host_type
            [ -z "$host_type" ] && host_type=1
            if [[ ! $host_type =~ ^[1-2]$ ]];then
                echo "${CWARNING}input error! Please only input number 1,2${CEND}"
            else
                if [ "$host_type" == '1' ]
				then
					virtualhost
				fi
				if [ "$host_type" == '2' ]
				then
					sslvirtualhost
				fi
				break
            fi
    done
}
function delvhost(){
    echo "--------------------------------------------------------------"
	echo "                   begin to delete host                       "
    echo "--------------------------------------------------------------"
	echo "please input hostname(like tennfy.com):"
	read hostname
	if [ -f /etc/nginx/conf.d/${hostname}.conf ]
	then
	    rm -f /etc/nginx/conf.d/${hostname}.conf
	fi
	if [ -d /home/wwwroot/${hostname} ]
	then 
	    rm -r /home/wwwroot/${hostname}
	fi
	/etc/init.d/nginx start
	echo -e "------------------------------------------------------------" &&
	echo -e "    ${CSUCCESS}delete virtual host successfully!${CEND}     " &&
	echo -e "------------------------------------------------------------"
}
function uninstalllnmp(){
    echo "--------------------------------------------------------------"
	echo "                   begin to uninstall lnmp                    "
    echo "--------------------------------------------------------------"
    #stop all 
	/etc/init.d/php7-fpm stop
	/etc/init.d/nginx stop
	/etc/init.d/mysql stop
	#delete all install files
	rm -rf /opt/lnmp
	#delete all virtual hosts
	rm -rf /home/wwwroot
	#uninstall nginx
	update-rc.d -f nginx remove
	rm -rf /etc/nginx /etc/init.d/nginx /var/log/nginx
	rm -f  /usr/sbin/nginx  /var/run/nginx.pid
	#uninstall php
		update-rc.d -f php7-fpm remove
                rm -rf /etc/php7 /usr/local/php7 /usr/local/libiconv /usr/local/curl /usr/local/mhash /usr/local/mcrypt /usr/local/libmcrypt /usr/local/libmcrypt
		rm -f /etc/init.d/php7-fpm /usr/bin/php /usr/bin/phpize /usr/sbin/php7-fpm /var/run/php7-fpm.sock /var/run/php7-fpm.pid /var/log/php7-fpm.log 	
	#usinstall mysql
		update-rc.d -f mysql remove
		rm -rf /etc/mysql /usr/local/mysql /var/lib/mysql /var/run/mysqld 
		rm -f  /etc/init.d/mysql /usr/bin/mysql /usr/bin/mysqladmin /usr/bin/mysqldump /usr/bin/myisamchk /usr/bin/mysqld_safe /var/run/mysqld/mysqld.sock /etc/ld.so.conf.d/mysql.conf
	echo -e "------------------------------------------------------------" &&
	echo -e "    ${CSUCCESS}uninstall lnmp successfully!${CEND}          " &&
	echo -e "------------------------------------------------------------"
}
######################### Initialization ################################################
action=$1
[ -z $1 ] && action=install
case "$action" in
install)
    installlnmp
    ;;
addvhost)
    addvhost
    ;;
delvhost)
    delvhost
    ;;
uninstall)
    uninstalllnmp
    ;;
*)
    echo "Arguments error! [${action} ]"
    echo "Usage: `basename $0` {install|addvhost|delvhost|uninstall}"
    ;;
esac
