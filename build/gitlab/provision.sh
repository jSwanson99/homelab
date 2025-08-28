#! /bin/bash

curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.rpm.sh | bash
dnf install -y gitlab-ce

firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --reload

mkdir -p /etc/gitlab/ssl
chmod 755 /etc/gitlab/ssl
