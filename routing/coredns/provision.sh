COREDNS_VERSION="1.11.1"
dnf update -y
dnf install -y wget tar gzip firewalld dnsutils telnet policycoreutils-python-utils

cd /tmp
wget https://github.com/coredns/coredns/releases/download/v${COREDNS_VERSION}/coredns_${COREDNS_VERSION}_linux_amd64.tgz
tar xzf coredns_${COREDNS_VERSION}_linux_amd64.tgz

mv coredns /usr/local/bin/
chmod +x /usr/local/bin/coredns
# Some SELinux fix
semanage fcontext -a -t bin_t '/usr/local/bin/coredns'
restorecon -v /usr/local/bin/coredns
# Allows bind to 53
setcap cap_net_bind_service=+ep /usr/local/bin/coredns

useradd -r -s /bin/false coredns
mkdir -p /etc/coredns

# Otelcol
VERSION=0.120.0
wget https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v${VERSION}/otelcol-contrib_${VERSION}_linux_amd64.rpm
rpm -vhi otelcol-contrib_${VERSION}_linux_amd64.rpm
usermod -a -G systemd-journal otelcol-contrib
