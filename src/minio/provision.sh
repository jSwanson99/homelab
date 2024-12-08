MINIO_VERSION="20241013133411"

dnf update -y
dnf install -y wget tar gzip

cd /tmp
wget https://dl.min.io/server/minio/release/linux-amd64/archive/minio-${MINIO_VERSION}.0.0-1.x86_64.rpm -O minio.rpm
dnf install -y minio.rpm

useradd -r -s /bin/false svc-minio
mkdir -p /etc/minio
mkdir -p /etc/minio/data
