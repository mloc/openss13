/*
 *	dispenser - A dispenser unit for oxygen and plasma tanks.
 *
 *	Note: tanks cannot be reinserted.
 */

obj/machinery/dispenser
	desc = "A simple yet bulky one-way storage device for gas tanks. Holds 10 plasma and 10 oxygen tanks."
	name = "Tank Storage Unit"
	icon = 'turfs2.dmi'
	icon_state = "dispenser"
	density = 1
	anchored = 1
	var
		o2tanks = 10.0		// number of oxygen tanks
		pltanks = 10.0		// number of plasma tanks


	// if unit powered, use a small amount of power

	process()
		if(stat & NOPOWER)
			return
		use_power(5)


	// attack by AI same as attack by human

	attack_ai(mob/user as mob)
		return src.attack_hand(user)

	// attack by monkey same as attack by human

	attack_paw(mob/user)
		return src.attack_hand(user)

	// attack by human - show window to dispense a tank of either kind

	attack_hand(mob/user)

		user.machine = src
		var/dat = text("<TT><B>Loaded Tank Dispensing Unit</B><BR>\n<FONT color = 'blue'><B>Oxygen</B>: []</FONT> []<BR>\n<FONT color = 'orange'><B>Plasma</B>: []</FONT> []<BR>\n</TT>", src.o2tanks, (src.o2tanks ? text("<A href='?src=\ref[];oxygen=1'>Dispense</A>", src) : "empty"), src.pltanks, (src.pltanks ? text("<A href='?src=\ref[];plasma=1'>Dispense</A>", src) : "empty"))
		user << browse(dat, "window=dispenser")
		return

	// dispense a tank when topic link is clicked on from interaction window

	Topic(href, href_list)
		..()
		if (usr.stat || usr.restrained() )
			return
		if ((!( istype(usr, /mob/human) ) && (!( ticker ) || (ticker && ticker.mode != "monkey"))))
			if (!istype(usr, /mob/ai))
				usr << "\red You don't have the dexterity to do this!"
			else
				usr << "\red You are unable to dispense anything, since the controls are physical levers which don't go through any other kind of input."
			return
		if ((usr.contents.Find(src) || (get_dist(src, usr) <= 1 && istype(src.loc, /turf))))
			usr.machine = src

			if (href_list["oxygen"])
				if (text2num(href_list["oxygen"]))
					if (src.o2tanks > 0)
						use_power(5)
						new /obj/item/weapon/tank/oxygentank( src.loc )
						src.o2tanks--
				if (istype(src.loc, /mob))
					attack_hand(src.loc)

			else if (href_list["plasma"])
				if (text2num(href_list["plasma"]))
					if (src.pltanks > 0)
						use_power(5)
						new /obj/item/weapon/tank/plasmatank( src.loc )
						src.pltanks--
				if (istype(src.loc, /mob))
					attack_hand(src.loc)

			src.add_fingerprint(usr)

			for(var/mob/M in viewers(1, src))
				if ((M.client && M.machine == src))
					src.attack_hand(M)

			usr << browse(null, "window=dispenser")
			return
		return


	// explosion, blob and meteor-hit actions - have a chance to dump all held tanks

	ex_act(severity)
		switch(severity)
			if(1.0)
				del(src)
				return
			if(2.0)
				if (prob(50))
					del(src)
					return
			if(3.0)
				if (prob(25))
					while(src.o2tanks > 0)
						new /obj/item/weapon/tank/oxygentank( src.loc )
						src.o2tanks--
					while(src.pltanks > 0)
						new /obj/item/weapon/tank/plasmatank( src.loc )
						src.pltanks--
			else
		return

	blob_act()

		if (prob(25))
			while(src.o2tanks > 0)
				new /obj/item/weapon/tank/oxygentank( src.loc )
				src.o2tanks--
			while(src.pltanks > 0)
				new /obj/item/weapon/tank/plasmatank( src.loc )
				src.pltanks--
			del(src)

	meteorhit()

		while(src.o2tanks > 0)
			new /obj/item/weapon/tank/oxygentank( src.loc )
			src.o2tanks--
		while(src.pltanks > 0)
			new /obj/item/weapon/tank/plasmatank( src.loc )
			src.pltanks--
		del(src)
		return
