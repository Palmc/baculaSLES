#!/bin/bash
#More info here: http://bacula.us/compilation/

set -e

#Version de bacula que se utilizará
bacula_ver=9.2.2

#Directorio en el que se guardan los backups
backup_dir=/mnt/backup

mkdir $backup_dir

#wget https://sourceforge.net/projects/bacula/files/latest/download
wget -O bacula.tar.gz https://sourceforge.net/projects/bacula/files/bacula/$bacula_ver/bacula-$bacula_ver.tar.gz/download

mkdir /usr/src/bacula
tar xzvf bacula.tar.gz -C /usr/src/bacula --strip-components 1
zypper in -y gcc-c++ readline-devel zlib-devel lzo-devel libacl-devel mt_st mtx postfix libopenssl-devel postgresql96-devel postgresql96-server

chown -R root:root /usr/src/bacula
cd /usr/src/bacula/
./configure --with-readline=/usr/include/readline \
--disable-conio \
--bindir=/usr/bin \
--sbindir=/usr/sbin \
--with-scriptdir=/etc/bacula/scripts \
--with-working-dir=/var/lib/bacula \
--with-logdir=/var/log \
--enable-smartalloc \
--with-postgresql \
--with-archivedir=$backup_dir \
--with-systemd=/usr/lib/systemd/system \
--with-job-email=sample@email.com \
--with-hostname=localhost


make -j8 && make install && make --directory /usr/src/bacula/platforms/systemd/ install



sudo -u postgres mkdir /var/lib/pgsql/data 
cd /var/lib/pgsql/data
sudo -u postgres /usr/lib/postgresql96/bin/initdb -D /var/lib/pgsql/data
sudo -u postgres /usr/lib/postgresql96/bin/pg_ctl -D /var/lib/pgsql/data -l logfile start

sleep 2

mkdir /tmp/bacula
cp /etc/bacula/scripts/* /tmp/bacula
chmod -R +rx /tmp/bacula

sudo -u postgres /tmp/bacula/create_postgresql_database 
sudo -u postgres /tmp/bacula/make_postgresql_tables
sudo -u postgres /tmp/bacula/grant_postgresql_privileges
systemctl enable postgresql.service