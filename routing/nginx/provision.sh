mkdir /etc/pki/nginx -p
mkdir /etc/pki/nginx/certs -p
mkdir /etc/pki/nginx/ca -p
mkdir /etc/nginx/conf.d -p
chown -R nginx:nginx /etc/pki/nginx
chown -R nginx:nginx /etc/nginx
chown -R nginx:nginx /var/log/nginx
chmod ug+rw /etc/pki/nginx
chmod ug+rw /etc/nginx
chmod ug+rwx /var/log/nginx
chmod ug+rwx /etc/pki/nginx/certs

dnf update -y
dnf install -y wget firewalld dnsutils telnet gzip epel-release 

# dnf install -y nginx
dnf install -y dnf-utils
yum-config-manager --add-repo https://openresty.org/package/rocky/openresty.repo
yum install -y openresty openresty-resty openresty-opm --nogpgcheck
