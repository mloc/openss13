/*
 *	Turbine and compressor -- auxilliary power generation system
 *
 *	TODO: Tweak values to make the aux generator useful. It was intended to generate large amounts of power,
 *		   but use up plasma too fast to be sustainable for a long time.
 *
 *
 */


/*
 * Compressor - not actually a power-connected machine, but only used with a turbine
 */

#define COMPFRICTION 5e5			// a breaking friction coefficient (so compressor has a maximum speed
									// and spins down when unpowered)
#define COMPSTARTERLOAD 2800		// the power load needed to run the starter

obj/machinery/compressor
	name = "compressor"
	desc = "The compressor stage of a gas turbine generator."
	icon = 'pipes.dmi'
	icon_state = "compressor"
	anchored = 1
	density = 1
	var
		obj/machinery/power/turbine/turbine			// the associated turbine object
		obj/substance/gas/gas						// the gas reservoir inside the compressor
		turf/inturf									// the inlet turf (where gas is drawn in)
		starter = 0									// true if the starter is engaged
		rpm = 0										// the current spin rate
		rpmtarget = 0								// the target spin rate
		capacity = 1e6								// maximum gas capacity


	// Create a compressor. Set the inlet turf (one step to west) and the turbine (one step to east)

	New()
		..()

		gas = new/obj/substance/gas(src)
		gas.maximum = capacity
		inturf = get_step(src, WEST)

		spawn(5)
			turbine = locate() in get_step(src, EAST)
			if(!turbine)
				stat |= BROKEN


	// Timed process. Make spin rate tend to the target rate, draw in gas.
	//set target rate to 1000 if starter is on, and display the icon overlay correspoinding to the current spin rate

	process()

		overlays = null
		if(stat & BROKEN)
			return

		rpm = 0.9* rpm + 0.1 * rpmtarget


		gas.turf_take(inturf, rpm/30000*capacity)


		rpm = max(0, rpm - (rpm*rpm)/COMPFRICTION)


		if(starter && !(stat & NOPOWER))
			use_power(2800)
			if(rpm<1000)
				rpmtarget = 1000
			else
				starter = 0
		else
			if(rpm<1000)
				rpmtarget = 0



		if(rpm>50000)
			overlays += image('pipes.dmi', "comp-o4", FLY_LAYER)
		else if(rpm>10000)
			overlays += image('pipes.dmi', "comp-o3", FLY_LAYER)
		else if(rpm>2000)
			overlays += image('pipes.dmi', "comp-o2", FLY_LAYER)
		if(rpm>500)
			overlays += image('pipes.dmi', "comp-o1", FLY_LAYER)


/*
 * Turbine - generates power and spins compressor depending on gas parameters inside the compressor
 */

#define TURBPRES 90000000	// the "pressure" (gas amount * temperature) required to generate 30000 RPM
#define TURBGENQ 20000		// coefficient relating spin rate to power generated
#define TURBGENG 0.8		// linearity coefficient of spinrate/power curve (1=linear)


obj/machinery/power/turbine
	name = "gas turbine generator"
	desc = "A gas turbine used to for backup power generation."
	icon = 'pipes.dmi'
	icon_state = "turbine"
	anchored = 1
	density = 1
	directwired = 1

	var
		obj/machinery/compressor/compressor			// the associated compressor
		turf/outturf								// the outlet turf (1 step to east)
		lastgen										// the power generated last cycle




	// Create a turbine. Sets the outlet turf (1 step to east) and the compressor (1 step to west)

	New()
		..()

		outturf = get_step(src, EAST)

		spawn(5)

			compressor = locate() in get_step(src, WEST)
			if(!compressor)
				stat |= BROKEN


	// Timed process.
	// Generate power depending on current rpm. Set new target rpm depending on compressor gas temperature and amount
	// Output gas to outlet turf. Update overlay if actually generating signifcant power


	process()

		overlays = null
		if(stat & BROKEN)
			return

		lastgen = ((compressor.rpm / TURBGENQ)**TURBGENG) *TURBGENQ
		add_avail(lastgen)

		//if(compressor.gas.temperature > (T20C+50))
		var/newrpm = ((compressor.gas.temperature-T20C-50) * compressor.gas.tot_gas() / TURBPRES)*30000
		newrpm = max(0, newrpm)

		if(!compressor.starter || newrpm > 1000)
			compressor.rpmtarget = newrpm

		if(compressor.gas.tot_gas()>0)
			var/oamount = min(compressor.gas.tot_gas(), (compressor.rpm+100)/35000*compressor.capacity)

			compressor.gas.turf_add(outturf, oamount)

			outturf.firelevel = outturf.poison

		if(lastgen > 100)
			overlays += image('pipes.dmi', "turb-o", FLY_LAYER)


		src.updateDialog()

	// Attack by AI, do user interaction

	attack_ai(mob/user)

		add_fingerprint(user)

		if(stat & (BROKEN | NOPOWER)) return

		interact(user)
		
	// Attack hand, do user interaction

	attack_hand(mob/user)

		add_fingerprint(user)

		if(stat & (BROKEN | NOPOWER)) return

		interact(user)


	// Show the interaction window

	proc/interact(mob/user)

		if ( (get_dist(src, user) > 1 ) || (stat & (NOPOWER|BROKEN)) && (!istype(user, /mob/ai)) )
			user.machine = null
			user.client_mob() << browse(null, "window=turbine")
			return

		user.machine = src

		var/t = "<TT><B>Gas Turbine Generator</B><HR><PRE>"

		var/gen = max(0, lastgen - (compressor.starter * COMPSTARTERLOAD) )
		t += "Generated power : [round(gen)] W<BR><BR>"

		t += "Turbine: [round(compressor.rpm)] RPM<BR>"

		t += "Starter: [ compressor.starter ? "<A href='?src=\ref[src];str=1'>Off</A> <B>On</B>" : "<B>Off</B> <A href='?src=\ref[src];str=1'>On</A>"]<BR>"

		//t += "Gas: [compressor.gas.tostring()]<BR>"

		t += "</PRE><HR><A href='?src=\ref[src];close=1'>Close</A>"

		t += "</TT>"
		user.client_mob() << browse(t, "window=turbine")

		return


	// Handle topic links from interaction window

	Topic(href, href_list)
		..()
		if(stat & BROKEN)
			return
		if (usr.stat || usr.restrained() )
			return
		if ((!( istype(usr, /mob/human) ) && (!( ticker ) || (ticker && ticker.mode != "monkey"))))
			if (!istype(usr, /mob/ai))		
				if (!istype(usr, /mob/drone))
					usr.client_mob() << "\red You don't have the dexterity to do this!"
					return

		if (( usr.machine==src && (get_dist(src, usr) <= 1 && istype(src.loc, /turf))) || (istype(usr, /mob/ai)))


			if( href_list["close"] )
				usr.client_mob() << browse(null, "window=turbine")
				usr.machine = null
				return

			else if( href_list["str"] )
				compressor.starter = !compressor.starter

			spawn(0)
				src.updateDialog()

		else
			usr.client_mob() << browse(null, "window=turbine")
			usr.machine = null

		return