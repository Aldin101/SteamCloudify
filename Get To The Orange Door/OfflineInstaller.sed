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
TargetName=C:\Users\jinda\Desktop\Steam-Cloud\file.exe
FriendlyName=Steam Cloud Offline Installer
AppLaunched=cmd /c powershell -NoLogo -NoProfile -ExecutionPolicy Bypass ./OfflineInstaller.ps1
PostInstallCmd=<None>
AdminQuietInstCmd=
UserQuietInstCmd=
FILE0="SteamCloudBackground.exe"
FILE1="SteamCloudSync.exe"
FILE2="OfflineInstaller.ps1"
[SourceFiles]
SourceFiles0=C:\Users\jinda\Desktop\Steam-Cloud\Get To The Orange Door\
[SourceFiles0]
%FILE0%=
%FILE1%=
%FILE2%=