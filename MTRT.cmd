@ECHO OFF
:::::::::::::::::::::::::::::::::::::::::::::
:: MTRT - Microsoft Telemetry Removal Tool ::
::         made by u/spexdi                ::
:::::::::::::::::::::::::::::::::::::::::::::
::
:::::::::::::::
:: VARIABLES :: -------------- You are welcome to edit these settings. --------- ::
:::::::::::::::

:: MTRT log File Name
	SET "MTRT_LOGFILENAME=MTRT_Log"
:: Where to save log file
:: %~1 is set so it pull log path from command switch if invoked remotely (Ex: START "" /I /B /Wait MTRT.cmd "C:\OtherPath\MTRT_Logs")
	SET "MTRT_LOGPATH=%~1"

:: MTRT data folder, where the ini files are located. Leave blank to set to current directory.
	SET "DATAFOLDER=data"

:: Dry Run - Run through script, but don't execute any jobs
:: ** Can be paired with Command Logging to generate a log of what commands will run on your system.
	SET "DRY_RUN=NO"

:: Command Logging: Logs command and it's output to log file *WARNING* May generate large log file!
:: ** Can be paired with Dry Run to skip command execution
:: SETTINGS: YES or NO
	SET "COMMAND_LOGGING=NO"

:: Folders to be cleaned and locked down
:: NOTE: A ^ is required at the end of each line except the last
:: NOTE: Windows.old contains previous installation if OS was upgraded. If you upgraded to 10 and might want to go back to 7/8, do NOT clean Windows.old folder
	SET WINTEMP=^
		%SystemDrive%\Windows.old^
		%SystemDrive%\$Windows.~BT^
		%SystemDrive%\$Windows.~WS^
		%WinDir%\System32\GWX^
		%WinDir%\System32\Tasks\Microsoft\Windows\Setup\GWXTriggers^
		%ProgramData%\Microsoft\Windows\RetailDemo^
		%WinDir%\SystemApps\Microsoft.Windows.CloudExperienceHost_cw5n1h2txyewy\RetailDemo



:: --------------------------- Don't edit anything below this line --------------------------- ::
:: Check/Get ADMIN rights
(NET FILE||(
	CD /D "%TEMP%"
	CALL :WRITE_VBS_FILE
	START /I /HIGH ElevateMTRT.vbs
	EXIT /B
))>NUL 2>&1

SETLOCAL EnableDelayedExpansion

pushd "%~dp0" & cd /d "%~dp0"

:: MTRT Version number
SET "SCRIPT_VERSION=2.5"

:: Set build date
SET BUILDDATE=2015-12-12

:: Set title
TITLE MTRT v%SCRIPT_VERSION% (%BUILDDATE%)

:: Set data folder path
SET "DATA=%~Dp0%DATAFOLDER%"

:: If no switch passed, set default log destination
	IF "%MTRT_LOGPATH%"=="" (
		set "MTRT_LOGPATH=%SYSTEMDRIVE%\Logs\MTRT"
	)

:: Set date and time for logging
FOR /F %%a IN ('WMIC OS GET LocalDateTime ^| find "."') DO SET DTS=%%a
SET CUR_DATE=%DTS:~0,4%-%DTS:~4,2%-%DTS:~6,2%

:: Set MTRT Log filename with date
SET "MTRT_LOGFILE=%MTRT_LOGFILENAME%_%DTS:~0,4%-%DTS:~4,2%-%DTS:~6,2%.Log"

:: Configure Command Logging
IF /I "%COMMAND_LOGGING%"=="YES" (
		SET "VERBOSE=>>"%MTRT_LOGPATH%\%MTRT_LOGFILE%" 2>&1"
	) ELSE (
		SET "VERBOSE=>NUL 2>&1"
)

:: Create Log dir
IF NOT EXIST "%MTRT_LOGPATH%" MKDIR "%MTRT_LOGPATH%"

:: Determine OS
FOR /F "tokens=3*" %%I IN ('REG QUERY "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /V ProductName ^| Find "ProductName"') DO (SET WIN_VER=%%I %%J)

:: OS check & set tokens for Reg.ini and KB.ini file
IF /I "%WIN_VER:~0,9%"=="Windows 7"				(set "TOKENS=1,4,5,6,7" & GOTO END_VER_CHECK)
IF /I "%WIN_VER:~0,9%"=="Windows 8"				(set "TOKENS=2,4,5,6,7" & GOTO END_VER_CHECK)
IF /I "%WIN_VER:~0,19%"=="Windows Server 2012"	(set "TOKENS=2,4,5,6,7" & GOTO END_VER_CHECK)
IF /I "%WIN_VER:~0,9%"=="Windows 1"				(set "TOKENS=3,4,5,6,7" & GOTO END_VER_CHECK)
GOTO FAIL
:END_VER_CHECK

:: Determine and set which SetACL to use
IF EXIST "%WINDIR%\SysWOW64" (set "SETACL=%DATA%\SetACL_x64.exe") else (set "SETACL=%data%\SetACL_x32.exe")

:: Get User SID
FOR /F "DELIMS= " %%A IN ('"WMIC PATH WIN32_UserAccount WHERE Name='%UserName%' GET SID"') DO (
   IF /I NOT "%%A"=="SID" (          
      SET SID=%%A
      GOTO :END_SID_LOOP
   ))
:END_SID_LOOP


:START
CD /D "%DATA%"
CALL :LOGTXT "  Start MTRT - MS Telemetry Removal %SCRIPT_VERSION%"
CALL :LOGTXT "   Logging to: %MTRT_LOGPATH%\%MTRT_LOGFILE%"

CALL :LOGTXT "   Killing Gwx / OneDrive / Windows Update Service"
CALL :LOGCMD TASKKILL /F /IM "Gwx.exe" /T
CALL :LOGCMD TASKKILL /F /IM "OneDrive.exe" /T
CALL :LOGCMD NET STOP wuauserv

CALL :LOGTXT "   Setting registry permissions"
:: Take ownership of registry folders as defined in reg.ini file
FOR /F "eol=# tokens=%TOKENS% delims=	|" %%A IN (Reg.ini) DO (
	IF /I "%%A"=="Y" (
		CALL :LOGCMD "%SETACL%" -ON "%%B" -OT REG -ACTN SETOWNER -OWNR "N:ADMINISTRATORS" -REC YES
		CALL :LOGCMD "%SETACL%" -ON "%%B" -OT REG -ACTN ACE -ACE "N:ADMINISTRATORS;P:FULL" -REC YES
	))

CALL :LOGTXT "   Disable scheduled telemtry tasks"
FOR /F "eol=# tokens=1* delims=$" %%D IN (SchedTasks.ini) DO (CALL :LOGCMD SCHTASKS /Change /Disable /TN "%%D")

CALL :LOGTXT "   Disable Remote Registry"
CALL :LOGCMD NET STOP RemoteRegistry
CALL :LOGCMD SC CONFIG RemoteRegistry START= disabled

CALL :LOGTXT "   Disable Windows Event Collector Service"
CALL :LOGCMD NET STOP Wecsvc
CALL :LOGCMD SC CONFIG Wecsvc START= disabled

CALL :LOGTXT "   Disable Windows Error Reporting Service"
CALL :LOGCMD NET STOP WerSvc
CALL :LOGCMD SC CONFIG WerSvc START= disabled

CALL :LOGTXT "   Delete Diagnostic Tracking Service"
CALL :LOGCMD NET STOP DiagTrack
CALL :LOGCMD SC CONFIG DiagTrack START= disabled
CALL :LOGCMD NET STOP diagnosticshub.standardcollector.service
CALL :LOGCMD SC CONFIG diagnosticshub.standardcollector.service START= disabled
:: Clear or create log file, then lock it down
IF NOT EXIST "%SYSTEMDRIVE%\ProgramData\Microsoft\Diagnosis\ETLLogs\AutoLogger\AutoLogger-Diagtrack-Listener.etl" (
	CALL :LOGCMD MKDIR "%SYSTEMDRIVE%\ProgramData\Microsoft\Diagnosis\ETLLogs\AutoLogger"
	)
CD /D "%SYSTEMDRIVE%\ProgramData\Microsoft\Diagnosis\ETLLogs\AutoLogger"
CALL :LOGCMD TAKEOWN /F AutoLogger-Diagtrack-Listener.etl
CALL :LOGCMD ICACLS AutoLogger-Diagtrack-Listener.etl /GRANT ADMINISTRATORS:F /Q
CALL :LOGCMD COPY /Y NUL AutoLogger-Diagtrack-Listener.etl
:: CALL :LOGCMD BREAK>AutoLogger-Diagtrack-Listener.etl
CALL :LOGCMD ICACLS AutoLogger-Diagtrack-Listener.etl /INHERITANCE:R /DENY SYSTEM:F /DENY ADMINISTRATORS:F
CD /D "%DATA%"




:: Start Window 10 Only
IF /I NOT "%WIN_VER:~0,9%"=="Windows 1" (GOTO :SKIP_10_TWEAKS)
CALL :LOGTXT "   Kill OneDrive integration"
CALL :LOGCMD TASKKILL /F /IM  Explorer.exe
CALL :LOGCMD TIMEOUT 5
CALL :LOGCMD %SystemRoot%\System32\OneDriveSetup.exe /Uninstall
CALL :LOGCMD %SystemRoot%\SysWOW64\OneDriveSetup.exe /Uninstall
:: These keys are orphaned after the OneDrive uninstallation and can be safely removed
CALL :LOGCMD REG DELETE "HKCR\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /F
CALL :LOGCMD REG DELETE "HKCR\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /F
CD /D "%USERPROFILE%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs"
CALL :LOGCMD DEL "OneDrive.lnk" /F /S /Q
FOR %%D IN ("%LOCALAPPDATA%\Microsoft\OneDrive","%USERPROFILE%\OneDrive","%PROGRAMDATA%\Microsoft OneDrive","%SYSTEMDRIVE%\OneDriveTemp") DO (
	CALL :LOGCMD TAKEOWN /F %%D /A /R /D Y
	CALL :LOGCMD ICACLS %%D /GRANT ADMINISTRATORS:F /T /Q
	CALL :LOGCMD DEL %%D /F /S /Q
	CALL :LOGCMD RMDIR %%D /S /Q
)
CD /D "%WINDIR%\WinSxS"
FOR /D %%O IN (*onedrive*) DO (
	CALL :LOGCMD TAKEOWN /F %%O /A /R /D Y
	CALL :LOGCMD ICACLS %%O /GRANT ADMINISTRATORS:F /T /Q
	CALL :LOGCMD DEL %%O /F /S /Q
	CALL :LOGCMD RMDIR %%O /S /Q
)
CALL :LOGCMD TIMEOUT 5
CALL :LOGCMD START Explorer.exe
CD /D "%DATA%"


CALL :LOGTXT "   Disable WAP Push Message Routing Service"
CALL :LOGCMD NET STOP dmwappushservice
CALL :LOGCMD SC CONFIG dmwappushservice START= disabled


CALL :LOGTXT "   Disable RetailDemo Service"
CALL :LOGCMD NET STOP RetailDemo
CALL :LOGCMD SC CONFIG RetailDemo START= disabled


CALL :LOGTXT "   Disable Xbox Live Services"
CALL :LOGCMD NET STOP XblAuthManager
CALL :LOGCMD NET STOP XblGameSave
CALL :LOGCMD NET STOP XboxNetApiSvc
CALL :LOGCMD SC CONFIG XblAuthManager START= disabled
CALL :LOGCMD SC CONFIG XblGameSave START= disabled
CALL :LOGCMD SC CONFIG XboxNetApiSvc START= disabled


:: Overly redundant keys, as we disable Wifi Sense is the main tweaks, this is just another layer
:: 893- All enabled		828- All disabled
CALL :LOGCMD REG ADD "HKLM\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\features\%SID%" /T REG_DWORD /V FeatureStates /D 828 /F
CALL :LOGCMD REG ADD "HKLM\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\features\%SID%\SocialNetworks\ABCH" /T REG_DWORD /V OptInStatus /D 0 /F
CALL :LOGCMD REG ADD "HKLM\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\features\%SID%\SocialNetworks\ABCH-SKYPE" /T REG_DWORD /V OptInStatus /D 0 /F
CALL :LOGCMD REG ADD "HKLM\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\features\%SID%\SocialNetworks\FACEBOOK" /T REG_DWORD /V OptInStatus /D 0 /F
:SKIP_10_TWEAKS



CALL :LOGTXT "   Adding registry tweaks"
CD /D "%DATA%"
FOR /F "eol=# tokens=%TOKENS% delims=	|" %%A IN (Reg.ini) DO (
	IF /I %%A==Y (
		CALL :LOGCMD REG ADD "%%B" /T %%E /V %%C /D %%D /F
	))

CALL :LOGTXT "   Blocking via Windows Firewall"
:: Read from WindowsFirewall.ini
FOR /F "eol=# tokens=1* delims=	 " %%A IN (WindowsFirewall.ini) DO (
NETSH AdvFirewall Firewall Show Rule %%A >NUL && (
		CALL :LOGCMD NETSH AdvFirewall Firewall Set Rule %%A New %%B Dir=Out Action=Block Enable=Yes
	)||(
		CALL :LOGCMD NETSH AdvFirewall Firewall Add Rule %%A %%B Dir=Out Action=Block Enable=Yes
	))


IF /I "%WIN_VER:~0,9%"=="Windows 1" (GOTO :SKIPHOSTS)
CALL :LOGTXT "   Blocking PersistentRoutes"
:: Parse PersistentRoutes.ini, skip any line starting with ; and route to 0.0.0.0
FOR /F "eol=# tokens=1*" %%E in (PersistentRoutes.ini) DO (CALL :LOGCMD ROUTE -P ADD %%E 0.0.0.0)


:: Configure HOSTS permissions and make backup
CALL :LOGTXT "   Backing up HOSTS file and applying tweaks"
CD /D "%WINDIR%\System32\drivers\etc"
CALL :LOGCMD TAKEOWN /F hosts
CALL :LOGCMD ICACLS hosts /GRANT ADMINISTRATORS:F /Q
IF EXIST "hosts*.*" (CALL :LOGCMD ATTRIB +A -H -R -S "hosts*.*")
IF EXIST "hosts" (CALL :LOGCMD COPY "hosts" "HOSTS_%CUR_DATE%.BAK" /Y)
CALL :LOGTXT "    - File HOSTS_%CUR_DATE%.BAK created."
ECHO.>>"%WINDIR%\System32\Drivers\etc\hosts"
CD /D "%DATA%"
:: Finding and adding missing HOSTS entries as defined by hosts.ini
FOR /F "eol=# tokens=1 delims=	 " %%F IN (hosts.ini) DO (
	FIND /I "0.0.0.0 %%F #" "%WINDIR%\System32\Drivers\etc\hosts" >NUL || (
		ECHO 0.0.0.0 %%F #>>"%WINDIR%\System32\Drivers\etc\hosts"
))
CALL :LOGCMD IPCONFIG /FlushDNS



:: Uninstall KB Updates
CALL :LOGTXT "   Searching and Uninstalling KB updates:"
FOR /F "skip=5 eol=# tokens=%TOKENS% delims=	|" %%A IN (KB.ini) DO (
	IF /I %%A==Y (
		TITLE MTRT v%SCRIPT_VERSION% - Searching for KB%%B
		CALL :LOGCMD WUSA /UNINSTALL /KB:%%B /NORESTART /QUIET
		IF !ERRORLEVEL!==3010 (CALL :LOGTXT "     - KB%%B uninstalled")
	))


:: Clean and lock folders
:: Clean up WINTEMP variable
FOR %%G IN (%WINTEMP:	= %) DO (
	CALL :LOGTXT "   Cleaning and locking %%G folder"
	IF EXIST "%%G" (
		CALL :LOGCMD TAKEOWN /F "%%G" /A /R /D Y
		CALL :LOGCMD ICACLS "%%G" /GRANT ADMINISTRATORS:F /T /Q
		CALL :LOGCMD DEL "%%G" /F /S /Q
		CALL :LOGCMD RMDIR "%%G" /S /Q
		)
	CALL :LOGCMD MKDIR "%%G"
	CALL :LOGCMD ATTRIB +R +S +H +I "%%G"
	CALL :LOGCMD ICACLS "%%G" /INHERITANCE:R /DENY SYSTEM:F /DENY ADMINISTRATORS:F
)


:: Attempt to hide bad KB's from Windows Update
CALL :LOGCMD NET START wuauserv
IF /I "%WIN_VER:~0,9%"=="Windows 1" (GOTO :SKIPHIDEUPDATES)
CALL :LOGTXT "   Hiding Updates (VERY SLOW, last step though)"
CD /D "%DATA%"
FOR /F "eol=# tokens=%TOKENS% delims=	|" %%A IN (KB.ini) DO (
	IF /I %%A==Y (	
		SET KB=!KB! %%B
	))
CALL :LOGTXT "     - Press CTRL_C to skip if pressed for time"
CALL :LOGCMD CSCRIPT //NOLOGO HideWindowsUpdates.vbs%KB% "%MTRT_LOGPATH%\%MTRT_LOGFILE%"
:SKIPHIDEUPDATES



:COMPLETE
CALL :LOGTXT "   All done! You should restart your PC now."
ECHO   
TIMEOUT 6
GOTO :EOF
:FAIL
TITLE MTRT - ERROR
ECHO.
ECHO   
ECHO   Error, OS not recognized or not Admin!
ECHO    - This tool is to be run on Windows 7, 8, or 10
ECHO    - Please Right-Click on this file and choose "Run as Administrator" 
TIMEOUT 6
GOTO :EOF
:WRITE_VBS_FILE
BREAK>"%TEMP%\ElevateMTRT.vbs"
ECHO:Set objShell = CreateObject("Shell.Application")>"ElevateMTRT.vbs"
ECHO:Set objWshShell = WScript.CreateObject("WScript.Shell")>>"ElevateMTRT.vbs"
ECHO:Set objWshProcessEnv = objWshShell.Environment("PROCESS")>>"ElevateMTRT.vbs"
ECHO:objShell.ShellExecute "%~DPF0", "%~1", "", "runas", 1 >>"ElevateMTRT.vbs"
EXIT /B
:LOGCMD
IF /I "%COMMAND_LOGGING%"=="YES" (
		ECHO:%CUR_DATE% %TIME%      ^> %* >>"%MTRT_LOGPATH%\%MTRT_LOGFILE%"
		IF /I "%DRY_RUN%"=="YES" EXIT /B
		%* >>"%MTRT_LOGPATH%\%MTRT_LOGFILE%" 2>&1
	) ELSE (
		IF /I "%DRY_RUN%"=="YES" EXIT /B
		%* >NUL 2>&1
)
EXIT /B
:LOGTXT
ECHO:%CUR_DATE% %TIME%  %~1 >>"%MTRT_LOGPATH%\%MTRT_LOGFILE%"
ECHO:%CUR_DATE% %TIME%  %~1
EXIT /B
:EOF
ENDLOCAL
EXIT /B