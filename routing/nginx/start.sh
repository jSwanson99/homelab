groupadd nginx
useradd -r -g nginx -s /sbin/nologin -M nginx
mkdir -p /var/log/nginx
touch /var/log/nginx/error.log
touch /var/log/nginx/access.log

chown -R nginx:nginx /etc/pki/nginx
chown -R nginx:nginx /etc/nginx
chown -R nginx:nginx /var/log/nginx
chmod ug+rw /etc/pki/nginx
chmod ug+rw /etc/nginx
chmod ug+rwx /var/log/nginx
chmod ug+rwx /etc/pki/nginx/certs

# Permissions
chmod ug+x /etc/pki/nginx/sign.sh
chown -R nginx:nginx /var/log/nginx
chown -R nginx:nginx /etc/pki/nginx
chown -R nginx:nginx /usr/local/openresty
## Allow openresty to bind to 80/443
sudo setcap cap_net_bind_service=+ep /usr/local/openresty/nginx/sbin/nginx

firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --reload

systemctl enable nginx
systemctl start nginx
