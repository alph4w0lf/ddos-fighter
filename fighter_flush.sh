#!/bin/bash
# ips unblocker for DDOS_Fighter
# Copyright© 2012 Hussien Yousef

# the config file path
config_path=/etc/ddos_fighter/fighter.conf

# blocked ip list path for iptables
blocked_path=/etc/ddos_fighter/blocked.list

# include the config variables
echo "Removing all blocked ips ...."
if [ -e "$config_path" ]
then
  source $config_path
else
  echo "Couldn't find the config file in $config_path"
  echo "Make sure the config file exits and is readable ."
  exit 2
fi

# check which firewall software is used
if [ $csf_exits -eq "1"  ];then
# flashing all ips blocked by csf
echo "# ips last flashed by DDOS_Fighter in `date`" > /etc/csf/csf.deny
csf -r
else
# flashing all ips blocked by IPTables
while read ip other
do
/sbin/iptables -D INPUT -s $ip -j DROP
done < "$blocked_path"
service iptables save
service iptables restart
fi
echo "Done. All blocked ips have been removed successfully."
