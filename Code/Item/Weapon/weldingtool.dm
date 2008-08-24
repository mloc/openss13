/*
 *	Weldingtool - used for a variety of purposes, including cutting, burning, etc.
 *
 *	Uses fuel when used, can be refueled at a weldfueltank.
 */

/obj/item/weapon/weldingtool
	name = "weldingtool"
	icon_state = "welder"
	flags = 322.0
	force = 3.0
	throwforce = 5.0
	throwspeed = 5.0
	w_class = 2.0

	var/welding = 0			// true if welding (turned on)
	var/weldfuel = 20		// number of fuel units left
	var/processing = 0		// true if running a process loop


	// Note: most welding functionality is contained in the attackby() proc of the target atoms


	// Standard examine proc

	examine()
		set src in usr

		usr << "\icon[src] [src.name] contains [src.weldfuel] units of fuel left!"
		return


	// Afterattack - called by atom/DblClick() after calling src.attackby(weapon, user)
	// Use up fuel, and turn of welder if no fuel left

	afterattack(obj/O, mob/user)
		if (src.welding)
			src.weldfuel--
			if (src.weldfuel <= 0)
				usr << "\blue Need more fuel!"		// no fuel left, so set welder to off state
				src.welding = 0
				src.force = 3
				src.damtype = "brute"
				src.icon_state = "welder"
			var/turf/location = user.loc			// also ignite turf if welder was used in plasma
			if (!( istype(location, /turf) ))
				return
			location.firelevel = location.poison + 1
		return


	// Attack self - toggle between welding and not welding, if there's fuel left.
	// Note having the welder on doesn't use fuel, only when it is used on something (pilot light?)

	attack_self(mob/user)
		src.welding = !( src.welding )
		if (src.welding)
			if (src.weldfuel <= 0)
				user << "\blue Need more fuel!"
				src.welding = 0
				return 0
			user << "\blue You will now weld when you attack."
			src.force = 15
			src.damtype = "fire"
			src.icon_state = "welder1"
			spawn(0)
				process()			// run process loop to check for plasma ignition
		else
			user << "\blue Not welding anymore."
			src.force = 3
			src.damtype = "brute"
			src.icon_state = "welder"
		return


	// Process loop, spawned when turning on the welding tool
	// Every second, check whether we're on a turf or in a mob's hand
	// if so, set the local firelevel to the poison level (+1), will ignite any plasma present
	// setting "processing" variable prevents multiple loops being started for the same tool.

	proc/process()

		if(processing)		// a processing loop is already running, so don't start this one
			return			// needed so rapidly toggling a welder doesn't start multiple loops
		processing = 1

		while(welding)		// repeat while the tool is turned on

			var/turf/location = src.loc						// location of the tool

			if(ismob(location))								// if tool in contents of a mob
				var/mob/M = location

				if(M.l_hand == src || M.r_hand == src)		// if tool in a mob's hand
					location = M.loc						// update location to mob's location

			// "location" is now turf the tool is on, or turf the mob is on if it's in the mob's hands
			// note if the mob is inside something else (closet etc.), location will not be a turf, and fail the next check

			if(isturf(location))								// if located on a turf
				location.firelevel = location.poison + 1		// start a fire if plasma present

			sleep(10)		// sleep for 1 second

		processing = 0		// tool has stopped welding, so exit the loop
