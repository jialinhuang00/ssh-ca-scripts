FROM ubuntu:22.04

RUN apt-get update && apt-get install -y openssh-server

RUN mkdir /var/run/sshd

RUN useradd -m demo-user

COPY gen_ca_and_certs.sh /gen_ca_and_certs.sh
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /gen_ca_and_certs.sh /entrypoint.sh

# gen ca, cert, then immediately start sshd
ENTRYPOINT ["/entrypoint.sh"]

