/*
 *	Shuttle -- emergency shuttle control computer
 *
 *
 */

obj/machinery/computer/shuttle
	name = "shuttle"
	icon = 'shuttle.dmi'
	icon_state = "shuttlecom"

	var
		auth_need = 3						// number of authorizations needed to launch shuttle early
		list/authorized = list(  )			// list of names of those authorizing the early launch
		allowed								// ID card job assignmented needed to authorize (none)
		access = "2000"						// ID card access level needed to authorize


	// Restabalize verb
	// Set all shuttle locations to standard atmosphere

	verb/restabalize()
		set src in oview(1)

		world << "\red <B>Restabalizing shuttle atmosphere!</B>"
		var/A = locate(/area/shuttle)
		for(var/obj/move/T in A)
			T.firelevel = 0
			T.oxygen = O2STANDARD
			T.oldoxy = O2STANDARD
			T.tmpoxy = O2STANDARD
			T.poison = 0
			T.oldpoison = 0
			T.tmppoison = 0
			T.co2 = 0
			T.oldco2 = 0
			T.tmpco2 = 0
			T.sl_gas = 0
			T.osl_gas = 0
			T.tsl_gas = 0
			T.n2 = N2STANDARD
			T.on2 = N2STANDARD
			T.tn2 = N2STANDARD
			T.temp = T20C
			T.otemp = T20C
			T.ttemp = T20C

		world << "\red <B>Shuttle Restabalized!</B>"
		src.add_fingerprint(usr)


	// Hijack verb
	// Can be used only by the traitor to end a round
	// Note can only occur when shuttle is at CC, not at the station level

	verb/hijack()
		set src in oview(1)

		if ((!( ticker ) || ticker.shuttle_location != shuttle_z))
			return
		if (usr != ticker.killer)
			return
		world << "\blue <B>Alert: The shuttle is has been hijacked prematurely by the traitor!</B>"
		ticker.timing = 0
		ticker.check_win()
		src.add_fingerprint(usr)


	// Attack with object
	// Allows shuttle to be launched early if 3 ID card of sufficient level (from different holders) are used

	attackby(obj/item/weapon/card/id/W, mob/user)


		if ((!( istype(W, /obj/item/weapon/card/id) ) || !( ticker ) || ticker.shuttle_location == shuttle_z || !( user )))
			return
		if (!W.check_access(access, allowed))
			user << text("The access level ([]) of [] card is not high enough. ", W.access_level, W.registered)
			return
		var/choice = alert(user, text("Would you like to (un)authorize a shortened launch time? [] authorization\s are still needed. Use abort to cancel all authorizations.", src.auth_need - src.authorized.len), "Shuttle Launch", "Authorize", "Repeal", "Abort")
		switch(choice)
			if("Authorize")
				src.authorized -= W.registered
				src.authorized += W.registered
				if (src.auth_need - src.authorized.len > 0)
					world << text("\blue <B>Alert: [] authorizations needed until shuttle is launched early</B>", src.auth_need - src.authorized.len)
				else
					world << "\blue <B>Alert: Shuttle launch time shortened to 10 seconds!</B>"
					ticker.timeleft = 100
					//src.authorized = null
					del(src.authorized)
					src.authorized = list(  )
			if("Repeal")
				src.authorized -= W.registered
				world << text("\blue <B>Alert: [] authorizations needed until shuttle is launched early</B>", src.auth_need - src.authorized.len)
			if("Abort")
				world << "\blue <B>All authorizations to shorting time for shuttle launch have been revoked!</B>"
				src.authorized.len = 0
				src.authorized = list(  )
