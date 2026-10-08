#!/bin/bash
# Arranque de la máquina "servidor" (no hace falta tocarlo).
#
#  - Si el reino Kerberos ya existe, arranca el KDC (así sobrevive a "./lab.sh reiniciar").
#  - Arranca slapd en PRIMER PLANO, escuchando en lo que diga SLAPD_SERVICES
#    de /etc/default/slapd. Por defecto: "ldap:/// ldapi:///" (en claro).
#  - "./lab.sh reiniciar" equivale a "systemctl restart slapd" y CONSERVA todo.
mkdir -p /run/slapd && chown openldap:openldap /run/slapd
touch /var/log/krb5kdc.log

if [ -f /var/lib/krb5kdc/principal ]; then
    krb5kdc && echo "KDC de Kerberos arrancado (reino SECURECORP.LOCAL)"
fi

SLAPD_SERVICES="ldap:/// ldapi:///"
. /etc/default/slapd
echo "slapd escuchando en: $SLAPD_SERVICES"
exec /usr/sbin/slapd -h "$SLAPD_SERVICES" -g openldap -u openldap -F /etc/ldap/slapd.d -d stats
