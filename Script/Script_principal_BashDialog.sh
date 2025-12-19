#!/bin/bash
##################################################################
#                 SCRIPT PRINCIPAL AVCE DIALOG                   #
#                    SCRIPT_BY ANIS FRED EROS                    #
#                       WILD_CODE_SCHOOL                         #
#                        12/12/2025                              #
##################################################################

export LANG=C.UTF-8
export LC_ALL=C.UTF-8

export DIALOG_OK="OK"
export DIALOG_CANCEL="Retour"
export DIALOG_HELP="Aide"
export DIALOG_EXTRA="Extra"
export DIALOG_ITEM_HELP="Aide"
export DIALOG_EXIT="Retour"
###############################################################
#          CONFIGURATION THEME DE DIALOG                      #      
###############################################################
export DIALOGRC="/tmp/dialogrc_$$"
echo "screen_color = (WHITE,MAGENTA,ON)
shadow_color = (BLACK,BLACK,OFF)
dialog_color = (BLACK,WHITE,OFF)
title_color = (BLUE,WHITE,ON)
border_color = (BLACK,WHITE,ON)
button_active_color = (WHITE,MAGENTA,ON)
button_inactive_color = (BLACK,WHITE,ON)
button_key_active_color = (WHITE,MAGENTA,ON)
button_key_inactive_color = (BLACK,WHITE,ON)
button_label_active_color = (WHITE,MAGENTA,ON)
button_label_inactive_color = (BLACK,WHITE,ON)
inputbox_color = (BLACK,WHITE,OFF)
inputbox_border_color = (BLACK,WHITE,ON)
menubox_color = (BLACK,WHITE,OFF)
menubox_border_color = (BLACK,WHITE,ON)
item_color = (BLACK,WHITE,OFF)
item_selected_color = (WHITE,MAGENTA,ON)
tag_color = (BLACK,WHITE,ON)
tag_selected_color = (WHITE,MAGENTA,ON)
tag_key_color = (BLACK,WHITE,ON)
tag_key_selected_color = (WHITE,MAGENTA,ON)
gauge_color = (MAGENTA,WHITE,ON)
check_color = (BLACK,WHITE,OFF)
check_selected_color = (WHITE,MAGENTA,ON)
use_shadow = ON
use_colors = ON" > "$DIALOGRC"

###############################################################
#                        CONFIGURATION                        #
###############################################################

ip_reseau="172.16.20."
export port_ssh="22222"
delai_ping=1
fichier_temp="/tmp/scriptbash_machines_$$.txt"
fichier_noms="/tmp/scriptbash_noms_$$.txt"
fichier_result="/tmp/scriptbash_result_$$.txt"
export utilisateur_linux="wilder"
local_ip=""
declare -a liste_ip
declare -A noms_machines
machine_ip=""
machine_nom=""
machine_user=""
LARGEUR=90
HAUTEUR=25
MENU_HAUTEUR=10
BACKTITLE=""

###############################################################
#                     FONCTIONS DIALOG                        #
###############################################################

#FONCTION POUR AFFICHE UNE INFORMATION
afficher_info() {
    local titre="${2:-INFORMATION}"
    dialog --backtitle "$BACKTITLE" \
        --title "[ $titre ]" \
        --msgbox "$1" 10 55
}

#FONCTION POUR AFFICHE UNE ERREUR
afficher_erreur() {
    dialog --backtitle "$BACKTITLE" \
        --title "[ ERREUR ]" \
        --msgbox "$1" 10 55
}

#FONCTION POUR AFFICHE UN SUCCES
afficher_succes() {
    dialog --backtitle "$BACKTITLE" \
        --title "[ SUCCES ]" \
        --msgbox "$1" 10 55
}

#FONCTION POUR AFFICHE UN AVERTISSEMENT
afficher_avertissement() {
    dialog --backtitle "$BACKTITLE" \
        --title "[ ATTENTION ]" \
        --msgbox "$1" 10 55
}

#FONCTION POUR DEMANDER CONFIRMATION O/N
demander_confirmation() {
    dialog --backtitle "$BACKTITLE" \
        --title "[ CONFIRMATION ]" \
        --yes-label "Oui" \
        --no-label "Non" \
        --cancel-label "Retour" --stdout \
        --yesno "$1" 10 55
    return $?
}

#FONCTION POUR DEMANDER UNE SAISIE
demander_saisie() {
    local titre="$1"
    local message="$2"
    local saisie
    saisie=$(dialog --backtitle "$BACKTITLE" \
        --title "[ $titre ]" \
        --cancel-label "Retour" --stdout \
        --inputbox "$message" 12 60)
    local ret=$?
    if [ $ret -eq 0 ] && [ -n "$saisie" ]; then
        echo "$saisie"
    fi
    return $ret
}

#FONCTION POUR DEMANDE UN MDP
demander_mot_de_passe() {
    local titre="$1"
    local message="$2"
    local mdp
    mdp=$(dialog --backtitle "$BACKTITLE" \
        --title "[ $titre ]" \
        --cancel-label "Retour" --stdout \
        --insecure \
        --passwordbox "$message" 10 50)
    local ret=$?
    if [ $ret -eq 0 ]; then
        echo "$mdp"
    fi
    return $ret
}

#FONCTION POUR AFFICHE DU TEXTE
afficher_texte() {
    local titre="$1"
    local contenu="$2"
    echo -e "$contenu" > "$fichier_result"
    dialog --backtitle "$BACKTITLE" \
        --title "[ $titre ]" \
        --exit-label "Retour" \
        --textbox "$fichier_result" $HAUTEUR $LARGEUR
}

#FONCTION POUR AFFICHE UN MESSAGE DE CHARGEMENT
afficher_chargement() {
    local message="$1"
    dialog --backtitle "$BACKTITLE" \
        --title "[ CHARGEMENT ]" \
        --infobox "\n  $message\n\n  Veuillez patienter...\n" 7 45
}
###############################################################
#                       FONCTIONS SSH                         #
###############################################################
#FONCTION POUR EXECUTE UNE COMMANDE SSH SUR LA MACHINE DISTANTE
executer_ssh() {
    local commande="$1"
    ssh -p $port_ssh -o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=no "${machine_user}@${machine_ip}" "$commande" 2>&1 
}
###############################################################
#                 FONCTION AFFICHER UTILISATEURS              #
###############################################################

#FONCTION POUR AFFICHE LA LISTE DES UTILISATEURS LOCAUX
afficher_utilisateurs_locaux() {
    executer_ssh "cat /etc/passwd | grep '/home' | cut -d':' -f1 | tr '\n' ' ' | sed 's/ / | /g' | sed 's/ | $//'"
}
###############################################################
#                        DETECTION RESEAU                     #
###############################################################

#FONCTION POUR DETECTE UNE MACHINE LINUX
detecter_linux() {
    local ip="$1"
    if ssh -p $port_ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o BatchMode=yes "${utilisateur_linux}@${ip}" "uname" 2>/dev/null | grep -qi "linux"; then
        return 0
    fi
    return 1
}

#FONCTION POUR RECUPERE LE NOM DUNE MACHINE VIA SSH
recuperer_nom_machine() {
    local ip="$1"
    local nom=""
    nom=$(ssh -p $port_ssh -o ConnectTimeout=3 -o BatchMode=yes -o StrictHostKeyChecking=no "${utilisateur_linux}@${ip}" "hostname" 2>/dev/null | tr -d '\r')
    if [ -n "$nom" ]; then
        noms_machines["$ip"]="$nom"
    else
        noms_machines["$ip"]="?"
    fi
}

#FONCTION POUR SCANNE LE RESEAU ET TROUVER LES MACHINES LINUX
scanner_reseau() {
    liste_ip=()
    noms_machines=()
    > "$fichier_temp"
    > "$fichier_noms"
    if [ -z "$local_ip" ]; then
        local_ip=$(hostname -I 2>/dev/null | tr ' ' '\n' | grep "^$ip_reseau" | head -n1)
    fi
    (
        for i in $(seq 1 254); do
            local ip="${ip_reseau}${i}"
            (
                ping -c 1 -W "$delai_ping" "$ip" &>/dev/null && echo "$ip" >> "$fichier_temp"
            ) &
            if [ $((i % 50)) -eq 0 ]; then
                wait
            fi
            local points_num=$(( (i / 20) % 3 ))
            local points=""
            case $points_num in
                0) points="." ;;
                1) points=".." ;;
                2) points="..." ;;
            esac
            local pct=$(( i * 100 / 254 ))
            echo "XXX"
            echo "$pct"
            echo "\nScan du reseau en cours$points\n\nAdresse: $ip"
            echo "XXX"
        done
        wait
    ) | dialog --backtitle "$BACKTITLE" \
            --title "[ SCAN DU RESEAU ]" \
            --gauge "\nScan du reseau en cours...\n" 10 55 0
    if [ -s "$fichier_temp" ]; then
        local ips_trouvees=()
        while read -r ligne; do
            [ -n "$ligne" ] && ips_trouvees+=("$ligne")
        done < "$fichier_temp"
        for ip in "${ips_trouvees[@]}"; do
            if [ "$ip" != "$local_ip" ]; then
                if ssh -p $port_ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o BatchMode=yes "${utilisateur_linux}@${ip}" "uname" 2>/dev/null | grep -qi "linux"; then
                    local nom=$(ssh -p $port_ssh -o ConnectTimeout=3 -o BatchMode=yes -o StrictHostKeyChecking=no "${utilisateur_linux}@${ip}" "hostname" 2>/dev/null | tr -d '\r')
                    [ -z "$nom" ] && nom="?"
                    liste_ip+=("$ip")
                    noms_machines["$ip"]="$nom"
                fi
            fi
        done
    fi
    rm -f "$fichier_temp" "$fichier_noms"
    [ ${#liste_ip[@]} -gt 0 ]
}
###############################################################
#                     FONCTIONS REPERTOIRES                   #
###############################################################

#FONCTION POUR CREE UN NOUVEAU REPERTOIRE
creer_repertoire() {
    while true; do
        local Chemin
        Chemin=$(demander_saisie "CREATION DE REPERTOIRE" "Chemin complet du repertoire a creer :")
        [ $? -ne 0 ] && return
        if [ -z "$Chemin" ]; then
            afficher_erreur "CHEMIN NON SPECIFIE"
            continue
        fi
        local existe=$(executer_ssh "[ -d '$Chemin' ] && echo 'OUI' || echo 'NON'")
        if [ "$existe" = "OUI" ]; then
            afficher_avertissement "LE REPERTOIRE EXISTE DEJA"
            continue
        fi
        demander_confirmation "Confirmer la creation de *$Chemin* ?" || {
            afficher_avertissement "CREATION ANNULEE"
            return
        }
        afficher_chargement "Creation du repertoire..."
        local result=$(executer_ssh "sudo mkdir -p '$Chemin' 2>&1 && echo 'SUCCES'")
        if echo "$result" | grep -q "SUCCES"; then
            afficher_succes "REPERTOIRE CREE AVEC SUCCES"
        else
            afficher_erreur "IMPOSSIBLE DE CREER LE REPERTOIRE"
        fi
        demander_confirmation "Voulez-vous creer un autre repertoire ?" || return
    done
}

#FONCTION POUR SUPPRIME UN REPERTOIRE
supprimer_repertoire() {
    while true; do
        local Chemin
        Chemin=$(demander_saisie "SUPPRESSION DE REPERTOIRE" "Chemin complet du repertoire a supprimer :")
        [ $? -ne 0 ] && return
        if [ -z "$Chemin" ]; then
            afficher_erreur "CHEMIN NON SPECIFIE"
            continue
        fi
        local existe=$(executer_ssh "[ -d '$Chemin' ] && echo 'OUI' || echo 'NON'")
        if [ "$existe" = "NON" ]; then
            afficher_erreur "LE REPERTOIRE N'EXISTE PAS"
            continue
        fi
        demander_confirmation "Confirmer la suppression de *$Chemin* ?" || {
            afficher_avertissement "SUPPRESSION ANNULEE"
            return
        }
        afficher_chargement "Suppression du repertoire..."
        local result=$(executer_ssh "sudo rm -rf '$Chemin' 2>&1 && echo 'SUCCES'")
        if echo "$result" | grep -q "SUCCES"; then
            afficher_succes "REPERTOIRE SUPPRIME AVEC SUCCES"
        else
            afficher_erreur "IMPOSSIBLE DE SUPPRIMER LE REPERTOIRE"
        fi
        demander_confirmation "Voulez-vous supprimer un autre repertoire ?" || return
    done
}
###############################################################
#                    FONCTIONS LOGICIELS                      #
###############################################################

#FONCTION POUR AFFICHE LES APPLICATIONS INSTALLEES
afficher_applications_installees() {
    afficher_chargement "Recuperation des applications..."
    local liste_apps=$(executer_ssh "dpkg -l 2>/dev/null | grep '^ii' | awk '{print \$2}'")
    if [ -z "$liste_apps" ]; then
        afficher_erreur "Impossible de recuperer les applications"
    else
        afficher_texte "APPLICATIONS INSTALLEES" "$liste_apps"
    fi
}

#FONCTION POUR AFFICHE LES MISES A JOUR CRITIQUES
afficher_mises_a_jour_manquantes() {
    afficher_chargement "Verification des mises a jour critiques..."
    executer_ssh "sudo apt-get update -qq 2>/dev/null" >/dev/null
    local liste_maj=$(executer_ssh "apt-get -s upgrade 2>/dev/null | grep '^Inst' | grep -i 'security' | awk '{print \$2}'")
    if [ -z "$liste_maj" ]; then
        liste_maj=$(executer_ssh "apt list --upgradable 2>/dev/null | grep -i 'security' | cut -d'/' -f1 | grep -v '^Listing'")
    fi
    local nb_maj=0
    if [ -n "$liste_maj" ]; then
        nb_maj=$(echo "$liste_maj" | grep -v "^$" | wc -l)
    fi
    if [ "$nb_maj" -eq 0 ] || [ -z "$liste_maj" ]; then
        afficher_succes "AUCUNE MISE A JOUR CRITIQUE DISPONIBLE"
    else
        local result="$nb_maj MISE(S) A JOUR CRITIQUE(S) DISPONIBLE(S):

$liste_maj"
        afficher_texte "MISES A JOUR CRITIQUES" "$result"
    fi
}
###############################################################
#                   FONCTIONS SERVICES                        #
###############################################################
#FONCTION POUR AFFICHE LES SERVICES EN COURS
afficher_services_en_cours() {
    afficher_chargement "Recuperation des services..."
    local liste_services=$(executer_ssh "systemctl list-units --type=service --state=running --no-pager")
    if [ -z "$liste_services" ]; then
        afficher_erreur "Impossible de recuperer les services"
    else
        afficher_texte "SERVICES EN COURS D'EXECUTION" "$liste_services"
    fi
}
###############################################################
#                      FONCTIONS RESEAU                       #
###############################################################

#FONCTION POUR AFFICHE LES PORTS OUVERTS
afficher_ports_ouverts() {
    afficher_chargement "Recuperation des ports ouverts..."
    local liste_ports=$(executer_ssh "ss -tulnp 2>/dev/null | grep LISTEN")
    if [ -z "$liste_ports" ]; then
        liste_ports="Aucun port en ecoute"
    fi
    afficher_texte "PORTS OUVERTS" "$liste_ports"
}

#FONCTION POUR AFFICHE LA CONFIGURATION IP
afficher_config_ip() {
    afficher_chargement "Recuperation configuration IP..."
    local config_ip=$(executer_ssh "
        for iface in \$(ls /sys/class/net/); do
            IP=\$(ip -4 addr show \$iface 2>/dev/null | grep 'inet ' | tr -s ' ' | cut -d' ' -f3)
            if [ -n \"\$IP\" ]; then
                echo \"INTERFACE: \$iface - IP: \$IP\"
            fi
        done
        echo \"\"
        Passerelle=\$(ip route | grep default | tr -s ' ' | cut -d' ' -f3)
        echo \"PASSERELLE: \$Passerelle\"
    ")
    afficher_texte "INFORMATION RESEAU" "$config_ip"
}

#FONCTION POUR ACTIVER LE PARE-FEU
activer_pare_feu() {
    while true; do
        afficher_chargement "Verification du pare-feu..."
        local status=$(executer_ssh "systemctl is-active ufw 2>/dev/null")
        local statut_texte=""
        if [ "$status" = "active" ]; then
            statut_texte="STATUT DU PARE-FEU : ACTIF"
        else
            statut_texte="STATUT DU PARE-FEU : INACTIF"
        fi
        local choix
        choix=$(dialog --backtitle "$BACKTITLE" \
            --title "[ GESTION DU PARE-FEU ]" \
            --cancel-label "Retour" --stdout \
            --menu "\n$statut_texte\n" \
            $HAUTEUR $LARGEUR $MENU_HAUTEUR \
            "1" "Activer le pare-feu")
        [ $? -ne 0 ] && return
        case "$choix" in
            "1")
                demander_confirmation "Activer le pare-feu sur $machine_nom ?" || continue
                afficher_chargement "Activation du pare-feu..."
                local result=$(executer_ssh "sudo ufw --force enable 2>&1")
                if echo "$result" | grep -qi "enabled\|activ"; then
                    afficher_succes "PARE-FEU ACTIVE"
                else
                    afficher_erreur "IMPOSSIBLE D'ACTIVER LE PARE-FEU"
                fi
                ;;
        esac
    done
}
###############################################################
#                     FONCTIONS SYSTEME                       #
###############################################################

#FONCTION POUR AFFICHE LES INFORMATIONS SYSTEME
afficher_info_systeme() {
    afficher_chargement "Recuperation infos systeme..."
    local result=$(executer_ssh "
        echo \"NOM: \$(lsb_release -d 2>/dev/null | cut -f2)\"
        echo \"VERSION: \$(lsb_release -r 2>/dev/null | cut -f2)\"
        echo \"ARCHITECTURE: \$(uname -m)\"
        echo \"KERNEL: \$(uname -r)\"
        echo \"FABRICANT: \$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || echo 'NON DISPONIBLE')\"
        echo \"MODELE: \$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo 'NON DISPONIBLE')\"
    ")
    afficher_texte "INFORMATIONS SYSTEME" "$result"
}

#FONCTION POUR AFFICHE LUTILISATION DE LA RAM
afficher_utilisation_ram() {
    afficher_chargement "Recuperation utilisation RAM..."
    local result=$(executer_ssh "free -h")
    afficher_texte "UTILISATION DE LA MEMOIRE RAM" "$result"
}
###############################################################
#                    FONCTIONS CONTROLES                      #
###############################################################

#FONCTION POUR REDEMARRE LA MACHINE
redemarrer_machine() {
    demander_confirmation "Redemarrer la machine ?" || {
        afficher_avertissement "REDEMARRAGE ANNULE"
        return
    }
    demander_confirmation "CONFIRMER LE REDEMARRAGE ?" || {
        afficher_avertissement "REDEMARRAGE ANNULE"
        return
    }
    afficher_chargement "Redemarrage en cours..."
    executer_ssh "sudo reboot" &
    afficher_info "REDEMARRAGE EN COURS..." "REDEMARRAGE"
}

#FONCTION POUR EXECUTE UN SCRIPT
executer_script_distant() {
    while true; do
        local CheminScript
        CheminScript=$(demander_saisie "EXECUTION D'UN SCRIPT" "Chemin complet du script a executer :")
        [ $? -ne 0 ] && return
        if [ -z "$CheminScript" ]; then
            afficher_erreur "CHEMIN NON SPECIFIE"
            continue
        fi
        local existe=$(executer_ssh "[ -f '$CheminScript' ] && echo 'OUI' || echo 'NON'")
        if [ "$existe" = "NON" ]; then
            afficher_erreur "LE FICHIER N'EXISTE PAS"
            continue
        fi
        demander_confirmation "Executer le script *$CheminScript* ?" || {
            afficher_avertissement "EXECUTION ANNULEE"
            return
        }
        afficher_chargement "Execution du script en cours..."
        local result=$(executer_ssh "sudo bash '$CheminScript' 2>&1")
        if [ -z "$result" ]; then
            result="Script execute (aucune sortie)"
        fi
        afficher_succes "SCRIPT EXECUTE"
        afficher_texte "RESULTAT" "$result"
        demander_confirmation "Voulez-vous executer un autre script ?" || return
    done
}

#FONCTION POUR OUVRE UNE CONSOLE
ouvrir_console_distante() {
    ssh -p $port_ssh -t "${machine_user}@${machine_ip}" 'clear; echo ""; echo "  Machine : $(hostname)"; echo "  IP : '"$machine_ip"'"; echo ""; echo "  Tapez *exit* pour revenir au menu"; echo ""; exec bash'
}
###############################################################
#                   FONCTIONS UTILISATEURS                    #
###############################################################

#FONCTION POUR AFFICHE LES PERMISSIONS DUN FICHIER
afficher_permissions_utilisateur() {
    while true; do
        local Chemin
        Chemin=$(demander_saisie "DROITS ET PERMISSIONS SUR FICHIER" "Chemin du fichier ou dossier :")
        [ $? -ne 0 ] && return
        if [ -z "$Chemin" ]; then
            afficher_erreur "CHEMIN NON SPECIFIE"
            continue
        fi
        local existe=$(executer_ssh "[ -e '$Chemin' ] && echo 'OUI' || echo 'NON'")
        if [ "$existe" = "NON" ]; then
            afficher_erreur "LE CHEMIN *$Chemin* N'EXISTE PAS"
            continue
        fi
        afficher_chargement "Recuperation des permissions..."
        local permissions=$(executer_ssh "ls -lA '$Chemin' 2>&1")
        afficher_texte "PERMISSIONS" "CHEMIN: $Chemin

$permissions"
        demander_confirmation "Voulez-vous consulter un autre chemin ?" || return
    done
}

#FONCTION POUR CREE UN NOUVEL UTILISATEUR
creer_utilisateur_local() {
    while true; do
        afficher_chargement "Recuperation des utilisateurs existants..."
        local users_list=$(afficher_utilisateurs_locaux)
        local NomUtilisateur
        NomUtilisateur=$(dialog --backtitle "$BACKTITLE" \
            --title "[ CREATION D'UN COMPTE UTILISATEUR ]" \
            --cancel-label "Retour" --stdout \
            --inputbox "\nUtilisateurs locaux :\n$users_list\n\nNom du nouvel utilisateur :" 14 60)
        [ $? -ne 0 ] && return
        if [ -z "$NomUtilisateur" ]; then
            afficher_erreur "NOM D'UTILISATEUR NON SPECIFIE"
            continue
        fi
        local existe=$(executer_ssh "cat /etc/passwd | grep '^$NomUtilisateur:' && echo 'OUI'")
        if echo "$existe" | grep -q "OUI"; then
            afficher_avertissement "L'UTILISATEUR \"$NomUtilisateur\" EXISTE DEJA"
            continue
        fi
        demander_confirmation "Confirmer la creation de \"$NomUtilisateur\" ?" || {
            afficher_avertissement "CREATION ANNULEE"
            return
        }
        afficher_chargement "Creation de l'utilisateur..."
        local result=$(executer_ssh "sudo useradd -m -s /bin/bash '$NomUtilisateur' 2>&1")
        local verif=$(executer_ssh "cat /etc/passwd | grep '^$NomUtilisateur:'")
        if [ -n "$verif" ]; then
            afficher_succes "UTILISATEUR \"$NomUtilisateur\" CREE AVEC SUCCES"
            local mot_de_passe
            mot_de_passe=$(demander_mot_de_passe "MOT DE PASSE" "Definissez le mot de passe :")
            if [ -n "$mot_de_passe" ]; then
                local mot_de_passe_confirm
                mot_de_passe_confirm=$(demander_mot_de_passe "CONFIRMATION" "Confirmez le mot de passe :")
                if [ "$mot_de_passe" = "$mot_de_passe_confirm" ]; then
                    afficher_chargement "Definition du mot de passe..."
                    local result_mdp=$(executer_ssh "echo '$NomUtilisateur:$mot_de_passe' | sudo chpasswd 2>&1")
                    if [ -z "$result_mdp" ]; then
                        afficher_succes "UTILISATEUR \"$NomUtilisateur\" PRET A SE CONNECTER"
                    else
                        afficher_erreur "IMPOSSIBLE DE DEFINIR LE MOT DE PASSE"
                    fi
                else
                    afficher_erreur "LES MOTS DE PASSE NE CORRESPONDENT PAS"
                fi
            fi
        else
            afficher_erreur "IMPOSSIBLE DE CREER L'UTILISATEUR"
        fi
        demander_confirmation "Voulez-vous creer un autre utilisateur ?" || return
    done
}

#FONCTION POUR MODIFIE LE MOT DE PASSE DUN UTILISATEUR
modifier_mot_de_passe_utilisateur() {
    while true; do
        afficher_chargement "Recuperation des utilisateurs..."
        local users_list=$(afficher_utilisateurs_locaux)
        local NomUtilisateur
        NomUtilisateur=$(dialog --backtitle "$BACKTITLE" \
            --title "[ CHANGEMENT DE MOT DE PASSE ]" \
            --cancel-label "Retour" --stdout \
            --inputbox "\nUtilisateurs locaux :\n$users_list\n\nNom de l'utilisateur :" 14 60)
        [ $? -ne 0 ] && return
        if [ -z "$NomUtilisateur" ]; then
            afficher_erreur "NOM D'UTILISATEUR NON SPECIFIE"
            continue
        fi
        local existe=$(executer_ssh "cat /etc/passwd | grep '^$NomUtilisateur:'")
        if [ -z "$existe" ]; then
            afficher_erreur "L'UTILISATEUR \"$NomUtilisateur\" N'EXISTE PAS"
            continue
        fi
        demander_confirmation "Confirmer le changement de mot de passe pour \"$NomUtilisateur\" ?" || {
            afficher_avertissement "MODIFICATION ANNULEE"
            return
        }
        local mot_de_passe
        mot_de_passe=$(demander_mot_de_passe "NOUVEAU MOT DE PASSE" "Nouveau mot de passe :")
        [ -z "$mot_de_passe" ] && continue
        local mot_de_passe_confirm
        mot_de_passe_confirm=$(demander_mot_de_passe "CONFIRMATION" "Confirmez le mot de passe :")
        if [ "$mot_de_passe" = "$mot_de_passe_confirm" ]; then
            afficher_chargement "Modification du mot de passe..."
            local result=$(executer_ssh "echo '$NomUtilisateur:$mot_de_passe' | sudo chpasswd 2>&1")
            if [ -z "$result" ]; then
                afficher_succes "MOT DE PASSE MODIFIE POUR \"$NomUtilisateur\""
            else
                afficher_erreur "IMPOSSIBLE DE MODIFIER LE MOT DE PASSE"
            fi
        else
            afficher_erreur "LES MOTS DE PASSE NE CORRESPONDENT PAS"
        fi
        demander_confirmation "Voulez-vous modifier un autre mot de passe ?" || return
    done
}

#FONCTION POUR DESACTIVE UN COMPTE UTILISATEUR
desactiver_utilisateur_local() {
    while true; do
        afficher_chargement "Recuperation des utilisateurs"
        local users_list=$(afficher_utilisateurs_locaux)
        local NomUtilisateur
        NomUtilisateur=$(dialog --backtitle "$BACKTITLE" \
            --title "[ DESACTIVATION DE COMPTE UTILISATEUR ]" \
            --cancel-label "Retour" --stdout \
            --inputbox "\nUtilisateurs locaux :\n$users_list\n\nNom de l'utilisateur a desactiver :" 14 60)
        [ $? -ne 0 ] && return
        if [ -z "$NomUtilisateur" ]; then
            afficher_erreur "NOM D'UTILISATEUR NON SPECIFIE"
            continue
        fi
        local existe=$(executer_ssh "cat /etc/passwd | grep '^$NomUtilisateur:'")
        if [ -z "$existe" ]; then
            afficher_erreur "L'UTILISATEUR \"$NomUtilisateur\" N'EXISTE PAS"
            continue
        fi
        demander_confirmation "Desactiver \"$NomUtilisateur\" ?" || {
            afficher_avertissement "DESACTIVATION ANNULEE"
            return
        }
        afficher_chargement "Desactivation du compte..."
        local result=$(executer_ssh "sudo usermod -L '$NomUtilisateur' 2>&1")
        if [ -z "$result" ]; then
            afficher_succes "UTILISATEUR \"$NomUtilisateur\" DESACTIVE"
        else
            afficher_erreur "IMPOSSIBLE DE DESACTIVER L'UTILISATEUR"
        fi
        demander_confirmation "Voulez-vous desactiver un autre utilisateur ?" || return
    done
}

#FONCTION POUR SUPPRIME UN COMPTE UTILISATEUR
supprimer_utilisateur_local() {
    while true; do
        afficher_chargement "Recuperation des utilisateurs..."
        local users_list=$(afficher_utilisateurs_locaux)
        local NomUtilisateur
        NomUtilisateur=$(dialog --backtitle "$BACKTITLE" \
            --title "[ SUPPRESSION DE COMPTE UTILISATEUR ]" \
            --cancel-label "Retour" --stdout \
            --inputbox "\nUtilisateurs locaux :\n$users_list\n\nNom de l'utilisateur a supprimer :" 14 60)
        [ $? -ne 0 ] && return
        if [ -z "$NomUtilisateur" ]; then
            afficher_erreur "NOM D'UTILISATEUR NON SPECIFIE"
            continue
        fi
        local existe=$(executer_ssh "cat /etc/passwd | grep '^$NomUtilisateur:'")
        if [ -z "$existe" ]; then
            afficher_erreur "L'UTILISATEUR \"$NomUtilisateur\" N'EXISTE PAS"
            continue
        fi
        demander_confirmation "Supprimer definitivement \"$NomUtilisateur\" ?" || {
            afficher_avertissement "SUPPRESSION ANNULEE"
            return
        }
        afficher_chargement "Suppression du compte..."
        local result=$(executer_ssh "sudo userdel '$NomUtilisateur' 2>&1")
        local verif=$(executer_ssh "cat /etc/passwd | grep '^$NomUtilisateur:'")
        if [ -z "$verif" ]; then
            afficher_succes "UTILISATEUR \"$NomUtilisateur\" SUPPRIME"
        else
            afficher_erreur "IMPOSSIBLE DE SUPPRIMER L'UTILISATEUR"
        fi
        demander_confirmation "Voulez-vous supprimer un autre utilisateur ?" || return
    done
}

#FONCTION POUR AFFICHE LES GROUPES DUN UTILISATEUR
afficher_groupes_utilisateur() {
    while true; do
        afficher_chargement "Recuperation des utilisateurs..."
        local users_list=$(afficher_utilisateurs_locaux)
        local NomUtilisateur
        NomUtilisateur=$(dialog --backtitle "$BACKTITLE" \
            --title "[ GROUPES D'APPARTENANCE D'UN UTILISATEUR ]" \
            --cancel-label "Retour" --stdout \
            --inputbox "\nUtilisateurs locaux :\n$users_list\n\nNom de l'utilisateur :" 14 60)
        [ $? -ne 0 ] && return
        if [ -z "$NomUtilisateur" ]; then
            afficher_erreur "NOM D'UTILISATEUR NON SPECIFIE"
            continue
        fi
        local existe=$(executer_ssh "cat /etc/passwd | grep '^$NomUtilisateur:'")
        if [ -z "$existe" ]; then
            afficher_erreur "L'UTILISATEUR \"$NomUtilisateur\" N'EXISTE PAS"
            continue
        fi
        afficher_chargement "Recuperation des groupes..."
        local groupes=$(executer_ssh "id -Gn '$NomUtilisateur' 2>&1 | sed 's/ / | /g'")
        afficher_texte "GROUPES DE \"$NomUtilisateur\"" "GROUPES : $groupes"
        demander_confirmation "Voulez-vous consulter un autre utilisateur ?" || return
    done
}

#FONCTION POUR AJOUTE UN UTILISATEUR AU GROUPE SUDO
ajouter_utilisateur_groupe_admin() {
    while true; do
        afficher_chargement "Recuperation des utilisateurs..."
        local users_list=$(afficher_utilisateurs_locaux)
        local NomUtilisateur
        NomUtilisateur=$(dialog --backtitle "$BACKTITLE" \
            --title "[ AJOUT AUX ADMINISTRATEURS (SUDO) ]" \
            --cancel-label "Retour" --stdout \
            --inputbox "\nUtilisateurs locaux :\n$users_list\n\nNom de l'utilisateur :" 14 60)
        [ $? -ne 0 ] && return
        if [ -z "$NomUtilisateur" ]; then
            afficher_erreur "NOM D'UTILISATEUR NON SPECIFIE"
            continue
        fi
        local existe=$(executer_ssh "cat /etc/passwd | grep '^$NomUtilisateur:'")
        if [ -z "$existe" ]; then
            afficher_erreur "L'UTILISATEUR \"$NomUtilisateur\" N'EXISTE PAS"
            continue
        fi
        demander_confirmation "Ajouter \"$NomUtilisateur\" au groupe *SUDO* ?" || {
            afficher_avertissement "AJOUT ANNULE"
            return
        }
        afficher_chargement "Ajout au groupe sudo..."
        local result=$(executer_ssh "sudo usermod -aG sudo '$NomUtilisateur' 2>&1")
        local verif=$(executer_ssh "id -nG '$NomUtilisateur' | grep -w 'sudo'")
        if [ -n "$verif" ]; then
            afficher_succes "UTILISATEUR \"$NomUtilisateur\" AJOUTE AU GROUPE *SUDO*"
        else
            afficher_erreur "IMPOSSIBLE D'AJOUTER L'UTILISATEUR AU GROUPE"
        fi
        demander_confirmation "Voulez-vous ajouter un autre utilisateur ?" || return
    done
}

#FONCTION POUR AJOUTE UN UTILISATEUR A UN GROUPE
ajouter_utilisateur_groupe() {
    while true; do
        afficher_chargement "Recuperation des utilisateurs..."
        local users_list=$(afficher_utilisateurs_locaux)
        local NomUtilisateur
        NomUtilisateur=$(dialog --backtitle "$BACKTITLE" \
            --title "[ AJOUT A UN GROUPE ]" \
            --cancel-label "Retour" --stdout \
            --inputbox "\nUtilisateurs locaux :\n$users_list\n\nNom de l'utilisateur :" 14 60)
        [ $? -ne 0 ] && return
        if [ -z "$NomUtilisateur" ]; then
            afficher_erreur "NOM D'UTILISATEUR NON SPECIFIE"
            continue
        fi
        local existe=$(executer_ssh "cat /etc/passwd | grep '^$NomUtilisateur:'")
        if [ -z "$existe" ]; then
            afficher_erreur "L'UTILISATEUR \"$NomUtilisateur\" N'EXISTE PAS"
            continue
        fi
        afficher_chargement "Recuperation des groupes disponibles..."
        local groupes_dispo=$(executer_ssh "
            groupes_classiques=\$(cat /etc/group | grep -E '^(sudo|users|adm|cdrom|plugdev|netdev|audio|video|staff|games|docker|www-data):' | cut -d: -f1)
            groupes_utilisateurs=\$(awk -F: '\$3 >= 1000 {print \$1}' /etc/group)
            echo -e \"\$groupes_classiques\n\$groupes_utilisateurs\" | sort -u | grep -v '^\$' | tr '\n' ' ' | sed 's/ / | /g' | sed 's/ | \$//'
        ")
        local NomGroupe
        NomGroupe=$(dialog --backtitle "$BACKTITLE" \
            --title "[ NOM DU GROUPE ]" \
            --cancel-label "Retour" --stdout \
            --inputbox "\nGroupes disponibles :\n$groupes_dispo\n\nNom du groupe :" 14 60)
        [ $? -ne 0 ] && return
        if [ -z "$NomGroupe" ]; then
            afficher_erreur "NOM DU GROUPE NON SPECIFIE"
            continue
        fi
        local groupe_existe=$(executer_ssh "cat /etc/group | grep '^$NomGroupe:'")
        if [ -z "$groupe_existe" ]; then
            afficher_erreur "LE GROUPE *$NomGroupe* N'EXISTE PAS"
            continue
        fi
        demander_confirmation "Ajouter \"$NomUtilisateur\" au groupe *$NomGroupe* ?" || {
            afficher_avertissement "AJOUT ANNULE"
            return
        }
        afficher_chargement "Ajout au groupe..."
        local result=$(executer_ssh "sudo usermod -aG '$NomGroupe' '$NomUtilisateur' 2>&1")
        local verif=$(executer_ssh "id -nG '$NomUtilisateur' | grep -w '$NomGroupe'")
        if [ -n "$verif" ]; then
            afficher_succes "UTILISATEUR \"$NomUtilisateur\" AJOUTE AU GROUPE *$NomGroupe*"
        else
            afficher_erreur "IMPOSSIBLE D'AJOUTER L'UTILISATEUR AU GROUPE"
        fi
        demander_confirmation "Voulez-vous ajouter un autre utilisateur ?" || return
    done
}
###############################################################
#                           MENUS                             #
###############################################################
#FONCTION POUR AFFICHE LE MENU DES REPERTOIRES
menu_repertoires() {
    while true; do
        local choix
        choix=$(dialog --backtitle "$BACKTITLE" \
            --title "[ REPERTOIRES ]" \
            --cancel-label "Retour" --stdout \
            --menu "\nMachine : $machine_nom\nIP : $machine_ip\n" \
            $HAUTEUR $LARGEUR $MENU_HAUTEUR \
            "1" "Creer un repertoire" \
            "2" "Supprimer un repertoire")
        [ $? -ne 0 ] && return
        case "$choix" in
            "1") creer_repertoire ;;
            "2") supprimer_repertoire ;;
        esac
    done
}

#FONCTION POUR AFFICHE LE MENU LOGICIELS
menu_logiciels() {
    while true; do
        local choix
        choix=$(dialog --backtitle "$BACKTITLE" \
            --title "[ LOGICIELS ]" \
            --cancel-label "Retour" --stdout \
            --menu "\nMachine : $machine_nom\nIP : $machine_ip\n" \
            $HAUTEUR $LARGEUR $MENU_HAUTEUR \
            "1" "Applications installees" \
            "2" "Mises a jour critiques")
        [ $? -ne 0 ] && return
        case "$choix" in
            "1") afficher_applications_installees ;;
            "2") afficher_mises_a_jour_manquantes ;;
        esac
    done
}

#FONCTION POUR AFFICHE LE MENU SERVICES
menu_services() {
    while true; do
        local choixs
        choix=$(dialog --backtitle "$BACKTITLE" \
            --title "[ GESTION DES SERVICES ]" \
            --cancel-label "Retour" --stdout \
            --menu "\nMachine : $machine_nom\nIP : $machine_ip\n" \
            $HAUTEUR $LARGEUR $MENU_HAUTEUR \
            "1" "Lister les services en cours")
        [ $? -ne 0 ] && return
        case "$choix" in
            "1") afficher_services_en_cours ;;
        esac
    done
}

#FONCTION POUR AFFICHE LE MENU RESEAU
menu_reseau() {
    while true; do
        local choix
        choix=$(dialog --backtitle "$BACKTITLE" \
            --title "[ RESEAU ]" \
            --cancel-label "Retour" --stdout \
            --menu "\nMachine : $machine_nom\nIP : $machine_ip\n" \
            $HAUTEUR $LARGEUR $MENU_HAUTEUR \
            "1" "Ports ouverts" \
            "2" "Information reseau" \
            "3" "Activation du pare-feu")
        [ $? -ne 0 ] && return
        case "$choix" in
            "1") afficher_ports_ouverts ;;
            "2") afficher_config_ip ;;
            "3") activer_pare_feu ;;
        esac
    done
}

#FONCTION POUR AFFICHE LE MENU SYSTEME
menu_systeme() {
    while true; do
        local choix
        choix=$(dialog --backtitle "$BACKTITLE" \
            --title "[ SYSTEME ]" \
            --cancel-label "Retour" --stdout \
            --menu "\nMachine : $machine_nom\nIP : $machine_ip\n" \
            $HAUTEUR $LARGEUR $MENU_HAUTEUR \
            "1" "Informations systeme" \
            "2" "Information sur la RAM")
        [ $? -ne 0 ] && return
        case "$choix" in
            "1") afficher_info_systeme ;;
            "2") afficher_utilisation_ram ;;
        esac
    done
}

#FONCTION POUR AFFICHE LE MENU CONTROLES
menu_controles() {
    while true; do
        local choix
        choix=$(dialog --backtitle "$BACKTITLE" \
            --title "[ CONTROLES ]" \
            --cancel-label "Retour" --stdout \
            --menu "\nMachine : $machine_nom\nIP : $machine_ip\n" \
            $HAUTEUR $LARGEUR $MENU_HAUTEUR \
            "1" "Redemarrage" \
            "2" "Executer un script" \
            "3" "Prise de main a distance (CLI)")
        [ $? -ne 0 ] && return
        case "$choix" in
            "1") redemarrer_machine ;;
            "2") executer_script_distant ;;
            "3") ouvrir_console_distante ;;
        esac
    done
}

#FONCTION POUR AFFICHE LE MENU UTILISATEURS
menu_utilisateurs() {
    while true; do
        local choix
        choix=$(dialog --backtitle "$BACKTITLE" \
            --title "[ GESTION DES UTILISATEURS ]" \
            --cancel-label "Retour" --stdout \
            --menu "\nMachine : $machine_nom\nIP : $machine_ip\n" \
            $HAUTEUR $LARGEUR $MENU_HAUTEUR \
            "1" "Creer un compte utilisateur local" \
            "2" "Changer un mot de passe" \
            "3" "Desactiver un compte" \
            "4" "Supprimer un compte" \
            "5" "Verifier l'appartenance a un groupe" \
            "6" "Ajouter aux administrateurs" \
            "7" "Ajouter a un groupe" \
            "8" "Droits et permissions sur fichier")
        [ $? -ne 0 ] && return
        case "$choix" in
            "1") creer_utilisateur_local ;;
            "2") modifier_mot_de_passe_utilisateur ;;
            "3") desactiver_utilisateur_local ;;
            "4") supprimer_utilisateur_local ;;
            "5") afficher_groupes_utilisateur ;;
            "6") ajouter_utilisateur_groupe_admin ;;
            "7") ajouter_utilisateur_groupe ;;
            "8") afficher_permissions_utilisateur ;;
        esac
    done
}

#FONCTION POUR AFFICHE LE MENU GESTION DE LA MACHINE
menu_gestion_machine() {
    while true; do
        local choix
        choix=$(dialog --backtitle "$BACKTITLE" \
            --title "[ GESTION DE LA MACHINE ]" \
            --cancel-label "Retour" --stdout \
            --menu "\nMachine : $machine_nom\nIP : $machine_ip\nUtilisateur : $machine_user\n" \
            $HAUTEUR $LARGEUR $MENU_HAUTEUR \
            "1" "Repertoires" \
            "2" "Logiciels" \
            "3" "Services" \
            "4" "Reseau" \
            "5" "Systeme" \
            "6" "Controles")
        [ $? -ne 0 ] && return
        case "$choix" in
            "1") menu_repertoires ;;
            "2") menu_logiciels ;;
            "3") menu_services ;;
            "4") menu_reseau ;;
            "5") menu_systeme ;;
            "6") menu_controles ;;
        esac
    done
}

#FONCTION POUR AFFICHE LE MENU CLIENT
menu_client() {
    while true; do
        local choix
        choix=$(dialog --backtitle "$BACKTITLE" \
            --title "[ MENU PRINCIPAL ]" \
            --cancel-label "Retour" --stdout \
            --menu "\nMachine : $machine_nom\nIP : $machine_ip\nUtilisateur : $machine_user\n" \
            $HAUTEUR $LARGEUR $MENU_HAUTEUR \
            "1" "GESTION DE LA MACHINE" \
            "2" "GESTION DES UTILISATEURS")
        [ $? -ne 0 ] && return
        case "$choix" in
            "1") menu_gestion_machine ;;
            "2") menu_utilisateurs ;;
        esac
    done
}

#FONCTION POUR AFFICHE LA LISTE DES MACHINES DISPONIBLES
afficher_liste_machines() {
    while true; do
        local options=()
        local i=1
        for ip in "${liste_ip[@]}"; do
            local nom="${noms_machines[$ip]}"
            options+=("$i" "$ip - $nom")
            ((i++))
        done
        local choix
        choix=$(dialog --backtitle "$BACKTITLE" \
            --title "[ MACHINES DISPONIBLES ]" \
            --cancel-label "Retour" \
            --extra-button --extra-label "Rescanner" --stdout \
            --menu "\nSelectionnez une machine :\n" \
            $HAUTEUR $LARGEUR $MENU_HAUTEUR \
            "${options[@]}")
        local ret=$?
        case $ret in
            0)
                if [[ "$choix" =~ ^[0-9]+$ ]] && [ "$choix" -ge 1 ] && [ "$choix" -le ${#liste_ip[@]} ]; then
                    local index=$((choix - 1))
                    machine_ip="${liste_ip[$index]}"
                    machine_nom="${noms_machines[$machine_ip]}"
                    machine_user="$utilisateur_linux"
                    menu_client
                fi
                ;;
            3)
                scanner_reseau
                ;;
            *)
                return
                ;;
        esac
    done
}

#FONCTION POUR AFFICHE LE MENU PRINCIPAL
menu_principal() {
    while true; do
        local choix
        choix=$(dialog --backtitle "$BACKTITLE" \
            --title "[ SCRIPT PRINCIPAL ]" \
            --cancel-label "Quitter" --stdout \
            --menu "\n\
 ██╗    ██╗██╗██╗     ██████╗      ██████╗ ██████╗ ██████╗ ███████╗\n\
 ██║    ██║██║██║     ██╔══██╗    ██╔════╝██╔═══██╗██╔══██╗██╔════╝\n\
 ██║ █╗ ██║██║██║     ██║  ██║    ██║     ██║   ██║██║  ██║█████╗  \n\
 ██║███╗██║██║██║     ██║  ██║    ██║     ██║   ██║██║  ██║██╔══╝  \n\
 ╚███╔███╔╝██║███████╗██████╔╝    ╚██████╗╚██████╔╝██████╔╝███████╗\n\
  ╚══╝╚══╝ ╚═╝╚══════╝╚═════╝      ╚═════╝ ╚═════╝ ╚═════╝ ╚══════╝\n\
                ███████╗ ██████╗██╗  ██╗ ██████╗  ██████╗ ██╗     \n\
                ██╔════╝██╔════╝██║  ██║██╔═══██╗██╔═══██╗██║     \n\
                ███████╗██║     ███████║██║   ██║██║   ██║██║     \n\
                ╚════██║██║     ██╔══██║██║   ██║██║   ██║██║     \n\
                ███████║╚██████╗██║  ██║╚██████╔╝╚██████╔╝███████╗\n\
                ╚══════╝ ╚═════╝╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚══════╝\n\n\
  Date   : $(date '+%d/%m/%Y')                                   ┌────────────────┐\n\
  Heure  : $(date '+%H:%M:%S')                                     │ FRED|ANIS|EROS │\n\
  Reseau : ${ip_reseau}0/24                               └────────────────┘\n" \
            28 80 $MENU_HAUTEUR \
            "1" "SCANNER LE RESEAU")
        local ret=$?
        if [ $ret -ne 0 ]; then
            demander_confirmation "Voulez-vous quitter ?" && {
                clear
                exit 0
            }
            continue
        fi
        case "$choix" in
            "1")
                if scanner_reseau; then
                    afficher_liste_machines
                else
                    afficher_erreur "Aucune machine Linux accessible\n\nVerifiez :\n- Machines allumees\n- SSH actif\n- Cles SSH configurees"
                fi
                ;;
        esac
    done
}

#FONCTION POUR SUPPRIMER LES FICHIERS TEMPORAIRES
nettoyer() {
    rm -f "$fichier_temp" "$fichier_noms" "$fichier_result" "$DIALOGRC" 
    clear
}
trap nettoyer EXIT SIGINT SIGTERM
###############################################################
#                DEMARRAGE DU SCRIPT                          #
###############################################################
if ! command -v dialog &>/dev/null; then
    echo ""
    echo "ERREUR :dialog n'est pas installe"
    echo ""
    echo "  sudo apt install dialog"
    echo ""
    exit 1
fi

clear
menu_principal