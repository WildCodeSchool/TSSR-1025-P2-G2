#!/bin/bash
##################################################################
#                          SCRIPT_PRINCIPAL                      #
#                      SCRIPT_BY ANIS FRED EROS                  #
#                          WILD_CODE_SCHOOL                      #
##################################################################

###############################################################
#                CONFIGURATION ET VARIABLES                   #
###############################################################

port_ssh="22222"
script_dir="$(cd "$(dirname "$0")" && pwd)"
ip_reseau="172.16.20."
delai_ping=1
fichier_temp="/tmp/machines_actives_$$.txt"
fichier_noms="/tmp/noms_machines_$$.txt"
script_linux="$script_dir/scriptbash.sh"
script_windows="$script_dir/scriptpowershell.ps1"
utilisateur_linux="wilder"
utilisateurs_windows=("wilder1" "wilder" "admin" "administrateur" "administrator" "user")
date_actuelle=$(date "+%Y-%m-%d")
heure_actuelle=$(date "+%H-%M-%S")
local_ip=""

log_dir="/var/log"
log_file="$log_dir/log_evt.log"
info_dir="$script_dir/info"

###############################################################
#                      TABLEAU                                #
###############################################################
declare -a liste_ip
declare -A noms_machines
declare -A type_os
declare -A utilisateur_windows 

###############################################################
#            FONCTIONS DE JOURNALISATION                      #
###############################################################

#FONCTION QUI PREPARE LE FICHIER DE LOG ET LE DOSSIER INFO
initialiser_journal() {
    if [ -f "$log_file" ]; then
        if echo "" >> "$log_file" 2>/dev/null; then
            :
        else
            echo "LE FICHIER $log_file EXISTE MAIS VOUS NE POUVEZ PAS ECRIRE DEDANS"
            echo "TENTATIVE DE CORRECTION DES DROITS"
            sudo chmod 666 "$log_file" 2>/dev/null
            if [ $? -ne 0 ]; then
                echo "IMPOSSIBLE DE MODIFIER LES PERMISSIONS LE LOG SERA DANS LE SCRIPT"
                log_dir="$script_dir"
                log_file="$script_dir/log_evt.log"
            fi
        fi
    else
        echo "CREATION DU FICHIER DE LOG DANS VAR LOG"
        echo "MOT DE PASSE SUDO REQUIS"
        sudo touch "$log_file" 2>/dev/null && sudo chmod 666 "$log_file" 2>/dev/null
        if [ $? -ne 0 ]; then
            echo "IMPOSSIBLE DE CREER LE FICHIER DANS VAR LOG LE LOG SERA DANS LE SCRIPT"
            log_dir="$script_dir"
            log_file="$script_dir/log_evt.log"
            touch "$log_file" 2>/dev/null
        else
            echo "FICHIER DE LOG CREE AVEC SUCCES"
        fi
    fi
    if [ ! -d "$info_dir" ]; then
        mkdir -p "$info_dir" 2>/dev/null
    fi
}

#FONCTION QUI ENREGISTRE UN EVENEMENT DANS LE FICHIER DE LOG
sauvegarder_log() {
    local evenement="$1"
    local date_evt
    local heure_evt
    local utilisateur_evt
    date_evt=$(date "+%Y%m%d")
    heure_evt=$(date "+%H%M%S")
    utilisateur_evt="${USER:-inconnu}"
    echo "${date_evt}_${heure_evt}_${utilisateur_evt}_${evenement}" >> "$log_file" 2>/dev/null
}

#FONCTION QUI RECUPERE LES FICHIERS INFO ET LOG SUR UNE MACHINE LINUX
recuperer_info_linux() {
    local ip="$1"
    local utilisateur="$2"
    if ssh -p $port_ssh -o batchmode=yes "${utilisateur}@${ip}" "test -f /tmp/log_evt.log" 2>/dev/null; then
        scp -P $port_ssh -q -o stricthostkeychecking=no "${utilisateur}@${ip}:/tmp/log_evt.log" "/tmp/log_client_$$.log" 2>/dev/null
        if [ -f "/tmp/log_client_$$.log" ]; then
            cat "/tmp/log_client_$$.log" >> "$log_file" 2>/dev/null
            rm -f "/tmp/log_client_$$.log"
        fi
        ssh -p $port_ssh -o batchmode=yes "${utilisateur}@${ip}" "rm -f /tmp/log_evt.log" 2>/dev/null
    fi
    if ssh -p $port_ssh -o batchmode=yes "${utilisateur}@${ip}" "test -d /tmp/info" 2>/dev/null; then
        scp -P $port_ssh -q -o stricthostkeychecking=no "${utilisateur}@${ip}:/tmp/info/*" "$info_dir/" 2>/dev/null
        ssh -p $port_ssh -o batchmode=yes "${utilisateur}@${ip}" "rm -rf /tmp/info" 2>/dev/null
    fi
}

#FONCTION QUI RECUPERE LES FICHIERS INFO ET LOG SUR UNE MACHINE WINDOWS
recuperer_info_windows() {
    local ip="$1"
    local utilisateur="$2"
    if ssh -p $port_ssh -o batchmode=yes "${utilisateur}@${ip}" "cmd /c if exist %userprofile%\\Documents\\log_evt.log echo OK" 2>/dev/null | grep -q "OK"; then
        scp -P $port_ssh -q -o stricthostkeychecking=no "${utilisateur}@${ip}:Documents/log_evt.log" "/tmp/log_client_$$.log" 2>/dev/null
        if [ -f "/tmp/log_client_$$.log" ]; then
            cat "/tmp/log_client_$$.log" >> "$log_file" 2>/dev/null
            rm -f "/tmp/log_client_$$.log"
        fi
        ssh -p $port_ssh -o batchmode=yes "${utilisateur}@${ip}" "cmd /c del /F /Q %userprofile%\\Documents\\log_evt.log" 2>/dev/null
    fi
    if ssh -p $port_ssh -o batchmode=yes "${utilisateur}@${ip}" "cmd /c if exist %userprofile%\\Documents\\info echo OK" 2>/dev/null | grep -q "OK"; then
        scp -P $port_ssh -q -r -o stricthostkeychecking=no "${utilisateur}@${ip}:Documents/info/*" "$info_dir/" 2>/dev/null
        ssh -p $port_ssh -o batchmode=yes "${utilisateur}@${ip}" "cmd /c rmdir /S /Q %userprofile%\\Documents\\info" 2>/dev/null
    fi
}

###################################################################################
#        FONCTIONS POUR DETECTER  UTILISATEURS WINDOWS/SYSTEME/NOM DE MACHINE     #
###################################################################################

#FONCTION QUI CHERCHE QUEL UTILISATEUR WINDOWS PEUT SE CONNECTER EN SSH
trouver_utilisateur_windows() {
    local ip="$1"
    local utilisateur
    for utilisateur in "${utilisateurs_windows[@]}"; do
        if timeout 3 ssh -p $port_ssh -o connecttimeout=2 -o stricthostkeychecking=no -o batchmode=yes "${utilisateur}@${ip}" "cmd /c echo Windows" 2>/dev/null | grep -qi "windows"; then
            echo "$utilisateur"
            return 0
        fi
    done
    echo ""
    return 1
}

#FONCTION QUI DETERMINE LE SYSTEME DEXPLOITATION DE LA MACHINE
detecter_systeme() {
    local ip="$1"
    local utilisateur_win
    if timeout 2 ssh -p $port_ssh -o connecttimeout=2 -o stricthostkeychecking=no -o batchmode=yes "${utilisateur_linux}@${ip}" "uname" 2>/dev/null | grep -qi linux; then
        type_os["$ip"]="linux"
        return 0
    fi
    utilisateur_win=$(trouver_utilisateur_windows "$ip")
    if [ -n "$utilisateur_win" ]; then
        type_os["$ip"]="windows"
        utilisateur_windows["$ip"]="$utilisateur_win"
        return 0
    fi
    type_os["$ip"]="inconnu"
    return 1
}

#FONCTION QUI RECUPERE LE NOM DE LA MACHINE A DISTANCE
recuperer_nom_machine() {
    local ip="$1"
    local nom=""
    local utilisateur=""
    if [ -z "${type_os[$ip]}" ]; then
        detecter_systeme "$ip"
    fi
    if [ "${type_os[$ip]}" = "windows" ]; then
        utilisateur="${utilisateur_windows[$ip]}"
        if [ -z "$utilisateur" ]; then
            utilisateur=$(trouver_utilisateur_windows "$ip")
            utilisateur_windows["$ip"]="$utilisateur"
        fi
    else
        utilisateur="$utilisateur_linux"
    fi
    nom=$(ssh -p $port_ssh -o connecttimeout=3 -o batchmode=yes -o loglevel=quiet "${utilisateur}@${ip}" "hostname" 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$nom" ]; then
        noms_machines["$ip"]=$(echo "$nom" | tr -d '\r')
    else
        noms_machines["$ip"]="?"
    fi
}

##################################################################################
#                     FONCTION POUR SCANNER LE RESEAU                            #
##################################################################################

#FONCTION POUR SCANNER LE RESEAU
scanner_reseau() {
    liste_ip=()
    noms_machines=()
    type_os=()
    > "$fichier_temp"
    > "$fichier_noms"
    for i in {5..30}; do
        local ip="${ip_reseau}${i}"
        (
            ping -c 1 -W "$delai_ping" "$ip" &>/dev/null
            if [ $? -eq 0 ]; then
                echo "$ip" >> "$fichier_temp"
            fi
        ) &
    done
    wait
    if [ -s "$fichier_temp" ]; then
        mapfile -t liste_ip < "$fichier_temp"
        if [ -z "$local_ip" ]; then
            local_ip=$(hostname -I 2>/dev/null | tr ' ' '\n' | grep "^$ip_reseau" | head -n1)
        fi
        if [ -n "$local_ip" ]; then
            local liste_filtree=()
            local ip
            for ip in "${liste_ip[@]}"; do
                if [ "$ip" != "$local_ip" ]; then
                    liste_filtree+=("$ip")
                fi
            done
            liste_ip=("${liste_filtree[@]}")
        fi
        if [ ${#liste_ip[@]} -eq 0 ]; then
            rm -f "$fichier_temp" "$fichier_noms"
            return 0
        fi
        local ip
        for ip in "${liste_ip[@]}"; do
            (
                detecter_systeme "$ip"
                recuperer_nom_machine "$ip"
                echo "$ip:${type_os[$ip]}:${noms_machines[$ip]}:${utilisateur_windows[$ip]}" >> "$fichier_noms"
            ) &
        done
        wait
        while IFS=: read -r ip systeme nom utilisateur; do
            type_os["$ip"]="$systeme"
            noms_machines["$ip"]="$nom"
            if [ -n "$utilisateur" ]; then
                utilisateur_windows["$ip"]="$utilisateur"
            fi
        done < "$fichier_noms"
    fi
    rm -f "$fichier_temp" "$fichier_noms"
}

##################################################################################
#                   FONCTIONS DE CONNEXION AUX MACHINES                          #
##################################################################################

#FONCTION POUR SE CONNECTER A UNE MACHINE LINUX
connexion_machine_linux() {
    local ip="$1"
    local nom_machine="${noms_machines[$ip]}"
    local utilisateur_local="${USER:-inconnu}"
    if [ ! -f "$script_linux" ]; then
        echo "ERREUR SCRIPT LINUX INTROUVABLE $script_linux"
        exit 1
    fi
    echo "CONNEXION A $ip LINUX" >/dev/null
    sauvegarder_log "Action_ConnexionSSH_${nom_machine}_${ip}"
    scp -P $port_ssh -q -o stricthostkeychecking=no "$script_linux" "${utilisateur_linux}@${ip}:/tmp/scriptbash.sh"
    if [ $? -ne 0 ]; then
        echo "ERREUR ECHEC DE COPIE DU SCRIPT LINUX"
        exit 1
    fi
    ssh -p $port_ssh -tt "${utilisateur_linux}@${ip}" "sed -i 's/\r$//' /tmp/scriptbash.sh && chmod +x /tmp/scriptbash.sh && /tmp/scriptbash.sh '$utilisateur_local'; rm -f /tmp/scriptbash.sh" 2>/dev/null 2>/dev/null
    recuperer_info_linux "$ip" "$utilisateur_linux"
}

#FONCTION POUR SE CONNECTER A UNE MACHINE WINDOWS
connexion_machine_windows() {
    local ip="$1"
    local utilisateur="${utilisateur_windows[$ip]}"
    local nom_machine="${noms_machines[$ip]}"
    local utilisateur_local="${USER:-inconnu}"
    if [ -z "$utilisateur" ]; then
        echo "RECHERCHE DE L'UTILISATEUR WINDOWS POUR $ip"
        utilisateur=$(trouver_utilisateur_windows "$ip")
        if [ -z "$utilisateur" ]; then
            echo "ERREUR AUCUN UTILISATEUR WINDOWS NE FONCTIONNE EN SSH SUR $ip"
            exit 1
        fi
        utilisateur_windows["$ip"]="$utilisateur"
    fi
    if [ ! -f "$script_windows" ]; then
        echo "ERREUR SCRIPT WINDOWS INTROUVABLE $script_windows"
        exit 1
    fi
    echo "CONNEXION A $ip WINDOWS UTILISATEUR $utilisateur" >/dev/null
    sauvegarder_log "Action_ConnexionSSH_${nom_machine}_${ip}"
    ssh -p $port_ssh -o batchmode=yes "${utilisateur}@${ip}" "cmd /c if exist %userprofile%\\Documents\\scriptpowershell.ps1 del /F /Q %userprofile%\\Documents\\scriptpowershell.ps1" 2>/dev/null
    scp -P $port_ssh -q -o stricthostkeychecking=no "$script_windows" "${utilisateur}@${ip}:Documents/scriptpowershell.ps1"
    if [ $? -ne 0 ]; then
        echo "ERREUR ECHEC DU TRANSFERT DU SCRIPT WINDOWS"
        echo "VERIFIEZ LES DROITS DE L'UTILISATEUR WINDOWS"
        exit 1
    fi
    ssh -p $port_ssh -tt "${utilisateur}@${ip}" "powershell -executionpolicy bypass -file %userprofile%\\Documents\\scriptpowershell.ps1 -UtilisateurLocal '$utilisateur_local' && del /F /Q %userprofile%\\Documents\\scriptpowershell.ps1" 2>/dev/null
    recuperer_info_windows "$ip" "$utilisateur"
}

#FONCTION POUR SE CONNECTER A UNE MACHINE
connexion_machine() {
    local ip="$1"
    local systeme="${type_os[$ip]}"
    if [ -z "$systeme" ]; then
        detecter_systeme "$ip"
        systeme="${type_os[$ip]}"
    fi
    if [ "$systeme" = "linux" ]; then
        connexion_machine_linux "$ip"
        return 0
    elif [ "$systeme" = "windows" ]; then
        connexion_machine_windows "$ip"
        return 0
    else
        return 1
    fi
}

##################################################################################
#                            MENU PRINCIPAL                                      #
##################################################################################

BLEU='\e[34m'
BLANC='\e[97m'
ROUGE='\e[31m'
ROSE='\e[95m'
RESET='\e[0m'

#FONCTION QUI AFFICHE LE MENU PRINCIPAL
menu_principal() {
    while true; do
        clear
        printf "%b\n" "${BLEU}####################${BLANC}##############${ROUGE}####################${RESET}"
        printf "%b\n" "${BLEU}#${RESET}                  ${BLANC}SCRIPT_PRINCIPAL${RESET}                  ${ROUGE}#${RESET}"
        printf "%b\n" "${BLEU}#${RESET}                ${BLANC}$date_actuelle|$heure_actuelle${RESET}                 ${ROUGE}#${RESET}"
        printf "%b\n" "${BLEU}#${RESET}                  ${BLANC}WILD_CODE_SCHOOL${RESET}                  ${ROUGE}#${RESET}"
        printf "%b\n" "${BLEU}#${RESET}              ${BLANC}SCRIPT_BY:ANIS|FRED|EROS${RESET}              ${ROUGE}#${RESET}"
        printf "%b\n" "${BLEU}####################${BLANC}##############${ROUGE}####################${RESET}"
        echo ""
        echo "1.SE CONNECTER A UNE MACHINE"
        echo "Q.QUITTER"
        echo "___________________________"
        echo ""
        echo -n "CHOISISSEZ UNE OPTION [1 OU Q]: "
        tput sc
        echo ""
        echo ""
        echo ""
        echo ""
        echo -e "${ROSE}\$\$\\      \$\$\\ \$\$\$\$\$\$\\ \$\$\\       \$\$\$\$\$\$\$\\  \$\$\$\$\$\$\$\$\\ \$\$\$\$\$\$\$\\  ${RESET}"
        echo -e "${ROSE}\$\$ | \$\\  \$\$ |\\_\$\$  _|\$\$ |      \$\$  __\$\$\\ \$\$  _____|\$\$  __\$\$\\ ${RESET}"
        echo -e "${ROSE}\$\$ |\$\$\$\\ \$\$ |  \$\$ |  \$\$ |      \$\$ |  \$\$ |\$\$ |      \$\$ |  \$\$ |${RESET}"
        echo -e "${ROSE}\$\$ \$\$ \$\$\\\$\$ |  \$\$ |  \$\$ |      \$\$ |  \$\$ |\$\$\$\$\$\\    \$\$\$\$\$\$\$  |${RESET}"
        echo -e "${ROSE}\$\$\$\$  _\$\$\$\$ |  \$\$ |  \$\$ |      \$\$ |  \$\$ |\$\$  __|   \$\$  __\$\$< ${RESET}"
        echo -e "${ROSE}\$\$\$  / \\\$\$\$ |  \$\$ |  \$\$ |      \$\$ |  \$\$ |\$\$ |      \$\$ |  \$\$ |${RESET}"
        echo -e "${ROSE}\$\$  /   \\\$\$ |\$\$\$\$\$\$\\ \$\$\$\$\$\$\$\$\\ \$\$\$\$\$\$\$  |\$\$\$\$\$\$\$\$\\ \$\$ |  \$\$ |${RESET}"
        echo -e "${ROSE}\\__/     \\__|\\______|\\________|\\_______/ \\________|\\__|  \\__|${RESET}"
        echo -e "${ROSE}              W I L D   C O D E   S C H O O L${RESET}"
        tput rc
        read choix
        case "$choix" in
            1)
                sauvegarder_log "Navigation_MenuConnexion"
                echo ""
                echo "SCAN DU RESEAU EN COURS..."
                scanner_reseau 2>/dev/null
                if [ ${#liste_ip[@]} -gt 0 ]; then
                    while true; do
                        clear
                        printf "%b\n" "${BLEU}####################${BLANC}##############${ROUGE}####################${RESET}"
                        printf "%b\n" "${BLEU}#${RESET}                  ${BLANC}SCRIPT_PRINCIPAL${RESET}                  ${ROUGE}#${RESET}"
                        printf "%b\n" "${BLEU}#${RESET}                ${BLANC}$date_actuelle|$heure_actuelle${RESET}                 ${ROUGE}#${RESET}"
                        printf "%b\n" "${BLEU}#${RESET}                  ${BLANC}WILD_CODE_SCHOOL${RESET}                  ${ROUGE}#${RESET}"
                        printf "%b\n" "${BLEU}#${RESET}              ${BLANC}SCRIPT_BY:ANIS|FRED|EROS${RESET}              ${ROUGE}#${RESET}"
                        printf "%b\n" "${BLEU}####################${BLANC}##############${ROUGE}####################${RESET}"
                        echo ""
                        echo "MACHINES DISPONIBLES :"
                        echo ""
                        local i
                        for i in "${!liste_ip[@]}"; do
                            ip="${liste_ip[$i]}"
                            nom="${noms_machines[$ip]}"
                            echo -e "  $((i+1)).\t$ip\t$nom"
                        done
                        echo "  Q.QUITTER"
                        echo ""
                        local max="${#liste_ip[@]}"
                        local plage
                        if [ "$max" -eq 1 ]; then
                            plage="1"
                        else
                            plage="1-$max"
                        fi
                        echo -n "CHOISISSEZ UNE OPTION [$plage OU Q]: "
                        tput sc
                        echo ""
                        echo ""
                        echo ""
                        echo -e "${ROSE}\$\$\\      \$\$\\ \$\$\$\$\$\$\\ \$\$\\       \$\$\$\$\$\$\$\\  \$\$\$\$\$\$\$\$\\ \$\$\$\$\$\$\$\\  ${RESET}"
                        echo -e "${ROSE}\$\$ | \$\\  \$\$ |\\_\$\$  _|\$\$ |      \$\$  __\$\$\\ \$\$  _____|\$\$  __\$\$\\ ${RESET}"
                        echo -e "${ROSE}\$\$ |\$\$\$\\ \$\$ |  \$\$ |  \$\$ |      \$\$ |  \$\$ |\$\$ |      \$\$ |  \$\$ |${RESET}"
                        echo -e "${ROSE}\$\$ \$\$ \$\$\\\$\$ |  \$\$ |  \$\$ |      \$\$ |  \$\$ |\$\$\$\$\$\\    \$\$\$\$\$\$\$  |${RESET}"
                        echo -e "${ROSE}\$\$\$\$  _\$\$\$\$ |  \$\$ |  \$\$ |      \$\$ |  \$\$ |\$\$  __|   \$\$  __\$\$< ${RESET}"
                        echo -e "${ROSE}\$\$\$  / \\\$\$\$ |  \$\$ |  \$\$ |      \$\$ |  \$\$ |\$\$ |      \$\$ |  \$\$ |${RESET}"
                        echo -e "${ROSE}\$\$  /   \\\$\$ |\$\$\$\$\$\$\\ \$\$\$\$\$\$\$\$\\ \$\$\$\$\$\$\$  |\$\$\$\$\$\$\$\$\\ \$\$ |  \$\$ |${RESET}"
                        echo -e "${ROSE}\\__/     \\__|\\______|\\________|\\_______/ \\________|\\__|  \\__|${RESET}"
                        echo -e "${ROSE}              W I L D   C O D E   S C H O O L${RESET}"
                        tput rc
                        read selection
                        if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le ${#liste_ip[@]} ]; then
                            ip_cible="${liste_ip[$((selection-1))]}"
                            if connexion_machine "$ip_cible"; then
                                break
                            fi
                        elif [ "$selection" = "Q" ] || [ "$selection" = "q" ]; then
                            sauvegarder_log "Navigation_Retour"
                            break
                        else
                            echo ""
                            echo "CHOIX INVALIDE"
                            sleep 1
                        fi
                    done
                else
                    echo ""
                    echo "AUCUNE MACHINE TROUVEE SUR LE RESEAU"
                    echo "RETOUR AU MENU"
                    sleep 1
                fi
                ;;
            Q|q)
                sauvegarder_log "EndScript"
                echo ""
                echo "A BIENTOT WILDER!"
                exit 0
                ;;
            *)
                echo ""
                echo "CHOIX INVALIDE"
                sleep 1
                ;;
        esac
    done
}

##################################################################################
#                         DEMARRAGE DU SCRIPT PRINCIPAL                          #
##################################################################################

initialiser_journal
sauvegarder_log "StartScript"
if [ ! -f "$script_linux" ]; then
    echo "ATTENTION SCRIPT LINUX INTROUVABLE $script_linux"
fi
if [ ! -f "$script_windows" ]; then
    echo "ATTENTION SCRIPT WINDOWS INTROUVABLE $script_windows"
fi
menu_principal