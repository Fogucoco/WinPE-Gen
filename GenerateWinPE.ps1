[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Error handling
$ErrorActionPreference = "Stop"
function Handle-Error {
    Write-Host "Something went wrong Cleaning up and exiting"
    Dism /Unmount-Image /MountDir:.tmp\WinPE_amd64\mount /Discard
    Remove-Item ".tmp" -Recurse -Force
    Read-Host "Press Enter to continue"
    Write-Error "Unknown error"
    exit 1
} trap { Handle-Error }


# Check for administrator rights
Write-Host "Checking for administrator rights"
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as an administrator"
    Read-Host "Press Enter to continue"
    exit 1
}

# Runs the ADK environment setup batch file to configure deployment tools
$adkEnvPath = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\DandISetEnv.bat"
if (-not (Test-Path $adkEnvPath)) {
    Write-Error "ADK environment setup batch file not found at '$adkEnvPath' 
Please ensure that the Windows ADK is installed (https://learn.microsoft.com/en-us/windows-hardware/get-started/adk-install)"
    Read-Host "Press Enter to continue"
    exit 1
}
Write-Host "Running ADK environment setup batch file"
# Get all environment variables set by the batch file
$envVars = cmd /c "`"$adkEnvPath`" && set" 

# Set them in the current PowerShell session
foreach ($line in $envVars) {
    if ($line -match "^(.*?)=(.*)$") {
        $name = $matches[1]
        $value = $matches[2]
        Set-Item -Path "Env:$name" -Value $value
    }
}


# Download binaries
# wget.exe existance check and download if not
Write-Host "Downloading binaries"
Write-Host "Downloading wget.exe"
if (-not (Test-Path ".\files\wget.exe")) {
    Invoke-WebRequest -Uri "https://eternallybored.org/misc/wget/1.21.4/64/wget.exe" -OutFile ".\files\wget.exe"
} else {
    Write-Host "wget.exe already exists, skipping download"
}

# sdelete.exe existance check and download if not
Write-Host "Downloading sdelete.exe"
if (-not (Test-Path ".\files\sdelete.exe")) {
    Invoke-WebRequest -Uri "https://download.sysinternals.com/files/SDelete.zip" -OutFile ".\files\SDelete.zip"
    Write-Host "Extracting SDelete.zip"
    Expand-Archive -Path ".\files\SDelete.zip" -DestinationPath ".\files" -Force
    Remove-Item ".\files\eula.txt" -ErrorAction SilentlyContinue
    Remove-Item ".\files\SDelete.zip" -ErrorAction SilentlyContinue
} else {
    Write-Host "sdelete.exe already exists, skipping download"
}


# Create WinPE mount
$winPEMountPath = ".tmp\WinPE_amd64\mount"

Write-Host "Creating WinPE directory structure"
copype amd64 .tmp\WinPE_amd64

Write-Host "Mounting WinPE image"
Dism /Unmount-Image /MountDir:.tmp\WinPE_amd64\mount /Discard # copype mounts it not the way we want, so unmounting first
Dism /Mount-Image /ImageFile:.tmp\WinPE_amd64\media\sources\boot.wim /Index:1 /MountDir:$winPEMountPath


# Customize WinPE
Write-Host "Adding WinPE-WMI package to WinPE image"
Dism /Image:$winPEMountPath /Add-Package /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-WMI.cab"

Write-Host "Copying binaries to WinPE"
copy ".\files\*.exe" $winPEMountPath\Windows\System32\

Write-Host "Creating drivers and updates directories in WinPE"
md $winPEMountPath\drivers
md $winPEMountPath\updates

Write-Host "Installing drivers to WinPE image"
Dism /Image:$winPEMountPath /Add-Driver /Driver:.\drivers /Recurse /ForceUnsigned

Write-Host "Copying drivers to WinPE"
Copy-Item -Path .\drivers\* -Destination "$winPEMountPath\drivers" -Recurse -Force -Container

Write-Host "Copying update files to WinPE"
Get-ChildItem -Path ".\updates" -Recurse -Filter *.msu | Copy-Item -Destination "$winPEMountPath\updates" -Force -Container

Write-Host "Copying startnet.cmd to WinPE"
Copy-Item -Path .\files\startnet.cmd -Destination "$winPEMountPath\Windows\System32\startnet.cmd" -Force


# Commiting changes and unmounting WinPE image
Write-Host "Committing and unmounting WinPE image"
Dism /Unmount-Image /MountDir:$winPEMountPath /Commit

# Creating result directory
md .\result\

# Downloading wimboot
Invoke-WebRequest -Uri "https://github.com/ipxe/wimboot/raw/refs/heads/master/wimboot" -OutFile ".\result\wimboot"

Write-Host "Copying result files"
Copy-Item -Path .\.tmp\WinPE_amd64\media\boot\BCD -Destination .\result\bcd
Copy-Item -Path .\.tmp\WinPE_amd64\media\boot\boot.sdi -Destination .\result\boot.sdi
Copy-Item -Path .\.tmp\WinPE_amd64\media\sources\boot.wim -Destination .\result\boot.wim

Write-Host "Cleaning up"
Dism /Cleanup-Mountpoints
Remove-Item ".tmp" -Recurse -Force

Write-Host "Bulding completed"
Read-Host "Press Enter to continue"
