sudo systemctl enable postgresql-17
sudo systemctl start postgresql-17
sudo firewall-cmd --add-port=5432/tcp --permanent
