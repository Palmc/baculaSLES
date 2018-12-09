#!/bin/bash

set -e

### Version de baculum que se utilizará ###
baculum_ver=9.2.2

wget -O bacula-gui.tar.gz https://sourceforge.net/projects/bacula/files/bacula/$baculum_ver/bacula-gui-$baculum_ver.tar.gz/download

### Descomprimimos y ponemos los permisos correctos ###
tar xzvf bacula-gui.tar.gz -C /usr/src/
chown -R root:root /usr/src/bacula-gui-$baculum_ver

### Instalamos las dependencias necesarias ###
zypper addrepo https://download.opensuse.org/repositories/devel:languages:php/SLE_12_SP3/devel:languages:php.repo
zypper --gpg-auto-import-keys refresh
zypper in -y apache2 apache2-mod_php7 php7 php7-pgsql php7-curl php7-json php7-bcmath php7-mbstring php7-pdo php7-gd php7-pear php7-gettext php7-mysql

### Habilitamos módulos de apache ###
a2enmod php7; a2enmod rewrite; a2enmod access_compat; a2enmod gzip

### Copiamos los contenidos necesarios al directorio de apache ###
cp -R /usr/src/bacula-gui-$baculum_ver/baculum /srv/www/htdocs/

### Permitimos al usuario de apache ejecutar como sudo algunos comandos de bacula ###
cat >> /etc/sudoers.d/baculum <<EOF
wwwrun ALL= NOPASSWD: /usr/sbin/bconsole
wwwrun ALL= NOPASSWD: /etc/bacula/confapi
wwwrun ALL= NOPASSWD: /usr/sbin/bdirjson
wwwrun ALL= NOPASSWD: /usr/sbin/bbconsjson
wwwrun ALL= NOPASSWD: /usr/sbin/bfdjson
wwwrun ALL= NOPASSWD: /usr/sbin/bsdjson
EOF

### Creamos el directorio de bacula que será utilizado para guardar las configuraciones de bacula desde la interfaz web ###
mkdir -p /etc/bacula/confapi
chown wwwrun:www /etc/bacula/confapi
chmod 775 /etc/bacula/confapi

### Cambiamos el límite de memoria de php ###
sed -i "s/memory_limit = 128M/memory_limit = 256M/g" /etc/php7/apache2/php.ini

#Elegir contraseña para el usuario admin de las páginas de apache
	echo -e "\n\nEnter the password that the \e[33madmin\e[0m user will have ( Baculum Auth )"
	while true; do
		echo -e "\n"
		read -s -p "Password: " pass
		echo -e "\n"
		read -s -p "Type password again: " pass2
	 	[ "$pass" = "$pass2" ] && break
		echo -e "\nError, please try again"
	done
echo -e "\n\e[92mSucess!!\e[0m"


### Creamos el archivo de usuario y contraseña que será utilizado al entrar en la páginas de la api y de administración ###
htpasswd -cb /srv/www/htdocs/baculum/protected/Web/baculum.users admin $pass2
cp /srv/www/htdocs/baculum/protected/Web/baculum.users /srv/www/htdocs/baculum/protected/Web/Config/
cp /srv/www/htdocs/baculum/protected/Web/baculum.users /srv/www/htdocs/baculum/protected/API/Config/

###Creamos los archivos de configuración de apache necesarios para la pagina de la web y la de la API###

## WEB ##
cp /srv/www/htdocs/baculum/examples/rpm/baculum-web-apache.conf /etc/apache2/conf.d/baculum-web.conf
sed -i 's/\/usr\/share\/baculum\/htdocs/\/srv\/www\/htdocs\/baculum/g' /etc/apache2/conf.d/baculum-web.conf
sed -i 's/\/var\/log\/httpd/\/var\/log\/apache2/g' /etc/apache2/conf.d/baculum-web.conf
#chown -R :www /etc/bacula/

## API ##
cp /srv/www/htdocs/baculum/examples/rpm/baculum-api-apache.conf /etc/apache2/conf.d/baculum-api.conf
sed -i 's/\/usr\/share\/baculum\/htdocs/\/srv\/www\/htdocs\/baculum/g' /etc/apache2/conf.d/baculum-api.conf
sed -i 's/\/var\/log\/httpd/\/var\/log\/apache2/g' /etc/apache2/conf.d/baculum-api.conf

### Cambiamos permisos ###
chown -R wwwrun:www /srv/www/htdocs/baculum


#Delete .htaccess
#find /srv/www/htdocs/baculum -name .htaccess > /tmp/htaccess.txt
#
#for i in `cat /tmp/htaccess.txt`
#do
#	rm $i 
#	echo $i "deleted"
#done
#rm /tmp/htaccess.txt

### Creamos enlaces a los archivos de configuración de bacula ###
ln -s /etc/bacula/etc/* /etc/bacula/

### Iniciamos y habilitamos el servicio de apache
systemctl start apache2; systemctl enable apache2



echo -e "\n############################################"
echo "###############  FINISHED  #################"
echo "############################################"

ip=$(ip route get 8.8.8.8 | awk 'NR==1 {print $NF}')
echo -e "\n\nFirst you must configure the API here: \e[92mhttp://$ip:9096\e[0m"
echo -e "\nAnd then configure the web interface here: \e[92mhttp://$ip:9095\e[0m\n"

#cd /etc/bacula/
#       chown apache /sbin/bconsole
#       chown apache /etc/bacula/bconsole.conf
#chmod 775 /etc/bacula/

