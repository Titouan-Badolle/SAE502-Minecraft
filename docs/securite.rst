Sécurité
========

=========================  ======================================================
Mesure                     Mise en œuvre
=========================  ======================================================
Pare-feu                   UFW, politique ``deny`` ; seuls 22, 80, 443, 25565.
Exposition Docker          Seul CT-proxy publie des ports (Docker contourne UFW).
SSH                        Clés uniquement, ``root`` interdit
                           (``/etc/ssh/sshd_config.d/01-infra_mc.conf``, validé
                           par ``sshd -t`` avant application).
Secrets                    ansible-vault (AES-256) : SQL root, SQL LuckPerms,
                           RCON, Grafana, supervision SQL. Mot de passe du coffre
                           hors dépôt.
Secrets dans les logs      ``no_log: true`` sur les commandes contenant un secret.
Secrets dans les scripts   Aucun : lus dans l'environnement des conteneurs.
HTTPS                      Certificat auto-signé (1 an), TLS 1.2/1.3, HTTP → HTTPS.
Grafana                    Inscription désactivée, mot de passe admin depuis Vault.
Base de données            Aucun port publié ; utilisateur de supervision en
                           lecture seule (``PROCESS, REPLICATION CLIENT, SELECT``)
                           limité à ``127.0.0.1``.
Sauvegardes                Dossier ``0700`` (root), scripts ``0750``.
=========================  ======================================================

Limites connues
---------------

* Certificat auto-signé : avertissement du navigateur (Let's Encrypt impossible
  sans nom de domaine public).
* Les sauvegardes sont sur la même VM : une copie externe serait nécessaire en
  production.
* Le port 25565 est filtré par le réseau de l'IUT/VPN ; accès de test par tunnel
  SSH (voir :doc:`tutoriel`).
