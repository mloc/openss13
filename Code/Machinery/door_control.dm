/*
 *	Door_control -- A remote control for opening/closing poddoors
 *
 *
 */

obj/machinery/door_control
	name = "remote door control"
	icon = 'stationobjs.dmi'
	icon_state = "doorctrl0"
	desc = "A remote control switch for a door."
	anchored = 1.0
	var
		id = null		// id must match that of the poddoor to operate


	// attack by monkey same as human

	attack_paw(mob/user)
		return src.attack_hand(user)


	// attack by an item same as empty hand

	attackby(nothing, mob/user)
		return src.attack_hand(user)

	// attack by hand, toggle all poddoors with same id

	attack_hand(mob/user)

		if(stat & NOPOWER)
			return
		use_power(5)
		icon_state = "doorctrl1"

		for(var/obj/machinery/door/poddoor/M in machines)
			if (M.id == src.id)
				if (M.density)
					spawn( 0 )
						M.openpod()
						return
				else
					spawn( 0 )
						M.closepod()
						return

		spawn(15)
			if(!(stat & NOPOWER))
				icon_state = "doorctrl0"


	// area power changed, set the icon_state to unpowered

	power_change()
		..()
		if(stat & NOPOWER)
			icon_state = "doorctrl-p"
		else
			icon_state = "doorctrl0"

