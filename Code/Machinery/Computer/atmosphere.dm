/*
 *	Atmosphere -- the base type for atmosphere computers
 *
 *	Two derived types:
 *  Siphonsiwtch control the siphons and air filters/regulator in an area
 *	Mastersiphonswitch controls all areas in the world, but isn't used in current maps as it's too powerful
 *
 */


obj/machinery/computer/atmosphere
	name = "atmosphere"
	icon = 'turfs.dmi'


	// Prototype: returns the contents of the area that the computer controls
	// Used to find all the siphon objects in the controlled region

	proc/returnarea()
		return


	// The siphon switch derived type

	siphonswitch
		name = "Area Air Control"
		icon_state = "switch"
		var
			otherarea				// set this for the computer to control an area other than the one its in
									// e.g. set this to "testlab1" to control /area/testlab1
			area/area				// the area to control. Defaults to the area containing the computer, unless otherarea is set.


		// Create a siphonswitch computer
		// Set the controlled area to the containing area, or to that in the "otherarea" var if set

		New()
			..()

			spawn(5)	// wait for map to finish loading
				src.area = src.loc.loc
				if(otherarea)
					src.area = locate(text2path("/area/[otherarea]"))


		// Return the contents of the controlled area

		returnarea()
			return area.contents


		// The verbs for siphonswitch and mastersiphonswitch
		// Siphons are controlled through the reset() proc for each

		// Switch all siphons on

		verb/siphon_all()
			set src in oview(1)
			if(stat & NOPOWER)	return
			if (usr.restrained())
				return
			if (usr.stat)
				return
			usr << "Starting all siphon systems."
			for(var/obj/machinery/atmoalter/siphs/S in src.returnarea())
				S.reset(1, 0)
			src.add_fingerprint(usr)


		// Turn off all siphons

		verb/stop_all()
			set src in oview(1)
			if(stat & NOPOWER)	return
			if (usr.stat)
				return
			if (usr.restrained())
				return
			usr << "Stopping all siphon systems."
			for(var/obj/machinery/atmoalter/siphs/S in src.returnarea())
				S.reset(0, 0)
			src.add_fingerprint(usr)


		// Set all siphons to automatic mode

		verb/auto_on()
			set src in oview(1)
			if(stat & NOPOWER)	return
			if (usr.restrained())
				return
			if (usr.stat)
				return
			usr << "Starting automatic air control systems."
			for(var/obj/machinery/atmoalter/siphs/S in src.returnarea())
				S.reset(0, 1)
			src.add_fingerprint(usr)


		// Set all scrubber type siphons to	release

		verb/release_scrubbers()
			set src in oview(1)
			if (usr.restrained())
				return
			if(stat & NOPOWER)	return
			if (usr.stat)
				return
			usr << "Releasing all scrubber toxins."
			for(var/obj/machinery/atmoalter/siphs/scrubbers/S in src.returnarea())
				S.reset(-1.0, 0)
			src.add_fingerprint(usr)


		// Set all siphons to release

		verb/release_all()
			set src in oview(1)
			if(stat & NOPOWER)	return
			if (usr.stat)
				return
			if (usr.restrained())
				return
			usr << "Releasing all stored air."
			for(var/obj/machinery/atmoalter/siphs/S in src.returnarea())
				S.reset(-1.0, 0)
			src.add_fingerprint(usr)



		// The master siphon switch - controls all siphons in the world
		// Not used in current maps since it's rather too powerful

		mastersiphonswitch
			name = "Master Air Control"


			// Return the world as the contolled area

			returnarea()
				return world

