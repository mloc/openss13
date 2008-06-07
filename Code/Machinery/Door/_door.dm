/*
 *	Door -- the base door type.
 *			All other doors (airlocks, false walls, poddoors, firedoors and windowdoors) descend from this.
 *
 */

obj/machinery/door
	name = "door"
	icon = 'doors.dmi'
	icon_state = "door1"
	opacity = 1
	density = 1
	anchored = 1

	var
		visible = 1.0				// True for all except windowdoors; controls whether door becomes opaque when closed.

		access = "0000"				// ID card access levels
		allowed = null				// ID card job assignment access

		p_open = 0.0				// True if the wiring panel is open; currently only used for airlocks
		operating = null			// True if door is currently opening/closing


	// Create a new door. Ensure that turf links are updated.

	New()
		..()
		var/turf/T = src.loc
		if (istype(T, /turf))
			if (src.density)
				T.updatecell = 0
				T.buildlinks()


	// Called to open a door
	// Plays opening animation, updates icon state, ensures turf links are updated

	proc/open()
		if (src.operating)
			return
		src.operating = 1
		flick(text("[]doorc0", (src.p_open ? "o_" : null)), src)
		src.icon_state = text("[]door0", (src.p_open ? "o_" : null))
		sleep(15)
		src.density = 0
		src.opacity = 0
		var/turf/T = src.loc
		if (istype(T, /turf))
			T.updatecell = 1
			T.buildlinks()
		src.operating = 0


	// Called to close a door.
	// Plays closing animation, updates icon state, ensures turf links are updated

	proc/close()
		if (src.operating)
			return
		src.operating = 1
		flick(text("[]doorc1", (src.p_open ? "o_" : null)), src)
		src.icon_state = text("[]door1", (src.p_open ? "o_" : null))
		src.density = 1
		if (src.visible)
			src.opacity = 1
		var/turf/T = src.loc
		if (istype(T, /turf))
			T.updatecell = 0
			T.buildlinks()
		sleep(15)
		src.operating = 0

	// Monkey attack same as human

	attack_paw(mob/user)
		return src.attack_hand(user)

	// AI attack same as human, for most doors

	attack_ai(mob/user)
		return src.attack_hand(user)

	// Attack with hand. If human and wearing an ID, same as attacking with the ID

	attack_hand(mob/user as mob)
		if (istype(user, /mob/drone))
			if (user:controlledBy != null)
				user = user:controlledBy
				
		if(istype(user, /mob/human))
			var/mob/human/H = user
			if(H.wear_id)
				attackby(H.wear_id, user)
		else if(istype(user, /mob/ai))
			attackby(user, user)
		
		
		
	// Does it accept IDs?

	proc/acceptsIDs()
		return 1

	// Attack with an item
	// If an emag card, open the door if closed. Note: Door cannot be reclosed with an emag.
	// If anything else, check to see if user is wearing an ID (or the ID was used)
	// then check the ID access and open or close the door

	attackby(obj/item/I, mob/user)

		if (src.operating)
			return
		src.add_fingerprint(user)
		if (!src.acceptsIDs())
			if (istype(user, /mob/ai))
				if (src.density)
					open()
				else
					close()
			else
				if (src.density)
					flick("door_deny", src)
				else
					close()
			return
		if ((src.density && istype(I, /obj/item/weapon/card/emag)))
			src.operating = 1
			flick("door_spark", src)
			sleep(6)
			src.operating = null
			open()
			return 1
		var/obj/item/weapon/card/id/card
		if (istype(user, /mob/human))
			var/mob/human/H = user
			card = H.wear_id
		if (istype(I, /obj/item/weapon/card/id))
			card = I
		else
			if (!( istype(card, /obj/item/weapon/card/id) ))
				if ((istype(user, /mob/ai)))
					if (src.density)
						open()
					else
						close()
					return
				else
					return 0
		if (card.check_access(access, allowed))
			if (src.density)
				open()
			else
				close()
		else
			if (src.density)
				flick("door_deny", src)


	//  If hit by a meteor, open the door

	meteorhit(obj/M)
		src.open()
		return

	// Attack by blob, chance to destroy the door.

	blob_act()
		if(prob(20))
			del(src)

// Built-in proc called when the door moves location
	// Since doors do not move, this seems to be redundent

	Move()
		..()
		if (src.density)
			var/turf/location = src.loc
			if (istype(location, /turf))
				location.updatecell = 0
				buildlinks()
