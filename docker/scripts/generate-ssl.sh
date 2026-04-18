#!/bin/bash
# Generate a self-signed SSL cert + key for Nginx dev.
# Usage:  ./docker/scripts/generate-ssl.sh [server_name]
# Example: ./docker/scripts/generate-ssl.sh laravel.test

set -e

SERVER_NAME="${1:-laravel.test}"
SSL_DIR="docker/nginx/ssl"

mkdir -p "$SSL_DIR"

if [[ -f "$SSL_DIR/cert.pem" && -f "$SSL_DIR/key.pem" ]]; then
    echo "SSL certificate already exists at $SSL_DIR/."
    echo "Delete cert.pem and key.pem first if you want to regenerate."
    exit 0
fi

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "$SSL_DIR/key.pem" \
    -out "$SSL_DIR/cert.pem" \
    -subj "/C=US/ST=Local/L=Local/O=Dev/CN=${SERVER_NAME}" \
    -addext "subjectAltName=DNS:${SERVER_NAME},DNS:*.${SERVER_NAME},DNS:localhost,IP:127.0.0.1"

echo "Generated self-signed certificate for ${SERVER_NAME}:"
echo "  $SSL_DIR/cert.pem"
echo "  $SSL_DIR/key.pem"
echo ""
echo "Browsers will warn because the cert isn't trusted. Add the CA to your"
echo "system/browser store (or use mkcert) for a warning-free dev experience."
