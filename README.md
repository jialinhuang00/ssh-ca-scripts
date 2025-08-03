# OpenSSH CA Demo

This project demonstrates how to use OpenSSH CA for unidirectional (user cert) and bidirectional (user+host cert) authentication.

---

## Docker Usage

```sh
docker build -t ssh-ca-demo .
docker run -it --rm -p 2222:22 --name ssh-ca-demo ssh-ca-demo
```
- This will start an SSH server, mapping port 2222 on the host to port 22 in the container.
- The server will automatically generate CA, user/host keys and certificates, and configure sshd on startup.

---

## Unidirectional CA Authentication (User Cert Only)

1. Start the container (as above)
2. On the host, run:
   ```sh
   ./scripts/host_test_uni.sh
   ```
   - Automatically copies CA files from the container
   - Generates a user key and signs a user certificate
   - Logs in to the server using the user certificate
   - **Only the user cert is verified; the host is verified by fingerprint**

---

## Bidirectional CA Authentication (User + Host Cert)

1. Start the container (as above)
2. On the host, run:
   ```sh
   ./scripts/host_test_dual.sh
   ```
   - Automatically copies CA files from the container
   - Generates a user key and signs a user certificate
   - Adds the host CA to known_hosts (with @cert-authority)
   - Logs in to the server using the user certificate, and verifies the server's host cert is signed by the CA
   - **Both user cert and host cert are verified (bidirectional CA)**

---

## Others

- You can inspect certificate details with
  ```sh
  ssh-keygen -L -f <cert file>
  ```

- **Don't forget to use `-o UserKnownHostsFile=./known_hosts` when testing!** Otherwise, SSH will use the default `~/.ssh/known_hosts` and you may get unexpected results.
- For detailed steps and scripts, see the `scripts/` directory
- **DO CLEANUP ALL THE TIME**.
---



## SSH Login Methods: Files & Examples

### 1. Password Login
- **Server needs:** `/etc/shadow` (stores user password hashes)
- **Server needs:** `/etc/ssh/sshd_config` (`PasswordAuthentication` yes)
- **Client needs:** Just the password

**Example:**
- On server, you set a password for user `alice`:
  ```sh
  sudo passwd alice
  # (enter password)
  ```
- `/etc/shadow` (snippet):
  ```
  alice:$6$randomsalt$encryptedpasswordhash:...:...
  ```
- On server `/etc/ssh/sshd_config`, you need to make this key be true
  ```
  PasswordAuthentication yes
  ```
login
```
ssh me@server_ip
# input password
```
---

### 2. Private Key Login
- **Server needs:** `~/.ssh/authorized_keys` (for user `alice`)
- **Server needs:** `~/etc/ssh/sshd_config` (`PubkeyAuthentication` yes)
- **Client needs:** key pair (e.g. `~/.ssh/id_rsa` and `~/.ssh/id_rsa.pub`)

**Example:**
- On client, generate key:
  ```sh
  ssh-keygen -t rsa -f ~/.ssh/id_rsa
  ```
- Copy public key to server (login by password then register your public key to that list):
  ```sh
  ssh-copy-id -i ~/.ssh/id_rsa.pub me@server
  ```
- On server, `~/.ssh/authorized_keys` (on server, for user `me`):
  ```
  ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC... user@host
  ```
- On server, `~/etc/ssh/sshd_config`
  ```
  PubkeyAuthentication yes
  ```
- `~/.ssh/id_rsa` (private key, on client):
  ```
  -----BEGIN RSA PRIVATE KEY-----
  MIIEpAIBAAKCAQEA7... (long base64)...
  -----END RSA PRIVATE KEY-----
  ```
login
```
ssh me@server_ip
```
---

### 3. CA Certificate Login

#### (A) One-way CA (User Certificate Only)
- **Server needs:**
  - CA public key bundle file: `/etc/ssh/ca-bundle.pub` (contains multiple CA public keys, one per line)
  - SSH config: `/etc/ssh/sshd_config` (with line: `TrustedUserCAKeys /etc/ssh/ca-bundle.pub`)
- **Client needs:**
  - Private key: `~/.ssh/id_rsa`
  - Certificate signed by CA: `~/.ssh/id_rsa-cert.pub`

**Example:**
- `/etc/ssh/ca-bundle.pub` (on server, multiple lines):
  ```
  ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... ca1@yourorg
  ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAJ... ca2@yourorg
  ```
- On client,`~/.ssh/id_rsa-cert.pub`:
  ```
  ssh-rsa-cert-v01@openssh.com AAAAHHNzaC1yc2EAAAADAQABAAABAQC... (signed blob) ... user@host
  ```
- On server, `/etc/ssh/sshd_config`:
  ```
  TrustedUserCAKeys /etc/ssh/ca-bundle.pub
  ```
login
```
ssh me@server_ip
```

#### (B) Two-way CA (User + Host Certificate)
- **Server needs:**
  - All of the above (contains files used in One-way CA (User Certificate Only))
  - Host CA public key: `/etc/ssh/host_ca.pub` (shared with clients)
  - Host private key: `/etc/ssh/host_key`
  - Host certificate: `/etc/ssh/host_key-cert.pub`
  - `/etc/ssh/sshd_config`:
    ```
    HostKey /etc/ssh/host_key
    # let client check me aka server is valid
    HostCertificate /etc/ssh/host_key-cert.pub

    # for checking client is valid
    TrustedUserCAKeys /etc/ssh/ca-bundle.pub
    ```
- **Client needs:**
  - All of the above (user private key + user cert)
  - Host CA public key: `~/.ssh/host_ca.pub` (or just the public key string)
  - `~/.ssh/known_hosts` with:
    ```
    @cert-authority *.yourdomain.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... host-ca@org
    ```

**This means:**
- Client will only trust servers whose host cert is signed by the trusted host CA.
- Server will only trust users whose user cert is signed by the trusted user CA.

#### (C) Fine-grained CA trust with @cert-authority in authorized_keys
- For example, on the SSH server, in the home directory of user alice, the ~/.ssh/authorized_keys file can include:
  ```
  @cert-authority ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... ca1@yourorg
  ```
- This allows you to trust a CA for just one user, not globally.
- OpenSSH will check `TrustedUserCAKeys` first, then look for `@cert-authority` lines in `authorized_keys` if needed.
- `TrustedUserCAKeys` is the first global filter
- `authorized_keys` with @cert-authority is a second filter.

---

### CA Certificate Login: Required Files Summary

| File/Config                        | One-way CA (User Cert Only) | Two-way CA (User+Host Cert) | Server/Client/CA Mgmt | Purpose/Notes                         |
|------------------------------------|:--------------------------:|:---------------------------:|:--------------------:|---------------------------------------|
| `/etc/ssh/user_ca`                 |           ✓                |            ✓                |   CA Mgmt Host       | User CA **private key** (keep secure, never copy to server/client) |
| `/etc/ssh/user_ca.pub`             |           ✓                |            ✓                |   CA Mgmt/Server     | User CA **public key** (copy to server as ca-bundle.pub)           |
| `/etc/ssh/ca-bundle.pub`           |           ✓                |            ✓                |   Server             | User CA public keys (for user certs)  |
| `/etc/ssh/sshd_config`             |           ✓                |            ✓                |   Server             | SSHD config, incl. TrustedUserCAKeys  |
| `~/.ssh/id_rsa`                    |           ✓                |            ✓                |   Client             | User private key                      |
| `~/.ssh/id_rsa-cert.pub`           |           ✓                |            ✓                |   Client             | User certificate (signed by user-ca)  |
| `/etc/ssh/host_ca`                 |                            |            ✓                |   CA Mgmt Host       | Host CA **private key** (keep secure, never copy to server/client) |
| `/etc/ssh/host_ca.pub`             |                            |            ✓                |   CA Mgmt/Server/Client | Host CA **public key** (shared to client for host cert validation) |
| `/etc/ssh/host_key`                |                            |            ✓                |   Server             | Host private key                      |
| `/etc/ssh/host_key-cert.pub`       |                            |            ✓                |   Server             | Host certificate (signed by host-ca)  |
| `~/.ssh/host_ca.pub`               |                            |            ✓                |   Client             | Host CA public key (for known_hosts)  |
| `~/.ssh/known_hosts`               |                            |            ✓                |   Client             | Trust host CA with @cert-authority     |

**Legend:**
- ✓ = required for this mode
- user-ca = CA for user certs
- host-ca = CA for host certs
- CA Mgmt Host = CA management host (should be secure, not a regular server)

**Note:**
- Only the **public keys** (`user_ca.pub`, `host_ca.pub`) are distributed to server/client.
- The **private keys** (`user_ca`, `host_ca`) must remain secure and never leave the CA management host.

---

## How CA Signing Works (Simple)

1. **You generate your own key pair:**
   ```sh
   ssh-keygen -t rsa -f ~/.ssh/id_rsa
   ```
2. **You send your public key (`~/.ssh/id_rsa.pub`) to the CA admin.**
3. **CA admin signs your public key with their CA private key:**
   ```sh
   ssh-keygen -s /etc/ssh/user_ca -I alice -n alice -V +52w ~/.ssh/id_rsa.pub
   # This creates ~/.ssh/id_rsa-cert.pub
   ```
4. **You get back `~/.ssh/id_rsa-cert.pub` (the certificate).**

---

## Why do you need to bring your private key (`id_rsa`) when logging in with a certificate?

- The certificate (`~/.ssh/id_rsa-cert.pub`) proves your public key is trusted by the CA.
- But the server needs to know you really own that private key.
- When you log in, the server sends a random challenge.
- Your SSH client uses that private key to sign this challenge.
- The server checks the signature using the public key from your certificate.
- If it matches, you are authenticated!

**In short:**
- The certificate says "this public key is trusted."
- The private key is used locally to sign the server's challenge, proving "I am the real owner of this public key."
- THE PRIVATE KEY ITSELF NEVER LEAVES YOUR CLIENT MACHINE.