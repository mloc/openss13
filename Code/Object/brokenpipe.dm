/*
 *	Broken Pipe -- a broken pipe object
 *
 *  This object is substituted for a /obj/machinery/pipes object when it is broken
 *
 *	TODO: make removable and/or repairable
 *
 */

obj/brokenpipe
	name = "a broken pipe"
	icon = 'reg_pipe.dmi'
	icon_state = "12-b"
	anchored = 1

	var/p_dir = 0		// the p_dir or h_dir of the original pipe

	var/ptype = 0		// pipe type of orginal pipe
						// 0 = regular, 1 = h/e


	// Create a new broken pipe,

	New()
		..()
		updateicon()

	// Set the state of the brokenpipe
	// Copies data from the original pipe object

	proc/update(var/obj/machinery/pipes/P)

		ptype = 0				// defaults for regular pipe
		p_dir = P.p_dir

		if(istype(P, /obj/machinery/pipes/heat_exch))		// h/e pipe
			ptype = 1
			p_dir = P.h_dir

		level = P.level

		updateicon()



	// Update the broken pipe icon depending on the pipe dirs and type

	proc/updateicon()
		var/is

		switch(ptype)
			if(0)
				icon = 'reg_pipe.dmi'
				is = "[p_dir]-b"
			if(1)
				icon = 'heat_pipe.dmi'
				is = "[p_dir]-b"


		var/turf/T = src.loc

		if ((src.level == 1 && isturf(T) && T.intact))
			src.invisibility = 101
			is += "-f"

		else
			src.invisibility = null

		icon_state = is
		return

	// Called when a pipe is revealed or hidden when a floor tile is removed, etc.
	// Just call updateicon(), since all is handled there already

	hide(var/i)
		updateicon()


	// attack with item
	// if welder, delete the pipe

	attackby(obj/item/weapon/W, mob/user)

		if (istype(W, /obj/item/weapon/weldingtool))
			var/obj/item/weapon/weldingtool/WT = W
			if(WT.welding)

				if(WT.weldfuel > 2)
					WT.weldfuel -=2

					user.client_mob() << "\blue Removing the broken pipe. Stand still as this takes some time."
					var/turf/T = user.loc
					sleep(30)

					if ((user.loc == T && user.equipped() == W))

						del(src)
				else
					user.client_mob() << "\blue You need more welding fuel to remove the pipe."
		else
			..()
		return

// Global proc - look for a matching broken pipe
// step direction dirn from turf OT
// must match level and ptype
// returns true if found, false otherwise

proc/findbrokenpipe(var/turf/OT, var/dirn, var/lev, var/pipetype)

	var/turf/T = get_step(OT, dirn)		// look in this turf

	var/flipdir = turn(dirn,180)		// for brokenpipe matching this pdir

	for(var/obj/brokenpipe/BP in T)
		if(BP.p_dir & flipdir)
			if(BP.level == lev && BP.ptype == pipetype)
				return 1		// found a matching brokenpipe

	return 0					// found no match


