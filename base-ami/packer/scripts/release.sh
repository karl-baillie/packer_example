#!/bin/bash -xe

# clean this instance
systemctl stop rsyslog
shred -u /etc/ssh/*_key /etc/ssh/*_key.pub
find /var/log -type f -exec rm -f {} \;
touch /var/log/lastlog
rm -rf /tmp/files

echo "SUCCESS"
