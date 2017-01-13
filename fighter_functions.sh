# Pre-defined functions

# block the recieved ip by csf
function block_csf()
{
	echo "/sbin/iptables -A INPUT -s $1 -j DROP # Banned by DDOS_Fighter for $2 connections to port 80 on `date`" >>/etc/csf/csfpost.sh
}

# block the recieved ip by iptables
function block_ipt()
{
	iptables -A INPUT -s $1 -j DROP
	echo "$1 # Banned by DDOS_Fighter for $2 connections to port 80 on `date`" >>$blocked_path
}

function isRunning()
{
	if [ -e /etc/ddos_fighter/ddos_fighter.pid ]; then
		pid=`cat /etc/ddos_fighter/ddos_fighter.pid`
		return 0
	else
		return 1
	fi
}

# create pid file and store the process number
function writePID()
{
	echo $$ >/etc/ddos_fighter/ddos_fighter.pid
}

function beforeExit()
{
	rm -f /etc/ddos_fighter/ddos_fighter.pid
	rm -f /etc/ddos_fighter/results.txt
	logThat "interrupt caught on line: $1, quitting"
}

function logThat()
{
	echo "`date "+%d/%m/%Y %T %z | "` $1"
}

# args
# $1 variable, string of configuration variable
# $2 flushEvery of checkEvery to identify what to validate
function validateCalculateTiming()
{
	# Validating flushEvery or checkEvery and calculating the seconds
	# Checking every char in flushEvery to ensure it doesn't contain other than d, h, m, s, DIGIT
	str=$1
	for (( i=0; i<${#str}; i++ )); do
		if [[ ${str:$i:1} -ge 0 ]] 2>/dev/null; then
			continue
		else
			if [[ "${str:$i:1}" == "h" ]] || [[ "${str:$i:1}" == "d" ]] || [[ "${str:$i:1}" == "m" ]] || [[ "${str:$i:1}" == "s" ]]; then
				continue
			else
				# second argument will identify whats being validating
				logThat "Wrong entry for $2 variable in fighter.conf"
				exit 1
			fi
		fi
	done

	# cut -f1 -dd means split the string by delimiter "d" and get the first "f1"
	days=$(echo $str | cut -f1 -dd)
	hours=$(echo $str | cut -f2 -dd | cut -f1 -dh)
	minutes=$(echo $str | cut -f2 -dd | cut -f2 -dh | cut -f1 -dm)
	seconds=$(echo $str | cut -f2 -dd | cut -f2 -dh | cut -f2 -dm | cut -f1 -ds)

	if [[ $days -gt 0 ]] 2>/dev/null; then
		: # a positive number
	else
		days=0
	fi

	if [[ $hours -gt 0 ]] 2>/dev/null; then
		: # a positive number
	else
		hours=0
	fi

	if [[ $minutes -gt 0 ]] 2>/dev/null; then
		: # a positive number
	else
		minutes=0
	fi

	if [[ $seconds -gt 0 ]] 2>/dev/null; then
		: # a positive number
	else
		seconds=0
	fi

	if [[ "$2" == "flushEvery" ]]; then
		flushEveryInSeconds=$(($days*86400+$hours*3600+$minutes*60+$seconds))
	elif [[ "$2" == "checkEvery" ]]; then
		checkEveryInSeconds=$(($days*86400+$hours*3600+$minutes*60+$seconds))
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
