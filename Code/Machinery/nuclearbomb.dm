/*
 *  Nuclearbomb -- A nuclear explosive
 *
 *	Requires authentication disk and code to activate
 *
 *	As used in "Nuclear" mode.
 *
 *	TODO: Unify explosion proc with other explosions (plamsabombs, etc.)
 *
 */

obj/machinery/nuclearbomb
	desc = "Uh oh."
	name = "Nuclear Fission Explosive"
	icon = 'stationobjs.dmi'
	icon_state = "nuclearbomb0"
	density = 1
	flags = FPRINT|DRIVABLE

	var
		extended = 0									// True if bomb is deployed
		timeleft = 60.0									// Time (seconds) until explosion
		timing = 0										// True if counting down the timer
		r_code = "ADMIN"								// The activation code of the nuke
		code = ""										// The code typed in
		yes_code = 0									// True if typed code matches
		safety = 1										// False to enable bomb to explode
		obj/item/weapon/disk/nuclear/auth = null		// The authenication disk of the nuke, or null if none inserted


	// Create a nuclear bomb.
	// nuke_code is a global integer randomly set between 10000 and 99999

	New()

		if (nuke_code)
			src.r_code = "[nuke_code]"
		..()


	// Timed process
	// If timing, count down the timer and explode when expires
	// Update interaction window of viewing clients

	process()

		if (src.timing)
			src.timeleft--
			if (src.timeleft <= 0)
				explode()

			src.updateDialog()


	// Monkey interact same as human

	attack_paw(mob/user)
		return src.attack_hand(user)


	// Human interact
	// If already deployed, show the interaction window
	// Otherwise, deploy and anchor the bomb

	attack_hand(mob/user)
		if (src.extended)			// Bomb deployed?
			user.machine = src

									// insert auth disk here
			var/dat = {"<TT><B>Nuclear Fission Explosive</B><BR>
Auth. Disk: <A href='?src=\ref[src];auth=1'>[(src.auth ? "++++++++++" : "----------")]</A><HR>"}

			if (src.auth)				// auth disk inserted
				if (src.yes_code)		// and code is correct
										// show full control panel
					dat += {"
<B>Status</B>: [(src.timing ? "Func/Set" : "Functional")]-[(src.safety ? "Safe" : "Engaged")]<BR>
<B>Timer</B>: [src.timeleft]<BR>
<BR>
Timer: [(src.timing ? "On" : "Off")] <A href='?src=\ref[src];timer=1'>Toggle</A><BR>
Time: <A href='?src=\ref[src];time=-10'>-</A> <A href='?src=\ref[src];time=-1'>-</A> [src.timeleft] <A href='?src=\ref[src];time=1'>+</A> <A href='?src=\ref[src];time=10'>+</A><BR>
<BR>
Safety: [(src.safety ? "On" : "Off")] <A href='?src=\ref[src];safety=1'>Toggle</A><BR>
Anchor: [(src.anchored ? "Engaged" : "Off")] <A href='?src=\ref[src];anchor=1'>Toggle</A><BR>
"}

				else					// otherwise, lock controls until code entered

					dat += {"
<B>Status</B>: Auth. S2-[(src.safety ? "Safe" : "Engaged")]<BR>
<B>Timer</B>: [src.timeleft]<BR>
<BR>\nTimer: [(src.timing ? "On" : "Off")] Toggle<BR>
Time: - - [src.timeleft] + +<BR>
<BR>
Safety: [(src.safety ? "On" : "Off")] Toggle<BR>
Anchor: [(src.anchored ? "Engaged" : "Off")] Toggle<BR>
"}

			else
				if (src.timing)			// auth disk removed, but counting down, lock controls

					dat += {"
<B>Status</B>: Set-[(src.safety ? "Safe" : "Engaged")]<BR>
<B>Timer</B>: [src.timeleft]<BR>
<BR>
Timer: [(src.timing ? "On" : "Off")] Toggle<BR>
Time: - - [src.timeleft] + +<BR>
<BR>
Safety: [(src.safety ? "On" : "Off")] Toggle<BR>
Anchor: [(src.anchored ? "Engaged" : "Off")] Toggle<BR>
"}

				else					// also lock controls if not counting, no auth disk

					dat += {"
<B>Status</B>: Auth. S1-[(src.safety ? "Safe" : "Engaged")]<BR>
<B>Timer</B>: [src.timeleft]<BR>
<BR>
Timer: [(src.timing ? "On" : "Off")] Toggle<BR>
Time: - - [src.timeleft] + +<BR>
<BR>
Safety: [(src.safety ? "On" : "Off")] Toggle<BR>
Anchor: [(src.anchored ? "Engaged" : "Off")] Toggle<BR>
"}

			var/message = "AUTH"

			if (src.auth)
				message = "[src.code]"
				if (src.yes_code)
					message = "*****"
											// The keypad - enter code here
			dat += {"<HR>
[message]<BR>
<A href='?src=\ref[src];type=1'>1</A>-<A href='?src=\ref[src];type=2'>2</A>-<A href='?src=\ref[src];type=3'>3</A><BR>
<A href='?src=\ref[src];type=4'>4</A>-<A href='?src=\ref[src];type=5'>5</A>-<A href='?src=\ref[src];type=6'>6</A><BR>
<A href='?src=\ref[src];type=7'>7</A>-<A href='?src=\ref[src];type=8'>8</A>-<A href='?src=\ref[src];type=9'>9</A><BR>
<A href='?src=\ref[src];type=R'>R</A>-<A href='?src=\ref[src];type=0'>0</A>-<A href='?src=\ref[src];type=E'>E</A><BR>
</TT>"}
			user.client_mob() << browse(dat, "window=nuclearbomb;size=300x400")

		else					// Deploy and anchor the bomb.

			src.anchored = 1
			flick("nuclearbombc", src)
			src.icon_state = "nuclearbomb1"
			src.extended = 1
		return


	// Handle topic links from interaction window

	Topic(href, href_list)
		..()
		if (usr.stat || usr.restrained())
			return
		if ((!( istype(usr, /mob/human) ) && (!( ticker ) || (ticker && ticker.mode != "monkey"))))
			if (!istype(usr, /mob/drone))
				usr.client_mob() << "\red You don't have the dexterity to do this!"
				return
		if ((usr.contents.Find(src) || (get_dist(src, usr) <= 1 && istype(src.loc, /turf))))
			usr.machine = src

			if (href_list["auth"])		// auth link - if disk already inserted, remove it
				if (src.auth)
					src.auth.loc = src.loc
					src.yes_code = 0
					src.auth = null
				else					// if not inserted, check that it's in the player's hand
					var/obj/item/I = usr.equipped()
					if (istype(I, /obj/item/weapon/disk/nuclear))
						usr.drop_item()
						I.loc = src
						src.auth = I
			if (src.auth)
				if (href_list["type"])					// keypad typing
					if (href_list["type"] == "E")		// enter the current code, check against nuke code
						if (src.code == src.r_code)
							src.yes_code = 1
							src.code = null
						else
							src.code = "ERROR"
					else
						if (href_list["type"] == "R")	// reset code
							src.yes_code = 0
							src.code = null
						else
							src.code += "[href_list["type"]]"		// otherwise, add a digit
							if (length(src.code) > 5)
								src.code = "ERROR"
				if (src.yes_code)
					if (href_list["time"])
						var/time = text2num(href_list["time"])
						src.timeleft += time
						src.timeleft = min(max(round(src.timeleft), 5), 600)
					if (href_list["timer"])
						if (src.timing == -1.0)
							return
						src.timing = !( src.timing )
						if (src.timing)
							src.icon_state = "nuclearbomb2"
						else
							src.icon_state = "nuclearbomb1"
					if (href_list["safety"])
						src.safety = !( src.safety )
					if (href_list["anchor"])
						src.anchored = !( src.anchored )

			src.add_fingerprint(usr)

			src.updateDialog()
		else
			usr.client_mob() << browse(null, "window=nuclearbomb")
			return


	// On explosion, only (potentially) delete nuke if not about to explode

	ex_act()
		if (src.timing == -1.0)
			return
		else
			return ..()


	// Blob attack same as explosion

	blob_act()

		if (src.timing == -1.0)
			return
		else
			return ..()


	// Explode the nuke, destroying almost everything around
	// TODO: Unify this explosion proc with others

	proc/explode()

		if (src.safety)
			src.timing = 0
			return
		src.timing = -1.0
		src.yes_code = 0
		src.icon_state = "nuclearbomb3"
		sleep(20)							// 2 second delay
		var/turf/T = src.loc
		while(!( istype(T, /turf) ))
			T = T.loc
		var/min = 50
		var/med = 250
		var/max = 500
		var/sw = locate(1, 1, T.z)						// explosion encompasses whole of z-level
		var/ne = locate(world.maxx, world.maxy, T.z)

		defer_powernet_rebuild = 1			// Prevent powenet being rebuilt when cable objects deleted

		for(var/turf/U in block(sw, ne))
			var/zone = 4
			if ((U.y <= T.y + max && U.y >= T.y - max && U.x <= T.x + max && U.x >= T.x - max))
				zone = 3
			if ((U.y <= T.y + med && U.y >= T.y - med && U.x <= T.x + med && U.x >= T.x - med))
				zone = 2
			if ((U.y <= T.y + min && U.y >= T.y - min && U.x <= T.x + min && U.x >= T.x - min))
				zone = 1
			for(var/atom/A in U)
				A.ex_act(zone)

			U.ex_act(zone)
			U.buildlinks()


		defer_powernet_rebuild = 0		// Renable powernet rebuilt
		makepowernets()					// And do so
		ticker.nuclear(src.z)			// inform gameticker that nuke exploded
		del(src)
