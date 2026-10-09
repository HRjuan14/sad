# Práctica 1 de SAD · SecureCorp — Respuestas

**Nombre y apellidos:**
**Usuario:**

Responde con tus palabras, en 1-3 líneas. En la defensa te preguntaré lo mismo en voz alta.

**Contraseñas que has usado** (solo porque es un laboratorio; en una empresa, jamás en un fichero):

- Tu usuario: jherrador
- mtorres:

---

**1. (A1)** ¿Quién es el `issuer` de tu `ca.crt`? ¿Hasta qué fecha es válido? ¿Por qué el `subject`
y el `issuer` de la CA son iguales y los de `ldap.crt` no?

C = ES, O = SecureCorp, CN = Juan Root CA - Juan Herrador. La fecha válida es hasta el 5 de octubre de 2036 a las 15:41:15 GMT. Porque el certificado de CA es un certificado raiz autofirmado, lo que significa que la propia entidad emisora se firma a sí misma para iniciar la cadena de confianza, haciendo que el titular (subject) y el emisor (issuer) sean el mismo.

**2. (A3)** Pega el comando y el resultado de tus dos búsquedas:

```
a) miembros de rrhh:
ldapsearch -x -LLL -H ldap://ldap.securecorp.local -b "ou=groups,dc=securecorp,dc=local" "(cn=rrhh)" member

dn: cn=rrhh,ou=groups,dc=securecorp,dc=local
member: uid=lromero,ou=people,dc=securecorp,dc=local
member: uid=mtorres,ou=people,dc=securecorp,dc=local

b) cn y mail de todas las personas:
ldapsearch -x -LLL -H ldap://ldap.securecorp.local -b "ou=people,dc=securecorp,dc=local" "(objectClass=inetOrgPerson)" cn mail

dn: uid=lromero,ou=people,dc=securecorp,dc=local
cn: Lucia Romero
mail: lromero@securecorp.local

dn: uid=jherrador,ou=people,dc=securecorp,dc=local
cn: Juan Herrador
mail: jherrador@securecorp.local

dn: uid=mtorres,ou=people,dc=securecorp,dc=local
cn: Marta Torres
mail: mtorres@securecorp.local

```

**3. (A4)** ¿Por qué la clave `ldap.key` tiene que ser de `openldap` y tener permisos 600?

Pertenencia a openldap: Porque el servicio LDAP no se ejecuta como root, 
sino como el usuario openldap, y necesita ser el dueño para poder leerla.
Permisos 600: Para que solo openldap pueda leerla y escribirla (-rw-------). 
Si la leen otros usuarios, la seguridad del servidor se rompe.

**4. (A4)** ¿Qué valor has puesto en `SLAPD_SERVICES` y por qué?

Valor: SLAPD_SERVICES="ldaps:/// ldapi:///"
Por qué: ldaps:/// abre el puerto 636 cifrado y ldapi:/// permite administrar el servidor en local. 
Quitamos ldap:/// para cerrar el puerto 389 y 
prohibir conexiones sin cifrar.

**5. (A4)** Antes de añadir `TLS_CACERT` en el cliente, `ldaps://` no funcionaba. ¿Por qué?

Porque nuestra CA es privada y el cliente no confía en ella por defecto.
 Sin TLS_CACERT, el cliente no puede validar el certificado del servidor y 
corta la conexión por seguridad.

**6. (B3)** Pega la salida de `klist` con tus dos tickets. ¿Para qué sirve cada uno? ¿Ha viajado tu
contraseña por la red?

```
root@CLIENTE:~# klist
Ticket cache: FILE:/tmp/krb5cc_0
Default principal: jherrador@SECURECORP.LOCAL

Valid starting     Expires            Service principal
10/09/26 14:33:50  10/10/26 00:33:50  krbtgt/SECURECORP.LOCAL@SECURECORP.LOCAL
	renew until 10/16/26 14:33:50
10/09/26 14:34:13  10/10/26 00:33:50  host/web.securecorp.local@SECURECORP.LOCAL
	renew until 10/16/26 14:33:50

```

**7. (C)** En el `docker-compose.yml`, ¿qué diferencia hay entre `build:` e `image:`? ¿Qué
significa la línea `- "8081:80"` del servicio `phpldapadmin`?

build: vs image:: build: crea la imagen desde un Dockerfile local; 
image: la descarga ya hecha de Docker Hub.

- "8081:80": Mapea el puerto 8081 de mi PC al 80 del contenedor
 para abrir phpldapadmin en http://localhost:8081.

**8. (C)** ¿Por qué en la máquina `web` no has tenido que escribir a mano `TLS_CACERT`, y en el
cliente sí? ¿Qué pasaría con esa línea del cliente si hicieras `./lab.sh reset`?

Porque lo metí en su Dockerfile y ya viene grabado en la imagen.
Se borra. Al no estar en el Dockerfile ni en un volumen, 
se pierde al recrear el contenedor.
