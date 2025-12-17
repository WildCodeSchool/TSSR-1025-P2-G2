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

---

---

# 👨‍💻 Préparer une machine Windows pour l’administration distante

Ces étapes permettent de configurer une machine Windows pour être administrée à distance de manière sécurisée et fiable. Elles assurent que l’utilisateur dispose des droits nécessaires, que le réseau est correctement reconnu et que les communications avec d’autres machines sont autorisées.

# ⚙️ 1. ​Configuration Windows pour l’administration distante :

Il faut exécuter PowerShell (Windows PowerShell 5.1) en tant qu’administrateur, sinon certaines commandes échoueront. (UAC, registre, pare-feu, WinRM)


| Etape     | Description       | Action |
| ---------- | ---------- | -------- |
| 1.1       | Activer le contrôle des comptes utilisateurs (UAC) pour gérer les droits d’administration.         | Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 1 -Type DWord |
| 1.2      | Autoriser les comptes administrateurs locaux à se connecter à distance.         | Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "LocalAccountTokenFilterPolicy" -Value 1 -Type DWord |
| 1.3     | Définir le réseau comme privé pour faciliter les communications. | Set-NetConnectionProfile -InterfaceAlias "Ethernet" -NetworkCategory Private |
| 1.4       | Ajouter les règles nécessaires au pare-feu pour autoriser les connexions distantes via WinRM.         | netsh advfirewall firewall add rule name="WinRM-HTTP" dir=in localport=5985 protocol=TCP action=allow |
| 1.5       | Activer le service Windows Remote Management (WinRM) pour l’exécution de commandes à distance.         | Enable-PSRemoting -Force -SkipNetworkProfileCheck |
| 1.6       | Définir les machines autorisées à se connecter, le caractère * autorise tous les hôtes, mais pour plus de sécurité spécifier l’adresse IP ou le nom de la machine qui va administrer la cible. | Set-Item WSMan:\localhost\Client\TrustedHosts -Value "*" -Force |
| 1.7       | Redémarrer la machine pour que toutes les modifications soient prises en compte.         | Restart-Computer |




