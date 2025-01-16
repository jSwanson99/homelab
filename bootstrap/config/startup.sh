# Postgres should be first because vault tries to connect to it
sudo systemctl enable postgresql-17
sudo systemctl start postgresql-17
sudo firewall-cmd --add-port=5432/tcp --permanent

sudo systemctl daemon-reload
sudo systemctl enable vault
sudo systemctl start vault
sudo firewall-cmd --add-port=8200/tcp --permanent

sudo firewall-cmd --reload
