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
