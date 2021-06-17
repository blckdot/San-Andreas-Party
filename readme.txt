/--------------------------------------------\
|San Andreas Party - Sourcecodes - 20-09-2008|
\--------------------------------------------/
http://www.sa-party.com

README CONTENTS

1. WELCOME
2. WHAT IS WHAT
3. WHAT DO YOU NEED
4. THINGS I ASK FROM YOU
5. LICENSE
6. DOCUMENTATION/FAQ/HELP
7. CREDITS/THANKS TO
8. INFORMATION

----------
1. WELCOME
----------
Hi there! Thanks for downloading San Andreas Party (sourcecodes). First of all, this is the last OFFICIAL release of San Andreas Party. I stopped with this project because lack of time and other things.

This release contains 3 San Andreas Party versions (with sourcecode) which are all 3 unstable.
- 0.3: The version with many scripting functions and which got working script functions like my race script. It works nice when you're alone ingame ( :') ), but it fails with more players due to crashes and bugs. Also, 0.3 is the only sourcecode which uses the non-dynamic actor system (which sucks).
- 0.4: Better packet structure and it was written from scratch. Don't know exactly what works and what doesn't. As far as I know it's better (but still bugs) as 0.3 but it got not as many script functions as 0.3.
- 0.5: Even better packet structure and is (again) written from scratch. Is the most incomplete version and only got basic sync (and some bugs again).

Watch out: I don't give out the sourcecode of the DirectX hook, because it's made by VRocker and I don't got his permission (and I didn't ask for it yet, may do it later) to release the sourcecode of it.

I hope you can try to combine this 3 releases and make a good working multiplayer mod.

---------------
2. WHAT IS WHAT
---------------
Every release (own folder) got 2 folders: "Client" and "Server". All versions got compiled binaries (the EXE files) and the sourcecodes are in it too.
Some files I'm going to list now aren't in every version.
Just stick with it.

CLIENT folder
> data\d3d9.dll - The DirectX hook from VRocker which brings the ingame chat onto your screen.
> data\d3dx9_34.dll - File from Microsoft to make the d3d9.dll work.
> data\main.scm - Yeah well. The mission script which communicates with the client to make the MP mod work. Open it with Sanny Builder (you should rather open main.txt with Sanny).
> data\script.img - Part of main.scm
> data\main.txt - Sourcecode of main.scm. Open with Sanny Builder so you can compile it again with it.
> data\chat.sap - Same as data\d3d9.dll.
> data\launcher.sap - EXE file which launches GTA: San Andreas for SAP.
> clean.bat - Cleans all backup files Delphi creates.
> SAPClient.dpr - The file you need to open with Delphi to edit the sourcecode.
> SAPClient.exe - The compiled client.
SERVER folder
> scripts\*.* - Scripts/gamemodes for SAP (open with Notepad). Can be both *.sap and/or *.script , depends on SAP version.
> clean.bat - Cleans all backup files Delphi creates.
> bans.lst - The banlist (0.3 only).
> SAPServer.dpr - The file you need to open with Delphi to edit the sourcecode.
> SAPServer.exe - The compiled server.
> settings.ini - Server settings like server name, port etc. etc. (open with Notepad).

-------------------
3. WHAT DO YOU NEED
-------------------
To edit the client and/or server you need Borland Delphi 7 Enterprise (other Delphi version won't work).
With the following (free) custom components installed:
- PascalScript ( http://www.remobjects.com/download.asp?id={A6BA09DE-0384-4157-AAB0-EF9A3D2BE165}&nodownloadinfo=now )
- JCL ( http://downloads.sourceforge.net/jcl/jcl-1.102.1.3072.zip?modtime=1217368323&big_mirror=0 )
- JVCL ( http://sourceforge.net/project/showfiles.php?group_id=45786&package_id=42327&release_id=625271 )

Also, I've commented the sourcecode in both Dutch & English. Use Google Translate or whatever to translate it if you want to.


------------------------
4. THINGS I ASK FROM YOU
------------------------
You can do anything with the sourcecode. All I ask from you is to keep my (nick)name onto the client and server (in the credits/thanks to place or whatever).

That's all I ask from you :) .

----------
5. LICENSE
----------
Before using, editing and/or sharing this awesome piece of software. Make sure you accept the EULA/license that can be found in "license.txt".
If you don't accept it. Please uninstall the software and sourcecodes.

-------------------------
6. DOCUMENTATION/FAQ/HELP
-------------------------
If you need help on editing SAP or getting it work. Try to ask your question on the forums.

>>> http://www.sa-party.com <<<

--------------------
7. CREDITS/THANKS TO
--------------------
I would like to thank some people. Please respect them since they all me helped with the project.

- Mount: Developing SAP with me (sometimes).
- VRocker: Created DirectX hook (ingame chat).
- Sebihunter: Being an awesome guy and testing SAP :D
- MrJax: Helping me out with some stuff.
- Killerkid: Testing SAP a lot (your ping still sucks Killerkid).
- AlienX: (Also) helping me out with some stuff. AlienX rocks :) .
- Sacky: Can't remember why... Something with scripting functions.
- Peter: Being a nice guy and helping me out with memory adresses.
- TommyLR: The italian one :P . Thanks for testing!
- mabako: Being first nice. And afterwards a strange guy / retard.
- tomozj: Oh hai! Thanks for everything...
- SiLvEr: Sometimes you are in the betateam and sometimes you aren't :P .
- UZI-I: Nice guy... thanks for testing and such.
- JGuntherS: Helping me out all the time and did the SCM work in de 0.1/0.2 stages of SAP.
- GTAModding.com/GTANet/GTAForums.com: For the great Memory Adresses Wiki page and memory adresses forum thread/topic :> .
- Fl@sh: Designing the forum header/logo.
- Mr-Green.nl: My gaming community lolz
- You: For downloading this. I hope you can continue with this awesome piece of server xD .


--------------
8. INFORMATION
--------------
San Andreas Party 0.2 0.3, 0.4 and 0.5 sourcecodes (release date: 20-09-2008)
© 2008 Xoti Software
http://www.xoti.net

Created by: Jarno "Ywa" Veuger
WWW: http://www.sa-party.com/
E-mail: jarno@veuger.nl
MSN: msn@jarnoveuger.nl

ONLY DUTCH (NOT DEUTSCH) AND ENGLISH E-MAILS PLEASE!