# Documentation d’Installation – Service SSH

## 📋 Table des Matières

- [A ) Installation SSH sur Windows Server 2022](#a--installation-ssh-sur-windows-server-2022)

- [B ) Installation SSH sur Debian 13.1 Serveur](#b--installation-ssh-sur-debian-131-serveur)

- [C ) FAQ](#c--faq)


---

## 🔩 Prérequis Techniques

- Un environnement réseau local opérationnel.

- Des postes Windows et/ou Linux intégrés au même réseau.

- Un compte disposant des droits administrateur sur les machines à gérer.

- L’accès au réseau nécessaire pour l’administration à distance (ports, services et pare-feu ouverts).

- Une connexion stable vers les machines cibles pour assurer la communication entre les composants.

---

### 👔 Contexte du Projet 

Dans le cadre de la mise en place d’une solution d’administration centralisée, la configuration de SSH sur quatre machines permet d’établir un accès distant sécurisé entre les différents systèmes. 
Deux de ces machines joueront un rôle de postes de contrôle (SRVWIN01) & (SRVLX01), tandis que les deux autres serviront de machines administrées (CLILIN01) & (CLIWIN01). 

Grâce à SSH, les postes de contrôle pourront exécuter des commandes à distance, transférer des fichiers de manière sécurisée, surveiller l’activité des machines administrées et automatiser certaines tâches d’administration. 
Cette configuration assure une gestion plus efficace, sécurisée et centralisée de l’infrastructure.

---

## A ) Installation SSH sur Windows Server 2022

### Etape 1 :

- Ouvrez le menu Démarrer et tapez : "Settings".

- Cliquez sur l'onglet "Apps".

![image URL](https://github.com/WildCodeSchool/TSSR-1025-P2-G2/blob/f11585318909be07023406460adf4c6e9564e5b5/Ressources/install.md%20(ssh%20windows)/01_installation_ssh_winserv2022.png)

---

### Etape 2 :

- Dans "Apps & features", cliquez sur "Optional features".

- Cette section présente toutes les applications et fonctionnalités installées sur la machine, en tapant "OpenSSH", seul OpenSSH Client sera affiché.


![image URL](https://github.com/WildCodeSchool/TSSR-1025-P2-G2/blob/f11585318909be07023406460adf4c6e9564e5b5/Ressources/install.md%20(ssh%20windows)/02_installation_ssh_winserv2022.png)

---

### Etape 3 :

- Cliquez sur "Add a feature".

- Cette section permet d'installer les applications et fonctionnalité qu'il nous faut.

![image URL](https://github.com/WildCodeSchool/TSSR-1025-P2-G2/blob/f11585318909be07023406460adf4c6e9564e5b5/Ressources/install.md%20(ssh%20windows)/03_installation_ssh_winserv2022.png)

---

### Etape 4 :

- Tapez "OpenSSH".

- Sélectionnez "OpenSSH Server", puis cliquez sur "Install".

![image URL](https://github.com/WildCodeSchool/TSSR-1025-P2-G2/blob/f11585318909be07023406460adf4c6e9564e5b5/Ressources/install.md%20(ssh%20windows)/04_installation_ssh_winserv2022.png)

---

### Etape 5 :

- Patientez pendant que l’installation de "OpenSSH Server" se termine.

- Tapez "OpenSSH" pour vérifier si le service "OpenSSH Server" est présent sur votre machine.

![image URL](https://github.com/WildCodeSchool/TSSR-1025-P2-G2/blob/f11585318909be07023406460adf4c6e9564e5b5/Ressources/install.md%20(ssh%20windows)/05_installation_ssh_winserv2022.png)

---

## B ) Installation SSH sur Debian 13.1 Serveur

### Etape 1 :

Après avoir mis à jour les paquets de votre serveur, tapez "sudo apt install openssh-server"

![image URL](https://github.com/WildCodeSchool/TSSR-1025-P2-G2/blob/f11585318909be07023406460adf4c6e9564e5b5/Ressources/install.md%20(ssh%20debian)/01_installation_ssh_debianserv.png)

---

### Etape 2 :

- Vérifiez l’état du service SSH en tapant "systemctl status ssh".

- "systemctl status ssh" est une commande qui affiche l’état du service SSH (Secure Shell) sur une machine Linux. Elle permet de déterminer si le service est : installé, en cours d’exécution (active), arrêté (inactive), si il y a eu des erreurs au démarrage.
  

![image URL](https://github.com/WildCodeSchool/TSSR-1025-P2-G2/blob/f11585318909be07023406460adf4c6e9564e5b5/Ressources/install.md%20(ssh%20debian)/02_installation_ssh_debianserv.png)


---

### Etape 3 :

- Après avoir vérifié l’état de votre service SSH, tapez les commandes suivantes :

- "sudo systemctl start ssh" pour démarrer le service. 

- "sudo systemctl enable ssh" pour l’activer au démarrage.

- Revérifiez l'était de votre service SSH, vous devriez avoir "Active : active (running)", "*ssh.service: enabled, "preset: enabled)".

![image URL](https://github.com/WildCodeSchool/TSSR-1025-P2-G2/blob/f11585318909be07023406460adf4c6e9564e5b5/Ressources/install.md%20(ssh%20debian)/03_installation_ssh_debianserv.png)


---


## C ) FAQ

#### Configuration des machines clientes :

**Quels sont les prérequis nécessaires avant que le serveur puisse contrôler une machine cliente ?** 

*Avant toute utilisation, chaque poste client doit avoir son pare-feu configuré pour autoriser les connexions SSH entrantes, le service OpenSSH activé, et le port SSH ouvert (par défaut 22). L’installation d’OpenSSH Client est généralement déjà présente par défaut sur Windows et Linux, mais doit être vérifiée. Le serveur doit également générer une paire de clés SSH, dont la clé publique devra être copiée sur les clients pour permettre l’authentification. Enfin, pour améliorer la sécurité, il est possible de modifier le port SSH sur les machines clientes. L’ensemble de ces étapes, ainsi que les procédures détaillées pour Windows et Linux, sont expliquées dans le UserGuide.md.* 

---














