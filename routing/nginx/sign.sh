#!/bin/bash
DOMAIN=$1
CA_KEY=/etc/pki/nginx/ca/ca.key
CA_CERT=/etc/pki/nginx/ca/ca.crt
CERT_DIR=/etc/nginx/ssl/certs

# Generate private key
openssl genrsa -out "$CERT_DIR/$DOMAIN.key" 2048

# Generate CSR
openssl req -new -key "$CERT_DIR/$DOMAIN.key" \
  -out "$CERT_DIR/$DOMAIN.csr" \
  -subj "/CN=$DOMAIN"

# Sign certificate with CA
openssl x509 -req -in "$CERT_DIR/$DOMAIN.csr" \
  -CA $CA_CERT -CAkey $CA_KEY \
  -CAcreateserial -out "$CERT_DIR/$DOMAIN.crt" \
  -days 365 -sha256

# Clean up CSR
rm "$CERT_DIR/$DOMAIN.csr"
