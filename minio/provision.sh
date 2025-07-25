#! /bin/sh

dnf install -y wget

# Minio
wget https://dl.min.io/server/minio/release/linux-amd64/archive/minio-20250613113347.0.0-1.x86_64.rpm -O minio.rpm
dnf install -y minio.rpm

mkdir -p /etc/default /etc/minio/pki/CAs
setcap 'cap_net_bind_service=+ep' /usr/local/bin/minio

groupadd -r minio-user
useradd -M -r -g minio-user minio-user
mkdir -p /mnt/data
chown minio-user:minio-user /mnt/data
chown minio-user:minio-user /usr/local/bin/minio
chown minio-user:minio-user /etc/default/minio
chmod ug+rwx /usr/local/bin/minio
chmod ug+rw /etc/default/minio

chown minio-user:minio-user /etc/minio/pki
chmod ug+rw /etc/minio/pki

# Otelcol
VERSION=0.120.0
wget https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v${VERSION}/otelcol-contrib_${VERSION}_linux_amd64.rpm
rpm -vhi otelcol-contrib_${VERSION}_linux_amd64.rpm
usermod -a -G systemd-journal otelcol-contrib
