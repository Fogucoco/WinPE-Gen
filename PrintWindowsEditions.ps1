$installPath = Read-Host "Enter install.esd/.wim path (e.g., C:\path\to\install.esd)"

if (-not (Test-Path $installPath)) {
    Write-Error "The specified install.esd/.wim file does not exist."
    Read-Host "Press Enter to continue"
    exit 1
}

Dism /Get-WimInfo /WimFile:$installPath

Read-Host "Press Enter to continue"
