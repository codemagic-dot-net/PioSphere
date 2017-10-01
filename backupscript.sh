#!/bin/bash
#========================================================================       
sudo bash -c "dd if=/dev/mmcblk0 | sudo gzip > /opt/codemagic/backups/$1.gz"
