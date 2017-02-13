# REQUIRES:
#       - server (the forge server instance)
#		- site_name (the name of the site folder)
#

# Install Nginx & PHP-FPM

apt-get install -y --force-yes nginx php7.1-fpm

# Generate dhparam File

openssl dhparam -out /etc/nginx/dhparams.pem 2048