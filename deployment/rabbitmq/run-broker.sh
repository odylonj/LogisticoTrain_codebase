#!/bin/sh
set -eu

BROKER_USER="$(cat /run/secrets/broker_user)"
BROKER_PASSWORD="$(cat /run/secrets/broker_password)"

cat > /etc/rabbitmq/conf.d/30-logisticotrain.conf <<EOF
listeners.tcp = none
stomp.listeners.tcp.1 = 61613
stomp.default_user = ${BROKER_USER}
stomp.default_pass = ${BROKER_PASSWORD}
EOF

export RABBITMQ_DEFAULT_USER="$BROKER_USER"
export RABBITMQ_DEFAULT_PASS="$BROKER_PASSWORD"

exec docker-entrypoint.sh rabbitmq-server
