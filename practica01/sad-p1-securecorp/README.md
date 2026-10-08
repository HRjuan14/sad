# Práctica 1 de SAD · SecureCorp — Kit del laboratorio

Todo lo que necesitas para la práctica. **No tienes que saber Docker**: el laboratorio se maneja
con una sola orden, `./lab.sh`.

## Empezar (solo la primera vez)

```bash
cd sad-p1-securecorp        # la carpeta que has descomprimido
chmod +x lab.sh
./lab.sh preparar           # te pide tu nombre y tu usuario, y construye la imagen
./lab.sh arrancar           # enciende las máquinas
```

## Cada día

```bash
./lab.sh arrancar           # encender (si apagaste el ordenador)
./lab.sh servidor           # terminal en el SERVIDOR  (prompt en rojo)
./lab.sh cliente            # terminal en el CLIENTE   (prompt en verde)
./lab.sh comprobar          # ¿qué llevo bien y qué me falta?
./lab.sh parar              # apagar al terminar (no se pierde nada)
```

Todas las órdenes: `./lab.sh ayuda`.

## Qué hay aquí

| Carpeta / fichero | Para qué | Dentro de las máquinas |
|---|---|---|
| `pki/` | Aquí guardas tus certificados y claves | `/pki` |
| `ldif/` | Los LDIF (en `01-securecorp.ldif` pones tus datos) | `/ldif` |
| `respuestas.md` | Las preguntas que tienes que contestar | — |
| `web/Dockerfile` | La receta de la máquina web: la completas en la **Parte C** | — |
| `entrega/` | Aquí aparece el `.zip` al hacer `./lab.sh entregar` | — |
| `lab.sh` | El mando a distancia del laboratorio | — |
| `docker-compose.yml` | El plano del laboratorio. Solo lo tocas en la **Parte C** (haz antes una copia) | — |
| `Dockerfile`, `krb5/`, `arranque-servidor.sh` | El laboratorio. **No los toques** | — |

Lo que guardes en `pki/` y `ldif/` está a la vez en tu ordenador y dentro de las dos máquinas:
puedes editar los LDIF con tu editor de siempre o con `nano` dentro del contenedor.

## Si algo va mal

| Problema | Solución |
|---|---|
| `permission denied` al usar Docker | `sudo usermod -aG docker $USER` y cierra sesión |
| El puerto 8081 está ocupado | Cierra lo que lo use o ignora phpLDAPadmin: no es obligatorio |
| `./lab.sh reiniciar` dice que el servidor NO arranca | Lee el error que te muestra y usa `./lab.sh rescate` para arreglarlo |
| He estropeado el `docker-compose.yml` | `cp docker-compose.yml.bak docker-compose.yml` |
| Lo he roto todo | `./lab.sh reset` (borra las máquinas, conserva `pki/` y `ldif/`) |

En Windows usa WSL (Ubuntu) con Docker Desktop: `lab.sh` es un script de bash.
