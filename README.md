# WinPE-Gen
### Description
Generates WinPE image for Foreman Windows provisioning

### Requirements
- Windows
- Windows ADK in default directory on `C:`.  
To be precise, C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\DandISetEnv.bat should exist  
https://learn.microsoft.com/en-us/windows-hardware/get-started/adk-install
- Windows PE add-on for the Windows ADK (same link above)
- PowerShell with administrative rights

### Usage
1. Put drivers (`.inf` files) in `.\drivers` directory (optional)  
It's better to put driver directories as your manufacturer provided to keep the installation queue
2. Put updates (`.msu` files) in `.\updates` directory (optional)
3. Execute `GenerateWinPE.ps1`
4. Resulted WinPE will be in `.\result` directory
5. Use theese templates in foreman
    - Windows default iPXE (already in foreman)
    - `WinPE-Gen/provisioning-templates/Windows-peSetup.cmd_by-WinPE-Gen.erb`
    - `WinPE-Gen/provisioning-templates/Windows-default-provision_by-WinPE-Gen.erb`
    - `WinPE-Gen/provisioning-templates/Windows-default-finish_by-WinPE-Gen.erb`

6. Copy WinPE result in your Windows boot directory on your Foreman server
7. Extract/mount your Windows ISO on a file server and add its address as an installation media in Foreman  

### Problem solving
- `GenerateWinPE.ps1` gives errors or freezes  
    Run `Delete-.tmp.ps1` and try again
- If you booted into WinPE and the peSetup.cmd took too short, which lead to Windows not installing
    1. `install.esd`/`install.wim` should be at `./sources` directory on your file server (installation media in foreman)
    2. Make sure your target host resolves your file server
    3. Make sure you created all of the `./provisioning-templates/` in foreman and apllied them to your OS, then pressed `Cancel build` and `Build` at your host page
- My drivers failed to install
    1. Drivers must be at least self-signed to be installed
    2. There must be `.inf` extension files
    3. Some drivers depend on others. Manufacturers provide drivers in folders organized in a specific sequence, which you should preserve
___
**Author:** Sergey Malyuk  
**License:** GPL-3.0
