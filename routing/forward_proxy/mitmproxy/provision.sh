dnf update -y
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
dnf install -y \
	telnet \
	lsof \
	firewalld \
	dnsutils \
	docker-ce \
	docker-ce-cli \
	containerd.io \
	docker-buildx-plugin \
	docker-compose-plugin

systemctl start docker
systemctl enable docker
mkdir /etc/mitmproxy

#dnf install -y python3-pip python3-devel

#useradd -r -s /bin/bash mitmproxy
#mkdir /home/mitmproxy
#chown -R mitmproxy:mitmproxy /home/mitmproxy

#su - mitmproxy -c "pip3 install --user mitmproxy"
#su - mitmproxy -c "echo 'export PATH=/home/mitmproxy/.local/bin:$PATH' >> /home/mitmproxy/.bashrc"
#su - mitmproxy -c "source /home/mitmproxy/.bashrc && which mitmproxy"

