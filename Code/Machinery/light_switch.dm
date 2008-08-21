/*
 *	Light_switch -  Controls the lighting of an area
 *					Can have multiple switches per area, they will interact correctly
 *					Set the "otherarea" var to control the lighting of a remote area (non-loc)
 */


obj/machinery/light_switch
	desc = "A light switch"
	name = null
	icon = 'power.dmi'
	icon_state = "light1"
	anchored = 1.0
	layer = 3.1
	var
		on = 1					// true if currently switched on
		area/area = null		// holds the area object that this switch controls
		otherarea = null		// By default, the switch controls the area it is located in.
								// By setting this string, the switch will control the area
								// matching the path "/area/(otherarea)"
								// this allows remote light switches located outside the area controlled (e.g. brig)


	// Create a new switch

	New()
		..()
		spawn(5) 							// wait for world to completely load
			src.area = src.loc.loc			// by default, switch contains the area it is in

			if(otherarea)					// setting this var to control a different area
				src.area = locate(text2path("/area/[otherarea]"))

			if(!name)
				name = "light switch ([area.name])"

			src.on = src.area.lightswitch	// default on/off state is set by the area vars
			updateicon()


	// Update the icon state to on, off, or unpowered

	proc/updateicon()
		if(stat & NOPOWER)
			icon_state = "light-p"
		else
			if(on)
				icon_state = "light1"
			else
				icon_state = "light0"


	// Examine verb

	examine()
		set src in oview(1)
		if(usr && !usr.stat)
			usr.client_mob() << "A light switch. It is [on? "on" : "off"]."


	// Monkey interact same as human

	attack_paw(mob/user)
		src.attack_hand(user)


	// Interact, switch the switch

	attack_hand(mob/user)

		on = !on

		area.lightswitch = on
		updateicon()

		// Update all other light switches in this area to same state

		for(var/obj/machinery/light_switch/L in area)
			L.on = on
			L.updateicon()

		area.updateicon()		// update the area icon_state to set the darkness overlay


	// When area power status of the lighting channel changes, update the switch status

	power_change()

		if(!otherarea)
			if(powered(LIGHT))
				stat &= ~NOPOWER
			else
				stat |= NOPOWER

			updateicon()
