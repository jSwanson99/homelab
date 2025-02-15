groupadd nginx
useradd -r -g nginx -s /sbin/nologin -M nginx
mkdir -p /var/log/nginx
touch /var/log/nginx/error.log
touch /var/log/nginx/access.log
chown -R nginx:nginx /var/log/nginx
chown -R nginx:nginx /etc/pki/nginx

systemctl enable nginx
systemctl start nginx

firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --reload
