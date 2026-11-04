#!/bin/bash
# Arranque de cada máquina de Bodegas Atlántico según su ROL: fw, tienda, oficina, erp, cliente, enologa, comercial
# o reservas (el WAF es la imagen de OWASP). Bloques C y D solo si el complemento ha traído fw/suricata/ y reservas/.
# En el firewall también: arranque.sh suricata ids|ips  (lo usa ./lab.sh para arrancar Suricata en un modo u otro)
set -u
ROL=${ROL:-?}

# Suricata (bloque C): IDS = mira una copia del tráfico de la wan (af-packet) · IPS = el tráfico pasa POR él (NFQUEUE)
suricata_modo() {
  pkill -x Suricata-Main 2>/dev/null; pkill -x suricata 2>/dev/null
  # Esperar a que el anterior suelte la tarjeta: si no, el nuevo muere con «cluster-id 1 already in use»
  for _ in $(seq 20); do pgrep -f '^suricata ' >/dev/null || break; sleep 0.5; done
  pkill -9 -f '^suricata ' 2>/dev/null; sleep 0.5
  nft delete table inet ips 2>/dev/null
  rm -f /run/suricata.pid; mkdir -p /var/log/suricata
  # -k none: no mirar las sumas de comprobación (en Docker las calcula la tarjeta «de mentira» y saldrían mal)
  local op=(-c /etc/suricata/suricata.yaml -S /lab/suricata/local.rules -l /var/log/suricata -k none -D --pidfile /run/suricata.pid)
  if [ "$1" = ips ]; then
    nft -f - <<'EOF'
table inet ips {
  chain forward {
    type filter hook forward priority -10;
    queue num 0 bypass
  }
}
EOF
    suricata "${op[@]}" -q 0 >/dev/null 2>&1
  else
    suricata "${op[@]}" --af-packet=wan >/dev/null 2>&1
  fi
}
if [ "${1:-}" = suricata ]; then suricata_modo "${2:-ids}"; exit; fi

# Prompt de color con el nombre de la máquina, para no confundirse de terminal
case "$ROL" in
  fw) C=31 ;; tienda) C=33 ;; oficina) C=34 ;; erp) C=36 ;; cliente) C=35 ;; enologa) C=32 ;; comercial) C=32 ;; reservas) C=36 ;; *) C=37 ;;
esac
grep -q "PS1=" /root/.bashrc || echo "PS1='\[\e[1;${C}m\]${ROL}\[\e[0m\]:\w# '" >> /root/.bashrc

# Servicios simulados: cada puerto contesta quién es y desde qué IP le llega la petición (curl http://IP:PUERTO)
pagina() {
  local nombre=$1; shift
  { echo "server {"; for p in "$@"; do echo "  listen $p;"; done
    printf '  location / { default_type text/plain; return 200 "%s (puerto $server_port) · te llega una peticion desde $remote_addr\\n"; }\n}\n' "$nombre"
  } > /etc/nginx/sites-enabled/lab
  nginx
}

# Lo que se edita vive en /lab (tu carpeta fw/, enologa/, comercial/ o reservas/)
if [ -d /lab ]; then
  [ -f /lab/nftables.conf ] && ln -sf /lab/nftables.conf /etc/nftables.conf
  mkdir -p /lab/wireguard && rm -rf /etc/wireguard && ln -s /lab/wireguard /etc/wireguard
  # Lo que se crea aquí dentro (claves, registros…) es de root y desde tu ordenador no podrías editarlo:
  # cada 2 s pasa a ser del dueño de la carpeta (tú)
  ( while sleep 2; do find /lab ! -user "$(stat -c %u /lab)" -exec chown -h "$(stat -c %u:%g /lab)" {} + 2>/dev/null; done ) &
fi

case "$ROL" in
  fw)
    # Las interfaces se llaman por la red a la que van: wan, dmz y lan (Docker las crea como eth0, eth1…)
    for i in $(ls /sys/class/net | grep -v -e '^lo$' -e '^wg'); do
      ip=$(ip -4 -o addr show "$i" | awk '{print $4}')
      case "$ip" in 198.51.100.*) n=wan ;; 172.16.20.*) n=dmz ;; 172.16.10.*) n=lan ;; *) continue ;; esac
      ip link set "$i" down && ip link set "$i" name "$n" && ip link set "$n" up
    done
    ip route replace default via 198.51.100.1 dev wan 2>/dev/null
    pagina "SSH del firewall (simulado)" 22
    nft -f /etc/nftables.conf 2>/dev/null || echo "nftables.conf tiene errores: corrígelo y ./lab.sh aplicar"
    [ -s /etc/wireguard/wg0.conf ] && wg-quick up wg0 >/dev/null 2>&1
    # Bloque C: si el complemento ha traído las reglas de Suricata, arráncalo vigilando la wan
    [ -f /lab/suricata/local.rules ] && suricata_modo ids
    ;;
  tienda)
    ip route replace default via 172.16.20.254
    # La web de la tienda (misma respuesta en 80, 443 y el 22 simulado para los bloques A y B)
    cat > /etc/nginx/sites-enabled/tienda <<'EOF'
server {
  listen 80 default_server; listen 443; listen 22;
  default_type text/plain;
  location /contacto { return 200 "Tienda de Bodegas Atlantico · gracias por tu comentario\n"; }
  location /catas    { return 200 "Tienda de Bodegas Atlantico · catas · nota recibida\n"; }
  location /         { return 200 "Tienda online de Bodegas Atlantico · producto $arg_id\n"; }
}
EOF
    nginx
    # Para el bloque D, la tienda hace de «PC del administrador»: lleva la llave de admin para entrar en reservas
    [ -f /etc/lab/admin ] && { mkdir -p /root/.ssh; cp /etc/lab/admin /root/.ssh/id_ed25519; chmod 600 /root/.ssh/id_ed25519;
      printf 'Host *\n  StrictHostKeyChecking no\n  UserKnownHostsFile /dev/null\n  LogLevel ERROR\n' > /root/.ssh/config; }
    ;;
  oficina) ip route replace default via 172.16.10.254; pagina "PC de la oficina" 80 22 ;;
  erp)     ip route replace default via 172.16.10.254; pagina "ERP de la bodega" 8080 5432 ;;
  cliente) ip route replace 172.16.0.0/16 via 198.51.100.254; pagina "Servidor de Internet" 80 ;;
  enologa|comercial) [ -s /etc/wireguard/wg0.conf ] && wg-quick up wg0 >/dev/null 2>&1 ;;
  reservas)
    # Bloque D · un servidor «recién instalado y descuidado» en la DMZ (172.16.20.40)
    ip route replace default via 172.16.20.254
    if [ ! -e /etc/lab/sembrado ]; then
      echo "root:bodega2026" | chpasswd
      useradd -m -s /bin/bash admin && echo "admin:Admin1234" | chpasswd
      [ -f /etc/lab/admin.pub ] && { mkdir -p /home/admin/.ssh; cp /etc/lab/admin.pub /home/admin/.ssh/authorized_keys;
        chown -R admin:admin /home/admin/.ssh; chmod 700 /home/admin/.ssh; chmod 600 /home/admin/.ssh/authorized_keys; }
      useradd -o -u 0 -g 0 -M -d /root -s /bin/bash soporte && echo "soporte:soporte" | chpasswd   # una «puerta trasera» (UID 0)
      cp /bin/bash /usr/local/bin/copia-seguridad && chmod u+s /usr/local/bin/copia-seguridad       # un SUID de más
      printf '\n# Lo que dejó el instalador\nPermitRootLogin yes\nPasswordAuthentication yes\nX11Forwarding yes\nMaxAuthTries 6\n' >> /etc/ssh/sshd_config
      sed -i 's/^\s*server_tokens off;.*/\t# server_tokens off;/' /etc/nginx/nginx.conf                  # dice su versión
      echo '<h1>Servidor de reservas de la bodega</h1>' > /var/www/html/index.html
      touch /etc/lab/sembrado
    fi
    # Lo que se edita vive en /lab (tu carpeta reservas/): SSH, Nginx y Fail2ban leen de ahí
    mkdir -p /lab/ssh /lab/nginx /lab/fail2ban
    rm -rf /etc/ssh/sshd_config.d /etc/nginx/conf.d && ln -s /lab/ssh /etc/ssh/sshd_config.d && ln -s /lab/nginx /etc/nginx/conf.d
    ln -sf /lab/fail2ban/jail.local /etc/fail2ban/jail.local
    printf 'server { listen 80 default_server; root /var/www/html; }\n' > /etc/nginx/sites-enabled/reservas
    # El registro del sistema: los intentos de SSH quedan en /var/log/auth.log, que es lo que lee Fail2ban
    sed -i '/imklog/s/^/#/' /etc/rsyslog.conf; rm -f /run/rsyslogd.pid; rsyslogd
    mkdir -p /run/sshd && ssh-keygen -A >/dev/null 2>&1
    /usr/sbin/sshd || echo "La configuración de SSH tiene errores: sshd -t"
    nginx || echo "La configuración de Nginx tiene errores: nginx -t"
    fail2ban-client -x start >/dev/null 2>&1 || echo "Fail2ban no arranca: fail2ban-client -d"
    ;;
esac
echo "$ROL listo"
exec sleep infinity
