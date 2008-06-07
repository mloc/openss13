/*
 * Sec_lock	-- Control for opening paired security doors
 *			   As used in brig, prision station, etc.
 *			   Requires ID card to operate
 *
 *	TODO: Merge security checks in Topic() proc
 */

obj/machinery/sec_lock
	name = "Security Pad"
	icon = 'stationobjs.dmi'
	icon_state = "sec_lock"
	anchored = 1.0

	var
		obj/item/weapon/card/id/scan = null			// the inserted ID card
		a_type = 0									// position of the controlled doors
													//0 = doors S/SE, 1 = SW/(SW+W), 2 = NW/(NW+W)
		obj/machinery/door/d1 = null				// the 1st door to control
		obj/machinery/door/d2 = null				// the 2nd door to control
		access = "5500"								// ID access level required to operate lock
		allowed = "Prison Security/Prison Warden/Security Officer/Head of Personnel/Captain"
													// Job titles required to operate lock

	// Create a new sec_lock
	// Looks for 1st & 2nd controlled doors at positions determined by a_type

	New()
		..()
		spawn( 2 )	// wait for world to finished loading
			if (src.a_type == 1)
				src.d2 = locate(/obj/machinery/door, locate(src.x - 2, src.y - 1, src.z))
				src.d1 = locate(/obj/machinery/door, get_step(src, SOUTHWEST))
			else
				if (src.a_type == 2)
					src.d2 = locate(/obj/machinery/door, locate(src.x - 2, src.y + 1, src.z))
					src.d1 = locate(/obj/machinery/door, get_step(src, NORTHWEST))
				else
					src.d1 = locate(/obj/machinery/door, get_step(src, SOUTH))
					src.d2 = locate(/obj/machinery/door, get_step(src, SOUTHEAST))
			return
		return



	// Monkey interact same as human

	attack_paw(mob/user)
		return src.attack_hand(user)

	// attack by AI, same as human

	attack_ai(mob/user)
		return src.attack_hand(user)

	// Interact, show window

	attack_hand(mob/user)

		if(stat & NOPOWER)
			return
		use_power(10)

		if ((src.loc == user.loc) || (istype(user, /mob/ai)))
			var/dat = {"<B>Security Pad:</B><BR>
Keycard: [src.scan ? "<A href='?src=\ref[src];card=1'>[src.scan.name]</A>" : "<A href='?src=\ref[src];card=1'>-----</A>"]<BR>
<A href='?src=\ref[src];door1=1'>Toggle Outer Door</A><BR>
<A href='?src=\ref[src];door2=1'>Toggle Inner Door</A><BR>
<BR>
<A href='?src=\ref[src];em_cl=1'>Emergency Close</A><BR>
<A href='?src=\ref[src];em_op=1'>Emergency Open</A><BR>"}

			user.client_mob() << browse(dat, "window=sec_lock")
		return


	// Attack by item, same as attack with empty hand

	attackby(nothing, mob/user)
		return src.attack_hand(user)


	// Handle topic links from interction window
	// Note: user can insert an ID card by attacking the 'card' link with a card equipped

	Topic(href, href_list)
		..()


		if ((!( istype(usr, /mob/human) ) && (!( ticker ) || (ticker && ticker.mode != "monkey"))))
			if (!istype(usr, /mob/ai))
				if (!istype(usr, /mob/drone))
					usr.client_mob() << "\red You don't have the dexterity to do this!"
					return
		if ((usr.stat || usr.restrained()))
			return
		if ((!( src.d1 ) || !( src.d2 )))
			usr.client_mob() << "\red Error: Cannot interface with door security!"
			return
		if ((usr.contents.Find(src) || (get_dist(src, usr) <= 1 && istype(src.loc, /turf)) || (istype(usr, /mob/ai))))
			usr.machine = src
			if (href_list["card"])				// clicked card link
				if (src.scan)					// if card already present, remove the card
					src.scan.loc = src.loc
					src.scan = null
				else													// otherwise
					if (!istype(usr, /mob/ai))
						var/obj/item/weapon/card/id/I = usr.equipped()		// check to see if an ID card is equipped
						if (istype(I, /obj/item/weapon/card/id))
							usr.drop_item()
							I.loc = src
							src.scan = I									// and insert the ID card
			var/valid = 0
			if (istype(usr, /mob/ai))
				valid = 1
			else if (src.scan)
				if (scan.check_access(access, allowed))
					valid = 1
			if (href_list["door1"])
				if (valid)
					if (src.d1.density)
						spawn( 0 )
							src.d1.open()
							return
					else
						spawn( 0 )
							src.d1.close()
							return
			if (href_list["door2"])
				if (valid)
					if (src.d2.density)
						spawn( 0 )
							src.d2.open()
							return
					else
						spawn( 0 )
							src.d2.close()
							return
			if (href_list["em_cl"])
				if (valid)
					if (!( src.d1.density ))
						src.d1.close()
						return
					sleep(1)
					spawn( 0 )
						if (!( src.d2.density ))
							src.d2.close()
						return
			if (href_list["em_op"])
				if (valid)
					spawn( 0 )
						if (src.d1.density)
							src.d1.open()
						return
					sleep(1)
					spawn( 0 )
						if (src.d2.density)
							src.d2.open()
						return
			src.add_fingerprint(usr)

			src.updateDialog()
		return


