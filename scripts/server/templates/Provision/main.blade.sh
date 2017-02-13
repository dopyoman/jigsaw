#!/usr/bin/env bash

@include('Provision._variables')

sudo sed -i "s/#precedence ::ffff:0:0\/96  100/precedence ::ffff:0:0\/96  100/" /etc/gai.conf

@include('Provision._aptRepositories')

# Base Packages

apt-get install -y --force-yes build-essential curl fail2ban gcc git libmcrypt4 libpcre3-dev \
make python2.7 python-pip supervisor ufw unattended-upgrades unzip whois zsh

# Install Python Httpie

pip install httpie


# Disable Password Authentication Over SSH

sed -i "/PasswordAuthentication yes/d" /etc/ssh/sshd_config
echo "" | sudo tee -a /etc/ssh/sshd_config
echo "" | sudo tee -a /etc/ssh/sshd_config
echo "PasswordAuthentication no" | sudo tee -a /etc/ssh/sshd_config

# Restart SSH

ssh-keygen -A
service ssh restart

# Set The Hostname If Necessary


echo "$host_name" > /etc/hostname
sed -i 's/127\.0\.0\.1.*localhost/127.0.0.1	$host_name localhost/' /etc/hosts
hostname $host_name


# Set The Timezone

ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime

# Create The Root SSH Directory If Necessary

if [ ! -d /root/.ssh ]
then
	mkdir -p /root/.ssh
	touch /root/.ssh/authorized_keys
fi

@include('Provision._user')
# Configure Git Settings

git config --global user.name "$git_name"
git config --global user.email "$git_email"

# Add The Reconnect Script Into Forge Directory

cat > /home/$sudo_user/.$sudo_user/reconnect << EOF
#!/usr/bin/env bash

echo "# Laravel $sudo_user" | tee -a /home/forge/.ssh/authorized_keys > /dev/null
echo \$1 | tee -a /home/forge/.ssh/authorized_keys > /dev/null

echo "# Laravel $sudo_user" | tee -a /root/.ssh/authorized_keys > /dev/null
echo \$1 | tee -a /root/.ssh/authorized_keys > /dev/null

echo "Keys Added!"
EOF

@include('Provision._forgeEnv')

# Setup Site Directory Permissions

chown -R $sudo_user:$sudo_user /home/$sudo_user
chmod -R 755 /home/$sudo_user
chmod 700 /home/$sudo_user/.ssh/id_rsa

# Setup UFW Firewall

ufw allow 22
ufw allow 80
ufw allow 443
ufw --force enable

# Allow FPM Restart

echo "forge ALL=NOPASSWD: /usr/sbin/service php7.0-fpm reload" > /etc/sudoers.d/php-fpm
echo "forge ALL=NOPASSWD: /usr/sbin/service php5-fpm reload" >> /etc/sudoers.d/php-fpm

			# Install Base PHP Packages

	apt-get install -y --force-yes php7.1-cli php7.1-dev \
	php7.1-pgsql php7.1-sqlite3 php7.1-gd \
	php7.1-curl php7.1-memcached \
	php7.1-imap php7.1-mysql php7.1-mbstring \
	php7.1-xml php7.1-zip php7.1-bcmath php7.1-soap \
	php7.1-intl php7.1-readline

# Install Composer Package Manager

curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

# Misc. PHP CLI Configuration

sudo sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.0/cli/php.ini
sudo sed -i "s/display_errors = .*/display_errors = On/" /etc/php/7.0/cli/php.ini
sudo sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/7.0/cli/php.ini
sudo sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/7.0/cli/php.ini

# Configure Sessions Directory Permissions

chmod 733 /var/lib/php/sessions
chmod +t /var/lib/php/sessions


	#
# REQUIRES:
#       - server (the forge server instance)
#		- site_name (the name of the site folder)
#

# Install Nginx & PHP-FPM

	apt-get install -y --force-yes nginx php7.1-fpm

# Generate dhparam File

openssl dhparam -out /etc/nginx/dhparams.pem 2048


# Copy fastcgi_params to Nginx because they broke it on the PPA

cat > /etc/nginx/fastcgi_params << EOF
fastcgi_param	QUERY_STRING		\$query_string;
fastcgi_param	REQUEST_METHOD		\$request_method;
fastcgi_param	CONTENT_TYPE		\$content_type;
fastcgi_param	CONTENT_LENGTH		\$content_length;
fastcgi_param	SCRIPT_FILENAME		\$request_filename;
fastcgi_param	SCRIPT_NAME		\$fastcgi_script_name;
fastcgi_param	REQUEST_URI		\$request_uri;
fastcgi_param	DOCUMENT_URI		\$document_uri;
fastcgi_param	DOCUMENT_ROOT		\$document_root;
fastcgi_param	SERVER_PROTOCOL		\$server_protocol;
fastcgi_param	GATEWAY_INTERFACE	CGI/1.1;
fastcgi_param	SERVER_SOFTWARE		nginx/\$nginx_version;
fastcgi_param	REMOTE_ADDR		\$remote_addr;
fastcgi_param	REMOTE_PORT		\$remote_port;
fastcgi_param	SERVER_ADDR		\$server_addr;
fastcgi_param	SERVER_PORT		\$server_port;
fastcgi_param	SERVER_NAME		\$server_name;
fastcgi_param	HTTPS			\$https if_not_empty;
fastcgi_param	REDIRECT_STATUS		200;
EOF


# Disable The Default Nginx Site

rm /etc/nginx/sites-enabled/default
rm /etc/nginx/sites-available/default
service nginx restart

# Tweak Some PHP-FPM Settings

sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.0/fpm/php.ini

sed -i "s/display_errors = .*/display_errors = On/" /etc/php/7.0/fpm/php.ini

sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/7.0/fpm/php.ini

sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/7.0/fpm/php.ini

sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/7.0/fpm/php.ini

# Setup Session Save Path

sed -i "s/\;session.save_path = .*/session.save_path = \"\/var\/lib\/php5\/sessions\"/" /etc/php/7.0/fpm/php.ini

	sed -i "s/php5\/sessions/php\/sessions/" /etc/php/7.0/fpm/php.ini

# Configure Nginx & PHP-FPM To Run As Forge

sed -i "s/user www-data;/user ${sudo_user};/" /etc/nginx/nginx.conf
sed -i "s/# server_names_hash_bucket_size.*/server_names_hash_bucket_size 64;/" /etc/nginx/nginx.conf

sed -i "s/^user = www-data/user = ${sudo_user}/" /etc/php/7.0/fpm/pool.d/www.conf

sed -i "s/^group = www-data/group = ${sudo_user}/" /etc/php/7.0/fpm/pool.d/www.conf

sed -i "s/;listen\.owner.*/listen.owner = ${sudo_user}/" /etc/php/7.0/fpm/pool.d/www.conf

sed -i "s/;listen\.group.*/listen.group = ${sudo_user}/" /etc/php/7.0/fpm/pool.d/www.conf

sed -i "s/;listen\.mode.*/listen.mode = 0666/" /etc/php/7.0/fpm/pool.d/www.conf

# Configure A Few More Server Things

sed -i "s/;request_terminate_timeout.*/request_terminate_timeout = 60/" /etc/php/7.0/fpm/pool.d/www.conf

sed -i "s/worker_processes.*/worker_processes auto;/" /etc/nginx/nginx.conf
sed -i "s/# multi_accept.*/multi_accept on;/" /etc/nginx/nginx.conf

# Install A Catch All Server

cat > /etc/nginx/sites-available/catch-all << EOF
server {
	return 404;
}
EOF

ln -s /etc/nginx/sites-available/catch-all /etc/nginx/sites-enabled/catch-all

# Restart Nginx & PHP-FPM Services

# Restart Nginx & PHP-FPM Services

if [ ! -z "\$(ps aux | grep php-fpm | grep -v grep)" ]
then
	service php7.0-fpm restart
fi

service nginx restart
service nginx reload

# Add Forge User To www-data Group

usermod -a -G www-data ${sudo_user}
id ${sudo_user}
groups ${sudo_user}


#
# REQUIRES:
#       - server (the forge server instance)
#

# Only Install PHP Extensions When Not On HHVM


curl --silent --location https://deb.nodesource.com/setup_6.x | bash -

apt-get update

sudo apt-get install -y --force-yes nodejs

npm install -g pm2
npm install -g gulp
npm install -g yarn

    #
# REQUIRES:
#       - server (the forge server instance)
#       - db_password (random password for mysql user)
#

# Set The Automated Root Password

export DEBIAN_FRONTEND=noninteractive

debconf-set-selections <<< "mariadb-server-10.0 mysql-server/data-dir select ''"
debconf-set-selections <<< "mariadb-server-10.0 mysql-server/root_password password 9koYO6UcaH21J2o5kMom"
debconf-set-selections <<< "mariadb-server-10.0 mysql-server/root_password_again password 9koYO6UcaH21J2o5kMom"

# Install MySQL

apt-get install -y mariadb-server

# Configure Password Expiration

 echo "default_password_lifetime = 0" >> /etc/mysql/my.cnf

# Configure Access Permissions For Root & Forge Users

sed -i '/^bind-address/s/bind-address.*=.*/bind-address = */' /etc/mysql/my.cnf
mysql --user="$mysql_username" --password="$mysql_password" -e "GRANT ALL ON *.* TO root@'54.84.51.50' IDENTIFIED BY '$mysql_password';"
mysql --user="$mysql_username" --password="$mysql_password" -e "GRANT ALL ON *.* TO root@'%' IDENTIFIED BY '$mysql_password';"
service mysql restart

mysql --user="$mysql_username" --password="$mysql_password" -e "CREATE USER 'forge'@'54.84.51.50' IDENTIFIED BY '$mysql_password';"
mysql --user="$mysql_username" --password="$mysql_password" -e "GRANT ALL ON *.* TO 'forge'@'54.84.51.50' IDENTIFIED BY '$mysql_password' WITH GRANT OPTION;"
mysql --user="$mysql_username" --password="$mysql_password" -e "GRANT ALL ON *.* TO 'forge'@'%' IDENTIFIED BY '$mysql_password' WITH GRANT OPTION;"
mysql --user="$mysql_username" --password="$mysql_password" -e "FLUSH PRIVILEGES;"

# Set Character Set

echo "" >> /etc/mysql/my.cnf
echo "[mysqld]" >> /etc/mysql/my.cnf
echo "character-set-server = utf8" >> /etc/mysql/my.cnf

# Create The Initial Database If Specified

mysql --user="$mysql_username" --password="$mysql_password" -e "CREATE DATABASE $mysql_database;"


#
# REQUIRES:
#		- server (the forge server instance)
#		- db_password (random password for database user)
#

# Install Postgres

apt-get install -y --force-yes postgresql

# Configure Postgres For Remote Access

sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /etc/postgresql/9.5/main/postgresql.conf
echo "host    all             all             0.0.0.0/0               md5" | tee -a /etc/postgresql/9.5/main/pg_hba.conf
sudo -u postgres psql -c "CREATE ROLE $sudo_user LOGIN UNENCRYPTED PASSWORD '$mysql_password' SUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;"
service postgresql restart

# Create The Initial Database If Specified

sudo -u postgres /usr/bin/createdb --echo --owner=forge forge


# Install & Configure Redis Server

apt-get install -y redis-server
sed -i 's/bind 127.0.0.1/bind 0.0.0.0/' /etc/redis/redis.conf
service redis-server restart
# Install & Configure Memcached

apt-get install -y memcached
sed -i 's/-l 127.0.0.1/-l 0.0.0.0/' /etc/memcached.conf
service memcached restart
# Install & Configure Beanstalk

apt-get install -y --force-yes beanstalkd
sed -i "s/BEANSTALKD_LISTEN_ADDR.*/BEANSTALKD_LISTEN_ADDR=0.0.0.0/" /etc/default/beanstalkd
sed -i "s/#START=yes/START=yes/" /etc/default/beanstalkd
/etc/init.d/beanstalkd start

apt-get install -y blackfire-agent blackfire-php
service php7.0-fpm restart

# Install & Configure MailHog

# Download binary from github
wget --quiet -O /usr/local/bin/mailhog https://github.com/mailhog/MailHog/releases/download/v0.2.1/MailHog_linux_amd64

# Make it executable
chmod +x /usr/local/bin/mailhog

# Make it start on reboot
sudo tee /etc/systemd/system/mailhog.service <<EOL
[Unit]
Description=Mailhog
After=network.target

[Service]
User=vagrant
ExecStart=/usr/bin/env /usr/local/bin/mailhog > /dev/null 2>&1 &

[Install]
WantedBy=multi-user.target
EOL

# Start it now in the background
service mailhog start


# Configure Supervisor Autostart

systemctl enable supervisor.service
service supervisor start

# Configure Swap Disk

if [ -f /swapfile ]; then
    echo "Swap exists."
else
    fallocate -l 1G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo "/swapfile none swap sw 0 0" >> /etc/fstab
    echo "vm.swappiness=30" >> /etc/sysctl.conf
    echo "vm.vfs_cache_pressure=50" >> /etc/sysctl.conf
fi

# Setup Unattended Security Upgrades

cat > /etc/apt/apt.conf.d/50unattended-upgrades << EOF
Unattended-Upgrade::Allowed-Origins {
    "Ubuntu xenial-security";
};
Unattended-Upgrade::Package-Blacklist {
    //
};
EOF

cat > /etc/apt/apt.conf.d/10periodic << EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF
