/*
 *	Igniter -- Togglable igniter, as used in the engine.
 *
 *	Sets turf location on fire if enough plasma is present
 *
 */

obj/machinery/igniter

	name = "igniter"
	icon = 'stationobjs.dmi'
	icon_state = "igniter1"
	anchored = 1.0
	var
		on = 1.0		// true if the igniter is turned on


	// Initializes the icon state

	New()
		..()
		icon_state = "igniter[on]"


	// Called if area loses/gains power
	// sets the icon_state off if no power available

	power_change()
		..()
		if(!( stat & NOPOWER) )
			icon_state = "igniter[src.on]"
		else
			icon_state = "igniter0"


	// AI attack
	attack_ai(mob/user as mob)
		return src.attack_hand(user)

	// monkey attack same as human if in monkey mode

	attack_paw(mob/user as mob)
		if ((ticker && ticker.mode == "monkey"))
			return src.attack_hand(user)


	// When attacked, toggle the igniter on/off

	attack_hand(mob/user as mob)

		..()
		add_fingerprint(user)
		if(stat & NOPOWER)	return

		use_power(50)
		src.on = !( src.on )
		src.icon_state = text("igniter[]", src.on)
		return


	// if turned on (and powered), ignite the turf if enough plasma present

	process()

		if (src.on && !(stat & NOPOWER) )
			var/turf/T = src.loc
			if (locate(/obj/move, T))
				T = locate(/obj/move, T)
			if (T.firelevel < config.min_gas_for_fire)
				T.firelevel = T.poison


