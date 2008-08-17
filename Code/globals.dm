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
	SS13_version = "1.0 \[Development Version] - 8/17/2008"
	changes = {"<FONT color='blue'><H3>Version: [SS13_version]</H3><B>Changes from base version 1</B></FONT><BR>
<HR>
<p><B>This is a test version which hasn't been released yet, the reason being to test new bugfixes and/or features to see if they're all working without having broken anything else.
</B></p>
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
