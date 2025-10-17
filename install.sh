sudo apt-get update
sudo apt-get upgrade
sudo apt-get install nginx php mariadb-server curl wget
wget https://repo.manticoresearch.com/manticore-repo.noarch.deb
sudo dpkg -i manticore-repo.noarch.deb
rm -f manticore-repo.noarch.deb
sudo apt-get update
sudo apt-get install manticore manticore-extra
sudo systemctl start manticore
sudo apt-get install acl file gettext git openssh-client python3
sudo apt-get install php-intl php-gd php-mysql php-xml php-zip
sudo apt-get install unzip
if [ ! -f "$HOME/bin/composer" ]; then
	mkdir ~/bin
	curl -sS https://getcomposer.org/installer | php -- --install-dir=$HOME/bin --filename=composer
fi
cd ~/rox
composer install
