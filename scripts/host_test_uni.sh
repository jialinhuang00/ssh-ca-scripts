#!/bin/bash
set -e

# 0. Auto copy CA files from container
docker cp ssh-ca-demo:/etc/ssh/user_ca ./user_ca

# 1. Check if CA files exist (after docker cp)
if [ ! -f ./user_ca ]; then
    echo "Please docker cp ssh-ca-demo:/etc/ssh/user_ca . to local first"
    exit 1
fi

# 2. Generate user key
ssh-keygen -f ./user_key -N "" -t ed25519 -C "Local User Key"

# 3. Sign user_key.pub with user_ca
ssh-keygen -s ./user_ca -I local_user_cert -n demo-user -V +5m ./user_key.pub

# 4. Use user_key to login server (no @cert-authority in known_hosts)
echo "Trying to connect to docker ssh server with user cert (unidirectional verification)"
ssh -i ./user_key -o UserKnownHostsFile=./known_hosts -p 2222 demo-user@localhost 