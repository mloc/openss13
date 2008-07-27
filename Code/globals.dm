/* Changes

	Tobiasstrife

		DONE:

		Since Rev 106

		Built redesigned medical satelite for testing new pipe atmo control.
		Added filtered inlets and filtered/regulated vents.
			Added 5 associated filters.
			Gas specific turf_add procs.
			Filter specifc turf_take procs.
			Associated redesigned/new icons.
		Added functional pumps.
		Changed global FLOWFRAC from .05 to .99.
		Added "white" canister, aka: atmosphere reservoir.  Contains air mixture.
		Fixed typo somewhere in monkey mode win display

		TODO:

		Since Rev 106

		Remap SS13 atmo system!!
		Polish medical satelite.
		Rethink atmo reservoir
		Redesign some icons, especially for pump and reservoir
		Add new items to pipe adding/removing systems when Hobnob gets it done.


*/


/* Most recent changes (Since H9.6)

	Contining reorg of obj/machinery code
	Changed how solar panel directions are displayed, to fix the rotation display bug.

	Added remote APC control the power_monitor
	Fixed a bug where APCs would continue to draw power for cell charging even when the breaker was off.

	Added CO2 to gasbomb proc (plasmatank/proc/release())

	Moved computer objects ex_act() to base type (since all are identical)



	 (Since H9.5)

	Started pipelaying system, /obj/item/weapon/pipe.

	Added burning icon for labcoat
	Fixed a minor airsystem bug for /obj/moves
	Fixed admin toggle of mode-voting message (now reports state of allowvotemode correctly)
	Engine ejection now carries over firelevel of turfs
	Fixed bug with aux engine not working if started too quickly.

	Converted pipelines to use list exclusively, rather than numbers (so that list can be modified)
	Continues pipe laying - some checking of new lines now done, needs 2-pipe case

	Finished pipe laying - needs checking for all cases

	Updated autolathe to make pipe fittings

	Changed maximum circulator rates to give a better range of working values.
	Fixed firealarm triggering when unpowered.
	Made a temporary fix to runtime errors when blob attacks pipes (until full pipe damage system implemented).

	Code reorganization of obj/machinery continued.

*/



/*  To-do list

	Bugs:
	hearing inside closets/pods
	check head protection when hit by tank etc.


	gas progagation btwen obj/move & turfs - no flow
	due to turf/updatecell not counting /obj/moves as sources
	//firelevel lost when ejecting engine


	bug with two single-length pipes overlaying - pipeline ends up with no members

	alarm continuing when power out?



	New:

	recode obj/move stuff to use turfs exclusively?

	make regular glass melt in fire
	Blood splatters, can sample DNA & analyze
	also blood stains on clothing - attacker & defender

	whole body anaylzer in medbay - shows damage areas in popup?

	try station map maximizing use of image rather than icon

	useful world/Topic commands

	flow rate maximum for pipes - slowest of two connected notes

	system for breaking / making pipes, handle deletion, pipeline spliting/rejoining etc.


	add power-off mode for computers & other equipment (with reboot time)

	make grilles conductive for shocks (again)

	for prison warden/sec - baton allows precise targeting

	portable generator - hook to wire system

	modular repair/construction system
	maintainance key
	diagnostic tool
	modules - module construction


	hats/caps
	suit?

	build/unbuild engine floor with rf sheet

	crowbar opens airlocks when no power

*/


var

	world_message = "Welcome to OpenSS13!"
	savefile_ver = "4"
	SS13_version = "1.0 \[Development Version] - 6/21/2008"
	changes = {"<FONT color='blue'><H3>Version: [SS13_version]</H3><B>Changes from base version 40.93.2</B></FONT><BR>
<HR>
<!--
<p><B>This is a test version which hasn't been released yet, the reason being to test new bugfixes and/or features to see if they're all working without having broken anything else.
</B></p>
-->

<p><B>Version 40.93.2H9.7</B>
<ul>
<li>Merged in basically everything from http://shadowlord13.googlepages.com/openss13_b12-index.html (the person who was working on that is on the openss13 dev team now. If you're curious, that's also the person writing this particular entry in the changelog).
</li><li>Made further changes to the map, starting with that map version: moved the air tunnel north, made a hall going north to it, moved the crew arrival shuttle so it connects to that hall, so meteors can hit the part of the station it was protecting before
</li><li>The air tunnel now connects to a gauntlet of turrets leading to the AI upload room, which is in the space between the air tunnel and the rest of the station south of it.
</li><li>Moved the AI's room itself into there as well. The weapons sat has returned to being what it originally was. To get to the AI now, you would either have to go through one or more rwalls and grilles (depending on where you try to break through), or go through the turret gauntlet, and through the AI upload room and out a door on the other side of it. (Of course a sufficiently powerful bomb could probably bust through the walls, if not kill the AI, even if you plant it in the air tunnel)
</li><li>The AI still has four SMES generators, but they are charged from SS13's main power now. So, if the station loses power, the AI will probably die as well (eventually).
</li><li>Fixed an exception coming from the AI clicking an engine computer.
</li><li>Fixed exceptions from clicking things which dropped the active held item while you had someone grabbed in your active hand. If you try to click a closet with someone grabbed, you stuff them in it now. If you try to click a table or rack, you don't do anything. Previously all of these caused you to lose the grip and caused an exception (because when it told the grip to be dropped, it deleted itself, and then it tried to move null).
</li><li>Many many things which could take someone from being 'dead' to being 'unconscious' have been fixed. These were all cases where stat was being set to 1 without being checked to see if it was 2. Mind you, it wasn't terribly easy to actually resurrect someone with this, since they always immediately died again due to all the damage they had taken, but it did cause them to get (Dead) (Dead) (Dead) (Dead) spammed at the end of their corpse's name if they were thwacked repeatedly. Also, related stuff that would say they were stunned, weakened, etc, should also not happen (unless I missed some).
</li><li>Syndicate mini-station is more rectangular-ish, and the forcefield around it is more circle-ish. The forcefield is also thicker and completely encases the mini-station, making it harder to teleport inside.
</li><li>Un-nerfed meteor chance in non-meteor modes a bit ... well, it was really at 0%, so this is technically still an un-nerfing. Now it's at 0.1% chance each second.
</li><li>Added an alternate_ai_laws config variable, which gives the AI some more reasonable laws. It also has some more law adjustments when it's the traitor.
</li><li>Merged in a number of changes from the goons' svn (but not all of them - I didn't take all of them, and I probably missed a bunch because I didn't try to compare any of the code which was moved in the openss13 code reorganizations). Changes that I merged in include:
<ul><li>Anesthetic tanks have 700000 N2O and 1000000 oxygen in them now, instead of 1000 N2O and no oxygen
</li><li>Syndicate closets on the mini-station instead of stuff strewn everywhere
</li><li>Starting the syndicates in nuclear mode with a few bombs (the goons had given them four bombs and left the heater with the parts to make one or two more bombs, but I've reduced that to two bombs and removed the heater and the bomb-making parts)
</li><li>Blob dies in space and can't spread at all in the start zone or shuttles
</li><li>Map transitions west and east work properly
</li><li>A hardcoded supply station spawnpoint at 77,40,7 for Thief jack, Link43130, Hutchy2k1, Easty, and Exadv1 was removed.
</li><li>You spawn in /area/arrival/start now instead of sleep_area, and the rest of the arrival shuttle has its own area (/area/arrival/shuttle). The original sleep area is also actually in /area/sleep_area again now.
</li><li>Attacking someone with a taser gun at point-blank range uses charges and will thwack them instead of stunning if you have no charges.
</li><li>People who are disconnected have "a vacant look in their eyes" when checked with a medical analyzer.
</li><li>A fix to make the gasmask overlay not remain after death
</li><li>Stuttering is applied before HTMLizing text.
</li><li>Shuttle doors can be opened and closed by clicking them now.
</li><li>A fix for spawning without your ID
</li><li>Staff assistants have access level 3.
</li><li>Fixes to timers showing the wrong icon.
</li><li>Taser and laser gun have a maximum charges var (They have 10 each).
</li><li>I had missed the desc on the protect station module.
</li><li>Added this patch, which reduces turret firing rate and makes shots able to hit things other than the chest (which is another way of fixing the "the turret can't kill me" problem, but is probably better than the one I used). I didn't include the fix for shooting laying down people, since I think my fix for that was better than the one in this patch: http://code.google.com/p/ss13/issues/detail?id=91&colspec=ID%20Type%20Branch%20Status%20Priority%20Owner%20Summary
</ul>
</li><li>The steal-laser-pistol objective checks the charges against maximum_charges instead of 25 now.
</li><li>Prox bombs and timer bombs count for the traitor fully-heated-plasma-bomb objective now.
</li><li>In nuclear mode, there is now a 25% chance of the AI being loyal to the syndicate instead of SS13. (The SS13 personnel won't know it)
</li><li>There are now 24 solar panels at north solar, which is the same number that main solar (southwest) has (there were 12 at north solar before).
</li><li>Fixed several places (everywhere I did it) where I typo'd in an infinite loop in attack_ai calling itself when it should have been calling attack_hand instead.
</li><li>Fixed some more errors in the computers that crept in while I was merging them through the reorganizations.
</li><li>Fixed a bug which was causing the air tank dialog to not update when you switched gas flow off (so it still said 'stop gas flow' instead of 'restore gas flow').
</li><li>You shouldn't be able to knock out, stun, paralyze, etc, the AI anymore.
</li><li>Timer/igniters now actually ignite when the timer finishes.
</li><li>Added air_pressure_flow to config.txt, which, if enabled (it's disabled by default), makes a few changes to air stuff: Air pressure and temperature will affect how strongly things are pushed/pulled between tiles, and air and fire processing will occur on tiles which are adjacent to space. This is disabled by default because it would be slightly slower and the only really notable thing it does is letting tiles next to space burn.
</li><li>Added admin panel secret for making air ignite itself if it reaches a sufficient amount of oxygen (initially for testing purposes).
</li><li>Added a config var for the amount of gas needed for a fire in a tile to keep going, or for it to spread to another tile, with the config.txt variable named min_gas_for_fire. (If you're bored, change it from 900000 to 9000, start a game, and light an igniter to set the station on fire. Eventually it'll consume all the oxygen *without destroying the floors* because the temperature won't get hot enough (in most places) to harm them. Or use the air-ignites-self secret :P)
</li><li>Added a METEORCHANCE config.txt variable and fixed the meteor chance stuff. Previous attempts to put the chance below 1% per second were resulting in no meteors at all, due to BYOND's prob function not liking numbers like 0.5. (The config file's chance doesn't affect meteor mode or sandbox mode, which always have 100% and 0% respectively)
</li><li>The AI can no longer be: fed pills, handcuffed, injected with a syringe, shaken to wake up, have CPR applied, be knocked out or stunned by being struck by an air tank, eyedropped, treated with ointment, treated with a bruise pack, health-analyzed, sleepypenned, affected by flashes or flashbangs, or aggressively grabbed or strangled. Additionally, punching the AI will harm your active hand instead of harming the AI. You can still shoot it or whack it with actual objects.
</li><li>The AI has a HUD icon for power or loss thereof, a fire icon, and a damage icon. (There isn't a hud background under them, so they just float over a few tiles on the right side of the map)
</li><li>Fixed a bug: If you had flipped the main breaker off on the AI's APC, it was unable to find the APC to hack it. Now it can.
</li><li>The privs required to see links on the admin panel should match up now with the privs required to use those links. Previously it was possible - even likely for lower priv levels - that you could try to do something and the admin panel would simply ignore you (Of course, if I made a mistake and it's still broken, it will still ignore you. Er... I guess we don't want to give anyone trying to trick the system any hints or something like that).
</li><li>Deactivating cameras *should* cause anyone looking through it to get notified of the deactivation, and to then get kicked out of the camera. (This needs to be tested)
</li><li>Maintenance drones for the AI or station personnel to control (optional, see config.txt). It has the standard tools (wirecutters, crowbar, screwdriver, welder), and a gripper which is kind of like a robo-hand, for manipulating things, or picking up and carrying or using one other item, and drone control stations (for humans). There are three drones on SS13, one in a closet east of the EVA room, one in a closet attached to engine storage, and one in atmospherics in the room with all the gas tanks. There are currently two drone control stations, one in the engine room and one in southwest atmospherics (Security doesn't have one because (a) they're ridiculously easy to break into, and (b) these are maintenance drones).
</li><li>Electrician's toolboxes now have a pair of insulated gloves in them (replacing one of the coils of wires).
</li><li>You should no longer be able to open the take-off/put-on dialog on AIs (or drones).
</ul>

<p><B>Version 40.93.2H9.6</B>
<ul>
<li>Started pipelaying system, Pipe cutting/damage not yet complete.
<li>Added burning icon for labcoat
<li>Fixed a minor airsystem bug for /obj/moves
<li>Fixed admin toggle of mode-voting message (now reports state of allowvotemode correctly)
<li>Engine ejection now carries over firelevel of turfs
<li>Fixed bug with aux engine not working if started too quickly.
<li>Updated autolathe to make pipe fittings
<li>Lowererd maximum circulator rates to give a better range of working values.
<li>Fixed firealarm triggering when unpowered.
<li>Made a temporary fix to runtime errors when blob attacks pipes (until full pipe damage system implemented).
<li>Code reorganization of /obj/machinery continued.
</ul>

<p><B>Version 40.93.2H9.5</B>
<ul>
<li>Fixed a few bugs with reinforced windows.
<li>Adding turbine generator to aux. engine.
<li>Added Hikato's Sandbox mode.
<li>Fixed bug with repairing walls and cable visibility.
</ul>
<p><B>Version 40.93.2H9.4</B>
<ul>
<li>Initial version of new generator (not yet completly working). Redesigned and remapped engine and generator.
<li>T-scanners now have a chance to reveal cloakers when in range.
<li>Fire extinguishers and throwing object can be used to manoeuvre in space to a limited extent.
<li>SMESes now more user-friendly, will charge automatically if power available.
<li>Can now config so votes from dead players aren't counted.
<li>Can now config so player votes default to no vote.
<li>Players can now reply to Admin PMs.
</ul>
<p><B>Version 40.93.2H9.3</B>
<ul>
<li>Added main power storage devices (SMES). Reconfigured map power system to use them.
<li>Added backup solar power generators and added them to the map.
<li>Added custom job name assignments through the ID computer.
<li>Engine cannot be ejected now without sufficient ID access.
<li>Cable can now be directly connected from a turf to a power device (SMES, generator, etc.)
<li>Admins & above can now observe when not dead. (Now fixed).
<li>Solar panel controllers can now be set to rotate the panels at a given rate.
<li>Fixed a problem with client inactivity discounting votes much too soon.
</ul>
<p><B>Version 40.93.2H9.2</B>
<ul>
<li>Added some new admin options,
<li>Added 1st test version of engine power generator.
<li>Rewrote canister/pipework connection routines to fix a gas conservation bug.
<li>Valves don't require power to switch anymore.
<li>T-scanners can now be clipped on belts.
<li>Added a cell recharger.
<li>Some small map changes.
<li>Fixed crashes with admin Vars command.
<li>Fixed cable-cutting bug that sometimes did not update the power network.
<li>Fixed bugs when making reinforced glass.
<li>Destroyed canisters can now be disconnected from a pipe.
</ul>
<p><B>Version 40.93.2H9.1</B>
<ul>
<li>Cable item added. Cable cutting now works. Cable laying started.
<li>Fixed stacking bug with tiles, sheets etc.
<li>Newly laid cable now merges with existing powernets.
<li>Added power supply from a dummy generator object for testing. Power switching logic still buggy.
<li>Cables now affected by explosions & fire. Automatically rebuild power network when deleted.
<li>Improved power switching logic.
<li>Addeed high-capacity power cells to some key area APCs.
<li>Most machines now cannot be operated when unpowered.
<li>Made the station cable layout much more redundant. It's no long possible to disable the whole grid with a single cut.
<li>Added a monitoring computer to the engine.
<li>Canisters are now attached to a connector with a wrench (more logical than a screwdriver).
<li>It's now hazardous to cut or modify powered cable without proper protection.
<li>Grilles can now be electrified, and have a chance of shocking someone if attacked.
</ul>
<p><B>Version 40.93.2H9</B>
<ul>
<li>APC added, with test functionality. Started adding power requirements to machinery objects. (Wire system, power generators & cell charging not yet implemented.)
<li>Fixed bug with lightswitches that wouldn't turn back on.
<li>Power usage added for most machines. APCs currently running only on battery power, no way to recharge. Underfloor wire system placed but non-operational.
<li>Some background events added to Blob mode.
<li>Fixed some air propagation bugs and optimized some procedures.
<li>Power networks created, but not functional as yet.
<li>Added a scanner for underfloor wires and pipes.
<li>Modified underfloor hiding system to be more general.
</ul>
<p><B>Version 40.93.2H8</B>
<ul>
<li>Fixed bug with cryo freezer and flask changing.
<li>Fixed numerous runtime errors.
<li>Re-added nuclear mode to vote and config file.
<li>Char setup now autoloaded if your savefile exist
<li>Added reset button to char setup.
<li>Fixed move-to-top while dead.
<li>Fixed bug with voting before round begins.
<li>Fixed bug with engine ejection areas.
<li>Started work on power system. Lightswitches added to map. Area icon system updated.
<li>Fixed spawning on top of dense objects.
<li>Later enterers now get ID card access levels corresponding to their job.
</ul>
<p><B>Version 40.93.2H7.1D</B>
<ul>
<li>Total overhaul of pipework system. Circulators, manifolds, junctions, pipelines added.
<li>Heat exchange pipe added. Pipes now affect and are affected by turf temperature.
<li>Made connected canisters automatically anchored at startup.
<li>Removed redundant heat variable from turfs.
<li>Tweaked pipe-turf heat exchange to avoid thermal runaway.
<li>Added valves and vents to pipework system. Fixed gas loss problem with connectors.
<li>Added Captain specific closet and jumpsuite.
</ul>
<p><B>Version 40.93.2H7.0D</B>
<ul>
<li>Total overhaul of gas temperature system. Fixed temp. loss problem with scrubbers/vents
</ul>
<p><B>Version 40.93.2H6.4D</B>
<ul>
<li>Added player voting system for server reboot and game mode
<li>Added config options for voting system
<li>Made mode choice persistent across server reboots
<li>Removed vote delay after server reboot
<li>Tweaked pipework operation slightly
<li>Fixed bug with ID computer
<li>Added reinforced windows, reinf. glass sheets, etc.
<li>Fixed a win condition bug with location of stolen item in traitor mode
</ul>
<p><B>Version 40.93.2H6.3D</B>
<ul>
<li>Fixed firelarms so they can be sabotaged successfully
<li>"Random" mode added (like secret but actual mode is announced)
<li>Fixed more bugs with DNA-scanner
<li>Fixed cryocell bug with gas transfer
<li>Moved all testing verbs to admin-only
<li>Re-wrote damage icon system to fix standing mob image and skin tone change bugs
<li>Added external config file for logging options
<li>Enabled config of secret/random mode pick probabilities
</ul>
<p><B>Version 40.93.2H6.2D</B>
<ul>
<li>Fixed bug with floor tile stacking/use.
<li>Say/OOC now strips control characters.
<li>Fixed call error in rwall disassembly.
<li>Fixed pulling after item anchoring.
<li>Adjusted pipe/connector logic to enable pipework.
<li>Fixed background bug with certain procs.
<li>Fixed Engineer security levels in job info text.
</ul>
<p><B>Version 40.93.2H6.1D</B>
<ul><li>Airflow system changed to use cached FindTurfs (2x faster).
<li>Cell, Flow and Clear test verbs added to check airflow changes.
<li>Added Vars verb for object state checking.
<li>Current XYZ added to statpanel (for testing).
<li>Fixed score report in blob mode.
<li>Start_now added to admin commands.
<li>Partially fixed bug with standing mob image after death.
<li>Default movement speed is now run.
</ul>
<p><B>Version 40.93.2H6</B>
<ul>
<li>Timer interface auto-closes on drop.
<li>Fixed welding doors with non-active welder.
<li>Fixed self-deletion bug with bombs.
<li>Added new Blob gameplay mode.
<li>Fixed shuttle & eject positioning logic for non-default maps.
<li>Mass drivers with same ID now all fire together.
<li>Server logging of logon, logoff & OOC added.
</ul>
<p><B>Version 40.93.2H5</B>
<ul>
<li>Added move-to-top verb to sort item stacks.
<li>Gasmask, firealarm, and eject alarm overlays changed to alpha-blend textures.
<li>Doors allow empty-handed click to open (if wearing correct ID).
<li>Dedicated remote door controller added for poddoors.
<li>Poddoor icon changed.
<li>Alarm icon changed. Now reports air stats on examine.
<li>Timer/Igniter & Timer/Igniter/Plasmatank assemblies added.
<li>Bombs act as firebombs if plasma tank hole isn't bored.
<li>Fixed airflow bug with interior doors.
<li>Security computers now have minimap of station.
<li>Arm verb added to proximity detectors/assemblies.
<li>Proximity detectors fire if they bump.
<li>Timer and Motion assemblies state icons added.
<li>Meteors can now explode (sometimes).
</ul>
"}
	datum/air_tunnel/air_tunnel1/SS13_airtunnel = null
	datum/control/cellular/cellcontrol = null
	datum/control/gameticker/ticker = null
	obj/datacore/data_core = null
	obj/overlay/plmaster = null
	obj/overlay/liquidplmaster = null
	obj/overlay/slmaster = null
	going = 1.0
	master_mode = "random"//"extended"

	persistent_file = "mode.txt"

	obj/ctf_assist/ctf = null
	nuke_code = null
	poll_controller = null
	datum/engine_eject/engine_eject_control = null
	host = null
	obj/hud/main_hud = null
	obj/hud/hud2/main_hud2 = null
	ooc_allowed = 1.0
	dna_ident = 1.0
	abandon_allowed = 1.0
	enter_allowed = 1.0
	shuttle_frozen = 0.0
	prison_entered = null

	list/html_colours = new/list(0)
	list/occupations = list( "Engineer", "Engineer", "Security Officer", "Security Officer", "Forensic Technician", "Medical Researcher", "Research Technician", "Toxin Researcher", "Atmospheric Technician", "Medical Doctor", "Station Technician", "Head of Personnel", "Head of Research", "Prison Security", "Prison Security", "Prison Doctor", "Prison Warden", "AI" )
	list/assistant_occupations = list( "Technical Assistant", "Medical Assistant", "Research Assistant", "Staff Assistant" )
	list/bombers = list(  )
	list/admins = list(  )
	list/shuttles = list(  )
	list/reg_dna = list(  )
	list/banned = list(  )


        //
	shuttle_z = 10	//default
	list/monkeystart = list()
	list/blobstart = list()
	list/blobs = list()
	list/cardinal = list( NORTH, EAST, SOUTH, WEST )


	datum/station_state/start_state = null
	datum/config/config = null
	datum/vote/vote = null
	datum/sun/sun = null

	list/plines = list()
	list/gasflowlist = list()
	list/machines = list()

	list/powernets = null

	defer_powernet_rebuild = 0		// true if net rebuild will be called manually after an event

	Debug = 0	// global debug switch

	datum/debug/debugobj

	datum/moduletypes/mods = new()

	wavesecret = 0

	//airlockWireColorToIndex takes a number representing the wire color, e.g. the orange wire is always 1, the dark red wire is always 2, etc. It returns the index for whatever that wire does.
	//airlockIndexToWireColor does the opposite thing - it takes the index for what the wire does, for example AIRLOCK_WIRE_IDSCAN is 1, AIRLOCK_WIRE_POWER1 is 2, etc. It returns the wire color number.
	//airlockWireColorToFlag takes the wire color number and returns the flag for it (1, 2, 4, 8, 16, etc)
	list/airlockWireColorToFlag = RandomAirlockWires()
	list/airlockIndexToFlag
	list/airlockIndexToWireColor
	list/airlockWireColorToIndex
	list/airlockFeatureNames = list("IdScan", "Main power In", "Main power Out", "Drop door bolts", "Backup power In", "Backup power Out", "Power assist", "AI Control", "Electrify")

	numDronesInExistance = 0

world
	mob = /mob/human
	turf = /turf/space
	area = /area
	view = "15x15"

	hub = "Exadv1.spacestation13"
	hub_password = "kMZy3U5jJHSiBQjr"
	name = "Space Station 13"



	//visibility = 0

	//loop_checks = 0
