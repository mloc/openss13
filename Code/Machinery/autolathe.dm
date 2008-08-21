/*
 *	Autolathe - Constructs objects from stocks of metal and glass
 *
 *	Note: Currently only semi-implemented
 *
 */

obj/machinery/autolathe

	name = "Autolathe"
	icon = 'stationobjs.dmi'
	icon_state = "autolathe"
	anchored = 1
	var
		m_amount = 0.0		// amount (cc) of metal loaded
		g_amount = 0.0		// amount (cc) of glass loaded
		operating = 0		// true if the machine is operating
		opened = 0			// true if the machine is open (not fully implemented?)
		temp = null			// temporary intaction window text


	// Feed in metal or glass stock, or open the autolathe

	attackby(obj/item/weapon/O, mob/user)

		if (istype(O, /obj/item/weapon/sheet/metal))
			if (src.m_amount < 150000.0)
				src.m_amount += O:height * O:width * O:length * 1000000.0
				O:amount--
				if (O:amount < 1)
					del(O)

		else if (istype(O, /obj/item/weapon/sheet/glass))
			if (src.g_amount < 75000.0)
				src.g_amount += O:height * O:width * O:length * 1000000.0
				O:amount--
				if (O:amount < 1)
					del(O)

		else if (istype(O, /obj/item/weapon/screwdriver))
			if (!( src.operating ))
				src.opened = !( src.opened )
				src.icon_state = text("autolathe[]", (src.opened ? "f" : null))
			else
				user.client_mob() << "\red The machine is in use. You can not maintain it now."
		else
			spawn( 0 )
				src.attack_hand(user)
				return


	// Monkey interact same as human

	attack_paw(mob/user)
		return src.attack_hand(user)

	// And the AI's interact is still just the same.

	attack_ai(mob/user)
		return src.attack_hand(user)


	// Open interaction window
	// Currenty only pipe pieces can be made
	attack_hand(mob/user)

		if(stat & (BROKEN|NOPOWER))
			return

		var/dat
		if (src.temp)
			dat = text("<TT>[]</TT><BR><BR><A href='?src=\ref[];temp=1'>Clear Screen</A>", src.temp, src)
		else
			dat = text("<B>Metal Amount:</B> [] cm<sup>3</sup> (MAX: 150,000)<BR>\n<FONT color = blue><B>Glass Amount:</B></FONT> [] cm<sup>3</sup> (MAX: 75,000)<HR>", src.m_amount, src.g_amount)
			var/list/L = list(  )

			L["pipe"] = "Straight pipe (7500 cc)"
			L["bpipe"] = "Bent pipe (7500 cc)"
			L["hepipe"] = "Heat-exchange pipe (10000 cc)"
			L["bhepipe"] = "Bent heat-exchange pipe (10000 cc)"
			L["contr"] = "Pipe connector (10000 cc)"
			L["manif"] = "Pipe manifold (15000 cc)"
			L["junct"] = "Pipe junction (10000 cc)"
			L["vent"] = "Pipe vent (10000 cc)"
			L["inlet"] = "Pipe inlet (10000 cc)"
			if (config.enable_drones)
				L["drone"] = "Robot drone (150,000 cc)"
	/*		L["screwdriver"] = "Make Screwdriver {40 cc}"
			L["wirecutters"] = "Make Wirecutters {80 cc}"
			L["wrench"] = "Make Wrench {150 cc}"
			L["crowbar"] = "Make Crowbar {150 cc}"
			L["screw"] = "Make Screw (1) {3 cc}"
			L["5screws"] = "Make Screws (5) {14 cc}"
			L["rod_t"] = "Make Rod (1x20) {20 cc}"
			L["rod_l"] = "Make Rod (5x250) {1250 cc}"
			L["grille_1"] = "Make Grille (250x250x1) {27345 cc}"
			L["sheet_1"] = "Make Sheet (20x10x.01) {2 cc}"
			L["sheet_2"] = "Make Sheet (30x10x.01) {3 cc}"
			L["sheet_3"] = "Make Sheet (30x20x.01) {6 cc}"
			L["sheet_4"] = "Make Sheet (30x30x.01) {9 cc}"
			L["sheet_5"] = "Make Sheet (62.5x62.5x4) {15625 cc}" */


			for(var/t in L)
				dat += "<A href='?src=\ref[src];make=[t]'>[L["[t]"]]<BR>"
		user.client_mob() << browse("<HEAD><TITLE>Autolathe Control Panel</TITLE></HEAD><TT>[dat]</TT>", "window=autolathe")
		return

	// Called by topic links from interaction window
	// Make the chosen item

	Topic(href, href_list)
		..()


		if ((usr.stat || usr.restrained()))
			if (!istype(usr, /mob/ai))
				return
		if(operating || (stat & NOPOWER))
			return
		if ( (get_dist(src, usr) <= 1 || istype(usr, /mob/ai)) && istype(src.loc, /turf) )
			usr.machine = src
			src.add_fingerprint(usr)

			if (href_list["temp"])
				src.temp = null

			if(href_list["make"])

				var/list/C = list()
				C["pipe"] = 7500
				C["bpipe"] = 7500
				C["hepipe"] = 10000
				C["bhepipe"] = 10000
				C["contr"] = 10000
				C["manif"] = 15000
				C["junct"] = 10000
				C["vent"] = 10000
				C["inlet"] = 10000
				if (config.enable_drones)
					C["drone"] = 150000

				var/item = href_list["make"]
				var/cost = C[item]

				if(m_amount >= cost)
					m_amount -= cost
					operate()
					switch(item)
						if("pipe")
							new /obj/item/weapon/pipe{ ptype = 0 }(src.loc)
						if("bpipe")
							new /obj/item/weapon/pipe{ ptype = 1 }(src.loc)
						if("hepipe")
							new /obj/item/weapon/pipe{ ptype = 2 }(src.loc)
						if("bhepipe")
							new /obj/item/weapon/pipe{ ptype = 3 }(src.loc)
						if("contr")
							new /obj/item/weapon/pipe{ ptype = 4 }(src.loc)
						if("manif")
							new /obj/item/weapon/pipe{ ptype = 5 }(src.loc)
						if("junct")
							new /obj/item/weapon/pipe{ ptype = 6 }(src.loc)
						if("vent")
							new /obj/item/weapon/pipe{ ptype = 7 }(src.loc)
						if("inlet")
							new /obj/item/weapon/pipe{ ptype = 8 }(src.loc)
						if("drone")
							if (config.enable_drones)
								var/mob/drone/drone = new /mob/drone(src.loc)
								drone.nameDrone(numDronesInExistance)
								numDronesInExistance ++


		src.updateDialog()
		return

	// Perform operation animation

	proc/operate()

		use_power(500)
		operating = 1
		flick("autolathe_c", src)
		sleep(16)
		flick("autolathe_o", src)
		sleep(8)
		operating = 0
