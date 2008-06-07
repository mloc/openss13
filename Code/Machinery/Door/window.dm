/*
 * 	Window door -- A non-opaque door covering either the south or east edges of a turf
 *
 *	If the door has an access requirement, the security door icon is substituted
 */


obj/machinery/door/window
	name = "interior door"
	icon = 'windoor.dmi'
	visible = 0.0				// Door is not opaque when closed
	flags = WINDOW
	opacity = 0

	// Note dir var sets the 4 possible states - "door handle" points in the dir direction, slides in opposite dirn to open
	// dir=1 : Door on east edge, slides to south
	// dir=2:  Door on east edge, slides to north
	// dir=4:  Door on south edge, slides to west
	// dir=8:  Door on south edge, slides to east


	// Create a new windowdoor. If access controls are set, use the alternate icon for security doors

	New()
		..()
		var/turf/T = src.loc
		if (T)
			T.updatecell = 1
			T.buildlinks()
		if ( (access && access!="0000") || allowed)
			src.icon = 'security.dmi'


	// Override close() proc since windowdoors still update their turf when closed, unlike other doors.

	close()
		..()					// call standard door/close() proc
		var/turf/T = src.loc
		if (T)
			T.updatecell = 1	// turf still runs gas simulation
			T.buildlinks()
		return


	// If a mob bumps into the door, cycle the door (open then close)

	Bumped(atom/movable/AM)
		if (!( ismob(AM) ))
			return
		src.cycle(AM,1)
		return


	// Attack by monkey same as human

	attack_paw(mob/user)
		return src.attack_hand(user)

	// Attack by AI same as human
	
	attack_ai(mob/user)
		return src.attack_hand(user)
	
	// Human attack hand - cycle the door

	attack_hand(mob/user)
		src.cycle(user,0)


	// Called to cycle a windowdoor
	// If an unsecured door, open for 5 seconds, then close again
	// Otherwise, check ID access levels and toggle open/closed state
	// arg bumped is true if called from the Bump proc (will not check ID in this case)

	proc/cycle(mob/user, bumped=0)
		if (!( ticker ))				// doors won't open until round has started
			return
		if (src.operating)
			return
		if (access && access=="0000" && !allowed)		// unsecure door
			if (src.density)
				open()									// open then close 5 seconds later
				sleep(50)
				close()
			return

		if(bumped)										// if called from Bump(), return now - you can't bump open a secure door
			return

		var/obj/item/weapon/card/id/card				// check if user is human and wearing ID
		if (istype(user, /mob/drone))
			if (user:controlledBy != null)
				user = user:controlledBy
		if (istype(user, /mob/human))
			var/mob/human/H = user
			card = H.wear_id
			if (!( istype(card, /obj/item/weapon/card/id) ))
				return
		else
			if (istype(user, /mob/ai))
				if (src.density)
					open()
				else
					close()
			return
		if (card.check_access(access, allowed))			// check access levels of worn ID
			if (src.density)							// and toggle door open/closed depending on current state
				open()
			else
				close()
		else
			if (src.density)
				flick("door_deny", src)


	// Note attackby item (ID) handled by standard door proc


	// Called in turf/Enter() to see if windowdoor is passable, when turf being entered contains a windowdoor
	// O is the moving object
	// target is the turf it wants to move into

	CheckPass(atom/movable/O, target)
		if (src.density)								// only check if door is closed
			var/direct = get_dir(O, target)
			if ((direct == NORTH && src.dir & 12))		// moving north, and door is on south edge of target
				return 0								// can't pass
			else
				if ((direct == WEST && src.dir & 3))	// moving west, and door is on east edge of target
					return 0
		return 1


	// Called in turf/Enter() to see if windowdoor is passable, when turf entering from contains a windowdoor
	// O is the moving object
	// target is the turf it wants to move into

	CheckExit(atom/movable/O, target)

		if (src.density)								// only check if door is closed
			var/direct = get_dir(O, target)
			if ((direct == SOUTH && src.dir & 12))		// moving south, and door is on south edge
				return 0
			else
				if ((direct == EAST && src.dir & 3))	// moving east, and door is on east edge
					return 0
		return 1

