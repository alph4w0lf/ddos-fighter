#!/bin/bash
# DDOS_Fighter v1.0 Installer
# Copyright© 2012 Hussien Yousef

# check if DDOS_Fighter installed before
if [ -e "/etc/ddos_fighter/fighter.sh" ];then
echo "You have the app or an older version is already installed on you system"
echo "you need to uninstall it using sh /etc/ddos_fighter/uninstall.sh ."
exit 1
else
# remove an empty folder if exists
rm -rf /etc/ddos_fighter
fi

# download the app files
echo "Downloading DDOS_Fighter files ..."
wget http://fighter.ehcommunity.com/ddos_fighter.zip
unzip ddos_fighter.zip
mv ddos_fighter /etc/ddos_fighter
echo "[+] DDOS_Fighter files have been downloaded and installed."
chmod +x /etc/ddos_fighter/fighter.sh
chmod +x /etc/ddos_fighter/fighter_flush.sh
chmod +x /etc/ddos_fighter/uninstall.sh
echo "[+] DDOS_Fighter files are given the right permissions to work."


# set up new cron tasks to run the app
cron_path=/etc/cron.d/ddos_fighter
echo "# This is the cron file for DDOS_Fighter v1.0" > $cron_path
echo "# last updated in `date`" >> $cron_path
echo "* * * * * root sh /etc/ddos_fighter/fighter.sh -s >/dev/null 2>&1" >> $cron_path
echo "*/59 * * * * root sh /etc/ddos_fighter/fighter_flush.sh >/dev/null 2>&1" >> $cron_path
service crond restart
echo "[+] Cron tasks have been installed."

# final message
echo -e "\n The app now is ready and working , if you want to change any of it's"
echo "configuration , edit : /etc/ddos_fighter/fighter.conf ."
echo "if you edited the configuration file , don't forget to execute this command"
echo "sh /etc/ddos_fighter/fighter.sh -config"
echo -e "\n I wish this app can help you or at least lowers your problems."
echo "For any feedbacks , feel free to contact me at : buff3r0@gmail.com ."
