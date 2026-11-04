# Bodegas Atlántico · Práctica 2 de SAD (cortafuegos, VPN, IDS/WAF y bastionado)

Todo funciona con **Docker** y con **un solo mando**: `./lab.sh`. No hace falta saber Docker.

```bash
./lab.sh arrancar      # la primera vez tarda un par de minutos
./lab.sh ayuda         # todas las órdenes
./lab.sh comprobar     # qué está bien y qué falta
./lab.sh entregar      # guarda el informe; luego git add, commit y push a tu repositorio
```

| Carpeta / fichero | Qué es |
|---|---|
| `fw/nftables.conf` | La lista del vigilante (bloque A y reglas del bloque B). **Aquí trabajas.** |
| `fw/wireguard/`, `enologa/wireguard/`, `comercial/wireguard/` | Las claves y los `wg0.conf` de la VPN (bloque B) |
| `fw/suricata/local.rules` | Las reglas de Suricata (bloque C) |
| `waf/` | El WAF: su modo (`waf.env`) y las excepciones (`plugins/`) (bloque C) |
| `reservas/` | El servidor de reservas: SSH, Fail2ban y Nginx (bloque D) |
| `respuestas.md` | Tus respuestas (nmap, contador, tcpdump y las preguntas de cada bloque) |

**Descomprime el kit dentro de tu repositorio** (queda la carpeta `kit-sad-p2/`): se entrega con `git push`.
El enunciado completo está en Moodle. Si algo se lía: `./lab.sh reiniciar` (tus ficheros no se borran).
