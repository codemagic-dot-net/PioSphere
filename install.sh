#!/bin/bash
#========================================================================
# (c) Marcel Flaig 2015 info@codemagic.net
# Run this Script with sudo /opt/codemagic/install/install.sh 
#========================================================================
# Short Description: 
# This install script is also designed to be reused as update script - just run again.
# Creates and installs backup script and schedules backup in crontab
# adds ssmtp for sending mails
# mounts cifs share 
# Sections
# 00 - Basic config and settings
# 01 - Basic Installation of ssmtp for mailing / backup script etc.
# 02 - tomcat mysql django  php java
# 03 - Module Installation ( energenie, DHTXX, webcam)
# 04 - Project Wiki
# 99 - finishing installation - creating initial backup sending log etc.
#========================================================================
# Required Files:
# config.sh - config values
# todo.sh - This is to do
# LocalSettings.php   - Wiki settings
#========================================================================
# Required Setup:
# raspbian, shell logon configured, wlan set up, sudo rpi-update && sudo reboot
# config.sh fill out variables - set path below
#========================================================================
# CONFIG SECTION 
#========================================================================
source /opt/codemagic/install/config.sh
#========================================================================
working_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $working_dir
logfile="install.log"
#========================================================================
echo "# 00 - Prerequisites start: delete old log , create new log, check if root, create service user, update packages"
echo "#========================================================================"
echo "# 00 - Script is running from $working_dir"
if [ -f $working_dir/$logfile ]
     then
     echo "# 00 - removing old logfile"
rm $working_dir/$logfile
fi
echo "# 00 - Creating new Logfile at $working_dir/$logfile"

if [ -f $working_dir/err.log ]
     then
     echo "# 00 - removing old errorlogfile"
rm $working_dir/err.log
fi

exec 1> >( tee -a install.log )
exec 2> >( tee -a err.log install.log ) 

echo "To: $mailto"
echo "From: $mailto"
echo "Subject: installationlog"
echo ""
######################################################################################################

mkdir $install_dir
chmod -R 777 $install_dir
mkdir $install_dir/config



echo "#========================================================================"
echo "# 00 - Setup extra service account:"
echo "#========================================================================"
echo "# 00 - checking if user is root"
if [ "$(whoami)" != "root" ]
then
     sudo su -s "$0"
     exit
fi

echo "#========================================================================"
echo "# 00 - $user with the password $password will be created"
useradd -m $user
echo -e "$password\n$password\n" | passwd $user
echo "# 00 - Create Group called $user"
groupadd $user
useradd -G $user $user
echo "#========================================================================"
echo "# 00 - Getting prerequisites: running on a RHEL or debian?"
echo "#========================================================================"
OS_CHECK=$(python -c "import platform;print(platform.platform())")
if [ "$OS_CHECK" == "Linux-2.6.32-042stab108.2-x86_64-with-centos-6.7-Final" ]
   then
   		 echo "# 00 - Hmm... CentOS? Must be at work or something...."
         installer="yum"
         system="redhat"
		 yum -y update


elif [ "$OS_CHECK" == "Linux-4.1.7-v7+-armv7l-with-debian-8.0" ]
   then
   		 echo "# 00 - YAY... raspberrypi time"
         installer="apt-get"
         system="debian"
		 if [ ! -f $install_dir/config/$(date "+%Y.%m.%d").update ]
			then
				touch $install_dir/config/$(date "+%Y.%m.%d").update
				apt-get update
				apt-get -y upgrade
		fi

elif [ "$OS_CHECK" == "Linux-4.1.14-v7+-armv7l-with-debian-8.0" ]
   then
   		 echo "# 00 - YAY... raspberrypi time"
         installer="apt-get"
         system="debian"
		 if [ ! -f $install_dir/config/$(date "+%Y.%m.%d").update ]
			then
				touch $install_dir/config/$(date "+%Y.%m.%d").update
				apt-get update
				apt-get -y upgrade
		fi


elif [ "$OS_CHECK" == "Linux-3.13.0-042stab108.7-x86_64-with-Ubuntu-14.04-trusty" ]
   then
   		 echo "# 00 - Hmm... Ubuntu? are you serious?"
         installer="apt-get"
         system="debian"
		 if [ ! -f $install_dir/config/$(date "+%Y.%m.%d").update ]
			then
				touch $install_dir/config/$(date "+%Y.%m.%d").update
				apt-get update
				apt-get -y upgrade
		fi
		 
else 
		 echo "# 00 -  ERROR OS not recognized by install script"
		 exit
fi
echo "#========================================================================"
echo "# 00 - finished basic config and settings"
echo "#========================================================================"
if [ ! -f $install_dir/config/ssmtp.ok ]
     then
echo "#========================================================================"
echo "# 01 - Installing ssmtp"
echo "#========================================================================"
sudo apt-get -y install ssmtp
echo "AuthUser=$mailto" >>  /etc/ssmtp/ssmtp.conf
echo "AuthPass=$mailtopw" >>  /etc/ssmtp/ssmtp.conf
echo "FromLineOverride=YES" >>  /etc/ssmtp/ssmtp.conf
echo "mailhub=$mailtosmtp:587" >>  /etc/ssmtp/ssmtp.conf
echo "UseSTARTTLS=YES" >>  /etc/ssmtp/ssmtp.conf
touch $install_dir/config/ssmtp.ok
else 
echo "#========================================================================"
echo "# 01 - ssmtp already configured"
fi

echo "#========================================================================"
echo "# 01 - Creating backup script"
if [ -f $install_dir/backupscript.sh ]
     then
     echo "# 01 - removing old backupscript.sh"
rm $install_dir/backupscript.sh
fi
cd $install_dir
touch backupscript.sh
chmod 777 -R $install_dir/backupscript.sh
#chown -R $user:$user $install_dir
echo "#!/bin/bash" >> $install_dir/backupscript.sh
echo "#========================================================================       " >> $install_dir/backupscript.sh
echo "sudo bash -c \"dd if=/dev/mmcblk0 | sudo gzip > $backup_destination_dir_unix_mountpoint/\$1.gz\"" >> $install_dir/backupscript.sh
echo "#========================================================================   "
  
echo "# 01 - Mounting shares"
if [ ! -f $install_dir/config/fstab.ok ]
     then
echo "#========================================================================"
echo "# 01 - Writing fstab entries"
echo "#codemagic backup mount" >> /etc/fstab
echo "$backup_destination_dir_cifs_uncformat $backup_destination_dir_unix_mountpoint cifs sec=ntlmssp,$backup_destination_dir_cifs_credentials,user,rw 0 0" >> /etc/fstab
echo "" >> /etc/fstab
cat /etc/fstab
echo "# 01 - Mounting shares"
mkdir $backup_destination_dir_unix_mountpoint
mount -a
touch $install_dir/config/fstab.ok
echo "#========================================================================"
else 
echo "# 01 - fstab already configured"
fi

#Writing backupplan to crontab
if [ ! -f $install_dir/config/crontab.ok ]
     then
echo "#========================================================================"
echo "# 01 - Writing crontabfile"
echo "# codemagic backup" >> /etc/crontab
echo "0 0	* * $backup_interval_days	root	sudo bash -c \"dd if=/dev/mmcblk0 | sudo gzip > $backup_destination_dir_unix_mountpoint/\$(date +%d-%m-%Y).gz\"" >> /etc/crontab
cat /etc/crontab
touch $install_dir/config/crontab.ok
echo "#========================================================================"
else 
echo "# 01 - crontab already configured"
fi

cd $install_dir
if [ ! -f $install_dir/config/java.ok ]
	then
	touch $install_dir/config/java.ok
echo "#========================================================================"
echo "# 02 - Installing Java"
echo "#========================================================================"
apt-get -y install oracle-java7-jdk  
ps -ef | grep java 
java -version
fi
echo "#========================================================================"
echo "# 02 - Installing PHP"
echo "#========================================================================"
apt-get -y install php5 php-pear php5-mysql
echo "#========================================================================"
echo "# 02 - Installing mysql server"
echo "#========================================================================"
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password $mysqlpw'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password $mysqlpw'
sudo apt-get -y install mysql-server
sudo apt-get -y install mysql-server --fix-missing
sudo apt-get -y install mysql-client
echo "#========================================================================"
echo "# 02 - Enabling network access for mysql server"
echo "#========================================================================"
sudo sed -i.bak "s/127.0.0.1/*/g" /etc/mysql/my.cnf
echo "#========================================================================"
echo "# 02 - Installing JDBC for mysql server"
echo "#========================================================================"

	if [ ! -f $install_dir/mysql-connector-java-5.1.38.tar.gz ]
		then
		cd $install_dir
		wget http://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.38.tar.gz
		tar xzvf mysql-connector-java-5.1.38.tar.gz
	fi



echo "#========================================================================"
echo "# 02 -  You need to"
echo "# 02 - GRANT ALL ON *.* to root@'YOUR HOST NAME HERE' IDENTIFIED BY '$mysqlpw';"
echo "#========================================================================"


echo "#========================================================================"
echo "# 02 - Installing tomcat"
echo "#========================================================================"
cd $install_dir
mkdir tomcat
cd tomcat
	if [ ! -f $install_dir/config/downloaded_tomcat.ok ]
     then
	 			if [ ! -f $install_dir/tomcat/apache-tomcat-8.0.29.tar.gz ]
				then
					wget http://www.us.apache.org/dist/tomcat/tomcat-8/v8.0.29/bin/apache-tomcat-8.0.29.tar.gz
				fi
			touch $install_dir/config/downloaded_tomcat.ok
			tar xzf apache-tomcat*
			mv apache-tomcat-8.0.29  apache
			cd apache
			cd conf
			echo "# 02 - Creating Adminuser"
			sed -i.bak "s/<\/tomcat-users>/<user username=\"$tomcatuser\" password=\"$tomcatpw\" roles=\"manager-gui\"\/><\/tomcat-users>/g" tomcat-users.xml
			echo "# 02 - Creating genericWebcam Directory Access Entry"
			sed -i.bak "s/</Host>/			   <Context  docBase=\"/opt/codemagic/genericWebcam\"   path=\"/Piosphere/images\" /></Host>/g" server.xml
			cd ..
			cd ..
	fi
cd apache*
echo "#========================================================================"
echo "# 02 - Starting tomcat"
echo "#========================================================================"
chmod -R 777 /opt/codemagic/tomcat/
bin/startup.sh




if [ "$DHTXX" == "YES" ]
   then
	echo "#========================================================================"
	echo "# 03 - Installing pigpio for DHTXX "
	echo "#========================================================================"
	cd $install_dir
		if [ ! -f $install_dir/PIGPIO/pigpiod ]
				then
				wget abyz.co.uk/rpi/pigpio/pigpio.zip
				unzip pigpio.zip
				mv pigpio.zip $install_dir/PIGPIO
		fi
	cd PIGPIO
	make
	sudo make install
	./pigpiod
	echo "#========================================================================"
	echo "# 03 - Installing pigpio Sample Code for DHTXX "
	echo "#========================================================================"

	if [ ! -f $install_dir/DHTXXD/DHTXXD.zip ]
				then
				mkdir $install_dir/DHTXXD
				cd $install_dir/DHTXXD
					wget http://abyz.co.uk/rpi/pigpio/code/DHTXXD.zip
					unzip DHTXXD.zip
					gcc -Wall -pthread -o DHTXXD test_DHTXXD.c DHTXXD.c -lpigpiod_if2
				fi
	cd $install_dir/DHTXXD



	echo "#========================================================================"
	echo "# 03 - Creating DHTXX Script"
	i=0
		while [ $i -lt $DHTXX_NROFSENSORS ]
			do
			let i=$i+1
			if [ -f $install_dir/DHTXX$i.sh ]
				then
				echo "# 03 - removing old DHTXX$i.sh"
				rm $install_dir/DHTXX$i.sh
			fi
	cd $install_dir
	mkdir triggerTemp
	
	touch DHTXX$i.sh
	chmod 777 -R $install_dir/DHTXX$i.sh
	#chown -R $user:$user $install_dir
	echo "#!/bin/bash" >> $install_dir/DHTXX$i.sh
	echo "#========================================================================       " >> $install_dir/DHTXX$i.sh
	echo "# (c) Marcel Flaig 2015 info@codemagic.net" >> $install_dir/DHTXX$i.sh
	echo "#========================================================================" >> $install_dir/DHTXX$i.sh
	echo "measurement=\$($install_dir/DHTXXD/DHTXXD -g$DHTXX_GPIONR1)" >> $install_dir/DHTXX$i.sh
	echo "date=\$(date \"+%Y.%m.%d-%H.%M.%S\") " >> $install_dir/DHTXX$i.sh
	echo "space=\" \"" >> $install_dir/DHTXX$i.sh
	echo "echo \$date\$space\$measurement >> $install_dir/csv/out_sensor_"$i"_from_\$(date \"+%Y.%m.%d\").csv" >> $install_dir/DHTXX$i.sh
	echo "touch $install_dir/triggerTemp/"$i"_$measurement"
	echo "sleep $DHTXX_Intervall" >> $install_dir/DHTXX$i.sh


	echo "#========================================================================   "
done
	touch 	/etc/profile.d
	echo " export PATH=$PATH:$install_dir/DHTXXD" >>   /etc/profile.d/environment.sh

	 echo " export PATH=$PATH:$install_dir/PIGPIO" >>   /etc/profile.d/environment.sh
	chmod 777 /etc/profile.d/environment.sh


	 
fi





if [ "$genericWebcam" == "YES" ]
   then
echo "#========================================================================"
echo "# 03 - Installing generic webcam with $webcamResultion resolution"
echo "#========================================================================"
	apt-get -y  install fswebcam
		
	if [ -f $install_dir/webcam.sh ]
     then
		echo "# 03 - removing old webcam.sh"
		rm $install_dir/webcam.sh
	fi
	cd $install_dir
	touch webcam.sh

	mkdir $install_dir/genericWebcam
	echo "#!/bin/bash" >> $install_dir/webcam.sh
	echo "#========================================================================       " >> $install_dir/webcam.sh
	echo "# (c) Marcel Flaig 2015 info@codemagic.net" >> $install_dir/webcam.sh
	echo "#========================================================================" >> $install_dir/webcam.sh
	echo "DATE=\$(date +\"%Y-%m-%d_%H%M\")" >> $install_dir/webcam.sh
	echo "fswebcam -r $webcamResultion --no-banner $install_dir/genericWebcam/\$DATE.jpg" >> $install_dir/webcam.sh
fswebcam -r $webcamResultion --no-banner $install_dir/genericWebcam/installation_test.jpg

fi


	if [ ! -f $install_dir/config/installed_energenie.ok ]
     then
		touch $install_dir/config/installed_energenie.ok


if [ "$energenie" == "YES" ]
   then
echo "#========================================================================"
echo "# 03 - Installing energenie $energenie_type"
echo "#========================================================================"

	apt-get -y install libusb-dev
	if [ ! -f $install_dir/config/downloaded_sispm.ok ]
     then
		touch $install_dir/config/downloaded_sispm.ok
	
		cd $install_dir/sispm
				if [ ! -f $install_dir/sispm/sispmctl-3.1.tar.gz ]
				then
				wget http://downloads.sourceforge.net/project/sispmctl/sispmctl/sispmctl-3.1/sispmctl-3.1.tar.gz
				fi
		sleep 30
		tar xzvf sispm*.tar.gz
	fi
	cd $install_dir/sispm
	cd sispm*
	./configure
	make
	sudo make install

	echo "#========================================================================"
	echo "# 03 - $energenie_type installed"
	echo "#========================================================================"

	sispmctl -g 1
	sispmctl -g 2
	sispmctl -g 3
	sispmctl -g 4
	
	if [ "$energenie_startwebinterface" == "YES" ]
		then
			echo "# starting webinterface"
			sudo sispmctl -i 0.0.0.0 -p 8989 -l
	fi
	
	
echo "#========================================================================"
echo "# 03 - Creating energenie script"
if [ -f $install_dir/energenie.sh ]
     then
     echo "# 3 - removing old energenie.sh"
rm $install_dir/energenie.sh
fi
cd $install_dir
touch energenie.sh
chmod 777 -R $install_dir/energenie.sh
echo "#!/bin/bash" >> $install_dir/energenie.sh
echo "#========================================================================       " >> $install_dir/energenie.sh
echo "sudo sispmctl -\$2 \$1" >> $install_dir/energenie.sh
echo "#========================================================================   "
	
fi

fi


if [ ! -f $install_dir/config/wiki.ok ]
	then
	touch $install_dir/config/wiki.ok


echo "#========================================================================"
echo "# 04 - Installing $projectname-Wiki"
echo "#========================================================================"
echo "# 04 - Installing apache2 webserver"
apt-get -y install apache2
service apache2 restart
echo "# 04 - Installing PHP alternative cache"
apt-get -y install php-apc
echo "# 04 - Installing gdlibrary (for wiki thumbnails)"
apt-get -y install php5-gd
php5 -i | grep -i --color gd
echo "# 04 - Installing PHP PECL for standardization"
apt-get -y install php-pear
apt-get -y install php5-dev
apt-get -y install libcurl3-openssl-dev
echo "# 04 - Installing intl PECL Module..."
apt-get -y install php5-intl
apt-get -y install libicu-dev
service apache2 restart
echo -e "\n" | /usr/bin/pecl install intl
#sudo pecl install pecl_http
echo "Wiki Admin is sysadm PW 1$sy>s4a5d6/m77."


echo "# 04 - Installing $projectname-Wiki - www"
	mkdir $install_dir/wiki
	cd 	$install_dir/wiki
		if [ ! -f $install_dir/wiki/mediawiki-1.26.1.tar.gz ]
				then
		wget https://releases.wikimedia.org/mediawiki/1.26/mediawiki-1.26.1.tar.gz
		sleep 60
		tar xzvf media*.tar.gz
		mv mediawiki-1.26.1 wiki 
		mv wiki /var/www/html/wiki
		fi
echo "#========================================================================"
echo "# 04 - Installing $projectname-Wiki - DB"
if [ ! -f $install_dir/wiki/reset_mysqlpw.sql ]
	then
		/etc/init.d/mysql stop
		cd $install_dir/wiki
		touch reset_mysqlpw.sql
		# Reset MySQL PW
		sudo /usr/sbin/mysqld --skip-grant-tables --skip-networking &
				echo "FLUSH PRIVILEGES;" >> $install_dir/wiki/reset_mysqlpw.sql
				echo "SET PASSWORD FOR root@\'localhost\' = PASSWORD(\'$mysqlpw\');" >> $install_dir/wiki/reset_mysqlpw.sql
				echo "FLUSH PRIVILEGES;" >> $install_dir/wiki/reset_mysqlpw.sql
		mysql -u root < reset_mysqlpw.sql
		sudo /etc/init.d/mysql stop
		sudo /etc/init.d/mysql start
		cd $install_dir/wiki
		touch wikidb.sql
			echo "create database wikidb;" >> $install_dir/wiki/wikidb.sql
			echo " grant index, create, select, insert, update, delete, drop, alter, lock tables on wikidb.* to '$wikiuser'@\'localhost\' identified by '$wikipassword';" >> $install_dir/wiki/wikidb.sql
		mysql -u root -p $mysqlpw < wikidb.sql
fi


		
echo "#========================================================================"
echo "# 04 - Installing $projectname-Wiki - Sync"		
echo "# 04 - TODO - SRY - Installing $projectname-Wiki - Sync"	
fi		
		
		
echo "#========================================================================"
echo "# 04 - Installing automatic startup scripts"			
if [ ! -f /etc/init.d/tomcat ]
	then
	

	
touch /etc/init.d/tomcat	
echo "#! /bin/sh" >> /etc/init.d/tomcat
echo "/opt/codemagic/tomcat/apache/bin/startup.sh" >> /etc/init.d/tomcat
touch /etc/init.d/pigpio
echo "#! /bin/sh" >> /etc/init.d/pigpio
echo "pigpiod" >> /etc/init.d/pigpio
touch /etc/init.d/codemagic_mount
echo "#! /bin/sh" >> /etc/init.d/codemagic_mount
echo "mount -a" >> /etc/init.d/codemagic_mount

chkconfig --add tomcat
chkconfig tomcat on
chkconfig --list tomcat
chkconfig --add pigpio
chkconfig pigpio on
chkconfig --list pigpio
chkconfig --add codemagic_mount
chkconfig codemagic_mount on
chkconfig --list codemagic_mount
sudo chmod 777 /etc/init.d/tomcat
sudo chmod 777 /etc/init.d/pigpio
sudo chmod 777 /etc/init.d/codemagic_mount
	fi	
		
		
		
echo "#========================================================================"
echo "# 05 - Creating csv archive for $projectname"
echo "#========================================================================"
cd $install_dir
mkdir csv
echo "#========================================================================"
echo "# 05 - Creating crontab entry for project cronjobs for $projectname"
echo "#========================================================================"
echo "# 05 - Script will be called every minute - Project Cronjobs are inside this script"



if [ ! -f $install_dir/cron/myCron.sh ]
	then
		cd $install_dir
        mkdir cron
	touch $install_dir/cron/myCron.sh
	chmod 777 $install_dir/cron/myCron.sh
echo "* *	* * *	root	sudo $install_dir/cron/myCron.sh" >> /etc/crontab
cat /etc/crontab
echo "#!/bin/bash" >> $install_dir/cron/myCron.sh



fi



echo "#========================================================================"
echo "# 06 - Creating $projectname database and basic settings"
echo "#========================================================================"
echo "# 06 - Creating SQL File"
cd $install_dir/config
if [ ! -f $install_dir/config/installme.sql ]
	then
	touch $install_dir/config/installme.sql

echo "CREATE SCHEMA \`piosphere\` ;" >> $install_dir/config/installme.sql 
#echo "DROP TABLE \`piosphere\`.\`basic_settings\`; " >> $install_dir/config/installme.sql 
echo "#========================================================================"
echo "# 06 - Schema written, Writing tables..."
echo "#========================================================================"
echo "CREATE TABLE \`piosphere\`.\`basic_settings\` (" >> $install_dir/config/installme.sql 
echo "  \`basic_setting\` VARCHAR(100) NOT NULL DEFAULT '-' COMMENT ''," >> $install_dir/config/installme.sql 
echo "  \`basic_setting_value\` VARCHAR(300) NULL COMMENT ''," >> $install_dir/config/installme.sql 
echo "  \`basic_settings_id\` INT NOT NULL DEFAULT 1 COMMENT ''," >> $install_dir/config/installme.sql 
echo "  \`basic_setting_comment\` VARCHAR(500) NULL COMMENT ''," >> $install_dir/config/installme.sql 
echo "  PRIMARY KEY (\`basic_settings_id\`)  COMMENT ''," >> $install_dir/config/installme.sql 
echo "  UNIQUE INDEX \`basic_setting_UNIQUE\` (\`basic_setting\` ASC)  COMMENT '');" >> $install_dir/config/installme.sql 
echo "#========================================================================"
echo "  CREATE TABLE \`piosphere\`.\`time_jobs\` (" >> $install_dir/config/installme.sql 
echo "  \`id\` INT NOT NULL DEFAULT 1 COMMENT ''," >> $install_dir/config/installme.sql 
echo "  \`name\` VARCHAR(200) NULL COMMENT ''," >> $install_dir/config/installme.sql 
echo "  \`content\` VARCHAR(200) NULL COMMENT ''," >> $install_dir/config/installme.sql 
echo "  \`crontab_output\` VARCHAR(200) NULL COMMENT ''," >> $install_dir/config/installme.sql 
echo "  \`atTime\` VARCHAR(45) NULL DEFAULT 'Do a job at a specific time' COMMENT ''," >> $install_dir/config/installme.sql 
echo "  \`everyTimeMinutes\` VARCHAR(45) NULL DEFAULT 'Do a job every x minutes' COMMENT ''," >> $install_dir/config/installme.sql 
echo "  \`triggerOnOrOff\` VARCHAR(10) NULL COMMENT ''," >> $install_dir/config/installme.sql 
echo "  \`socketNumber\` VARCHAR(10) NULL COMMENT ''," >> $install_dir/config/installme.sql 
echo "  PRIMARY KEY (\`id\`)  COMMENT ''," >> $install_dir/config/installme.sql 
echo "  UNIQUE INDEX \`time_job_name_UNIQUE\` (\`name\` ASC)  COMMENT '');" >> $install_dir/config/installme.sql 
echo "#========================================================================"
echo "  CREATE TABLE \`piosphere\`.\`sensor_jobs\` (" >> $install_dir/config/installme.sql 
echo "  \`id\` INT NOT NULL DEFAULT 1 COMMENT ''," >> $install_dir/config/installme.sql 
echo "  \`name\` VARCHAR(200) NULL COMMENT ''," >> $install_dir/config/installme.sql 
echo "  \`content\` VARCHAR(200) NULL COMMENT ''," >> $install_dir/config/installme.sql 
echo "  \`crontab_output\` VARCHAR(200) NULL COMMENT ''," >> $install_dir/config/installme.sql 
echo "  \`whichSensor\` VARCHAR(45) NULL DEFAULT 'whichSensor' COMMENT ''," >> $install_dir/config/installme.sql 
echo "  \`belowOrAbove\` VARCHAR(45) NULL DEFAULT 'trigger when below or when above' COMMENT ''," >> $install_dir/config/installme.sql 
echo "  \`sensorValue\` VARCHAR(45) NULL DEFAULT 'Value when to trigger' ''," >> $install_dir/config/installme.sql 
echo "  \`triggerOnOrOff\` VARCHAR(10) NULL COMMENT ''," >> $install_dir/config/installme.sql 
echo "  \`socketNumber\` VARCHAR(10) NULL COMMENT ''," >> $install_dir/config/installme.sql 
echo "  PRIMARY KEY (\`id\` )  COMMENT ''," >> $install_dir/config/installme.sql 
echo "  UNIQUE INDEX \`sensor_job_name_UNIQUE\` (\`name\` ASC)  COMMENT '');" >> $install_dir/config/installme.sql 
echo "#========================================================================"
echo "    CREATE TABLE \`piosphere\`.\`mailto_jobs\` (" >> $install_dir/config/installme.sql 
echo "  \`id\` INT NOT NULL DEFAULT 1 COMMENT ''," >> $install_dir/config/installme.sql 
echo "  \`name\` VARCHAR(200) NULL COMMENT ''," >> $install_dir/config/installme.sql 
echo "  \`content\` VARCHAR(200) NULL COMMENT ''," >> $install_dir/config/installme.sql 
echo "  \`crontab_output\` VARCHAR(200) NULL COMMENT ''," >> $install_dir/config/installme.sql 
echo "  \`whichSensor\` VARCHAR(45) NULL DEFAULT 'whichSensor' COMMENT ''," >> $install_dir/config/installme.sql 
echo "  \`belowOrAbove\` VARCHAR(45) NULL DEFAULT 'trigger when below or when above' COMMENT ''," >> $install_dir/config/installme.sql 
echo "  \`sensorValue\` VARCHAR(45) NULL DEFAULT 'Value when to trigger' ''," >> $install_dir/config/installme.sql 
echo "  \`mailto\` VARCHAR(10) NULL COMMENT ''," >> $install_dir/config/installme.sql   
echo "  \`mail_text\` VARCHAR(10) NULL COMMENT ''," >> $install_dir/config/installme.sql   
echo "  PRIMARY KEY (\`id\` )  COMMENT ''," >> $install_dir/config/installme.sql   
echo "  UNIQUE INDEX \`sensor_job_name_UNIQUE\` (\`name\` ASC)  COMMENT '');" >> $install_dir/config/installme.sql   
echo "#========================================================================"
#echo "  DROP TABLE \`piosphere\`.\`user_config\`;" >> $install_dir/config/installme.sql   
echo "  CREATE TABLE \`piosphere\`.\`user_config\` (" >> $install_dir/config/installme.sql   
echo "    \`id\` INT NOT NULL DEFAULT 1 COMMENT ''," >> $install_dir/config/installme.sql   
echo "    \`name\` VARCHAR(200) NULL COMMENT ''," >> $install_dir/config/installme.sql   
echo "    \`content\` VARCHAR(200) NULL COMMENT ''," >> $install_dir/config/installme.sql   
echo "    \`comment\` VARCHAR(200) NULL COMMENT ''," >> $install_dir/config/installme.sql    
echo "    PRIMARY KEY (\`id\` )  COMMENT ''," >> $install_dir/config/installme.sql   
echo "    UNIQUE INDEX \`user_config_name_UNIQUE\` (\`name\` ASC)  COMMENT '');" >> $install_dir/config/installme.sql   
echo "    ALTER TABLE \`piosphere\`.\`user_config\` " >> $install_dir/config/installme.sql
echo "    CHANGE COLUMN \`id\` \`id\` INT(11) NOT NULL AUTO_INCREMENT COMMENT '' ;" >> $install_dir/config/installme.sql
echo "#========================================================================" 
echo "# 06 - Tables written writing basic settings"
echo "#========================================================================"
echo "INSERT INTO \`piosphere\`.\`basic_settings\` (\`basic_settings_id\`, \`basic_setting\`, \`basic_setting_value\`, \`basic_setting_comment\`) VALUES ('2', 'user', '$user', 'used for OS');" >> $install_dir/config/installme.sql 
echo "INSERT INTO \`piosphere\`.\`basic_settings\` (\`basic_settings_id\`, \`basic_setting\`, \`basic_setting_value\`) VALUES ('3', 'password', '$password');" >> $install_dir/config/installme.sql 
echo "INSERT INTO \`piosphere\`.\`basic_settings\` (\`basic_settings_id\`, \`basic_setting\`, \`basic_setting_value\`) VALUES ('4', 'mailto', '$mailto');" >> $install_dir/config/installme.sql 
echo "INSERT INTO \`piosphere\`.\`basic_settings\` (\`basic_settings_id\`, \`basic_setting\`, \`basic_setting_value\`) VALUES ('5', 'mailtopw', '$mailtopw');" >> $install_dir/config/installme.sql 
echo "INSERT INTO \`piosphere\`.\`basic_settings\` (\`basic_settings_id\`, \`basic_setting\`, \`basic_setting_value\`) VALUES ('6', 'install_dir', '$install_dir');" >> $install_dir/config/installme.sql 
echo "INSERT INTO \`piosphere\`.\`basic_settings\` (\`basic_settings_id\`, \`basic_setting\`, \`basic_setting_value\`) VALUES ('7', 'backup_destination_dir_unix_mountpoint', '$backup_destination_dir_unix_mountpoint');" >> $install_dir/config/installme.sql 
echo "INSERT INTO \`piosphere\`.\`basic_settings\` (\`basic_settings_id\`, \`basic_setting\`, \`basic_setting_value\`) VALUES ('8', 'backup_destination_dir_cifs_uncformat', '$backup_destination_dir_cifs_uncformat');" >> $install_dir/config/installme.sql 
echo "INSERT INTO \`piosphere\`.\`basic_settings\` (\`basic_settings_id\`, \`basic_setting\`, \`basic_setting_value\`) VALUES ('9', 'backup_destination_dir_cifs_credentials', '$backup_destination_dir_cifs_credentials');" >> $install_dir/config/installme.sql 
echo "INSERT INTO \`piosphere\`.\`basic_settings\` (\`basic_settings_id\`, \`basic_setting\`, \`basic_setting_value\`) VALUES ('11', 'mysqlpw', '$password');" >> $install_dir/config/installme.sql 
echo "INSERT INTO \`piosphere\`.\`basic_settings\` (\`basic_settings_id\`, \`basic_setting\`, \`basic_setting_value\`) VALUES ('12', 'tomcatpw', '$password');" >> $install_dir/config/installme.sql 
echo "INSERT INTO \`piosphere\`.\`basic_settings\` (\`basic_settings_id\`, \`basic_setting\`, \`basic_setting_value\`) VALUES ('13', 'tomcatuser', '$user');" >> $install_dir/config/installme.sql 
echo "INSERT INTO \`piosphere\`.\`basic_settings\` (\`basic_settings_id\`, \`basic_setting\`, \`basic_setting_value\`) VALUES ('14', 'wikipassword', '$password');" >> $install_dir/config/installme.sql 
echo "INSERT INTO \`piosphere\`.\`basic_settings\` (\`basic_settings_id\`, \`basic_setting\`, \`basic_setting_value\`) VALUES ('15', 'wikiuser', '$user');" >> $install_dir/config/installme.sql 
echo "INSERT INTO \`piosphere\`.\`basic_settings\` (\`basic_settings_id\`, \`basic_setting\`, \`basic_setting_value\`) VALUES ('16', 'projectname', '$projectname');" >> $install_dir/config/installme.sql 
echo "INSERT INTO \`piosphere\`.\`basic_settings\` (\`basic_settings_id\`, \`basic_setting\`, \`basic_setting_value\`) VALUES ('17', 'energenie', '$energenie');" >> $install_dir/config/installme.sql 
echo "INSERT INTO \`piosphere\`.\`basic_settings\` (\`basic_settings_id\`, \`basic_setting\`, \`basic_setting_value\`) VALUES ('18', 'energenie_type', '$energenie_type');" >> $install_dir/config/installme.sql 
echo "INSERT INTO \`piosphere\`.\`basic_settings\` (\`basic_settings_id\`, \`basic_setting\`, \`basic_setting_value\`) VALUES ('19', 'energenie_startwebinterface', '$energenie_startwebinterface');" >> $install_dir/config/installme.sql 
echo "INSERT INTO \`piosphere\`.\`basic_settings\` (\`basic_settings_id\`, \`basic_setting\`, \`basic_setting_value\`) VALUES ('20', 'DHTXX', '$DHTXX');" >> $install_dir/config/installme.sql 
echo "INSERT INTO \`piosphere\`.\`basic_settings\` (\`basic_settings_id\`, \`basic_setting\`, \`basic_setting_value\`) VALUES ('21', 'DHTXX_NROFSENSORS', '$DHTXX_NROFSENSORS');" >> $install_dir/config/installme.sql 
echo "INSERT INTO \`piosphere\`.\`basic_settings\` (\`basic_settings_id\`, \`basic_setting\`, \`basic_setting_value\`) VALUES ('22', 'DHTXX_GPIONR1', '$DHTXX_GPIONR1');" >> $install_dir/config/installme.sql 
echo "INSERT INTO \`piosphere\`.\`basic_settings\` (\`basic_settings_id\`, \`basic_setting\`, \`basic_setting_value\`) VALUES ('23', 'DHTXX_GPIONR2', '$DHTXX_GPIONR2');" >> $install_dir/config/installme.sql 
echo "INSERT INTO \`piosphere\`.\`basic_settings\` (\`basic_settings_id\`, \`basic_setting\`, \`basic_setting_value\`, \`basic_setting_comment\`) VALUES ('24', 'DHTXX_Intervall', '$DHTXX_Intervall', 'Settings below 30 seconds can damage the sensor');" >> $install_dir/config/installme.sql 
echo "INSERT INTO \`piosphere\`.\`basic_settings\` (\`basic_settings_id\`, \`basic_setting\`, \`basic_setting_value\`) VALUES ('25', 'webcamResultion', '$webcamResultion');" >> $install_dir/config/installme.sql 
echo "INSERT INTO \`piosphere\`.\`basic_settings\` (\`basic_settings_id\`, \`basic_setting\`, \`basic_setting_value\`) VALUES ('26', 'genericWebcam', '$genericWebcam');" >> $install_dir/config/installme.sql 
echo "INSERT INTO \`piosphere\`.\`basic_settings\` (\`basic_settings_id\`, \`basic_setting\`, \`basic_setting_value\`) VALUES ('1', 'mailtosmtp', '$mailtosmtp');" >> $install_dir/config/installme.sql 
echo "#========================================================================" 
echo "# 06 - Basic settings written - writing user config"
echo "#========================================================================"
echo "INSERT INTO \`piosphere\`.\`user_config\` (\`name\`, \`content\`) VALUES ('Enable generic webcam', '$genericWebcam');" >> $install_dir/config/installme.sql 
echo "INSERT INTO \`piosphere\`.\`user_config\` (\`name\`, \`content\`) VALUES ('Generic webcam resolution', '$webcamResultion');" >> $install_dir/config/installme.sql 
echo "INSERT INTO \`piosphere\`.\`user_config\` (\`name\`, \`content\`) VALUES ('Record timelapse', '$webcamTimelapse');" >> $install_dir/config/installme.sql 
echo "INSERT INTO \`piosphere\`.\`user_config\` (\`name\`, \`content\`) VALUES ('Enable DHTXX sensor', '$DHTXX');" >> $install_dir/config/installme.sql 
echo "INSERT INTO \`piosphere\`.\`user_config\` (\`name\`, \`content\`) VALUES ('Enable energenie / sispm device', '$energenie');" >> $install_dir/config/installme.sql 
echo "INSERT INTO \`piosphere\`.\`user_config\` (\`name\`, \`content\`) VALUES ('Enable light dependent resistors', '$useLDR');" >> $install_dir/config/installme.sql 
echo "INSERT INTO \`piosphere\`.\`user_config\` (\`name\`, \`content\`) VALUES ('Phone home and share', '$phone_home');" >> $install_dir/config/installme.sql 
echo "INSERT INTO \`piosphere\`.\`user_config\` (\`name\`, \`content\`) VALUES ('Enable Media Wiki	', '$enable_media_wiki');" >> $install_dir/config/installme.sql 
echo "INSERT INTO \`piosphere\`.\`user_config\` (\`name\`, \`content\`) VALUES ('Archive into MySQL DB', '$enable_mysql_archive');" >> $install_dir/config/installme.sql 
echo "INSERT INTO \`piosphere\`.\`user_config\` (\`name\`, \`content\`) VALUES ('Enable regular backup', '$enable_backup');" >> $install_dir/config/installme.sql 
echo "INSERT INTO \`piosphere\`.\`user_config\` (\`name\`, \`content\`) VALUES ('Enable e-mail notification', '$enable_mail');" >> $install_dir/config/installme.sql 
echo "INSERT INTO \`piosphere\`.\`user_config\` (\`name\`, \`content\`) VALUES ('Timelapse time in minutes', '$webcamTimelapseTimeInMinutes');" >> $install_dir/config/installme.sql 
echo "INSERT INTO \`piosphere\`.\`user_config\` (\`name\`, \`content\`) VALUES ('Number of DHTXX sensors	', '$DHTXX_NROFSENSORS');" >> $install_dir/config/installme.sql 
echo "INSERT INTO \`piosphere\`.\`user_config\` (\`name\`, \`content\`) VALUES ('GPIO Numbers DHTXX connected to', '$DHTXX_GPIONR1,$DHTXX_GPIONR2');" >> $install_dir/config/installme.sql 
echo "INSERT INTO \`piosphere\`.\`user_config\` (\`name\`, \`content\`) VALUES ('Number of LDR sensors', '$number_Of_LDR_Sensors');" >> $install_dir/config/installme.sql 
echo "INSERT INTO \`piosphere\`.\`user_config\` (\`name\`, \`content\`) VALUES ('GPIO Numbers LDRs connected to', '$LDR_GPIONRS');" >> $install_dir/config/installme.sql 
echo "INSERT INTO \`piosphere\`.\`user_config\` (\`name\`, \`content\`) VALUES ('Number of energenie / sispm device slots', '$energenie_sockets');" >> $install_dir/config/installme.sql 
echo "INSERT INTO \`piosphere\`.\`user_config\` (\`name\`, \`content\`) VALUES ('Name of devices connected to sispm device', '$energenie_device_names');" >> $install_dir/config/installme.sql 
echo "INSERT INTO \`piosphere\`.\`user_config\` (\`name\`, \`content\`) VALUES ('Notification mailto', '$mailto');" >> $install_dir/config/installme.sql 
echo "INSERT INTO \`piosphere\`.\`user_config\` (\`name\`, \`content\`) VALUES ('Backupdir', '$backup_destination_dir_cifs_uncformat');" >> $install_dir/config/installme.sql 
echo "INSERT INTO \`piosphere\`.\`user_config\` (\`name\`, \`content\`) VALUES ('Name of LDR sensors', '$name_Of_LDR_Sensors');" >> $install_dir/config/installme.sql 
echo "INSERT INTO \`piosphere\`.\`user_config\` (\`name\`, \`content\`) VALUES ('Name of DHTXX sensors', '$DHTXX_Names');" >> $install_dir/config/installme.sql 
echo "INSERT INTO \`piosphere\`.\`user_config\` (\`name\`, \`content\`) VALUES ('Name of temperature sensors', '$Temp_Names');" >> $install_dir/config/installme.sql 

echo "#========================================================================" 
echo "# 06 - SQL File written - applying SQL FILE"
echo "#========================================================================"
mysql -u root -p$password< $install_dir/config/installme.sql 


fi



  
#TODO
sudo chown -R pi:pi /opt/codemagic/
sudo chmod -R 777 /opt/codemagic/
		

if [ ! -f $install_dir/config/initialbackup.ok ]
     then
echo "#========================================================================"
echo "# 99 - Creating initial backup"
sudo bash -c "dd if=/dev/mmcblk0 | sudo gzip > $backup_destination_dir_unix_mountpoint/initial.gz"
echo "#========================================================================"
touch $install_dir/config/initialbackup.ok
else
echo "#========================================================================"
echo "# 99 - initial backup already created"
fi



echo "#========================================================================"
echo "# 99 - cleanup - Remove File because of cleartext password logged - restart services - mail result"
echo "#========================================================================"
echo "#========================================================================"
echo "# 99 - following stderrors were detected:"
echo "#========================================================================"
cd $working_dir
cat err.log



echo "#========================================================================"
echo "# 99 - sending log via mail"
echo "#========================================================================"

cd $working_dir
echo $working_dir/$logfile 
ssmtp $mailto < $working_dir/$logfile 



if [ -f $working_dir/$logfile ]
     then
	 sleep 10
rm $working_dir/$logfile 
fi

if [ -f $working_dir/err.log ]
     then
	 sleep 10
rm $working_dir/err.log
fi

cd $working_dir

echo "#========================================================================"
echo "# 99 - Installation finished - have a nice day"
echo "# 99 - rebooting in 120 seconds"
echo "#========================================================================"
sleep 120
#reboot