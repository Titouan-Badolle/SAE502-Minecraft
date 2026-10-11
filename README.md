# Projet SAÉ 5.02 - Infrastructure d'hébergement Minecraft automatisée

## Objectif du projet
Ce projet consiste à automatiser de bout en bout le déploiement d'une infrastructure d'hébergement de production pour serveurs de jeu (Minecraft PaperMC). L'objectif est de s'affranchir d'un hébergement clé en main en déployant un environnement sécurisé comprenant :
- Un proxy d'accès (Nginx).
- Le serveur de jeu (PaperMC).
- Une base de données isolée (MariaDB).
- Une supervision complète (Prometheus/Grafana).
- Des sauvegardes automatisées avec tests de restauration.

## Architecture
L'ensemble est orchestré via Ansible et déployé à l'aide des modules `community.docker` sur une machine virtuelle hôte Ubuntu 26.04 (192.168.108.6, VM du TP réutilisée). 
Les conteneurs communiquent sur un réseau bridge Docker dédié `infra_mc` (172.30.52.0/24) pour éviter tout conflit de routage.

## Prérequis
- Une VM Ubuntu 26.04 avec Docker (docker-ce), accessible en SSH par clé.
- Ansible avec les collections `community.docker`, `community.general`, `community.crypto` et `ansible.posix`.
- Le mot de passe Ansible Vault dans le fichier `~/.vault_pass_sae502` (hors dépôt, droits 600).

## Comment lancer le déploiement
1. Cloner ce dépôt et vérifier l'hôte dans `inventory.yml`.
2. Lancer le playbook (`-K` demande le mot de passe sudo) :
   ```bash
   ./deploy.sh -K                          # depuis le poste d'administration, en SSH
   ./deploy.sh -K -i inventory_local.yml   # depuis la VM elle-même (connexion locale)
   ```

## Points techniques
- Ubuntu 26.04 utilise `sudo-rs` par défaut : Ansible ne reconnaît pas son invite de mot de passe, d'où `ansible_become_exe: sudo.ws` dans l'inventaire.
- Docker contourne UFW pour les ports publiés : seul CT-proxy publie des ports, les autres conteneurs restent sur `infra_mc`.

## Documentation
Documentation technique et tutoriel de reprise (Sphinx) dans `docs/` :
```bash
pip install -r docs/requirements.txt
sphinx-build -b html docs docs/_build/html   # puis ouvrir docs/_build/html/index.html
```
