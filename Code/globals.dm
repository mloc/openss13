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

	Double message at end of round.

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

	world_message = "Welcome to SS13!"
	savefile_ver = "3"
	SS13_version = "40.93.2H9.6"
	changes = {"<FONT color='blue'><B>Changes from base version 40.93.2</B></FONT><BR>
<HR>
<p><B>Version 40.93.2H9.6</B>
<ul>
<li> Started pipelaying system, Pipe cutting/damage not yet complete.
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
	list/occupations = list( "Engineer", "Engineer", "Security Officer", "Security Officer", "Forensic Technician", "Medical Researcher", "Research Technician", "Toxin Researcher", "Atmospheric Technician", "Medical Doctor", "Station Technician", "Head of Personnel", "Head of Research", "Prison Security", "Prison Security", "Prison Doctor", "Prison Warden" )
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

world
	mob = /mob/human
	turf = /turf/space
	area = /area
	view = "15x15"

	hub = "Exadv1.spacestation13"
	hub_password = "kMZy3U5jJHSiBQjr"
	//hub = "Hobnob.SS13D"
	//hub = "Stephen001.CustomSpaceStation13"
	name = "Space Station 13"



	//visibility = 0

	//loop_checks = 0