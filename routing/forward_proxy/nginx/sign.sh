#!/bin/bash
DOMAIN=$1
CA_KEY=/etc/pki/nginx/ca/ca.key
CA_CERT=/etc/pki/nginx/ca/ca.crt
CERT_DIR=/etc/pki/nginx/certs

mkdir -p "$CERT_DIR"
openssl genrsa -out "$CERT_DIR/$DOMAIN.key" 2048

cat > "$CERT_DIR/$DOMAIN.conf" << EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = US
ST = State
L = City
O = Home Network
OU = Proxy
CN = $DOMAIN

[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
subjectAltName = @alt_names

[alt_names]
DNS.1 = $DOMAIN
DNS.2 = *.$DOMAIN
EOF

# Add IP if domain is IP address
if [[ $DOMAIN =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    echo "IP.1 = $DOMAIN" >> "$CERT_DIR/$DOMAIN.conf"
fi

# Generate CSR and sign
openssl req -new -key "$CERT_DIR/$DOMAIN.key" \
  -out "$CERT_DIR/$DOMAIN.csr" \
  -config "$CERT_DIR/$DOMAIN.conf"

openssl x509 -req -in "$CERT_DIR/$DOMAIN.csr" \
  -CA $CA_CERT -CAkey $CA_KEY \
  -CAcreateserial -out "$CERT_DIR/$DOMAIN.crt" \
  -days 365 -sha256 \
  -extfile "$CERT_DIR/$DOMAIN.conf" \
  -extensions v3_req

# Cleanup
rm "$CERT_DIR/$DOMAIN.csr" "$CERT_DIR/$DOMAIN.conf"

# Set permissions
chmod 600 "$CERT_DIR/$DOMAIN.key"
chmod 644 "$CERT_DIR/$DOMAIN.crt"
chown nginx:nginx "$CERT_DIR/$DOMAIN.key" "$CERT_DIR/$DOMAIN.crt"
