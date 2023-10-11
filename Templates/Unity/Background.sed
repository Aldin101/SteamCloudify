[Version]
Class=IEXPRESS
SEDVersion=3
[Options]
PackagePurpose=InstallApp
ShowInstallProgramWindow=1
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
VersionInfo=VersionSection
[VersionSection]
FileDescription=Steam Cloud Sync Background Task
CompanyName=Aldin101
FileVersion=1.0.0
ProductVersion=1.0.0
OriginalFilename=SteamCloudBackground.exe
LegalCopyright=
ProductName=Steam Cloud Sync
InternalName=
[Strings]
InstallPrompt=
DisplayLicense=
FinishMessage=
TargetName=C:\Users\jinda\Desktop\GTTOD-Save-Editor\SteamCloud\GTTODSteamCloud.exe
FriendlyName=Cloud Sync
AppLaunched=cmd /c powershell .\Background.ps1
PostInstallCmd=<None>
AdminQuietInstCmd=
UserQuietInstCmd=
FILE0="Background.ps1"
[SourceFiles]
SourceFiles0=C:\Users\jinda\Desktop\GTTOD-Save-Editor\SteamCloud
[SourceFiles0]
%FILE0%=
