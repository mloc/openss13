/*
 *	Firedoor - a door automatically closed by the firealarm system
 *
 */

obj/machinery/door/firedoor
	name = "firedoor"
	icon = 'Door1.dmi'
	icon_state = "door0"
	opacity = 0					// Firedoors start open
	density = 0					//
	var
		blocked = null			// true if the door has been welded shut (can't be opened)


	// Standard open and close procs do not work with firedoors

	open()
		usr << "This is a remote firedoor!"


	close()
		usr << "This is a remote firedoor!"



	// Called when area power status changes. Firedoors use the ENVIRON channel.

	power_change()
		if( powered(ENVIRON) )
			stat &= ~NOPOWER
		else
			stat |= NOPOWER


	// Attack by an item
	// If a welding tool, weld the door shut (or unweld)
	// If a crowbar. open the door.

	attackby(obj/item/weapon/C, mob/user)

		src.add_fingerprint(user)
		if ((istype(C, /obj/item/weapon/weldingtool) && !( src.operating ) && src.density))
			var/obj/item/weapon/weldingtool/W = C
			if(W.welding)
				if (W.weldfuel > 2)
					W.weldfuel -= 2
				if (!( src.blocked ))
					src.blocked = 1
					src.icon_state = "doorl"
				else
					src.blocked = 0
					src.icon_state = "door1"
				return
		else
			if (!( istype(C, /obj/item/weapon/crowbar) ))
				return
		if ((src.density && !( src.blocked ) && !( src.operating )))
			spawn( 0 )
				src.operating = 1
				flick("doorc0", src)
				src.icon_state = "door0"
				sleep(15)
				src.density = 0
				src.opacity = 0
				var/turf/T = src.loc
				if (istype(T, /turf))
					T.updatecell = 1
					T.buildlinks()
				src.operating = 0


	// Called to open a firedoor
	// Play opening animation, update icon state, and update turf links

	proc/openfire()
		set src in oview(1)

		if (stat & NOPOWER) return

		if ((src.operating || src.blocked))
			return
		use_power(50, ENVIRON)
		src.operating = 1
		flick("doorc0", src)
		src.icon_state = "door0"
		sleep(15)
		src.density = 0
		src.opacity = 0
		var/turf/T = src.loc
		if (istype(T, /turf))
			T.updatecell = 1
			T.buildlinks()
		src.operating = 0


	// Called to close a firedoor.
	// Play closing animation, update icon state, and update turf links.

	proc/closefire()
		set src in oview(1)

		if (stat & NOPOWER) return

		if (src.operating)
			return
		use_power(50, ENVIRON)
		src.operating = 1
		flick("doorc1", src)
		src.icon_state = "door1"
		src.density = 1
		src.opacity = 1
		var/turf/T = src.loc
		if (istype(T, /turf))
			T.updatecell = 0
			T.buildlinks()
			T.firelevel = 0
		sleep(15)
		src.operating = 0

