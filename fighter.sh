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
if [ -e "$config_path" ]; then
	source $config_path
else
	echo -e "\n Couldn't find the config file in $config_path"
	echo "Make sure the config file exits and is readable ."
	exit 1
fi

# include the functions file
if [ -e /etc/ddos_fighter/fighter_functions.sh ]; then
	source /etc/ddos_fighter/fighter_functions.sh
else
	echo -e "\n Couldn't find the functions file"
	echo "Please reinstall the program."
	exit 1
fi

# blocked ip list path for iptables
blocked_path=/etc/ddos_fighter/blocked.list

# The main options
case $1 in
"-s") # Here is the code to start fighting DDOS attacks
	if isRunning; then
		echo -e "\n The program is already running"
		echo "run: /etc/ddos_fighter/fighter.sh -r to restart and apply new configurations"
		exit 1
	else
		# Catch interrupts
		trap 'beforeExit $LINENO $BASH_COMMAND; exit' SIGHUP SIGINT SIGQUIT SIGTERM

		writePID
		while [ 1 ]; do
			# flushing
			if [[ $(($(date +%s) - ($lastFlush+$flushEveryInMinutes*60))) -ge 0 ]]; then
				bash /etc/ddos_fighter/fighter_flush.sh
			fi

			# checking
			if [[ $(($(date +%s) - ($lastCheck+$checkEveryInMinutes*60))) -ge 0 ]]; then
				# output information about ips and connections to $results_file
				results_file=/etc/ddos_fighter/results.txt
				netstat -n|grep :80|cut -c 45-|cut -f 1 -d ':'|sort|uniq -c|sort -nr|more > $results_file

				# start checking connections and block attackers ips
				blocked_num=0
				while read num_con ip
				do
					if [ $num_con -ge $conn_limit ]; then
						# here is what to do if an ip exceded the limit number of connections
						((blocked_num++))
						if [ $csf_exits -eq 1 ]; then
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
			fi

			# sleep for 10 seconds
			# the amount of time between two checks if neither flush nor check was executed
			sleep 10
		done
	fi
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
	bash /etc/ddos_fighter/fighter_flush.sh
	;;
"-r") # restart
	if isRunning; then
		kill -s SIGTERM $pid
	fi

	validateCalculateTiming $flushEvery flushEvery
	validateCalculateTiming $checkEvery checkEvery
	echo "[+] Calculating timing."
	#sed -i 's/flushEvery=.*/flushEvery=$flushEvery/' fighter.conf
	#sed -i 's/checkEvery=.*/checkEvery=$checkEvery/' fighter.conf
	sed -i 's,^\(flushEveryInMinutes=\).*,\1'$flushEveryInMinutes',' fighter.conf
	sed -i 's,^\(checkEveryInMinutes=\).*,\1'$checkEveryInMinutes',' fighter.conf
	bash /etc/ddos_fighter/fighter.sh -s >/dev/null 2>&1 &
	echo "[+] Running ..."
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