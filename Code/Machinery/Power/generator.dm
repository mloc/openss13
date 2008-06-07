/*
 * 	Generator - The main power generation machine
 *
 *	A generator makes power using the heat difference between the gas levels in two circulator machines.
 *
 */

#define GENRATE 0.0015			// generator output coefficient

obj/machinery/power/generator
	name = "generator"
	desc = "A high efficiency thermoelectric generator."
	icon_state = "teg"
	anchored = 1
	density = 1

	var
		obj/machinery/circulator/circ1			// the cold gas circulator; must be to west of generator
		obj/machinery/circulator/circ2			// the hot gas circulator; must be to east of generator

		c1on = 0								// true if circulator 1 is on
		c2on = 0								//   "   "     "      2  "  "
		c1rate = 10								// circulator 1's pumping rate (percentage)
		c2rate = 10								// circulator 2's pumping rate (percentage)
		lastgen = 0								// the power generated in the last cycle
		lastgenlev = -1							// the last bargraph overlay level


	// Create a generator, and locate the two circulators on either side

	New()
		..()

		spawn(5)
			circ1 = locate(/obj/machinery/circulator) in get_step(src,WEST)
			circ2 = locate(/obj/machinery/circulator) in get_step(src,EAST)
			if(!circ1 || !circ2)
				stat |= BROKEN

			updateicon()


	// Update the icon overlays depending on status and power output level

	proc/updateicon()

		if(stat & (NOPOWER|BROKEN))
			overlays = null
		else
			overlays = null

			if(lastgenlev != 0)
				overlays += image('power.dmi', "teg-op[lastgenlev]")

			overlays += image('power.dmi', "teg-oc[c1on][c2on]")


	// Generate power, depending on the gas amounts and temperatures in the circulators

	// The device works as a semi-realistic heat engine; heat from the hot reservoir is converted to energy
	// at a set efficiency (65% of Carnot). The waste heat is dumped into the cold reservoir
	// This can only be sustained while the cold reservoir is cooler than the hot one.

	process()

		if(circ1 && circ2)			// both circulators must be present


			var/gc = circ1.gas2.shc()
			var/gh = circ2.gas2.shc()

			var/tc = circ1.gas2.temperature
			var/th = circ2.gas2.temperature
			var/deltat = th-tc

			if (th>0)
				var/eta = (1-tc/th)*0.65		// efficiency 65% of Carnot

				if(gc > 0 && deltat >0)		// require some cold gas (for sink) and a positive temp gradient
					var/ghoc = gh/gc

					//var/qc = gc*tc
					//var/qh = gh*th

					var/fdt = 1/( (1-eta)*ghoc + 1)	// min timestep

					fdt = min(fdt, 0.1)	// max timestep

					var/q = fdt*eta*gh*(deltat)	// heat generated

					var/thp = th - fdt * deltat
					var/tcp = tc + fdt * (1 - eta) * (ghoc) * deltat

					lastgen = q * GENRATE
					add_avail(lastgen)

					circ1.ngas2.temperature = tcp
					circ2.ngas2.temperature = thp

				else
					lastgen = 0
			else
				lastgen = 0

		// update icon overlays only if displayed level has changed

		var/genlev = max(0, min( round(11*lastgen / 100000), 11))
		if(genlev != lastgenlev)
			lastgenlev = genlev
			updateicon()

		src.updateDialog()

	// Attack with hand, open interaction window

	
	attack_ai(mob/user)
		if(stat & (BROKEN|NOPOWER)) return

		interact(user)
		
	attack_hand(mob/user)

		add_fingerprint(user)

		if(stat & (BROKEN|NOPOWER)) return

		interact(user)


	// Display interaction window

	proc/interact(mob/user)

		if ( (get_dist(src, user) > 1 ) && (!istype(user, /mob/ai)))
			user.machine = null
			user.client_mob() << browse(null, "window=teg")
			return

		user.machine = src

		var/t = "<PRE><B>Thermo-Electric Generator</B><HR>"

		t += "Output : [round(lastgen)] W<BR><BR>"

		t += "<B>Cold loop</B><BR>"
		t += "Temperature Inlet: [round(circ1.ngas1.temperature, 0.1)] K  Outlet: [round(circ1.ngas2.temperature, 0.1)] K<BR>"

		t += "Circulator: [c1on ? "<B>On</B> <A href = '?src=\ref[src];c1p=1'>Off</A>" : "<A href = '?src=\ref[src];c1p=1'>On</A> <B>Off</B> "]<BR>"
		t += "Rate: <A href = '?src=\ref[src];c1r=-3'>M</A> <A href = '?src=\ref[src];c1r=-2'>-</A> <A href = '?src=\ref[src];c1r=-1'>-</A> [add_lspace(c1rate,3)]% <A href = '?src=\ref[src];c1r=1'>+</A> <A href = '?src=\ref[src];c1r=2'>+</A> <A href = '?src=\ref[src];c1r=3'>M</A><BR>"

		t += "<B>Hot loop</B><BR>"
		t += "Temperature Inlet: [round(circ2.ngas1.temperature, 0.1)] K  Outlet: [round(circ2.ngas2.temperature, 0.1)] K<BR>"

		t += "Circulator: [c2on ? "<B>On</B> <A href = '?src=\ref[src];c2p=1'>Off</A>" : "<A href = '?src=\ref[src];c2p=1'>On</A> <B>Off</B> "]<BR>"
		t += "Rate: <A href = '?src=\ref[src];c2r=-3'>M</A> <A href = '?src=\ref[src];c2r=-2'>-</A> <A href = '?src=\ref[src];c2r=-1'>-</A> [add_lspace(c2rate,3)]% <A href = '?src=\ref[src];c2r=1'>+</A> <A href = '?src=\ref[src];c2r=2'>+</A> <A href = '?src=\ref[src];c2r=3'>M</A><BR>"

		t += "<BR><HR><A href='?src=\ref[src];close=1'>Close</A>"

		t += "</PRE>"
		user.client_mob() << browse(t, "window=teg;size=460x300")
		return


	// Handle topic links from interaction window

	Topic(href, href_list)
		..()

		if (usr.stat || usr.restrained() )
			return
		if ((!( istype(usr, /mob/human) ) && (!( ticker ) || (ticker && ticker.mode != "monkey"))))
			if (!istype(usr, /mob/ai))	
				if (!istype(usr, /mob/drone))			
					usr.client_mob() << "\red You don't have the dexterity to do this!"
					return

		//world << "[href] ; [href_list[href]]"

		if (( usr.machine==src && (get_dist(src, usr) <= 1 && istype(src.loc, /turf))) || (istype(usr, /mob/ai)))


			if( href_list["close"] )
				usr.client_mob() << browse(null, "window=teg")
				usr.machine = null
				return

			else if( href_list["c1p"] )
				c1on = !c1on
				circ1.control(c1on, c1rate)			// used to control the circulator power and rate settings
				updateicon()
			else if( href_list["c2p"] )
				c2on = !c2on
				circ2.control(c2on, c2rate)
				updateicon()

			else if( href_list["c1r"] )

				var/i = text2num(href_list["c1r"])

				var/d = 0
				switch(i)
					if(-3)
						c1rate = 0
					if(3)
						c1rate = 100

					if(1)
						d = 1
					if(-1)
						d = -1
					if(2)
						d = 10
					if(-2)
						d = -10

				c1rate += d
				c1rate = max(1, min(100, c1rate))	// clamp to range

				circ1.control(c1on, c1rate)
				updateicon()

			else if( href_list["c2r"] )

				var/i = text2num(href_list["c2r"])

				var/d = 0
				switch(i)
					if(-3)
						c2rate = 0
					if(3)
						c2rate = 100

					if(1)
						d = 1
					if(-1)
						d = -1
					if(2)
						d = 10
					if(-2)
						d = -10

				c2rate += d
				c2rate = max(1, min(100, c2rate))	// clamp to range

				circ2.control(c2on, c2rate)
				updateicon()

			src.updateDialog()
		else
			usr.client_mob() << browse(null, "window=teg")
			usr.machine = null

		return


	// When are power changes, perfrom default action and update icon overlays

	power_change()
		..()
		updateicon()

