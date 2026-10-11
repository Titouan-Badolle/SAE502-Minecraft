# Projet SAÉ 5.02 - Infrastructure d'hébergement Minecraft automatisée

## Objectif du projet
Ce projet consiste à automatiser de bout en bout le déploiement d'une infrastructure d'hébergement de production pour serveurs de jeu (Minecraft PaperMC). L'objectif est de s'affranchir d'un hébergement clé en main en déployant un environnement sécurisé comprenant :
- Un proxy d'accès (Nginx).
- Le serveur de jeu (PaperMC).
- Une base de données isolée (MariaDB).
- Une supervision complète (Prometheus/Grafana).
- Des sauvegardes automatisées avec tests de restauration.

## Architecture
L'ensemble est orchestré via Ansible et déployé à l'aide des modules `community.docker` sur une machine virtuelle hôte (192.168.119.6). 
Les conteneurs communiquent sur un réseau bridge Docker dédié `infra_mc` (172.30.52.0/24) pour éviter tout conflit de routage.

## Prérequis
Pour déployer cette infrastructure, il est nécessaire d'avoir :
- Une machine cible sous Linux (Debian/Ubuntu) accessible via SSH.
- Ansible installé sur la machine exécutant le playbook.
- Le mot de passe du coffre-fort `Ansible Vault` pour déchiffrer les secrets (mots de passe SQL, RCON, certificats).

## Comment lancer le déploiement
1. Cloner ce dépôt sur la machine d'exécution.
2. S'assurer que la machine hôte cible est bien renseignée dans le fichier `inventory.yml`.
3. Lancer le playbook principal avec la commande suivante :
   ```bash
   ansible-playbook -i inventory.yml playbook.yml --ask-vault-pass