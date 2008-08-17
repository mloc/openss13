/*
 * 	APC - Area power controller.
 *
 *	APCs control the distribution of power from the cable power network to each area
 *  They have three channels, equipment, lighting, and environmental, which can be independently controlled
 *  Each channel may be switched off to reduce power demand, and may do so automatically.
 *
 *  The APC contains a power cell object that is used as a backup power supply for the area, which charges when
 *  external power is sufficient. The cell may also be removed if the cover lock is diengaged.
 *
 *	The APC controls require an ID card swipe to be unlocked. Once unlocked, each channel can be controlled.
 *
 *	TODO: More graceful behaviour when there is more than one APC per area. Currenly, they may conflict if this happens.
 *        and cell drain rate is not accurate.
 *  TODO: Extend logic when a cell is not inserted. Currently, the APC turns off completely if no cell is inside.
 *        Would be better to do some kind of channel switching depending on available external power.
 *  TODO: Reduction of thrashing when total load exceeds demand. Perhaps needs some kind of (settable?) priority
 *        for each APC, so more important APCs are powered first. Thrashing occurs because all APCs see surplus power,
 *        then switch on charging, which reduces available power below the limit, thus causing all APCs to stop charging.
 *        Fix requires some kind of cumulative load variable in the powenet, but map order processing of this would be
 * 		  unsuitable.
 */


obj/machinery/power/apc
	name = "area power controller"

	icon_state = "apc0"
	anchored = 1
	netnum = -1		// Always -1, set so that APCs aren't found as powernet nodes
					// instead, all connections are done through the associated terminal object
	var
		area/area						// the area that this APC controls
		obj/item/weapon/cell/cell		// the power cell object inserted in this APC (or null if none)
		start_charge = 90				// initial cell charge %
		cell_type = 1					// the cell type: 0=no cell, 1=regular, 2=high-cap (x5)
		opened = 0						// true if the APC is opened (cell exposed)
		locked = 1						// true if the APC interface is locked (non-alterable)
		coverlocked = 1					// true if the APC cover is locked

		lighting = 3					// The status of the 3 area power channels
		equipment = 3					// 0=Off, 1=Auto Off, 2=On, 3=Auto On
		environ = 3						// When set to "auto", the channel will change between states depending on power conditions

		operating = 1					// True if the APC is turned on (main breaker)
		charging = 0					// Cell: 0=Not charging 1=Charging, 2=Fully Charged
		chargemode = 1					// Cell charging mode 0=Off 1=Auto (charge whenever power available)
		chargecount = 0					// Count used to ensure power status is stable before switching to charging mode

		tdir = null						// Direction of APC from terminal
		obj/machinery/power/terminal/terminal = null	// The associated power terminal

		lastused_light = 0				// Last power usage of lighting channel in this area
		lastused_equip = 0				// Last power usage of equipment channel
		lastused_environ = 0			// Last power usage of environmental channel
		lastused_total = 0				// Total last power usage of this area

		main_status = 0					// Main power (powernet) status: 0=Node, 1=Low, 2=Good
		access = "4000/0002/0030"		// ID card access levels needed to lock/unlock interface
		allowed = "Systems"				// ID card job assignment needed to lock/unlock interface



	// Create an APC

	New()
		..()

		// offset 24 pixels in direction of dir
		// this allows the APC to be embedded in a wall, yet still inside an area

		tdir = dir
		dir = SOUTH			// to fix Vars bug

		// Pixel offsets so that APC actually appears embedded in the wall
		pixel_x = (tdir & 3)? 0 : (tdir == 4 ? 24 : -24)
		pixel_y = (tdir & 3)? (tdir ==1 ? 24 : -24) : 0


		// if starting with a power cell installed, create it and set its charge level
		if(cell_type)
			src.cell = new/obj/item/weapon/cell(src)
			cell.maxcharge = cell_type==1 ? 1000 : 5000				// if type=2, make a hp cell
			cell.charge = start_charge * cell.maxcharge / 100.0 		// (convert percentage to actual value)


		var/area/A = src.loc.loc		// the area this APC controls

		if(isarea(A))
			src.area = A

		updateicon()

		// create a terminal object at the same position as original turf loc
		// wires will attach to this rather than the APC itself

		terminal = new/obj/machinery/power/terminal(src.loc)
		terminal.dir = tdir
		terminal.master = src

		spawn(5)
			update()


	// Examine verb

	examine()
		set src in oview(1)

		if(stat & BROKEN) return

		if(usr && !usr.stat)
			usr.client_mob() << "A control terminal for the area electrical systems."
			if(opened)
				usr.client_mob() << "The cover is open and the power cell is [ cell ? "installed" : "missing"]."
			else
				usr.client_mob() << "The cover is closed."


	// Update the APC icon to show the three base states (normal, opened with cell, opened without cell)
	// also add overlays for indicator lights

	proc/updateicon()
		if(opened)
			icon_state = "[ cell ? "apc2" : "apc1" ]"		// if opened, show cell if it's inserted
			src.overlays = null								// also delete all overlays
		else
			icon_state = "apc0"

			// if closed, update overlays for channel status

			src.overlays = null

			overlays += image('power.dmi', "apcox-[locked]")	// 0=blue 1=red
			overlays += image('power.dmi', "apco3-[charging]") // 0=red, 1=yellow/black 2=green


			if(operating)
				overlays += image('power.dmi', "apco0-[equipment]")	// 0=red, 1=green, 2=blue
				overlays += image('power.dmi', "apco1-[lighting]")
				overlays += image('power.dmi', "apco2-[environ]")


	//Attack with an item - open/close cover, insert cell, or (un)lock interface

	attackby(obj/item/weapon/W, mob/user)

		if(stat & BROKEN) return

		if (istype(user, /mob/ai))
			return src.attack_hand(user)

		if (istype(W, /obj/item/weapon/screwdriver))	// screwdriver means open or close the cover
			if(opened)
				opened = 0
				updateicon()
			else
				if(coverlocked)
					user.client_mob() << "The cover is locked and cannot be opened."
				else
					opened = 1
					updateicon()

		else if	(istype(W, /obj/item/weapon/cell) && opened)	// trying to put a cell inside
			if(cell)
				user.client_mob() << "There is a power cell already installed."
			else
				user.drop_item()
				W.loc = src
				cell = W
				user.client_mob() << "You insert the power cell."
				chargecount = 0

			updateicon()
		else if (istype(W, /obj/item/weapon/card/id) )			// trying to unlock the interface with an ID card

			if(opened)
				user.client_mob() << "You must close the cover to swipe an ID card."
			else
				var/obj/item/weapon/card/id/I = W
				if (I.check_access(access, allowed))
					locked = !locked
					user.client_mob() << "You [ locked ? "lock" : "unlock"] the APC interface."
					updateicon()
				else
					user.client_mob() << "\red Access denied."

		else if (istype(W, /obj/item/weapon/card/emag) )		// trying to unlock with an emag card

			if(opened)
				user.client_mob() << "You must close the cover to swipe an ID card."
			else
				flick("apc-spark", src)
				sleep(6)
				if(prob(50))
					locked = !locked
					user.client_mob() << "You [ locked ? "lock" : "unlock"] the APC interface."
					updateicon()
				else
					user.client_mob() << "You fail to [ locked ? "unlock" : "lock"] the APC interface."


	// Attack with hand - remove cell (if present and cover open) or interact with the APC

	attack_ai(mob/user)
		return src.attack_hand(user)

	attack_hand(mob/user)

		add_fingerprint(user)

		if(stat & BROKEN) return

		if(opened && (!istype(user, /mob/ai)))
			if(cell)
				cell.loc = usr
				cell.layer = 20
				//Added User.equipped() because apparently there is some bug where attach_hand gets called after attack_by().  --Zjm7891
				if (user.hand )
					if(!user.equipped())
						user.l_hand = cell
				else
					if(!user.equipped())
						user.r_hand = cell

				cell.add_fingerprint(user)
				cell.updateicon()

				src.cell = null
				user << "You remove the power cell."
				charging = 0
				src.updateicon()

		else
			// do APC interaction
			src.interact(user)


	// Shows APC interaction window

	proc/interact(mob/user)

		if ( (get_dist(src, user) > 1 ))
			if (!istype(user, /mob/ai))
				user.machine = null
				user.client_mob() << browse(null, "window=apc")
				return

		user.machine = src
		var/t = "<TT><B>Area Power Controller</B> ([area.name])<HR>"

		if(locked && (!istype(user, /mob/ai)))									// If interface is locked, show status only
			t += "<I>(Swipe ID card to unlock inteface.)</I><BR>"
			t += "Main breaker : <B>[operating ? "On" : "Off"]</B><BR>"
			t += "External power : <B>[ main_status ? (main_status ==2 ? "<FONT COLOR=#004000>Good</FONT>" : "<FONT COLOR=#D09000>Low</FONT>") : "<FONT COLOR=#F00000>None</FONT>"]</B><BR>"
			t += "Power cell: <B>[cell ? "[round(cell.percent())]%" : "<FONT COLOR=red>Not connected.</FONT>"]</B>"
			if(cell)
				t += " ([charging ? ( charging == 1 ? "Charging" : "Fully charged" ) : "Not charging"])"
				t += " ([chargemode ? "Auto" : "Off"])"

			t += "<BR><HR>Power channels<BR><PRE>"

			var/list/L = list ("Off","Off (Auto)", "On", "On (Auto)")

			t += "Equipment:    [add_lspace(lastused_equip, 6)] W : <B>[L[equipment+1]]</B><BR>"
			t += "Lighting:     [add_lspace(lastused_light, 6)] W : <B>[L[lighting+1]]</B><BR>"
			t += "Environmental:[add_lspace(lastused_environ, 6)] W : <B>[L[environ+1]]</B><BR>"

			t += "<BR>Total load: [lastused_light + lastused_equip + lastused_environ] W</PRE>"
			t += "<HR>Cover lock: <B>[coverlocked ? "Engaged" : "Disengaged"]</B>"

		else													// If interface is unlocked, show status and control links
			if (!istype(user, /mob/ai))
				t += "<I>(Swipe ID card to lock interface.)</I><BR>"
			t += "Main breaker: [operating ? "<B>On</B> <A href='?src=\ref[src];breaker=1'>Off</A>" : "<A href='?src=\ref[src];breaker=1'>On</A> <B>Off</B>" ]<BR>"
			t += "External power : <B>[ main_status ? (main_status ==2 ? "<FONT COLOR=#004000>Good</FONT>" : "<FONT COLOR=#D09000>Low</FONT>") : "<FONT COLOR=#F00000>None</FONT>"]</B><BR>"
			if(cell)
				t += "Power cell: <B>[round(cell.percent())]%</B>"
				t += " ([charging ? ( charging == 1 ? "Charging" : "Fully charged" ) : "Not charging"])"
				t += " ([chargemode ? "<A href='?src=\ref[src];cmode=1'>Off</A> <B>Auto</B>" : "<B>Off</B> <A href='?src=\ref[src];cmode=1'>Auto</A>"])"

			else
				t += "Power cell: <B><FONT COLOR=red>Not connected.</FONT></B>"

			t += "<BR><HR>Power channels<BR><PRE>"


			t += "Equipment:    [add_lspace(lastused_equip, 6)] W : "
			switch(equipment)
				if(0)
					t += "<B>Off</B> <A href='?src=\ref[src];eqp=2'>On</A> <A href='?src=\ref[src];eqp=3'>Auto</A>"
				if(1)
					t += "<A href='?src=\ref[src];eqp=1'>Off</A> <A href='?src=\ref[src];eqp=2'>On</A> <B>Auto (Off)</B>"
				if(2)
					t += "<A href='?src=\ref[src];eqp=1'>Off</A> <B>On</B> <A href='?src=\ref[src];eqp=3'>Auto</A>"
				if(3)
					t += "<A href='?src=\ref[src];eqp=1'>Off</A> <A href='?src=\ref[src];eqp=2'>On</A> <B>Auto (On)</B>"
			t +="<BR>"

			t += "Lighting:     [add_lspace(lastused_light, 6)] W : "

			switch(lighting)
				if(0)
					t += "<B>Off</B> <A href='?src=\ref[src];lgt=2'>On</A> <A href='?src=\ref[src];lgt=3'>Auto</A>"
				if(1)
					t += "<A href='?src=\ref[src];lgt=1'>Off</A> <A href='?src=\ref[src];lgt=2'>On</A> <B>Auto (Off)</B>"
				if(2)
					t += "<A href='?src=\ref[src];lgt=1'>Off</A> <B>On</B> <A href='?src=\ref[src];lgt=3'>Auto</A>"
				if(3)
					t += "<A href='?src=\ref[src];lgt=1'>Off</A> <A href='?src=\ref[src];lgt=2'>On</A> <B>Auto (On)</B>"
			t +="<BR>"


			t += "Environmental:[add_lspace(lastused_environ, 6)] W : "
			switch(environ)
				if(0)
					t += "<B>Off</B> <A href='?src=\ref[src];env=2'>On</A> <A href='?src=\ref[src];env=3'>Auto</A>"
				if(1)
					t += "<A href='?src=\ref[src];env=1'>Off</A> <A href='?src=\ref[src];env=2'>On</A> <B>Auto (Off)</B>"
				if(2)
					t += "<A href='?src=\ref[src];env=1'>Off</A> <B>On</B> <A href='?src=\ref[src];env=3'>Auto</A>"
				if(3)
					t += "<A href='?src=\ref[src];env=1'>Off</A> <A href='?src=\ref[src];env=2'>On</A> <B>Auto (On)</B>"



			t += "<BR>Total load: [lastused_light + lastused_equip + lastused_environ] W</PRE>"
			t += "<HR>Cover lock: [coverlocked ? "<B><A href='?src=\ref[src];lock=1'>Engaged</A></B>" : "<B><A href='?src=\ref[src];lock=1'>Disengaged</A></B>"]"

		t += "<BR><HR><A href='?src=\ref[src];close=1'>Close</A>"

		t += "</TT>"
		user.client_mob() << browse(t, "window=apc")
		return


	//Returns a string showing the status of the APC.

	proc/report()
		return "[area.name] : [equipment]/[lighting]/[environ] ([lastused_equip+lastused_light+lastused_environ]) : [cell? cell.percent() : "N/C"] ([charging])"



	// Called whenever the status of an APC control changes.
	// Sets the underlying area power status variables, and informs the area that something has changed.

	proc/update()
		if(operating)
			area.power_light = (lighting > 1)
			area.power_equip = (equipment > 1)
			area.power_environ = (environ > 1)
		else
			area.power_light = 0
			area.power_equip = 0
			area.power_environ = 0
			chargecount = 0				// H9.6 FIX: If breaker is off, stop charging
			charging = 0

		area.power_change()


	// Handle topic links from the interaction window

	Topic(href, href_list)

		..()

		if (usr.stat || usr.restrained() )
			return
		if ((!( istype(usr, /mob/human) ) && (!( ticker ) || (ticker && ticker.mode != "monkey"))))
			if (!istype(usr, /mob/ai))
				usr.client_mob() << "\red You don't have the dexterity to do this!"
				return

		if (( (get_dist(src, usr) <= 1 && istype(src.loc, /turf))) || (istype(usr, /mob/ai)))

			usr.machine = src
			if (href_list["lock"])
				coverlocked = !coverlocked

			else if (href_list["breaker"])
				operating = !operating
				src.update()
				updateicon()

			else if (href_list["cmode"])
				chargemode = !chargemode
				if(!chargemode)
					charging = 0
					updateicon()

			else if (href_list["eqp"])
				var/val = text2num(href_list["eqp"])

				equipment = (val==1) ? 0 : val

				updateicon()
				update()

			else if (href_list["lgt"])
				var/val = text2num(href_list["lgt"])

				lighting = (val==1) ? 0 : val

				updateicon()
				update()
			else if (href_list["env"])
				var/val = text2num(href_list["env"])

				environ = (val==1) ? 0 :val

				updateicon()
				update()
			else if( href_list["close"] )
				usr.client_mob() << browse(null, "window=apc")
				usr.machine = null
				return


			src.updateDialog()
		else
			usr.client_mob() << browse(null, "window=apc")
			usr.machine = null

		return


	// Helper functions for interfacing to the powernet
	// Overriden for APC since they connect to the powernet only through the terminal

	// Return the surplus power of the powernet

	surplus()
		if(terminal)
			return terminal.surplus()
		else
			return 0


	// Add a load amount to the powernet

	add_load(var/amount)
		if(terminal && terminal.powernet)
			terminal.powernet.newload += amount


	// Return the available power (neglecting load) of the powernet

	avail()
		if(terminal)
			return terminal.avail()
		else
			return 0

// Constant - amount of power used to charge the power cell

#define CHARGELEVEL 500


	// APC timed process - executed ~once per second
	// Calculates the channel settings and cell charging status depending on area power usage,
	// power available from the network, and cell charge level.

	process()

		if(stat & BROKEN)
			return

		if(!area.requires_power)			// set for an area if it never requires power
			return

		area.calc_lighting()				// calculate the power used for lighting an area (by number of turfs)

		// Find the cumulative power usage for the APC's area. Then reset it.

		lastused_light = area.usage(LIGHT)
		lastused_equip = area.usage(EQUIP)
		lastused_environ = area.usage(ENVIRON)
		area.clear_usage()

		lastused_total = lastused_light + lastused_equip + lastused_environ


		//cache control states so to update icon only if any change during this proc
		var/last_lt = lighting
		var/last_eq = equipment
		var/last_en = environ
		var/last_ch = charging


		var/excess = surplus()

		// Set the external power display depending on the surplus power on the powernet

		if(!src.avail())
			main_status = 0
		else if(excess < 0)
			main_status = 1
		else
			main_status = 2


		// Perapc is the calculated power surplus evenly divided by every APC in the network. This is used in some
		// anti-thrashing calculations

		var/perapc = 0
		if(terminal && terminal.powernet)
			perapc = terminal.powernet.perapc

		if(cell)		// If a power cell is present

			// draw power from cell

			var/cellused = min(cell.charge, CELLRATE * lastused_total)	// clamp deduction to a max, amount left in cell

			cell.charge -= cellused		// reduce the cell charge level



			// set channels depending on how much charge we have left


			if(cell.charge <= 0)					// zero charge, turn all off
				equipment = autoset(equipment, 2)
				lighting = autoset(lighting, 2)
				environ = autoset(environ, 2)
			else if(cell.percent() < 15)				// <15%, turn off lighting & equipment
				equipment = autoset(equipment, 2)
				lighting = autoset(lighting, 2)
				environ = autoset(environ, 1)
			else if(cell.percent() < 30)			// <30%, turn off equipment
				equipment = autoset(equipment, 2)
				lighting = autoset(lighting, 1)
				environ = autoset(environ, 1)
			else									// otherwise all can be on
				equipment = autoset(equipment, 1)
				lighting = autoset(lighting, 1)
				environ = autoset(environ, 1)


			if(excess > 0 || perapc > lastused_total)		// if power excess, or enough anyway, recharge the cell
															// by the same amount just used

				cell.charge = min(cell.maxcharge, cell.charge + cellused)

				add_load(cellused/CELLRATE)		// add the load used to recharge the cell


			else		// no excess, and not enough per-apc

				if( (cell.charge/CELLRATE+perapc) >= lastused_total)		// can we draw enough from cell+grid to cover last usage?

					cell.charge = min(cell.maxcharge, cell.charge + CELLRATE * perapc)	//recharge with what we can

					add_load(perapc)		// so draw what we can from the grid
					charging = 0

				else	// not enough!
					charging = 0			// kill everything
					chargecount = 0
					equipment = autoset(equipment, 0)
					lighting = autoset(lighting, 0)
					environ = autoset(environ, 0)



			// now trickle-charge the cell


			if(chargemode && charging == 1)
				if(excess > 0)		// check to make sure we have enough to charge

					var/ch = min(CHARGELEVEL, (cell.maxcharge - cell.charge)/CELLRATE )	// clamp charging to max free in cell

					ch = min(ch, perapc)	// clamp charging to our share

					add_load(CHARGELEVEL)

					cell.charge += ch * CELLRATE		// actually recharge the cell

				else

					charging = 0		// stop charging
					chargecount = 0



			// show cell as fully charged if so

			if(cell.charge >= cell.maxcharge)
				charging = 2

			// switch between charging and not depending on stability of external power

			if(chargemode)
				if(!charging)
					if(excess > CHARGELEVEL)
						chargecount++
					else
						chargecount = 0


					if(chargecount == 5)	// right amount of excess power must be available for 5 second before switching to charge

						chargecount = 0
						charging = 1

			else // chargemode off
				charging = 0
				chargecount = 0




		else
			// no cell

			// for now, switch everything off

			// TODO: Something more logical here, depending on excess external power

			charging = 0
			chargecount = 0
			equipment = autoset(equipment, 0)
			lighting = autoset(lighting, 0)
			environ = autoset(environ, 0)



		// update icon & area power only if anything changed

		if(last_lt != lighting || last_eq != equipment || last_en != environ || last_ch != charging)
			updateicon()
			update()

		// update any player looking at the interaction window

		src.updateDialog()

	// If APC hit by a meteor, break it

	meteorhit(var/obj/O)
		set_broken()
		return

	// APC in explosion, chance to break depending on the severity

	ex_act(severity)

		switch(severity)
			if(1.0)
				set_broken()
				del(src)
				return
			if(2.0)
				if (prob(50))
					set_broken()
			if(3.0)
				if (prob(25))
					set_broken()
			else
		return

	// Blob attack

	blob_act()
		if (prob(50))
			set_broken()


	// Called to set the APC into a broken state.
	// Set Stat and broken icon_state, inform area to turn everything off.
	// Can't (yet) be fixed again.

	proc/set_broken()
		stat |= BROKEN
		icon_state = "apc-b"
		overlays = null

		operating = 0
		update()


// Global helper proc, used only in apc/process()
// returns the new state of a channel control, given the current settings
// This is so a channel can switch between AutoOn and AutoOff depending on available power levels
// But a channel set to On will stay on until power is zero, when it will switch to Off and stay there

// val 0=off, 1=off(auto) 2=on 3=on(auto)
// on 0=off, 1=on, 2=autooff

/proc/autoset(var/val, var/on)

	if(on==0)
		if(val==2)			// if on, return off
			return 0
		else if(val==3)		// if auto-on, return auto-off
			return 1

	else if(on==1)
		if(val==1)			// if auto-off, return auto-on
			return 3

	else if(on==2)
		if(val==3)			// if auto-on, return auto-off
			return 1

	return val


