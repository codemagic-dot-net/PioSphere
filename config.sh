#!/bin/bash
#========================================================================
# (c) Marcel Flaig 2015 info@codemagic.net
echo "#========================================================================"
echo "# 00 - starting config"
echo "#========================================================================"
# Basic Setup
#========================================================================
user="pi"
password="victualia"
mailto="piosphere@codemagic.net"
mailtopw="nicetry"
mailtosmtp="smtp.2und3.de"
install_dir="/opt/codemagic"
phone_home="YES"
#========================================================================
# Backup Setup
#========================================================================
enable_backup="YES"
backup_destination_dir_unix_mountpoint="/opt/codemagic/backups"
backup_destination_dir_cifs_uncformat="//DESKTOP-9FBVUKM/PiBackup"
#backup_destination_dir_cifs_credentials="domain=it,user=avweb,password=Tropnd5!"
backup_destination_dir_cifs_credentials="user=pibackup,password=pibackup"
#backup_interval_days="*"
backup_interval_days="3"
#========================================================================
# Energenie Powersocket Setup
#========================================================================
energenie="YES"
energenie_type="EG-PMS2"
energenie_startwebinterface="NO"
energenie_sockets="4"
energenie_device_names="ventilator,surface_heating,lighting,pump"
#========================================================================
# DHTXX Temperature / humidty sensor Setup
#========================================================================
# Set DHTXX to YES if you are using DHTXX or DHTXX Sensor
DHTXX="YES"
#Set total number of sensors connected to the gpio board
DHTXX_NROFSENSORS="2"
#Set number of GPIO that is used for the sensor
DHTXX_GPIONR1="04"
DHTXX_GPIONR2="07"
DHTXX_Names="großer,kleiner"
Temp_Names="wasser_großer,wasser_kleiner"
#========================================================================
# Generic Webcam Setup
#========================================================================
genericWebcam="YES"
webcamTimelapse="YES"
webcamTimelapseTimeInMinutes="30"
webcamResultion=640x480
#========================================================================
# LDR Setup
#========================================================================
useLDR="YES"
number_Of_LDR_Sensors="2"
name_Of_LDR_Sensors="großer,kleiner"
LDR_GPIONRS="4,7"
#========================================================================
#========================================================================
#========================================================================
#========================================================================
#========================================================================
#========================================================================

#========================================================================
# System Settings - do not change
#========================================================================
projectname="piosphere"
# MySQL Setup
mysqlpw=$password
# tomcat Setup
tomcatpw=$password
tomcatuser=$user
# wiki Setup
wikipassword=$password
wikiuser=$user
#Setting in seconds,a setting below 30 seconds can damage the sensor
DHTXX_Intervall="30"
enable_media_wiki="YES"
enable_mysql_archive="YES"
enable_mail="YES"
#========================================================================
# Debugging Zone
#========================================================================
echo "#========================================================================"
echo "# 00 - config end"
echo "#========================================================================"



