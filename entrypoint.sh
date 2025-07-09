#!/bin/bash
set -e

/gen_ca_and_certs.sh

echo "=== start sshd ==="
exec /usr/sbin/sshd -D -f /etc/ssh/sshd_config

