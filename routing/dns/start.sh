#! /bin/sh

chown -R coredns:coredns /etc/coredns
systemctl daemon-reload
systemctl enable coredns
systemctl start coredns
systemctl restart otelcol-contrib
firewall-cmd --permanent --add-port=53/tcp
firewall-cmd --permanent --add-port=53/udp
firewall-cmd --permanent --add-port=9153/tcp # Metrics
firewall-cmd --reload
