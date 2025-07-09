#!/bin/bash
set -e

WORKDIR=/etc/ssh
cd $WORKDIR

echo "=== Generate User CA and Host CA ==="
ssh-keygen -f user_ca -N "" -t ed25519 -C "User CA"
ssh-keygen -f host_ca -N "" -t ed25519 -C "Host CA"

echo "=== Generate User key and Host key ==="
ssh-keygen -f user_key -N "" -t ed25519 -C "User Key"
ssh-keygen -f host_key -N "" -t ed25519 -C "Host Key"

echo "=== Sign certificates with CA ==="
ssh-keygen -s user_ca -I user_cert -n demo-user -V +10m user_key.pub
ssh-keygen -s host_ca -I host_cert -h -n localhost,demo-server -V +10m host_key.pub

echo "=== Set permissions ==="
chmod 600 host_key
chown root:root host_key

# Create .ssh directory if it does not exist
mkdir -p /home/demo-user/.ssh
chown demo-user:demo-user /home/demo-user/.ssh
chmod 700 /home/demo-user/.ssh

# Write allowed principal
echo "demo-user" > /home/demo-user/.ssh/authorized_principals
chown demo-user:demo-user /home/demo-user/.ssh/authorized_principals
chmod 600 /home/demo-user/.ssh/authorized_principals

echo "=== Configure sshd_config ==="
cat > /etc/ssh/sshd_config <<EOF

Port 22
HostKey $WORKDIR/host_key
HostCertificate $WORKDIR/host_key-cert.pub
AuthorizedKeysFile .ssh/authorized_keys
TrustedUserCAKeys $WORKDIR/user_ca.pub
AuthorizedPrincipalsFile /home/%u/.ssh/authorized_principals
PasswordAuthentication no
ChallengeResponseAuthentication no
PermitRootLogin no
PubkeyAuthentication yes
UsePAM no
EOF

echo "=== Configuration complete ==="

# Create demo-user account if not exists
useradd -m demo-user 2>/dev/null || true
# Remove password lock to allow login
passwd -d demo-user

