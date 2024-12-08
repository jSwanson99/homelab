# Install open-webui
dnf install -y dnf-plugins-core
dnf config-manager --set-enabled crb
dnf install -y epel-release tee
dnf install -y python3.11 python3.11-pip
pip3.11 install open-webui

mkdir -p /etc/openwebui
mkdir -p /etc/openwebui/huggingface
mkdir -p /etc/openwebui/models
mkdir -p /home/svc_openwebui/.cache/huggingface/hub
chown -R svc_openwebui:svc_openwebui /etc/openwebui
chown -R svc_openwebui:svc_openwebui /etc/openwebui/models
chown -R svc_openwebui:svc_openwebui /etc/openwebui/huggingface
chmod 755 /etc/openwebui
chmod 755 /etc/openwebui/models
chmod 755 /etc/openwebui/huggingface


# Update sqlite
dnf groupinstall -y "Development Tools"
dnf install -y wget tcl-devel readline-devel zlib-devel

mkdir -p /opt/sqlite
mkdir -p /opt/sqlite/src
cd /opt/sqlite/src
wget https://www.sqlite.org/2024/sqlite-autoconf-3450000.tar.gz
tar xvfz sqlite-autoconf-3450000.tar.gz
cd sqlite-autoconf-3450000

./configure --prefix=/opt/sqlite \
  --enable-readline \
  --enable-fts5 \
  --enable-json1 \
  --enable-shared \
  --enable-load-extension

make
make install
chown -R root:root /opt/sqlite

tee /etc/profile.d/sqlite3.sh << 'EOF'
export SQLITE_HOME=/opt/sqlite
export PATH=$SQLITE_HOME/bin:$PATH
export LD_LIBRARY_PATH=$SQLITE_HOME/lib:$LD_LIBRARY_PATH
export PKG_CONFIG_PATH=$SQLITE_HOME/lib/pkgconfig:$PKG_CONFIG_PATH
EOF
chmod 755 /etc/profile.d/sqlite3.sh

tee /etc/ld.so.conf.d/sqlite3.conf << EOF
/opt/sqlite/lib
EOF

ldconfig

# Service user setup
useradd -r -s /sbin/nologin svc_openwebui
mkdir -p /var/log/openwebui
mkdir -p /etc/openwebui
chown -R svc_openwebui:svc_openwebui /var/log/openwebui
chown -R svc_openwebui:svc_openwebui /etc/openwebui


# Ollama Setup
useradd -r -s /sbin/nologin ollama
mkdir -p /var/lib/ollama
chown -R ollama:ollama /var/lib/ollama
curl -fsSL https://ollama.com/install.sh | sh
cp ollama.service /etc/systemd/system/
systemctl daemon-reload

