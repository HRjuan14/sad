# Parte C · La máquina web.securecorp.local (el servidor web de SecureCorp)
#
# ✍️ Completa los ____ (lo explica el enunciado, Parte C).
#    Pista: el Dockerfile del laboratorio (el de la carpeta de arriba) hace casi lo mismo.

# 1 · Imagen de partida: la misma Debian que el resto del laboratorio
FROM ____

ENV DEBIAN_FRONTEND=noninteractive

# 2 · Programas: el cliente de Kerberos (kinit, klist) y el de LDAP (ldapsearch, ldapwhoami)
RUN apt-get update && apt-get install -y \
      ____ ____ ca-certificates \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

# 3 · Que confíe en la CA de SecureCorp desde que nace
#     (la misma línea que en A4 escribiste a mano en el cliente)
RUN echo "____" >> /etc/ldap/ldap.conf

# 4 · Qué hace al arrancar: quedarse encendida sin hacer nada
CMD ____
