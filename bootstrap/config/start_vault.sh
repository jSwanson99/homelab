sudo systemctl daemon-reload
sudo systemctl enable vault
sudo systemctl start vault
sudo firewall-cmd --add-port=8200/tcp --permanent

sudo firewall-cmd --reload
