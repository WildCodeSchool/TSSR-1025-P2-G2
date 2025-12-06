# Documentation d’Installation – Service SSH

## 📋 Table des Matières

### A ) [Installation SSH sur Windows Server 2022](#-installation-ssh-sur-windows-server-2022)

### B ) [Installation SSH sur Debian 13.1](#-installation-sur-debian-13.1-serveur)  

### C ) [FAQ](#-faq)
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

# Installation SSH sur Windows Server 2022


### Etape 1

- Ouvrez le menu Démarrer et tapez : "Settings".

- Cliquez sur l'onglet "Apps".

![image URL](Ressources/01_installation_ssh_winserv2022.png)

---

### Etape 2 

- Dans "Apps & features", cliquez sur "Optional features".

- Cette section présente toutes les applications et fonctionnalités installées sur la machine, en tapant "OpenSSH", seul OpenSSH Client sera affiché.


![image URL](Ressources/02_installation_ssh_winserv2022.png)

---

### Etape 3

- Cliquez sur "Add a feature".

- Cette section permet d'installer les applications et fonctionnalité qu'il nous faut.

![image URL](Ressources/03_installation_ssh_winserv2022.png)

---

### Etape 4

- Tapez "OpenSSH".

- Sélectionnez "OpenSSH Server", puis cliquez sur "Install".

![image URL](Ressources/04_installation_ssh_winserv2022.png)

---

### Etape 5 

- Patientez pendant que l’installation de "OpenSSH Server" se termine.

- Tapez "OpenSSH" pour vérifier si le service "OpenSSH Server" est présent sur votre machine.

![image URL](Ressources/05_installation_ssh_winserv2022.png)

---

# Installation SSH sur Debian 13.1


### Etape 1

Après avoir mis à jour les paquets de votre serveur, tapez "sudo apt install openssh-server"

![image URL](https://github.com/WildCodeSchool/TSSR-1025-P2-G2/blob/ca4256e367d710832eace9004d63a31f851724eb/Ressources/install.md%20(ssh%20debian)/01_installation_ssh_debianserv.png)

---

### Etape 2 

- Vérifiez l’état du service SSH en tapant "systemctl status ssh".

- "systemctl status ssh" est une commande qui affiche l’état du service SSH (Secure Shell) sur une machine Linux. Elle permet de déterminer si le service est :

- Installé,

- En cours d’exécution (active),

- Arrêté (inactive),

- Si il y a eu des erreurs au démarrage.
  

![image URL](https://github.com/WildCodeSchool/TSSR-1025-P2-G2/blob/ca4256e367d710832eace9004d63a31f851724eb/Ressources/install.md%20(ssh%20debian)/02_installation_ssh_debianserv.png
)


---

### Etape 3 

- Après avoir vérifié l’état de votre service SSH, tapez les commandes suivantes :

- "sudo systemctl start ssh" pour démarrer le service. 

- "sudo systemctl enable ssh" pour l’activer au démarrage.

- Revérifiez l'était de votre service SSH, vous devriez avoir "Active : active (running)", "*ssh.service: enabled, "preset: enabled)".

![image URL](https://github.com/WildCodeSchool/TSSR-1025-P2-G2/blob/ca4256e367d710832eace9004d63a31f851724eb/Ressources/install.md%20(ssh%20debian)/03_installation_ssh_debianserv.png)


---


## C) 👁️‍🗨️ FAQ

Dans notre architecture, la différence entre serveur et client est simple : le serveur est la machine centrale qui exécute le script principal, lance les actions, d’administration ou de contrôle, et se connecte aux postes distants ; le client, lui, est simplement la machine à contrôler. Pour qu’un poste client puisse être géré, il n’a aucune installation complexe à effectuer : il doit seulement disposer de OpenSSH Client (déjà présent par défaut sur la plupart des systèmes ou installable en une commande). Grâce à ça, le serveur peut établir une connexion sécurisée via SSH. Le poste client doit également disposer du pare-feu configuré pour autoriser les connexions entrantes, avec le port SSH ouvert et le service OpenSSH client actif, afin que le serveur puisse établir la connexion.

---





