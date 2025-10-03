# Use when something failed and the main script couldn't delele the .tmp directory or
# when the script frezzes or gives errors

# Check for administrator rights
Write-Host "Checking for administrator rights"
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as an administrator"
    Read-Host "Press Enter to continue"
    exit 1
}

Write-Host "Unmounting WinPE and cleaning up"
Dism /Cleanup-Mountpoints
Dism /Unmount-Image /MountDir:.tmp\WinPE_amd64\mount /Discard
Remove-Item ".tmp" -Recurse -Force
