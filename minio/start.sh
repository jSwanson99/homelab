#! /bin/sh

systemctl enable minio.service
systemctl start minio.service
systemctl restart otelcol-contrib
firewall-cmd --permanent --add-port=9000/tcp
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --reload

mkdir -p /etc/default/
