/*
 *	Firealarm - Machine that controls firealarm triggering in an area
 *
 *  			When fire present, triggers flashing area icon and closes firedoors.
 */

obj/machinery/firealarm
	name = "firealarm"
	icon = 'items.dmi'
	icon_state = "firealarm"
	anchored = 1
	var
		detecting = 1			// true if the alarm is working, false if disabled
		//working = 1			// unused
		time = 10.0				// seconds left until alarm triggered
		timing = 0				// true if counting down timer


	// Called if the location turf is on fire; triggers the alarm if so

	burn(fi_amount)
		if(stat & NOPOWER)
			return
		if(src.detecting) src.alarm()
		return


	// Attack with item, if wirecutters connect/disconnect fire detector
	// Otherwise, trigger the alarm

	attackby(obj/item/weapon/W, mob/user)
		if (istype(W, /obj/item/weapon/wirecutters))
			src.detecting = !( src.detecting )
			var/list/observers = viewers(user, null)
			if (src.detecting)
				for (var/mob/M in observers)
					M.client_mob() << "\red [user] has reconnected [src]'s detecting unit!"
			else
				for (var/mob/M in observers)
					M.client_mob() << "\red [user] has disconnected [src]'s detecting unit!"
		else
			src.alarm()
		src.add_fingerprint(user)
		return


	// Timed process. Countdown if set to trigger after time.

	process()

		if(stat & NOPOWER)
			return

		use_power(10, ENVIRON)

		if (src.timing)
			if (src.time > 0)
				src.time = round(src.time) - 1
			else
				alarm()
				src.time = 0
				src.timing = 0

			src.updateDialog()
		return


	// When area power state changes, disable alarm if no power in ENVIRON channel

	power_change()
		if(powered(ENVIRON))
			stat &= ~NOPOWER
			icon_state = "firealarm"
		else
			spawn(rand(0,15))
				stat |= NOPOWER
				icon_state = "firealarm-p"

	// AI interact same as human

	attack_ai(mob/user)
		return src.attack_hand(user)

	// Monkey interact same as human

	attack_paw(mob/user)
		return src.attack_hand(user)


	// Interact and show window
	// Garbled text if a monkey

	attack_hand(mob/user)

		if(user.stat || stat&NOPOWER) return

		user.machine = src
		var/area/A = src.loc
		var/d1
		var/d2
		if (istype(user, /mob/human) || istype(user, /mob/ai))
			A = A.loc

			if (A.fire)
				d1 = "<A href='?src=\ref[src];reset=1'>Reset - Lockdown</A>"
			else
				d1 = "<A href='?src=\ref[src];alarm=1'>Alarm - Lockdown</A>"
			if (src.timing)
				d2 = "<A href='?src=\ref[src];time=0'>Stop Time Lock</A>"
			else
				d2 = "<A href='?src=\ref[src];time=1'>Initiate Time Lock</A>"
			var/second = src.time % 60
			var/minute = (src.time - second) / 60
			var/dat = text("<HTML><HEAD></HEAD><BODY><TT><B>Fire alarm</B> []\n<HR>\nTimer System: []<BR>\nTime Left: [][] <A href='?src=\ref[];tp=-30'>-</A> <A href='?src=\ref[];tp=-1'>-</A> <A href='?src=\ref[];tp=1'>+</A> <A href='?src=\ref[];tp=30'>+</A>\n</TT></BODY></HTML>", d1, d2, (minute ? text("[]:", minute) : null), second, src, src, src, src)
			user.client_mob() << browse(dat, "window=firealarm")
		else
			A = A.loc
			if (A.fire)
				d1 = text("<A href='?src=\ref[];reset=1'>[]</A>", src, stars("Reset - Lockdown"))
			else
				d1 = text("<A href='?src=\ref[];alarm=1'>[]</A>", src, stars("Alarm - Lockdown"))
			if (src.timing)
				d2 = text("<A href='?src=\ref[];time=0'>[]</A>", src, stars("Stop Time Lock"))
			else
				d2 = text("<A href='?src=\ref[];time=1'>[]</A>", src, stars("Initiate Time Lock"))
			var/second = src.time % 60
			var/minute = (src.time - second) / 60
			var/dat = text("<HTML><HEAD></HEAD><BODY><TT><B>[]</B> []\n<HR>\nTimer System: []<BR>\nTime Left: [][] <A href='?src=\ref[];tp=-30'>-</A> <A href='?src=\ref[];tp=-1'>-</A> <A href='?src=\ref[];tp=1'>+</A> <A href='?src=\ref[];tp=30'>+</A>\n</TT></BODY></HTML>", stars("Fire alarm"), d1, d2, (minute ? text("[]:", minute) : null), second, src, src, src, src)
			user.client_mob() << browse(dat, "window=firealarm")
		return


	// Handle topic links from interaction window

	Topic(href, href_list)
		..()
		if (usr.stat || stat&NOPOWER)
			return

		if ((usr.contents.Find(src) || (get_dist(src, usr) <= 1 && istype(src.loc, /turf))) || (istype(usr, /mob/ai)))
			usr.machine = src

			if (href_list["reset"])
				src.reset()

			else if (href_list["alarm"])
				src.alarm()

			else if (href_list["time"])
				src.timing = text2num(href_list["time"])

			else if (href_list["tp"])
				var/tp = text2num(href_list["tp"])
				src.time += tp
				src.time = min(max(round(src.time), 0), 120)

			src.updateDialog()
			src.add_fingerprint(usr)
		else
			usr.client_mob() << browse(null, "window=firealarm")
			return
		return


	// Reset the alarm. Area icon updated, all firedoors in area opened.

	proc/reset()
		var/area/A = src.loc
		A = A.loc
		if (!( istype(A, /area) ))
			return
		A.fire = 0
		A.mouse_opacity = 0
		A.updateicon()

		for(var/obj/machinery/door/firedoor/D in A)
			if (D.density)
				spawn( 0 )
					D.openfire()
					return
		return


	// Trigger the alarm. Calls area/firealert()

	proc/alarm()
		var/area/A = src.loc
		A = A.loc
		if (!( istype(A, /area) ))
			return
		A.firealert()
		return
