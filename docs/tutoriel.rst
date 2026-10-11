Tutoriel de reprise
===================

.. note::
   Destiné à un technicien qui reprend l'infrastructure.
   TODO (Titouan) : relire et reformuler chaque étape avec mes propres mots.

1. Se connecter à la VM
-----------------------

La connexion par mot de passe est désactivée : il faut une clé SSH autorisée.

#. Générer une clé : ``ssh-keygen -t ed25519``
#. Envoyer la **clé publique** (``~/.ssh/id_ed25519.pub``) à l'administrateur,
   qui l'ajoute dans ``ssh_authorized_keys`` puis relance le playbook.
#. Se connecter : ``ssh rt@192.168.119.6``

2. Vérifier que tout fonctionne
-------------------------------

.. code-block:: bash

   docker ps --format '{{.Names}}  {{.Status}}'

Les 8 conteneurs doivent être ``Up`` ; CT-db et CT-serveur ``(healthy)``.
Dans Grafana, les 4 cibles du tableau de bord doivent être **UP**.

3. Rejoindre le serveur Minecraft
---------------------------------

Version **1.21.8**, adresse ``192.168.119.6``.
Si le port 25565 est filtré (VPN), passer par un tunnel SSH :

.. code-block:: bash

   ssh -N -L 25565:127.0.0.1:25565 rt@192.168.119.6

puis se connecter à ``localhost`` dans le jeu.

4. Modifier la configuration
----------------------------

Ne jamais modifier les fichiers à la main sur la VM : ils seraient écrasés au
prochain déploiement. Modifier le dépôt, puis :

.. code-block:: bash

   git checkout dev
   # modifier group_vars/all/main.yml ou un rôle
   ./deploy.sh -K
   git commit -am "description du changement" && git push

Exemple : passer la rétention des sauvegardes à 14 jours →
``backup_retention_days: 14``.

5. Restaurer après un incident
------------------------------

Voir :doc:`exploitation`, section *Restauration*.

6. Que faire si…
----------------

==================================  ==============================================
Symptôme                            Action
==================================  ==============================================
Grafana : cibles DOWN après un      ``./deploy.sh -K`` (redémarre les sidecars
redémarrage de la VM                dans le bon ordre)
Ansible attend puis échoue sur      vérifier ``ansible_become_exe: sudo.ws``
« privilege escalation prompt »     dans l'inventaire
Serveur Minecraft lent / plante     ``docker logs CT-serveur`` ; augmenter
                                    ``mc_memory`` si la RAM le permet
Disque plein                        ``sudo du -sh /var/backups/infra_mc`` ;
                                    réduire ``backup_retention_days``
==================================  ==============================================
