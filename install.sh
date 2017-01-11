#!/usr/bin/env bash
# DDOS_Fighter v1.0 Installer
# Copyright© 2012 Hussien Yousef
if [ $EUID -ne 0 ]; then
	echo "This script must be run as root" 
	exit 1
fi

version=2.1

# check if DDOS_Fighter installed before and what version
if [ -e "/etc/ddos_fighter/fighter.sh" ] && [ -e "/etc/ddos_fighter/fighter.conf" ]; then
	source /etc/ddos_fighter/fighter.conf
	if [ $ddosfighter_version -ge $version ]; then
		echo "You have a newer version is already installed on you system"
		exit 1
	fi
else
	# remove an empty folder if exists
	rm -rf /etc/ddos_fighter
fi

# Checking config file for errors and setting *EveryInMinutes
source fighter_functions.sh
source fighter.conf
validateCalculateTiming $flushEvery flushEvery
validateCalculateTiming $checkEvery checkEvery
echo "[+] Calculating timing."
#sed -i 's/flushEvery=.*/flushEvery=$flushEvery/' fighter.conf
#sed -i 's/checkEvery=.*/checkEvery=$checkEvery/' fighter.conf
sed -i 's,^\(flushEveryInMinutes=\).*,\1'$flushEveryInMinutes',' fighter.conf
sed -i 's,^\(checkEveryInMinutes=\).*,\1'$checkEveryInMinutes',' fighter.conf

# Making the folder and copy files
mkdir /etc/ddos_fighter
cp fighter.sh /etc/ddos_fighter/
cp fighter_flush.sh /etc/ddos_fighter/
cp fighter_functions.sh /etc/ddos_fighter/
cp fighter.conf /etc/ddos_fighter/
cp blocked.list /etc/ddos_fighter/
echo "[+] DDOS_Fighter files have been moved to /etc/ddos_fighter"
chmod +x /etc/ddos_fighter/fighter.sh
chmod +x /etc/ddos_fighter/fighter_flush.sh
chmod +x /etc/ddos_fighter/fighter_functions.sh
echo "[+] DDOS_Fighter files are given the right permissions to work."

# set up new cron tasks to run the app
# cron_path=/etc/cron.d/ddos_fighter
# echo "# This is the cron file for DDOS_Fighter v1.0" > $cron_path
# echo "# last updated in `date`" >> $cron_path
# echo "* * * * * root sh /etc/ddos_fighter/fighter.sh -s >/dev/null 2>&1" >> $cron_path
# echo "* * * * * root sh /etc/ddos_fighter/fighter_flush.sh >/dev/null 2>&1" >> $cron_path
# service crond restart
# echo "[+] Cron tasks have been installed."

bash /etc/ddos_fighter/fighter.sh -s >/dev/null 2>&1 &

# final message
echo -e "\n The app now is ready and working , if you want to change any of it's"
echo "configuration , edit : /etc/ddos_fighter/fighter.conf ."
echo "if you edited the configuration file , don't forget to execute this command"
echo "sh /etc/ddos_fighter/fighter.sh -config"
echo -e "\n I wish this app can help you or at least lowers your problems."
echo "For any feedbacks , feel free to contact me at : buff3r0@gmail.com ."
