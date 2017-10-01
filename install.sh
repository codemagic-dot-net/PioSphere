#!/bin/bash
#========================================================================
# (c) Marcel Flaig 2015 info@codemagic.net
# Run this Script with ./install.sh username_forservice password_for_this_user 
# example sudo ./install.sh piconfig '!e$m%p(e)ror_1n2o3r4t5on'
#========================================================================
# Short Description: 
# Creates and installs backup script and schedules backup in crontab
# adds ssmtp for sending mails
# mounts cifs share
#========================================================================
# Required Files:
# None
#========================================================================
# Required Setup:
# raspbian, shell logon, wlan, windows share, email account , 		 sudo rpi-update && sudo reboot
#========================================================================
# CONFIG SECTION 
#========================================================================
working_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
user=$1
password=$2
mailto="info@codemagic.net"
mailtopw="topsecret"
mailtosmtp="smtp.2und3.de"
logfile=install.log
backup_destination_dir_unix_mountpoint="/opt/codemagic/backups"
backup_destination_dir_cifs_uncformat="//DESKTOP-9FBVUKM/PiBackup"
#backup_destination_dir_cifs_credentials="domain=it,user=avweb,password=Tropnd5!"
backup_destination_dir_cifs_credentials="user=pibackup,password=pibackup"
backup_script_install_dir="/opt/codemagic"
#backup_interval_days="*"
backup_interval_days="3"
######################################################################################################


#Prerequisites start: delete old log , create new log, check if root, create service user, update yum Packages
echo "#========================================================================"
echo " 0 - Script is running from $working_dir"
if [ -f $working_dir/$logfile ]
     then
     echo "removing old logfile"
rm $logfile
fi
echo "Creating new Logfile"
exec > >(tee $logfile)
echo "To: info@codemagic.net"
echo "From: installer@codemagic.net"
echo "Subject: installationlog"
echo "#========================================================================"
echo "# 0 - Setup extra service account:"
echo "#========================================================================"
echo "checking if user is root"
if [ "$(whoami)" != "root" ]
then
     sudo su -s "$0"
     exit
fi
echo "#========================================================================"
echo "# 0 - $user with the password $password will be created"
useradd -m $user
echo -e "$password\n$password\n" | passwd $user
echo "# 0 - Create Group called $user"
groupadd $user
useradd -G $user $user
echo "#========================================================================"
echo "# 0 - Getting prerequisites: running on a RHEL or debian?"
echo "#========================================================================"
OS_CHECK=$(python -c "import platform;print(platform.platform())")
if [ "$OS_CHECK" == "Linux-2.6.32-042stab108.2-x86_64-with-centos-6.7-Final" ]
   then
   		 echo "# 0 - Hmm... CentOS? Must be at work or something...."
         installer="yum"
         system="redhat"
		 yum -y update

fi
if [ "$OS_CHECK" == "Linux-4.1.7-v7+-armv7l-with-debian-8.0" ]
   then
   		 echo "# 0 - YAY... raspberrypi time"
         installer="apt-get"
         system="debian"
		 apt-get update
		 apt-get -y upgrade
fi
if [ "$OS_CHECK" == "Linux-3.13.0-042stab108.7-x86_64-with-Ubuntu-14.04-trusty" ]
   then
   		 echo "# 0 - Hmm... Ubuntu? are you serious?"
         installer="apt-get"
         system="debian"
		 apt-get update
		 apt-get -y upgrade
fi
echo "#========================================================================"
echo "# Installing ssmtp"
sudo apt-get install ssmtp
echo "AuthUser=$mailto" >>  /etc/ssmtp/ssmtp.conf
echo "AuthPass=$mailtopw" >>  /etc/ssmtp/ssmtp.conf
echo "FromLineOverride=YES" >>  /etc/ssmtp/ssmtp.conf
echo "mailhub=$mailtosmtp:587" >>  /etc/ssmtp/ssmtp.conf
echo "UseSTARTTLS=YES" >>  /etc/ssmtp/ssmtp.conf

echo "#========================================================================"
echo "# Creating backup script"
mkdir $backup_script_install_dir
cd $backup_script_install_dir
touch backupscript.sh
chmod 770 -R $backup_script_install_dir/backupscript.sh
chown -R $user:$user $backup_script_install_dir

echo "#!/bin/bash" >> $backup_script_install_dir/backupscript.sh
echo "#========================================================================       " >> $backup_script_install_dir/backupscript.sh
echo "sudo bash -c \"dd if=/dev/mmcblk0 | sudo gzip > $backup_destination_dir_unix_mountpoint/\$1.gz\"" >> $backup_script_install_dir/backupscript.sh



  
#Mounting shares
echo "#========================================================================"
echo "Writing fstab entries"
echo "$backup_destination_dir_cifs_uncformat $backup_destination_dir_unix_mountpoint cifs sec=ntlmssp,$backup_destination_dir_cifs_credentials,user,rw 0 0" >> /etc/fstab
echo "" >> /etc/fstab
cat /etc/fstab
echo "# Mounting shares"
mkdir $backup_destination_dir_unix_mountpoint
mount -a
echo "#========================================================================"


#Writing backupplan to crontab
echo "#========================================================================"
echo "# Writing crontabfile"
echo "0 0	* * $backup_interval_days	root	sudo bash -c \"dd if=/dev/mmcblk0 | sudo gzip > $backup_destination_dir_unix_mountpoint/\$(date +%d-%m-%Y).gz\"" >> /etc/crontab
cat /etc/crontab
echo "#========================================================================"


echo "#========================================================================"
echo "# Creating initial backup"
sudo bash -c "dd if=/dev/mmcblk0 | sudo gzip > $backup_destination_dir_unix_mountpoint/initial.gz"
echo "#========================================================================"


echo "#========================================================================"
echo "#- cleanup - Remove File because of cleartext password logged - restart services - mail result"
echo "#========================================================================"



echo "#========================================================================"
echo "sending log via mail"
echo "#========================================================================"
cd $working_dir
#mail -s "$logfile" $mailto < $$logfile
ssmtp $mailto < $working_dir/$logfile 
if [ -f $working_dir/$logfile ]
     then
rm $logfile
fi
echo "#========================================================================"
echo "Installation finished - have a nice day"
echo "#========================================================================"