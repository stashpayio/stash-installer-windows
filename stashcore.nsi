# This installs two files, app.exe and logo.ico, creates a start menu shortcut, builds an uninstaller, and
# adds uninstall information to the registry for Add/Remove Programs
 
# To get started, put this script into a folder with the two files (app.exe, logo.ico, and license.rtf -
# You'll have to create these yourself) and run makensis on it
 
# If you change the names "app.exe", "logo.ico", or "license.rtf" you should do a search and replace - they
# show up in a few places.
# All the other settings can be tweaked by editing the !defines at the top of this script
!define APPNAME "Stash"
!define COMPANYNAME "Stash"
!define DESCRIPTION "Stash Core"
!define CONFIG_FOLDER "StashCore"
# These three must be integers
!define VERSIONMAJOR 0
!define VERSIONMINOR 12
!define VERSIONBUILD 3
!define VERSIONREVISION 2
!define SPROUT_PROVING_HASH "af23e521697ed69d8b8a6b9c53e48300"
!define SPROUT_VERIFYING_HASH "21e8b499aa84b5920ca0cea260074f34"
# These will be displayed by the "Click here for support information" link in "Add/Remove Programs"
# It is possible to use "mailto:" links in here to open the email client
!define HELPURL "https://github.com/stashpayio" # "Support Information" link
!define UPDATEURL "https://github.com/stashpayio" # "Product Updates" link
!define ABOUTURL "https://github.com/stashpayio" # "Publisher" link
# This is the size (in kB) of all the files copied into "Program Files"
!define INSTALLSIZE 1048576

# For running after install complete
!define MUI_FINISHPAGE_RUN
!define MUI_FINISHPAGE_RUN_TEXT "Run Stash"
!define MUI_FINISHPAGE_RUN_FUNCTION "LaunchLink"

;--------------------------------
;Interface Settings

!include "MUI2.nsh"

!insertmacro MUI_PAGE_LICENSE "License.txt"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_LANGUAGE "English"
 
RequestExecutionLevel admin ;Require admin rights on NT6+ (When UAC is turned on)
 
InstallDir "$PROGRAMFILES\${APPNAME}"
 
# rtf or txt file - remember if it is txt, it must be in the DOS text format (\r\n)
#LicenseData "license.txt"
# This will be in the installer/uninstaller's title bar
Name "${APPNAME}"
Icon "res\stash.ico"
outFile "stashcore-installer-win.exe"
 
!include LogicLib.nsh
 
!macro VerifyUserIsAdmin
UserInfo::GetAccountType
pop $0
${If} $0 != "admin" ;Require admin rights on NT4+
        messageBox mb_iconstop "Administrator rights required!"
        setErrorLevel 740 ;ERROR_ELEVATION_REQUIRED
        quit
${EndIf}
!macroend
 
function .onInit
	setShellVarContext current
	!insertmacro VerifyUserIsAdmin
functionEnd
 
section "install"
	# Files for the install directory - to build the installer, these should be in the same directory as the install script (this file)
	setOutPath $INSTDIR	  
	# Files added here should be removed by the uninstaller (see section "uninstall")
	file "bin\stash-qt.exe"
	file "bin\stashd.exe"
    file "bin\stash-cli.exe"
	file "res\stash.ico"
	file "res\stash_testnet.ico"
	# Add any other files for the install directory (license files, app data, etc) here
  
    SetOutPath "$APPDATA\ZcashParams"
    
	/* Uncommnet to make offline installer
	#file "ZcashParams\sprout-proving.key"
    #file "ZcashParams\sprout-verifying.key"
	*/

	# Download verifying key
	download_verifing_key:

	IfFileExists "$APPDATA\ZcashParams\sprout-verifying.key" check_verifing_key_hash 0	
	DetailPrint "Downloading: sprout-verifying.key..."
	inetc::get /RESUME "Resume download?" "https://z.cash/downloads/sprout-verifying.key" "$APPDATA\ZcashParams\sprout-verifying.key" /END
    Pop $0 # return value = exit code, "OK" if OK
	DetailPrint "Download status...$0"

	${If} $0 != "OK"
    	MessageBox mb_iconstop "Error downloading sprout-verifying.key. Check the internet connection and run the installer again.$\r$\n $0"
		Quit
	${EndIf}

	# Check verifying key
	# 21e8b499aa84b5920ca0cea260074f34  sprout-verifying.key
	check_verifing_key_hash:
	DetailPrint "Verifying sprout-verifying.key..."
	md5dll::GetMD5File "$APPDATA\ZcashParams\sprout-verifying.key"
  	Pop $0
    DetailPrint "sprout-verifying.key hash: [$0]"

	${If} $0 != "${SPROUT_VERIFYING_HASH}"
    	MessageBox mb_iconstop "Hash check failed for sprout-verifying.key.The installer will try and download again $\r$\n$0" ;Show cancel/error message
		Delete "$APPDATA\ZcashParams\sprout-verifying.key"
		Goto download_verifing_key
	${EndIf}
	
	# Download proving key
	download_proving_key:
	IfFileExists "$APPDATA\ZcashParams\sprout-proving.key" check_proving_key_hash 0
	DetailPrint "Downloading: sprout-proving.key..."
	inetc::get /RESUME "Resume download?" "https://z.cash/downloads/sprout-proving.key" "$APPDATA\ZcashParams\sprout-proving.key" /END
    Pop $0 # return value = exit code, "OK" if OK
	DetailPrint "Download status: $0"
	
	${If} $0 != "OK"
    	MessageBox mb_iconstop "Error downloading proving-verifying.key. Check the internet connection and run the installer again.$\r$\n $0"
		Quit
	${EndIf}

	# Check proving key
	# af23e521697ed69d8b8a6b9c53e48300  sprout-proving.key
	check_proving_key_hash:
	DetailPrint "Verifying sprout-proving.key..."
	md5dll::GetMD5File "$APPDATA\ZcashParams\sprout-proving.key"
  	Pop $0
    DetailPrint "sprout-proving.key hash: [$0]"
	${If} $0 != "${SPROUT_PROVING_HASH}"
    	MessageBox mb_iconstop "Hash check failed for sprout-proving.key. The installer will try and download again $\r$\n$0" ;Show cancel/error message
		Delete "$APPDATA\ZcashParams\sprout-proving.key"		
		Goto download_proving_key
	${EndIf}


	# Write stash config file
    SetOutPath "$APPDATA\${CONFIG_FOLDER}"
    file "stash.conf"
	# Uninstaller - See function un.onInit and section "uninstall" for configuration
	writeUninstaller "$INSTDIR\uninstall.exe"	

	# Start Menu
	createDirectory "$SMPROGRAMS\${COMPANYNAME}"
	createShortCut "$SMPROGRAMS\${COMPANYNAME}\${APPNAME}.lnk" "$INSTDIR\stash-qt.exe" "" "$INSTDIR\stash.ico"
	createShortCut "$SMPROGRAMS\${COMPANYNAME}\${APPNAME} Testnet.lnk" "$INSTDIR\stash-qt.exe" "-testnet=1" "$INSTDIR\stash_testnet.ico"
	
 
	# Registry information for add/remove programs
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "DisplayName" "${APPNAME}"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "UninstallString" "$\"$INSTDIR\uninstall.exe$\""
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "QuietUninstallString" "$\"$INSTDIR\uninstall.exe$\" /S"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "InstallLocation" "$\"$INSTDIR$\""
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "DisplayIcon" "$\"$INSTDIR\stash.ico$\""
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "Publisher" "${COMPANYNAME}"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "HelpLink" "$\"${HELPURL}$\""
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "URLUpdateInfo" "$\"${UPDATEURL}$\""
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "URLInfoAbout" "$\"${ABOUTURL}$\""
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "DisplayVersion" "${VERSIONMAJOR}.${VERSIONMINOR}.${VERSIONBUILD}.${VERSIONREVISION}"
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "VersionMajor" "${VERSIONMAJOR}"
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "VersionMinor" "${VERSIONMINOR}"
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "VersionBuild" "${VERSIONBUILD}"
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "VersionRevision" "${VERSIONREVISION}"
	# There is no option for modifying or repairing the install
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "NoModify" 1
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "NoRepair" 1
	# Set the INSTALLSIZE constant (!defined at the top of this script) so Add/Remove Programs can accurately report the size
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "EstimatedSize" ${INSTALLSIZE}
sectionEnd
 
# Uninstaller
 
function un.onInit
	SetShellVarContext current
 
	#Verify the uninstaller - last chance to back out
	MessageBox MB_OKCANCEL "Permanantly remove ${APPNAME}?" IDOK next
		Abort
	next:
	!insertmacro VerifyUserIsAdmin
functionEnd
 
section "uninstall"
 
	# Remove Start Menu launcher
	delete "$SMPROGRAMS\${COMPANYNAME}\${APPNAME}.lnk"
	delete "$SMPROGRAMS\${COMPANYNAME}\${APPNAME} Testnet.lnk" 
	# Try to remove the Start Menu folder - this will only happen if it is empty
	rmDir "$SMPROGRAMS\${COMPANYNAME}"
 
	# Remove files
	delete $INSTDIR\stash-qt.exe
    delete $INSTDIR\stash-cli.exe
	delete $INSTDIR\stashd.exe

	delete $INSTDIR\stash.ico
	delete $INSTDIR\stash_testnet.ico
 
	# Always delete uninstaller as the last action
	delete $INSTDIR\uninstall.exe
 
	# Try to remove the install directory - this will only happen if it is empty
	rmDir $INSTDIR

	#Remove config folders

	rmDir /r "$APPDATA\${CONFIG_FOLDER}\blocks"
	rmDir /r "$APPDATA\${CONFIG_FOLDER}\chainstate"
	rmDir /r "$APPDATA\${CONFIG_FOLDER}\testnet3\blocks"
	rmDir /r "$APPDATA\${CONFIG_FOLDER}\testnet3\chainstate"

 	# Remove mainnet files (does not delete wallet.dat or backups folder)
	delete "$APPDATA\${CONFIG_FOLDER}\.lock"
	delete "$APPDATA\${CONFIG_FOLDER}\banlist.dat"
	delete "$APPDATA\${CONFIG_FOLDER}\db.log"
	delete "$APPDATA\${CONFIG_FOLDER}\debug.log"
	delete "$APPDATA\${CONFIG_FOLDER}\fee_estimates.dat"
	delete "$APPDATA\${CONFIG_FOLDER}\governance.dat"
	delete "$APPDATA\${CONFIG_FOLDER}\mempool.dat"
	delete "$APPDATA\${CONFIG_FOLDER}\masternode.conf"
	delete "$APPDATA\${CONFIG_FOLDER}\mncache.dat"
	delete "$APPDATA\${CONFIG_FOLDER}\mnpayments.dat"
	delete "$APPDATA\${CONFIG_FOLDER}\netfulfilled.dat"
	delete "$APPDATA\${CONFIG_FOLDER}\peers.dat"

	# Remove testnet files
	delete "$APPDATA\${CONFIG_FOLDER}\testnet3\.lock"
	delete "$APPDATA\${CONFIG_FOLDER}\testnet3\banlist.dat"
	delete "$APPDATA\${CONFIG_FOLDER}\testnet3\db.log"
	delete "$APPDATA\${CONFIG_FOLDER}\testnet3\debug.log"
	delete "$APPDATA\${CONFIG_FOLDER}\testnet3\fee_estimates.dat"
	delete "$APPDATA\${CONFIG_FOLDER}\testnet3\governance.dat"
	delete "$APPDATA\${CONFIG_FOLDER}\testnet3\mempool.dat"
	delete "$APPDATA\${CONFIG_FOLDER}\testnet3\masternode.conf"
	delete "$APPDATA\${CONFIG_FOLDER}\testnet3\mncache.dat"
	delete "$APPDATA\${CONFIG_FOLDER}\testnet3\mnpayments.dat"
	delete "$APPDATA\${CONFIG_FOLDER}\testnet3\netfulfilled.dat"
	delete "$APPDATA\${CONFIG_FOLDER}\testnet3\peers.dat"
		 
	# Remove uninstaller information from the registry
	DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}"
sectionEnd

Function LaunchLink
  ExecShell "" "$INSTDIR\stash-qt.exe" ;Run stash
FunctionEnd