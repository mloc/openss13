/*
 *	Cryo_cell -- used to heal mobs of major damage
 *
 *				 Needs a freezer unit attached by a (flex)pipe to operate.
 *
 *	TODO: Cell does not seem to have a broken icon state, nor does breaking the cell affect overlays. Needs further work.
 */

obj/machinery/cryo_cell
	name = "cryo cell"
	icon = 'Cryogenic2.dmi'
	icon_state = "celltop"
	density = 1
	anchored = 1
	p_dir = 8			// pipe direction is west
	capmult = 1			// capacity multiplier

	var
		mob/occupant = null					// the mob inside, or null if none

		obj/substance/gas/gas = null		// the gas reservoir
		obj/substance/gas/ngas = null		// the new calculated gas

		obj/overlay/O1 = null				// the console overlay object
		obj/overlay/O2 = null				// the base of cell overlay object

		obj/machinery/line_in = null		// the connected pipe
		obj/machinery/vnode = null			// the connected pipeline of line_in


	// Create a cryo_cell
	// Pixel-displaced overlays are used to show the console and base of the cell, with the main icon being the cell top

	New()
		..()
		src.layer = 5
		O1 = new /obj/overlay(  )
		O1.icon = 'Cryogenic2.dmi'
		O1.icon_state = "cellconsole"
		O1.pixel_y = -32.0
		O1.layer = 4

		O2 = new /obj/overlay(  )
		O2.icon = 'Cryogenic2.dmi'
		O2.icon_state = "cellbottom"
		O2.pixel_y = -32.0

		src.pixel_y = 32

		add_overlays()

		src.gas = new /obj/substance/gas( null )
		gas.temperature = T20C
		src.ngas = new /obj/substance/gas (null)
		ngas.temperature = T20C

		gasflowlist += src


	// Find the connected (flex)pipe and its pipeline object

	buildnodes()

		var/turf/T = src.loc

		line_in = get_machine(level, T, p_dir )

		if(line_in) vnode = line_in.getline()



	// Called to set the object overlays to the stored values

	proc/add_overlays()
		src.overlays = list(O1, O2)


	// Gas procs


	// Return gas fullness value

	get_gas_val(from)
		return gas.tot_gas()


	// Return the gas reservoir

	get_gas(from)
		return gas


	// Update gas levels with new levels calculated in process()

	gas_flow()
		gas.replace_by(ngas)



	// Called when area power state changes
	// If no power, update icon states to show unpowered versions

	power_change()
		..()
		if(stat & NOPOWER)
			icon_state = "celltop-p"
			O1.icon_state="cellconsole-p"
			O2.icon_state="cellbottom-p"
		else
			icon_state = "celltop[ occupant ? "_1" : ""]"
			O1.icon_state ="cellconsole"
			O2.icon_state ="cellbottom"

		add_overlays()


	// Timed process
	// Perform gas flow, use area power

	process()

		if(vnode)
			var/delta_gt = FLOWFRAC * ( vnode.get_gas_val(src) - gas.tot_gas() / capmult)
			calc_delta( src, gas, ngas, vnode, delta_gt)
		else
			leak_to_turf()


		if(stat & NOPOWER)
			return
		use_power(500)


		for(var/mob/M in viewers(1, src))
			if ((M.client && M.machine == src))
				src.attack_hand(M)


	// Called if no pipe is present
	// Leak gas contents to turf to west

	proc/leak_to_turf()
		var/turf/T = get_step(src, WEST)

		if(T.density)
			T = src.loc
			if(T.density)
				return

		flow_to_turf(gas, ngas, T)


	// Cryocell verbs


	// Eject the occupant

	verb/move_eject()
		set src in oview(1)

		if (usr.stat != 0)
			return
		src.go_out()
		add_fingerprint(usr)


	// Move the player into the cell
	// Cell must be powered, can't already have an occupant, and player can't be wearing anything.
	// If all true, move the player inside and update the view

	verb/move_inside()
		set src in oview(1)

		if (usr.stat != 0 || stat & NOPOWER)
			return
		if (src.occupant)
			usr << "\blue <B>The cell is already occupied!</B>"
			return
		if (usr.abiotic())
			usr << "Subject may not have abiotic items on."
			return
		usr.pulling = null
		usr.client.perspective = EYE_PERSPECTIVE
		usr.client.eye = src
		usr.loc = src
		src.occupant = usr
		src.icon_state = "celltop_1"
		for(var/obj/O in src)
			O.loc = src.loc

		src.add_fingerprint(usr)


	// Attack by item
	// A special case - only works with the pseudo-item representing grabbing another player
	// Make standard checks, then move grabbed player into the cell, and update their view.

	attackby(obj/item/weapon/grab/G, mob/user)

		if (stat & NOPOWER) return

		if ((!( istype(G, /obj/item/weapon/grab) ) || !( ismob(G.affecting) )))
			return
		if (src.occupant)
			user << "\blue <B>The cell is already occupied!</B>"
			return
		if (G.affecting.abiotic())
			user << "Subject may not have abiotic items on."
			return
		var/mob/M = G.affecting
		if (M.client)
			M.client.perspective = EYE_PERSPECTIVE
			M.client.eye = src
		M.loc = src
		src.occupant = M
		src.icon_state = "celltop_1"
		for(var/obj/O in src)
			del(O)
		src.add_fingerprint(user)
		del(G)


	// Monkey interact same as human

	attack_paw(mob/user)
		return src.attack_hand(user)


	// Human interact, show status window of machine and occupant
	// No topic links, since all control is handled through the freezer unit

	attack_hand(mob/user)

		if(stat & NOPOWER)
			return

		user.machine = src
		if (istype(user, /mob/human))
			var/dat = "<font color='blue'> <B>System Statistics:</B></FONT><BR>"
			if (src.gas.temperature > T0C)
				dat += text("<font color='red'>\tTemperature (&deg;C): [] (MUST be below 0, add coolant to mixture)</FONT><BR>", round(src.gas.temperature-T0C, 0.1))
			else
				dat += text("<font color='blue'>\tTemperature (&deg;C): [] </FONT><BR>", round(src.gas.temperature-T0C, 0.1))
			if (src.gas.plasma < 1)
				dat += text("<font color='red'>\tPlasma Units: [] (Add plasma to mixture!)</FONT><BR>", round(src.gas.plasma, 0.1))
			else
				dat += text("<font color='blue'>\tPlasma Units: []</FONT><BR>", round(src.gas.plasma, 0.1))
			if (src.gas.oxygen < 1)
				dat += text("<font color='red'>\tOxygen Units: [] (Add oxygen to mixture!)</FONT><BR>", round(src.gas.oxygen, 0.1))
			else
				dat += text("<font color='blue'>\tOxygen Units: []</FONT><BR>", round(src.gas.oxygen, 0.1))
			if (src.occupant)
				dat += "<font color='blue'><B>Occupant Statistics:</B></FONT><BR>"
				var/t1
				switch(src.occupant.stat)
					if(0.0)
						t1 = "Conscious"
					if(1.0)
						t1 = "Unconscious"
					if(2.0)
						t1 = "*dead*"
					else
				dat += text("[]\tHealth %: [] ([])</FONT><BR>", (src.occupant.health > 50 ? "<font color='blue'>" : "<font color='red'>"), src.occupant.health, t1)
				dat += text("[]\t-Respiratory Damage %: []</FONT><BR>", (src.occupant.oxyloss < 60 ? "<font color='blue'>" : "<font color='red'>"), src.occupant.oxyloss)
				dat += text("[]\t-Toxin Content %: []</FONT><BR>", (src.occupant.toxloss < 60 ? "<font color='blue'>" : "<font color='red'>"), src.occupant.toxloss)
				dat += text("[]\t-Burn Severity %: []</FONT>", (src.occupant.fireloss < 60 ? "<font color='blue'>" : "<font color='red'>"), src.occupant.fireloss)
			dat += text("<BR><BR><A href='?src=\ref[];mach_close=cryo'>Close</A>", user)
			user << browse(dat, "window=cryo;size=400x500")
		else
			var/dat = text("<font color='blue'> <B>[]</B></FONT><BR>", stars("System Statistics:"))
			if (src.gas.temperature > T0C)
				dat += text("<font color='red'>\t[]</FONT><BR>", stars(text("Temperature (C): [] (MUST be below 0, add coolant to mixture)", round(src.gas.temperature-T0C, 0.1))))
			else
				dat += text("<font color='blue'>\t[] </FONT><BR>", stars(text("Temperature(C): []", round(src.gas.temperature-T0C, 0.1))))
			if (src.gas.plasma < 1)
				dat += text("<font color='red'>\t[]</FONT><BR>", stars(text("Plasma Units: [] (Add plasma to mixture!)", round(src.gas.plasma, 0.1))))
			else
				dat += text("<font color='blue'>\t[]</FONT><BR>", stars(text("Plasma Units: []", round(src.gas.plasma, 0.1))))
			if (src.gas.oxygen < 1)
				dat += text("<font color='red'>\t[]</FONT><BR>", stars(text("Oxygen Units: [] (Add oxygen to mixture!)", round(src.gas.oxygen, 0.1))))
			else
				dat += text("<font color='blue'>\t[]</FONT><BR>", stars(text("Oxygen Units: []", round(src.gas.oxygen, 0.1))))
			if (src.occupant)
				dat += "<font color='blue'><B>Occupant Statistics:</B></FONT><BR>"
				var/t1 = null
				switch(src.occupant.stat)
					if(0.0)
						t1 = "Conscious"
					if(1.0)
						t1 = "Unconscious"
					if(2.0)
						t1 = "*dead*"
					else
				dat += text("[]\t[]</FONT><BR>", (src.occupant.health > 50 ? "<font color='blue'>" : "<font color='red'>"), stars(text("Health %: [] ([])", src.occupant.health, t1)))
				dat += text("[]\t[]</FONT><BR>", (src.occupant.oxyloss < 60 ? "<font color='blue'>" : "<font color='red'>"), stars(text("-Respiratory Damage %: []", src.occupant.oxyloss)))
				dat += text("[]\t[]</FONT><BR>", (src.occupant.toxloss < 60 ? "<font color='blue'>" : "<font color='red'>"), stars(text("-Toxin Content %: []", src.occupant.toxloss)))
				dat += text("[]\t[]</FONT>", (src.occupant.fireloss < 60 ? "<font color='blue'>" : "<font color='red'>"), stars(text("-Burn Severity %: []", src.occupant.fireloss)))
			dat += text("<BR><BR><A href='?src=\ref[];mach_close=cryo'>Close</A>", user)
			user << browse(dat, "window=cryo;size=400x500")


	// Called to remove the occupant of a cell
	// Reset the view back to normal

	proc/go_out()

		if (!( src.occupant ))
			return
		for(var/obj/O in src)
			O.loc = src.loc

		if (src.occupant.client)
			src.occupant.client.eye = src.occupant.client.mob
			src.occupant.client.perspective = MOB_PERSPECTIVE
		src.occupant.loc = src.loc
		src.occupant = null
		src.icon_state = "celltop"


	// Called when client tries to move while inside the cell
	// If the user is able to move, leave the cell

	relaymove(mob/user)

		if (user.stat)
			return
		src.go_out()


	// Called in mob/Life() proc while mob is inside the cell
	// Actually heal the occupant, while using up plasma and oxygen from the cell

	alter_health(mob/M)

		if(stat & NOPOWER)
			return

		if (M.health < 0)
			if ((src.gas.temperature > T0C || src.gas.plasma < 1))
				return
		if (M.stat == 2)
			return
		if (src.gas.oxygen >= 1)
			src.ngas.oxygen--
			if (M.oxyloss >= 10)
				var/amount = max(0.15, 2)
				M.oxyloss -= amount
			else
				M.oxyloss = 0
			M.health = 100 - M.oxyloss - M.toxloss - M.fireloss - M.bruteloss
		if ((src.gas.temperature < T0C && src.gas.plasma >= 1))
			src.ngas.plasma--
			if (M.toxloss > 5)
				var/amount = max(0.1, 2)
				M.toxloss -= amount
			else
				M.toxloss = 0
			M.health = 100 - M.oxyloss - M.toxloss - M.fireloss - M.bruteloss
			if (istype(M, /mob/human))
				var/mob/human/H = M
				var/ok = 0
				for(var/organ in H.organs)
					var/obj/item/weapon/organ/external/affecting = H.organs[text("[]", organ)]
					ok += affecting.heal_damage(5, 5)

				if (ok)
					H.UpdateDamageIcon()
				else
					H.UpdateDamage()
			else
				if (M.fireloss > 15)
					var/amount = max(0.3, 2)
					M.fireloss -= amount
				else
					M.fireloss = 0
				if (M.bruteloss > 10)
					var/amount = max(0.3, 2)
					M.bruteloss -= amount
				else
					M.bruteloss = 0
			M.health = 100 - M.oxyloss - M.toxloss - M.fireloss - M.bruteloss
			M.paralysis += 5
		if (src.gas.temperature < (60+T0C))
			src.gas.temperature = min(src.gas.temperature + 1, 60+T0C)

		for(var/mob/E in viewers(1, src))
			if ((E.client && E.machine == src))
				src.attack_hand(E)



	// Explosion - delete the cell or break it

	ex_act(severity)

		switch(severity)
			if(1.0)
				del(src)
			if(2.0)
				if (prob(50))
					for(var/x in src.verbs)
						src.verbs -= x
					src.icon_state = "broken"


	// Blob attack - break the cell

	blob_act()
		for(var/x in src.verbs)
			src.verbs -= x
		src.icon_state = "broken"
		src.density = 0



	/* Unused

	allow_drop()
		return 0

	*/