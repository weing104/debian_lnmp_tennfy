#!/bin/bash

function installlnmp(){
	# add dotdeb.
dv=$(cut -d. -f1 /etc/debian_version)
if [ "$dv" = "7" ]; then
	echo -e 'deb http://packages.dotdeb.org wheezy all' >> /etc/apt/sources.list
    echo -e 'deb-src http://packages.dotdeb.org wheezy all' >> /etc/apt/sources.list
elif [ "$dv" = "6" ]; then
    echo -e 'deb http://packages.dotdeb.org squeeze all' >> /etc/apt/sources.list
    echo -e 'deb-src http://packages.dotdeb.org squeeze all' >> /etc/apt/sources.list
fi

#inport GnuPG key
wget http://www.dotdeb.org/dotdeb.gpg
cat dotdeb.gpg | apt-key add -
rm dotdeb.gpg
apt-get update
mkdir /var/www
#install zip unzip
apt-get install -y zip unzip
#install mysql
apt-get install -y mysql-server mysql-client
echo -e 'skip-innodb' >> /etc/mysql/my.cnf
#install PHP
apt-get -y install php5-fpm php5-gd php5-common php5-curl php5-imagick php5-mcrypt php5-memcache php5-mysql php5-cgi php5-cli 
#edit php
sed -i '/upload_max_filesize = 2M/s/2/8/g' /etc/php5/fpm/php.ini
sed -i '/memory_limit = 128M/s/128/48/g' /etc/php5/fpm/php.ini
sed -i "/listen = 127.0.0.1:9000/s/127.0.0.1:9000/\/var\/run\/php5-fpm.sock/g" /etc/php5/fpm/pool.d/www.conf
#install nginx
apt-get -y install nginx-full
# edit nginx
rm /etc/nginx/sites-available/default
cat >> /etc/nginx/sites-available/default <<EOF
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
rm /etc/nginx/wordpress.conf
cat  >> /etc/nginx/wordpress.conf <<"EOF"
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
cat  >> /etc/nginx/dz.conf <<"EOF"
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
#install sendmail
apt-get install sendmail-bin sendmail
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

echo "which do you want to?input the number."
echo "1. install lnmp"
echo "2. add virtualhost"
echo "3. repaire 502error"
read num

case "$num" in
[1] ) (installlnmp);;
[2] ) (addvirtualhost);;
[3] ) (repaire502);;
*) echo "nothing,exit";;
esac
