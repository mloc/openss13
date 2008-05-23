/*
 * Solar -- Solar panel power generator machine.
 *
 *
 */

#define SOLARGENRATE 1500			// maximum power output of a single panel when it is facing exactly towards the sun

obj/machinery/power/solar
	name = "solar panel"
	desc = "A solar electrical generator."
	icon = 'power.dmi'
	icon_state = "sp_base"
	anchored = 1
	density = 1
	directwired = 1
	dir = SOUTH						// the current direction of the solar panel
	var
		id = 1						// solar_control must have matching id (and be on same powernet) to control this machine
		obscured = 0				// true if the panel is in shadow (thus does not generate power)
		sunfrac = 0					// fraction (0.0-1.0) of the maximum exposure of the solar panel to the sun
									// calculated from the relative angle of the sun and the panel

		ndir = SOUTH				// the new set direction of the panel
		turn_angle = 0				// the angle to turn through to get to the set angle; -45 or +45
		obj/machinery/power/solar_control/control		// the controller for this panel


	// Create a new solar panel
	// Search the connected powernet for a solar_control with matching ID; if found, set as the controller

	New()
		..()
		spawn(10)			// wait until sure powernets have been built
			updateicon()
			updatefrac()

			if(powernet)
				for(var/obj/machinery/power/solar_control/SC in powernet.nodes)
					if(SC.id == id)
						control = SC


	// Updates the icon for the solar panel
	// The object icon is just the base, with the panel itself being an 8-direction overlay
	// As the object direction is changed, the overlay direction will echo it

	proc/updateicon()
		src.overlays = null
		if(stat & BROKEN)
			overlays += image('power.dmi', "solar_panel-b", FLY_LAYER)
		else
			overlays += image('power.dmi', "solar_panel", FLY_LAYER)


	// Calculate the fraction of power produced by the panel
	// Depends if the panel is obscured by shadow, and the relative angle of the panel and the sun
	// The global /datum/sun/sun holds the current sun position

	proc/updatefrac()

		if(obscured)
			sunfrac = 0
			return

		var/p_angle = dir2angle(dir) - sun.angle

		if(abs(p_angle) > 90)			// if facing more than 90deg from sun, zero output
			sunfrac = 0
			return

		sunfrac = cos(p_angle)*cos(p_angle)	 // this is the fraction of the panel area which subtends the sun's output


	// Timed process. Generate power (if in sunlight), and turn the current panel angle if it is not at the set angle

	process()

		if(stat & BROKEN)
			return

		if(!obscured)
			var/sgen = SOLARGENRATE * sunfrac
			add_avail(sgen)
			if(powernet && control)
				if(control in powernet.nodes)
					control.gen += sgen			// notify the controller of how much was generated


		if(dir == ndir)						// if current angle == set angle, stop turning
			turn_angle = 0
		else									// otherwise turn
			spawn(rand(0,10))					// slight random delay is to stop all panels turning in lockstep
				dir = turn(dir, turn_angle)
				updateicon()
				updatefrac()					// update the panel icon and the fractional power production for the new angle


	// Makes the panel broken and updates the icon to the broken state
	// No way to fix panels (yet)

	proc/broken()
		stat |= BROKEN
		updateicon()


	// When hit by a meteor, break

	meteorhit()
		broken()


	// In an explosion, totally destroyed or a chance of breaking, depending on severity

	ex_act(severity)
		switch(severity)
			if(1.0)
				//SN src = null
				del(src)
				return
			if(2.0)
				if (prob(50))
					broken()
			if(3.0)
				if (prob(25))
					broken()
		return


	// Blob attack

	blob_act()
		if (prob(50))
			broken()
			src.density = 0