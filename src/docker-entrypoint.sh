#!/usr/bin/env ash
set -eu

ENVIRONMENT="${ENVIRONMENT:?ENVIRONMENT must be set}"
WORKDIR="/app"

TLS_CRT_PATH="${WORKDIR}/crt"
TLS_KEY_PATH="${WORKDIR}/key"

# Generate the certificate we will use
# This is for communication between the registry proxy and the amazon load balancer
# As such we don't need a CA, trust is done through security groups
echo "Generating self-signed certificate"
echo "  Key:         $TLS_KEY_PATH"
echo "  Certificate: $TLS_CRT_PATH"
openssl req -x509 \
            -nodes \
            -newkey rsa:2048 \
            -keyout "$TLS_KEY_PATH" \
            -out    "$TLS_CRT_PATH" \
            -subj "/CN=ecr-proxy.{$ENVIRONMENT}.pymnt.internal" \
            -days   730
echo 'Finished generating self-signed certificate'

/app/do_auth.sh
do_auth_status="$?"
if [ "$do_auth_status" != "0" ]; then
  echo "do_auth.sh failed. Exiting"
  exit 1
fi

echo 'Starting nginx'
nginx -c /app/nginx.conf
