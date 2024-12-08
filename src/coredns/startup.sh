chown -R coredns:coredns /etc/coredns
systemctl daemon-reload

systemctl enable coredns
systemctl start coredns

echo "search local\rnameserver 127.0.0.1" > /etc/resolv.conf

systemctl enable firewalld
systemctl start firewalld

firewall-cmd --permanent --add-port=53/tcp
firewall-cmd --permanent --add-port=53/udp
firewall-cmd --permanent --add-port=9153/tcp
firewall-cmd --reload
