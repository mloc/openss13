/*
 *	Airlock -- an airlock door.
 *
 *  TODO: Make the interaction between the "test light" and the new power system more logical.
 *  TODO: Make it possible to crowbar an airlock open if the area power is out (but bolts still up)
 */

obj/machinery/door/airlock
	name = "airlock"
	icon = 'Door1.dmi'
	var
		blocked = null			// true if door is welded shut
		powered = 1.0			// true if the test light is on
		locked = 0.0			// true if the door bolts are down (locked)
		wires = 511				// bitmask representing the 9 internal wires. Defaults to all connected
								// The wire conditions effect the "powered" and "locked" variables.


	// Called to open door.
	// Door must be unwelded, not locked, test light on, and area power present to open

	open()
		if ((src.blocked || src.locked || !( src.powered )) || stat & NOPOWER)
			return
		use_power(50)
		..()


	// Called to close door
	// If test light is off or no area power, do not close

	close()
		if (!( src.powered || stat & NOPOWER))
			return
		use_power(50)
		..()
		var/turf/T = src.loc
		if (T)
			T.firelevel = 0


	// Set the icon state and other variables, depending on the wires bitfield.

	proc/update()
		if (((!( src.wires & 2 ) || !( src.wires & 8 ) || !( src.wires & 32 ) || !( src.wires & 64 ) || !( src.wires & 128 ) || !( src.wires & 256 )) && src.powered))
			src.locked = 1			// Door is locked if grey, blue, yellow, white, dk red or orange wires are cut and test light is on
									// Note bolts are not automatically raised - you must use a wrench to reset
		if ((!( src.wires & 1 ) && !( src.wires & 4 ) && !( src.wires & 16 )))
			src.powered = 0			// Test light goes off if black, green and red wires are cut
		else
			src.powered = 1			// Otherwise test light is on
		var/d = src.density
		if (src.blocked)			// true if welded shut
			d = "l"
		src.icon_state = text("[]door[]", (src.p_open ? "o_" : null), d)
		return


	// Monkey interact same a human

	attack_paw(mob/user)
		return src.attack_hand(user)


	// Human interact. If the door panel is open, show the wire interaction window. Otherwise, do standard door interaction.

	attack_hand(mob/user)
		if (src.p_open)
			user.machine = src
			var/t1 = {"<B>Access Panel</B><br>
Orange Wire: [(src.wires & 256 ? "<A href='?src=\ref[src];wires=256'>Cut Wire</A>" : "<A href='?src=\ref[src];wires=256'>Mend Wire</A>")]<br>
Dark Red Wire:   [(src.wires & 128 ? "<A href='?src=\ref[src];wires=128'>Cut Wire</A>" : "<A href='?src=\ref[src];wires=128'>Mend Wire</A>")]<br>
White Wire:  [(src.wires & 64 ? "<A href='?src=\ref[src];wires=64'>Cut Wire</A>" : "<A href='?src=\ref[src];wires=64'>Mend Wire</A>")]<br>
Yellow Wire: [(src.wires & 32 ? "<A href='?src=\ref[src];wires=32'>Cut Wire</A>" : "<A href='?src=\ref[src];wires=32'>Mend Wire</A>")]<br>
Red Wire:   [(src.wires & 16 ? "<A href='?src=\ref[src];wires=16'>Cut Wire</A>" : "<A href='?src=\ref[src];wires=16'>Mend Wire</A>")]<br>
Blue Wire:  [(src.wires & 8 ? "<A href='?src=\ref[src];wires=8'>Cut Wire</A>" : "<A href='?src=\ref[src];wires=8'>Mend Wire</A>")]<br>
Green Wire: [(src.wires & 4 ? "<A href='?src=\ref[src];wires=4'>Cut Wire</A>" : "<A href='?src=\ref[src];wires=4'>Mend Wire</A>")]<br>
Grey Wire:   [(src.wires & 2 ? "<A href='?src=\ref[src];wires=2'>Cut Wire</A>" : "<A href='?src=\ref[src];wires=2'>Mend Wire</A>")]<br>
Black Wire:  [(src.wires & 1 ? "<A href='?src=\ref[src];wires=1'>Cut Wire</A>" : "<A href='?src=\ref[src];wires=1'>Mend Wire</A>")]<br>
<br>
[(src.locked ? "The door bolts have fallen!" : "The door bolts look up.")]<br>
[(src.powered ? "The test light is on." : "The test light is off!")]"}


			user << browse(t1, "window=airlock")
		else
			..(user)
		return


	// Handle topic links from interaction window. Cut/join wires if clicking with wirecutters

	Topic(href, href_list)
		..()
		if (usr.stat || usr.restrained() )
			return
		if ((get_dist(src, usr) <= 1 && istype(src.loc, /turf)))
			usr.machine = src
			if (href_list["wires"])
				var/t1 = text2num(href_list["wires"])
				if (!( istype(usr.equipped(), /obj/item/weapon/wirecutters) ))
					return
				if (!( src.p_open ))
					return
				if (t1 & 1)
					if (src.wires & 1)
						src.wires &= ~1
					else
						src.wires |= 1
				else if (t1 & 2)
					if (src.wires & 2)
						src.wires &= ~2
					else
						src.wires |= 2
				else if (t1 & 4)
					if (src.wires & 4)
						src.wires &= ~4
					else
						src.wires |= 4
				else if (t1 & 8)
					if (src.wires & 8)
						src.wires &= ~8
					else
						src.wires |= 8
				else if (t1 & 16)
					if (src.wires & 16)
						src.wires &= ~16
					else
						src.wires |= 16
				else if (t1 & 32)
					if (src.wires & 32)
						src.wires &= ~32
					else
						src.wires |= 32
				else if (t1 & 64)
					if (src.wires & 64)
						src.wires &= ~64
					else
						src.wires |= 64
				else if (t1 & 128)
					if (src.wires & 128)
						src.wires &= ~128
					else
						src.wires |= 128
				else if (t1 & 256)
					if (src.wires & 256)
						src.wires &= ~256
					else
						src.wires |= 256
		src.update()
		add_fingerprint(usr)
		for(var/mob/M in viewers(1, src))
			if ((M.client && M.machine == src))
				src.attack_hand(M)
		return


	// Attack with item.
	// If weldingtool (and door is closed), weld/unweld the door
	// If wrench, and door has test light on, unlock the door (raise bolts)
	// If screwdriver, toggle door panel open/closed
	// If crowbar, and door is closed, not welded, test light off and not locked, open the door
	// Otherwise, do standard door attackby()

	attackby(obj/item/weapon/C, mob/user)
		src.add_fingerprint(user)
		if ((istype(C, /obj/item/weapon/weldingtool) && !( src.operating ) && src.density))
			var/obj/item/weapon/weldingtool/W = C
			if(W.welding)
				if (W.weldfuel > 2)
					W.weldfuel -= 2
				else
					user << "Need more welding fuel!"
					return
				if (!( src.blocked ))
					src.blocked = 1
				else
					src.blocked = null
				src.update()
				return
		else if (istype(C, /obj/item/weapon/wrench))
			if (src.p_open)
				if (src.powered)
					src.locked = null
				else
					user << alert("You need power assist!", null, null, null, null, null)
			src.update()
		else if (istype(C, /obj/item/weapon/screwdriver))
			src.p_open = !( src.p_open )
			update()
		else if (istype(C, /obj/item/weapon/crowbar))
			if ((src.density && !( src.blocked ) && !( src.operating ) && !( src.powered ) && !( src.locked )))
				spawn( 0 )
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
					return
		else
			..()
		return

