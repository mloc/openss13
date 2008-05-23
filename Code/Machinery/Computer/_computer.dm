/*
 *	Computer -- the base computer machine
 *
 *
 *	TODO: Eventual rewrite of computer system from scratch?
 */


obj/machinery/computer
	name = "computer"
	density = 1
	anchored = 1

	// Note the icon files for computer objects should have a "broken" and "c_unpowered" state, unless the following procs are overridden.



	// Called when area power state changes
	// Display the correct icon depending on the state of the machine

	power_change()
		if(stat & BROKEN)
			icon_state = "broken"
		else
			if( powered() )							// Defaults to equipment channel
				icon_state = initial(icon_state)
				stat &= ~NOPOWER
			else
				spawn(rand(0, 15))
					src.icon_state = "c_unpowered"
					stat |= NOPOWER


	// Default timed process. Use power (as long as computer is operating)

	process()
		if(stat & (NOPOWER|BROKEN))
			return
		use_power(250)


	// Default when hit by a meteor. Break the computer, and remove any verbs.

	meteorhit(var/obj/O)
		for(var/x in src.verbs)
			src.verbs -= x
		src.icon_state = "broken"
		stat |= BROKEN


	// Default when attacked by blob. 50% change to break computer.

	blob_act()
		if (prob(50))
			for(var/x in src.verbs)
				src.verbs -= x
			src.icon_state = "broken"
			src.stat |= BROKEN
			src.density = 0


	// Default when exploded. Delete or chance to break the computer

	ex_act(severity)

		switch(severity)
			if(1.0)
				del(src)

			if(2.0)
				if (prob(50))
					for(var/x in src.verbs)
						src.verbs -= x

					src.icon_state = "broken"
					stat |= BROKEN
			if(3.0)
				if (prob(25))
					for(var/x in src.verbs)
						src.verbs -= x
					src.icon_state = "broken"
					stat |= BROKEN
