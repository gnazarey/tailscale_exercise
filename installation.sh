#!/bin/bash
# This is the installation script for netdata and tailscail
#
# Check for configuration file
if [ ! -e ./install_config.sh ]; then
	echo "ERROR: install_config.sh does not exist. Please create it and place it in this directory"
	exit 1
fi
source ./install_config.sh

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
	sed -i 's/API_KEY=\"YOUR_GENERATED_UUID_HERE\"/API_KEY=\"'$GEN_API_KEY'\"/g' ./install_config.sh
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
	sed -i 's/PARENT_IP=\"A.B.C.D\"/PARENT_IP=\"'$TAILSCALE_IP'\"/g' ./install_config.sh
fi

# Clean up
for i in /tmp/stream.conf.$$ /tmp/netdata-kickstart.sh /tmp/tailscale_install.sh
	do
		if [ -e "$i" ]; then
			rm $i
		fi
	done
