[Version]
Class=IEXPRESS
SEDVersion=3
[Options]
PackagePurpose=InstallApp
ShowInstallProgramWindow=0
HideExtractAnimation=1
UseLongFileName=1
InsideCompressed=0
CAB_FixedSize=0
CAB_ResvCodeSigning=0
RebootMode=N
InstallPrompt=%InstallPrompt%
DisplayLicense=%DisplayLicense%
FinishMessage=%FinishMessage%
TargetName=%TargetName%
FriendlyName=%FriendlyName%
AppLaunched=%AppLaunched%
PostInstallCmd=%PostInstallCmd%
AdminQuietInstCmd=%AdminQuietInstCmd%
UserQuietInstCmd=%UserQuietInstCmd%
SourceFiles=SourceFiles
[Strings]
InstallPrompt=
DisplayLicense=
FinishMessage=
TargetName=C:\Users\jinda\Desktop\Steam-Cloud\Multi Game Installer\SteamCloudInstaller.exe
FriendlyName=Steam Cloud Installer
AppLaunched=cmd /c powershell -NoLogo -NoProfile -ExecutionPolicy Bypass .\SteamCloudInstaller.ps1
PostInstallCmd=<None>
AdminQuietInstCmd=
UserQuietInstCmd=
FILE0="SteamCloudInstaller.ps1"
[SourceFiles]
SourceFiles0=C:\Users\jinda\Desktop\Steam-Cloud\Multi Game Installer
[SourceFiles0]
%FILE0%=