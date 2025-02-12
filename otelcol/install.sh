#!/bin/bash
dnf install -y wget
wget https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v0.118.0/otelcol_0.118.0_linux_amd64.rpm
sudo rpm -ivh otelcol_0.118.0_linux_amd64.rpm
