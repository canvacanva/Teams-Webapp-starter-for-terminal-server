# === CONFIGURATION ===
$chromePath = "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
$teamsURL   = "https://teams.microsoft.com"
$iconPath   = "C:\Icons\TeamsWebApp.ico"  # Optional: place a .ico file here

$desktopShortcut = "$env:USERPROFILE\Desktop\Teams Web App.lnk"
$menuShortcut    = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Teams Web App.lnk"
$userStartup     = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\Teams Web App.lnk"
$globalStartup   = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\Teams Web App.lnk"

# === FUNCTION: Detect VDI/Terminal Session ===
function Is-VDISession {
    $sessionName   = $env:SESSIONNAME
    $manufacturer  = (Get-WmiObject Win32_ComputerSystem).Manufacturer
    $model         = (Get-WmiObject Win32_ComputerSystem).Model

    $isRemoteSession   = $sessionName -ne "Console"
    $isVirtualMachine  = $manufacturer -match "VMware|Microsoft Corporation|Citrix|Xen" -or
                         $model -match "Virtual|VMware|VirtualBox"

    return ($isRemoteSession -or $isVirtualMachine)
}

# === FUNCTION: Create Shortcut ===
function Create-Shortcut {
    param ([string]$shortcutPath)

    if (Test-Path $shortcutPath) { return }  # Skip if already exists

    $wshell   = New-Object -ComObject WScript.Shell
    $shortcut = $wshell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath   = $chromePath
    $shortcut.Arguments    = "--app=$teamsURL"
    $shortcut.WindowStyle  = 7   # 7 = Minimized (background)
    $shortcut.Description  = "Microsoft Teams Web App"

    if (Test-Path $iconPath) {
        $shortcut.IconLocation = $iconPath
    } else {
        $shortcut.IconLocation = "$chromePath,0"
    }

    $shortcut.Save()
}

# === MAIN LOGIC ===
if (Is-VDISession) {
    if (Test-Path $chromePath) {
        # Create desktop + Start Menu shortcuts for convenience
        Create-Shortcut -shortcutPath $desktopShortcut
        Create-Shortcut -shortcutPath $menuShortcut

        # Ensure only ONE auto-launch shortcut at user level
        Create-Shortcut -shortcutPath $userStartup

        # Remove any global auto-launch shortcut to prevent double launch
        Remove-Item $globalStartup -ErrorAction SilentlyContinue
    }
}

# === CLEAN REGISTRY AUTO-LAUNCH (optional safeguard) ===
if (Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run") {
    Remove-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "Teams Web App" -ErrorAction SilentlyContinue
}
if (Test-Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run") {
    Remove-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "Teams Web App" -ErrorAction SilentlyContinue
}
