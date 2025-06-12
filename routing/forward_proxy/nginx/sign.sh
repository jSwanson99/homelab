#!/bin/bash
DOMAIN=$1
CA_KEY=/etc/pki/nginx/ca/ca.key
CA_CERT=/etc/pki/nginx/ca/ca.crt
CERT_DIR=/etc/pki/nginx/certs

openssl genrsa -out "$CERT_DIR/$DOMAIN.key" 2048

cat > "$CERT_DIR/$DOMAIN.conf" << EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
CN = $DOMAIN

[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectKeyIdentifier = hash
subjectAltName = @alt_names

[alt_names]
DNS.1 = $DOMAIN
DNS.2 = *.$DOMAIN
EOF

openssl req -new -key "$CERT_DIR/$DOMAIN.key" \
  -out "$CERT_DIR/$DOMAIN.csr" \
  -config "$CERT_DIR/$DOMAIN.conf"

openssl x509 -req -in "$CERT_DIR/$DOMAIN.csr" \
  -CA $CA_CERT -CAkey $CA_KEY \
  -CAcreateserial -out "$CERT_DIR/$DOMAIN.crt" \
  -days 365 -sha256 \
  -extfile "$CERT_DIR/$DOMAIN.conf" \
  -extensions v3_req

rm "$CERT_DIR/$DOMAIN.csr" "$CERT_DIR/$DOMAIN.conf"
