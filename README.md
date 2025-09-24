# WinPE-Gen
## Description
Generates WinPE image for Foreman provisioning

## Requirements
- Windows
- Windows ADK (https://learn.microsoft.com/en-us/windows-hardware/get-started/adk-install)
- PowerShell with administrative rights

## Usage
1. Put drivers (.inf files) in drivers directory (optional)
2. Put updates (.msu files) in updates directory (optional)
3. Execute GenerateWinPE.ps1
4. Resulted WinPE will be in result directory
5. Use theese templates in foreman
    - Windows default finish
    - Windows default iPXE
    - Windows default provision
    - WinPE-Gen/provisioning-templates/Windows-peSetup.cmd_by-WinPE-Gen.erb (based on _Windows peSetup.cmd_ template from Foreman)
6. Copy WinPE result in your Foreman boot directory
7. Extract your Windows ISO on a file server and add it as an installation media in Foreman

___
**Author:** Sergey Malyuk
**License:** GPL
