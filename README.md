![image URL](Ressources/README-PROJET2.png)

---

## Sommaire 

- [🎯 Présentation du projet](#presentation-du-projet)
- [📜 Introduction](#introduction)
- [👥 Membres du groupe par sprint](#membres-du-groupe-par-sprint)
- [⚙️ Choix Techniques](#choix-techniques)
- [🧗Difficultés rencontrées](#difficultes-rencontrees)
- [💡 Solutions trouvées](#solutions-trouvees)
- [🚀 Améliorations possibles](#ameliorations-possibles)



# 🖥️ ADMINISTRATION DE CLIENTS A DISTANCE

# 🎯 Présentation du projet
<span id="presentation-du-projet"></span>



## Présentation

Ce projet vise à développer une solution d'administration réseau centralisée et automatisée. Le script doit réaliser une cartographie dynamique du réseau local. L'objectif est de fournir un outil unique permettant aux utilisateurs de se connecter de manière fluide et sécurisée à toutes les machines détectées pour y exécuter des tâches à distance. Dans un environnement professionnel, la gestion d'un parc informatique hétérogène (Windows et Linux) représente un défi majeur pour les administrateurs système. La multiplicité des outils, des protocoles de connexion et des interfaces d'administration engendre une perte de temps significative et augmente le risque d'erreurs humaines.


## Détail de la tâche principale : Scan Réseau et Interopérabilité

La tâche principale du projet est de scanner l’ensemble du sous-réseau 172.16.20.0/24 afin de repérer les hôtes actifs. Une fois une machine identifiée, le script doit déterminer comment communiquer avec elle selon son système :

Machines Windows : Connexion via SSH pour pour lancer des commandes d’administration à distance.

Machines Linux (Debian/Ubuntu) : Connexion via SSH pour lancer des commandes d’administration à distance.

Cette étape permet de rendre toutes les machines du réseau accessibles par un mécanisme unique.

## Détail de la tâche principale (suite) : Exécution de Tâches Administratives à Distance

La suite de la tâche consiste à fournir une série d’outils pour administrer les machines à distance une fois la connexion établie.
Ces actions peuvent inclure :

**Gestion de la sécurité** : Activation pare-feu, Etat des ports, RAM totale/utilisation-en-cours.

**Gestion des comptes** : désactivation d'un compte utilisateur local, vérification d'appartenance groupe, ajout à un groupe /admin, droits/permissions d'utilisateur sur un dossier.

**Gestion du réseau** : Vérifier l’adresse IP-masque-passerelle, lister les interfaces réseau, vérifier les ports ouverts, tester la prise en main à distance (CLI), exécution d’un script à distance via WinRM / SSH

**Gestion du stockage** : Création de répertoire, Suppression de répertoire, /log événement utilisateur, Recherche d'événements pour un ordinateur dans log_evt.log

**Gestion des applications et services** : Liste des applications/paquets installés, liste des services en cours d'exécution.

**Gestion du système et configuration OS** : Redémarrage du système, Vérification de la version de l’OS, Vérification de la marque et du modèle de la machine, Vérification de l’UAC (Windows) activée, Recherche des mises à jour critiques manquantes.


# 📜 Introduction
<span id="introduction"></span>

### Problématique
Comment centraliser et simplifier l'administration de machines aux systèmes d'exploitation différents, tout en garantissant une gestion sécurisée et efficace des tâches courantes ?

### Notre Solution
Ce projet propose un script d'administration unifié capable de :

- Découvrir automatiquement les machines actives sur le réseau local
- Identifier le système d'exploitation de chaque hôte détecté
- Établir une connexion sécurisée via SSH (Linux/Windows)
- Éxécuter des tâches d'administration de manière standardisée, quel que soit l'OS cible

### Périmètre du Projet

| Élément      |	Description    |
| :----------: | :-------------: |
| Réseau cible |	172.16.20.0/24 |
| Systèmes supportés |	Windows 11, Windows Server 2022, Ubuntu 24 , Debian 13 |
| Protocole de connexion |	SSH |
| Type d'interface |	CLI (ligne de commande) |

## 👥 Membres du groupe par sprint
<span id="membres-du-groupe-par-sprint"></span>

### Sprint 1

|  Membre                 |    Rôle    | Missions                            |
| :---------------------: | :--------: | :---------------------------------: |
| Anis BOUTALEB           |     SM     | Création du tableau Trello, Mise en place structuration Script, Doc Github         |
| Frederick FLAVIL        |     PO     | Structuration du script, Mise en place d'une structuration Script, Doc Github      |
|  Eros-Nathan RIGUIDEL   | Technicien | Installation des pré-requis, Mise en place d'une structuration Script, Doc Github  |

### Sprint 2

|  Membre                 |    Rôle    | Missions                            |
| :---------------------: | :--------: | :---------------------------------: |
| Anis BOUTALEB           | Techicien  | Créations fonctions (Tâches) (.sh)  |
| Frederick FLAVIL        |     SM     | Pseudo-Code, Documentation Github   |
|  Eros-Nathan RIGUIDEL   |     PO     | Création Script (.sh)               |

### Sprint 3

|  Membre                 |    Rôle    | Missions                            |
| :---------------------: | :--------: | :---------------------------------: |
| Anis BOUTALEB           |     PO     | Créations fonctions (Tâches) (.ps1) |
| Frederick FLAVIL        | Technicien | Pseudo-Code, Documentation Github   |
|  Eros-Nathan RIGUIDEL   |     SM     | Documentation Github, Création Script (.ps1) |

### Sprint 4

|  Membre                 |    Rôle    | Missions                            |
| :---------------------: | :--------: | :---------------------------------: |
| Anis BOUTALEB           |     SM     | Création du tableau Trello,         |
| Frederick FLAVIL        |     PO     | Structuration du script             |
|  Eros-Nathan RIGUIDEL   | Technicien | Installation des pré-requis         |

## ⚙️ Choix techniques
<span id="choix-techniques"></span>

## Configuration Réseau des VM: 

- Plage IP du Réseau : 172.16.20.0/24
- Passerelle (GateWay) : 172.16.20.254
- Masque de Sous-réseau : 255.255.255.0
- DNS : 8.8.8.8

## Configuration PROXMOX : 

Nos machines sont les machines **220** à **227**.


## Configuration Réseau des VM: 

## **Matériels Serveurs**

**Serveur Debian :**
- Nom : **SRVLX01**
- OS : **Debian 13.1.0 CLI**
- Langue : US
- Compte utilisateur :  **Root** / **wilder (groupe sudo)**
- Mot de passe : **Azerty1***
- IP : **172.16.20.10**
- Masque : **255.255.255.0**
- DNS : 8.8.8.8

**Serveur Windows :**
  - Nom : **SRVWIN01**
  - OS : **Windows server 2022**
  - Compte utilisateur :  **Administrator** / **Wilder (groupe admin)**
  - Mot de passe : **Azerty1***
  - IP & Masque : **172.16.20.5**
  - Masque : **255.255.255.0**
  - DNS : 8.8.8.8


## **Matériels Clients**

**Client Ubuntu :**
- Nom : **CLINLIN01**
- OS : **Ubuntu 24.04 LTS**
- Compte utilisateur : **wilder (groupe sudo)**
- Langue : FR
- Mot de passe : **Azerty1***
- IP : **172.16.20.30**
- Masque : **255.255.255.0**
- DNS : 8.8.8.8


**Client Windows :**
- Nom : **CLINWIN01**
- OS : **Windows 11**
- Langue : FR
- Compte utilisateur : **Wilder (groupe admin local)**
- Mot de passe : **Azerty1***
- IP : **172.16.20.20**
- Masque : **255.255.255.0**
- DNS : 8.8.8.8



## 🧗 Difficultés rencontrées
<span id="difficultes-rencontrees"></span>

**Compatibilité des versions PowerShell**

Au cours du projet, des problèmes de compatibilité entre les différentes versions de PowerShell ont été identifiés. Certaines fonctionnalités et commandes ne se comportaient pas de la même manière entre Windows PowerShell 5.1 et PowerShell 7+, ce qui a nécessité des ajustements afin de garantir le bon fonctionnement des scripts sur l’ensemble des environnements.

**Mises à jour critiques manquantes**

La gestion des mises à jour critiques via une tâche données par le client a mis en évidence des manques sur certaines machines. Toutes les mises à jour n’étaient pas correctement détectées, ce qui a compliqué l’automatisation et a demandé des vérifications supplémentaires.

**Configuration SSH et gestion des clés (Windows)**

La mise en place du service SSH sur Windows a été longue en raison de la gestion des clés d’authentification, qui a nécessité de nombreuses étapes pour garantir des connexions sécurisées et fiables.
En outre, malgré la configuration du port SSH spécifique et l’ajustement des règles du pare-feu, Windows ne permettait pas de laisser le pare-feu actif tout en autorisant le nouveau port. Cette limitation a compliqué la sécurisation de l’accès à distance et a prolongé le temps nécessaire pour finaliser la configuration.

**Mise en place du scan réseau**

Au départ, nous ne savions pas quelle approche adopter pour mettre en place une détection automatique des équipements sur le réseau. La mise en place du scan réseau a ensuite posé des contraintes supplémentaires, notamment l’identification des plages d’adresses IP à analyser, la gestion des hôtes injoignables ainsi que les restrictions liées aux pare-feux sur chaques postes. Ces difficultés ont rendu le scan moins fiable dans un premier temps, nécessitant des ajustements pour obtenir des résultats exploitables.

**Problème de gestion des droits et de l’administration à distance sous Windows**

Lors des tests d’administration à distance sur les machines Windows, nous avons rencontré des difficultés liées à la gestion des droits et des mécanismes de sécurité du système. Malgré l’utilisation de comptes disposant de privilèges administrateur, certaines actions échouaient ou étaient exécutées avec des droits restreints lors des connexions à distance. Ce comportement était principalement lié à l’UAC et à la manière dont Windows gère les jetons de sécurité pour les accès distants. En parallèle, l’accès à distance aux machines n’était pas systématiquement possible en raison des restrictions réseau et pare-feu appliquées par défaut. Selon le profil réseau actif, certaines communications nécessaires à l’administration distante étaient bloquées, empêchant l’exécution correcte du scripts. Ces limitations ont rendu l’automatisation et la gestion centralisée plus complexes que prévu et ont nécessité une adaptation de la configuration des systèmes afin de garantir un accès distant fonctionnel et cohérent.


## 💡 Solutions trouvées
<span id="solutions-trouvees"></span>

**Compatibilité des versions PowerShell**

Afin de garantir un fonctionnement homogène des scripts sur l’ensemble des machines, une version commune et plus récente de PowerShell a été utilisée. L’adoption de PowerShell 7 a permis de supprimer les incompatibilités rencontrées entre les environnements et d’assurer une meilleure stabilité et portabilité des scripts.

**Configuration SSH et gestion des clés**

Malgré le temps nécessaire à sa mise en place, la configuration du service SSH a été finalisée avec succès. La gestion des clés d’authentification a permis de sécuriser les connexions à distance tout en rendant les accès plus fiables et adaptés à l’automatisation du script des actions sur les systèmes Windows et Linux. Le changement de port SSH a été appliqué sur Windows, permettant aux machines de se connecter correctement même sur un port non standard. Sur Linux, le port a également été modifié et les protections du pare-feu ont été maintenues, assurant ainsi un accès distant sécurisé et pleinement fonctionnel. Cette solution garantit que les connexions à distance sont fiables et sécurisées, tout en permettant l’automatisation des actions sur les deux systèmes, et ce, malgré les particularités et contraintes propres à chaque environnement.

**Mise en place du scan réseau**

Un scan réseau parallélisé a été mis en place afin d’automatiser la détection des équipements sur le réseau. La solution retenue consiste à permettre au script d’identifier automatiquement le réseau disponible sur lequel la machine est connectée. À partir de cette détection, les équipements accessibles sont identifiés et présentés à l’utilisateur, lui offrant un accès direct aux machines disponibles sans qu’il soit nécessaire de saisir manuellement une adresse IP ou un nom de machine. Cette approche simplifie l’utilisation et améliore l’efficacité globale de l’automatisation.

**Gestion des droits et administration à distance sous Windows**

Une configuration spécifique des mécanismes de sécurité Windows a été appliquée afin de garantir le bon fonctionnement de l’administration à distance. Cette solution permet d’assurer que les actions lancées à distance disposent des droits nécessaires, que les communications réseau requises soient autorisées et que les machines puissent être administrées de manière centralisée et cohérente, tout en respectant les principes de sécurité du système.


## 🚀 Améliorations possibles
<span id="ameliorations-possibles"></span>


