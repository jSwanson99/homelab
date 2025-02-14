sudo systemctl daemon-reload
sudo systemctl enable mitmproxy
sudo systemctl start mitmproxy 
firewall-cmd --permanent --add-port=8080/tcp
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --reload
