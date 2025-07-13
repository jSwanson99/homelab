mkdir /etc/pki/nginx -p
mkdir /etc/pki/nginx/certs -p
mkdir /etc/pki/nginx/ca -p
mkdir /etc/nginx/conf.d -p

dnf update -y
dnf install -y wget firewalld dnsutils telnet gzip epel-release 

# dnf install -y nginx
dnf install -y dnf-utils
yum-config-manager --add-repo https://openresty.org/package/rocky/openresty.repo
yum install -y openresty openresty-resty openresty-opm --nogpgcheck

# Otelcol
VERSION=0.120.0
wget https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v${VERSION}/otelcol-contrib_${VERSION}_linux_amd64.rpm
rpm -vhi otelcol-contrib_${VERSION}_linux_amd64.rpm
usermod -a -G systemd-journal otelcol-contrib
