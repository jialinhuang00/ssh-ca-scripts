#!/bin/bash
set -e

# 0. Auto copy CA files from container
docker cp ssh-ca-demo:/etc/ssh/user_ca ./user_ca
docker cp ssh-ca-demo:/etc/ssh/user_ca.pub ./user_ca.pub
docker cp ssh-ca-demo:/etc/ssh/host_ca.pub ./host_ca.pub

# 1. Check if CA files exist (after docker cp)
if [ ! -f ./user_ca ] || [ ! -f ./user_ca.pub ] || [ ! -f ./host_ca.pub ]; then
  echo "Please docker cp ssh-ca-demo:/etc/ssh/user_ca . and user_ca.pub and host_ca.pub to local first"
  exit 1
fi

# 2. Generate user key
ssh-keygen -f ./user_key -N "" -t ed25519 -C "Local User Key"

# 3. Sign user_key.pub with user_ca
ssh-keygen -s ./user_ca -I local_user_cert -n demo-user -V +5m ./user_key.pub

# 4. Add host_ca.pub to known_hosts (@cert-authority)
echo "@cert-authority localhost $(cat ./host_ca.pub)" > ./known_hosts

# 5. Use user_key to login server, specify known_hosts
echo "Trying to connect to docker ssh server with user cert (bidirectional CA verification)"
ssh -i ./user_key  -o UserKnownHostsFile=./known_hosts -o StrictHostKeyChecking=yes -p 2222 demo-user@localhost 