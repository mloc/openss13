#define DEBUG
/*
======================================================
			DEVELOPER CHANGELOG & ToDo/Bugs
======================================================


	ToDo:
======================


- Add slight red tint to thermal/meson scanners
- Add slight green tint to meson scanners
- Add slight dark tint to sunglasses
- Add a few more jobs for PS13, and maybe for CC and Medsat.
- Work on in-game documents (Legal SOP, etc)
- Work on a background story for certain elements in the game
- Clear up the confusion about who/what controls what, etc.

- Possibly making pens double as miniture flash lights. :D
- Start the electricity systemz. Woot.
- Lighting in other stations
- Server choice for whether or not to use lighting


Bugs:
======================

-Eric Solius- [145.9]-broadcasts:  I&#39;ve noticed the station has taken some serious damage as of late. I&#39;ve begun repairs.
-Android Data says:
BUG: When you grab a monkey by it's neck, it's pixel_ values do not reset to 0 after this is cancelled
-OOC: Sapesurmak: Bloodstream Analysis located -3.8147e-06 units of rejuvenation chemicals.
-Give monkeys more emotes






===========================================================================================
=========================			CHANGELOG			===================================
===========================================================================================


============================================================
START DATE 07/02/08 	- Murrawhip
======================
Whoops, got of the habit of using these things. A lot've stuff is forgotten. :)
Changes:
=====================
- Added Close button to Engine console
- Readded Gamekits and put the cache files at ss13.blulogic.net
- Assigned icon to wrapping paper equiped
- Made left hand icon for cardboard tube and wrapping paper
- Gotten rid of the secure doors in supplies. They're a bit pointless when there's a door only a few tiles away. :)
- Fixed CPR, you naughty bug maker you. And uhh, I've made it so you can still /spam/ the message, but it won't ever give rejuvs if over 10 units already there.


======================
END DATE 07/02/08		- Murrawhip
============================================================



============================================================
START DATE 02/01/08 	- AZA
======================

Changes:
=====================
- Fixed the comms computer refresh bug.
- Removed 'Relay Satellite' Info from comms computer
- Added 'Timer' to comms computer (using time2text with ticker.timeleft)
- Added Auto-refresh on comms computer every 1 second.
- Fixed Mass Drivers - (Pods are default anchored, duh. =\)
- Fixed Chair & Mass Driver bug
- Deleted admin_chat.dm (Empty file)
- Fixed Fire Extinguisher Going through Airlocks Bug (again)
- Added 3 extra z-levels
- Moved 'SB' to Z-level 14
- The little bit with the beacon in the middle of space is now the 'comm satellite' but has no functionality. Just spruced it up with a bit of grille-age. ;p
- Removed gamekits for now (see //GAMEKIT01 and //GAMEKIT02)
- Added a 'biohazard response storage' room above Medical Research.
- Modified Medical Bay to have a table reception-type area.
- Reinforced and slightly modified Security bay.
- Modified Storage to have a table-stores feel.
- Added several tracking implants to the map in storage, for security purposes. They are hidden so as to not be abused. They have to be found! bwhaha.
- Modified Aux. Engine area.
- Fixed Rod stacking issue.
- Added 'Close' Command to Comms Console
- Actually Fixed Grilles and Rods
- Moved Staff Assistant to Start Outside Main Security Area
- Replaed the secure door with a normal door in Storage.
-

======================
END DATE 04/01/08		- AZA
============================================================

============================================================
START DATE 24/01/08 	- AZA
======================

Changes:
=====================
- Fixed the 'going through walls' thing with electrocpack.
- Fixed using Topic() when unconcious or lying down. (Made sure not to change it for Start-up menu or admin panel, etc.)
- Fixed Mass Driver firing Anchored Objects - now returns instead of firing.
- Fixed ID Consoles changing name bug.
- Lightswitches can't be broken - there's already a delay on using it in place.
- Fixed the bug where you can't send the emergency shuttle back.
- Added a backup ID assignment card to the captain's room in case a captain or HoP is not assigned. (People will have to break into the room)
- Added a '_design.dm' file for new items/systems design.
- I added a 'comms' satellite which I have placed special spawns for you and I and ID cards there. (You need to use Kate Jasden and I need to use Alex Fenning)
- Fixed fire extinguisher going through airlocks.
- Made PS13, CC, Medsat and SB truely dynamic, they can be destroyed, burnt, etc.
- Mapped areas in PS13, CC and Medsat with fire alarms and new firedoors.

======================
END DATE 26/01/08		- AZA
============================================================





============================================================
START DATE 23/01/08 	- Murrawhip
======================

Changes:
=====================
- /Actually/ fixed the closet dragging bug. :D AZA, search for "/obj/closet/MouseDrop_T" and see.
- Fixed the dead say html bug
- Fixed the headset say html bug (Your changes list liesss)
- Added UHRS.dm, just ignore it for now, the receiving server isn't set up properly yet.
- Made the dark and gas mask states brighter, it's just too darn hard to see. And with some people's monitors, they couldn't see at all.
- The room above shuttle bay had a light switch on /area/, I fixed that.



======================
END DATE 24/01/08		- Murrawhip
============================================================




============================================================
START DATE 20/01/08 	- AZA
======================

Changes:
=====================
- Can no longer pull through glass or doors.
- Added Delay on All Intents - Grab Help Hurt Disarm of 2 seconds.
- Fixed End-Of-Traitor Runtime
- Added 'maxclass' variable for storage containers. Edit this for individual
  storage containers to change the max class item they can hold.
- Revoked dead chat HTML & other HTML rights (monkey/ghost chat)
- Removed Admin Chat Panel
- Fixed chat problem in lockers and pods.
- Added Chance of Failure to Grab
- Fixed chat lag in lockers and pods.
- Added ability to turn panes of glass into shards using any tool with enough force. (gave it health)
- Added sleepy pen creation - ScrewDriver on Normal Pen, Normal Pen in Sleep Toxins, ScrewDriver on Pen.
- Fixed Fire Alarm Positions
- Free emote text range longer
- Changed spam limit to 1 message per half a second.
- Lightswitches now reflect status on other lightswitches,and also fixed to work with fire alarms etc.
- Added ID restrictions to Communications and Engine console.
- You can now turn two stacked metal rods into a metal sheet using a welder.
- Weight value for grilles now much higher. Shouldn't be effected by air movement.
- You can no longer stuff yourself into other closets - it checks for a turf location before allowing the move.
- Fixed pulling items through two windows next to your item.
- Moved doors to sort out area, closets have to have the area or they will not work with fire/lighting system
- Syringes now have residue you can't use leftover. You can eliminate this residue by injecting it back into the bottle.
- Various Grammar Fixes
- Added checks to remove ability to use some actions and objects while dead or unconcious.
- Fixed *signal- emote to only allow numerical values.
- Door glitch fixed.
- Changed the map and turf paths so that central command / PS13 can now have fires/bombs/etc. (yay)

======================
END DATE 22/01/08		- AZA
============================================================




============================================================
START DATE 18/01/08 	- Murrawhip
======================

Changes
======================
- Fixed table un/fastening with screwdriver bug
- Raised prison doctor access from 2>000 to 3>000 so that they can leave PS13
- Made ion trails, water and telesparks not clickable
- Fixed remote door controller icon
- Made fire extinguisher a normal-sized item, rather than small. They shouldn't fit in your pockets. -.-
- Traitor winning with item in right hand is screwed (May be fixed)
- Added tech_office area to technician's place
- Fixed the bug where, if in a closet, you can move into a dna scanner
- Stopped Help from popping up everytime you log in, and added a new start up message instead.





======================
END DATE 18/01/08		- Murrawhip
============================================================




============================================================
START DATE 18/01/08 	- AZA
======================

Changes
======================

- Used Alpha Transparency on All Windows, Window-Doors and Window-Security-Doors. They look so good.
- Used Alpha Transparency on some of the icons like helmets etc.
- Added a free-emote function.
- Made it so the syringe wont inject any residue under 1 unit.
- Hopefully the traitor item not being recognised has been fixed, need to test it.
- Skin Tone and Knock-Down bug has been fixed again
- When buckled to a chair, you can no longer be put into a locker
- The electric chair bug (e_chair) no longer generates a runtime error and now produces the correct equipment.
- You can now screw/unscrew a table (single only) to move it using a screwdriver
- Updated the map with minor changes including new fire doors and alpha transparency windows.
- Made some new areas and mapped them
- Made it so floor tiles can only create a 'burnt' floor tile, requiring two tiles to build a full floor tile.
- Added remote doors again
- Added lighting in again, but this time using Alpha Trasparency (Thanks for making me realise that neat new feature :D)
- Added alpha transparency for flash, flashbang and bombs.



Notes:
======================
- Dying Kits aren't actually added and adding them in means changing the way people equip uniforms and changing items around. Lets just hope they don't notice!
- I <3 Alpha Transparency, we could change the bomb and flash things using it, too. =D




======================
END DATE 18/01/08		- AZA
============================================================




============================================================
START DATE 17/01/08	- Murrawhip
=====================
-mouse opacity for areas fixed
-added transparent overlays for fire alarms, engine alarm, gas mask, and the need to wear glasses
-fixed the bug where a runtime error is sent if traitor mode is selected, and an assassination is supposed to take place, but pick() screws up because no one is 'entered' into the game
-Added in a delay thingo to stop testfire from being spammed
-Stopped areas from able to be examined and turfs(cept for walls)
-in temp.dm, I've put in a report a bug verb, just for when we host 'n stuff. it outputs to bugs.html.
-removed dumpsource



Notes
-Don't forget to fix that knock down bug caused by BYOND4
-Don't forget to redo all of those map changes. (y) :D

======================
END DATE 17/01/08		- Murrawhip
============================================================


*/