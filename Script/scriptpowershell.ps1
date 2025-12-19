##################################################################
#                        SCRIPT_WINDOWS                          #
#                  Script_By: ANIS|FRED|EROS                     #
#                      WILD_CODE_SCHOOL                          #   
#                        06/12/2025                              #
##################################################################

###############################################################
#           CONFIGURATION DE LA JOURNALISATION                #
###############################################################

param(
    [string]$UtilisateurLocal = $env:USERNAME
)

$log_dir = "$env:USERPROFILE\Documents"
$log_file = "$log_dir\log_evt.log"
$info_dir = "$log_dir\info"
$nom_machine = $env:COMPUTERNAME
$utilisateur_distant = $env:USERNAME
$connexion_date = Get-Date -Format "yyyyMMdd_HHmmss"
$script:MOT_DE_PASSE_ADMIN = $null
$script:CREDENTIAL_ADMIN = $null

###############################################################
#           FONCTIONS DE JOURNALISATION                       #
###############################################################

#FONCTION POUR INITIALISER LE JOURNAL
function InitialiserJournal {
    if (-not (Test-Path $log_file)) {
        New-Item -Path $log_file -ItemType File -Force | Out-Null
    }
    if (-not (Test-Path $info_dir)) {
        New-Item -Path $info_dir -ItemType Directory -Force | Out-Null
    }
}

#FONCTION POUR SAUVEGARDER UN EVENEMENT DANS LE LOG
function SauvegarderLog {
    param([string]$Evenement)
    $date_evt = Get-Date -Format "yyyyMMdd"
    $heure_evt = Get-Date -Format "HHmmss"
    $ligne = "${date_evt}_${heure_evt}_${UtilisateurLocal}_${utilisateur_distant}_${nom_machine}_${Evenement}"
    Add-Content -Path $log_file -Value $ligne -ErrorAction SilentlyContinue
}

#FONCTION POUR SAUVEGARDER DES INFORMATIONS DANS UN FICHIER
function SauvegarderInfo {
    param([string]$Contenu)
    $fichier_info = "$info_dir\info_${nom_machine}_${utilisateur_distant}_${connexion_date}.txt"
    if (-not (Test-Path $info_dir)) {
        New-Item -Path $info_dir -ItemType Directory -Force | Out-Null
    }
    Add-Content -Path $fichier_info -Value $Contenu -ErrorAction SilentlyContinue
}

###############################################################
#                 MOT DE PASSE ADMINISTRATEUR                 #
###############################################################

#FONCTION POUR VERIFIER LE MOT DE PASSE ADMINISTRATEUR
function VerifierMotDePasseAdmin {
    param([string]$Action)
    Write-Host ""
    Write-Host "=== ACTION SENSIBLE : $Action ==="
    Write-Host ""
    $securePassword = Read-Host "MOT DE PASSE ADMINISTRATEUR" -AsSecureString
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
    $mdp = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
    try {
        Add-Type -AssemblyName System.DirectoryServices.AccountManagement
        $contextType = [System.DirectoryServices.AccountManagement.ContextType]::Machine
        $principalContext = New-Object System.DirectoryServices.AccountManagement.PrincipalContext($contextType)
        $validationResult = $principalContext.ValidateCredentials($env:USERNAME, $mdp)
        if ($validationResult) {
            $script:MOT_DE_PASSE_ADMIN = $mdp
            $script:CREDENTIAL_ADMIN = New-Object System.Management.Automation.PSCredential($env:USERNAME, $securePassword)
            return $true
        } else {
            Write-Host ""
            Write-Host "[ERREUR] MOT DE PASSE INCORRECT" -ForegroundColor Red
            Write-Host ""
            Read-Host "APPUYEZ SUR [ENTREE] POUR CONTINUER"
            return $false
        }
    } catch {
        Write-Host ""
        Write-Host "[ERREUR] MOT DE PASSE INCORRECT" -ForegroundColor Red
        Write-Host ""
        Read-Host "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        return $false
    }
}

###############################################################
#                       FONCTION ENTETE                       #
###############################################################

#FONCTION POUR AFFICHER LENTETE
function AfficherEntete {
    Clear-Host
    $NomMachine = $env:COMPUTERNAME
    $AllIPs = [System.Net.Dns]::GetHostAddresses($env:COMPUTERNAME) | Where-Object { $_.AddressFamily -eq "InterNetwork" }
    $AdresseIP = ($AllIPs | Where-Object { $_.IPAddressToString -like "172.16.20.*" } | Select-Object -First 1).IPAddressToString
    if (-not $AdresseIP) {
        $AdresseIP = ($AllIPs | Where-Object { $_.IPAddressToString -notlike "127.*" } | Select-Object -First 1).IPAddressToString
    }
    if (-not $AdresseIP) {
        $AdresseIP = "NON DISPONIBLE"
    }
    Write-Host "##################" -NoNewline -ForegroundColor DarkBlue
    Write-Host "##################" -NoNewline -ForegroundColor White
    Write-Host "##################" -ForegroundColor DarkRed
    Write-Host "#                    " -NoNewline -ForegroundColor DarkBlue
    Write-Host "  $NomMachine  " -NoNewline -ForegroundColor White
    Write-Host "                    #" -ForegroundColor DarkRed
    Write-Host "#                  " -NoNewline -ForegroundColor DarkBlue
    Write-Host "  $AdresseIP  " -NoNewline -ForegroundColor White
    Write-Host "                  #" -ForegroundColor DarkRed
    Write-Host "##################" -NoNewline -ForegroundColor DarkBlue
    Write-Host "##################" -NoNewline -ForegroundColor White
    Write-Host "##################" -ForegroundColor DarkRed
    Write-Host ""
}

###############################################################
#              FONCTION AFFICHER UTILISATEURS                 #
###############################################################

#FONCTION POUR AFFICHER LES UTILISATEURS LOCAUX
function AfficherUtilisateursLocaux {
    Write-Host "  UTILISATEURS LOCAUX"
    Write-Host ""
    Get-LocalUser | Format-Table Name, Enabled, LastLogon -AutoSize
    Write-Host ""
}

###############################################################
#                    FONCTIONS REPERTOIRES                    #
###############################################################

#FONCTION POUR CREER UN REPERTOIRE
function CreerRepertoire {
    AfficherEntete
    Write-Host "CREATION DE REPERTOIRE"
    Write-Host ""
    $Chemin = Read-Host "CHEMIN COMPLET DU REPERTOIRE A CREER (Q POUR QUITTER)"
    if ($Chemin -eq "q" -or $Chemin -eq "Q") {
        SauvegarderLog "Navigation_Retour"
        MenuRepertoires
        return
    }
    if ([string]::IsNullOrEmpty($Chemin)) {
        Write-Host "CHEMIN NON SPECIFIE"
        Read-Host "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        CreerRepertoire
        return
    }
    if (Test-Path $Chemin) {
        Write-Host "LE REPERTOIRE EXISTE DEJA" -ForegroundColor Red
        Read-Host "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        CreerRepertoire
        return
    }
    $Confirm = Read-Host "CONFIRMER LA CREATION DE *$Chemin* ? [O/N]"
    if ($Confirm -ne "O" -and $Confirm -ne "o") {
        Write-Host "CREATION ANNULEE"
        Read-Host "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        MenuRepertoires
        return
    }
    try {
        New-Item -ItemType Directory -Path $Chemin -Force | Out-Null
        Write-Host "REPERTOIRE CREE AVEC SUCCES" -ForegroundColor Green
        SauvegarderLog "Action_CreationRepertoire_$Chemin"
    } catch {
        Write-Host "IMPOSSIBLE DE CREER LE REPERTOIRE" -ForegroundColor Red
    }
    Write-Host ""
    $Continuer = Read-Host "VOULEZ-VOUS CREER UN AUTRE REPERTOIRE ? [O/N]"
    if ($Continuer -eq "O" -or $Continuer -eq "o") {
        CreerRepertoire
    } else {
        MenuRepertoires
    }
}

#FONCTION POUR SUPPRIMER UN REPERTOIRE
function SupprimerRepertoire {
    AfficherEntete
    Write-Host "  SUPPRESSION DE REPERTOIRE"
    Write-Host ""
    $Chemin = Read-Host "CHEMIN COMPLET DU REPERTOIRE A SUPPRIMER (Q POUR QUITTER)"
    if ($Chemin -eq "q" -or $Chemin -eq "Q") {
        SauvegarderLog "Navigation_Retour"
        MenuRepertoires
        return
    }
    if ([string]::IsNullOrEmpty($Chemin)) {
        Write-Host "CHEMIN NON SPECIFIE"
        Read-Host "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        SupprimerRepertoire
        return
    }
    if (-not (Test-Path $Chemin)) {
        Write-Host "LE REPERTOIRE N'EXISTE PAS" -ForegroundColor Red
        Read-Host "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        SupprimerRepertoire
        return
    }
    if (-not (VerifierMotDePasseAdmin "SUPPRIMER REPERTOIRE *$Chemin*")) {
        SupprimerRepertoire
        return
    }
    $Confirm = Read-Host "CONFIRMER LA SUPPRESSION DE *$Chemin* ? [O/N]"
    if ($Confirm -ne "O" -and $Confirm -ne "o") {
        Write-Host "SUPPRESSION ANNULEE"
        Read-Host "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        MenuRepertoires
        return
    }
    try {
        Remove-Item -Path $Chemin -Recurse -Force
        Write-Host "REPERTOIRE SUPPRIME AVEC SUCCES" -ForegroundColor Green
        SauvegarderLog "Action_SuppressionRepertoire_$Chemin"
    } catch {
        Write-Host "IMPOSSIBLE DE SUPPRIMER LE REPERTOIRE" -ForegroundColor Red
    }
    Write-Host ""
    $Continuer = Read-Host "VOULEZ-VOUS SUPPRIMER UN AUTRE REPERTOIRE ? [O/N]"
    if ($Continuer -eq "O" -or $Continuer -eq "o") {
        SupprimerRepertoire
    } else {
        MenuRepertoires
    }
}

###############################################################
#                    FONCTIONS LOGICIELS                      #
###############################################################

#FONCTION POUR AFFICHER LES APPLICATIONS INSTALLEES
function AfficherApplicationsInstallees {
    AfficherEntete
    Write-Host "  APPLICATIONS INSTALLEES"
    Write-Host ""
    SauvegarderLog "Consultation_ApplicationsInstallees"
    $apps = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* -ErrorAction SilentlyContinue | 
        Where-Object { $_.DisplayName } | 
        Select-Object DisplayName, DisplayVersion | 
        Sort-Object DisplayName
    $nb_apps = ($apps | Measure-Object).Count
    $liste_apps = $apps | Out-String
    SauvegarderInfo "=== APPLICATIONS INSTALLEES === $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n$liste_apps"
    if ($nb_apps -le 10) {
        Write-Host $liste_apps
        Write-Host "($nb_apps APPLICATIONS ENREGISTREES)"
    } else {
        Write-Host "LISTE DES APPLICATIONS ENREGISTREE ($nb_apps APPLICATIONS)"
    }
    Write-Host ""
    Read-Host "APPUYEZ SUR [ENTREE] POUR CONTINUER"
    MenuLogiciels
}

#FONCTION POUR AFFICHER LES MISES A JOUR CRITIQUES
function AfficherMisesAJourManquantes {
    AfficherEntete
    Write-Host "  MISES A JOUR CRITIQUES"
    Write-Host ""
    SauvegarderLog "Consultation_MisesAJourCritiques"
    try {
        $UpdateSession = New-Object -ComObject Microsoft.Update.Session
        $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
        $SearchResult = $UpdateSearcher.Search("IsInstalled=0")
        $nb_maj = $SearchResult.Updates.Count
        if ($nb_maj -eq 0) {
            Write-Host "AUCUNE MISE A JOUR DISPONIBLE"
            SauvegarderInfo "=== MISES A JOUR === $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`nAUCUNE MISE A JOUR"
        } else {
            $mises_a_jour = $SearchResult.Updates | Select-Object Title | Out-String
            SauvegarderInfo "=== MISES A JOUR === $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n$mises_a_jour"
            if ($nb_maj -le 10) {
                Write-Host "$nb_maj MISE(S) A JOUR DISPONIBLE(S):"
                Write-Host ""
                Write-Host $mises_a_jour
                Write-Host "($nb_maj MISES A JOUR ENREGISTREES)"
            } else {
                Write-Host "LISTE DES MISES A JOUR ENREGISTREE ($nb_maj MISES A JOUR)"
            }
        }
    } catch {
        Write-Host "VERIFICATION DES MISES A JOUR IMPOSSIBLE" -ForegroundColor DarkGray
        SauvegarderInfo "=== MISES A JOUR === $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`nVERIFICATION IMPOSSIBLE"
    }
    Write-Host ""
    Read-Host "APPUYEZ SUR [ENTREE] POUR CONTINUER"
    MenuLogiciels
}

###############################################################
#                    FONCTIONS SERVICES                       #
###############################################################

#FONCTION POUR AFFICHER LES SERVICES EN COURS
function AfficherServicesEnCours {
    AfficherEntete
    Write-Host "  SERVICES EN COURS D'EXECUTION"
    Write-Host ""
    SauvegarderLog "Consultation_ServicesEnCours"
    $liste_services = net start | Out-String
    $nb_lignes = ($liste_services -split "`n" | Where-Object { $_.Trim() -ne "" }).Count
    SauvegarderInfo "=== SERVICES EN COURS === $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n$liste_services"
    if ($nb_lignes -le 10) {
        Write-Host $liste_services
    } else {
        Write-Host "LISTE DES SERVICES ENREGISTREE ($nb_lignes SERVICES)"
    }
    Write-Host ""
    Read-Host "APPUYEZ SUR [ENTREE] POUR CONTINUER"
    MenuServices
}

###############################################################
#                    FONCTIONS RESEAU                         #
###############################################################

#FONCTION POUR AFFICHER LA CONFIGURATION IP
function AfficherConfigIP {
    AfficherEntete
    Write-Host "  CONFIGURATION IP"
    Write-Host ""
    SauvegarderLog "Consultation_ConfigurationIP"
    $config_complete = ipconfig | Out-String
    SauvegarderInfo "=== CONFIGURATION IP === $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n$config_complete"
    $lignes = ipconfig
    $passerelle = ""
    foreach ($ligne in $lignes) {
        if ($ligne -match "^Ethernet adapter|^Carte Ethernet") {
            if ($passerelle -ne "") {
                Write-Host "  PASSERELLE: $passerelle"
            }
            Write-Host ""
            Write-Host " $ligne "
            $passerelle = "[AUCUNE]"
        }
        elseif ($ligne -match "IPv4.*:\s*(\d+\.\d+\.\d+\.\d+)") {
            Write-Host "  IP:         $($Matches[1])"
        }
        elseif ($ligne -match "Subnet.*:\s*(\d+\.\d+\.\d+\.\d+)") {
            Write-Host "  MASQUE:     $($Matches[1])"
        }
        elseif ($ligne -match "Masque.*:\s*(\d+\.\d+\.\d+\.\d+)") {
            Write-Host "  MASQUE:     $($Matches[1])"
        }
        elseif ($ligne -match "Gateway.*:\s*(\d+\.\d+\.\d+\.\d+)") {
            $passerelle = $Matches[1]
        }
        elseif ($ligne -match "Passerelle.*:\s*(\d+\.\d+\.\d+\.\d+)") {
            $passerelle = $Matches[1]
        }
    }
    if ($passerelle -ne "") {
        Write-Host "  PASSERELLE: $passerelle"
    }
    Write-Host ""
    Write-Host ""
    Read-Host "APPUYEZ SUR [ENTREE] POUR CONTINUER"
    MenuReseau
}

#FONCTION POUR AFFICHER LES PORTS OUVERTS
function AfficherPortsOuverts {
    AfficherEntete
    Write-Host "  PORTS OUVERTS "
    Write-Host ""
    SauvegarderLog "Consultation_PortsOuverts"
    $liste_ports = netstat -an | Select-String "LISTENING"
    $liste_ports_str = $liste_ports | Out-String
    $nb_lignes = ($liste_ports_str -split "`n" | Where-Object { $_.Trim() -ne "" }).Count
    SauvegarderInfo "=== PORTS OUVERTS === $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n$liste_ports_str"
    if ($nb_lignes -le 10) {
        Write-Host $liste_ports_str
    } else {
        Write-Host "LISTE DES PORTS ENREGISTREE ($nb_lignes PORTS)"
    }
    Write-Host ""
    Read-Host "APPUYEZ SUR [ENTREE] POUR CONTINUER"
    MenuReseau
}

#FONCTION POUR ACTIVER LE PARE-FEU WINDOWS
function ActiverPareFeu {
    AfficherEntete
    SauvegarderLog "Navigation_MenuPareFeu"
    Write-Host "  ACTIVATION DU PARE-FEU"
    Write-Host ""
    $etatDomain = (netsh advfirewall show domainprofile state | Select-String "State" | Out-String).Trim()
    $etatPrivate = (netsh advfirewall show privateprofile state | Select-String "State" | Out-String).Trim()
    $etatPublic = (netsh advfirewall show publicprofile state | Select-String "State" | Out-String).Trim()
    $statusDomain = if ($etatDomain -match "ON") { "ON" } else { "OFF" }
    $statusPrivate = if ($etatPrivate -match "ON") { "ON" } else { "OFF" }
    $statusPublic = if ($etatPublic -match "ON") { "ON" } else { "OFF" }
    Write-Host "  1. DOMAINE      [$statusDomain]"
    Write-Host "  2. PRIVE        [$statusPrivate]"
    Write-Host "  3. PUBLIC       [$statusPublic]"
    Write-Host "  4. TOUS LES PROFILS"
    Write-Host "  5. QUITTER"
    Write-Host ""
    $etat_complet = "DOMAINE: $statusDomain`nPRIVE: $statusPrivate`nPUBLIC: $statusPublic"
    SauvegarderInfo "=== ETAT PARE-FEU === $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n$etat_complet"
    $Choix = Read-Host "TAPEZ [1-5]"
    switch ($Choix) {
        1 {
            if (-not (VerifierMotDePasseAdmin "ACTIVER PARE-FEU *DOMAINE*")) {
                ActiverPareFeu
                return
            }
            netsh advfirewall set domainprofile state on 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "PARE-FEU DOMAINE ACTIVE" -ForegroundColor Green
                SauvegarderLog "Action_ActivationPareFeu_Domaine"
            } else {
                Write-Host "IMPOSSIBLE D'ACTIVER (PRIVILEGES REQUIS)" -ForegroundColor DarkGray
            }
            Read-Host "APPUYEZ SUR [ENTREE] POUR CONTINUER"
            ActiverPareFeu
        }
        2 {
            if (-not (VerifierMotDePasseAdmin "ACTIVER PARE-FEU *PRIVE*")) {
                ActiverPareFeu
                return
            }
            netsh advfirewall set privateprofile state on 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "PARE-FEU PRIVE ACTIVE" -ForegroundColor Green
                SauvegarderLog "Action_ActivationPareFeu_Prive"
            } else {
                Write-Host "IMPOSSIBLE D'ACTIVER (PRIVILEGES REQUIS)" -ForegroundColor DarkGray
            }
            Read-Host "APPUYEZ SUR [ENTREE] POUR CONTINUER"
            ActiverPareFeu
        }
        3 {
            if (-not (VerifierMotDePasseAdmin "ACTIVER PARE-FEU *PUBLIC*")) {
                ActiverPareFeu
                return
            }
            netsh advfirewall set publicprofile state on 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "PARE-FEU PUBLIC ACTIVE" -ForegroundColor Green
                SauvegarderLog "Action_ActivationPareFeu_Public"
            } else {
                Write-Host "IMPOSSIBLE D'ACTIVER (PRIVILEGES REQUIS)" -ForegroundColor DarkGray
            }
            Read-Host "APPUYEZ SUR [ENTREE] POUR CONTINUER"
            ActiverPareFeu
        }
        4 {
            if (-not (VerifierMotDePasseAdmin "ACTIVER *TOUS LES PARE-FEU*")) {
                ActiverPareFeu
                return
            }
            netsh advfirewall set allprofiles state on 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "TOUS LES PARE-FEU ACTIVES" -ForegroundColor Green
                SauvegarderLog "Action_ActivationPareFeu_Tous"
            } else {
                Write-Host "IMPOSSIBLE D'ACTIVER (PRIVILEGES REQUIS)" -ForegroundColor DarkGray
            }
            Read-Host "APPUYEZ SUR [ENTREE] POUR CONTINUER"
            ActiverPareFeu
        }
        5 {
            SauvegarderLog "Navigation_Retour"
            MenuReseau
        }
        default {
            Read-Host "CHOIX INVALIDE, APPUYEZ SUR [ENTREE] POUR CONTINUER"
            ActiverPareFeu
        }
    }
}

###############################################################
#                  FONCTIONS SYSTEME                          #
###############################################################

#FONCTION POUR AFFICHER LES INFORMATIONS SYSTEME
function AfficherInfoSysteme {
    AfficherEntete
    Write-Host "  INFORMATIONS SYSTEME"
    Write-Host ""
    SauvegarderLog "Consultation_InfoSysteme"
    $OsName = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -ErrorAction SilentlyContinue).ProductName
    $OsVersion = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -ErrorAction SilentlyContinue).DisplayVersion
    $OsBuild = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -ErrorAction SilentlyContinue).CurrentBuild
    $OsArch = if ([Environment]::Is64BitOperatingSystem) { "64-bit" } else { "32-bit" }
    try {
        $cs = Get-CimInstance Win32_ComputerSystem
        $fabricant = $cs.Manufacturer
        $modele = $cs.Model
        $type = $cs.SystemType
    } catch {
        $fabricant = "NON DISPONIBLE"
        $modele = "NON DISPONIBLE"
        $type = "NON DISPONIBLE"
    }
    $info_systeme = "NOM: $OsName`nVERSION: $OsVersion (BUILD $OsBuild)`nARCHITECTURE: $OsArch`nFABRICANT: $fabricant`nMODELE: $modele`nTYPE: $type"
    SauvegarderInfo "=== INFORMATIONS SYSTEME === $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n$info_systeme"
    Write-Host "NOM: $OsName"
    Write-Host "VERSION: $OsVersion (BUILD $OsBuild)"
    Write-Host "ARCHITECTURE: $OsArch"
    Write-Host "FABRICANT: $fabricant"
    Write-Host "MODELE: $modele"
    Write-Host "TYPE: $type"
    Write-Host ""
    Read-Host "APPUYEZ SUR [ENTREE] POUR CONTINUER"
    MenuSysteme
}

#FONCTION POUR AFFICHER LUTILISATION DE LA RAM
function AfficherUtilisationRAM {
    AfficherEntete
    Write-Host "  UTILISATION DE LA MEMOIRE RAM"
    Write-Host ""
    SauvegarderLog "Consultation_UtilisationRAM"
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $totalRAM = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
        $ramLibre = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
        $ramUtilisee = [math]::Round($totalRAM - $ramLibre, 2)
        $ram_info = "RAM TOTALE: $totalRAM GO`nRAM UTILISEE: $ramUtilisee GO`nRAM LIBRE: $ramLibre GO"
        SauvegarderInfo "=== UTILISATION RAM === $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n$ram_info"
        Write-Host "RAM TOTALE: $totalRAM GO"
        Write-Host "RAM UTILISEE: $ramUtilisee GO"
        Write-Host "RAM LIBRE: $ramLibre GO"
    } catch {
        Write-Host "IMPOSSIBLE DE RECUPERER LES INFORMATIONS RAM" -ForegroundColor DarkGray
    }
    Write-Host ""
    Read-Host "APPUYEZ SUR [ENTREE] POUR CONTINUER"
    MenuSysteme
}

#FONCTION POUR AFFICHER LE STATUT DE LUAC
function AfficherStatutUAC {
    AfficherEntete
    Write-Host "  STATUT DE L'UAC"
    Write-Host ""
    SauvegarderLog "Consultation_StatutUAC"
    try {
        $uac = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -ErrorAction SilentlyContinue
        if ($uac.EnableLUA -eq 1) {
            Write-Host "UAC: " -NoNewline
            Write-Host "ACTIVE" -ForegroundColor Green
            $uac_info = "UAC: ACTIVE"
        } else {
            Write-Host "UAC: " -NoNewline
            Write-Host "DESACTIVE" -ForegroundColor Red
            $uac_info = "UAC: DESACTIVE"
        }
        SauvegarderInfo "=== STATUT UAC === $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n$uac_info"
    } catch {
        Write-Host "IMPOSSIBLE DE RECUPERER LE STATUT UAC" -ForegroundColor DarkGray
    }
    Write-Host ""
    Read-Host "APPUYEZ SUR [ENTREE] POUR CONTINUER"
    MenuSysteme
}

###############################################################
#                  FONCTIONS CONTROLES                        #
###############################################################

#FONCTION POUR REDEMARRER LA MACHINE
function RedemarrerMachine {
    AfficherEntete
    Write-Host "  REDEMARRAGE DE LA MACHINE"
    Write-Host ""
    $Confirm1 = Read-Host "REDEMARRER LA MACHINE ? [O/N]"
    if ($Confirm1 -ne "O" -and $Confirm1 -ne "o") {
        Write-Host "REDEMARRAGE ANNULE"
        Read-Host "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        MenuControles
        return
    }
    $Confirm2 = Read-Host "CONFIRMER LE REDEMARRAGE ? [O/N]"
    if ($Confirm2 -ne "O" -and $Confirm2 -ne "o") {
        Write-Host "REDEMARRAGE ANNULE"
        Read-Host "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        MenuControles
        return
    }
    Write-Host ""
    Write-Host "REDEMARRAGE EN COURS..."
    SauvegarderLog "Action_RedemarrageMachine"
    shutdown /r /t 5
    if ($LASTEXITCODE -eq 0) {
        Write-Host "LA MACHINE REDEMARRERA DANS 5 SECONDES..." -ForegroundColor Green
        Start-Sleep -Seconds 2
        exit
    } else {
        Write-Host "ECHEC DU REDEMARRAGE (PRIVILEGES INSUFFISANTS)" -ForegroundColor Red
        Read-Host "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        MenuControles
    }
}

#FONCTION POUR EXECUTER UN SCRIPT DISTANT
function ExecuterScriptDistant {
    AfficherEntete
    Write-Host "  EXECUTION D'UN SCRIPT"
    Write-Host ""
    $CheminScript = Read-Host "CHEMIN COMPLET DU SCRIPT A EXECUTER (Q POUR QUITTER)"
    if ($CheminScript -eq "q" -or $CheminScript -eq "Q") {
        SauvegarderLog "Navigation_Retour"
        MenuControles
        return
    }
    if ([string]::IsNullOrEmpty($CheminScript)) {
        Write-Host "CHEMIN NON SPECIFIE"
        Read-Host "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        ExecuterScriptDistant
        return
    }
    if (-not (Test-Path $CheminScript)) {
        Write-Host "LE FICHIER N'EXISTE PAS" -ForegroundColor Red
        Read-Host "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        ExecuterScriptDistant
        return
    }
    if (-not (VerifierMotDePasseAdmin "EXECUTER SCRIPT *$CheminScript*")) {
        ExecuterScriptDistant
        return
    }
    $Confirm = Read-Host "EXECUTER LE SCRIPT *$CheminScript* ? [O/N]"
    if ($Confirm -ne "O" -and $Confirm -ne "o") {
        Write-Host "EXECUTION ANNULEE"
        Read-Host "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        MenuControles
        return
    }
    Write-Host ""
    Write-Host "EXECUTION DU SCRIPT EN COURS..."
    Write-Host ""
    SauvegarderLog "Action_ExecutionScript_$CheminScript"
    try {
        & $CheminScript
        Write-Host ""
        Write-Host "SCRIPT EXECUTE" -ForegroundColor Green
    } catch {
        Write-Host "ERREUR LORS DE L'EXECUTION" -ForegroundColor Red
    }
    Write-Host ""
    $Continuer = Read-Host "VOULEZ-VOUS EXECUTER UN AUTRE SCRIPT ? [O/N]"
    if ($Continuer -eq "O" -or $Continuer -eq "o") {
        ExecuterScriptDistant
    } else {
        MenuControles
    }
}

#FONCTION POUR OUVRIR UNE CONSOLE DISTANTE
function OuvrirConsoleDistante {
    AfficherEntete
    Write-Host "  PRISE DE MAIN A DISTANCE (CLI)"
    Write-Host ""
    Write-Host "TAPEZ *EXIT* POUR REVENIR AU MENU"
    Write-Host ""
    SauvegarderLog "Action_OuvertureConsole"
    powershell.exe -NoLogo
    SauvegarderLog "Action_FermetureConsole"
    MenuControles
}

###############################################################
#                  FONCTIONS UTILISATEURS                     #
###############################################################

#FONCTION POUR CREER UN COMPTE UTILISATEUR LOCAL
function CreerUtilisateurLocal {
    AfficherEntete
    Write-Host "  CREATION D'UN COMPTE UTILISATEUR"
    Write-Host ""
    AfficherUtilisateursLocaux
    $NomUtilisateur = Read-Host "NOM DU NOUVEL UTILISATEUR (Q POUR QUITTER)"
    if ($NomUtilisateur -eq "q" -or $NomUtilisateur -eq "Q") {
        SauvegarderLog "Navigation_Retour"
        MenuUtilisateurs
        return
    }
    if ([string]::IsNullOrEmpty($NomUtilisateur)) {
        Write-Host "NOM D'UTILISATEUR NON SPECIFIE"
        Read-Host "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        CreerUtilisateurLocal
        return
    }
    if (Get-LocalUser -Name $NomUtilisateur -ErrorAction SilentlyContinue) {
        Write-Host "L'UTILISATEUR `"$NomUtilisateur`" EXISTE DEJA" -ForegroundColor Red
        Read-Host "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        CreerUtilisateurLocal
        return
    }
    $Confirm = Read-Host "CONFIRMER LA CREATION DE `"$NomUtilisateur`" ? [O/N]"
    if ($Confirm -ne "O" -and $Confirm -ne "o") {
        Write-Host "CREATION ANNULEE"
        Read-Host "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        MenuUtilisateurs
        return
    }
    try {
        New-LocalUser -Name $NomUtilisateur -NoPassword
        Write-Host ""
        Write-Host "UTILISATEUR `"$NomUtilisateur`" CREE AVEC SUCCES" -ForegroundColor Green
        SauvegarderLog "Action_CreationUtilisateur_$NomUtilisateur"
    } catch {
        Write-Host "IMPOSSIBLE DE CREER L'UTILISATEUR" -ForegroundColor Red
    }
    Write-Host ""
    $Continuer = Read-Host "VOULEZ-VOUS CREER UN AUTRE UTILISATEUR ? [O/N]"
    if ($Continuer -eq "O" -or $Continuer -eq "o") {
        CreerUtilisateurLocal
    } else {
        MenuUtilisateurs
    }
}

#FONCTION POUR SUPPRIMER UN COMPTE UTILISATEUR LOCAL
function SupprimerUtilisateurLocal {
    AfficherEntete
    Write-Host "  SUPPRESSION DE COMPTE UTILISATEUR"
    Write-Host ""
    AfficherUtilisateursLocaux
    $NomUtilisateur = Read-Host "NOM D'UTILISATEUR (Q POUR QUITTER)"
    if ($NomUtilisateur -eq "q" -or $NomUtilisateur -eq "Q") {
        SauvegarderLog "Navigation_Retour"
        MenuUtilisateurs
        return
    }
    if ([string]::IsNullOrEmpty($NomUtilisateur)) {
        Write-Host "NOM D'UTILISATEUR NON SPECIFIE"
        Read-Host "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        SupprimerUtilisateurLocal
        return
    }
    if (-not (Get-LocalUser -Name $NomUtilisateur -ErrorAction SilentlyContinue)) {
        Write-Host "L'UTILISATEUR `"$NomUtilisateur`" N'EXISTE PAS" -ForegroundColor Red
        Read-Host "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        SupprimerUtilisateurLocal
        return
    }
    if (-not (VerifierMotDePasseAdmin "SUPPRIMER UTILISATEUR `"$NomUtilisateur`"")) {
        SupprimerUtilisateurLocal
        return
    }
    $Confirm = Read-Host "SUPPRIMER DEFINITIVEMENT `"$NomUtilisateur`" ? [O/N]"
    if ($Confirm -ne "O" -and $Confirm -ne "o") {
        Write-Host "SUPPRESSION ANNULEE"
        Read-Host "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        MenuUtilisateurs
        return
    }
    try {
        Remove-LocalUser -Name $NomUtilisateur
        Write-Host ""
        Write-Host "UTILISATEUR `"$NomUtilisateur`" SUPPRIME" -ForegroundColor Green
        SauvegarderLog "Action_SuppressionUtilisateur_$NomUtilisateur"
    } catch {
        Write-Host "IMPOSSIBLE DE SUPPRIMER L'UTILISATEUR" -ForegroundColor Red
    }
    Write-Host ""
    $Continuer = Read-Host "VOULEZ-VOUS SUPPRIMER UN AUTRE UTILISATEUR ? [O/N]"
    if ($Continuer -eq "O" -or $Continuer -eq "o") {
        SupprimerUtilisateurLocal
    } else {
        MenuUtilisateurs
    }
}

#FONCTION POUR DESACTIVER UN COMPTE UTILISATEUR LOCAL
function DesactiverUtilisateurLocal {
    AfficherEntete
    Write-Host "  DESACTIVATION DE COMPTE UTILISATEUR"
    Write-Host ""
    AfficherUtilisateursLocaux
    $NomUtilisateur = Read-Host "NOM D'UTILISATEUR (Q POUR QUITTER)"
    if ($NomUtilisateur -eq "q" -or $NomUtilisateur -eq "Q") {
        SauvegarderLog "Navigation_Retour"
        MenuUtilisateurs
        return
    }
    if ([string]::IsNullOrEmpty($NomUtilisateur)) {
        Write-Host "NOM D'UTILISATEUR NON SPECIFIE"
        Read-Host "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        DesactiverUtilisateurLocal
        return
    }
    if (-not (Get-LocalUser -Name $NomUtilisateur -ErrorAction SilentlyContinue)) {
        Write-Host "L'UTILISATEUR `"$NomUtilisateur`" N'EXISTE PAS" -ForegroundColor Red
        Read-Host "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        DesactiverUtilisateurLocal
        return
    }
    if (-not (VerifierMotDePasseAdmin "DESACTIVER UTILISATEUR `"$NomUtilisateur`"")) {
        DesactiverUtilisateurLocal
        return
    }
    $Confirm = Read-Host "DESACTIVER `"$NomUtilisateur`" ? [O/N]"
    if ($Confirm -ne "O" -and $Confirm -ne "o") {
        Write-Host "DESACTIVATION ANNULEE"
        Read-Host "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        MenuUtilisateurs
        return
    }
    try {
        Disable-LocalUser -Name $NomUtilisateur
        Write-Host ""
        Write-Host "UTILISATEUR `"$NomUtilisateur`" DESACTIVE" -ForegroundColor Green
        SauvegarderLog "Action_DesactivationUtilisateur_$NomUtilisateur"
    } catch {
        Write-Host "IMPOSSIBLE DE DESACTIVER L'UTILISATEUR" -ForegroundColor Red
    }
    Write-Host ""
    $Continuer = Read-Host "VOULEZ-VOUS DESACTIVER UN AUTRE UTILISATEUR ? [O/N]"
    if ($Continuer -eq "O" -or $Continuer -eq "o") {
        DesactiverUtilisateurLocal
    } else {
        MenuUtilisateurs
    }
}

#FONCTION POUR MODIFIER LE MOT DE PASSE DUN UTILISATEUR
function ModifierMotDePasseUtilisateur {
    AfficherEntete
    Write-Host "  CHANGEMENT DE MOT DE PASSE"
    Write-Host ""
    AfficherUtilisateursLocaux
    $NomUtilisateur = Read-Host "NOM D'UTILISATEUR (Q POUR QUITTER)"
    if ($NomUtilisateur -eq "q" -or $NomUtilisateur -eq "Q") {
        SauvegarderLog "Navigation_Retour"
        MenuUtilisateurs
        return
    }
    if ([string]::IsNullOrEmpty($NomUtilisateur)) {
        Write-Host "NOM D'UTILISATEUR NON SPECIFIE"
        Read-Host "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        ModifierMotDePasseUtilisateur
        return
    }
    if (-not (Get-LocalUser -Name $NomUtilisateur -ErrorAction SilentlyContinue)) {
        Write-Host "L'UTILISATEUR `"$NomUtilisateur`" N'EXISTE PAS" -ForegroundColor Red
        Read-Host "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        ModifierMotDePasseUtilisateur
        return
    }
    $Password = Read-Host "NOUVEAU MOT DE PASSE" -AsSecureString
    $Confirm = Read-Host "CONFIRMER LE CHANGEMENT DE MOT DE PASSE POUR `"$NomUtilisateur`" ? [O/N]"
    if ($Confirm -ne "O" -and $Confirm -ne "o") {
        Write-Host "MODIFICATION ANNULEE"
        Read-Host "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        MenuUtilisateurs
        return
    }
    try {
        Set-LocalUser -Name $NomUtilisateur -Password $Password
        Write-Host ""
        Write-Host "MOT DE PASSE MODIFIE POUR `"$NomUtilisateur`"" -ForegroundColor Green
        SauvegarderLog "Action_ModificationMotDePasse_$NomUtilisateur"
    } catch {
        Write-Host "IMPOSSIBLE DE MODIFIER LE MOT DE PASSE" -ForegroundColor Red
    }
    Write-Host ""
    $Continuer = Read-Host "VOULEZ-VOUS MODIFIER UN AUTRE MOT DE PASSE ? [O/N]"
    if ($Continuer -eq "O" -or $Continuer -eq "o") {
        ModifierMotDePasseUtilisateur
    } else {
        MenuUtilisateurs
    }
}

#FONCTION POUR AJOUTER UN UTILISATEUR A UN GROUPE LOCAL
function AjouterUtilisateurGroupe {
    AfficherEntete
    Write-Host "  AJOUT A UN GROUPE"
    Write-Host ""
    AfficherUtilisateursLocaux
    $NomUtilisateur = Read-Host "NOM D'UTILISATEUR (Q POUR QUITTER)"
    if ($NomUtilisateur -eq "q" -or $NomUtilisateur -eq "Q") {
        SauvegarderLog "Navigation_Retour"
        MenuUtilisateurs
        return
    }
    if ([string]::IsNullOrEmpty($NomUtilisateur)) {
        Write-Host "NOM D'UTILISATEUR NON SPECIFIE"
        Read-Host "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        AjouterUtilisateurGroupe
        return
    }
    if (-not (Get-LocalUser -Name $NomUtilisateur -ErrorAction SilentlyContinue)) {
        Write-Host "L'UTILISATEUR `"$NomUtilisateur`" N'EXISTE PAS" -ForegroundColor Red
        Read-Host "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        AjouterUtilisateurGroupe
        return
    }
    Write-Host ""
    $tousGroupes = Get-LocalGroup -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name | Sort-Object
    $groupes_dispo = $tousGroupes -join " | "
    Write-Host "GROUPES DISPONIBLES: $groupes_dispo"
    Write-Host ""
    $NomGroupe = Read-Host "NOM DU GROUPE (Q POUR QUITTER)"
    if ($NomGroupe -eq "q" -or $NomGroupe -eq "Q") {
        SauvegarderLog "Navigation_Retour"
        MenuUtilisateurs
        return
    }
    if ([string]::IsNullOrEmpty($NomGroupe)) {
        Write-Host "NOM DU GROUPE NON SPECIFIE"
        Read-Host "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        AjouterUtilisateurGroupe
        return
    }
    if (-not (Get-LocalGroup -Name $NomGroupe -ErrorAction SilentlyContinue)) {
        Write-Host "LE GROUPE *$NomGroupe* N'EXISTE PAS" -ForegroundColor Red
        Read-Host "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        AjouterUtilisateurGroupe
        return
    }
    $membres = Get-LocalGroupMember -Group $NomGroupe -ErrorAction SilentlyContinue
    if ($membres.Name -like "*\$NomUtilisateur" -or $membres.Name -eq $NomUtilisateur) {
        Write-Host "L'UTILISATEUR `"$NomUtilisateur`" EST DEJA DANS LE GROUPE *$NomGroupe*" -ForegroundColor DarkGray
        Read-Host "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        AjouterUtilisateurGroupe
        return
    }
    $Confirm = Read-Host "AJOUTER `"$NomUtilisateur`" AU GROUPE *$NomGroupe* ? [O/N]"
    if ($Confirm -ne "O" -and $Confirm -ne "o") {
        Write-Host "AJOUT ANNULE"
        Read-Host "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        MenuUtilisateurs
        return
    }
    try {
        net localgroup "$NomGroupe" "$NomUtilisateur" /add 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "UTILISATEUR `"$NomUtilisateur`" AJOUTE AU GROUPE *$NomGroupe*" -ForegroundColor Green
            SauvegarderLog "Action_AjoutGroupe_${NomUtilisateur}_${NomGroupe}"
        } else {
            Write-Host "IMPOSSIBLE D'AJOUTER L'UTILISATEUR AU GROUPE" -ForegroundColor Red
        }
    } catch {
        Write-Host "IMPOSSIBLE D'AJOUTER L'UTILISATEUR AU GROUPE" -ForegroundColor Red
    }
    Write-Host ""
    $Continuer = Read-Host "VOULEZ-VOUS AJOUTER UN AUTRE UTILISATEUR ? [O/N]"
    if ($Continuer -eq "O" -or $Continuer -eq "o") {
        AjouterUtilisateurGroupe
    } else {
        MenuUtilisateurs
    }
}

#FONCTION POUR AJOUTER UN UTILISATEUR AU GROUPE ADMINISTRATEURS
function AjouterUtilisateurGroupeAdmin {
    AfficherEntete
    Write-Host "  AJOUT AUX ADMINISTRATEURS"
    Write-Host ""
    AfficherUtilisateursLocaux
    $NomUtilisateur = Read-Host "NOM D'UTILISATEUR (Q POUR QUITTER)"
    if ($NomUtilisateur -eq "q" -or $NomUtilisateur -eq "Q") {
        SauvegarderLog "Navigation_Retour"
        MenuUtilisateurs
        return
    }
    if ([string]::IsNullOrEmpty($NomUtilisateur)) {
        Write-Host "NOM D'UTILISATEUR NON SPECIFIE"
        Read-Host "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        AjouterUtilisateurGroupeAdmin
        return
    }
    if (-not (Get-LocalUser -Name $NomUtilisateur -ErrorAction SilentlyContinue)) {
        Write-Host "L'UTILISATEUR `"$NomUtilisateur`" N'EXISTE PAS" -ForegroundColor Red
        Read-Host "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        AjouterUtilisateurGroupeAdmin
        return
    }
    $dejaAdmin = net localgroup "Administrateurs" 2>$null | Select-String -Pattern "^$NomUtilisateur$"
    if (-not $dejaAdmin) {
        $dejaAdmin = net localgroup "Administrators" 2>$null | Select-String -Pattern "^$NomUtilisateur$"
    }
    if ($dejaAdmin) {
        Write-Host "L'UTILISATEUR `"$NomUtilisateur`" EST DEJA DANS LE GROUPE *ADMINISTRATEURS*" -ForegroundColor DarkGray
        Read-Host "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        AjouterUtilisateurGroupeAdmin
        return
    }
    if (-not (VerifierMotDePasseAdmin "AJOUTER `"$NomUtilisateur`" AU GROUPE *ADMINISTRATEURS*")) {
        AjouterUtilisateurGroupeAdmin
        return
    }
    $Confirm = Read-Host "AJOUTER `"$NomUtilisateur`" AU GROUPE *ADMINISTRATEURS* ? [O/N]"
    if ($Confirm -ne "O" -and $Confirm -ne "o") {
        Write-Host "AJOUT ANNULE"
        Read-Host "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        MenuUtilisateurs
        return
    }
    $resultat = net localgroup "Administrateurs" "$NomUtilisateur" /add 2>&1
    if ($LASTEXITCODE -ne 0) {
        $resultat = net localgroup "Administrators" "$NomUtilisateur" /add 2>&1
    }
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "UTILISATEUR `"$NomUtilisateur`" AJOUTE AU GROUPE *ADMINISTRATEURS*" -ForegroundColor Green
        SauvegarderLog "Action_AjoutGroupeAdmin_$NomUtilisateur"
    } else {
        Write-Host ""
        Write-Host "IMPOSSIBLE D'AJOUTER L'UTILISATEUR AU GROUPE" -ForegroundColor Red
    }
    Write-Host ""
    $Continuer = Read-Host "VOULEZ-VOUS AJOUTER UN AUTRE UTILISATEUR ? [O/N]"
    if ($Continuer -eq "O" -or $Continuer -eq "o") {
        AjouterUtilisateurGroupeAdmin
    } else {
        MenuUtilisateurs
    }
}

#FONCTION POUR AFFICHER LES GROUPES DUN UTILISATEUR
function AfficherGroupesUtilisateur {
    AfficherEntete
    Write-Host "  GROUPES D'APPARTENANCE D'UN UTILISATEUR"
    Write-Host ""
    AfficherUtilisateursLocaux
    $NomUtilisateur = Read-Host "NOM D'UTILISATEUR (Q POUR QUITTER)"
    if ($NomUtilisateur -eq "q" -or $NomUtilisateur -eq "Q") {
        SauvegarderLog "Navigation_Retour"
        MenuUtilisateurs
        return
    }
    if ([string]::IsNullOrEmpty($NomUtilisateur)) {
        Write-Host "NOM D'UTILISATEUR NON SPECIFIE"
        Read-Host "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        AfficherGroupesUtilisateur
        return
    }
    if (-not (Get-LocalUser -Name $NomUtilisateur -ErrorAction SilentlyContinue)) {
        Write-Host "L'UTILISATEUR `"$NomUtilisateur`" N'EXISTE PAS" -ForegroundColor Red
        Read-Host "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        AfficherGroupesUtilisateur
        return
    }
    SauvegarderLog "Consultation_GroupesUtilisateur_$NomUtilisateur"
    $groupesTrouves = @()
    Get-LocalGroup | ForEach-Object {
        $membres = Get-LocalGroupMember -Group $_.Name -ErrorAction SilentlyContinue
        if ($membres.Name -like "*\$NomUtilisateur" -or $membres.Name -eq $NomUtilisateur) {
            $groupesTrouves += $_.Name
        }
    }
    if ($groupesTrouves.Count -eq 0) {
        $groupes = "AUCUN GROUPE TROUVE"
    } else {
        $groupes = $groupesTrouves -join " | "
    }
    SauvegarderInfo "=== GROUPES UTILISATEUR === $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`nUTILISATEUR: $NomUtilisateur`nGROUPES: $groupes"
    Write-Host ""
    Write-Host "GROUPES DE `"$NomUtilisateur`": $groupes"
    Write-Host ""
    $Continuer = Read-Host "VOULEZ-VOUS CONSULTER UN AUTRE UTILISATEUR ? [O/N]"
    if ($Continuer -eq "O" -or $Continuer -eq "o") {
        AfficherGroupesUtilisateur
    } else {
        MenuUtilisateurs
    }
}

#FONCTION POUR AFFICHER LES PERMISSIONS DUN FICHIER
function AfficherPermissionsUtilisateur {
    AfficherEntete
    Write-Host "  DROITS ET PERMISSIONS SUR FICHIER"
    Write-Host ""
    $Chemin = Read-Host "CHEMIN DU FICHIER OU DOSSIER (Q POUR QUITTER)"
    if ($Chemin -eq "q" -or $Chemin -eq "Q") {
        SauvegarderLog "Navigation_Retour"
        MenuUtilisateurs
        return
    }
    if ([string]::IsNullOrEmpty($Chemin)) {
        Write-Host "CHEMIN NON SPECIFIE"
        Read-Host "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        AfficherPermissionsUtilisateur
        return
    }
    if (-not (Test-Path $Chemin)) {
        Write-Host "LE CHEMIN *$Chemin* N'EXISTE PAS" -ForegroundColor Red
        Read-Host "APPUYEZ SUR [ENTREE] POUR CONTINUER"
        AfficherPermissionsUtilisateur
        return
    }
    SauvegarderLog "Consultation_Permissions_$Chemin"
    Write-Host ""
    Write-Host "PERMISSIONS:"
    Write-Host ""
    if (Test-Path $Chemin -PathType Container) {
        $items = Get-ChildItem $Chemin -Force
        foreach ($item in $items) {
            $acl = Get-Acl $item.FullName
            $type = if ($item.PSIsContainer) { "[DOSSIER]" } else { "[FICHIER]" }
            Write-Host "$type $($item.Name)"
            Write-Host "  PROPRIETAIRE: $($acl.Owner)"
            $acl.Access | ForEach-Object {
                Write-Host "  $($_.IdentityReference) - $($_.FileSystemRights) - $($_.AccessControlType)"
            }
            Write-Host ""
        }
        $permissions = $items | ForEach-Object { "$($_.Name) - $($(Get-Acl $_.FullName).Owner)" } | Out-String
    } else {
        $acl = Get-Acl $Chemin
        Write-Host "PROPRIETAIRE: $($acl.Owner)"
        Write-Host ""
        $acl.Access | ForEach-Object {
            Write-Host "$($_.IdentityReference) - $($_.FileSystemRights) - $($_.AccessControlType)"
        }
        $permissions = $acl.Access | Select-Object IdentityReference, FileSystemRights, AccessControlType | Out-String
    }
    SauvegarderInfo "=== PERMISSIONS === $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`nCHEMIN: $Chemin`n$permissions"
    Write-Host ""
    $Continuer = Read-Host "VOULEZ-VOUS CONSULTER UN AUTRE CHEMIN ? [O/N]"
    if ($Continuer -eq "O" -or $Continuer -eq "o") {
        AfficherPermissionsUtilisateur
    } else {
        MenuUtilisateurs
    }
}

###############################################################
#                         MENUS                               #
###############################################################

#FONCTION POUR AFFICHER LE MENU DES REPERTOIRES
function MenuRepertoires {
    AfficherEntete
    SauvegarderLog "Navigation_MenuRepertoires"
    Write-Host "  REPERTOIRES"
    Write-Host ""
    Write-Host "  1.CREER UN REPERTOIRE"
    Write-Host "  2.SUPPRIMER UN REPERTOIRE"
    Write-Host "  3.RETOUR"
    Write-Host ""
    $Choix = Read-Host "TAPEZ [1-3]"
    switch ($Choix) {
        1 { CreerRepertoire }
        2 { SupprimerRepertoire }
        3 { SauvegarderLog "Navigation_Retour"; MenuGestionMachine }
        default {
            Read-Host "CHOIX INVALIDE, APPUYEZ SUR [ENTREE] POUR CONTINUER"
            MenuRepertoires
        }
    }
}

#FONCTION POUR AFFICHER LE MENU DES LOGICIELS
function MenuLogiciels {
    AfficherEntete
    SauvegarderLog "Navigation_MenuLogiciels"
    Write-Host "  LOGICIELS"
    Write-Host ""
    Write-Host "  1.APPLICATIONS INSTALLEES"
    Write-Host "  2.MISES A JOUR CRITIQUES"
    Write-Host "  3.RETOUR"
    Write-Host ""
    $Choix = Read-Host "TAPEZ [1-3]"
    switch ($Choix) {
        1 { AfficherApplicationsInstallees }
        2 { AfficherMisesAJourManquantes }
        3 { SauvegarderLog "Navigation_Retour"; MenuGestionMachine }
        default {
            Read-Host "CHOIX INVALIDE, APPUYEZ SUR [ENTREE] POUR CONTINUER"
            MenuLogiciels
        }
    }
}

#FONCTION POUR AFFICHER LE MENU DES SERVICES
function MenuServices {
    AfficherEntete
    SauvegarderLog "Navigation_MenuServices"
    Write-Host "  GESTION DES SERVICES"
    Write-Host ""
    Write-Host "  1.LISTER LES SERVICES EN COURS"
    Write-Host "  2.RETOUR"
    Write-Host ""
    $Choix = Read-Host "TAPEZ [1-2]"
    switch ($Choix) {
        1 { AfficherServicesEnCours }
        2 { SauvegarderLog "Navigation_Retour"; MenuGestionMachine }
        default {
            Read-Host "CHOIX INVALIDE, APPUYEZ SUR [ENTREE] POUR CONTINUER"
            MenuServices
        }
    }
}

#FONCTION POUR AFFICHER LE MENU RESEAU
function MenuReseau {
    AfficherEntete
    SauvegarderLog "Navigation_MenuReseau"
    Write-Host "  RESEAU"
    Write-Host ""
    Write-Host "  1.PORTS OUVERTS"
    Write-Host "  2.INFORMATION RESEAU"
    Write-Host "  3.ACTIVATION DU PARE-FEU"
    Write-Host "  4.RETOUR"
    Write-Host ""
    $Choix = Read-Host "TAPEZ [1-4]"
    switch ($Choix) {
        1 { AfficherPortsOuverts }
        2 { AfficherConfigIP }
        3 { ActiverPareFeu }
        4 { SauvegarderLog "Navigation_Retour"; MenuGestionMachine }
        default {
            Read-Host "CHOIX INVALIDE, APPUYEZ SUR [ENTREE] POUR CONTINUER"
            MenuReseau
        }
    }
}

#FONCTION POUR AFFICHER LE MENU SYSTEME
function MenuSysteme {
    AfficherEntete
    SauvegarderLog "Navigation_MenuSysteme"
    Write-Host "  SYSTEME"
    Write-Host ""
    Write-Host "  1.INFORMATIONS SYSTEME"
    Write-Host "  2.INFORMATION SUR LA RAM"
    Write-Host "  3.STATUT UAC"
    Write-Host "  4.RETOUR"
    Write-Host ""
    $Choix = Read-Host "TAPEZ [1-4]"
    switch ($Choix) {
        1 { AfficherInfoSysteme }
        2 { AfficherUtilisationRAM }
        3 { AfficherStatutUAC }
        4 { SauvegarderLog "Navigation_Retour"; MenuGestionMachine }
        default {
            Read-Host "CHOIX INVALIDE, APPUYEZ SUR [ENTREE] POUR CONTINUER"
            MenuSysteme
        }
    }
}

#FONCTION POUR AFFICHER LE MENU CONTROLES
function MenuControles {
    AfficherEntete
    SauvegarderLog "Navigation_MenuControles"
    Write-Host "  CONTROLES"
    Write-Host ""
    Write-Host "  1.REDEMARRAGE"
    Write-Host "  2.EXECUTER UN SCRIPT"
    Write-Host "  3.PRISE DE MAIN A DISTANCE (CLI)"
    Write-Host "  4.RETOUR"
    Write-Host ""
    $Choix = Read-Host "TAPEZ [1-4]"
    switch ($Choix) {
        1 { RedemarrerMachine }
        2 { ExecuterScriptDistant }
        3 { OuvrirConsoleDistante }
        4 { SauvegarderLog "Navigation_Retour"; MenuGestionMachine }
        default {
            Read-Host "CHOIX INVALIDE, APPUYEZ SUR [ENTREE] POUR CONTINUER"
            MenuControles
        }
    }
}

#FONCTION POUR AFFICHER LE MENU DES UTILISATEURS
function MenuUtilisateurs {
    AfficherEntete
    SauvegarderLog "Navigation_MenuUtilisateurs"
    Write-Host "  GESTION DES UTILISATEURS"
    Write-Host ""
    Write-Host "  1.CREER UN COMPTE UTILISATEUR LOCAL"
    Write-Host "  2.CHANGER UN MOT DE PASSE"
    Write-Host "  3.DESACTIVER UN COMPTE"
    Write-Host "  4.SUPPRIMER UN COMPTE"
    Write-Host "  5.VERIFIER L'APPARTENANCE A UN GROUPE"
    Write-Host "  6.AJOUTER AUX ADMINISTRATEURS"
    Write-Host "  7.AJOUTER A UN GROUPE"
    Write-Host "  8.DROITS ET PERMISSIONS SUR FICHIER"
    Write-Host "  9.RETOUR"
    Write-Host ""
    $Choix = Read-Host "TAPEZ [1-9]"
    switch ($Choix) {
        1 { CreerUtilisateurLocal }
        2 { ModifierMotDePasseUtilisateur }
        3 { DesactiverUtilisateurLocal }
        4 { SupprimerUtilisateurLocal }
        5 { AfficherGroupesUtilisateur }
        6 { AjouterUtilisateurGroupeAdmin }
        7 { AjouterUtilisateurGroupe }
        8 { AfficherPermissionsUtilisateur }
        9 { SauvegarderLog "Navigation_Retour"; MenuPrincipal }
        default {
            Read-Host "CHOIX INVALIDE, APPUYEZ SUR [ENTREE] POUR CONTINUER"
            MenuUtilisateurs
        }
    }
}

#FONCTION POUR AFFICHER LE MENU GESTION DE LA MACHINE
function MenuGestionMachine {
    AfficherEntete
    SauvegarderLog "Navigation_MenuGestionMachine"
    Write-Host "  GESTION DE LA MACHINE"
    Write-Host ""
    Write-Host "  1.REPERTOIRES"
    Write-Host "  2.LOGICIELS"
    Write-Host "  3.SERVICES"
    Write-Host "  4.RESEAU"
    Write-Host "  5.SYSTEME"
    Write-Host "  6.CONTROLES"
    Write-Host "  7.RETOUR"
    Write-Host ""
    $Choix = Read-Host "TAPEZ [1-7]"
    switch ($Choix) {
        1 { MenuRepertoires }
        2 { MenuLogiciels }
        3 { MenuServices }
        4 { MenuReseau }
        5 { MenuSysteme }
        6 { MenuControles }
        7 { SauvegarderLog "Navigation_Retour"; MenuPrincipal }
        default {
            Read-Host "CHOIX INVALIDE, APPUYEZ SUR [ENTREE] POUR CONTINUER"
            MenuGestionMachine
        }
    }
}

#FONCTION POUR AFFICHER LE MENU PRINCIPAL
function MenuPrincipal {
    AfficherEntete
    SauvegarderLog "Navigation_MenuPrincipal"
    Write-Host "  MENU PRINCIPAL"
    Write-Host ""
    Write-Host "  1.GESTION DE LA MACHINE"
    Write-Host "  2.GESTION DES UTILISATEURS"
    Write-Host "  Q.QUITTER"
    Write-Host ""
    $Choix = Read-Host "TAPEZ [1-2 OU Q]"
    switch ($Choix) {
        1 { MenuGestionMachine }
        2 { MenuUtilisateurs }
        "Q" {
            Clear-Host
            SauvegarderLog "DeconnexionMachine"
            exit
        }
        "q" {
            Clear-Host
            SauvegarderLog "DeconnexionMachine"
            exit
        }
        default {
            Read-Host "CHOIX INVALIDE, APPUYEZ SUR [ENTREE] POUR CONTINUER"
            MenuPrincipal
        }
    }
}

###############################################################
#                    DEMARAGE                                 #
###############################################################
InitialiserJournal
SauvegarderLog "ConnexionMachine"
MenuPrincipal