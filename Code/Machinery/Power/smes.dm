/*
 * SMES -- Superconduction magnetic energy storage unit
 *
 * A machine that stores power.
 *
 * SMESes have two "sides" where the are connected to the cable network: Input and output.
 * The input side is connected via a terminal to the SMES; this is where the SMES draws power from to charge
 * The output side is directly wired to the SMES object; this is where the SMES outputs stored power
 * If the two sides are part of the same powernet, the SMES will still work correctly
 *
 * TODO: See note a proc/restore() below
 */

#define SMESMAXCHARGELEVEL 200000		// This is the maximum rate at which you can charge the SMES

#define SMESMAXOUTPUT 200000				// This is the maxmium output power of the SMES

#define SMESRATE 0.05					// rate of internal charge to external power output


/obj/machinery/power/smes
	name = "power storage unit"
	desc = "A high-capacity superconducting magnetic energy storage (SMES) unit."
	icon_state = "smes"
	density = 1
	anchored = 1
	var
		output = 30000				// the current power output level - limited to SMEXMAXOUTPUT
		lastout = 0					// the output during the last cycle
		loaddemand = 0				// the actual amount during the last cycle (may be lower if powernet load is lower)
		capacity = 5e6				// the total maximum charge capacity
		charge = 1e6				// the current charge level; default is 20% of maximum
		charging = 0				// true if charging
		chargemode = 0				// true if set to automatically charge
		chargecount = 0				// count of number of times excess power has been availiable (used to control when charging is started)
		chargelevel = 30000			// the amount of power to use to charge the SMES - limited to SMESMAXCHARGELEVEL
		online = 1					// true if online (outputing power)
		n_tag = null				// a string nametag to display on the control panel (e.g. Main No. 1)
		obj/machinery/power/terminal/terminal = null		// the input terminal connected to this SMES


	// Create a new SMES
	// After waiting for the powernets to be built, look for a matching terminal in the 4 cardinal directions
	// If found, store the terminal, otherwise mark the SMES as broken

	New()
		..()

		spawn(5)
			dir_loop:
				for(var/d in cardinal)
					var/turf/T = get_step(src, d)
					for(var/obj/machinery/power/terminal/term in T)
						if(term && term.dir == turn(d, 180))		// terminal must have wires pointing towards the SMES
							terminal = term
							break dir_loop

			if(!terminal)
				stat |= BROKEN
				return

			terminal.master = src

			updateicon()



	// Updates the SMES icon to show overlays representing charging state, online state, and charge level

	proc/updateicon()

		overlays = null
		if(stat & BROKEN)
			return

		overlays += image('power.dmi', "smes-op[online]")

		if(charging)
			overlays += image('power.dmi', "smes-oc1")
		else
			if(chargemode)
				overlays += image('power.dmi', "smes-oc0")

		var/clevel = chargedisplay()
		if(clevel>0)
			overlays += image('power.dmi', "smes-og[clevel]")


	// Returns the level (0-5) of the bargraph overlay (representing the charge level) to display

	proc/chargedisplay()
		return round(5.5*charge/capacity)



	// Timed process; recharge the SMES if power is available, output power if online

	process()
		if(stat & BROKEN)
			return

		//store machine state to see if we need to update the icon overlays
		var/last_disp = chargedisplay()
		var/last_chrg = charging
		var/last_onln = online

		if(terminal)
			var/excess = terminal.surplus()

			if(charging)
				if(excess >= 0)		// if there's power available, try to charge

					var/load = min((capacity-charge)/SMESRATE, chargelevel)		// charge at set rate, limited to spare capacity

					charge += load * SMESRATE	// increase the charge

					add_load(load)		// add the load to the terminal side network

				else					// if not enough capcity
					charging = 0		// stop charging
					chargecount  = 0

			else
				if(chargemode)
					if(chargecount > rand(3,10))		// random count to switch to charging reduces thrashing
						charging = 1
						chargecount = 0

					if(excess > chargelevel)
						chargecount++
					else
						chargecount = 0
				else
					chargecount = 0

		if(online)		// if outputting
			lastout = min( charge/SMESRATE, output)		//limit output to that stored

			charge -= lastout*SMESRATE		// reduce the storage (may be recovered in /restore() if excessive)

			add_avail(lastout)				// add output to powernet (smes side)

			if(charge < 0.0001)
				online = 0					// stop output if charge falls to zero

		// only update icon if state changed
		if(last_disp != chargedisplay() || last_chrg != charging || last_onln != online)
			updateicon()

		src.updateDialog()


	// A special routine for SMES
	// Called by the main game loop after all other power processes are finished
	// SMESes make availabe a set amount of power per cycle, but should only have as much power drained
	// as the actual load that cycle. This restore() proc restores the excess charge that wasn't really used.

	// TODO: Make the charge restoration more logical. Either need a priority setting, or some way to evenly
	// share load between SMESes.

	proc/restore()
		if(stat & BROKEN)
			return

		if(!online)
			loaddemand = 0
			return

		var/excess = powernet.netexcess		// this was how much wasn't used on the network last ptick, minus any removed by other SMESes

		excess = min(lastout, excess)				// clamp it to how much was actually output by this SMES last ptick

		excess = min((capacity-charge)/SMESRATE, excess)	// for safety, also limit recharge by space capacity of SMES (shouldn't happen)

		// now recharge this amount

		var/clev = chargedisplay()

		charge += excess * SMESRATE
		powernet.netexcess -= excess		// remove the excess from the powernet, so later SMESes don't try to use it

		loaddemand = lastout-excess

		if(clev != chargedisplay() )
			updateicon()


	// Add a load amount. Loading is done throught the terminal's powernet for SMESes

	add_load(var/amount)
		if(terminal && terminal.powernet)
			terminal.powernet.newload += amount

	// Attack to open interaction window
	
	attack_ai(mob/user)

		add_fingerprint(user)

		if(stat & BROKEN) return

		interact(user)
	
	// Attack to open interaction window

	attack_hand(mob/user)

		add_fingerprint(user)

		if(stat & BROKEN) return

		interact(user)


	// Display interaction window

	proc/interact(mob/user)

		if ( (get_dist(src, user) > 1 ))
			if (!istype(user, /mob/ai))
				user.machine = null
				user << browse(null, "window=smes")
				return

		user.machine = src


		var/t = "<TT><B>SMES Power Storage Unit</B> [n_tag? "([n_tag])" : null]<HR><PRE>"

		t += "Stored capacity : [round(100.0*charge/capacity, 0.1)]%<BR><BR>"

		t += "Input: [charging ? "Charging" : "Not Charging"]    [chargemode ? "<B>Auto</B> <A href = '?src=\ref[src];cmode=1'>Off</A>" : "<A href = '?src=\ref[src];cmode=1'>Auto</A> <B>Off</B> "]<BR>"


		t += "Input level:  <A href = '?src=\ref[src];input=-4'>M</A> <A href = '?src=\ref[src];input=-3'>-</A> <A href = '?src=\ref[src];input=-2'>-</A> <A href = '?src=\ref[src];input=-1'>-</A> [add_lspace(chargelevel,5)] <A href = '?src=\ref[src];input=1'>+</A> <A href = '?src=\ref[src];input=2'>+</A> <A href = '?src=\ref[src];input=3'>+</A> <A href = '?src=\ref[src];input=4'>M</A><BR>"

		t += "<BR><BR>"

		t += "Output: [online ? "<B>Online</B> <A href = '?src=\ref[src];online=1'>Offline</A>" : "<A href = '?src=\ref[src];online=1'>Online</A> <B>Offline</B> "]<BR>"

		t += "Output level: <A href = '?src=\ref[src];output=-4'>M</A> <A href = '?src=\ref[src];output=-3'>-</A> <A href = '?src=\ref[src];output=-2'>-</A> <A href = '?src=\ref[src];output=-1'>-</A> [add_lspace(output,5)] <A href = '?src=\ref[src];output=1'>+</A> <A href = '?src=\ref[src];output=2'>+</A> <A href = '?src=\ref[src];output=3'>+</A> <A href = '?src=\ref[src];output=4'>M</A><BR>"

		t += "Output load: [round(loaddemand)] W<BR>"

		t += "<BR></PRE><HR><A href='?src=\ref[src];close=1'>Close</A>"

		t += "</TT>"
		user << browse(t, "window=smes;size=460x300")
		return


		// Handle topic links from the interaction window

	Topic(href, href_list)
		..()

		if (usr.stat || usr.restrained() )
			return
		if ((!( istype(usr, /mob/human) ) && (!( ticker ) || (ticker && ticker.mode != "monkey"))))
			if (!istype(usr, /mob/ai))		
				usr << "\red You don't have the dexterity to do this!"
				return

		//world << "[href] ; [href_list[href]]"

		if (( usr.machine==src && (get_dist(src, usr) <= 1 && istype(src.loc, /turf))) || (istype(usr, /mob/ai)))


			if( href_list["close"] )
				usr << browse(null, "window=smes")
				usr.machine = null
				return

			else if( href_list["cmode"] )
				chargemode = !chargemode
				if(!chargemode)
					charging = 0
				updateicon()

			else if( href_list["online"] )
				online = !online
				updateicon()
			else if( href_list["input"] )

				var/i = text2num(href_list["input"])

				var/d = 0
				switch(i)
					if(-4)
						chargelevel = 0
					if(4)
						chargelevel = SMESMAXCHARGELEVEL		//30000

					if(1)
						d = 100
					if(-1)
						d = -100
					if(2)
						d = 1000
					if(-2)
						d = -1000
					if(3)
						d = 10000
					if(-3)
						d = -10000

				chargelevel += d
				chargelevel = max(0, min(SMESMAXCHARGELEVEL, chargelevel))	// clamp to range

			else if( href_list["output"] )

				var/i = text2num(href_list["output"])

				var/d = 0
				switch(i)
					if(-4)
						output = 0
					if(4)
						output = SMESMAXOUTPUT		//30000

					if(1)
						d = 100
					if(-1)
						d = -100
					if(2)
						d = 1000
					if(-2)
						d = -1000
					if(3)
						d = 10000
					if(-3)
						d = -10000

				output += d
				output = max(0, min(SMESMAXOUTPUT, output))	// clamp to range


			src.updateDialog()
		else
			usr << browse(null, "window=smes")
			usr.machine = null

		return