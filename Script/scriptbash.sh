#!/bin/bash
##################################################################
#                     SCRIPT_LINUX                               #
#                SCRIPT_BY ANIS FRED EROS                        #
#                   WILD_CODE_SCHOOL                             #
#                      24/11/2025                                #
##################################################################

#################################################################
#   DECLARATIONS VARIABLE & CONFIGURATION DE LA JOURNALISATION  #
#################################################################

log_dir="/tmp"
log_file="$log_dir/log_evt.log"
info_dir="/tmp/info"
nom_machine=$(hostname)
utilisateur_distant="${USER:-inconnu}"
utilisateur_local="${1:-$utilisateur_distant}"
connexion_date=$(date "+%Y%m%d_%H%M%S")
MOT_DE_PASSE_ADMIN=""

VERT='\e[32m'
GRIS='\e[90m'
BLEU='\e[34m'
BLANC='\e[97m'
ROUGE='\e[31m'
RESET='\e[0m'
####################################################################
#                     FONCTIONS DE JOURNALISATION                  #
####################################################################

#FONCTION POUR PREPARE LE FICHIER DE LOG ET LE DOSSIER INFO
initialiser_journal() {
    touch "$log_file" 2>/dev/null
    if [ ! -d "$info_dir" ]; then
        mkdir -p "$info_dir" 2>/dev/null
    fi
}

#FONCTION POUR ENREGISTRE UN EVENEMENT DANS LE FICHIER DE LOG
sauvegarder_log() {
    local evenement="$1"
    local date_evt
    local heure_evt
    date_evt=$(date "+%Y%m%d")
    heure_evt=$(date "+%H%M%S")
    echo "${date_evt}_${heure_evt}_${utilisateur_local}_${utilisateur_distant}_${nom_machine}_${evenement}" >> "$log_file" 2>/dev/null
}

#FONCTION QUI ENREGISTRE DES INFORMATIONS DANS UN FICHIER
sauvegarder_info() {
    local contenu="$1"
    local fichier_info
    fichier_info="$info_dir/info_${nom_machine}_${utilisateur_distant}_${connexion_date}.txt"
    if [ ! -d "$info_dir" ]; then
        mkdir -p "$info_dir" 2>/dev/null
    fi
    echo "$contenu" >> "$fichier_info" 2>/dev/null
}
####################################################################
#                  MOT DE PASSE ADMINISTRATEUR                     #
####################################################################

#FONCTION QUI DEMANDE LE MOT DE PASSE ADMIN POUR LES ACTIONS SENSIBLES
verifier_mot_de_passe_admin() {
    local action="$1"
    echo ""
    echo "=== ACTION SENSIBLE : $action ==="
    echo ""
    read -s -p "MOT DE PASSE ADMINISTRATEUR: " mdp
    echo ""
    echo "$mdp" | su -c "true" "$USER" 2>/dev/null
    if [ $? -eq 0 ]; then
        MOT_DE_PASSE_ADMIN="$mdp"
        return 0
    else
        echo ""
        echo -e "${ROUGE}MOT DE PASSE INCORRECT${RESET}"
        echo ""
        read -p "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        return 1
    fi
}
####################################################################
#                          FONCTION ENTETE                         #
####################################################################

#FONCTION QUI AFFICHE LENTETE AVEC NOM MACHINE + IP
afficher_entete() {
    clear
    NomMachine=$(hostname)
    AdresseIP=$(hostname -I | tr ' ' '\n' | grep "^172.16.20" | head -n1)
    if [ -z "$AdresseIP" ]; then
        AdresseIP=$(hostname -I | cut -d' ' -f1)
    fi
    echo -e "${BLEU}####################${BLANC}##############${ROUGE}####################${RESET}"
    echo -e "${BLEU}#${RESET}                      ${BLANC}$NomMachine${RESET}                      ${ROUGE}#${RESET}"
    echo -e "${BLEU}#${RESET}                    ${BLANC}$AdresseIP${RESET}                    ${ROUGE}#${RESET}"
    echo -e "${BLEU}####################${BLANC}##############${ROUGE}####################${RESET}"
    echo ""
}

####################################################################
#                 FONCTION AFFICHER UTILISATEURS                   #
####################################################################

#FONCTION POUR AFFICHE LA LISTE DES UTILISATEURS LOCAUX
afficher_utilisateurs_locaux() {
    echo "  UTILISATEURS LOCAUX"
    echo ""
    cat /etc/passwd | grep "/home"
    echo ""
}

####################################################################
#                        FONCTIONS REPERTOIRES                     #
####################################################################

#FONCTION POUR CREE UN NOUVEAU REPERTOIRE
creer_repertoire() {
    afficher_entete
    echo "  CREATION DE REPERTOIRE"
    echo ""
    read -p "CHEMIN COMPLET DU REPERTOIRE A CREER (Q POUR QUITTER): " Chemin
    if [ "$Chemin" = "q" ] || [ "$Chemin" = "Q" ]; then
        sauvegarder_log "Navigation_Retour"
        menu_repertoires
        return
    fi
    if [ -z "$Chemin" ]; then
        echo -e "${ROUGE}CHEMIN NON SPECIFIE${RESET}"
        read -p "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        creer_repertoire
        return
    fi
    if [ -d "$Chemin" ]; then
        echo -e "${GRIS}LE REPERTOIRE EXISTE DEJA${RESET}"
        read -p "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        creer_repertoire
        return
    fi
    read -p "CONFIRMER LA CREATION DE *$Chemin* ? [O/N]: " Confirm
    if [ "$Confirm" != "O" ] && [ "$Confirm" != "o" ]; then
        echo -e "${GRIS}CREATION ANNULEE${RESET}"
        read -p "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        menu_repertoires
        return
    fi
    mkdir -p "$Chemin" 2>/dev/null
    if [ -d "$Chemin" ]; then
        echo -e "${VERT}REPERTOIRE CREE AVEC SUCCES${RESET}"
        sauvegarder_log "Action_CreationRepertoire_$Chemin"
    else
        echo -e "${ROUGE}IMPOSSIBLE DE CREER LE REPERTOIRE${RESET}"
    fi
    echo ""
    read -p "VOULEZ-VOUS CREER UN AUTRE REPERTOIRE ? [O/N]: " Continuer
    if [ "$Continuer" = "O" ] || [ "$Continuer" = "o" ]; then
        creer_repertoire
    else
        menu_repertoires
    fi
}

#FONCTION POUR SUPPRIMER UN REPERTOIRE
supprimer_repertoire() {
    afficher_entete
    echo "  SUPPRESSION DE REPERTOIRE"
    echo ""
    read -p "CHEMIN COMPLET DU REPERTOIRE A SUPPRIMER (Q POUR QUITTER): " Chemin
    if [ "$Chemin" = "q" ] || [ "$Chemin" = "Q" ]; then
        sauvegarder_log "Navigation_Retour"
        menu_repertoires
        return
    fi
    if [ -z "$Chemin" ]; then
        echo -e "${ROUGE}CHEMIN NON SPECIFIE${RESET}"
        read -p "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        supprimer_repertoire
        return
    fi
    if [ ! -d "$Chemin" ]; then
        echo -e "${ROUGE}LE REPERTOIRE N'EXISTE PAS${RESET}"
        read -p "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        supprimer_repertoire
        return
    fi
    if ! verifier_mot_de_passe_admin "SUPPRIMER REPERTOIRE *$Chemin*"; then
        supprimer_repertoire
        return
    fi
    read -p "CONFIRMER LA SUPPRESSION DE *$Chemin* ? [O/N]: " Confirm
    if [ "$Confirm" != "O" ] && [ "$Confirm" != "o" ]; then
        echo -e "${GRIS}SUPPRESSION ANNULEE${RESET}"
        read -p "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        menu_repertoires
        return
    fi
    echo "$MOT_DE_PASSE_ADMIN" | sudo -S rm -rf "$Chemin" 2>/dev/null
    if [ ! -d "$Chemin" ]; then
        echo -e "${VERT}REPERTOIRE SUPPRIME AVEC SUCCES${RESET}"
        sauvegarder_log "Action_SuppressionRepertoire_$Chemin"
    else
        echo -e "${ROUGE}IMPOSSIBLE DE SUPPRIMER LE REPERTOIRE${RESET}"
    fi
    echo ""
    read -p "VOULEZ-VOUS SUPPRIMER UN AUTRE REPERTOIRE ? [O/N]: " Continuer
    if [ "$Continuer" = "O" ] || [ "$Continuer" = "o" ]; then
        supprimer_repertoire
    else
        menu_repertoires
    fi
}

####################################################################
#                        FONCTIONS LOGICIELS                       #
####################################################################

#FONCTION QUI AFFICHE LES MISES A JOUR CRITIQUES
afficher_mises_a_jour_manquantes() {
    afficher_entete
    echo "  MISES A JOUR CRITIQUES"
    echo ""
    sauvegarder_log "Consultation_MisesAJourCritiques"
    liste_maj=$(apt-get -s upgrade 2>/dev/null | grep "^Inst" | grep -i "security" | awk '{print $2}')
    if [ -z "$liste_maj" ]; then
        liste_maj=$(apt list --upgradable 2>/dev/null | grep -E "security|Security" | cut -d'/' -f1)
    fi
    if [ -z "$liste_maj" ]; then
        liste_maj=$(apt list --upgradable 2>/dev/null | grep -v "En train de lister" | grep -v "Listing" | cut -d'/' -f1)
    fi
    if [ -z "$liste_maj" ]; then
        nb_maj=0
    else
        nb_maj=$(echo "$liste_maj" | grep -v "^$" | wc -l)
    fi
    if [ "$nb_maj" -eq 0 ]; then
        echo -e "${VERT}AUCUNE MISE A JOUR CRITIQUE DISPONIBLE${RESET}"
        sauvegarder_info "=== MISES A JOUR CRITIQUES === $(date '+%Y-%m-%d %H:%M:%S') AUCUNE MISE A JOUR CRITIQUE"
    else
        sauvegarder_info "=== MISES A JOUR CRITIQUES === $(date '+%Y-%m-%d %H:%M:%S') $liste_maj"
        if [ "$nb_maj" -le 10 ]; then
            echo "$nb_maj MISE(S) A JOUR CRITIQUE(S) DISPONIBLE(S):"
            echo ""
            echo "$liste_maj"
            echo ""
            echo -e "${GRIS}$nb_maj MISES A JOUR ENREGISTREES${RESET}"
        else
            echo -e "${GRIS}LISTE DES MISES A JOUR ENREGISTREE ($nb_maj MISES A JOUR CRITIQUES)${RESET}"
        fi
    fi
    echo ""
    read -p "APPUYEZ SUR [ENTREE] POUR CONTINUER"
    menu_logiciels
}

#FONCTION QUI AFFICHE LES APPLICATIONS INSTALLEES
afficher_applications_installees(){
    afficher_entete
    echo "  APPLICATIONS INSTALLEES"
    echo ""
    sauvegarder_log "Consultation_ApplicationsInstallees"
    liste_apps=$(dpkg -l | grep "^ii" | awk '{print $2}' 2>/dev/null)
    nb_apps=$(echo "$liste_apps" | wc -l)
    sauvegarder_info "=== APPLICATIONS INSTALLEES === $(date '+%Y-%m-%d %H:%M:%S')
    $liste_apps"
    if [ "$nb_apps" -le 10 ]; then
        echo "$liste_apps"
        echo ""
        echo -e "${GRIS}($nb_apps APPLICATIONS ENREGISTREES)${RESET}"
    else
        echo -e "${GRIS}LISTE DES APPLICATIONS ENREGISTREE ($nb_apps APPLICATIONS)${RESET}"
    fi
    echo ""
    read -p "APPUYEZ SUR [ENTREE] POUR CONTINUER"
    menu_logiciels
}

####################################################################
#                   FONCTIONS SERVICES                             #
####################################################################

#FONCTION QUI AFFICHE LES SERVICES EN COURS
afficher_services_en_cours() {
    afficher_entete
    echo "  SERVICES EN COURS D'EXECUTION"
    echo ""
    sauvegarder_log "Consultation_ServicesEnCours"
    liste_services=$(systemctl list-units --type=service --state=running --no-pager 2>/dev/null | grep ".service")
    nb_lignes=$(echo "$liste_services" | wc -l)
    sauvegarder_info "=== SERVICES EN COURS === $(date '+%Y-%m-%d %H:%M:%S')$liste_services"
    if [ "$nb_lignes" -le 10 ]; then
        echo "$liste_services"
    else
        echo -e "${GRIS}LISTE DES SERVICES ENREGISTREE ($nb_lignes SERVICES)${RESET}"
    fi
    echo ""
    read -p "APPUYEZ SUR [ENTREE] POUR CONTINUER"
    menu_services
}

####################################################################
#                        FONCTIONS RESEAU                          #
####################################################################

#FONCTION POUR AFFICHER LES PORTS OUVERTS
afficher_ports_ouverts() {
    afficher_entete
    echo "  PORTS OUVERTS"
    echo ""
    sauvegarder_log "Consultation_PortsOuverts"
    liste_ports=$(ss -tulnp 2>/dev/null | grep LISTEN)
    nb_lignes=$(echo "$liste_ports" | wc -l)
    sauvegarder_info "=== PORTS OUVERTS === $(date '+%Y-%m-%d %H:%M:%S') $liste_ports"
    if [ "$nb_lignes" -le 10 ]; then
        echo "$liste_ports"
    else
        echo -e "${GRIS}LISTE DES PORTS ENREGISTREE ($nb_lignes PORTS)${RESET}"
    fi
    echo ""
    read -p "APPUYEZ SUR [ENTREE] POUR CONTINUER"
    menu_reseau
}

#FONCTION POUR AFFICHE LA CONFIGURATION IP
afficher_config_ip() {
    afficher_entete
    echo "  CONFIGURATION IP"
    echo ""
    sauvegarder_log "Consultation_ConfigurationIP"
    config_ip=""
    for iface in $(ls /sys/class/net/); do
        IP=$(ip -4 addr show $iface 2>/dev/null | grep "inet " | tr -s ' ' | cut -d' ' -f3)
        if [ -n "$IP" ]; then
            config_ip+="INTERFACE: $iface - IP: $IP\n"
        fi
    done
    Passerelle=$(ip route | grep default | tr -s ' ' | cut -d' ' -f3)
    config_ip+="\nPASSERELLE: $Passerelle"
    nb_lignes=$(echo "$config_ip" | wc -l)
    sauvegarder_info "=== CONFIGURATION IP === $(date '+%Y-%m-%d %H:%M:%S') $config_ip"
    if [ "$nb_lignes" -le 10 ]; then
        echo -e "$config_ip"
    else
        echo -e "${GRIS}CONFIGURATION IP ENREGISTREE${RESET}"
    fi
    echo ""
    read -p "APPUYEZ SUR [ENTREE] POUR CONTINUER"
    menu_reseau
}

#FONCTION POUR ACTIVER LE PARE-FEU
activer_pare_feu() {
    afficher_entete
    sauvegarder_log "Navigation_MenuPareFeu"
    echo "  GESTION DU PARE-FEU"
    echo ""
    echo "STATUT DU PARE-FEU :"
    if systemctl is-active --quiet ufw 2>/dev/null; then
        echo -e "${VERT}ACTIF${RESET}"
    else
        echo -e "${ROUGE}INACTIF${RESET}"
    fi
    echo ""
    echo "1. ACTIVER LE PARE-FEU"
    echo "Q. QUITTER"
    echo ""
    read -p "TAPEZ [1 OU Q]: " choix
    case "$choix" in
        1)
            if ! verifier_mot_de_passe_admin "ACTIVER LE PARE-FEU"; then
                activer_pare_feu
                return
            fi
            echo ""
            echo "$MOT_DE_PASSE_ADMIN" | sudo -S ufw --force enable 2>/dev/null
            if [ $? -eq 0 ]; then
                echo -e "${VERT}PARE-FEU ACTIVE${RESET}"
                sauvegarder_log "Action_ActivationPareFeu"
            else
                echo -e "${ROUGE}IMPOSSIBLE D'ACTIVER LE PARE-FEU${RESET}"
            fi
            echo ""
            read -p "APPUYEZ SUR [ENTREE] POUR CONTINUER"
            activer_pare_feu
            ;;
        Q|q)
            menu_reseau
            ;;
        *)
            echo -e "${ROUGE}CHOIX INVALIDE${RESET}"
            sleep 1
            activer_pare_feu
            ;;
    esac
}

####################################################################
#                        FONCTIONS SYSTEME                         #
####################################################################

#FONCTION QUI AFFICHE LES INFORMATIONS SYSTEME
afficher_info_systeme() {
    afficher_entete
    echo "  INFORMATIONS SYSTEME"
    echo ""
    sauvegarder_log "Consultation_InfoSysteme"
    OsName=$(lsb_release -d 2>/dev/null | cut -f2)
    OsVersion=$(lsb_release -r 2>/dev/null | cut -f2)
    OsArch=$(uname -m)
    Kernel=$(uname -r)
    Fabricant="NON DISPONIBLE"
    Modele="NON DISPONIBLE"
    NumeroSerie="NON DISPONIBLE"
    if [ -f /sys/class/dmi/id/sys_vendor ]; then
        Fabricant=$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null)
    fi
    if [ -f /sys/class/dmi/id/product_name ]; then
        Modele=$(cat /sys/class/dmi/id/product_name 2>/dev/null)
    fi
    if [ -f /sys/class/dmi/id/product_serial ]; then
        NumeroSerie=$(cat /sys/class/dmi/id/product_serial 2>/dev/null)
    fi
    info_systeme="NOM: $OsName
                VERSION: $OsVersion
                ARCHITECTURE: $OsArch
                KERNEL: $Kernel
                FABRICANT: $Fabricant
                MODELE: $Modele
                NUMERO SERIE: $NumeroSerie"
    sauvegarder_info "=== INFORMATIONS SYSTEME === $(date '+%Y-%m-%d %H:%M:%S') $info_systeme"
    echo "NOM: $OsName"
    echo "VERSION: $OsVersion"
    echo "ARCHITECTURE: $OsArch"
    echo "KERNEL: $Kernel"
    if [ "$Fabricant" = "NON DISPONIBLE" ]; then
        echo -e "FABRICANT: ${GRIS}$Fabricant${RESET}"
    else
        echo "FABRICANT: $Fabricant"
    fi
    if [ "$Modele" = "NON DISPONIBLE" ]; then
        echo -e "MODELE: ${GRIS}$Modele${RESET}"
    else
        echo "MODELE: $Modele"
    fi
    if [ "$NumeroSerie" = "NON DISPONIBLE" ]; then
        echo -e "NUMERO SERIE: ${GRIS}$NumeroSerie${RESET}"
    else
        echo "NUMERO SERIE: $NumeroSerie"
    fi
    echo ""
    read -p "APPUYEZ SUR [ENTREE] POUR CONTINUER"
    menu_systeme
}

#FONCTION QUI AFFICHE L'UTILISATION DE LA RAM
afficher_utilisation_ram() {
    afficher_entete
    echo "  UTILISATION DE LA MEMOIRE RAM"
    echo ""
    sauvegarder_log "Consultation_UtilisationRAM"
    ram_info=$(free -h)
    nb_lignes=$(echo "$ram_info" | wc -l)
    sauvegarder_info "=== UTILISATION RAM === $(date '+%Y-%m-%d %H:%M:%S') $ram_info"
    if [ "$nb_lignes" -le 10 ]; then
        echo "$ram_info"
    else
        echo -e "${GRIS}UTILISATION RAM ENREGISTREE${RESET}"
    fi
    echo ""
    read -p "APPUYEZ SUR [ENTREE] POUR CONTINUER"
    menu_systeme
}

####################################################################
#                         FONCTIONS CONTROLES                      #
####################################################################

#FONCTION POUR REDEMARRE LA MACHINE
redemarrer_machine() {
    afficher_entete
    echo "  REDEMARRAGE DE LA MACHINE"
    echo ""
    read -p "REDEMARRER LA MACHINE ? [O/N]: " Confirm1
    if [ "$Confirm1" != "O" ] && [ "$Confirm1" != "o" ]; then
        echo -e "${GRIS}REDEMARRAGE ANNULE${RESET}"
        read -p "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        menu_controles
        return
    fi
    read -p "CONFIRMER LE REDEMARRAGE ? [O/N]: " Confirm2
    if [ "$Confirm2" != "O" ] && [ "$Confirm2" != "o" ]; then
        echo -e "${GRIS}REDEMARRAGE ANNULE${RESET}"
        read -p "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        menu_controles
        return
    fi
    echo ""
    echo -e "${GRIS}REDEMARRAGE EN COURS...${RESET}"
    sauvegarder_log "Action_RedemarrageMachine"
    sleep 2
    sudo reboot
}

#FONCTION POUR EXECUTER UN SCRIPT
executer_script_distant() {
    afficher_entete
    echo "  EXECUTION D'UN SCRIPT"
    echo ""
    read -p "CHEMIN COMPLET DU SCRIPT A EXECUTER (Q POUR QUITTER): " CheminScript
    if [ "$CheminScript" = "q" ] || [ "$CheminScript" = "Q" ]; then
        sauvegarder_log "Navigation_Retour"
        menu_controles
        return
    fi
    if [ -z "$CheminScript" ]; then
        echo -e "${ROUGE}CHEMIN NON SPECIFIE${RESET}"
        read -p "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        executer_script_distant
        return
    fi
    if [ ! -f "$CheminScript" ]; then
        echo -e "${ROUGE}LE FICHIER N'EXISTE PAS${RESET}"
        read -p "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        executer_script_distant
        return
    fi
    if ! verifier_mot_de_passe_admin "EXECUTER SCRIPT *$CheminScript*"; then
        executer_script_distant
        return
    fi
    read -p "EXECUTER LE SCRIPT *$CheminScript* ? [O/N]: " Confirm
    if [ "$Confirm" != "O" ] && [ "$Confirm" != "o" ]; then
        echo -e "${GRIS}EXECUTION ANNULEE${RESET}"
        read -p "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        menu_controles
        return
    fi
    echo ""
    echo -e "${GRIS}EXECUTION DU SCRIPT EN COURS...${RESET}"
    echo ""
    sauvegarder_log "Action_ExecutionScript_$CheminScript"
    echo "$MOT_DE_PASSE_ADMIN" | sudo -S bash "$CheminScript" 2>/dev/null
    echo ""
    echo -e "${VERT}SCRIPT EXECUTE${RESET}"
    echo ""
    read -p "VOULEZ-VOUS EXECUTER UN AUTRE SCRIPT ? [O/N]: " Continuer
    if [ "$Continuer" = "O" ] || [ "$Continuer" = "o" ]; then
        executer_script_distant
    else
        menu_controles
    fi
}

#FONCTION POUR PRISE EN MAIN A DISTANCE
ouvrir_console_distante() {
    afficher_entete
    echo "  PRISE DE MAIN A DISTANCE (CLI)"
    echo ""
    echo -e "${GRIS}TAPEZ *EXIT* POUR REVENIR AU MENU${RESET}"
    echo ""
    sauvegarder_log "Action_OuvertureConsole"
    bash
    sauvegarder_log "Action_FermetureConsole"
    menu_controles
}

####################################################################
#                         FONCTIONS UTILISATEURS                   #
####################################################################

#FONCTION QUI AFFICHE LES PERMISSIONS DUN FICHIER OU DOSSIER
afficher_permissions_utilisateur() {
    afficher_entete
    echo "  DROITS ET PERMISSIONS SUR FICHIER"
    echo ""
    read -p "CHEMIN DU FICHIER OU DOSSIER (Q POUR QUITTER): " Chemin
    if [ "$Chemin" = "q" ] || [ "$Chemin" = "Q" ]; then
        sauvegarder_log "Navigation_Retour"
        menu_utilisateurs
        return
    fi
    if [ -z "$Chemin" ]; then
        echo -e "${ROUGE}CHEMIN NON SPECIFIE${RESET}"
        read -p "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        afficher_permissions_utilisateur
        return
    fi
    if [ ! -e "$Chemin" ]; then
        echo -e "${ROUGE}LE CHEMIN *$Chemin* N'EXISTE PAS${RESET}"
        read -p "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        afficher_permissions_utilisateur
        return
    fi
    sauvegarder_log "Consultation_Permissions_$Chemin"
    echo ""
    echo "PERMISSIONS:"
    if [ -d "$Chemin" ]; then
        permissions=$(ls -lA "$Chemin")
    else
        permissions=$(ls -lA "$Chemin")
    fi
    sauvegarder_info "=== PERMISSIONS === $(date '+%Y-%m-%d %H:%M:%S')CHEMIN: $Chemin $permissions"
    echo "$permissions"
    echo ""
    read -p "VOULEZ-VOUS CONSULTER UN AUTRE CHEMIN ? [O/N]: " Continuer
    if [ "$Continuer" = "O" ] || [ "$Continuer" = "o" ]; then
        afficher_permissions_utilisateur
    else
        menu_utilisateurs
    fi
}

#FONCTION POUR AJOUTER UN UTILISATEUR A UN GROUPE
ajouter_utilisateur_groupe() {
    afficher_entete
    echo "  AJOUT A UN GROUPE"
    echo ""
    afficher_utilisateurs_locaux
    read -p "NOM D'UTILISATEUR (Q POUR QUITTER): " NomUtilisateur
    if [ "$NomUtilisateur" = "q" ] || [ "$NomUtilisateur" = "Q" ]; then
        sauvegarder_log "Navigation_Retour"
        menu_utilisateurs
        return
    fi
    if [ -z "$NomUtilisateur" ]; then
        echo -e "${ROUGE}NOM D'UTILISATEUR NON SPECIFIE${RESET}"
        read -p "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        ajouter_utilisateur_groupe
        return
    fi
    if ! cat /etc/passwd | grep "^$NomUtilisateur:" > /dev/null; then
        echo -e "${ROUGE}L'UTILISATEUR \"$NomUtilisateur\" N'EXISTE PAS${RESET}"
        read -p "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        ajouter_utilisateur_groupe
        return
    fi
    echo ""
    groupes_classiques=$(cat /etc/group | grep -E "^(sudo|users|adm|cdrom|plugdev|netdev|audio|video|staff|games|docker|www-data):" | cut -d: -f1)
    groupes_utilisateurs=$(awk -F: '$3 >= 1000 {print $1}' /etc/group)
    groupes_dispo=$(echo -e "$groupes_classiques\n$groupes_utilisateurs" | sort -u | tr '\n' '|' | sed 's/|$//; s/|/ | /g')
    echo "GROUPES DISPONIBLES: $groupes_dispo"
    echo ""
    read -p "NOM DU GROUPE (Q POUR QUITTER): " NomGroupe
    if [ "$NomGroupe" = "q" ] || [ "$NomGroupe" = "Q" ]; then
        sauvegarder_log "Navigation_Retour"
        menu_utilisateurs
        return
    fi
    if [ -z "$NomGroupe" ]; then
        echo -e "${ROUGE}NOM DU GROUPE NON SPECIFIE${RESET}"
        read -p "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        ajouter_utilisateur_groupe
        return
    fi
    if ! cat /etc/group | grep "^$NomGroupe:" > /dev/null; then
        echo -e "${ROUGE}LE GROUPE *$NomGroupe* N'EXISTE PAS${RESET}"
        read -p "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        ajouter_utilisateur_groupe
        return
    fi
    read -p "AJOUTER \"$NomUtilisateur\" AU GROUPE *$NomGroupe* ? [O/N]: " Confirm
    if [ "$Confirm" != "O" ] && [ "$Confirm" != "o" ]; then
        echo -e "${GRIS}AJOUT ANNULE${RESET}"
        read -p "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        menu_utilisateurs
        return
    fi
    sudo usermod -aG "$NomGroupe" "$NomUtilisateur" 2>/dev/null
    if id -nG "$NomUtilisateur" | grep -qw "$NomGroupe"; then
        echo ""
        echo -e "${VERT}UTILISATEUR \"$NomUtilisateur\" AJOUTE AU GROUPE *$NomGroupe*${RESET}"
        sauvegarder_log "Action_AjoutGroupe_${NomUtilisateur}_${NomGroupe}"
    else
        echo -e "${ROUGE}IMPOSSIBLE D'AJOUTER L'UTILISATEUR AU GROUPE${RESET}"
    fi
    echo ""
    read -p "VOULEZ-VOUS AJOUTER UN AUTRE UTILISATEUR ? [O/N]: " Continuer
    if [ "$Continuer" = "O" ] || [ "$Continuer" = "o" ]; then
        ajouter_utilisateur_groupe
    else
        menu_utilisateurs
    fi
}

#FONCTION POUR AJOUTE UN UTILISATEUR AU GROUPE SUDO
ajouter_utilisateur_groupe_admin() {
    afficher_entete
    echo "  AJOUT AUX ADMINISTRATEURS *SUDO*"
    echo ""
    afficher_utilisateurs_locaux
    read -p "NOM D'UTILISATEUR (Q POUR QUITTER): " NomUtilisateur
    if [ "$NomUtilisateur" = "q" ] || [ "$NomUtilisateur" = "Q" ]; then
        sauvegarder_log "Navigation_Retour"
        menu_utilisateurs
        return
    fi
    if [ -z "$NomUtilisateur" ]; then
        echo -e "${ROUGE}NOM D'UTILISATEUR NON SPECIFIE${RESET}"
        read -p "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        ajouter_utilisateur_groupe_admin
        return
    fi
    if ! cat /etc/passwd | grep "^$NomUtilisateur:" > /dev/null; then
        echo -e "${ROUGE}L'UTILISATEUR \"$NomUtilisateur\" N'EXISTE PAS${RESET}"
        read -p "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        ajouter_utilisateur_groupe_admin
        return
    fi
    if ! verifier_mot_de_passe_admin "AJOUTER \"$NomUtilisateur\" AU GROUPE *SUDO*"; then
        ajouter_utilisateur_groupe_admin
        return
    fi
    read -p "AJOUTER \"$NomUtilisateur\" AU GROUPE *SUDO* ? [O/N]: " Confirm
    if [ "$Confirm" != "O" ] && [ "$Confirm" != "o" ]; then
        echo -e "${GRIS}AJOUT ANNULE${RESET}"
        read -p "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        menu_utilisateurs
        return
    fi
    echo "$MOT_DE_PASSE_ADMIN" | sudo -S usermod -aG sudo "$NomUtilisateur" 2>/dev/null
    if id -nG "$NomUtilisateur" | grep -qw "sudo"; then
        echo ""
        echo -e "${VERT}UTILISATEUR \"$NomUtilisateur\" AJOUTE AU GROUPE *SUDO*${RESET}"
        sauvegarder_log "Action_AjoutGroupeSudo_$NomUtilisateur"
    else
        echo -e "${ROUGE}IMPOSSIBLE D'AJOUTER L'UTILISATEUR AU GROUPE${RESET}"
    fi
    echo ""
    read -p "VOULEZ-VOUS AJOUTER UN AUTRE UTILISATEUR ? [O/N]: " Continuer
    if [ "$Continuer" = "O" ] || [ "$Continuer" = "o" ]; then
        ajouter_utilisateur_groupe_admin
    else
        menu_utilisateurs
    fi
}

#FONCTION POUR CHANGER LE MOT DE PASSE DUN USER
modifier_mot_de_passe_utilisateur() {
    afficher_entete
    echo "  CHANGEMENT DE MOT DE PASSE"
    echo ""
    afficher_utilisateurs_locaux
    read -p "NOM D'UTILISATEUR (Q POUR QUITTER): " NomUtilisateur
    if [ "$NomUtilisateur" = "q" ] || [ "$NomUtilisateur" = "Q" ]; then
        sauvegarder_log "Navigation_Retour"
        menu_utilisateurs
        return
    fi
    if [ -z "$NomUtilisateur" ]; then
        echo -e "${ROUGE}NOM D'UTILISATEUR NON SPECIFIE${RESET}"
        read -p "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        modifier_mot_de_passe_utilisateur
        return
    fi
    if ! cat /etc/passwd | grep "^$NomUtilisateur:" > /dev/null; then
        echo -e "${ROUGE}L'UTILISATEUR \"$NomUtilisateur\" N'EXISTE PAS${RESET}"
        read -p "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        modifier_mot_de_passe_utilisateur
        return
    fi
    read -p "CONFIRMER LE CHANGEMENT DE MOT DE PASSE POUR \"$NomUtilisateur\" ? [O/N]: " Confirm
    if [ "$Confirm" != "O" ] && [ "$Confirm" != "o" ]; then
        echo -e "${GRIS}MODIFICATION ANNULEE${RESET}"
        read -p "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        menu_utilisateurs
        return
    fi
    echo ""
    read -s -p "NOUVEAU MOT DE PASSE : " mot_de_passe
    echo ""
    read -s -p "CONFIRMEZ LE MOT DE PASSE : " mot_de_passe_confirm
    echo ""
    if [ "$mot_de_passe" = "$mot_de_passe_confirm" ]; then
        echo "$NomUtilisateur:$mot_de_passe" | sudo chpasswd 2>/dev/null
        if [ $? -eq 0 ]; then
            echo ""
            echo -e "${VERT}MOT DE PASSE MODIFIE POUR \"$NomUtilisateur\"${RESET}"
            sauvegarder_log "Action_ModificationMotDePasse_$NomUtilisateur"
        else
            echo -e "${ROUGE}IMPOSSIBLE DE MODIFIER LE MOT DE PASSE${RESET}"
        fi
    else
        echo -e "${ROUGE}LES MOTS DE PASSE NE CORRESPONDENT PAS${RESET}"
    fi
    echo ""
    read -p "VOULEZ-VOUS MODIFIER UN AUTRE MOT DE PASSE ? [O/N]: " Continuer
    if [ "$Continuer" = "O" ] || [ "$Continuer" = "o" ]; then
        modifier_mot_de_passe_utilisateur
    else
        menu_utilisateurs
    fi
}

#FONCTION POUR CREE UN NOUVEL UTILISATEUR
creer_utilisateur_local() {
    afficher_entete
    echo "  CREATION D'UN COMPTE UTILISATEUR"
    echo ""
    afficher_utilisateurs_locaux
    read -p "NOM DU NOUVEL UTILISATEUR (Q POUR QUITTER): " NomUtilisateur
    if [ "$NomUtilisateur" = "q" ] || [ "$NomUtilisateur" = "Q" ]; then
        sauvegarder_log "Navigation_Retour"
        menu_utilisateurs
        return
    fi
    if [ -z "$NomUtilisateur" ]; then
        echo -e "${ROUGE}NOM D'UTILISATEUR NON SPECIFIE${RESET}"
        read -p "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        creer_utilisateur_local
        return
    fi
    if cat /etc/passwd | grep "^$NomUtilisateur:" > /dev/null; then
        echo -e "${GRIS}L'UTILISATEUR \"$NomUtilisateur\" EXISTE DEJA${RESET}"
        read -p "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        creer_utilisateur_local
        return
    fi
    read -p "CONFIRMER LA CREATION DE \"$NomUtilisateur\" ? [O/N]: " Confirm
    if [ "$Confirm" != "O" ] && [ "$Confirm" != "o" ]; then
        echo -e "${GRIS}CREATION ANNULEE${RESET}"
        read -p "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        menu_utilisateurs
        return
    fi
    sudo useradd -m -s /bin/bash "$NomUtilisateur" 2>/dev/null
    if cat /etc/passwd | grep "^$NomUtilisateur:" > /dev/null; then
        echo ""
        echo -e "${VERT}UTILISATEUR \"$NomUtilisateur\" CREE AVEC SUCCES${RESET}"
        echo ""
        read -s -p "DEFINISSEZ LE MOT DE PASSE : " mot_de_passe
        echo ""
        read -s -p "CONFIRMEZ LE MOT DE PASSE : " mot_de_passe_confirm
        echo ""
        if [ "$mot_de_passe" = "$mot_de_passe_confirm" ]; then
            echo "$NomUtilisateur:$mot_de_passe" | sudo chpasswd 2>/dev/null
            if [ $? -eq 0 ]; then
                sauvegarder_log "Action_CreationUtilisateur_$NomUtilisateur"
                echo ""
                echo -e "${VERT}UTILISATEUR \"$NomUtilisateur\" PRET A SE CONNECTER${RESET}"
            else
                echo -e "${ROUGE}IMPOSSIBLE DE DEFINIR LE MOT DE PASSE${RESET}"
            fi
        else
            echo -e "${ROUGE}LES MOTS DE PASSE NE CORRESPONDENT PAS${RESET}"
        fi
    else
        echo -e "${ROUGE}IMPOSSIBLE DE CREER L'UTILISATEUR${RESET}"
    fi
    echo ""
    read -p "VOULEZ-VOUS CREER UN AUTRE UTILISATEUR ? [O/N]: " Continuer
    if [ "$Continuer" = "O" ] || [ "$Continuer" = "o" ]; then
        creer_utilisateur_local
    else
        menu_utilisateurs
    fi
}

#FONCTION POUR SUPPRIME UN COMPTE UTILISATEUR
supprimer_utilisateur_local() {
    afficher_entete
    echo "  SUPPRESSION DE COMPTE UTILISATEUR"
    echo ""
    afficher_utilisateurs_locaux
    read -p "NOM D'UTILISATEUR (Q POUR QUITTER): " NomUtilisateur
    if [ "$NomUtilisateur" = "q" ] || [ "$NomUtilisateur" = "Q" ]; then
        sauvegarder_log "Navigation_Retour"
        menu_utilisateurs
        return
    fi
    if [ -z "$NomUtilisateur" ]; then
        echo -e "${ROUGE}NOM D'UTILISATEUR NON SPECIFIE${RESET}"
        read -p "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        supprimer_utilisateur_local
        return
    fi
    if ! cat /etc/passwd | grep "^$NomUtilisateur:" > /dev/null; then
        echo -e "${ROUGE}L'UTILISATEUR \"$NomUtilisateur\" N'EXISTE PAS${RESET}"
        read -p "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        supprimer_utilisateur_local
        return
    fi
    if ! verifier_mot_de_passe_admin "SUPPRIMER UTILISATEUR \"$NomUtilisateur\""; then
        supprimer_utilisateur_local
        return
    fi
    read -p "SUPPRIMER DEFINITIVEMENT \"$NomUtilisateur\" ? [O/N]: " Confirm
    if [ "$Confirm" != "O" ] && [ "$Confirm" != "o" ]; then
        echo -e "${GRIS}SUPPRESSION ANNULEE${RESET}"
        read -p "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        menu_utilisateurs
        return
    fi
    echo "$MOT_DE_PASSE_ADMIN" | sudo -S userdel "$NomUtilisateur" 2>/dev/null
    if ! cat /etc/passwd | grep "^$NomUtilisateur:" > /dev/null; then
        echo ""
        echo -e "${VERT}UTILISATEUR \"$NomUtilisateur\" SUPPRIME${RESET}"
        sauvegarder_log "Action_SuppressionUtilisateur_$NomUtilisateur"
    else
        echo -e "${ROUGE}IMPOSSIBLE DE SUPPRIMER L'UTILISATEUR${RESET}"
    fi
    echo ""
    read -p "VOULEZ-VOUS SUPPRIMER UN AUTRE UTILISATEUR ? [O/N]: " Continuer
    if [ "$Continuer" = "O" ] || [ "$Continuer" = "o" ]; then
        supprimer_utilisateur_local
    else
        menu_utilisateurs
    fi
}

#FONCTION POUR DESACTIVEE UN COMPTE UTILISATEUR
desactiver_utilisateur_local() {
    afficher_entete
    echo "  DESACTIVATION DE COMPTE UTILISATEUR"
    echo ""
    afficher_utilisateurs_locaux
    read -p "NOM D'UTILISATEUR (Q POUR QUITTER): " NomUtilisateur
    if [ "$NomUtilisateur" = "q" ] || [ "$NomUtilisateur" = "Q" ]; then
        sauvegarder_log "Navigation_Retour"
        menu_utilisateurs
        return
    fi
    if [ -z "$NomUtilisateur" ]; then
        echo -e "${ROUGE}NOM D'UTILISATEUR NON SPECIFIE${RESET}"
        read -p "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        desactiver_utilisateur_local
        return
    fi
    if ! cat /etc/passwd | grep "^$NomUtilisateur:" > /dev/null; then
        echo -e "${ROUGE}L'UTILISATEUR \"$NomUtilisateur\" N'EXISTE PAS${RESET}"
        read -p "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        desactiver_utilisateur_local
        return
    fi
    if ! verifier_mot_de_passe_admin "DESACTIVER UTILISATEUR \"$NomUtilisateur\""; then
        desactiver_utilisateur_local
        return
    fi
    read -p "DESACTIVER \"$NomUtilisateur\" ? [O/N]: " Confirm
    if [ "$Confirm" != "O" ] && [ "$Confirm" != "o" ]; then
        echo -e "${GRIS}DESACTIVATION ANNULEE${RESET}"
        read -p "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        menu_utilisateurs
        return
    fi
    echo "$MOT_DE_PASSE_ADMIN" | sudo -S usermod -L "$NomUtilisateur" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${VERT}UTILISATEUR \"$NomUtilisateur\" DESACTIVE${RESET}"
        sauvegarder_log "Action_DesactivationUtilisateur_$NomUtilisateur"
    else
        echo -e "${ROUGE}IMPOSSIBLE DE DESACTIVER L'UTILISATEUR${RESET}"
    fi
    echo ""
    read -p "VOULEZ-VOUS DESACTIVER UN AUTRE UTILISATEUR ? [O/N]: " Continuer
    if [ "$Continuer" = "O" ] || [ "$Continuer" = "o" ]; then
        desactiver_utilisateur_local
    else
        menu_utilisateurs
    fi
}

#FONCTION QUI AFFICHE LES GROUPES DUN UTILISATEUR
afficher_groupes_utilisateur() {
    afficher_entete
    echo "  GROUPES D'APPARTENANCE D'UN UTILISATEUR"
    echo ""
    afficher_utilisateurs_locaux
    read -p "NOM D'UTILISATEUR (Q POUR QUITTER): " NomUtilisateur
    if [ "$NomUtilisateur" = "q" ] || [ "$NomUtilisateur" = "Q" ]; then
        sauvegarder_log "Navigation_Retour"
        menu_utilisateurs
        return
    fi
    if [ -z "$NomUtilisateur" ]; then
        echo -e "${ROUGE}NOM D'UTILISATEUR NON SPECIFIE${RESET}"
        read -p "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        afficher_groupes_utilisateur
        return
    fi
    if ! cat /etc/passwd | grep "^$NomUtilisateur:" > /dev/null; then
        echo -e "${ROUGE}L'UTILISATEUR \"$NomUtilisateur\" N'EXISTE PAS${RESET}"
        read -p "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        afficher_groupes_utilisateur
        return
    fi
    sauvegarder_log "Consultation_GroupesUtilisateur_$NomUtilisateur"
    groupes=$(id -Gn "$NomUtilisateur" | sed 's/ / | /g')
    sauvegarder_info "=== GROUPES UTILISATEUR === $(date '+%Y-%m-%d %H:%M:%S')UTILISATEUR: $NomUtilisateur GROUPES: $groupes"
    echo ""
    echo "GROUPES DE \"$NomUtilisateur\": $groupes"
    echo ""
    read -p "VOULEZ-VOUS CONSULTER UN AUTRE UTILISATEUR ? [O/N]: " Continuer
    if [ "$Continuer" = "O" ] || [ "$Continuer" = "o" ]; then
        afficher_groupes_utilisateur
    else
        menu_utilisateurs
    fi
}

####################################################################
#                         FONCTIONS MENUS                          #
####################################################################

#FONCTION QUI AFFICHE LE MENU REPERTOIRES
menu_repertoires() {
    afficher_entete
    sauvegarder_log "Navigation_MenuRepertoires"
    echo "  REPERTOIRES"
    echo ""
    echo "  1.CREER UN REPERTOIRE"
    echo "  2.SUPPRIMER UN REPERTOIRE"
    echo "  3.RETOUR"
    echo ""
    read -p "TAPEZ [1-3]: " Choix
    case $Choix in
        1) creer_repertoire ;;
        2) supprimer_repertoire ;;
        3) sauvegarder_log "Navigation_Retour"; menu_gestion_machine ;;
        *)
            echo -e "${ROUGE}CHOIX INVALIDE${RESET}"
            read -p "APPUYEZ SUR [ENTREE] POUR CONTINUER"
            menu_repertoires
            ;;
    esac
}

#FONCTION QUI AFFICHE LE MENU LOGICIELS
menu_logiciels() {
    afficher_entete
    sauvegarder_log "Navigation_MenuLogiciels"
    echo "  LOGICIELS"
    echo ""
    echo "  1.APPLICATIONS INSTALLEES"
    echo "  2.MISES A JOUR CRITIQUES"
    echo "  3.RETOUR"
    echo ""
    read -p "TAPEZ [1-3]: " Choix
    case $Choix in
        1) afficher_applications_installees ;;
        2) afficher_mises_a_jour_manquantes ;;
        3) sauvegarder_log "Navigation_Retour"; menu_gestion_machine ;;
        *)
            echo -e "${ROUGE}CHOIX INVALIDE${RESET}"
            read -p "APPUYEZ SUR [ENTREE] POUR CONTINUER"
            menu_logiciels
            ;;
    esac
}

#FONCTION QUI AFFICHE LE MENU DES SERVICES
menu_services() {
    afficher_entete
    sauvegarder_log "Navigation_MenuServices"
    echo "  GESTION DES SERVICES"
    echo ""
    echo "  1.LISTER LES SERVICES EN COURS"
    echo "  2.RETOUR"
    echo ""
    read -p "TAPEZ [1-2]: " Choix
    case $Choix in
        1) afficher_services_en_cours ;;
        2) sauvegarder_log "Navigation_Retour"; menu_gestion_machine ;;
        *)
            echo -e "${ROUGE}CHOIX INVALIDE${RESET}"
            read -p "APPUYEZ SUR [ENTREE] POUR CONTINUER"
            menu_services
            ;;
    esac
}

#FONCTION QUI AFFICHE LE MENU RESEAU
menu_reseau() {
    afficher_entete
    sauvegarder_log "Navigation_MenuReseau"
    echo "  RESEAU"
    echo ""
    echo "  1.PORTS OUVERTS"
    echo "  2.INFORMATION RESEAU"
    echo "  3.ACTIVATION DU PARE-FEU"
    echo "  4.RETOUR"
    echo ""
    read -p "TAPEZ [1-4]: " Choix
    case $Choix in
        1) afficher_ports_ouverts ;;
        2) afficher_config_ip ;;
        3) activer_pare_feu ;;
        4) sauvegarder_log "Navigation_Retour"; menu_gestion_machine ;;
        *)
            echo -e "${ROUGE}CHOIX INVALIDE${RESET}"
            read -p "APPUYEZ SUR [ENTREE] POUR CONTINUER"
            menu_reseau
            ;;
    esac
}

#FONCTION QUI AFFICHE LE MENU SYSTEME
menu_systeme() {
    afficher_entete
    sauvegarder_log "Navigation_MenuSysteme"
    echo "  SYSTEME"
    echo ""
    echo "  1.INFORMATIONS SYSTEME"
    echo "  2.INFORMATION SUR LA RAM"
    echo "  3.RETOUR"
    echo ""
    read -p "TAPEZ [1-3]: " Choix
    case $Choix in
        1) afficher_info_systeme ;;
        2) afficher_utilisation_ram ;;
        3) sauvegarder_log "Navigation_Retour"; menu_gestion_machine ;;
        *)
            echo -e "${ROUGE}CHOIX INVALIDE${RESET}"
            read -p "APPUYEZ SUR [ENTREE] POUR CONTINUER"
            menu_systeme
            ;;
    esac
}

#FONCTION QUI AFFICHE LE MENU DES CONTROLES
menu_controles() {
    afficher_entete
    sauvegarder_log "Navigation_MenuControles"
    echo "  CONTROLES"
    echo ""
    echo "  1.REDEMARRAGE"
    echo "  2.EXECUTER UN SCRIPT"
    echo "  3.PRISE DE MAIN A DISTANCE (CLI)"
    echo "  4.RETOUR"
    echo ""
    read -p "TAPEZ [1-4]: " Choix
    case $Choix in
        1) redemarrer_machine ;;
        2) executer_script_distant ;;
        3) ouvrir_console_distante ;;
        4) sauvegarder_log "Navigation_Retour"; menu_gestion_machine ;;
        *)
            echo -e "${ROUGE}CHOIX INVALIDE${RESET}"
            read -p "APPUYEZ SUR [ENTREE] POUR CONTINUER"
            menu_controles
            ;;
    esac
}

#FONCTION QUI AFFICHE LE MENU DES UTILISATEURS
menu_utilisateurs() {
    afficher_entete
    sauvegarder_log "Navigation_MenuUtilisateurs"
    echo "  GESTION DES UTILISATEURS"
    echo ""
    echo "  1.CREER UN COMPTE UTILISATEUR LOCAL"
    echo "  2.CHANGER UN MOT DE PASSE"
    echo "  3.DESACTIVER UN COMPTE"
    echo "  4.SUPPRIMER UN COMPTE"
    echo "  5.VERIFIER L'APPARTENANCE A UN GROUPE"
    echo "  6.AJOUTER AUX ADMINISTRATEURS"
    echo "  7.AJOUTER A UN GROUPE"
    echo "  8.DROITS ET PERMISSIONS SUR FICHIER"
    echo "  9.RETOUR"
    echo ""
    read -p "TAPEZ [1-9]: " Choix
    case $Choix in
        1) creer_utilisateur_local ;;
        2) modifier_mot_de_passe_utilisateur ;;
        3) desactiver_utilisateur_local ;;
        4) supprimer_utilisateur_local ;;
        5) afficher_groupes_utilisateur ;;
        6) ajouter_utilisateur_groupe_admin ;;
        7) ajouter_utilisateur_groupe ;;
        8) afficher_permissions_utilisateur ;;
        9) sauvegarder_log "Navigation_Retour"; menu_principal ;;
        *)
            echo -e "${ROUGE}CHOIX INVALIDE${RESET}"
            read -p "APPUYEZ SUR [ENTREE] POUR CONTINUER"
            menu_utilisateurs
            ;;
    esac
}

#FONCTION QUI AFFICHE LE MENU DE GESTION DE LA MACHINE
menu_gestion_machine() {
    afficher_entete
    sauvegarder_log "Navigation_MenuGestionMachine"
    echo "  GESTION DE LA MACHINE"
    echo ""
    echo "  1.REPERTOIRES"
    echo "  2.LOGICIELS"
    echo "  3.SERVICES"
    echo "  4.RESEAU"
    echo "  5.SYSTEME"
    echo "  6.CONTROLES"
    echo "  7.RETOUR"
    echo ""
    read -p "TAPEZ [1-7]: " Choix
    case $Choix in
        1) menu_repertoires ;;
        2) menu_logiciels ;;
        3) menu_services ;;
        4) menu_reseau ;;
        5) menu_systeme ;;
        6) menu_controles ;;
        7) sauvegarder_log "Navigation_Retour"; menu_principal ;;
        *)
            echo -e "${ROUGE}CHOIX INVALIDE${RESET}"
            read -p "APPUYEZ SUR [ENTREE] POUR CONTINUER"
            menu_gestion_machine
            ;;
    esac
}

#FONCTION QUI AFFICHE LE MENU PRINCIPAL
menu_principal() {
    afficher_entete
    sauvegarder_log "Navigation_MenuPrincipal"
    echo "  MENU PRINCIPAL"
    echo ""
    echo "  1.GESTION DE LA MACHINE"
    echo "  2.GESTION DES UTILISATEURS"
    echo "  Q.QUITTER"
    echo ""
    read -p "TAPEZ [1-2 OU Q]: " Choix
    case $Choix in
        1) menu_gestion_machine ;;
        2) menu_utilisateurs ;;
        Q|q)
            clear
            sauvegarder_log "DeconnexionMachine"
            exit 0
            ;;
        *)
            echo -e "${ROUGE}CHOIX INVALIDE${RESET}"
            read -p "APPUYEZ SUR [ENTREE] POUR CONTINUER"
            menu_principal
            ;;
    esac
}

####################################################################
#                       DEMARRAGE DU SCRIPT                        #
####################################################################

initialiser_journal
sauvegarder_log "ConnexionMachine"
menu_principal