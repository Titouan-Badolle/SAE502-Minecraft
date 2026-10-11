Architecture
============

Vue d'ensemble
--------------

::

                    Joueurs (TCP 25565)      Administrateur (HTTPS 443)
                              \                  /
                               v                v
   VM rt-sae502 (192.168.119.6/20, esx11) -- UFW : 22, 80, 443, 25565
   +----------------------------------------------------------------------+
   | réseau Docker infra_mc 172.30.52.0/24 (passerelle .1)                 |
   |                                                                      |
   |  CT-proxy .11       Nginx : stream 25565 -> .12, HTTPS 443 -> .14     |
   |  CT-serveur .12     PaperMC 1.21.8 + LuckPerms   [+ node_exporter]    |
   |  CT-db .13          MariaDB 11.4   [+ mysqld_exporter, node_exporter] |
   |  CT-monitoring .14  Grafana 12     [+ Prometheus]                     |
   +----------------------------------------------------------------------+

Seul **CT-proxy** publie des ports sur la VM. Docker contournant UFW pour les
ports publiés, les autres conteneurs ne sont joignables que depuis ``infra_mc``.

Inventaire
----------

=====================  ======================================================
Machines               1 VM Ubuntu 26.04 (1 vCPU, 5,2 Go RAM, 30 Go)
Conteneurs (logiques)  4 : CT-proxy, CT-serveur, CT-db, CT-monitoring
Conteneurs Docker      8 (les exporters et Prometheus sont des « sidecars »)
Services               Nginx, PaperMC, MariaDB, Prometheus, Grafana,
                       2 node_exporter, mysqld_exporter
Rôles Ansible          4, exécutés par 1 playbook (``playbook.yml``)
Secrets                1 fichier chiffré ``group_vars/all/vault.yml``
=====================  ======================================================

Conteneurs « sidecars »
-----------------------

Une image officielle n'exécute qu'un processus. Pour regrouper plusieurs
services dans un même conteneur logique, les conteneurs secondaires utilisent
``network_mode: container:<parent>`` : ils partagent l'adresse IP et
``localhost`` du parent.

==========================  ==================  ==================================
Conteneur Docker            Partage le réseau   Port
==========================  ==================  ==================================
CT-monitoring-prometheus    CT-monitoring       9090 (lu par Grafana en localhost)
CT-db-mysqld-exporter       CT-db               9104 (lit MariaDB en 127.0.0.1)
CT-db-node-exporter         CT-db               9100
CT-serveur-node-exporter    CT-serveur          9100
==========================  ==================  ==================================

.. warning::
   Si le parent redémarre, il obtient une nouvelle pile réseau : le sidecar doit
   être redémarré après lui. Le handler ``Redémarrer Grafana`` et le script de
   restauration le font automatiquement.

Flux réseau
-----------

======================  ===================  =========  =================================
Source                  Destination          Port       Usage
======================  ===================  =========  =================================
Joueurs                 CT-proxy             25565      Nginx ``stream`` (TCP brut)
CT-proxy                CT-serveur           25565      relais vers PaperMC
Administrateur          CT-proxy             80 → 443   redirection puis HTTPS
CT-proxy                CT-monitoring        3000       reverse proxy vers Grafana
CT-serveur              CT-db                3306       LuckPerms (stockage ``mariadb``)
Prometheus              .12, .13             9100/9104  collecte (pull, toutes les 15 s)
Script de sauvegarde    CT-db, CT-serveur    —          ``docker exec`` (dump, RCON)
======================  ===================  =========  =================================

Arborescence sur la VM
----------------------

=========================================  =====================================
``/opt/infra_mc/proxy``                    ``nginx.conf``, ``stream.d/``, ``certs/``
``/opt/infra_mc/serveur``                  données PaperMC (monde, plugins)
``/opt/infra_mc/db``                       données MariaDB
``/opt/infra_mc/monitoring``               données et provisioning Grafana/Prometheus
``/var/backups/infra_mc``                  sauvegardes (root uniquement, 0700)
``/usr/local/sbin/infra_mc-*.sh``          scripts de sauvegarde et de restauration
=========================================  =====================================
