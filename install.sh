#!/usr/bin/env bash
# DDOS_Fighter v2.2 Installer
# Copyright© 2012 Hussien Yousef
if [ $EUID -ne 0 ]; then
	echo "This script must be run as root" 
	exit 1
fi

version=2.2

# check if DDOS_Fighter installed before and what version
if [[ -e "/etc/ddos_fighter/fighter.sh" ]] && [[ -e "/etc/ddos_fighter/fighter.conf" ]]; then
	source /etc/ddos_fighter/fighter.conf
	if [[ "$ddosfighterVersion" > "$version" ]]; then
		echo "You have a newer version is already installed on your system"
		exit 1
	elif [[ "$ddosfighterVersion" == "$version" ]]; then
		echo "You have the latest version is already installed on your system"
		exit 1
	fi
fi

# Checking config file for errors and setting EveryInSeconds variables
echo "[+] Setting the configuration file."
source fighter_functions.sh
source fighter.conf
echo "[+] Calculating timing."
validateCalculateTiming $flushEvery flushEvery
validateCalculateTiming $checkEvery checkEvery
sed -i 's,^\(flushEveryInSeconds=\).*,\1'$flushEveryInSeconds',' fighter.conf
sed -i 's,^\(checkEveryInSeconds=\).*,\1'$checkEveryInSeconds',' fighter.conf

echo "[+] Copying files."
# Remove the folder if exists and making the folder and copy files
rm -rf /etc/ddos_fighter
mkdir /etc/ddos_fighter
cp fighter.sh /etc/ddos_fighter/
cp fighter_functions.sh /etc/ddos_fighter/
cp fighter.conf /etc/ddos_fighter/
cp blocked.list /etc/ddos_fighter/
echo "[+] DDOS_Fighter files have been moved to /etc/ddos_fighter"
chmod +x /etc/ddos_fighter/fighter.sh
if [[ $csf_exists -eq 1 ]];then
	touch /etc/csf/csfpost.sh
	chmod +x /etc/csf/csfpost.sh
fi
echo "[+] DDOS_Fighter files are given the right permissions to work."

/etc/ddos_fighter/fighter.sh -s &>$logFile &

# final message
echo -e "\n The program is now ready and working, please check $logFile for errors, if the program not running please run /etc/ddos_fighter/fighter.sh -r"
echo "if you want to change any of it's configuration, edit /etc/ddos_fighter/fighter.conf then restart by /etc/ddos_fighter/fighter.sh -r"
echo -e "\n I wish this program can help you or at least lowers your problems."
echo "For any feedbacks, feel free to contact me at: buff3r0@gmail.com"
