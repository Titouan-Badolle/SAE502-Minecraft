#!/usr/bin/env bash
# Vérification de bout en bout de l'infrastructure, à lancer SUR la VM :
#   bash tests/verification.sh
# ou depuis le poste d'administration :
#   ssh rt@192.168.119.6 bash -s < tests/verification.sh
# Code de retour 0 uniquement si tous les tests passent.
set -uo pipefail

ECHECS=0
test_ok() {  # test_ok "description" commande...
  local desc=$1; shift
  if "$@" > /dev/null 2>&1; then
    printf '  [OK]    %s\n' "$desc"
  else
    printf '  [ECHEC] %s\n' "$desc"; ECHECS=$((ECHECS + 1))
  fi
}
en_marche() { [ "$(docker inspect -f '{{.State.Running}}' "$1")" = true ]; }
sain()      { [ "$(docker inspect -f '{{.State.Health.Status}}' "$1")" = healthy ]; }
sql()       { docker exec CT-db sh -c "mariadb -uroot -p\"\$MARIADB_ROOT_PASSWORD\" -N -e \"$1\""; }

# portainer est un conteneur hors projet (installé pendant le TD), ignoré ici
seul_proxy_publie() {
  [ "$(docker ps --format '{{.Names}} {{.Ports}}' | grep -- '->' \
       | grep -v -e '^CT-proxy ' -e '^portainer ' | wc -l)" -eq 0 ]
}
redirection_https() { [ "$(curl -s -o /dev/null -w '%{http_code}' http://localhost)" = 301 ]; }
tables_luckperms() {
  local n
  n=$(sql "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='luckperms'")
  [ "${n:-0}" -gt 0 ]
}
cibles_up() {
  docker exec CT-monitoring wget -qO- 'http://localhost:9090/api/v1/query?query=min(up)' | grep -q '"1"\]'
}

echo "== Conteneurs"
for c in CT-proxy CT-serveur CT-serveur-node-exporter CT-db CT-db-mysqld-exporter \
         CT-db-node-exporter CT-monitoring CT-monitoring-prometheus; do
  test_ok "$c démarré" en_marche "$c"
done
test_ok "CT-db en bonne santé (healthcheck)" sain CT-db
test_ok "CT-serveur en bonne santé (healthcheck)" sain CT-serveur

echo "== Réseau et proxy"
test_ok "réseau infra_mc en 172.30.52.0/24" \
  sh -c "docker network inspect infra_mc | grep -q '172.30.52.0/24'"
test_ok "seul CT-proxy publie des ports" seul_proxy_publie
test_ok "HTTP redirige vers HTTPS" redirection_https
test_ok "Grafana répond en HTTPS via Nginx" curl -sfk https://localhost/api/health
test_ok "port Minecraft 25565 ouvert" timeout 3 bash -c '</dev/tcp/127.0.0.1/25565'

echo "== Applications"
test_ok "serveur Minecraft répond en RCON" docker exec CT-serveur rcon-cli list
test_ok "LuckPerms a créé ses tables dans MariaDB" tables_luckperms
test_ok "toutes les cibles Prometheus sont UP" cibles_up
test_ok "tableau de bord Grafana provisionné" \
  test -f /opt/infra_mc/monitoring/grafana-provisioning/dashboards/infra_mc.json

echo "== Maintenance"
test_ok "scripts de sauvegarde et restauration installés" \
  test -f /usr/local/sbin/infra_mc-backup.sh -a -f /usr/local/sbin/infra_mc-restore.sh
# La crontab de root n'est lisible que par root
if [ "$(id -u)" -eq 0 ]; then
  test_ok "sauvegarde quotidienne planifiée (cron root)" \
    sh -c "crontab -l -u root | grep -q infra_mc-backup"
else
  echo "  [--]    cron non vérifié (relancer avec sudo pour ce test)"
fi
echo
if [ "$ECHECS" -eq 0 ]; then
  echo "Tous les tests sont passés."
else
  echo "$ECHECS test(s) en échec."
fi
exit "$ECHECS"
