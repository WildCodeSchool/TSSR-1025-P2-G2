##################################################################
#                   SCRIPT PRINCIPAL POWERSHELL                  #
#                    Script_By: ANIS|FRED|EROS                   #
#                        WILD_CODE_SCHOOL                        # 
##################################################################

# REPERTOIRE OU SE TROUVE LE SCRIPT PRINCIPAL
if ($PSScriptRoot) {
    $script_dir = $PSScriptRoot
} elseif ($MyInvocation.MyCommand.Path) {
    $script_dir = Split-Path -Parent $MyInvocation.MyCommand.Path
} else {
    $script_dir = Get-Location
}
###############################################################
# CONFIGURATION & VARIABLES                                   #
###############################################################

$port_ssh = "22222"
$ip_reseau = "172.16.20."
$fichier_temp = "$env:TEMP\machines_actives_$PID.txt"
$fichier_noms = "$env:TEMP\noms_machines_$PID.txt"
$script_linux = "$script_dir\scriptbash.sh"
$script_windows = "$script_dir\scriptpowershell.ps1"
$utilisateur_linux = "wilder"
$utilisateurs_windows = @("wilder1", "wilder", "admin", "administrateur", "administrator", "user")
$date_actuelle = Get-Date -Format "yyyy-MM-dd"
$heure_actuelle = Get-Date -Format "HH-mm-ss"
$script:local_ip = ""
$script:liste_ip = @()
$script:noms_machines = @{}
$script:type_os = @{}
$script:utilisateur_windows_trouve = @{}

##################################################################################
#                   CONFIGURATION DE LA JOURNALISATION                           #
##################################################################################

$script:log_dir = "C:\Windows\System32\LogFiles"
$script:log_file = "$script:log_dir\log_evt.log"
$info_dir = "$script_dir\info"

##################################################################################
#                  FONCTIONS DE JOURNALISATION                                   #
##################################################################################

#FONCTION POUR INITIALISER LE FICHIER DE LOG ET LE DOSSIER INFO
function InitialiserJournal {
    if (-not (Test-Path $script:log_dir)) {
        try {
            New-Item -Path $script:log_dir -ItemType Directory -Force | Out-Null
            Write-Host "Dossier de log cree : $script:log_dir"
        } catch {
            Write-Host "Impossible de creer C:\Logs. Le log sera dans le dossier du script."
            $script:log_dir = $script_dir
            $script:log_file = "$script_dir\log_evt.log"
        }
    }
    if (-not (Test-Path $script:log_file)) {
        try {
            New-Item -Path $script:log_file -ItemType File -Force | Out-Null
        } catch {
            $script:log_file = "$script_dir\log_evt.log"
            New-Item -Path $script:log_file -ItemType File -Force -ErrorAction SilentlyContinue | Out-Null
        }
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
    $utilisateur_evt = $env:USERNAME
    $ligne = "${date_evt}_${heure_evt}_${utilisateur_evt}_${Evenement}"
    Add-Content -Path $script:log_file -Value $ligne -ErrorAction SilentlyContinue
}

#FONCTION POUR RECUPERER LES FICHIERS INFO ET LOG DEPUIS UNE MACHINE LINUX
function RecupererInfoLinux {
    param(
        [string]$ip,
        [string]$utilisateur
    )
    $testLog = ssh -p $port_ssh -o BatchMode=yes "${utilisateur}@${ip}" "test -f /tmp/log_evt.log && echo OK" 2>$null
    if ($testLog -match "OK") {
        scp -P $port_ssh -q -o StrictHostKeyChecking=no "${utilisateur}@${ip}:/tmp/log_evt.log" "$env:TEMP\log_client_$PID.log" 2>$null
        if (Test-Path "$env:TEMP\log_client_$PID.log") {
            Get-Content "$env:TEMP\log_client_$PID.log" | Add-Content -Path $script:log_file -ErrorAction SilentlyContinue
            Remove-Item "$env:TEMP\log_client_$PID.log" -Force -ErrorAction SilentlyContinue
        }
        ssh -p $port_ssh -o BatchMode=yes "${utilisateur}@${ip}" "rm -f /tmp/log_evt.log" 2>$null
    }
    $testInfo = ssh -p $port_ssh -o BatchMode=yes "${utilisateur}@${ip}" "test -d /tmp/info && echo OK" 2>$null
    if ($testInfo -match "OK") {
        scp -P $port_ssh -q -r -o StrictHostKeyChecking=no "${utilisateur}@${ip}:/tmp/info/*" "$info_dir/" 2>$null
        ssh -p $port_ssh -o BatchMode=yes "${utilisateur}@${ip}" "rm -rf /tmp/info" 2>$null
    }
}

#FONCTION POUR RECUPERER LES FICHIERS INFO ET LOG DEPUIS UNE MACHINE WINDOWS
function RecupererInfoWindows {
    param(
        [string]$ip,
        [string]$utilisateur
    )
    $testLog = ssh -p $port_ssh -o BatchMode=yes "${utilisateur}@${ip}" "cmd /c if exist %userprofile%\Documents\log_evt.log echo OK" 2>$null
    if ($testLog -match "OK") {
        scp -P $port_ssh -q -o StrictHostKeyChecking=no "${utilisateur}@${ip}:Documents/log_evt.log" "$env:TEMP\log_client_$PID.log" 2>$null
        if (Test-Path "$env:TEMP\log_client_$PID.log") {
            Get-Content "$env:TEMP\log_client_$PID.log" | Add-Content -Path $script:log_file -ErrorAction SilentlyContinue
            Remove-Item "$env:TEMP\log_client_$PID.log" -Force -ErrorAction SilentlyContinue
        }
        ssh -p $port_ssh -o BatchMode=yes "${utilisateur}@${ip}" "cmd /c del /F /Q %userprofile%\Documents\log_evt.log" 2>$null
    }
    $testInfo = ssh -p $port_ssh -o BatchMode=yes "${utilisateur}@${ip}" "cmd /c if exist %userprofile%\Documents\info echo OK" 2>$null
    if ($testInfo -match "OK") {
        scp -P $port_ssh -q -r -o StrictHostKeyChecking=no "${utilisateur}@${ip}:Documents/info/*" "$info_dir/" 2>$null
        ssh -p $port_ssh -o BatchMode=yes "${utilisateur}@${ip}" "cmd /c rmdir /S /Q %userprofile%\Documents\info" 2>$null
    }
}

#################################################################################
# FONCTIONS POUR DETECTER LES UTILISATEURS WINDOWS/LE SYSTEME/LE NOM DE MACHINE #
#################################################################################

#FONCTION POUR TROUVER LUTILISATEUR WINDOWS VALIDE EN SSH
function TrouverUtilisateurWindows {
    param([string]$ip)
    foreach ($utilisateur in $utilisateurs_windows) {
        $result = ssh -p $port_ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no -o BatchMode=yes "${utilisateur}@${ip}" "cmd /c echo Windows" 2>$null
        if ($result -match "Windows") {
            return $utilisateur
        }
    }
    return ""
}

#FONCTION POUR DETECTER LE SYSTEME DEXPLOITATION DE LA MACHINE DISTANTE
function DetecterSysteme {
    param([string]$ip)
    $result_linux = ssh -p $port_ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no -o BatchMode=yes "${utilisateur_linux}@${ip}" "uname" 2>$null
    if ($result_linux -match "Linux") {
        $script:type_os[$ip] = "linux"
        return
    }
    $utilisateur_win = TrouverUtilisateurWindows -ip $ip
    if ($utilisateur_win -ne "") {
        $script:type_os[$ip] = "windows"
        $script:utilisateur_windows_trouve[$ip] = $utilisateur_win
        return
    }
    $script:type_os[$ip] = "inconnu"
}

#FONCTION POUR RECUPERER LE NOM DE LA MACHINE DISTANTE
function RecupererNomMachine {
    param([string]$ip)
    $nom = ""
    $utilisateur = ""
    if ($script:type_os[$ip] -eq $null -or $script:type_os[$ip] -eq "") {
        DetecterSysteme -ip $ip
    }
    if ($script:type_os[$ip] -eq "windows") {
        $utilisateur = $script:utilisateur_windows_trouve[$ip]
        if ($utilisateur -eq $null -or $utilisateur -eq "") {
            $utilisateur = TrouverUtilisateurWindows -ip $ip
            $script:utilisateur_windows_trouve[$ip] = $utilisateur
        }
    } else {
        $utilisateur = $utilisateur_linux
    }
    $nom = ssh -p $port_ssh -o ConnectTimeout=3 -o BatchMode=yes -o StrictHostKeyChecking=no "${utilisateur}@${ip}" "hostname" 2>$null
    if ($LASTEXITCODE -eq 0 -and $nom -ne $null -and $nom -ne "") {
        $script:noms_machines[$ip] = $nom -replace "`r", "" -replace "`n", ""
    } else {
        $script:noms_machines[$ip] = "?"
    }
}

##################################################################################
#                   FONCTION POUR SCANNER LE RESEAU                              #
##################################################################################

#FONCTION POUR SCANNER LE RESEAU
function ScannerReseau {
    $script:liste_ip = @()
    $script:noms_machines = @{}
    $script:type_os = @{}
    $script:utilisateur_windows_trouve = @{}
    if (Test-Path $fichier_temp) { Remove-Item $fichier_temp -Force }
    if (Test-Path $fichier_noms) { Remove-Item $fichier_noms -Force }
    New-Item -Path $fichier_temp -ItemType File -Force | Out-Null
    New-Item -Path $fichier_noms -ItemType File -Force | Out-Null
    Write-Host "SCAN DU RESEAU EN COURS..."
    $jobs = @()
    for ($i = 5; $i -le 30; $i++) {
        $ip = "${ip_reseau}${i}"
        $jobs += Start-Process -FilePath "cmd.exe" -ArgumentList "/c ping -n 1 -w 500 $ip >nul 2>&1 && echo $ip >> `"$fichier_temp`"" -WindowStyle Hidden -PassThru
    }
    $timeout = 15
    $start = Get-Date
    while (($jobs | Where-Object { -not $_.HasExited }).Count -gt 0) {
        if (((Get-Date) - $start).TotalSeconds -gt $timeout) {
            $jobs | Where-Object { -not $_.HasExited } | ForEach-Object { 
                try { $_.Kill() } catch {} 
            }
            break
        }
        Start-Sleep -Milliseconds 200
    }
    if ((Test-Path $fichier_temp) -and (Get-Item $fichier_temp).Length -gt 0) {
        $ips_brutes = Get-Content $fichier_temp -ErrorAction SilentlyContinue
        if ($script:local_ip -eq "") {
            $interfaces = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress -like "${ip_reseau}*" }
            if ($interfaces) {
                $script:local_ip = $interfaces[0].IPAddress
            }
        }
        $liste_filtree = @()
        foreach ($ip in $ips_brutes) {
            $ip_clean = $ip.Trim()
            if ($ip_clean -ne "" -and $ip_clean -ne $script:local_ip) {
                $liste_filtree += $ip_clean
            }
        }
        if ($liste_filtree.Count -eq 0) {
            Remove-Item $fichier_temp -Force -ErrorAction SilentlyContinue
            Remove-Item $fichier_noms -Force -ErrorAction SilentlyContinue
            return
        }
        foreach ($ip in $liste_filtree) {
            DetecterSysteme -ip $ip
            RecupererNomMachine -ip $ip
            $ligne = "$ip`:$($script:type_os[$ip])`:$($script:noms_machines[$ip])`:$($script:utilisateur_windows_trouve[$ip])"
            Add-Content -Path $fichier_noms -Value $ligne -ErrorAction SilentlyContinue
        }
        $contenu = Get-Content $fichier_noms -ErrorAction SilentlyContinue
        foreach ($ligne in $contenu) {
            $parts = $ligne -split ":"
            if ($parts.Count -ge 3) {
                $ip = $parts[0]
                $systeme = $parts[1]
                $nom = $parts[2]
                $utilisateur = if ($parts.Count -ge 4) { $parts[3] } else { "" }
                if ($systeme -ne "inconnu") {
                    $script:liste_ip += $ip
                    $script:type_os[$ip] = $systeme
                    $script:noms_machines[$ip] = $nom
                    if ($utilisateur -ne "") {
                        $script:utilisateur_windows_trouve[$ip] = $utilisateur
                    }
                }
            }
        }
    }
    Remove-Item $fichier_temp -Force -ErrorAction SilentlyContinue
    Remove-Item $fichier_noms -Force -ErrorAction SilentlyContinue
}

##################################################################################
#                      FONCTIONS DE CONNEXION AUX MACHINES                       #
##################################################################################

#FONCTION POUR SE CONNECTER A UNE MACHINE LINUX
function ConnexionMachineLinux {
    param([string]$ip)
    $nom_machine = $script:noms_machines[$ip]
    $utilisateur_local = $env:USERNAME
    if (-not (Test-Path $script_linux)) {
        Write-Host "Erreur : Script Linux introuvable ($script_linux)" -ForegroundColor Red
        return $false
    }
    Write-Host "Connexion a $ip *Linux*"
    SauvegarderLog "Action_ConnexionSSH_${nom_machine}_${ip}"
    $scpArgs = @("-P", $port_ssh, "-o", "StrictHostKeyChecking=no", $script_linux, "${utilisateur_linux}@${ip}:/tmp/scriptbash.sh")
    & scp $scpArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Erreur : Echec de copie du script Linux (code: $LASTEXITCODE)" -ForegroundColor Red
        return $false
    }
    $cible = "${utilisateur_linux}@${ip}"
    $commande = "sed -i 's/\r$//' /tmp/scriptbash.sh && chmod +x /tmp/scriptbash.sh && /tmp/scriptbash.sh '$utilisateur_local'; rm -f /tmp/scriptbash.sh"
    Start-Process -FilePath "ssh" -ArgumentList "-p", $port_ssh, "-t", $cible, "`"$commande`"" -NoNewWindow -Wait
    Clear-Host
    RecupererInfoLinux -ip $ip -utilisateur $utilisateur_linux
    return $true
}

#FONCTION POUR SE CONNECTER A UNE MACHINE WINDOWS
function ConnexionMachineWindows {
    param([string]$ip)
    $utilisateur = $script:utilisateur_windows_trouve[$ip]
    $nom_machine = $script:noms_machines[$ip]
    $utilisateur_local = $env:USERNAME
    if ($utilisateur -eq $null -or $utilisateur -eq "") {
        Write-Host "Recherche de l'utilisateur Windows pour $ip"
        $utilisateur = TrouverUtilisateurWindows -ip $ip
        if ($utilisateur -eq "") {
            Write-Host "Erreur : Aucun utilisateur Windows ne fonctionne en SSH sur $ip" -ForegroundColor Red
            return $false
        }
        $script:utilisateur_windows_trouve[$ip] = $utilisateur
    }
    if (-not (Test-Path $script_windows)) {
        Write-Host "Erreur : Script Windows introuvable ($script_windows)" -ForegroundColor Red
        return $false
    }
    Write-Host "Connexion a $ip (Windows - Utilisateur : $utilisateur)"
    SauvegarderLog "Action_ConnexionSSH_${nom_machine}_${ip}"
    $cible = "${utilisateur}@${ip}"
    & ssh -p $port_ssh -o BatchMode=yes $cible "cmd /c if exist %userprofile%\Documents\scriptpowershell.ps1 del /F /Q %userprofile%\Documents\scriptpowershell.ps1" 2>$null
    $scpArgs = @("-P", $port_ssh, "-o", "StrictHostKeyChecking=no", $script_windows, "${utilisateur}@${ip}:Documents/scriptpowershell.ps1")
    & scp $scpArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Erreur : Echec du transfert du script Windows" -ForegroundColor Red
        Write-Host "Verifiez les droits de l'utilisateur distant."
        return $false
    }
    Start-Process -FilePath "ssh" -ArgumentList "-p", $port_ssh, "-t", "${utilisateur}@${ip}", "`"powershell -ExecutionPolicy Bypass -File %userprofile%\Documents\scriptpowershell.ps1 -UtilisateurLocal '$utilisateur_local'`"" -NoNewWindow -Wait
    & ssh -p $port_ssh -o BatchMode=yes "${utilisateur}@${ip}" "cmd /c del /F /Q %userprofile%\Documents\scriptpowershell.ps1" 2>$null
    Clear-Host
    RecupererInfoWindows -ip $ip -utilisateur $utilisateur
    return $true
}

#FONCTION POUR SE CONNECTER A UNE MACHINE
function ConnexionMachine {
    param([string]$ip)
    $systeme = $script:type_os[$ip]
    if ($systeme -eq $null -or $systeme -eq "") {
        DetecterSysteme -ip $ip
        $systeme = $script:type_os[$ip]
    }
    if ($systeme -eq "linux") {
        return ConnexionMachineLinux -ip $ip
    } elseif ($systeme -eq "windows") {
        return ConnexionMachineWindows -ip $ip
    } else {
        return $false
    }
}

##################################################################################
#                              MENU PRINCIPAL                                    #
##################################################################################

#FONCTION POUR AFFICHER LE MENU PRINCIPAL
function MenuPrincipal {
    while ($true) {
        Clear-Host
        Write-Host "####################" -NoNewline -ForegroundColor DarkBlue
        Write-Host "##############" -NoNewline -ForegroundColor White
        Write-Host "####################" -ForegroundColor DarkRed
        Write-Host "#" -NoNewline -ForegroundColor DarkBlue
        Write-Host "                  SCRIPT_PRINCIPAL                  " -NoNewline -ForegroundColor White
        Write-Host "#" -ForegroundColor DarkRed
        Write-Host "#" -NoNewline -ForegroundColor DarkBlue
        Write-Host "                $date_actuelle|$heure_actuelle                 " -NoNewline -ForegroundColor White
        Write-Host "#" -ForegroundColor DarkRed
        Write-Host "#" -NoNewline -ForegroundColor DarkBlue
        Write-Host "                  WILD_CODE_SCHOOL                  " -NoNewline -ForegroundColor White
        Write-Host "#" -ForegroundColor DarkRed
        Write-Host "#" -NoNewline -ForegroundColor DarkBlue
        Write-Host "              SCRIPT_BY:ANIS|FRED|EROS              " -NoNewline -ForegroundColor White
        Write-Host "#" -ForegroundColor DarkRed
        Write-Host "####################" -NoNewline -ForegroundColor DarkBlue
        Write-Host "##############" -NoNewline -ForegroundColor White
        Write-Host "####################" -ForegroundColor DarkRed
        Write-Host ""
        Write-Host "1.SE CONNECTER A UNE MACHINE"
        Write-Host "Q.QUITTER"
        Write-Host "______________________________"
        Write-Host ""
        Write-Host "CHOISISSEZ UNE OPTION [1 OU Q]: " -NoNewline
        $cursorPos = $Host.UI.RawUI.CursorPosition
        Write-Host ""
        Write-Host ""
        Write-Host ""
        Write-Host ""        
        Write-Host " ██╗    ██╗██╗██╗     ██████╗      ██████╗ ██████╗ ██████╗ ███████╗" -ForegroundColor Magenta
        Write-Host " ██║    ██║██║██║     ██╔══██╗    ██╔════╝██╔═══██╗██╔══██╗██╔════╝" -ForegroundColor Magenta
        Write-Host " ██║ █╗ ██║██║██║     ██║  ██║    ██║     ██║   ██║██║  ██║█████╗  " -ForegroundColor Magenta
        Write-Host " ██║███╗██║██║██║     ██║  ██║    ██║     ██║   ██║██║  ██║██╔══╝  " -ForegroundColor Magenta
        Write-Host " ╚███╔███╔╝██║███████╗██████╔╝    ╚██████╗╚██████╔╝██████╔╝███████╗" -ForegroundColor Magenta
        Write-Host "  ╚══╝╚══╝ ╚═╝╚══════╝╚═════╝      ╚═════╝ ╚═════╝ ╚═════╝ ╚══════╝" -ForegroundColor Magenta
        Write-Host "                ███████╗ ██████╗██╗  ██╗ ██████╗  ██████╗ ██╗     " -ForegroundColor Magenta
        Write-Host "                ██╔════╝██╔════╝██║  ██║██╔═══██╗██╔═══██╗██║     " -ForegroundColor Magenta
        Write-Host "                ███████╗██║     ███████║██║   ██║██║   ██║██║     " -ForegroundColor Magenta
        Write-Host "                ╚════██║██║     ██╔══██║██║   ██║██║   ██║██║     " -ForegroundColor Magenta
        Write-Host "                ███████║╚██████╗██║  ██║╚██████╔╝╚██████╔╝███████╗" -ForegroundColor Magenta
        Write-Host "                ╚══════╝ ╚═════╝╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚══════╝" -ForegroundColor Magenta
        Write-Host ""
        $Host.UI.RawUI.CursorPosition = $cursorPos
        $choix = Read-Host
        switch ($choix) {
            "1" {
                SauvegarderLog "Navigation_MenuConnexion"
                Write-Host ""
                ScannerReseau
                if ($script:liste_ip.Count -gt 0) {
                    while ($true) {
                        Clear-Host
                        Write-Host "####################" -NoNewline -ForegroundColor DarkBlue
                        Write-Host "##############" -NoNewline -ForegroundColor White
                        Write-Host "####################" -ForegroundColor DarkRed
                        Write-Host "#" -NoNewline -ForegroundColor DarkBlue
                        Write-Host "                  SCRIPT_PRINCIPAL                  " -NoNewline -ForegroundColor White
                        Write-Host "#" -ForegroundColor DarkRed
                        Write-Host "#" -NoNewline -ForegroundColor DarkBlue
                        Write-Host "                $date_actuelle|$heure_actuelle                 " -NoNewline -ForegroundColor White
                        Write-Host "#" -ForegroundColor DarkRed
                        Write-Host "#" -NoNewline -ForegroundColor DarkBlue
                        Write-Host "                  WILD_CODE_SCHOOL                  " -NoNewline -ForegroundColor White
                        Write-Host "#" -ForegroundColor DarkRed
                        Write-Host "#" -NoNewline -ForegroundColor DarkBlue
                        Write-Host "              SCRIPT_BY:ANIS|FRED|EROS              " -NoNewline -ForegroundColor White
                        Write-Host "#" -ForegroundColor DarkRed
                        Write-Host "####################" -NoNewline -ForegroundColor DarkBlue
                        Write-Host "##############" -NoNewline -ForegroundColor White
                        Write-Host "####################" -ForegroundColor DarkRed
                        Write-Host ""
                        Write-Host "MACHINES DISPONIBLES :"
                        Write-Host ""
                        for ($i = 0; $i -lt $script:liste_ip.Count; $i++) {
                            $ip = $script:liste_ip[$i]
                            $nom = $script:noms_machines[$ip]
                            Write-Host "  $($i+1).`t$ip`t$nom"
                        }
                        Write-Host "  Q.QUITTER"
                        Write-Host ""
                        $max = $script:liste_ip.Count
                        if ($max -eq 1) {
                            $plage = "1"
                        } else {
                            $plage = "1-$max"
                        }
                        Write-Host "CHOISISSEZ UNE OPTION [$plage OU Q]: " -NoNewline
                        $cursorPos = $Host.UI.RawUI.CursorPosition                   
                        Write-Host ""
                        Write-Host ""
                        Write-Host ""
                        Write-Host ""
                        Write-Host " ██╗    ██╗██╗██╗     ██████╗      ██████╗ ██████╗ ██████╗ ███████╗" -ForegroundColor Magenta
                        Write-Host " ██║    ██║██║██║     ██╔══██╗    ██╔════╝██╔═══██╗██╔══██╗██╔════╝" -ForegroundColor Magenta
                        Write-Host " ██║ █╗ ██║██║██║     ██║  ██║    ██║     ██║   ██║██║  ██║█████╗  " -ForegroundColor Magenta
                        Write-Host " ██║███╗██║██║██║     ██║  ██║    ██║     ██║   ██║██║  ██║██╔══╝  " -ForegroundColor Magenta
                        Write-Host " ╚███╔███╔╝██║███████╗██████╔╝    ╚██████╗╚██████╔╝██████╔╝███████╗" -ForegroundColor Magenta
                        Write-Host "  ╚══╝╚══╝ ╚═╝╚══════╝╚═════╝      ╚═════╝ ╚═════╝ ╚═════╝ ╚══════╝" -ForegroundColor Magenta
                        Write-Host "                ███████╗ ██████╗██╗  ██╗ ██████╗  ██████╗ ██╗     " -ForegroundColor Magenta
                        Write-Host "                ██╔════╝██╔════╝██║  ██║██╔═══██╗██╔═══██╗██║     " -ForegroundColor Magenta
                        Write-Host "                ███████╗██║     ███████║██║   ██║██║   ██║██║     " -ForegroundColor Magenta
                        Write-Host "                ╚════██║██║     ██╔══██║██║   ██║██║   ██║██║     " -ForegroundColor Magenta
                        Write-Host "                ███████║╚██████╗██║  ██║╚██████╔╝╚██████╔╝███████╗" -ForegroundColor Magenta
                        Write-Host "                ╚══════╝ ╚═════╝╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚══════╝" -ForegroundColor Magenta
                        Write-Host ""
                        $Host.UI.RawUI.CursorPosition = $cursorPos
                        $selection = Read-Host
                        if ($selection -match '^\d+$') {
                            $selectionInt = [int]$selection
                            if ($selectionInt -ge 1 -and $selectionInt -le $script:liste_ip.Count) {
                                $ip_cible = $script:liste_ip[$selectionInt - 1]
                                if (ConnexionMachine -ip $ip_cible) {
                                    break
                                }
                            }
                            else {
                                Write-Host ""
                                Write-Host "CHOIX INVALIDE"
                                Start-Sleep -Seconds 1
                            }
                        }
                        elseif ($selection -eq "Q" -or $selection -eq "q") {
                            SauvegarderLog "Navigation_Retour"
                            break
                        }
                        else {
                            Write-Host ""
                            Write-Host "CHOIX INVALIDE"
                            Start-Sleep -Seconds 1
                        }
                    }
                }
                else {
                    Write-Host ""
                    Write-Host "AUCUNE MACHINE TROUVEE SUR LE RESEAU"
                    Write-Host "RETOUR AU MENU"
                    Start-Sleep -Seconds 1
                }
            }
            {$_ -eq "Q" -or $_ -eq "q"} {
                SauvegarderLog "EndScript"
                Write-Host ""
                Write-Host "A BIENTOT WILDER!"
                exit
            }
            default {
                Write-Host ""
                Write-Host "CHOIX INVALIDE"
                Start-Sleep -Seconds 1
            }
        }
    }
}

##################################################################################
#                        DEMARRAGE DU SCRIPT PRINCIPAL                           #
##################################################################################

InitialiserJournal
SauvegarderLog "StartScript"
if (-not (Test-Path $script_linux)) {
    Write-Host "ATTENTION : SCRIPT LINUX INTROUVABLE ($script_linux)"
}
if (-not (Test-Path $script_windows)) {
    Write-Host "ATTENTION : SCRIPT WINDOWS INTROUVABLE ($script_windows)"
}
MenuPrincipal