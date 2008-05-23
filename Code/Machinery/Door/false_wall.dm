/*
 *  False_wall -- A fake wall that can be opened like a door.
 *
 *
 */

obj/machinery/door/false_wall
	name = "wall"
	icon = 'Doorf.dmi'


	// Create a false-wall door. Remove the pull verb as this gives away the doors position.

	New()
		..()
		src.verbs -= /atom/movable/verb/pull

	// Examine verb. Same result as a standard wall.

	examine()
		set src in oview(1)

		usr << "It looks like a regular wall"

	// Monkey interact - if in monkey mode, same as human

	attack_paw(mob/user)
		if ((ticker && ticker.mode == "monkey"))
			return src.attack_hand(user)


	// Human interact - 25% chance to open the door

	attack_hand(mob/user)

		src.add_fingerprint(user)
		if (src.density)
			if (prob(25))
				open()
			else
				user << "\blue You push the wall but nothing happens!"
		else
			close()

	// Attack by item
	// If a screwdriver, disassembly the false wall into components

	attackby(obj/item/weapon/screwdriver/S, mob/user)

		src.add_fingerprint(user)
		if (istype(S, /obj/item/weapon/screwdriver))
			new /obj/item/weapon/sheet/metal( src.loc )
			new /obj/d_girders( src.loc )
			del(src)
			return
		else
			..()
