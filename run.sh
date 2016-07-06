#!/bin/bash

pid=0
# SIGUSR1 handler
usr_handler() {
    echo "usr_handler"
}

# SIGTERM-handler
term_handler() {
    if [ $pid -ne 0 ]; then
        echo "Term signal catched. Shutdown redsocks and disable iptables rules..."
        kill -SIGTERM "$pid"
        wait "$pid"
        /usr/local/bin/redsocks-fw.sh stop ${use_type} ${proxy_ip}
    fi
    exit 143; # 128 + 15 -- SIGTERM
}

run_client() {
    if test $# -eq 4
    then
        proxy_ip=$1
        proxy_port=$2
        proxy_pass=$3
    else
        echo "No proxy URL defined. Exit."
        exit 1
    fi
    use_type=$4
    
    echo "Starting shadowsocks client..."
    /usr/local/bin/sslocal -s ${proxy_ip} -p ${proxy_port} -b 0.0.0.0 -l 1080 -k ${proxy_pass} -m aes-256-cfb -t 600 -d start
    
    echo "Activating iptables rules..."
    /usr/local/bin/redsocks-fw.sh start ${use_type} ${proxy_ip}
    
    # setup handlers
    trap 'kill ${!}; usr_handler' SIGUSR1
    trap 'kill ${!}; term_handler' SIGTERM
    
    echo "Starting redsocks..."
    /usr/sbin/redsocks -c /etc/redsocks.conf &
    pid="$!"
    
    # wait indefinetely
    while true
    do
        tail -f /dev/null & wait ${!}
    done
}

case "$1" in
    client)
	if test $# -ne 5
	then
	    echo "Missing params. Exit."
	    exit 1
        fi
        echo -n "Starting Redsocks and Shadowsocks client..."
	run_client $2 $3 $4 $5
	;;
    server)
	if test $# -ne 2
	then
	    echo "Missing params. Exit."
	    exit 1
        fi
        echo -n "Starting Shadowsocks Server..."
        /usr/local/bin/ssserver -s 0.0.0.0 -p 8388 -k $2 -m aes-256-cfb --user nobody
	;;
    forwarder)
	if test $# -ne 6
	then
	    echo "Missing params. Exit."
	    exit 1
        fi
	echo -n "Starting Shadowsocks Server..."
        /usr/local/bin/ssserver -s 0.0.0.0 -p 8388 -k $6 -m aes-256-cfb --user nobody &
        echo -n "Starting Redsocks and Shadowsocks client..."
	run_client $2 $3 $4 $5
	;;
esac
