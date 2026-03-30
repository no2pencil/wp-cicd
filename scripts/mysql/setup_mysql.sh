#!/bin/bash
logfile=/tmp/mysqlsetup.txt
echo "Launching User Data" > ${logfile}

echo "Waiting for network..." >> ${logfile}

until curl -s https://ipinfo.io > /dev/null; do
  echo "Network not ready, retrying..." >> ${logfile}
  sleep 3
done

# --- Update OS ---
echo "Update OS" >> ${logfile}
dnf update -y || echo "dnf update failed, continuing..." >> ${logfile}

# --- Install MySql Server and Client ---
echo "Checking for MySql installation" >> ${logfile}
which mysql >/dev/null 2>&1
retval=$?
if [ ${retval} -ne 0 ]; then
  echo "Installing MySql Server and Client" >> ${logfile}
  mkdir -p /usr/local/mysql
  ##wget https://dev.mysql.com/get/Downloads/MySQL-9.5/mysql-9.5.0-linux-glibc2.28-x86_64.tar.xz
  ##tar -xf mysql-9.5.0-linux-glibc2.28-x86_64.tar.xz
  ##mv  mysql-9.5.0-linux-glibc2.28-x86_64/* /usr/local/mysql/
  echo "Downloading MySql Server & Client " >> ${logfile}
  wget https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-8.0.45-linux-glibc2.28-x86_64.tar.xz
  tar -xf mysql-8.0.45-linux-glibc2.28-x86_64.tar.xz
  mv mysql-8.0.45-linux-glibc2.28-x86_64/* /usr/local/mysql/
  export PATH=$PATH:/usr/local/mysql/bin/
  echo 'export PATH=$PATH:/usr/local/mysql/bin/' >> ~/.bashrc
  source ~/.bashrc
fi
echo "Return Value : ${retval}" >> ${logfile}

# --- Create user and group ---
getent group mysql > /dev/null 2>&1
retval=$?
if [ ${retval} -ne 0 ]; then
  echo "Creating MySql Group" >> ${logfile}
  groupadd mysql
  useradd -r -g mysql -s /bin/false mysql
  chown -R mysql:mysql /usr/local/mysql
fi

# --- Init the db ---
echo "Initializing MySqld Service" >> ${logfile}
cd /usr/local/mysql/bin
mysqld --initialize --user=mysql 2> /var/log/mysqld.log

# --- Start MySQL ---
echo "Starting MySqld Service" >> ${logfile}
cp ../support-files/mysql.server /etc/init.d/mysql
service mysql start

retval=$(ps aux | grep mysql | grep -v grep | wc -l)
if [ ${retval} -ne 0 ]; then
  echo "Something went wrong and mysql not running.  Check logs." >> ${logfile}
  echo "Something went wrong and mysql not running.  Check logs."
  exit
fi

# --- Capture temporary root password --- 
echo "Setuping WordPress MySql DB" >> ${logfile}
echo "Gathering ROOT temporary creds" >> ${logfile}
MYSQL_ROOT_OLD_PASSWORD=$(grep 'temporary password' /var/log/mysqld.log | cut -d: -f4 | awk '{print $1}')
MYSQL_ROOT_PASSWORD="REMOVED1"

# --- Change root password safely ---
echo "Changing ROOT creds" >> ${logfile}
mysql --connect-expired-password -u root -p"${MYSQL_ROOT_OLD_PASSWORD}" \
  -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}'; FLUSH PRIVILEGES;"

# --- Create WordPress DB and user ---
echo "Create WordPress DB" >> ${logfile}
mysql -u root -p"${MYSQL_ROOT_PASSWORD}" <<SQL
CREATE DATABASE IF NOT EXISTS vrg_blog;
CREATE USER IF NOT EXISTS 'vrg'@'%' IDENTIFIED BY 'REMOVED2';
GRANT ALL PRIVILEGES ON vrg_blog.* TO 'vrg'@'%';
FLUSH PRIVILEGES;
SQL

# --- Bind MySQL to all interfaces (dev only) ---
if ! grep -q "^bind-address = 0.0.0.0" /etc/my.cnf; then
    echo "Updating allow bind" >> ${logfile}
    sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' /etc/my.cnf
    systemctl restart mysqld
fi

# After install cleanup
chmod 644 /run/php-fpm/www.sock

echo "MySQL setup complete" >> ${logfile}
echo "Completed User Data" >> ${logfile}

