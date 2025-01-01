#!/usr/bin/env bash
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
if [ $EUID -ne 0 ]; then
	echo "This script must be run as root"
	exit 1
fi

# the config file path
config_path=/etc/ddos_fighter/fighter.conf

# include the config variables
if [ -w "$config_path" ]; then
	source $config_path
else
	echo "Couldn't find the config file in $config_path"
	echo "Make sure the config file exits and is readable and writable."
	exit 1
fi

# include the functions file
if [ -e /etc/ddos_fighter/fighter_functions.sh ]; then
	source /etc/ddos_fighter/fighter_functions.sh
else
	echo "Couldn't find the functions file"
	echo "Please delete /etc/ddos_fighter and install it again."
	exit 1
fi

# The main options
case $1 in
"-s") # Here is the code to start fighting DDOS attacks
	if isRunning; then
		echo -e "\n The program is already running"
		echo "run /etc/ddos_fighter/fighter.sh -r to restart and apply new configurations"
		exit 1
	else
		# Catch interrupts
		trap 'beforeExit $LINENO $BASH_COMMAND; exit' SIGHUP SIGINT SIGQUIT SIGTERM EXIT

		writePID
		while [[ true ]]; do
			# flushing
			if [[ $(($(date +%s) - ($lastFlush+$flushEveryInSeconds))) -ge 0 ]]; then
				/etc/ddos_fighter/fighter.sh -f
				# updating last flush time
				lastFlush=$(date +%s)
				sed -i 's,^\(lastFlush=\).*,\1'$lastFlush',' /etc/ddos_fighter/fighter.conf
			fi

			# checking
			if [[ $(($(date +%s) - ($lastCheck+$checkEveryInSeconds))) -ge 0 ]]; then
				# output information about ips and connections to $results_file
				results_file=/etc/ddos_fighter/results.txt

				# When blocking IPs actually iptables firewall just block the new connections
				# Can't block already established connections. So this program may block the
				# same IP more than one time, to make sure when flushing that all duplicated
				# IPs is unblocked, the program will run into a loop and take some time depends
				# on the keep-alive configuration of the web sever.
				netstat -nut|grep :80|cut -c 45-|cut -f 1 -d ':'|sort|uniq -c|sort -nr > $results_file

				# start checking connections and block attackers ips
				blocked_num=0
				while read num_con ip
				do
					if [[ $num_con -ge $conn_limit ]]; then
						# here is what to do if an ip exceded the limit number of connections
						((blocked_num++))
						if [[ $csf_exists -eq 1 ]]; then
							#block by csf
							block_csf $ip $num_con
						else
							#block by ip_tables
							block_ipt $ip $num_con
						fi
					fi
				done < "$results_file"

				# After finishing checking and blocking
				# restart csf firewall
				if [[ $blocked_num -ge 1 ]] && [[ $csf_exists -eq 1 ]];then
					csf -r &
				fi
				# updating last check time
				lastCheck=$(date +%s)
				sed -i 's,^\(lastCheck=\).*,\1'$lastCheck',' /etc/ddos_fighter/fighter.conf

				#delete the results file
				rm -rf $results_file
				if [[ $blocked_num -ge 1 ]];then
					logThat "$blocked_num IPs have been blocked"
				fi
			fi

			# sleep for 2.5 seconds
			# this makes the margin of error 7.5s at maximum time without checking
			# the amount of time between two checks if neither flush nor check was executed
			sleep 2.5
		done
	fi
	;;
"-unb") # Unblock an ip address
	if [[ $csf_exists -eq 1 ]];then
		sed -i "/$2/d" /etc/csf/csfpost.sh
		csf -r &
		echo "$2 have been unblocked from CSF successfully."
	else
		iptables -D INPUT -s $2 -j DROP
		echo "$2 have been unblocked from IPTables successfully."
	fi
	;;
"-f") # remove all blocked IPs
	echo "Removing all blocked IPs ..."
	# check which firewall software is used
	if [[ $csf_exists -eq 1  ]];then
		# flushing all ips blocked by csf
		echo "# IPs last flushed by DDOS_Fighter in `date "+%d/%m/%Y %T %z | "`" >/etc/csf/csfpost.sh
		csf -r &
	else
		# flushing all ips blocked by IPTables
		while read ip other
		do
			if [[ "$ip" == \#* ]]; then
				continue
			fi

			while iptables -D INPUT -s $ip -j DROP &>/dev/null;
			do
				:
			done
		done < "$blocked_path"
	fi

	echo "`date "+%d/%m/%Y %T %z | "` All blocked IPs have been removed successfully." >>$logFile
	echo "All blocked IPs have been removed successfully."
	;;
"-r") # restart
	if isRunning; then
		kill -s SIGTERM $pid
		sleep 1
	fi

	validateCalculateTiming $flushEvery flushEvery
	validateCalculateTiming $checkEvery checkEvery
	echo "[+] Calculating timing."
	sed -i 's,^\(flushEveryInSeconds=\).*,\1'$flushEveryInSeconds',' /etc/ddos_fighter/fighter.conf
	sed -i 's,^\(checkEveryInSeconds=\).*,\1'$checkEveryInSeconds',' /etc/ddos_fighter/fighter.conf

	# if changed from csf to iptables, flush csf blocked IPs
	if [[ $csf_exists -eq 0 ]] && [[ -e /etc/csf/csfpost.sh ]];then
		echo "" > /etc/csf/csfpost.sh
		csf -r &
	fi

	/etc/ddos_fighter/fighter.sh -s &>>$logFile &
	echo "[+] Running ..."
	;;
*) # If no option specified invoke this
	echo "################################################################"
	echo "#                   DDOS_Fighter Version 2.2                   #"
	echo "#             Coded By Explicit (Hussien Yousef)               #"
	echo "#                   Mail: Buff3r0@Gmail.Com                    #"
	echo "#         Website: http://fighter.ehcommunity.com              #"
	echo "################################################################"
	echo -e "\n USAGE :"
	echo -e "\t-s\t\t# to start protection"
	echo -e "\t-f\t\t# unblock all blocked IPs"
	echo -e "\t-r\t\t# update current settings from configuration file"
	echo -e "\t-unb [IP]\t# to unblock an IP"
	;;
esac