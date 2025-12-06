# 🔐​ Configuration SSH (Serveur & Client) 

Ce guide explique comment configurer une connexion SSH sécurisée permettant aux serveurs de se connecter aux postes clients pour les administrer à distance. Il couvre les prérequis, 
la configuration SSH, la gestion des clés, le pare-feu, le port SSH et la sécurisation via un port personnalisé. L’objectif est d’installer un environnement simple où le serveur peut contrôler n’importe quel client Windows ou Linux.


# 👔​ Contexte

Dans cette architecture du projet :

Le serveur Windows (SRVWIN01) & serveur Debian (SRVLX01) contrôle les postes clients Ubuntu (CLILIN01) & Windows 11 (CLIWIN01) distants.

Les postes client sont les machine contrôlée.

La connexion SSH est initiée par le serveur vers le client.

Cela implique que tout ce qui permet de recevoir et autoriser la connexion se configure du côté client, tandis que le serveur se contente de posséder la clé privée et d’exécuter la commande SSH.

---
# ⚙️ 2. ​Configuration SSH Serveurs :

#### La connexion SSH utilise un système de paire de clés, le serveur doit posséder ces pré-requis :

- Clé privée

- Elle sert à prouver son identité.

- Elle doit rester secrète et ne jamais être copiée sur les clients.

Sur le serveur (Windows ou Linux), exécutez la commande suivante pour générer une paire de clés :


`ssh-keygen -t rsa -b 4096`

Deux fichiers sont créés :

| Fichier     | Description       | Action |
| ---------- | ---------- | -------- |
| 'id_rsa'       | Clé Privé         | À conserver uniquement sur le serveur (ne jamais partager) |
| 'id_rsa.pub'       | Clé Publique         | À déployer sur les machines clientes |

---
# ⚙️ 3. Configuration SSH Clients :

Client Linux
--
| Etape     | Description       | Action |
| ---------- | ---------- | -------- |
| 3.1       | Vérifier le service SSH        | sudo systemctl status ssh |
| 3.2       | Ouvrir le port SSH (pare-feu)         | sudo ufw allow 22/tcp |
| 3.3       | Copié la clé publique sur le client (depuis le serveur) | ssh-copy-id utilisateur@ip_client puis Coller le contenu de id_rsa.pub dans ~/.ssh/authorized_keys |


Client Windows
--
| Etape     | Description       | Action |
| ---------- | ---------- | -------- |
| 3.1       | Activer OpenSSH Server (GUI)        | Paramètres → Système → Fonctionnalités facultatives → Ajouter OpenSSH Server |
| 3.2       | Ouvrir le port SSH (pare-feu) (GUI)         | Pare-feu Windows → Règles de trafic entrant → Nouvelle règle → Port 22 TCP |
| 3.3       | Copié la clé publique sur le client (depuis le serveur) | Coller le contenu de "id_rsa.pub" dans → C: ~ \.ssh\authorized_keys |




