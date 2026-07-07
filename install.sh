#!/bin/bash
# This is the installation script for netdata and tailscale
# Written By: George Nazarey
# Date: 7/02/2026
# Email: gnazarey@gmail.com 
#
##########################
# FUNCTION SECTION
##########################
# Uninstall Netdata application
uninstall_netdata() {
	echo "Uninstalling Netdata"
	sudo systemctl stop netdata
	if [ -e /tmp/netdata-kickstart.sh ]; then
		sh /tmp/netdata-kickstart.sh --uninstall --non-interactive
	else
		/usr/bin/wget -O /tmp/netdata-kickstart.sh https://get.netdata.cloud/kickstart.sh
		if [ "abc541147e05940960461cc21e6d47e6" = "$(/usr/bin/md5sum /tmp/netdata-kickstart.sh | cut -d ' ' -f 1)" ]; then
			sh /tmp/netdata-kickstart.sh --uninstall --non-interactive
		else
			echo "ERROR: Invalid check sum for netdata kickstart script."
			exit 1
		fi 
	fi
	for i in /etc/netdata /var/cache/netdata /var/lib/netdata /var/log/netdata 
		do
			if [ -d "$i" ]; then
				sudo rm -rf $i
			fi
		done
	tmp_cleanup
}
# Uninstall Tailscale agent
uninstall_tailscale() {
	sudo /usr/bin/tailscale down
	sudo systemctl stop tailscaled
	# Remove it from the console
	DEVICE_ID=`curl -s -u "$TAILSCALE_API_KEY:" "https://api.tailscale.com/api/v2/tailnet/$TAILNET/devices?hostname=$HOSTNAME" | jq -r '.devices[] | "\(.name) ID: \(.id)"' | awk '{print $3}'`
	curl 'https://api.tailscale.com/api/v2/device/$DEVICE_ID' \
  	--request DELETE \
  	--header 'Authorization: Bearer $TAILSCALE_API_KEY'
	sudo apt-get purge tailscale -y
	if [ -d /var/lib/tailscale/ ]; then
		sudo rm -rf /var/lib/tailscale/
	fi
	if [ -e /tmp/tailscale_install.sh ]; then
		rm /tmp/tailscale_install.sh
	fi
	sudo rm /etc/apt/sources.list.d/tailscale.list
	sudo rm /usr/share/keyrings/tailscale-archive-keyring.gpg
}
# Clean tmp directory after install
tmp_cleanup() {
	for i in /tmp/netdata /tmp/netdata-uninstaller-* 
		do
			sudo rm -rf $i
		done
}
# check configuration
check_config() {
	local CONFIG_TYPE=$1
	local ERROR=false	
	case $CONFIG_TYPE in
  	c)
    	if [ "$PARENT_IP" = "A.B.C.D" ]; then
      	echo "Check the config. Parent IP is missing"
				ERROR=true
			fi
			if [ "$API_KEY" = "YOUR_GENERATED_UUID_HERE" ]; then
				echo "Check the config. API Key is missing"
				ERROR=true
			fi
      ;;
    u)
      if [ "$TAILSCALE_AUTH_KEY" = "INSERT_TAILSCALE_AUTH_KEY_HERE" ]; then
      	echo "Check the config. Tailscale AUTH KEY is missing"
        ERROR=true
      fi
      if [ "$TAILSCALE_API_KEY" = "INSERT_TAILSCALE_API_KEY_HERE" ]; then
      	echo "Check the config. Tailscale API KEY is missing"
        ERROR=true
      fi
      if [ "$TAILNET" = "INSERT_TAILNET_HERE" ]; then
      	echo "Check the config. Tailnet is missing"
        ERROR=true
      fi
       ;;
    esac
  if [ "$HOSTNAME" = "INSERT_HOST_NAME_HERE" ]; then
  		echo "Check the config. Hostname is missing"
  		ERROR=true
  fi
  if [ "$ERROR" = true ]; then
  	install_usage
  fi
}
# Client file creation
create_client_config() {
	echo "#!/usr/bin/env bash" > ./client_config.sh
	cat <<EOF >> ./client_config.sh
	HOSTNAME="INSERT_HOST_NAME_HERE"
	API_KEY="YOUR_GENERATED_UUID_HERE"
	PARENT_IP="A.B.C.D"
	TAILSCALE_AUTH_KEY="INSERT_TAILSCALE_AUTH_KEY_HERE"
	TAILSCALE_API_KEY="INSERT_TAILSCALE_API_KEY_HERE"
	TAILNET="INSERT_TAILNET_HERE"
EOF
}
# Installation usage help display
install_usage() {
    echo "Usage: $0 [-s] [-c]"
    echo "  -s  Run in server mode"
    echo "  -c  Run in client mode"
    echo "  -h  Display this help message"
    echo "  -u  Uninstall netdata and tailscale"
    exit 1
}
################
# Installation Program
################
# Check for configuration file
if [ ! -e ./server_config.sh ] || [ ! -e ./client_config.sh ]; then
	echo "ERROR: server_config.sh or client_config.sh does not exist. Please create it and place it in this directory"
	exit 1
fi
if [ -e ./server_config.sh ]; then
	source ./server_config.sh
fi
if [ -e ./client_config.sh ]; then
	source ./client_config.sh
else
	create_client_config
fi

# Initialize variables
SERVER_MODE=false
CLIENT_MODE=false
UNINSTALL=false

# Parse command line arguments
while getopts "scdhu" opt; do
    case $opt in
        s)
            SERVER_MODE=true
            check_config s
            ;;
        c)
            CLIENT_MODE=true
            check_config c
            ;;
        h)
            install_usage
            ;;
        u)
        		check_config u
        		uninstall_netdata
        		uninstall_tailscale
        		tmp_cleanup
        		exit 
        		;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            install_usage
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            install_usage
            ;;
    esac
done

# Check if no arguments were provided
if [ $# -eq 0 ]; then
    echo "Error: No arguments provided"
    install_usage
fi
# Validate that only one mode is selected
if [ "$SERVER_MODE" = true ] && [ "$CLIENT_MODE" = true ]; then
    echo "Error: Cannot specify both -s and -c options"
    install_usage
elif [ "$SERVER_MODE" = false ] && [ "$CLIENT_MODE" = false ]; then
    echo "Error: Must specify either -s (server) or -c (client) option"
    install_usage
fi
# Set the hostname
sudo hostnamectl set-hostname $HOSTNAME
# Netdata installation
/usr/bin/wget -O /tmp/netdata-kickstart.sh https://get.netdata.cloud/kickstart.sh
if [ "abc541147e05940960461cc21e6d47e6" = "$(/usr/bin/md5sum /tmp/netdata-kickstart.sh | cut -d ' ' -f 1)" ]; then
	sudo sh /tmp/netdata-kickstart.sh --no-updates --stable-channel --disable-telemetry	--non-interactive
else
	echo "ERROR: Invalid check sum for netdata kickstart script."
exit 1
fi 
# Netdata configuration
if [ "$API_KEY" == "YOUR_GENERATED_UUID_HERE" ]; then
	GEN_API_KEY=`/usr/bin/uuidgen`
	sed -i 's/API_KEY=\"YOUR_GENERATED_UUID_HERE\"/API_KEY=\"'$GEN_API_KEY'\"/g' ./client_config.sh
	API_KEY=$GEN_API_KEY
fi
if [ "$CLIENT_MODE" = true ]; then
###
# Client netdata installation
###
# Write directly to stream.conf on a child node
cat <<EOF > /tmp/stream.conf.$$
[stream]
  enabled = yes
  destination = ${PARENT_IP}:19999
  api key = ${API_KEY}
EOF
fi
if [ "$SERVER_MODE" = true ]; then
###
# Server netdata installation
###
cat <<EOF > /tmp/stream.conf.$$
[${API_KEY}]
	enabled = yes
	type = api
	allow from = *
	retention = 1h
EOF
fi
# Correct permissions and restart
sudo cp /tmp/stream.conf.$$ /etc/netdata/stream.conf
sudo chown netdata:netdata /etc/netdata/stream.conf
sudo systemctl restart netdata

# Tailscale installation
/usr/bin/wget -O /tmp/tailscale_install.sh https://tailscale.com/install.sh
sh /tmp/tailscale_install.sh
sudo tailscale up --auth-key=$TAILSCALE_AUTH_KEY
# Update configuration file
if [ "$PARENT_IP" == "A.B.C.D" ]; then
	#TAILSCALE_IP=`/usr/bin/tailscale status | grep $HOSTNAME | cut -d' ' -f1`
	TAILSCALE_IP=$(/usr/bin/tailscale ip -4)
	sed -i 's/PARENT_IP=\"A.B.C.D\"/PARENT_IP=\"'$TAILSCALE_IP'\"/g' ./client_config.sh
fi

# Clean up
for i in /tmp/stream.conf.$$ /tmp/netdata-kickstart.sh /tmp/tailscale_install.sh
	do
		if [ -e "$i" ]; then
			rm $i
		fi
	done
echo "****************************"
echo "Don't forget to copy the client_config.sh to the client machine before running the installation script."
echo "****************************"
if [ "$SERVER_MODE" = true ]; then
	sed -i 's/TAILSCALE_AUTH_KEY=\"INSERT_TAILSCALE_AUTH_KEY_HERE\"/TAILSCALE_AUTH_KEY=\"'$TAILSCALE_AUTH_KEY'\"/g' ./client_config.sh
	sed -i 's/TAILSCALE_API_KEY=\"INSERT_TAILSCALE_API_KEY_HERE\"/TAILSCALE_API_KEY=\"'$TAILSCALE_API_KEY'\"/g' ./client_config.sh
	sed -i 's/TAILNET=\"INSERT_TAILNET_HERE\"/TAILNET=\"'$TAILNET'\"/g' ./client_config.sh
	cat ./client_config.sh
fi