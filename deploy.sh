#!/usr/bin/env bash
# Lance le déploiement complet. Usage : ./deploy.sh [options d'ansible-playbook]
#   ./deploy.sh -K                            depuis WSL, vers la VM (SSH)
#   ./deploy.sh -K -i inventory_local.yml     depuis la VM elle-même (connexion locale)
set -e
cd "$(dirname "$0")"
# Le dossier est sur /mnt/c (accessible en écriture par tous) : Ansible y
# ignore ansible.cfg, sauf si on le désigne explicitement.
export ANSIBLE_CONFIG=./ansible.cfg
exec ansible-playbook playbook.yml "$@"
