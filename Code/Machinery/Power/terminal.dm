/*
 *	Terminal -- A wiring terminal power machine.
 *
 *  A terminal does not do anything of itself. It is used to connect powernets to other power machines,
 *  either for those where direct connection is undesirable (APCs)
 *	or for those that need to be connected to two separate powernets (SMESes).
 *
 */

obj/machinery/power/terminal
	name = "terminal"
	icon_state = "term"
	desc = "An underfloor wiring terminal for power equipment"
	level = 1			// the terminal is always underfloor (level=1)
	anchored = 1
	directwired = 0		// must have a cable on same turf connecting to terminal

	var
		obj/machinery/power/master = null		// the master power machine this terminal connects to


	// Create a new terminal. The terminal is underfloor (level=1), so hide it if the floor is intact.

	// Note: terminals are auto-created when APCs are spawned
	// All cable connections go to this object instead of the APC
	// This solves the problem of having the APC in a wall yet also inside an area

	New()
		..()
		var/turf/T = src.loc
		if(level==1) hide(T.intact)


	// Hide the terminal if "i" is true.
	// Sets the terminal icon to invisible and to a faded icon_state
	// This is done so T-scanners need only changes the invisibility setting to reveal a faded terminal icon

	hide(var/i)

		if(i)
			invisibility = 101
			icon_state = "term-f"
		else
			invisibility = 0
			icon_state = "term"
