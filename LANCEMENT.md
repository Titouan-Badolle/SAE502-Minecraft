# Guide de lancement

Toutes les commandes PowerShell se lancent **depuis le dossier du projet**.
Ansible tourne dans Ubuntu (WSL) : `wsl -d Ubuntu -u root -- <commande>`.

## 0. Avant de commencer

- Être sur le réseau de l'IUT ou connecté au **VPN** (sinon la VM 192.168.119.6 est injoignable).
- Vérifier que la VM répond :
  ```powershell
  Test-NetConnection 192.168.119.6 -Port 22
  ```
  `TcpTestSucceeded : True` → OK.

## 1. Déployer / mettre à jour toute l'infrastructure

```powershell
wsl -d Ubuntu -u root -- ./deploy.sh -K
```

- `BECOME password` : mot de passe de `rt` sur la VM (pour `sudo`).
- Le mot de passe Vault est lu automatiquement dans `~/.vault_pass_sae502` (WSL).
- Résultat attendu : `failed=0`. Un second lancement doit donner `changed=0`.
- Premier déploiement sur une VM vierge : 5 à 10 min (téléchargement des images,
  génération du monde).

## 1 bis. Vérifier que tout fonctionne (20 tests)

```powershell
wsl -d Ubuntu -u root -- bash -c "ssh rt@192.168.119.6 bash -s < tests/verification.sh"
```

Conteneurs, healthchecks, réseau, HTTPS, port 25565, RCON, tables LuckPerms,
cibles Prometheus, sauvegardes. Attendu : `Tous les tests sont passés.`
(Sur la VM, `sudo bash tests/verification.sh` vérifie aussi le cron.)

## 2. Se connecter à la VM en SSH

Connexion **par clé uniquement** (mot de passe désactivé).

- Termius : hôte `192.168.119.6`, utilisateur `rt`, clé `termius-titouan`.
- Ou depuis PowerShell :
  ```powershell
  wsl -d Ubuntu -u root -- ssh rt@192.168.119.6
  ```

## 3. Jouer sur le serveur Minecraft

Version du jeu : **1.21.8**.

- **Depuis le réseau de l'IUT** : adresse `192.168.119.6`.
- **Depuis le VPN** (port 25565 filtré) : ouvrir un tunnel SSH dans un PowerShell
  **laissé ouvert** pendant la partie :
  ```powershell
  wsl -d Ubuntu -u root -- ssh -N -L 25565:127.0.0.1:25565 rt@192.168.119.6
  ```
  puis se connecter à **`localhost`** dans le jeu. `Ctrl+C` ferme le tunnel.

Se donner les droits administrateur (sur la VM) :
```bash
docker exec CT-serveur rcon-cli op <pseudo>
```

## 4. Supervision (Grafana)

- Navigateur : **https://192.168.119.6** (accepter l'avertissement : certificat auto-signé).
- Utilisateur `admin`, mot de passe :
  ```powershell
  wsl -d Ubuntu -u root -- bash -c "ANSIBLE_CONFIG=./ansible.cfg ansible-vault view group_vars/all/vault.yml"
  ```
  (`vault_grafana_admin_password`)
- Tableau de bord : *Dashboards → Infrastructure → Infrastructure Minecraft*.

## 5. Sauvegarder / restaurer (sur la VM)

```bash
sudo /usr/local/sbin/infra_mc-backup.sh      # sauvegarde immédiate
sudo ls -lh /var/backups/infra_mc            # sauvegardes disponibles
sudo /usr/local/sbin/infra_mc-restore.sh     # restaure la plus récente
```

Sauvegarde automatique chaque jour à 3 h, conservée 7 jours.

## 6. Arrêter / redémarrer le serveur (sur la VM)

```bash
docker ps --format '{{.Names}}  {{.Status}}'   # état des 8 conteneurs
docker stop CT-serveur                         # arrêter Minecraft
docker start CT-serveur                        # le relancer
docker restart CT-serveur-node-exporter        # à faire après un redémarrage de CT-serveur
docker logs -f CT-serveur                      # console du serveur (Ctrl+C pour quitter)
```

**Après un redémarrage de la VM** : relancer le déploiement (étape 1). Il remet
les conteneurs « sidecars » (Prometheus, exporters) dans le bon ordre.

## 7. Démonstration (ordre conseillé)

1. `./deploy.sh -K` → `failed=0`, puis une 2e fois → `changed=0` (idempotence).
2. `tests/verification.sh` → tous les tests [OK] ; Grafana : les 4 cibles **UP**.
3. Connexion au serveur Minecraft, construction d'un repère.
4. `infra_mc-backup.sh` → destruction du repère → `infra_mc-restore.sh` → le repère revient.
5. `sudo ufw status` et `ssh` avec mot de passe refusé → sécurité.
