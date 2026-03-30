#!/bin/bash
logfile=/tmp/wpsetup.txt
echo "Launching User Data" > ${logfile}
# Update packages
echo "Installing OS Updates" >> ${logfile}
dnf update -y

# Install Nginx and PHP-FPM
echo "Installing nginx & PHP-FPM" >> ${logfile}
dnf install -y nginx php-fpm php-mysqlnd php-xml php-gd php-mbstring wget unzip

# Install EFS client for aws
echo "Installing EFS Client" >> ${logfile}
yum install -y amazon-efs-utils

# Enable services
echo "Enabling and starting nginx & PHP-FPM" >> ${logfile}
systemctl enable nginx
systemctl enable php-fpm
systemctl start nginx
systemctl start php-fpm

echo "Mounting EFS File System" >> ${logfile}
mount -t efs fs-0be512adc3621418b:/ /var/www/html/wordpress
echo "Changing user permissions" >> ${logfile}
chown -R nginx:nginx /var/www/html/
chmod -R 755 /var/www/html/

# Configure Nginx for WordPress
cat > /etc/nginx/conf.d/wordpress.conf <<EOF
server {
    listen 80;
    server_name _;
    root /var/www/html/wordpress/blog;
    index index.php index.html;

    location / {
      try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php\$ {
      include fastcgi_params;
      fastcgi_pass unix:/run/php-fpm/www.sock;
      fastcgi_index index.php;
      fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }
  }
EOF

echo "Launching Website" >> ${logfile}
systemctl restart nginx
echo "User Data Completed" >> ${logfile}
