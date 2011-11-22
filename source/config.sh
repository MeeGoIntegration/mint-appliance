#!/bin/bash
#================
# FILE          : config.sh
#----------------
# PROJECT       : OpenSuSE KIWI Image System
# COPYRIGHT     : (c) 2006 SUSE LINUX Products GmbH. All rights reserved
#               :
# AUTHOR        : Marcus Schaefer <ms@suse.de>
#               :
# BELONGS TO    : Operating System images
#               :
# DESCRIPTION   : configuration script for SUSE based
#               : operating systems
#               :
#               :
# STATUS        : BETA
#----------------
#======================================
# Functions...
#--------------------------------------
test -f /.kconfig && . /.kconfig
test -f /.profile && . /.profile

#======================================
# Greeting...
#--------------------------------------
echo "Configure image: [$name]..."

#======================================
# SuSEconfig
#--------------------------------------
echo "** Running suseConfig..."
suseConfig

echo "** Running ldconfig..."
/sbin/ldconfig

sed --in-place -e 's/icewm/icewm-session/' /usr/bin/wmlist

#======================================
# RPM GPG Keys Configuration
#--------------------------------------
echo '** Importing GPG Keys...'
rpm --import /studio/studio_rpm_key_0
rm /studio/studio_rpm_key_0
rpm --import /studio/studio_rpm_key_1
rm /studio/studio_rpm_key_1
rpm --import /studio/studio_rpm_key_2
rm /studio/studio_rpm_key_2
rpm --import /studio/studio_rpm_key_3
rm /studio/studio_rpm_key_3
rpm --import /studio/studio_rpm_key_4
rm /studio/studio_rpm_key_4
rpm --import /studio/studio_rpm_key_5
rm /studio/studio_rpm_key_5
rpm --import /studio/studio_rpm_key_6
rm /studio/studio_rpm_key_6
rpm --import /studio/studio_rpm_key_7
rm /studio/studio_rpm_key_7
rpm --import /studio/studio_rpm_key_8
rm /studio/studio_rpm_key_8
rpm --import /studio/studio_rpm_key_9
rm /studio/studio_rpm_key_9
rpm --import /studio/studio_rpm_key_10
rm /studio/studio_rpm_key_10
rpm --import /studio/studio_rpm_key_11
rm /studio/studio_rpm_key_11
rpm --import /studio/studio_rpm_key_12
rm /studio/studio_rpm_key_12

sed --in-place -e 's/# solver.onlyRequires.*/solver.onlyRequires = true/' /etc/zypp/zypp.conf

# Enable sshd
chkconfig sshd on

#======================================
# Setting up overlay files 
#--------------------------------------
echo '** Setting up overlay files...'
echo mkdir -p /
mkdir -p /
echo tar xfp /image/3ab2efcaa21e0e7b6f54e8a578f3ce67 -C /
tar xfp /image/3ab2efcaa21e0e7b6f54e8a578f3ce67 -C /
echo rm /image/3ab2efcaa21e0e7b6f54e8a578f3ce67
rm /image/3ab2efcaa21e0e7b6f54e8a578f3ce67
mkdir -p /etc/sysconfig/kernel/
mv /studio/overlay-tmp/files//etc/sysconfig/kernel//kernel /etc/sysconfig/kernel//kernel
chown root:root /etc/sysconfig/kernel//kernel
chmod 644 /etc/sysconfig/kernel//kernel
chown root:root /build-custom
chmod +x /build-custom
# run custom build_script after build
/build-custom
chown root:root /etc/init.d/suse_studio_custom
chmod +x /etc/init.d/suse_studio_custom
test -d /studio || mkdir /studio
cp /image/.profile /studio/profile
cp /image/config.xml /studio/config.xml
rm -rf /studio/overlay-tmp
true