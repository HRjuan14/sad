# Práctica 1 de SAD (SecureCorp) — imagen del laboratorio, ASIR 2º
#
# Debian 12, igual que en clase. La MISMA imagen sirve para las dos máquinas:
#   servidor -> OpenLDAP + Kerberos (KDC) de SecureCorp
#   cliente  -> el PC de un empleado
# Dentro de los contenedores los comandos son los normales de Linux (openssl,
# ldapsearch, kadmin.local, kinit...): Docker solo sirve para entrar y salir.

FROM debian:bookworm

ENV DEBIAN_FRONTEND=noninteractive

# Respuestas a la instalación de slapd y krb5: dominio securecorp.local
RUN printf '%s\n' \
      'slapd slapd/domain string securecorp.local' \
      'slapd shared/organization string SecureCorp' \
      'slapd slapd/password1 password SecureCorp2026' \
      'slapd slapd/password2 password SecureCorp2026' \
      'krb5-config krb5-config/default_realm string SECURECORP.LOCAL' \
      'krb5-config krb5-config/kerberos_servers string kdc.securecorp.local' \
      'krb5-config krb5-config/admin_server string kdc.securecorp.local' \
    | debconf-set-selections \
 && apt-get update && apt-get install -y --no-install-recommends \
      slapd ldap-utils krb5-kdc krb5-admin-server krb5-user \
      ca-certificates openssl nano less iproute2 iputils-ping tcpdump procps \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY arranque-servidor.sh /usr/local/bin/arranque-servidor.sh
RUN chmod +x /usr/local/bin/arranque-servidor.sh

# El prompt dice siempre en qué máquina estás (en rojo el servidor, en verde el cliente)
RUN echo 'if [ "$(hostname)" = servidor ]; then PS1="\[\e[1;31m\]root@SERVIDOR\[\e[0m\]:\w# "; else PS1="\[\e[1;32m\]root@CLIENTE\[\e[0m\]:\w# "; fi' >> /root/.bashrc

WORKDIR /root
CMD ["sleep", "infinity"]
