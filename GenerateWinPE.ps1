[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Error handling
$ErrorActionPreference = "Stop"
function Handle-Error {
    Write-Error "Something went wrong Cleaning up and exiting"
    Dism /Unmount-Image /MountDir:.tmp\WinPE_amd64\mount /Discard
    Read-Host "Press Enter to continue"
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
& $adkEnvPath


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

Write-Host "Copying driver files to WinPE"
Copy-Item -Path .\drivers\* -Destination "$winPEMountPath\drivers" -Recurse

Write-Host "Copying update files to WinPE"
Copy-Item -Path .\updates\* -Destination "$winPEMountPath\updates" -Recurse

Write-Host "Copying startnet.cmd to WinPE"
Copy-Item -Path .\startnet.cmd -Destination "$winPEMountPath\Windows\System32\startnet.cmd" -Force


# Commiting changes and unmounting WinPE image
Write-Host "Committing and unmounting WinPE image"
Dism /Unmount-Image /MountDir:$winPEMountPath /Commit
