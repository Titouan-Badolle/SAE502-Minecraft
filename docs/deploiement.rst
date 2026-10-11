Déploiement
===========

Prérequis
---------

* VM Ubuntu 26.04 avec ``docker-ce``, compte ``rt`` membre du groupe ``sudo``.
* Poste d'administration avec Ansible (testé : ansible-core 2.20) et les
  collections ``community.docker``, ``community.general``, ``community.crypto``,
  ``ansible.posix``.
* Clé publique SSH du poste ajoutée dans ``ssh_authorized_keys``
  (``group_vars/all/main.yml``) et dans ``~/.ssh/authorized_keys`` de ``rt``
  pour le premier accès.
* Mot de passe Vault dans ``~/.vault_pass_sae502`` (droits 600).

Lancement
---------

.. code-block:: bash

   git clone https://github.com/Titouan-Badolle/SAE502-Minecraft.git
   cd SAE502-Minecraft
   ./deploy.sh -K                          # en SSH depuis le poste d'administration
   ./deploy.sh -K -i inventory_local.yml   # directement sur la VM

``-K`` demande le mot de passe ``sudo`` de ``rt``. ``deploy.sh`` positionne
``ANSIBLE_CONFIG`` : sur un dossier accessible en écriture par tous (``/mnt/c``
sous WSL), Ansible ignore sinon ``ansible.cfg``.

Ordre d'exécution des rôles
---------------------------

#. ``role_init_host`` — UFW, clés SSH et durcissement de ``sshd``, répertoires,
   certificat auto-signé.
#. ``role_infrastructure`` — réseau ``infra_mc``, CT-db (+ utilisateur SQL de
   supervision et exporters), CT-monitoring (Grafana, Prometheus, source de
   données et tableau de bord provisionnés), CT-proxy. Se termine par un test
   HTTPS de bout en bout vers Grafana.
#. ``role_game_deploy`` — CT-serveur (PaperMC + LuckPerms sur MariaDB) et son
   node_exporter, attente du healthcheck, puis ouverture du flux 25565 dans Nginx.
#. ``role_maintenance`` — scripts de sauvegarde et de restauration, cron
   quotidien, première sauvegarde si aucune n'existe.

Variables principales
---------------------

Toutes dans ``group_vars/all/main.yml`` :

===========================  ====================  ==================================
Variable                     Valeur                Rôle
===========================  ====================  ==================================
``infra_subnet``             172.30.52.0/24        réseau Docker dédié
``mc_version``               1.21.8                version de Minecraft
``mc_memory``                1536M                 mémoire de la JVM
``backup_hour``              3                     heure de la sauvegarde quotidienne
``backup_retention_days``    7                     durée de conservation
``*_image``                  versions figées       reproductibilité du déploiement
===========================  ====================  ==================================

Points particuliers
-------------------

* **sudo-rs** : Ubuntu 26.04 utilise ``sudo-rs`` dont l'invite n'est pas
  reconnue par Ansible (attente de 12 s puis échec). L'inventaire force
  ``ansible_become_exe: sudo.ws``, le sudo classique.
* **docker-ce** : le rôle vérifie Docker sans installer ``docker.io``, qui
  remplacerait ``docker-ce``.
* **Idempotence** : un second lancement doit afficher ``changed=0``.
