#!/bin/sh

proxy_ip=$3
##########################
# Setup the Firewall rules
##########################
fw_setup() {
    # First we added a new chain called 'REDSOCKS' to the 'nat' table.
    iptables -t nat -N REDSOCKS

    case "$1" in
	black)
	    echo -n "Setting REDSOCKS blacklist rules..."
            # Use "-j RETURN" rules for the networks we don’t want to use a proxy.
            while read item; do
		echo -n "Disable $item"
                iptables -t nat -A REDSOCKS -d $item -j RETURN
            done < /etc/redsocks-blacklist.txt
	    iptables -t nat -A REDSOCKS -d $proxy_ip -j RETURN

            # Tell iptables to redirect all tcp connections to redsocks port.
            iptables -t nat -A REDSOCKS -p tcp -j REDIRECT --to-ports 12345

            # Tell iptables to use the ‘REDSOCKS’ chain for all outgoing connection.
            iptables -t nat -A OUTPUT -p tcp -j REDSOCKS
	    ;;
	white)
	    echo -n "Setting REDSOCKS whitelist rules..."
            # Tell iptables to redirect all tcp connections to redsocks port.
            iptables -t nat -A REDSOCKS -p tcp -j REDIRECT --to-ports 12345

            # Tell iptables to use the ‘REDSOCKS’ chain for whitelist networks.
            while read item; do
		echo -n "Enable $item"
                iptables -t nat -A OUTPUT -p tcp -d $item -j REDSOCKS
            done < /etc/redsocks-whitelist.txt
	    ;;
    esac
}

##########################
# Clear the Firewall rules
##########################
fw_clear() {
  iptables-save | grep -v REDSOCKS | iptables-restore
  #iptables -L -t nat --line-numbers
  #iptables -t nat -D PREROUTING 2
}

case "$1" in
    start)
        echo -n "Setting REDSOCKS firewall rules..."
        fw_clear
        fw_setup $2
        echo "done."
        ;;
    stop)
        echo -n "Cleaning REDSOCKS firewall rules..."
        fw_clear
        echo "done."
        ;;
    *)
        echo "Usage: $0 {start|stop}"
        exit 1
        ;;
esac
exit 0
