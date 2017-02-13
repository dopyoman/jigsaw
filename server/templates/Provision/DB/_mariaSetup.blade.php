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