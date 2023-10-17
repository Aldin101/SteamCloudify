# Steam Cloud
(NAME) is a tool that aims to allow you to use Steam's built in cloud syncing feature ("Steam Cloud") for as many games as possible, and the list of games supported by this tool is ever growing.

## Adding Games
Adding games is super easy, and you can do it yourself! Just follow the steps below or use this [link](video tutorial). Get stuck? Contact me on Discord by sending a friend request to @aldin101
1. Download the projects source code
2. Open the project folder in [https://code.visualstudio.com/](Visual Studio Code) or in any other text editor (these instructions assume you are using VScode). Don't worry, you do not need to write any code in order to add support for most games. If you end up using VScode make sure to install the PowerShell extension from the extensions tab on the left side bar.
3. Once you have the project downloaded and open `.Templates` folder. If the game runs on the Unity engine, then make a copy of the `Unity` folder and put it outside of the templates folder. If the game does not run on the Unity engine, then make a copy of the `Generic` folder and put it outside of the templates folder. If you do not know what engine the game runs on do the following. Right click the game in Steam and press browse local files. In the game folder if you see a file named `UnityPlayer.dll` in the game folder it runs on unity, if not then it runs on a different engine, what engine does not matter in most cases so just use the generic template.
4. Rename your copied template folder to the name of the game.
5. Rename the `[GAME NAME].json` file inside of the folder to the name of the game. The file contents are unimportant right now.
6. Open the `Background.ps1` file and take a look at the top, you will see some information about your game to fill in, and instructions on how to fill them in. Fill in all of the felids except for `databaseURL` and `updateLink`. That information is only needed once your game is added to the online list. Do not mess with anything outside the quotes for each felid. When filling in information (specifically the save file location) make sure not to include computer specific information, such as your windows username. For example, the path to the save files is `C:\users\Aldin101\appdata\locallow\publisher\gamename` you would want to type in `C:\users\$env:username\appdata\locallow\publisher\gamename` instead.
7. Next you are going to want to add your files to the build config. (If you are using VS Code and installed the PowerShell extension) Open `Build.ps1`, and in the top right corner press the run button (it looks like a play icon). Then type the number 6 and press enter. Once you do that there will be a list of games, find yours and type the number next to it and press enter. It will try it's hardest to pull the correct information about the game from the files you edited, but if it gets something wrong type `n` and hit enter. Then provide the correct information. If all the information is correct type `y` and hit enter.
8. Now that the files are in the build config you are going to want to add the game specific information that you put into `Background.ps1` into the other files in the template. Simply use option 7 and select the game you are adding, the information will sync.
9. Use option 4 in the build tool to build the executables that will sync your game saves and re-patch the game when it updates (note: the game will not be able to get re-patched until the game is added to the online list). Before you start building you will need to install some third-party dependencies including ResHack and PowerShell7, just accept those automatic installs and continue on. Once those are installed type the number next the game you are adding and hit enter. The current version is `1.0.0` so enter that for both the game launch task version and the background task version. Hit the enter key to submit the version number and then accept the admin prompt to start building. Once built you can find the executables in the `Built Executables` folder. The executables you just built won't do anything quite yet as they need to be installed.
10. Use option 3 to build the single game installer for the game you are adding, same as step 10, just select the game you are adding and hit enter. Type in `1.0.0` for the version and once built you can find the installer in the `Built Executables` folder. This installer will install the cloud sync mod and background task for the game you are adding. Simply run the installer, accept the admin prompt and follow the onscreen instructions. Once installed you can run the game from Steam as your normally would. Your saves will not sync between computers without installing the tool on every computer to want to sync saves between. So make sure to put that installer onto a flash drive and install it on another computer. Once installed your saves will be synced between the two computers, and any other computer you install it on!  If the game does not launch or crashes when launched contact me on Discord for help (send a friend request to @aldin101).
11. Once you have finished setting up the game you can make a pull request to add it to the online list. To do this you will need to fork the project, make your changes, commit them and then make a pull request. If you don't know how to do this then you can watch this [video tutorial](link to video tutorial). Once you have made the pull request, I will review it and if everything looks good, I will merge it and your game will be added to the online list for others to enjoy. Once it is added to the online list you should disable and re-enable cloud sync using the (online installer)[link to online installer] so that the game will be re-patched whenever it updates.

## Additional technical information
Information about how this tool works, this information is not needed to add most games, but is here for those who are interested.
### Build Tool
- The build tool is the `Build.ps1` file in root of the project. It does a lot of things that would be time consuming to do manually or things that make adding games easier for people less familiar with the project or programming in general.
- The build database option will build the online database that the online installer uses to see available games. It also copies any built executables on your computer to the database. Once the database is built and you commit and push your changes to GitHub the GitHub pages will automatically update and the online installer will be able to see any changes to existing games or added games. This option is not reverent to most people.
- The build multi game installer option will build the online installer, when the online installer is built it will just be put in the `Multi Game Installer` folder. This option is not reverent to most people.
- The build single game installer will build an installer for a single game. You can also have it build a single game installer for all games, although each game will still get its own installer. This installer does not need connection to the internet in order to function. It is meant for testing games not on the online list yet but can also be used for preservation purposes.
- The build Steam Cloud runtime and background executables will make the executables for the `SteamCloudSync.ps1` and `Background.ps1` files. You can pick a game to build the executables for or build them for all games. These executables are useless on their own, and need to be built into a single game installer and installed before they can do anything.
- Add a new game to the build config will add entries for a new game to the `BuildTool.json` file in the root of the project folder. If you have already made a copy of a template and filled in the information for the game, you are adding then this option will automatically fill in the information for you. If you have not done that yet, then you will need to fill in the information manually. It sometimes gets the information incorrect so make sure to double check it.
- The uninstall Resource Hacker option will uninstall Resource Hacker from your computer. Because the build tool installs Resource Hacker automatically you can use this option to uninstall it if you want to. This option is only available if you have Resource Hacker installed.
### Templates
- The templates are not just files that the user can base a new game off of, but they are also used by the build tool to build a game based off a template with the `.Templates` folder, instead of the code that is contained inside the game folder. This makes the project easier to maintain as updating the code for a template will update every game based off that template.
- Game specific code and variables needs to be above the `Game specific end-----` line, all code below that line will not be used. Instead, the code in the template will be used.
- All `.ps1` files contained in a template have a template identifier on the first line. This tells the build tool what template the game is based on so that it can use the correct template for that game. If you want to add game specific code, make sure to remove the template identifier from the top of any file you are editing. This will make the build tool build executables and the online install script from the code you wrote instead of the template code. Not using a template makes that game harder for me to maintain and most games don't need custom code so please use a template when possible.
### Resources
- Each game has a `Resources` folder. All resources are game specific and not pulled from a template every build. Resources contain an icon used by all executables and version info for each executable.
- When building the Steam Cloud runtime and background executables you will be prompted for a version number for each exe. This version number is written to the version info file for that exe. The version info is then compiled by ResHack and written to the build executable. The version that you enter in the build tool is the version that will be displayed in the file properties of the built executable and the version number that will be used when it checks for updates.
### SEDs
- The SED files in the `SEDs` folder control information about what files will be packaged, the start command, among other things. The empty felids that say `[FILLED IN BY TOOL]` will be filled in by the build tool when you build an executable. Those felids are filled in on build because they contain computer specific information.