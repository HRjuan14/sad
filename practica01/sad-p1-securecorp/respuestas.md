# Práctica 1 de SAD · SecureCorp — Respuestas

**Nombre y apellidos:**
**Usuario:**

Responde con tus palabras, en 1-3 líneas. En la defensa te preguntaré lo mismo en voz alta.

**Contraseñas que has usado** (solo porque es un laboratorio; en una empresa, jamás en un fichero):

- Tu usuario:
- mtorres:

---

**1. (A1)** ¿Quién es el `issuer` de tu `ca.crt`? ¿Hasta qué fecha es válido? ¿Por qué el `subject`
y el `issuer` de la CA son iguales y los de `ldap.crt` no?


**2. (A3)** Pega el comando y el resultado de tus dos búsquedas:

```
a) miembros de rrhh:

b) cn y mail de todas las personas:

```

**3. (A4)** ¿Por qué la clave `ldap.key` tiene que ser de `openldap` y tener permisos 600?


**4. (A4)** ¿Qué valor has puesto en `SLAPD_SERVICES` y por qué?


**5. (A4)** Antes de añadir `TLS_CACERT` en el cliente, `ldaps://` no funcionaba. ¿Por qué?


**6. (B3)** Pega la salida de `klist` con tus dos tickets. ¿Para qué sirve cada uno? ¿Ha viajado tu
contraseña por la red?

```

```

**7. (C)** En el `docker-compose.yml`, ¿qué diferencia hay entre `build:` e `image:`? ¿Qué
significa la línea `- "8081:80"` del servicio `phpldapadmin`?


**8. (C)** ¿Por qué en la máquina `web` no has tenido que escribir a mano `TLS_CACERT`, y en el
cliente sí? ¿Qué pasaría con esa línea del cliente si hicieras `./lab.sh reset`?

