COREDNS_VERSION="1.11.1"

dnf update -y
dnf install -y wget tar gzip firewalld dnsutils

cd /tmp
wget https://github.com/coredns/coredns/releases/download/v${COREDNS_VERSION}/coredns_${COREDNS_VERSION}_linux_amd64.tgz
tar xzf coredns_${COREDNS_VERSION}_linux_amd64.tgz

mv coredns /usr/local/bin/
chmod +x /usr/local/bin/coredns

useradd -r -s /bin/false coredns
mkdir -p /etc/coredns
