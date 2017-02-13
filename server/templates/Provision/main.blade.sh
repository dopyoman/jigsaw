#!/usr/bin/env bash

@include('Provision._variables')

sudo sed -i "s/#precedence ::ffff:0:0\/96  100/precedence ::ffff:0:0\/96  100/" /etc/gai.conf

@include('Provision._apt')

@include('Provision.packages._base)

@include('Provision.packages._httpie')

@include('Provision.setup._ssh')

@include('Provision.setup._hostname')

@include('Provision.setup._timezone')

@include('Provision._user')

@include('Provision._forgeEnv')

@include('Provision.setup._firewall')

@include('Provision.php._setup')

@include('Provision.php._composer')

@include('Provision.php._configurations')

@include('Provision.nginx._setup')

@include('Provision.nginx._fastcgi')



# Disable The Default Nginx Site

rm /etc/nginx/sites-enabled/default
rm /etc/nginx/sites-available/default
service nginx restart

@include('Provision.php._fpmSettings')


@include('Provision.nginx._catchall')

# Restart Nginx & PHP-FPM Services

if [ ! -z "\$(ps aux | grep php-fpm | grep -v grep)" ]
then
	service php7.1-fpm restart
fi

service nginx restart
service nginx reload

# Add User To www-data Group

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
