/*
 *	siphs - base type including siphons, scrubbers, air regulators, and air filters
 *
 *
 *
 */

 // base siph type

obj/machinery/atmoalter/siphs
	name = "siphs"
	density = 1
	weight = 1.0E7
	anchored = 1.0

	// from atmoalter
	maximum = 1.3E8
	holding = null
	t_status = 3.0
	t_per = 50.0
	c_per = 50.0
	c_status = 0.0

	var
		alterable = 1.0			// false if interface is locked (change with wrench)
		f_time = 1.0			// worldtime until automatic mode resumes; set to 30 seconds delay if a fire is present in turf
		//location = null		// unknown/not used
		empty =  null			// if true, fullairsiphons are spawned without any gas content
								// otherwise, filled with air


/* There are 6 types of siph objects:
 *
 *	fullairsiphon			-	Siphon - Can hold a tank. Starts containing air. Automatic process releases air to maintain correct O2/N2 levels
 *  fullairsiphon/port 		- 	Portable Siphon - same as fullairsiphon, but pushable.
 *  fullairsiphon/air_vent  -   Air Regulator - Vent on floor, same as fullairsiphon but cannot hold a tank.
 *
 *	scrubbers				- 	Scrubber - Can hold a tank. Starts empty. Automatic process removes toxins from air and stores in gas content.
 *  scubbers/port			-   Portable Scrubber - same as scrubbers but pushable.
 *	scubbers/air_filter		- 	Air Filter - Vent on floor, same as scrubbers but cannot hold a tank.
 */

	// new siphon object, create the gas content and set maximum capacity
	// Called by New() proc of all siph types

	New()
		..()
		src.gas = new /obj/substance/gas( src )
		src.gas.maximum = src.maximum


	// Set main valve to release and max setting

	proc/releaseall()
		src.t_status = 1
		src.t_per = max_valve
		return


	// Reset the siphon state. If "valve" is negative, main valve is set to release at that rate
	// If "valve" is positive, main valve set to siphon at that rate
	// If "auto" true, main valve set to automatic status
	// This routine is called by the siphonswitch computers to control the siphs


	proc/reset(valve, auto)
		if(c_status!=0)
			return

		if (valve < 0)
			src.t_per =  -valve
			src.t_status = 1
		else
			if (valve > 0)
				src.t_per = valve
				src.t_status = 2
			else
				src.t_status = 3
		if (auto)
			src.t_status = 4
		src.setstate()
		return


	// Release "amount" of gas into the turf

	proc/release(amount, flag)
		var/T = src.loc
		if (!( istype(T, /turf) ))
			return
		if (locate(/obj/move, T))
			T = locate(/obj/move, T)
		if (!( amount ))
			return
		if (!( flag ))
			amount = min(amount, max_valve)
		src.gas.turf_add(T, amount)
		return


	// Siphon "amount" of gas from the turf

	proc/siphon(amount, flag)

		var/T = src.loc
		if (!( istype(T, /turf) ))
			return
		if (locate(/obj/move, T))
			T = locate(/obj/move, T)
		if (!( amount ))
			return
		if (!( flag ))
			amount = min(amount, 900000.0)
		src.gas.turf_take(T, amount)
		return


	// Set the icon state, depending on status (unpowered, holding a tank, or accepting or releasing gas)

	proc/setstate()

		if(stat & NOPOWER)
			icon_state = "siphon:0"
			return

		if (src.holding)
			src.icon_state = "siphon:T"
		else
			if (src.t_status != 3)
				src.icon_state = "siphon:1"
			else
				src.icon_state = "siphon:0"
		return


	// Returns true if the siphon/scrubber is a portable type

	proc/portable()
		return istype(src, /obj/machinery/atmoalter/siphs/fullairsiphon/port) || istype(src, /obj/machinery/atmoalter/siphs/scrubbers/port)


	// Called when area power status changes. Siphons use the ENVIRON channel. Portable siphons/scrubbers do not use power.

	power_change()

		if( portable() )
			return

		if(!powered(ENVIRON))
			spawn(rand(0,15))
				stat |= NOPOWER
				setstate()
		else
			stat &= ~NOPOWER
			setstate()


	// Timed process. Note scrubbers/air filters override this.
	// Accept or release gas depending on settings

	process()
		if(stat & NOPOWER) return

		if (src.t_status != 3)
			var/turf/T = src.loc
			if (istype(T, /turf))
				if (locate(/obj/move, T))
					T = locate(/obj/move, T)
			else
				T = null

			switch(src.t_status)		// main valve status
				if(1.0)													// 1 = release
					if( !portable() ) use_power(50, ENVIRON)
					if (src.holding)									// if tank inserted, fill tank
						var/t1 = src.gas.tot_gas()
						var/t2 = t1
						var/t = src.t_per
						if (src.t_per > t2)
							t = t2
						src.holding.gas.transfer_from(src.gas, t)
					else												// otherwise release into turf
						if (T)
							var/t1 = src.gas.tot_gas()
							var/t2 = t1
							var/t = src.t_per
							if (src.t_per > t2)
								t = t2
							src.gas.turf_add(T, t)

				if(2.0)													// 2 = siphon
					if( !portable() ) use_power(50, ENVIRON)
					if (src.holding)									// if tank inserted, draw from tank
						var/t1 = src.gas.tot_gas()
						var/t2 = src.maximum - t1
						var/t = src.t_per
						if (src.t_per > t2)
							t = t2
						src.gas.transfer_from(src.holding.gas, t)
					else												// else take from turf atmosphere
						if (T)
							var/t1 = src.gas.tot_gas()
							var/t2 = src.maximum - t1
							var/t = src.t_per
							if (t > t2)
								t = t2

							src.gas.turf_take(T, t)
																		// 3 = stopped
				if(4.0)													// 4 = automatic
					if( !portable() )
						use_power(50, ENVIRON)

					if (T)
						if (T.firelevel > 900000.0)
							src.f_time = world.time + 300		// shut off automatic operation for 30 seconds if fire present
						else
							if (world.time > src.f_time)
								var/difference = CELLSTANDARD - (T.oxygen + T.n2)
								if (difference > 0)
									var/t1 = src.gas.tot_gas()
									if (difference > t1)
										difference = t1
									src.gas.turf_add(T, difference)		// add gas to turf to maintain standard N2/O2 levels

		// Pipe valve settings handled in /obj/machinery/connector/process()

		for(var/mob/M in viewers(1, src))
			if ((M.client && M.machine == src))
				src.attack_hand(M)
		src.setstate()
		return


	// Monkey interact same as human

	attack_paw(user as mob)
		return src.attack_hand(user)


	// Interact, show window
	// Used by siphons and scrubbers, but air regulators and filters override

	attack_hand(var/mob/user)

		if(stat & NOPOWER) return
		user.machine = src
		var/tt
		switch(src.t_status)
			if(1.0)
				tt = "Releasing <A href='?src=\ref[src];t=2'>Siphon</A> <A href='?src=\ref[src];t=3'>Stop</A>"
			if(2.0)
				tt = "<A href='?src=\ref[src];t=1'>Release</A> Siphoning <A href='?src=\ref[src];t=3'>Stop</A>"
			if(3.0)
				tt = "<A href='?src=\ref[src];t=1'>Release</A> <A href='?src=\ref[src];t=2'>Siphon</A> Stopped <A href='?src=\ref[src];t=4'>Automatic</A>"
			else
				tt = "Automatic equalizers are on!"

		var/ct = null
		switch(src.c_status)
			if(1.0)
				ct = "Releasing <A href='?src=\ref[src];c=2'>Accept</A> <A href='?src=\ref[src];c=3'>Stop</A>"
			if(2.0)
				ct = "<A href='?src=\ref[src];c=1'>Release</A> Accepting <A href='?src=\ref[src];c=3'>Stop</A>"
			if(3.0)
				ct = "<A href='?src=\ref[src];c=1'>Release</A> <A href='?src=\ref[src];c=2'>Accept</A> Stopped"
			else
				ct = "Disconnected"
		var/at = null
		if (src.t_status == 4)
			at = "Automatic On <A href='?src=\ref[src];t=3'>Stop</A>"
		var/dat = text("<TT><B>Canister Valves</B> []<BR>\n\t<FONT color = 'blue'><B>Contains/Capacity</B> [] / []</FONT><BR>\n\tUpper Valve Status: [] []<BR>\n\t\t<A href='?src=\ref[];tp=-[]'>M</A> <A href='?src=\ref[];tp=-10000'>-</A> <A href='?src=\ref[];tp=-1000'>-</A> <A href='?src=\ref[];tp=-100'>-</A> <A href='?src=\ref[];tp=-1'>-</A> [] <A href='?src=\ref[];tp=1'>+</A> <A href='?src=\ref[];tp=100'>+</A> <A href='?src=\ref[];tp=1000'>+</A> <A href='?src=\ref[];tp=10000'>+</A> <A href='?src=\ref[];tp=[]'>M</A><BR>\n\tPipe Valve Status: []<BR>\n\t\t<A href='?src=\ref[];cp=-[]'>M</A> <A href='?src=\ref[];cp=-10000'>-</A> <A href='?src=\ref[];cp=-1000'>-</A> <A href='?src=\ref[];cp=-100'>-</A> <A href='?src=\ref[];cp=-1'>-</A> [] <A href='?src=\ref[];cp=1'>+</A> <A href='?src=\ref[];cp=100'>+</A> <A href='?src=\ref[];cp=1000'>+</A> <A href='?src=\ref[];cp=10000'>+</A> <A href='?src=\ref[];cp=[]'>M</A><BR>\n<BR>\n\n<A href='?src=\ref[];mach_close=siphon'>Close</A><BR>\n\t</TT>", (!( src.alterable ) ? "<B>Valves are locked. Unlock with wrench!</B>" : "You can lock this interface with a wrench."), num2text(src.gas.tot_gas(), 10), num2text(src.maximum, 10), (src.t_status == 4 ? text("[]", at) : text("[]", tt)), (src.holding ? text("<BR>(<A href='?src=\ref[];tank=1'>Tank ([]</A>)", src, src.holding.gas.tot_gas()) : null), src, num2text(max_valve, 7), src, src, src, src, src.t_per, src, src, src, src, src, num2text(max_valve, 7), ct, src, num2text(max_valve, 7), src, src, src, src, src.c_per, src, src, src, src, src, num2text(max_valve, 7), user)
		user << browse(dat, "window=siphon;size=600x300")
		return


	// Handle topic links from interaction window

	Topic(href, href_list)
		..()

		if (usr.stat || usr.restrained())
			return
		if (!( src.alterable ))
			return
		if ((get_dist(src, usr) <= 1 && istype(src.loc, /turf)))
			usr.machine = src
			if (href_list["c"])
				var/c = text2num(href_list["c"])
				switch(c)
					if(1.0)
						src.c_status = 1
					if(2.0)
						src.c_status = 2
					if(3.0)
						src.c_status = 3

			else if (href_list["t"])
				var/t = text2num(href_list["t"])
				if (src.t_status == 0)
					return
				switch(t)
					if(1.0)
						src.t_status = 1
					if(2.0)
						src.t_status = 2
					if(3.0)
						src.t_status = 3
					if(4.0)
						src.t_status = 4
						src.f_time = 1

			else if (href_list["tp"])
				var/tp = text2num(href_list["tp"])
				src.t_per += tp
				src.t_per = min(max(round(src.t_per), 0), max_valve)
			else if (href_list["cp"])
				var/cp = text2num(href_list["cp"])
				src.c_per += cp
				src.c_per = min(max(round(src.c_per), 0), max_valve)
			else if (href_list["tank"])
				var/cp = text2num(href_list["tank"])
				if (cp == 1)
					src.holding.loc = src.loc
					src.holding = null
					if (src.t_status == 2)
						src.t_status = 3

			for(var/mob/M in viewers(1, src))
				if ((M.client && M.machine == src))
					src.attack_hand(M)
			src.add_fingerprint(usr)
		else
			usr << browse(null, "window=canister")
			return
		return


	// Attack by item
	// Use tank to insert a tank into siphon
	// Use screwdriver to attach to a connector (if present)
	// Use wrench to lock/unlock the interface
	// Note air filters and air regulators override this proc since tanks cannot be inserted

	attackby(var/obj/W as obj, mob/user as mob)

		if (istype(W, /obj/item/weapon/tank))		// insert tank
			if (src.holding)
				return
			var/obj/item/weapon/tank/T = W
			user.drop_item()
			T.loc = src
			src.holding = T

		else if (istype(W, /obj/item/weapon/screwdriver))		// connect/disconnect from connector
			var/obj/machinery/connector/con = locate(/obj/machinery/connector, src.loc)
			if (src.c_status)
				src.anchored = 0
				src.c_status = 0
				user.show_message("\blue You have disconnected the siphon.")
				if(con)
					con.connected = null
			else if (con && !con.connected)
				src.anchored = 1
				src.c_status = 3
				user.show_message("\blue You have connected the siphon.")
				con.connected = src
			else
				user.show_message("\blue There is nothing here to connect to the siphon.")


		else if (istype(W, /obj/item/weapon/wrench))		// lock/unlock the interface
			src.alterable = !( src.alterable )
			if (src.alterable)
				user << "\blue You unlock the interface!"
			else
				user << "\blue You lock the interface!"


	/*
	 *	Fullairsiphons - standard, air regulator, and portable
	 */

	fullairsiphon
		name = "Air siphon"
		icon = 'turfs.dmi'
		icon_state = "siphon:0"

		air_vent
			name = "Air regulator"
			icon = 'aircontrol.dmi'
			icon_state = "vent2"
			t_status = 4				// air regulator vents start in automatic mode
			alterable = 0				// with interface locked
			density = 0

		port
			name = "Portable Siphon"
			icon = 'stationobjs.dmi'
			flags = FPRINT|DRIVABLE
			anchored = 0


		// Create a new fullairsiphon. Unless empty var is true, fill with 21% O2/79% N2

		New()
			..()
			if(!empty)
				src.gas.oxygen = 2.73E7
				src.gas.n2 = 1.027E8


	// Reset the protable siphon

	fullairsiphon/port/reset(valve, auto)
		if (valve < 0)
			src.t_per =  -valve
			src.t_status = 1
		else
			if (valve > 0)
				src.t_per = valve
				src.t_status = 2
			else
				src.t_status = 3
		if (auto)
			src.t_status = 4
		src.setstate()
		return

	// Attack air regulator with item
	// If screwdriver, attach/unattach from connector (if present)
	// If wrench, lock/unlock the interface

	fullairsiphon/air_vent/attackby(obj/item/weapon/W, mob/user)

		if (istype(W, /obj/item/weapon/screwdriver))
			if (src.c_status)
				src.anchored = 1
				src.c_status = 0
			else
				if (locate(/obj/machinery/connector, src.loc))
					src.anchored = 1
					src.c_status = 3
		else
			if (istype(W, /obj/item/weapon/wrench))
				src.alterable = !( src.alterable )
		return


	// Set the icon state of an air regulator vent

	fullairsiphon/air_vent/setstate()
		if(stat & NOPOWER)
			icon_state = "vent-p"
			return

		if (src.t_status == 4)
			src.icon_state = "vent2"
		else
			if (src.t_status == 3)
				src.icon_state = "vent0"
			else
				src.icon_state = "vent1"
		return


	// Reset an air regulator vent. Only set automatic mode; do not change valve settings

	fullairsiphon/air_vent/reset(valve, auto)

		if (auto)
			src.t_status = 4
		return

	/*
	 *	Scrubbers - standard, air filter, and portable
	 */

	scrubbers
		name = "scrubbers"
		icon = 'turfs2.dmi'
		icon_state = "siphon:0"

		air_filter
			name = "air filter"
			icon = 'aircontrol.dmi'
			icon_state = "vent2"
			t_status = 4			// air filter vents start in automatic mode
			alterable = 0			// with interface locked
			density = 0

		port
			name = "Portable Siphon"
			icon = 'stationobjs.dmi'
			icon_state = "scrubber:0"
			flags = FPRINT|DRIVABLE
			anchored = 0.0


		// Timed process for scrubbers (overrides standard for siphs)

		process()

			if(stat & NOPOWER) return

			if (src.t_status != 3)						// unless stopped
				var/turf/T = src.loc					// add all oxygen in gas contents to turf
				if (istype(T, /turf))
					if (locate(/obj/move, T))
						T = locate(/obj/move, T)
					if (T.firelevel < 900000.0)
						src.gas.turf_add_all_oxy(T)

				else
					T = null

				switch(src.t_status)					// main valve status
					if(1.0)								// 1 = release
						if( !portable() ) use_power(50, ENVIRON)

						if (src.holding)				// if a tank is inserted, fill tank with gas
							var/t1 = src.gas.tot_gas()
							var/t2 = t1
							var/t = src.t_per
							if (src.t_per > t2)
								t = t2
							src.holding.gas.transfer_from(src.gas, t)
						else							// otherwise, release gas into turf atmosphere
							if (T)
								var/t1 = src.gas.tot_gas()
								var/t2 = t1
								var/t = src.t_per
								if (src.t_per > t2)
									t = t2
								src.gas.turf_add(T, t)

					if(2.0)								// 2 = siphon
						if( !portable() ) use_power(50, ENVIRON)
						if (src.holding)				// if a tank is inserted, draw gas from tank into contents
							var/t1 = src.gas.tot_gas()
							var/t2 = src.maximum - t1
							var/t = src.t_per
							if (src.t_per > t2)
								t = t2
							src.gas.transfer_from(src.holding.gas, t)
						else							// otherwise, siphon gas from the turf atmosphere
							if (T)
								var/t1 = src.gas.tot_gas()
								var/t2 = src.maximum - t1
								var/t = src.t_per
								if (t > t2)
									t = t2
								src.gas.turf_take(T, t)
					if(4.0)								// 4 = automatic mode
						if( !portable() ) use_power(50, ENVIRON)
						if (T)
							if (T.firelevel > 900000.0)
								src.f_time = world.time + 300	// disable automatic mode for 30 seconds if a fire present
							else
								if (world.time > src.f_time)
									src.gas.extract_toxs(T)		// remove toxins (co2, plasma, n2o) from turf into contents
									if( !portable() ) use_power(150, ENVIRON)
									var/contain = src.gas.tot_gas()	// release excess contents back into turf atmosphere
									if (contain > 1.3E8)
										src.gas.turf_add(T, 1.3E8 - contain)

			// Pipe valve status handled by /obj/machinery/connector/process()

			src.setstate()
			for(var/mob/M in viewers(1, src))
				if ((M.client && M.machine == src))
					src.attack_hand(M)
				//Foreach goto(654)
			return


	// Set icon state of air filter vent depending on status

	scrubbers/air_filter/setstate()
		if(stat & NOPOWER)
			icon_state = "vent-p"
			return

		if (src.t_status == 4)
			src.icon_state = "vent2"
		else
			if (src.t_status == 3)
				src.icon_state = "vent0"
			else
				src.icon_state = "vent1"
		return


	// Attack air filter vent by item
	// If screwdriver, attach/unattach from connector (if present)
	// If wrench, lock/unlock the interface

	scrubbers/air_filter/attackby(obj/item/weapon/W, mob/user)

		if (istype(W, /obj/item/weapon/screwdriver))
			if (src.c_status)
				src.anchored = 1
				src.c_status = 0
			else
				if (locate(/obj/machinery/connector, src.loc))
					src.anchored = 1
					src.c_status = 3
		else
			if (istype(W, /obj/item/weapon/wrench))
				src.alterable = !( src.alterable )
		return

	// Reset an air filter vent. Only set automatic mode; do not change valve settings

	scrubbers/air_filter/reset(valve, auto)

		if (auto)
			src.t_status = 4
		src.setstate()
		return


	// Set icon state for portable scrubber

	scrubbers/port/setstate()

		if(stat & NOPOWER)
			icon_state = "scrubber:0"
			return

		if (src.holding)
			src.icon_state = "scrubber:T"
		else
			if (src.t_status != 3)
				src.icon_state = "scrubber:1"
			else
				src.icon_state = "scrubber:0"
		return


	// Reset valve status for portable scrubber

	scrubbers/port/reset(valve, auto)
		if (valve < 0)
			src.t_per =  -valve
			src.t_status = 1
		else
			if (valve > 0)
				src.t_per = valve
				src.t_status = 2
			else
				src.t_status = 3
		if (auto)
			src.t_status = 4
		src.setstate()
		return
