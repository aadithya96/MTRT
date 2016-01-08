MTRT - Microsoft Telemetry Removal Tool - v2.6
Author: spexdi
For Windows 7 / 8(.1) / Server 2013 /10

===========
== About ==
===========

Since Windows XP, Microsoft has implimented extremely basic telemetry, which offered Microsoft useful data feedback to help create patches and learn about hardware-software interactions, and the internet as a whole has largly ignored and accepted that. More recent versions have increased the telemetry 'feedback', but with the recent release of Windows 10 (and 8 to a degree), Microsoft has significantly stepped up their game in attempting to spy on their users. To make matters worse, they have decided to back-port Windows 10 telemetry "features" to their older OS's (Wut? I thought backporting was only a Linux thing), with random reports that they are pushing this as far back as Vista!


Microsoft Telemetry Removal Tool (or MTRT) is my attempt at an automated script that aims to eradicate and block as many of the known Microsoft telemetry features as possible. I have tried to make it as open and tanspearent as possible, and with many .ini files, the user is given the power to change entries applied without any re-coding. 

Remember: If the product is free, you are not the comsumer, you are the product!

================
== DISCLAIMER ==
================
 
1) First and formost, you run this script at your OWN PERSONAL RISK. I can personally promise there are no viruses, but any unintended consequences of running this script I take zero responsibility for.
2) Some Antivirus programs may not like this script because it edits the HOSTS file directly. Disable AV to ensure proper execution of script.
3) I have done my best to create my personal profile of what the 'ideal' settings that should be applied: I aimed this script to be run on the average Joe's PC, so some entries are locked down hardcore to stop the average "ID-10-T-ERR" from happening.
4) INI file customization is HIGHLY recommended! There is a TON to cover, I hae done my best to give a strong default, but you better review the INI files and code before you start applying this recklessly in a corporate evironment.

==============
== Features ==
==============

This tool covers many areas of the decontamination process, such as:

   - Windows Update Settings: Changed to notify but not download update, optional updates are not packaged with important updates, and PC will not auto-reboot after update.
   - Disable Gwx/Skydrive/Spynet/Telemetry
   - Disable (Or Delete) Telemetry scheduled tasks
   - Delete Diagnostic Tracking Service and attempt to lock down log file
   - Disable Remote Registry
   - Block remote Microsoft IP's via Windows firewall
   - Remove OneDrive (Windows 10)
   - Disable WER and WEC
   - Disable RetailDemo service
   - Disable xBox Live services
   - Tons of registry entries applied to help protect your privacy
   - Block hosts: Through the HOSTS file and PersistentRoutes
   - Wipe the following folders, then attempt to lock them down hard:
	-  Windows.~BT, Windows.~WS and Windows.old, GWX folders, and RetailDemo folders.
   - Remove and block evil updates: updates are uninstalled and then ignored in windows updates.

===================
== Notable Files ==
===================

MTRT.cmd									- Main script, run as Admin. There are some basic settings to edit at the top of the file.
	\data\hosts.ini							- Entries being added to HOSTS file
	\data\KB.ini							- List of KB's being removed
	\data\PersistentRoutes.ini				- Entries being added to PersistentRoutes
	\data\Reg.ini							- List of registry folders to reset permissions on, as well as entries to set
	\data\SchedTasks.ini					- List of scheduled tasks to be disabled
	\data\WindowsFirewall.ini				- Entries added to Windows Firewall

	\help\Clear PersistentRoutes.bat		- Used to clear the PersistentRoutes table if needed
	\help\Edit system HOSTS file.lnk		- Admin shortcut to edit your system HOSTS file
	\help\etc - Shortcut.lnk				- Shortcut to the HOSTS folder
	\help\ReadMe.txt						- This file

	\help\View PersistentRoutes.bat			- View your current list of PersistentRoutes installed
	\help\Win10 Router HOSTS to block.txt	- If possible, these addresses should be added to an outbound filter on your router

	C:\Logs\MTRT\MTRT_Log_***.log			- Logfile created if run as Standalone app
	
=============
== License ==
=============

ISC? AFL? GPL? What's that? I know I wrote this script for me to help my friends as a technician, and I decided to post this online to help my friends everywhere. Do what you want with this, I highly encourage you to customize the ini files, add/remove/edit/disable entries, etc. Credit would be nice, but I can't control it.

=====================
== Version History ==
=====================

07/01/2016  v2.6.1	- Fix script crash in Win10 (thank /u/nihlathar)

16/12/2015	v2.6	- Disabled any entries that may deny the user the ability to upgrade to IE10/11 in Windows 7/8 (Thanks /u/jyi786)

12/12/2015	v2.5	- More KBs added, KB.ini resorted, now 51 updates tracked!
					- Reg.ini expanded, format tweaked to better see what keys are applied to what OS
						- Office 2015/2016 Telemetry Registry keys added
					- GWX and RetailDemo folders added to lockdown list
					- ReadMe file greatly expanded: Added disclaimer, etc
					- Tweaked elevation to use VBS instead of PowerShell (thanks /u/ngai)
					- 64-bit SetACL added to package
					- Added Windows Firewall blocking (WindowsFirewall.ini)
						- Cross-referening other ini files gives me TODO IDEA #2
						- hosts_database.ini file created, currently unused
					- Tweaked hosts editing to make sure 2 entries wouldnt accidently be added to one line (Thanks /u/jyi786)
					- Changed default log directory: MTRT should now be able to run from any read-only media.

12/10/2015	v2.2	- Fix issue with script being killed during onedrive removal (thanks /u/ssjkakaroto)
					- Added router blocking txt info
					- Metro apps list removed (feature creep)

08/10/2015  v2.1	- More KBs and Reg entries added
					- HideWindowsUpdate.vbs tweaked, should hopefully run better now 

01/10/2015	v2.0	- Windows 10 support added!
					- Metro apps list added
					- Compatible with Tron_script https://www.reddit.com/r/TronScript/
					- INI files have data on which OS to apply certain settings to, you are welcome to customize and disable whatever you need, or add your own custom entries!
					- Command Logging and Dry Run features added
					- Lots of registry keys, tasks, and IPs added

19/09/2015	v1.2	- Minor typo fixes

13/09/2015	v1.1	- Added KB3065988
					- Windows.old folder cleaned
					- Diagnostic Tracking Service log file cleared and locked down
					- Added ACL.ini, hosts.ini, KB.ini, PersistentRoutes.ini, SchedTasks.ini:
					  Entries can be added or removed without having to update script
					- Windows.~BT, Windows.~WS and Windows.old folders locked down after delete
					- OS now detected, now only attempts to uninstall/hide relevant updates.
					- Massive code cleanup/tweaking
					- dmwappushservice (WiFiSense) removed (Win10)
					- HOSTS IP fix removed (No longer using Spybot Anti-Beacon, this script does more)

11/09/2015	v1.0	- Initial release

======================
== Acknowledgements ==
======================

spexdi for code compilation

thepower for his script that was used as a launchpad and tip about the acl (voat.co/v/technology/comments/459263)
qua-z for the tips on the scheduled tasks (np.reddit.com/r/pcmasterrace/comments/3g7hr0)
Colin Bowern for the Hide Windows update vbs (http://serverfault.com/a/341318)
BlockWindows for the hosts (blockwindows.wordpress.com)
Spybot Anti-Beacon: great tool, helped me catch a few reg keys that other missed (forums.spybot.info/showthread.php?72686)
Most current list of bad KB updates (techne.alaya.net/?p=12499)
**Huge thanks to Matrix Leader for an amazing list of Evil KBs, as well as IE10/11 blocking tips (http://forum.notebookreview.com/threads/updates-to-hide-to-prevent-windows-10-upgrade-disable-telemetry.780476/)
More KB's (wilderssecurity.com/threads/379151)
xvitaly & azizLIGHT for more KB's (gist.github.com/xvitaly/eafa75ed2cb79b3bd4e9)
win10-unfu**k (https://github.com/Dfkt/win10-unfuck)
Debloat-Windows-10: https://github.com/W4RH4WK/Debloat-Windows-10
GWX removal info (http://www.tweaking.com/articles/pages/remove_windows_nag_icon_to_upgrade_to_windows_10,1.html)

===============================
== Known limitations / To Do ==
===============================

 - Debating about reming the Win10-OneDrive removal portion, as it isn't 100% related to what this tool is titled to do.
 - Should I add SuperFetch to the disabled services?
 - TODO: Merge hosts,PersistentRoutes, and WindowsWall ini's into one file
	- Track Host names and their IP addesses in a more coherent database
 - A blank line is added to the HOSTS file everytime this app is run, this is to avoid 2 entries ending up on 1 line. I don't have the patience to fix this perfectly. Whatev.
 - Hiding windows updates doesn't always seem to work even when it reports it did, suggest manually checking after reboot.
   - There are reports this may be a result of Microsoft re-issuing the same KB again (v1,v2,v3, etc)
 - Knowledge of KB3088195 introcudes potential Vista telemetry, investigatibg if coverage of this script should be expanded..
 - Currently I am focusing on HOSTS/PersistentRoutes/Firewall rules/Router block lists. Help would be greatly appreciated!