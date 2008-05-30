/*
 *	Pod computer -- controls launch of escape pods
 *
 *	Mass driver - launches the pods
 *
 */


/*
 *	The pod computer
 */

obj/machinery/computer/pod
	name = "Pod Launch Control"
	icon = 'escapepod.dmi'
	icon_state = "computer"

	var
		id = 1.0										// ID of mass driver(s) and poddoors to control
		obj/machinery/mass_driver/connected = null		// the controlled mass driver
		timing = 0.0									// true if counting down before launch
		time = 30.0										// time (seconds) to count down

	// Note: Only one massdriver is located via connected, but all drivers with matching ID are fired together


	// Create a new pod computer
	// Locate and set a massdriver with the same ID

	New()
		..()
		spawn( 5 )
			for(var/obj/machinery/mass_driver/M in machines)
				if (M.id == src.id)
					src.connected = M


	// Called to fire the driver
	// Open the poddoors with same ID, fire the matching mass drivers, then close the doors

	proc/alarm()

		if(stat & (NOPOWER|BROKEN)) return

		if (!( src.connected ))
			viewers(null, null) << "Cannot locate mass driver connector. Cancelling firing sequence!"
			return

		for(var/obj/machinery/door/poddoor/M in machines)
			if (M.id == src.id)
				spawn( 0 )
					M.openpod()
					return

		sleep(20)

		// Note updated from 40.93.3S source - all massdrivers with same ID are fired
		// (Previously, only the connected driver was fired)
		for(var/obj/machinery/mass_driver/M in machines)
			if(M.id == src.id)
				M.power = src.connected.power
				M.drive()
		//

		sleep(50)
		for(var/obj/machinery/door/poddoor/M in machines)
			if (M.id == src.id)
				spawn( 0 )
					M.closepod()
					return


	// Monkey interact same as human

	attack_paw(mob/user)
		return src.attack_hand(user)
	
	// AI interact
	
	attack_ai(mob/user)
		return src.attack_hand(user)

	

	// Human interact, show window

	attack_hand(mob/user)

		if(stat & (NOPOWER|BROKEN)) return

		var/dat = "<HTML><BODY><TT><B>Mass Driver Controls</B>"
		user.machine = src
		var/d2
		if (src.timing)
			d2 = "<A href='?src=\ref[src];time=0'>Stop Time Launch</A>"
		else
			d2 = "<A href='?src=\ref[src];time=1'>Initiate Time Launch</A>"
		var/second = src.time % 60
		var/minute = (src.time - second) / 60
		dat += {"<HR>
Timer System: [d2]
Time Left: [(minute ? "[minute]:" : null)][second] <A href='?src=\ref[src];tp=-30'>-</A> <A href='?src=\ref[src];tp=-1'>-</A> <A href='?src=\ref[src];tp=1'>+</A> <A href='?src=\ref[src];tp=30'>+</A>"}

		if (src.connected)
			var/temp = ""
			var/list/L = list( 0.25, 0.5, 1, 2, 4, 8, 16 )
			for(var/t in L)
				if (t == src.connected.power)
					temp += "[t] "
				else
					temp += "<A href = '?src=\ref[src];power=[t]'>[t]</A> "

			dat += "<HR>\nPower Level: [temp]<BR>\n<A href = '?src=\ref[src];alarm=1'>Firing Sequence</A><BR>\n<A href = '?src=\ref[src];drive=1'>Test Fire Driver</A><BR>\n<A href = '?src=\ref[src];door=1'>Toggle Outer Door</A><BR>"

		else
			dat += "<BR>\n<A href = '?src=\ref[src];door=1'>Toggle Outer Door</A><BR>"

		dat += "<BR><BR><A href='?src=\ref[user];mach_close=computer'>Close</A></TT></BODY></HTML>"
		user << browse(dat, "window=computer;size=400x500")


	// Handle topic links from interaction window

	Topic(href, href_list)
		..()

		if(stat & (NOPOWER|BROKEN))
			usr << browse(null, "window=computer")
			return

		if (usr.restrained() || usr.lying)
			if (!istype(usr, /mob/ai))
				return

		if ((!( istype(usr, /mob/human) ) && (!( ticker ) || (ticker && ticker.mode != "monkey"))))
			if (!istype(usr, /mob/ai))		
				usr << "\red You don't have the dexterity to do this!"
				return
		if ((usr.stat || usr.restrained()))
			if (!istype(usr, /mob/ai))
				return
		if ((usr.contents.Find(src) || (get_dist(src, usr) <= 1 && istype(src.loc, /turf))) || (istype(usr, /mob/ai)))
			usr.machine = src
			if (href_list["power"])
				var/t = text2num(href_list["power"])
				t = min(max(0.25, t), 16)
				if (src.connected)
					src.connected.power = t
			else if (href_list["alarm"])
				src.alarm()
			else if (href_list["time"])
				src.timing = text2num(href_list["time"])
			else if (href_list["tp"])
				var/tp = text2num(href_list["tp"])
				src.time += tp
				src.time = min(max(round(src.time), 0), 120)
			else if (href_list["door"])
				for(var/obj/machinery/door/poddoor/M in machines)
					if (M.id == src.id)
						if (M.density)
							spawn( 0 )
								M.openpod()
								return
						else
							spawn( 0 )
								M.closepod()
								return

			src.add_fingerprint(usr)
			src.updateDialog()
		return


	// Timed process
	// Countdown timer and fire when zero reached

	process()
		if(stat & (NOPOWER|BROKEN) )
			return
		use_power(250)

		if (src.timing)
			if (src.time > 0)
				src.time = round(src.time) - 1
			else
				alarm()
				src.time = 0
				src.timing = 0

			src.updateDialog()



/*
 *	The mass driver
 */

obj/machinery/mass_driver
	name = "mass driver"
	icon = 'stationobjs.dmi'
	icon_state = "mass_driver"
	anchored = 1
	var
		power = 1.0		// The power level to launch the pod
		id = 1.0		// ID of the mass driver. Pod computer must have matching ID.



	// Fire the driver
	// All objects at the location (that have the DRIVABLE flag) are launched in the direction of the driver
	// Show the firing animation

	proc/drive(amount)

		if(stat & NOPOWER)
			return

		use_power(500)
		for(var/obj/O in src.loc)
			if (O.flags & DRIVABLE)
				O.throwing = 1
				O.throwspeed = 100
				spawn( 0 )
					O.throwing(src.dir, src.power)
					return

		flick("mass_driver1", src)



