apt-get install gnupg2 add-apt-key -y
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/php7.x.list
apt-get update && apt-get upgrade -y 
# install Required Dependencies
apt-get install -y linux-image build-essential linux-headers-`uname -r` openssh-server apache2 mariadb-server\
  mariadb-client bison flex php7.4 php7.4-curl php7.4-cli php7.4-common php7.4-mysql php7.4-gd php7.4-mbstring\
  php7.4-intl php7.4-xml php-pear curl sox libncurses5-dev libssl-dev mpg123 libxml2-dev libnewt-dev sqlite3\
  libsqlite3-dev pkg-config automake libtool autoconf git unixodbc-dev uuid uuid-dev\
  libasound2-dev libogg-dev libvorbis-dev libicu-dev libcurl4-openssl-dev libical-dev libneon27-dev libsrtp2-dev\
  libspandsp-dev sudo subversion libtool-bin python-dev unixodbc dirmngr sendmail-bin sendmail\
# Install nodejs
curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
sudo apt-get install -y nodejs 
read -p "reboot CTRL-c to cancel" && reboot
# install MariaDB ODBC

cd /usr/src/
wget https://wiki.freepbx.org/download/attachments/202375584/libssl1.0.2_1.0.2u-1_deb9u4_amd64.deb
wget https://wiki.freepbx.org/download/attachments/122487323/mariadb-connector-odbc_3.0.7-1_amd64.deb
dpkg -i libssl1.0.2_1.0.2u-1_deb9u4_amd64.deb
dpkg -i mariadb-connector-odbc_3.0.7-1_amd64.deb


cd /usr/src
wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-16-current.tar.gz
# Compile and install DAHDI.
# If you don't have any physical PSTN hardware attached to this machine, you don't need to install DAHDI.(For example, a T1 or E1 card, or a USB device). Most smaller setups will not have DAHDI hardware, and this step can be safely skipped.
wget http://downloads.asterisk.org/pub/telephony/dahdi-linux-complete/dahdi-linux-complete-current.tar.gz
wget http://downloads.asterisk.org/pub/telephony/libpri/libpri-current.tar.gz
cd /usr/src
tar xvfz dahdi-linux-complete-current.tar.gz
rm -f dahdi-linux-complete-current.tar.gz
cd dahdi-linux-complete-*
make all
make install 
make install-config
cd /usr/src
tar xvfz libpri-current.tar.gz
rm -f libpri-current.tar.gz
cd libpri-*
make
make install
# Compile and install Asterisk
# Some scripts will have you enable CORE-SOUNDS and EXTRA-SOUNDS but this is unnecessary on FreePBX as the Sound Languages module will do this for you



cd /usr/src
tar xvfz asterisk-16-current.tar.gz
rm -f asterisk-16-current.tar.gz
cd asterisk-*
contrib/scripts/get_mp3_source.sh
contrib/scripts/install_prereq install
./configure --with-pjproject-bundled --with-jansson-bundled
make menuselect.makeopts
menuselect/menuselect --enable app_macro --enable format_mp3 menuselect.makeopts
# after selecting 'Save & Exit' you can then continue
make
make install
make config
ldconfig
update-rc.d -f asterisk remove
# Install and Configure FreePBX
# create the Asterisk user and set base file permissions.
useradd -m asterisk
chown asterisk. /var/run/asterisk
chown -R asterisk. /etc/asterisk
chown -R asterisk. /var/{lib,log,spool}/asterisk
chown -R asterisk. /usr/lib/asterisk
rm -rf /var/www/html
# a few small modifications to Apache.
sed -i 's/\(^upload_max_filesize = \).*/\120M/' /etc/php/7.4/apache2/php.ini
cp /etc/apache2/apache2.conf /etc/apache2/apache2.conf_orig
sed -i 's/^\(User\|Group\).*/\1 asterisk/' /etc/apache2/apache2.conf
sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf
a2enmod rewrite
service apache2 restart
# configure ODBC
# Edit /etc/odbcinst.ini and add the following. Note that this command assumes you are installing to a new machine, and that the file is empty. If this is not a freshly installed machine, please manually verify the contents of the file, rather than just copying and pasting the lines below. The 'EOF' does no go in the file, it simply signals to the 'cat' command that you have finished pasting.

cat <<EOF > /etc/odbcinst.ini
[MySQL]
Description = ODBC for MySQL (MariaDB)
Driver = /usr/local/lib/libmaodbc.so
FileUsage = 1
EOF
# you may need to verify these paths, if you're not on a x86_64 machine. You can use the command `find / -name libmyodbc.so` to verify the location

# Edit or create /etc/odbc.ini and add the following section. Note that, again, this command assumes you are installing to a new machine, and the file is empty. Please manually verify the contents of the files if this is not the case.

cat <<EOF > /etc/odbc.ini
[MySQL-asteriskcdrdb]
Description = MySQL connection to 'asteriskcdrdb' database
Driver = MySQL
Server = localhost
Database = asteriskcdrdb
Port = 3306
Socket = /var/run/mysqld/mysqld.sock
Option = 3
EOF
# Download and install FreePBX.
cd /usr/src
wget http://mirror.freepbx.org/modules/packages/freepbx/7.4/freepbx-16.0-latest.tgz
tar vxfz freepbx-16.0-latest.tgz
rm -f freepbx-16.0-latest.tgz
touch /etc/asterisk/{modules,cdr}.conf
cd freepbx
./start_asterisk start
./install -n

#Install all Freepbx modules
fwconsole ma disablerepo commercial
fwconsole ma installall
fwconsole ma delete firewall
fwconsole reload
fwconsole restart
echo "that's it!"
echo "You can now start using FreePBX.  Open up your web browser and connect to the IP address or hostname of your new FreePBX server.  You will see the Admin setup page, which is where you set your  'admin' account password, and configure an email address to receive update notifications. "

