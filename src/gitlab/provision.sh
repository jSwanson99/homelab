dnf config-manager --set-enabled crb
dnf install -y curl policycoreutils-python-utils openssh-server perl postfix firewalld

systemctl enable sshd
systemctl start sshd

systemctl enable firewalld
systemctl start firewalld

firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
systemctl reload firewalld

systemctl enable postfix
systemctl start postfix
