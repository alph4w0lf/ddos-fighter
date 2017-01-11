#!/usr/bin/env bash
# Pre-defined functions
function block_csf()
{
	# block the recieved ip by csf
	echo "$1 # Banned by DDOS_Fighter for $2 connections to port 80 on `date`" >> /etc/csf/csf.deny
}

function block_ipt()
{
	# block the recieved ip by iptables
	iptables -A INPUT -s $1 -j DROP
	echo "$1 # Banned by DDOS_Fighter for $2 connections to port 80 on `date`" >> $blocked_path
}

function isRunning()
{
	if [ -e /etc/ddos_fighter/ddos_fighter.pid ]; then
		pid=`cat /etc/ddos_fighter/ddos_fighter.pid`
		return 0
		# check if a valid number
		#if [ `expr $pid + 1 2> /dev/null` ]; then
	else
		return 1
	fi
}

function writePID()
{
	echo $$ > /etc/ddos_fighter/ddos_fighter.pid
}

function beforeExit()
{
	rm -f /etc/ddos_fighter/ddos_fighter.pid
	rm -f /etc/ddos_fighter/results.txt
	echo "$(basename $0) interrupt caught on line: $1 command was: $2"
}

# args
# $1 variable, string of configuration variable
# $2 flushEvery of checkEvery to identify what to validate
function validateCalculateTiming()
{
	# Validating flushEvery or checkEvery and calculating the minutes
	# Checking every char in flushEvery to ensure it doesn't contain other than d, h, m, DIGIT
	str=$1
	for (( i=0; i<${#str}; i++ )); do
		if [ ${str:$i:1} -ge 0 ] 2>/dev/null; then
			continue
		else
			if [ "${str:$i:1}" = "h" ] || [ "${str:$i:1}" = "d" ] || [ "${str:$i:1}" = "m" ]; then
				continue
			else
				# second argument will identify whats being validating
				echo "Wrong entry for $2 variable in fighter.conf"
				exit 1
			fi
		fi
	done

	days=$(echo $str | cut -f1 -dd)
	hours=$(echo $str | cut -f2 -dd | cut -f1 -dh)
	minutes=$(echo $str | cut -f2 -dd | cut -f2 -dh | cut -f1 -dm)

	if [ $days -gt 0 ] 2>/dev/null; then
		: # a positive number
	else
		days=0
	fi

	if [ $hours -gt 0 ] 2>/dev/null; then
		: # a positive number
	else
		hours=0
	fi

	if [ $minutes -gt 0 ] 2>/dev/null; then
		: # a positive number
	else
		minutes=0
	fi

	if [ "$2" = "flushEvery" ]; then
		flushEveryInMinutes=$(($days*1440+$hours*60+$minutes))
	elif [ "$2" = "checkEvery" ]; then
		checkEveryInMinutes=$(($days*1440+$hours*60+$minutes))
	fi
}

function whichDistro()
{
	if [ -f /etc/lsb-release ]; then
		distro=$(lsb_release -s -d)
	elif [ -f /etc/debian_version ]; then
		distro="Debian $(cat /etc/debian_version)"
	elif [ -f /etc/redhat-release ]; then
		distro=`cat /etc/redhat-release`
	else
		distro="$(uname -s) $(uname -r)"
	fi
}
