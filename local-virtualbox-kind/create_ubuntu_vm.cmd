@Echo off
SET VMNAME=Ubuntu-2204-scripted
SET OSTYPE=Ubuntu_64
SET ISOPATH=%homepath%\Downloads\
SET ISONAME=ubuntu-22.04.3-live-server-amd64.iso
SET RAM=8096
SET VRAM=64
SET CPUCOUNT=2
SET VirtualMachinePath=%userprofile%\virtual-machines\

echo checking if the virtual machines folder exists
if exist %VirtualMachinePath% (
    echo %VirtualMachinePath% folder already exists
) else (
    mkdir %VirtualMachinePath%
)

echo checking if a download of %ISONAME% is needed
if exist %ISOPATH%\%ISONAME% (
    echo ISO file exists
) else (
    echo ISO file doesn't exist - downloading %ISONAME% to %ISOPATH%
    powershell -Command "Invoke-WebRequest https://releases.ubuntu.com/22.04.3/%ISONAME% -OutFile %ISOPATH%\%ISONAME%"
)

echo check if VirtualBox has been installed already
if exist "%ProgramFiles%\Oracle\VirtualBox\VBoxManage.exe" set "VBOXMANAGE=%ProgramFiles%\Oracle\VirtualBox\VBoxManage.exe"
if exist "%ProgramFiles%\Oracle\VirtualBox" set "VBOXGUEST=%ProgramFiles%\Oracle\VirtualBox\VBoxGuestAdditions.iso"

if not exist "%VBOXMANAGE%" (

	echo.
	echo  VirtualBox is not installed, please download and install it
	start https://www.virtualbox.org/wiki/Downloads
	echo.
	echo  If you don't have VirtualBox installed in Program Files,
	echo  simply point "VirtualBoxPath" in config.ini with your custom path
	echo.
	pause
	goto :EOF

)

echo delete the old VM
"%VBOXMANAGE%" controlvm "%VMNAME%" poweroff >nul 2>nul
"%VBOXMANAGE%" unregistervm --delete "%VMNAME%" >nul 2>nul
del /S %VirtualMachinePath%%VMNAME%

echo create a new VM
"%VBOXMANAGE%" createvm --name "%VMNAME%" --ostype "%OSTYPE%" --register >nul 2>nul
"%VBOXMANAGE%" storagectl "%VMNAME%" --name "SATA" --add sata --controller IntelAHCI --portcount 4 --bootable on

echo configure hardware settings
"%VBOXMANAGE%" modifyvm "%VMNAME%" --cpus %CPUCOUNT% --firmware efi --graphicscontroller vmsvga --pae off
"%VBOXMANAGE%" modifyvm "%VMNAME%" --memory "%RAM%" --vram "%VRAM%"
"%VBOXMANAGE%" modifyvm "%VMNAME%" --mouse ps2 --keyboard ps2 --audio-enabled off --clipboard-mode bidirectional --usb-ehci off --usb-ohci off --usb-xhci off

echo modify networking to have NAT on enp0s3 and hostonly networking on enp0s8
"%VBOXMANAGE%" modifyvm "%VMNAME%" --nic1 nat --nictype1 virtio
"%VBOXMANAGE%" modifyvm "%VMNAME%" --nic2 hostonly --nictype2 virtio --hostonlyadapter2 "VirtualBox Host-Only Ethernet Adapter"

echo modify storage to mount root device, install ISO and VBoxGuest tools
"%VBOXMANAGE%" createmedium disk --filename "%VirtualMachinePath%%VMNAME%\%VMNAME%" --size 65536 --format %FORMAT% --variant Standard
"%VBOXMANAGE%" storageattach "%VMNAME%" --storagectl "SATA" --port 1 --device 0 --type hdd --medium  "%VirtualMachinePath%%VMNAME%\%VMNAME%.vdi"
"%VBOXMANAGE%" storageattach "%VMNAME%" --storagectl "SATA" --port 2 --device 0 --type dvddrive --medium "%ISOPATH%%ISONAME%"
"%VBOXMANAGE%" storageattach "%VMNAME%" --storagectl "SATA" --port 3 --device 0 --type dvddrive --medium "autoinstall\seed.iso"
"%VBOXMANAGE%" storageattach "%VMNAME%" --storagectl "SATA" --port 4 --device 0 --type dvddrive --medium "%VBOXGUEST%"

echo start the configured VM
"%VBOXMANAGE%" startvm "%VMNAME%"

echo exit