FROM ubuntu:14.04.3

# Install packages
RUN apt-get update
RUN apt-get install -y redsocks iptables
RUN apt-get install -y python-pip && pip install shadowsocks

# Copy configuration files...
COPY redsocks.conf /etc/redsocks.conf
COPY whitelist.txt /etc/redsocks-whitelist.txt
COPY blacklist.txt /etc/redsocks-blacklist.txt
COPY run.sh /usr/local/bin/run.sh
COPY redsocks-fw.sh /usr/local/bin/redsocks-fw.sh

RUN chmod +x /usr/local/bin/*

ENTRYPOINT ["/usr/local/bin/run.sh"]

CMD ["client", "127.0.0.1", "8388", "123456", "white"]
