# Install A Catch All Server

cat > /etc/nginx/sites-available/catch-all << EOF
server {
return 404;
}
EOF

ln -s /etc/nginx/sites-available/catch-all /etc/nginx/sites-enabled/catch-all
