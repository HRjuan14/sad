# Respuestas · Práctica 2 · Bodegas Atlántico

> Rellena este fichero en tu ordenador. Va en la entrega (`./lab.sh entregar`) y en la defensa te pueden preguntar por él.

## Bloque A · Piensa como un atacante (nmap)

Desde la calle: `./lab.sh cliente` y dentro `nmap -Pn -p 22,80,443,5432,8080 198.51.100.254`. Pega la salida:

```text
hrjuan@LinuxCasa:~/asignaturas/SAD/sad/practica2/kit-sad-p2$ ./lab.sh cliente
root@cliente:/# nmap -Pn -p 22,80,443,5432,8080 198.51.100.254
Starting Nmap 7.95 ( https://nmap.org ) at 2026-11-10 10:50 UTC
Nmap scan report for sad-p2-fw.sad-p2_calle (198.51.100.254)
Host is up (0.00011s latency).

PORT     STATE    SERVICE
22/tcp   filtered ssh
80/tcp   open     http
443/tcp  open     https
5432/tcp filtered postgresql
8080/tcp filtered http-proxy
MAC Address: 52:22:D5:48:B6:DC (Unknown)

Nmap done: 1 IP address (1 host up) scanned in 1.29 seconds
root@cliente:/# 

```

## Bloque A · El contador

Después de `./lab.sh comprobar`, mira `./lab.sh ver`. ¿Cuántos paquetes lleva el contador de A6? ¿Quién los ha mandado?

> Lleva 6 paquetes y lo ha eviado la tienda

## Bloque B · La prueba del cifrado

En el firewall (`./lab.sh fw`): `tcpdump -ni wan host 198.51.100.62 -c 6`. Mientras, en otra terminal, el comercial
(`./lab.sh comercial`) hace `curl http://172.16.10.20:8080`. Pega lo que sale en el firewall:

```text
hrjuan@LinuxCasa:~/asignaturas/SAD/sad/practica2/kit-sad-p2$ ./lab.sh fw
root@fw:/# tcpdump -ni wan host 198.51.100.62 -c 6
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on wan, link-type EN10MB (Ethernet), snapshot length 262144 bytes
10:37:42.561920 IP 198.51.100.62.53989 > 198.51.100.254.51820: UDP, length 96
10:37:42.563630 IP 198.51.100.254.51820 > 198.51.100.62.53989: UDP, length 96
10:37:42.564188 IP 198.51.100.62.53989 > 198.51.100.254.51820: UDP, length 96
10:37:42.564266 IP 198.51.100.62.53989 > 198.51.100.254.51820: UDP, length 176
10:37:42.564775 IP 198.51.100.254.51820 > 198.51.100.62.53989: UDP, length 96
10:37:42.564831 IP 198.51.100.254.51820 > 198.51.100.62.53989: UDP, length 304
6 packets captured
10 packets received by filter
0 packets dropped by kernel

```

En dos líneas: ¿qué se ve por la calle y qué NO se ve?

> Lo que se ve por la calle es el trafico UDP cifrado por el puerto 51820 y no se ve
> el trafico real las IPs privadas, peticiones HTTP ni datos al viajar encapsulado y cifrado

## Bloque C · Para la defensa (C4)

Del **mismo ataque** (la inyección a la web): ¿qué ve el vigilante de la red (el IDS) y qué ve el portero de la web? ¿Por
qué hacen falta los dos?

>

## Bloque D · La nota del servidor (D0 y D4)

Nota del análisis **antes** de bastionar (D0):

>

Nota **después** (D4). ¿Por qué no llega a 100? ¿Significa que el servidor sigue inseguro? Comenta un aviso que siga saliendo.

>
