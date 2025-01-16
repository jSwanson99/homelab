sudo dnf install -y openssl

MACHINE_IP=$1
COMMON_NAME=$2

sudo mkdir -p /etc/ssl/private
sudo chmod 700 /etc/ssl/private
sudo openssl genrsa -out /etc/ssl/private/server.key 2048
sudo chmod 600 /etc/ssl/private/server.key

sudo openssl req -new \
	-key /etc/ssl/private/server.key \
	-out /etc/ssl/certs/server.csr \
	-subj "/CN=$COMMON_NAME" \
	-addext 'subjectAltName = IP:127.0.0.1,IP:'$MACHINE_IP
