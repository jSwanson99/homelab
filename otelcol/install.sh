VERSION='0.120.0'

sudo yum update
sudo yum -y install wget systemctl
wget "https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v$VERSION/otelcol-contrib_$VERSION_linux_amd64.rpm"
sudo rpm -ivh otelcol-contrib_$VERSION_linux_amd64.rpm
usermod -a -G systemd-journal otelcol-contrib

