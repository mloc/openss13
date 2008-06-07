/*
 *	Engine -- engine computer
 *
 *  Used to eject the engine section, and can also read the gas levels present at a gas sensor
 *
 *	Most of the ejection logic is contained in the engine_eject datum
 */

/obj/machinery/computer/engine
	name = "engine"
	icon = 'enginecomputer.dmi'
	var
		temp = null						// temporary text string used for interaction window
		id = 1							// id of gas sensor to display
		obj/machinery/gas_sensor/gs		// the gas sensor object
		access = "4000/0030"			// the access levels required to start ejection timer (Capt, Head, or Engineer)
		allowed							// the job assignments to eject (null = none)


	// Create the engine computer, and the global ejector datum if not already exisiting
	// Also find the gas sensor object matching "id"

	New()
		if (!( engine_eject_control ))
			engine_eject_control = new /datum/engine_eject(  )
		..()

		spawn(5)
			for(var/obj/machinery/gas_sensor/G in machines)
				if(G.id == src.id)
					gs = G
					break


	// Timed process
	// Use power, update interaction window for viewers

	process()
		if(stat & (NOPOWER|BROKEN) )
			return
		use_power(250)

		src.updateDialog()


	// Attackby object - pass through to interact

	attackby(var/obj/O, mob/user)
		return src.attack_hand(user)

	// Monkey interact same a human

	attack_paw(var/mob/user as mob)
		return src.attack_hand(user)

	// AI interact
	attack_ai(mob/user)
		return src.attack_hand(user)
		
	
	// Human interact
	// Show interaction window

	attack_hand(var/mob/user as mob)
		if(stat & (NOPOWER|BROKEN) )
			return

		user.machine = src
		var/dat
		if (src.temp)
			dat = "<TT>[src.temp]</TT><BR><BR><A href='?src=\ref[src];temp=1'>Clear Screen</A>"
		else if (engine_eject_control.status == 0)
			dat = "<B>Engine Gas Monitor</B><HR>"
			if(gs)
				dat += "[gs.sense_string()]"

			else
				dat += "No sensor found."

			dat += "<BR><B>Engine Ejection Module</B><HR>\nStatus: Docked<BR>\n<BR>\nCountdown: [engine_eject_control.timeleft]/60 <A href='?src=\ref[src];reset=1'>\[Reset\]</A><BR>\n<BR>\n<A href='?src=\ref[src];eject=1'>Eject Engine</A><BR>\n<BR>\n<A href='?src=\ref[user];mach_close=computer'>Close</A>"
		else
			if (engine_eject_control.status == 1)
				dat = "<B>Engine Ejection Module</B><HR>\nStatus: Ejecting<BR>\n<BR>\nCountdown: [engine_eject_control.timeleft]/60 \[Reset\]<BR>\n<BR>\n<A href='?src=\ref[src];stop=1'>Stop Ejection</A><BR>\n<BR>\n<A href='?src=\ref[user];mach_close=computer'>Close</A>"
			else
				dat = "<B>Engine Ejection Module</B><HR>\nStatus: Ejected<BR>\n<BR>\nCountdown: N/60 \[Reset\]<BR>\n<BR>\nEngine Ejected!<BR>\n<BR>\n<A href='?src=\ref[user];mach_close=computer'>Close</A>"
		user.client_mob() << browse(dat, "window=computer;size=400x500")


	// Handle topic links from interaction window

	Topic(href, href_list)
		..()
		if ((!( istype(usr, /mob/human) ) && (!( ticker ) || (ticker && ticker.mode != "monkey"))))
			if (!istype(usr, /mob/ai))
				if (!istype(usr, /mob/drone))
					usr.client_mob() << "\red You don't have the dexterity to do this!"
					return
		if ((usr.stat || usr.restrained()))
			if (!istype(usr, /mob/ai))
				return
		if ((usr.contents.Find(src) || (get_dist(src, usr) <= 1 && istype(src.loc, /turf))))
			usr.machine = src

			if (href_list["eject"])
				if (engine_eject_control.status == 0)
					src.temp = "Eject Engine?<BR><BR><B><A href='?src=\ref[src];eject2=1'>\[Swipe ID to initiate eject sequence\]</A></B><BR><A href='?src=\ref[src];temp=1'>Cancel</A>"

			else if (href_list["eject2"])						// check ID card against access levels before ejecting
				var/obj/item/weapon/card/id/I = usr.equipped()
				if (istype(I))
					if(I.check_access(access,allowed))
						if (engine_eject_control.status == 0)
							engine_eject_control.ejectstart()
							src.temp = null
					else
						usr.client_mob() << "\red Access Denied."
			else if (href_list["stop"])
				if (engine_eject_control.status > 0)
					src.temp = text("Stop Ejection?<BR><BR><A href='?src=\ref[];stop2=1'>Yes</A><BR><A href='?src=\ref[];temp=1'>No</A>", src, src)

			else if (href_list["stop2"])
				if (engine_eject_control.status > 0)
					engine_eject_control.stopcount()
					src.temp = null

			else if (href_list["reset"])
				if (engine_eject_control.status == 0)
					engine_eject_control.resetcount()

			else if (href_list["temp"])
				src.temp = null

			src.add_fingerprint(usr)

			src.updateDialog()
