# Tweak Some PHP-FPM Settings

sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.0/fpm/php.ini

sed -i "s/display_errors = .*/display_errors = On/" /etc/php/7.0/fpm/php.ini

sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/7.0/fpm/php.ini

sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/7.0/fpm/php.ini

sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/7.0/fpm/php.ini

# Setup Session Save Path

sed -i "s/\;session.save_path = .*/session.save_path = \"\/var\/lib\/php5\/sessions\"/" /etc/php/7.0/fpm/php.ini

sed -i "s/php5\/sessions/php\/sessions/" /etc/php/7.0/fpm/php.ini

# Configure Nginx & PHP-FPM To Run As User

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