#! /bin/bash

sudo chown root:root /etc/gitlab/ssl/gitlab.jds.net.crt
sudo chmod 644 /etc/gitlab/ssl/gitlab.jds.net.crt

sudo chown root:root /etc/gitlab/ssl/gitlab.jds.net.key
sudo chmod 600 /etc/gitlab/ssl/gitlab.jds.net.key

gitlab-ctl reconfigure
gitlab-ctl start
