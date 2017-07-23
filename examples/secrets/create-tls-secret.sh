#!/bin/bash
if [ ! -d tls ]; then
  mkdir tls
fi
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls/key.pem -out tls/cert.pem -subj "/CN=${public_domain}/O=${org}"
echo 'hi' > tls/demo
