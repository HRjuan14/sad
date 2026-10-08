#!/usr/bin/env bash
#
# lab.sh — Mando a distancia del laboratorio de la Práctica 1 de SAD (SecureCorp).
#
# No necesitas saber Docker: todo lo que hace falta está aquí.
#   ./lab.sh ayuda        -> lista de órdenes
#
set -uo pipefail
cd "$(dirname "$0")"

SRV=sad-p1-servidor
CLI=sad-p1-cliente
WEB=sad-p1-web
BASE="dc=securecorp,dc=local"
ADMIN="cn=admin,$BASE"
ADMINPW="SecureCorp2026"
REINO="SECURECORP.LOCAL"

# ---------- colores ----------
if [ -t 1 ]; then
    R=$'\e[1;31m'; V=$'\e[1;32m'; A=$'\e[1;33m'; Z=$'\e[1;34m'; N=$'\e[1m'; X=$'\e[0m'
else
    R=""; V=""; A=""; Z=""; N=""; X=""
fi
info()  { echo "${Z}▶${X} $*"; }
bien()  { echo "${V}✔${X} $*"; }
aviso() { echo "${A}!${X} $*"; }
error() { echo "${R}✘ $*${X}" >&2; }

# ---------- comprobaciones previas ----------
necesita_docker() {
    if ! command -v docker >/dev/null 2>&1; then
        error "Docker no está instalado en este equipo."; exit 1
    fi
    if ! docker info >/dev/null 2>&1; then
        error "Docker está instalado pero no puedo usarlo."
        echo "  - ¿Está arrancado?           sudo systemctl start docker"
        echo "  - ¿Tu usuario está en el grupo docker?  sudo usermod -aG docker \$USER  (y cierra sesión)"
        exit 1
    fi
    if ! docker compose version >/dev/null 2>&1; then
        error "Falta 'docker compose' (el plugin de Docker Compose v2)."; exit 1
    fi
}

esta_corriendo() { [ "$(docker inspect -f '{{.State.Running}}' "$1" 2>/dev/null)" = "true" ]; }

necesita_lab() {
    necesita_docker
    if ! esta_corriendo "$SRV" || ! esta_corriendo "$CLI"; then
        error "El laboratorio no está arrancado."
        echo "  Arráncalo con:  ./lab.sh arrancar"
        exit 1
    fi
}

cargar_alumno() {
    ALUMNO_UID=""; ALUMNO_NOMBRE=""
    # shellcheck disable=SC1091
    [ -f alumno.conf ] && . ./alumno.conf
    if [ -z "$ALUMNO_UID" ]; then
        error "Todavía no me has dicho quién eres. Ejecuta primero:  ./lab.sh preparar"
        exit 1
    fi
}

# Los ficheros creados dentro de los contenedores son de root: los devolvemos a tu usuario
# para que puedas abrirlos, editarlos y borrarlos desde tu ordenador.
devolver_permisos() {
    esta_corriendo "$SRV" && docker exec "$SRV" chown -R "$(id -u):$(id -g)" /pki /ldif 2>/dev/null
    true
}

# ---------- órdenes ----------
cmd_ayuda() {
    cat <<EOF
${N}Laboratorio SecureCorp — Práctica 1 de SAD${X}

  ${N}./lab.sh preparar${X}     (1 vez) Tus datos y construir la imagen
  ${N}./lab.sh arrancar${X}     Encender las máquinas
  ${N}./lab.sh servidor${X}     Abrir una terminal en el SERVIDOR (LDAP + Kerberos)  ${R}[rojo]${X}
  ${N}./lab.sh cliente${X}      Abrir una terminal en el CLIENTE (PC de un empleado) ${V}[verde]${X}
  ${N}./lab.sh reiniciar${X}    Reiniciar el servidor (= systemctl restart slapd). No borra nada
  ${N}./lab.sh rescate${X}      Si el servidor NO arranca: entrar a arreglarlo
  ${N}./lab.sh logs ldap${X}    Ver en directo lo que hace slapd           (Ctrl+C para salir)
  ${N}./lab.sh logs kerberos${X} Ver en directo lo que hace el KDC          (Ctrl+C para salir)
  ${N}./lab.sh estado${X}       ¿Están encendidas las máquinas?
  ${N}./lab.sh comprobar${X}    Corrige tu práctica: qué está hecho y qué falta
  ${N}./lab.sh entregar${X}     Genera el fichero .zip para subir a Moodle
  ${N}./lab.sh parar${X}        Apagar las máquinas (no se pierde nada)
  ${N}./lab.sh reset${X}        ${R}Borrar las máquinas y empezar de cero${X} (pki/ y ldif/ se conservan)

  Directorio en el navegador: http://localhost:8081
     usuario: $ADMIN    contraseña: $ADMINPW

  Para salir de una terminal del servidor o del cliente: ${N}exit${X} (o Ctrl+D)
EOF
}

cmd_preparar() {
    necesita_docker
    echo "${N}== 1. Tus datos ==${X}"
    local nombre uid
    if [ -f alumno.conf ]; then
        # shellcheck disable=SC1091
        . ./alumno.conf
        aviso "Ya estabas registrado como: $ALUMNO_NOMBRE ($ALUMNO_UID)"
        read -r -p "¿Quieres cambiarlo? [s/N] " r
        [[ "$r" =~ ^[sS] ]] || { nombre="$ALUMNO_NOMBRE"; uid="$ALUMNO_UID"; }
    fi
    if [ -z "${uid:-}" ]; then
        read -r -p "Nombre y apellidos: " nombre
        echo "Tu usuario: inicial del nombre + primer apellido, en minúsculas, sin tildes ni eñes."
        echo "   Ejemplo: María Núñez Pérez -> mnunez"
        while true; do
            read -r -p "Tu usuario: " uid
            [[ "$uid" =~ ^[a-z][a-z0-9]{2,19}$ ]] && break
            error "Solo minúsculas y números, empezando por letra (3-20 caracteres). Prueba otra vez."
        done
        printf 'ALUMNO_NOMBRE="%s"\nALUMNO_UID="%s"\n' "$nombre" "$uid" > alumno.conf
    fi
    bien "Alumno: $nombre — usuario: ${N}$uid${X}"

    echo; echo "${N}== 2. Construyendo la imagen (la primera vez tarda unos minutos) ==${X}"
    docker compose build || { error "Ha fallado la construcción. ¿Tienes Internet?"; exit 1; }
    docker compose pull phpldapadmin >/dev/null 2>&1 || true
    echo; bien "Listo. Ahora:  ./lab.sh arrancar"
}

cmd_arrancar() {
    necesita_docker
    [ -f alumno.conf ] || aviso "Aún no has hecho ./lab.sh preparar (tus datos). Hazlo cuando puedas."
    docker compose up -d || { error "No he podido arrancar. Lee el mensaje de arriba."; exit 1; }
    sleep 2
    cmd_estado
    echo
    echo "Siguiente paso:  ${N}./lab.sh servidor${X}   o   ${N}./lab.sh cliente${X}"
}

cmd_estado() {
    necesita_docker
    local m
    for m in "$SRV" "$CLI" sad-p1-phpldapadmin; do
        if esta_corriendo "$m"; then bien "$m encendida"; else error "$m apagada"; fi
    done
    esta_corriendo "$WEB" && bien "$WEB encendida (Parte C)"
    if esta_corriendo "$SRV"; then
        local s
        s=$(docker exec "$SRV" bash -c '. /etc/default/slapd 2>/dev/null; echo "${SLAPD_SERVICES:-ldap:/// ldapi:///}"')
        echo "  slapd escucha en: $s"
        if docker exec "$SRV" pgrep -x krb5kdc >/dev/null; then echo "  KDC de Kerberos: funcionando"
        else echo "  KDC de Kerberos: parado (normal hasta que crees el reino en el bloque B)"; fi
    fi
}

cmd_entrar() {
    local quien=$1 cont=$2
    necesita_lab
    echo "Entrando en el ${N}$quien${X}. Para volver a tu ordenador: ${N}exit${X}"
    docker exec -it -w /root "$cont" bash
    devolver_permisos
    echo "Has vuelto a TU ordenador."
}

cmd_reiniciar() {
    necesita_docker   # no necesita_lab: hay que poder reiniciar un servidor que se ha caído
    info "Reiniciando el servidor (como un systemctl restart slapd)..."
    docker compose restart servidor >/dev/null 2>&1
    sleep 3
    if esta_corriendo "$SRV"; then
        bien "Servidor reiniciado."
        docker logs "$SRV" 2>&1 | grep -E "escuchando|KDC de" | tail -1 | sed "s/^/  /"
    else
        error "¡El servidor NO ha arrancado! slapd ha fallado al iniciar."
        echo "  Mira por qué (las últimas líneas suelen decirlo):"
        docker logs --tail 15 "$SRV" 2>&1 | sed 's/^/     /'
        echo
        echo "  Pistas: ¿has escrito bien SLAPD_SERVICES en /etc/default/slapd?"
        echo "          ¿las rutas y permisos de /etc/ldap/tls son correctos?"
        echo "  Para entrar y arreglarlo aunque slapd no arranque:  ./lab.sh rescate"
    fi
}

# Si slapd no arranca, el contenedor servidor se para y no se puede entrar.
# "rescate" abre una terminal sobre el MISMO disco del servidor sin arrancar slapd.
cmd_rescate() {
    necesita_docker
    aviso "Modo rescate: terminal en el disco del servidor SIN arrancar slapd."
    echo "   Arregla lo que falle (p. ej. nano /etc/default/slapd), sal con exit y haz ./lab.sh reiniciar"
    docker commit "$SRV" sad-p1-rescate >/dev/null || { error "No encuentro la máquina servidor."; exit 1; }
    docker rm -f sad-p1-rescate-tmp >/dev/null 2>&1
    docker run -it --name sad-p1-rescate-tmp --hostname servidor -w /root \
        -v "$PWD/pki:/pki" -v "$PWD/ldif:/ldif" sad-p1-rescate bash
    # Copiamos los ficheros de configuración arreglados de vuelta al servidor
    for f in /etc/default/slapd /etc/ldap/slapd.d /etc/ldap/tls; do
        docker cp -a "sad-p1-rescate-tmp:$f" - 2>/dev/null | docker cp -a - "$SRV:$(dirname "$f")" 2>/dev/null
    done
    docker rm -f sad-p1-rescate-tmp >/dev/null 2>&1
    docker rmi sad-p1-rescate >/dev/null 2>&1
    bien "Cambios copiados al servidor. Ahora:  ./lab.sh reiniciar"
}

cmd_logs() {
    necesita_lab
    case "${1:-}" in
        ldap)     info "Log de slapd (Ctrl+C para salir)"; docker logs -f --tail 20 "$SRV" ;;
        kerberos) info "Log del KDC (Ctrl+C para salir)"; docker exec -it "$SRV" tail -n 20 -F /var/log/krb5kdc.log ;;
        *)        error "Dime cuál:  ./lab.sh logs ldap   o   ./lab.sh logs kerberos" ;;
    esac
}

cmd_parar() {
    necesita_docker
    devolver_permisos
    docker compose stop && bien "Máquinas apagadas. Nada se ha borrado: ./lab.sh arrancar para seguir."
}

cmd_reset() {
    necesita_docker
    echo "${R}${N}Esto BORRA el servidor y el cliente:${X} el directorio LDAP, el reino Kerberos y"
    echo "toda la configuración que hayas hecho dentro de las máquinas."
    echo "Se conservan tus carpetas pki/ y ldif/ (certificados y LDIF) y respuestas.md."
    read -r -p "Escribe BORRAR para confirmar: " r
    [ "$r" = "BORRAR" ] || { echo "Cancelado."; exit 0; }
    devolver_permisos
    docker compose down && bien "Máquinas borradas. Para empezar de nuevo:  ./lab.sh arrancar"
}

# ---------- corrección automática ----------
OK=0; TOTAL=0
punto() {   # punto "Descripción" comando...
    local desc=$1; shift
    TOTAL=$((TOTAL+1))
    if "$@" >/dev/null 2>&1; then
        OK=$((OK+1)); echo "   ${V}✔${X} $desc"
    else
        echo "   ${R}✘${X} $desc"
    fi
}
en_srv() { docker exec "$SRV" bash -c "$1"; }
en_cli() { docker exec "$CLI" bash -c "$1"; }
ldap_admin() {  # búsqueda como admin por el socket local (funciona aunque cierres 389 y el anónimo)
    docker exec "$SRV" ldapsearch -x -LLL -H ldapi:/// -D "$ADMIN" -w "$ADMINPW" "$@"
}
existe_dn() { [ -n "$(ldap_admin -b "$1" -s base dn 2>/dev/null)" ]; }
es_miembro() { ldap_admin -b "cn=$1,ou=groups,$BASE" -s base member 2>/dev/null | grep -qi "member: uid=$2,ou=people,$BASE"; }
usuario_completo() {
    local u=$1 e
    e=$(ldap_admin -b "uid=$u,ou=people,$BASE" -s base objectClass userPassword mail 2>/dev/null)
    grep -qi "objectClass: posixAccount" <<<"$e" && grep -qi "objectClass: inetOrgPerson" <<<"$e" \
        && grep -q "^userPassword:" <<<"$e" && grep -q "^mail:" <<<"$e"
}
ous_existen() { existe_dn "ou=people,$BASE" && existe_dn "ou=groups,$BASE"; }
rrhh_ok() { es_miembro rrhh lromero && es_miembro rrhh mtorres; }
principal_existe() { en_srv "kadmin.local -q 'getprinc $1' 2>/dev/null | grep -q '^Principal: $1@'"; }
en_log() { en_srv "grep -qE '$1' /var/log/krb5kdc.log"; }

cmd_comprobar() {
    necesita_lab
    cargar_alumno
    local u=$ALUMNO_UID
    OK=0; TOTAL=0
    echo "${N}Comprobando la práctica de $ALUMNO_NOMBRE ($u)${X}"
    echo "(Que esté todo en verde NO es la nota: en la defensa tendrás que explicarlo.)"

    echo; echo "${N}BLOQUE A · Certificados y LDAP${X}"
    echo " A1 · La CA de SecureCorp"
    punto "Existe /pki/ca/ca.crt y es una CA (CA:TRUE)" \
        en_srv "openssl x509 -in /pki/ca/ca.crt -noout -text | grep -q 'CA:TRUE'"
    punto "Es autofirmada y su nombre lleva SecureCorp" \
        en_srv "s=\$(openssl x509 -in /pki/ca/ca.crt -noout -subject -nameopt RFC2253 | sed 's/^subject=//'); i=\$(openssl x509 -in /pki/ca/ca.crt -noout -issuer -nameopt RFC2253 | sed 's/^issuer=//'); [ \"\$s\" = \"\$i\" ] && grep -q SecureCorp <<<\"\$s\""
    punto "La clave /pki/ca/ca.key corresponde al certificado de la CA" \
        en_srv "test -s /pki/ca/ca.key && [ \"\$(openssl x509 -in /pki/ca/ca.crt -noout -pubkey)\" = \"\$(openssl pkey -in /pki/ca/ca.key -pubout)\" ]"

    echo " A2 · El certificado del servidor LDAP"
    punto "/pki/servidor/ldap.crt está firmado por tu CA" \
        en_srv "openssl verify -CAfile /pki/ca/ca.crt /pki/servidor/ldap.crt | grep -q ': OK'"
    punto "Tiene SAN con DNS:ldap.securecorp.local" \
        en_srv "openssl x509 -in /pki/servidor/ldap.crt -noout -ext subjectAltName | grep -q 'DNS:ldap.securecorp.local'"
    punto "La clave /pki/servidor/ldap.key corresponde al certificado" \
        en_srv "test -s /pki/servidor/ldap.key && [ \"\$(openssl x509 -in /pki/servidor/ldap.crt -noout -pubkey)\" = \"\$(openssl pkey -in /pki/servidor/ldap.key -pubout)\" ]"

    echo " A3 · El directorio de SecureCorp"
    punto "Existen ou=people y ou=groups" ous_existen
    local x
    for x in lromero "$u" mtorres; do
        punto "Usuario $x creado y con contraseña" usuario_completo "$x"
    done
    punto "Grupo rrhh con lromero y mtorres" rrhh_ok
    punto "Grupo sistemas contigo ($u)" es_miembro sistemas "$u"

    echo " A4 · LDAPS"
    punto "Certificados en /etc/ldap/tls, y la clave solo la lee openldap" \
        en_srv "test -f /etc/ldap/tls/ca.crt && test -f /etc/ldap/tls/ldap.crt && [ \"\$(stat -c %U /etc/ldap/tls/ldap.key)\" = openldap ] && [[ \"\$(stat -c %a /etc/ldap/tls/ldap.key)\" =~ ^6[04]0$ ]]"
    punto "slapd tiene configurado el certificado (cn=config)" \
        en_srv "ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b cn=config -s base olcTLSCertificateFile | grep -q '/etc/ldap/tls/ldap.crt'"
    punto "El cliente confía en tu CA (TLS_CACERT en /etc/ldap/ldap.conf)" \
        en_cli "grep -Eq '^TLS_CACERT[[:space:]]+/pki/ca/ca.crt' /etc/ldap/ldap.conf"
    punto "Desde el cliente funciona ldaps://ldap.securecorp.local (636)" \
        en_cli "ldapwhoami -x -H ldaps://ldap.securecorp.local -D '$ADMIN' -w $ADMINPW"
    punto "Desde el cliente ldap:// (389, en claro) ya NO funciona" \
        en_cli "! timeout 5 ldapwhoami -x -H ldap://ldap.securecorp.local -D '$ADMIN' -w $ADMINPW"

    echo; echo "${N}BLOQUE B · Kerberos${X}"
    echo " B1 · El reino"
    punto "Existe el reino $REINO" en_srv "test -f /var/lib/krb5kdc/principal && kadmin.local -q listprincs 2>/dev/null | grep -q 'krbtgt/$REINO@$REINO'"
    punto "El KDC está funcionando" en_srv "pgrep -x krb5kdc"

    echo " B2 · Usuarios y servicio"
    for x in lromero "$u" mtorres host/web.securecorp.local; do
        punto "Existe el principal $x" principal_existe "$x"
    done

    echo " B3 · Tickets"
    punto "Has pedido tu pulsera (TGT) con kinit (AS_REQ en el log)" en_log "AS_REQ.*ISSUE.*$u@$REINO for krbtgt"
    punto "Has pedido un ticket para host/web con kvno (TGS_REQ en el log)" en_log "TGS_REQ.*ISSUE.*$u@$REINO for host/web.securecorp.local"
    punto "Lucía también ha pedido su pulsera (AS_REQ de lromero)" en_log "AS_REQ.*ISSUE.*lromero@$REINO for krbtgt"

    echo; echo "${N}PARTE C · Por dentro: Dockerfile y docker-compose${X}"
    punto "web/Dockerfile completo (sin ____, con FROM, CMD y TLS_CACERT)" \
        bash -c "! grep -q '____' web/Dockerfile && grep -q '^FROM' web/Dockerfile && grep -q '^CMD' web/Dockerfile && grep -q TLS_CACERT web/Dockerfile"
    punto "docker-compose.yml tiene el servicio web" \
        bash -c "docker compose config --services 2>/dev/null | grep -qx web"
    punto "La máquina $WEB está encendida" esta_corriendo "$WEB"
    punto "Desde web funciona ldaps:// (confía en tu CA desde la imagen)" \
        docker exec "$WEB" ldapwhoami -x -H ldaps://ldap.securecorp.local -D "$ADMIN" -w "$ADMINPW"
    punto "Has hecho kinit $u DESDE la máquina web (AS_REQ desde su IP en el log)" \
        bash -c "ip=\$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $WEB) && [ -n \"\$ip\" ] && docker exec $SRV grep -qE \"AS_REQ.*\$ip: ISSUE.*$u@$REINO for krbtgt\" /var/log/krb5kdc.log"

    local obl_ok=$OK obl_total=$TOTAL
    echo; echo "${N}MINI-RETO (opcional) · Marta se va de vacaciones${X}"
    punto "mtorres no puede pedir tickets (DISALLOW_ALL_TIX)" \
        en_srv "kadmin.local -q 'getprinc mtorres' 2>/dev/null | grep -q DISALLOW_ALL_TIX"
    punto "Has comprobado que kinit mtorres falla (rechazo en el log)" en_log "AS_REQ.*CLIENT LOCKED OUT: mtorres@$REINO"

    echo
    local pct=$(( OK * 100 / TOTAL ))
    echo "${N}Obligatorio: $obl_ok de $obl_total · Total con el mini-reto: $OK de $TOTAL ($pct %)${X}"
    if [ "$OK" -eq "$TOTAL" ]; then bien "¡Todo en verde, mini-reto incluido! Prepárate para explicarlo en la defensa."
    elif [ "$obl_ok" -eq "$obl_total" ]; then bien "Todo lo obligatorio en verde. Te queda el mini-reto (opcional)."; fi
    return 0
}

cmd_entregar() {
    necesita_lab
    cargar_alumno
    devolver_permisos
    local u=$ALUMNO_UID d out
    d=$(mktemp -d)
    out="entrega/SAD-P1-$u"
    mkdir -p "$d/SAD-P1-$u"
    local e="$d/SAD-P1-$u"
    info "Recogiendo evidencias..."

    cmd_comprobar > "$e/01-comprobacion.txt" 2>&1
    sed -i 's/\x1b\[[0-9;]*m//g' "$e/01-comprobacion.txt"
    {
        echo "### Fecha: $(date '+%d/%m/%Y %H:%M')  ·  Alumno: $ALUMNO_NOMBRE ($u)"
        echo; echo "### Certificado de la CA"; en_srv "openssl x509 -in /pki/ca/ca.crt -noout -subject -issuer -dates -ext basicConstraints,keyUsage" 2>&1
        echo; echo "### Certificado del servidor"; en_srv "openssl x509 -in /pki/servidor/ldap.crt -noout -subject -issuer -dates -ext basicConstraints,keyUsage,extendedKeyUsage,subjectAltName" 2>&1
        echo; echo "### Verificación"; en_srv "openssl verify -CAfile /pki/ca/ca.crt /pki/servidor/ldap.crt" 2>&1
        echo; echo "### Permisos en /etc/ldap/tls"; en_srv "ls -l /etc/ldap/tls" 2>&1
        echo; echo "### /etc/default/slapd"; en_srv "grep ^SLAPD_SERVICES /etc/default/slapd" 2>&1
        echo; echo "### cn=config (TLS)"; en_srv "ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b cn=config -s base olcTLSCACertificateFile olcTLSCertificateFile olcTLSCertificateKeyFile" 2>&1
        echo; echo "### /etc/ldap/ldap.conf del cliente"; en_cli "grep -v '^#' /etc/ldap/ldap.conf | grep ." 2>&1
    } > "$e/02-certificados-y-tls.txt"
    ldap_admin -b "$BASE" '*' > "$e/03-directorio.ldif" 2>&1
    sed -i '/^userPassword::/d' "$e/03-directorio.ldif"
    {
        echo "### Principals"; en_srv "kadmin.local -q listprincs" 2>&1
        local x
        for x in "$u" lromero mtorres host/web.securecorp.local; do
            echo; echo "### getprinc $x"; en_srv "kadmin.local -q 'getprinc $x'" 2>&1
        done
    } > "$e/04-kerberos.txt"
    en_srv "cat /var/log/krb5kdc.log" > "$e/05-log-kdc.txt" 2>&1
    docker logs "$SRV" > "$e/06-log-slapd.txt" 2>&1

    cp -r ldif "$e/ldif"
    mkdir -p "$e/pki"
    find pki -name '*.crt' -exec cp --parents {} "$e/" \;
    find pki -name '*.cnf' -exec cp --parents {} "$e/" \; 2>/dev/null
    find pki -name '*.ext' -exec cp --parents {} "$e/" \; 2>/dev/null
    [ -f respuestas.md ] && cp respuestas.md "$e/"
    cp docker-compose.yml "$e/"
    [ -f web/Dockerfile ] && mkdir -p "$e/web" && cp web/Dockerfile "$e/web/"

    rm -f "$out.zip" "$out.tar.gz"
    if command -v zip >/dev/null 2>&1; then
        (cd "$d" && zip -qr - "SAD-P1-$u") > "$out.zip"; out="$out.zip"
    else
        tar -czf "$out.tar.gz" -C "$d" "SAD-P1-$u"; out="$out.tar.gz"
    fi
    rm -rf "$d"
    echo
    bien "Entrega generada: ${N}$out${X}"
    echo "   Lleva: comprobación, certificados (sin claves privadas), directorio, Kerberos, logs,"
    echo "   tus LDIF, docker-compose.yml, web/Dockerfile y respuestas.md. Súbelo a Moodle."
    [ -s respuestas.md ] || aviso "No encuentro respuestas.md con tus respuestas."
}

# ---------- principal ----------
case "${1:-ayuda}" in
    preparar)  cmd_preparar ;;
    arrancar|up|start) cmd_arrancar ;;
    servidor)  cmd_entrar SERVIDOR "$SRV" ;;
    cliente)   cmd_entrar CLIENTE "$CLI" ;;
    reiniciar|restart) cmd_reiniciar ;;
    rescate)   cmd_rescate ;;
    logs)      cmd_logs "${2:-}" ;;
    estado|status) cmd_estado ;;
    comprobar|check) cmd_comprobar ;;
    entregar)  cmd_entregar ;;
    parar|stop) cmd_parar ;;
    reset)     cmd_reset ;;
    ayuda|help|-h|--help) cmd_ayuda ;;
    *) error "No conozco la orden '$1'."; echo; cmd_ayuda; exit 1 ;;
esac
