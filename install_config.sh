#!/usr/bin/env bash
# User configuration 
PARENT_IP="A.B.C.D"
API_KEY="YOUR_GENERATED_UUID_HERE"
TAILSCALE_AUTH_KEY="INSERT_TAILSCALE_AUTH_KEY_HERE"
TAILSCALE_API_KEY="INSERT_TAILSCALE_API_KEY_HERE"
TAILNET="INSERT_TAILNET_HERE"

HOSTNAME="INSERT_HOST_NAME_HERE"

###
# Helper functions
###
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
# Installation usage help display
install_usage() {
    echo "Usage: $0 [-s] [-c]"
    echo "  -s  Run in server mode"
    echo "  -c  Run in client mode"
    echo "  -h  Display this help message"
    echo "  -u  Uninstall netdata and tailscale"
    exit 1
}
