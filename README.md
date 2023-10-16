# Steam Cloud
(NAME) is a tool that aims to allow you to use Steam's built in cloud syncing feature ("Steam Cloud") for as many games as possible, and the list of games supported by this tool is ever growing.

## Adding Games
Adding games is super easy, and you can do it yourself! Just follow the steps below or use this [link](video tutorial). Get stuck? Contact me on Discord by sending a friend request to @aldin101
1. Download the projects source code
2. Open the project folder in [https://code.visualstudio.com/](Visual Studio Code) or in any other text editor (these instructions assume you are using VScode). Don't worry, you do not need to write any code in order to add support for most games. If you end up using VScode make sure to install the PowerShell extention from the extensions tab on the left side bar.
3. Once you have the project downloaded and open `.Templates` folder. If the game runs on the Unity engine then make a copy the `Unity` folder and put it outside of the templates folder. If the game does not run on the Unity engine then make a copy of the `Generic` folder and put it outside of the templates folder. If you do not know what engine the game runs on do the following. Right click the the game in Steam and press browse local files. In the game folder if you see a file named `UnityPlayer.dll` in the game folder it runs on unity, if not then it runs on a different engine, what engine does not matter in most cases so just use the generic template.
4. Rename your copied template folder to the name of the game.
5. Rename the `[GAME NAME].json` file inside of the folder to the name of the game. The file contents are unimportant right now.
6. Open the `Background.ps1` file and take a look at the top, you will see some information about your game to fill in, and instructions on how to fill them in. Fill in all of the felids except for `databaseURL` and `updateLink`. That information are only needed once your game is added to the online list. Do not mess with anything outside the quotes for each felid. When filling in information (specifically the save file location) make sure not to include computer specific information, such as your windows username. For example the path to the save file is `C:\users\Aldin101\appdata\locallow\publisher\gamename` you would want to type in `C:\users\$env:username\appdata\locallow\publisher\gamename` instead.
7. Once you have filled in all of the information, select all of the text at the top of the file until `Game specific end-----` and copy it to your clipboard.
8. Open the other files (`OfflineInstaller.ps1`, `OnlineInstaller.ps1` and `SteamCloudSync.ps1`) and paste the text you copied into the top of each of those files, replacing the empty felids already there.
9. Next you are going to want to add your files to the build config. (If you are using VS Code and installed the PowerShell extension) Open `Build.ps1`, and in the top right corner press the run button (it looks like a play icon). Then type the number 5 and press enter. Once you do that there will be a list of games, find yours and type the number next to it and press enter. It will try it's hardest to pull the correct information about the game from the files you edited, but if it gets something wrong type `n` and hit enter. Then provide the correct information. If all the information is correct type `y` and hit enter.
10. Use option 4 in the build tool to build the executables that will sync your game saves and re-patch the game when it updates (note: the game will not be able to get re-patched until the game is added to the online list). Before you start building you will need to install some third-party dependencies including ResHack and PowerShell7, just accept those automatic installs and continue on. Once those are installed type the number next the the game you are adding and hit enter. The current version is `1.0.0` so enter that for both the game launch task version and the background task version. Hit the enter key to submit the version number and them accept the admin prompt to start building. Once built you can find the executables in the `Built Executables` folder. The executables you just built won't do anything quite yet as they need to be installed.
11. Use option 3 to build the single game installer for the game you are adding, same as step 10, just select the game you are adding and hit enter. Type in `1.0.0` for the version and once built you can find the installer in the `Built Executables` folder. This installer will install the cloud sync mod and background task for the game you are adding. Simply run the installer, accept the admin prompt and follow the onscreen instructions. Once installed you can run the game from Steam as your normally would. You saves will not sync between computers without installing the tool on every computer to want to sync saves between. So make sure to put that installer onto a flashdrive and install it on another computer. Once installed your saves will be synced between the two computers, and any other computer you install it on!
12. Once you have finished setting up the game you can make a pull request to add it to the online list. To do this you will need to fork the project, make your changes, commit them and then make a pull request. If you don't know how to do this then you can watch this [video tutorial](link to video tutorial). Once you have made the pull request I will review it and if everything looks good I will merge it and your game will be added to the online list for others to enjoy. Once it is added to the online list you should disable and re-enable cloud sync using the (online installer)[link to online installer] so that the game will be re-patched whenever it updates.