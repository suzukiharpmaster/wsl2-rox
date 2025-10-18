#!/bin/bash

unset $ROX_DIR

if [ $1 ]; then
	ROX_DIR=$1
else
	ROX_DIR="/var/www/bewelcome"
fi

wget https://repo.manticoresearch.com/manticore-repo.noarch.deb
sudo dpkg -i manticore-repo.noarch.deb
rm -f manticore-repo.noarch.deb
sudo apt-get update
sudo apt-get upgrade
sudo apt-get -y install manticore manticore-extra
sudo apt-get -y install nginx php mariadb-server curl wget
sudo apt-get -y install acl file gettext git openssh-client python3
sudo apt-get -y install php-intl php-gd php-mysql php-xml php-zip
sudo apt-get -y install php-mbstring php-common php-xmlrpc
sudo apt-get -y install zip php-fpm
sudo systemctl start manticore
sudo systemctl start nginx
sudo systemctl start mariadb
sudo systemctl start php8.4-fpm.service 

if [ ! -f "/usr/share/keyrings/yarn-keyring.gpg" ]; then
	curl -fsSL https://dl.yarnpkg.com/debian/pubkey.gpg | sudo gpg --dearmor -o /usr/share/keyrings/yarn-keyring.gpg
	echo "deb [signed-by=/usr/share/keyrings/yarn-keyring.gpg] https://dl.yarnpkg.com/debian stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
	sudo apt-get update
	sudo apt-get -y install yarn
fi

if [ ! -d "$HOME/bin" ]; then
	mkdir ~/bin
fi

if [ ! -f "$HOME/bin/mailhog" ]; then
	wget -c https://github.com/mailhog/MailHog/releases/download/v1.0.1/MailHog_linux_amd64 -O $HOME/bin/mailhog
	chmod +x $HOME/bin/mailhog
fi

if [ ! -f "$HOME/bin/composer" ]; then
	curl -sS https://getcomposer.org/installer | php -- --install-dir=$HOME/bin --filename=composer
	chmod +x $HOME/bin/composer
fi

cd $ROX_DIR

cp .env .env.local
sed -i 's/DB_HOST=db/DB_HOST=localhost/g' .env.local
sed -i 's/MAILER_DSN=smtp:\/\/mailer:25/MAILER_DSN=smtp:\/\/mailer:1025/g' .env.local
sed -i 's/serverVersion=12.0.2-MariaDB/serverVersion=11.8.3-MariaDB/g' .env.local

sudo mysql <<MYSQL_SCRIPT
CREATE USER IF NOT EXISTS 'bewelcome'@'localhost' IDENTIFIED BY 'bewelcome';
GRANT ALL PRIVILEGES ON bewelcome.* TO 'bewelcome'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

php bin/console test:database:create --drop --force

composer install
yarn install --frozen-lock

git rev-parse --short HEAD > VERSION
bzip2 -ckd docker/languages.sql.bz2 > docker/db/languages.sql
bzip2 -ckd docker/words.sql.bz2 > docker/db/words.sql

cat > bewelcome.conf <<NGINX_CONFIG
server {
    listen 8080;	
    root /var/www/bewelcome/public;

    location / {
        try_files \$uri /index.php\$is_args\$args;
    }

    location ~ ^/index\.php(/|$) {
        fastcgi_pass unix:/run/php/php8.4-fpm.sock;

        fastcgi_buffer_size 32k;
        fastcgi_buffers 32 4k;

        fastcgi_split_path_info ^(.+\.php)(/.*)$;
        include fastcgi_params;

        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        fastcgi_param DOCUMENT_ROOT \$realpath_root;
        internal;
    }

    location ~ \.php$ {
      return 404;
    }
}
NGINX_CONFIG

cat > reset_passwords.sql <<MYSQL
UPDATE members SET password = PASSWORD('password');
MYSQL

sudo mv bewelcome.conf /etc/nginx/conf.d/
sudo cp docker/php/conf.d/bewelcome.prod.ini /etc/php/8.4/cli/conf.d/bewelcome.ini
sudo cp docker/manticore/manticore.conf /etc/manticoresearch/manticore.conf
sudo mkdir -p /var/www/bewelcome/data/user/avatars
sudo chgrp -R www-data /var/www/bewelcome/
sudo chown -R www-data:www-data var build data
sudo mysql bewelcome -u bewelcome -pbewelcome < docker/db/languages.sql
sudo mysql bewelcome -u bewelcome -pbewelcome < docker/db/words.sql 
sudo mysql bewelcome -u bewelcome -pbewelcome < docker/db/geonamesadminunits.sql 
sudo mysql bewelcome -u bewelcome -pbewelcome < reset_passwords.sql 
make build version

sudo systemctl restart nginx
sudo systemctl restart mariadb
sudo systemctl restart php8.4-fpm.service 
