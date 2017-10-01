#!/bin/bash
#========================================================================       
# (c) Marcel Flaig 2015 info@codemagic.net
#========================================================================
DATE=$(date +"%Y-%m-%d_%H%M")
fswebcam -r 640x480 --no-banner /opt/codemagic/genericWebcam/$DATE.jpg
