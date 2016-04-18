#!/bin/bash
###############################################################
#                   DDOS_Fighter Version 1.0  
#                 Copyright© 2012 Hussien Yousef	                 
#This program is free software: you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation, either version 3 of the License, or
#(at your option) any later version.
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#You should have received a copy of the GNU General Public License
#along with this program.  If not, see <http://www.gnu.org/licenses/>.               
###############################################################

# the config file path
config_path=/etc/ddos_fighter/fighter.conf

# blocked ip list path for iptables
blocked_path=/etc/ddos_fighter/blocked.list

# include the config variables
if [ -e "$config_path" ]
then
  source $config_path
else
  echo -e "\n Couldn't find the config file in $config_path"
  echo "Make sure the config file exits and is readable ."
  exit 2
fi

# Pre-defined functions
function block_csf(){
# block the recieved ip by csf
echo "$1 # Banned by DDOS_Fighter for $2 connections to port 80 on `date`" >> /etc/csf/csf.deny
}

function block_ipt(){
# block the recieved ip by iptables
/sbin/iptables -A INPUT -s $1 -j DROP
echo "$1 # Banned by DDOS_Fighter for $2 connections to port 80 on `date`" >> $blocked_path
}

# The main options
case $1 in
"-s") # Here is the code to start fighting DDOS attacks

# output information about ips and connections to $results_file
results_file=/etc/ddos_fighter/results.txt
netstat -n|grep :80|cut -c 45-|cut -f 1 -d ':'|sort|uniq -c|sort -nr|more > $results_file

# start checking connections and block attackers ips
blocked_num=0
while read num_con ip
do
if [ $num_con -ge $conn_limit ]
then
# here is what to do if an ip exceded the limit number of connections
let "blocked_num += 1"
if [ $csf_exits -eq 1 ]
then
#block by csf
block_csf $ip $num_con
else
#block by ip_tables
block_ipt $ip $num_con
fi

fi
done < "$results_file"

# After finishing checking and blocking
# restart firewalls
if [ $blocked_num -ge "1" ];then
# choose which firewall to restart
if [ $csf_exits -eq "1" ];then
csf -r
else
service iptables save
service iptables restart
fi

fi

#delete the results file
rm -rf $results_file
echo -e "\n Done.  $blocked_num attackers have been blocked ."
;;
"-unb") # Unblock an ip address
echo "$2"
if [ $csf_exits -eq "1" ];then
echo -e "\n to unblock this ip , edit the file /etc/csf/csf.deny and remove the line that contains the ip"
echo "After removing the line , save the file then restart the firewall using the command : csf-r"
else
/sbin/iptables -D INPUT -s $2 -j DROP
service iptables save
service iptables restart
echo -e "\n $2 have been unblocked from IPTables successfully."
fi
;;
"-f") # remove all blocked ips
sh /etc/ddos_fighter/fighter_flush.sh
;;
"-config") # update settings from fighter.conf
cron_path=/etc/cron.d/ddos_fighter
echo "# This is the cron file for DDOS_Fighter v1.0" > $cron_path
echo "# last updated in `date`" >> $cron_path
echo "*/$f_minutes * * * * root sh /etc/ddos_fighter/fighter.sh -s >/dev/null 2>&1" >> $cron_path
echo "*/$x_minutes * * * * root sh /etc/ddos_fighter/fighter_flash.sh >/dev/null 2>&1" >> $cron_path
service crond restart
;;
*) # If no option specified invoke this
echo "################################################################"
echo "#                   DDOS_Fighter Version 1.0                   #"
echo "#             Coded By Explicit (Hussien Yousef)               #"
echo "#                   Mail: Buff3r0@Gmail.Com                    #"
echo "#         Website: http://fighter.ehcommunity.com              #"
echo "################################################################"
echo -e "\n USAGE :"
echo -e "-s\t# to start protection"
echo -e "-f\t# unblock all blocked ips"
echo -e "-config\t# update current settings from configuration file"
echo -e "-unb [ip]\t# to unblock an ip"
;;
esac
