# Laboratorio de la Práctica 2 de SAD · Bodegas Atlántico
# Una sola imagen para todas las máquinas: cada una hace su papel según ROL (ver arranque.sh).
# Bloques A y B: cortafuegos nftables + VPN WireGuard.
# Bloques C y D (complemento): Suricata en el firewall y el servidor de reservas bastionado.
# El WAF es la imagen oficial de OWASP (ModSecurity + Core Rule Set), ver docker-compose.yml.
FROM debian:trixie-slim
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      nftables iproute2 iputils-ping wireguard-tools tcpdump curl nmap netcat-openbsd nginx-light procps less nano vim-tiny zip \
      suricata openssh-server openssh-client sshpass fail2ban lynis rsyslog jq \
    && rm -rf /var/lib/apt/lists/* \
    && rm -f /etc/nginx/sites-enabled/default /etc/fail2ban/jail.d/defaults-debian.conf
# La llave de «admin» (el administrador que entra en el servidor de reservas): privada para la tienda, pública para reservas
RUN mkdir -p /etc/lab && ssh-keygen -q -t ed25519 -N "" -C admin@lab -f /etc/lab/admin
COPY arranque.sh /usr/local/bin/arranque.sh
RUN chmod +x /usr/local/bin/arranque.sh
CMD ["/usr/local/bin/arranque.sh"]
