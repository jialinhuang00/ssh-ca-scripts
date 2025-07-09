#!/bin/bash
set -e

rm -f user_ca user_ca.pub user_key user_key-cert.pub user_key.pub host_ca.pub known_hosts

echo "already deleted files"


if docker ps -a --format '{{.Names}}' | grep -q '^ssh-ca-demo$'; then
  echo "stop and delete docker container ssh-ca-demo..."
  docker stop ssh-ca-demo || true
  docker rm ssh-ca-demo || true
else
  echo "docker container ssh-ca-demo not exist"
fi

echo "DONE!" 