# Set The Hostname If Necessary


echo "$host_name" > /etc/hostname
sed -i 's/127\.0\.0\.1.*localhost/127.0.0.1	$host_name localhost/' /etc/hosts
hostname $host_name