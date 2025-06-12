#!/bin/sh

# pki
chown squid:squid /etc/squid/squid-*.pem
chmod 600 /etc/squid/squid-key.pem
chmod 644 /etc/squid/squid-cert.pem /etc/squid/squid-ca.pem

# ssl db
mkdir -p /var/lib/squid
#mkdir -p /var/lib/squid/ssl_db
chown -R squid:squid /var/lib/squid
chmod -R 755 /var/lib/squid

# se linux
semanage fcontext -a -t squid_cache_t "/var/lib/squid(/.*)?" 2>/dev/null || true

# Create parent directory with proper ownership and SELinux context
mkdir -p /var/lib/squid
chown -R squid:squid /var/lib/squid

chmod -R 755 /var/lib/squid
restorecon -Rv /var/lib/squid/

sudo -u squid /usr/lib64/squid/security_file_certgen -c -s /var/lib/squid/ssl_db -M 4MB
semanage fcontext -a -t squid_cache_t "/var/lib/squid/ssl_db(/.*)?" 2>/dev/null || true

if [ ! -f "/var/lib/squid/ssl_db/index.txt" ]; then
    echo "ERROR: SSL database was not properly initialized"
    ls -la /var/lib/squid/ssl_db/
    exit 1
fi

# Set proper permissions and SELinux context on SSL database
chown -R squid:squid /var/lib/squid/ssl_db
chmod -R 700 /var/lib/squid/ssl_db
restorecon -Rv /var/lib/squid/ssl_db/

echo "SSL database initialized successfully"

systemctl enable squid
systemctl start squid

# Check if squid started successfully
if ! systemctl is-active --quiet squid; then
    echo "ERROR: Squid failed to start"
    journalctl -u squid --no-pager -l
    exit 1
fi

echo "Squid started successfully"
