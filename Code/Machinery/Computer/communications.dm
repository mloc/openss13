/*
 *	Communications -- the communications computer
 *
 *  Used to call the emergency shuttle.
 */

obj/machinery/computer/communications
	name = "communications"
	icon = 'stationobjs.dmi'
	icon_state = "comm_computer"


	// Call the shuttle

	verb/call_shuttle()
		set src in oview(1)

		src.add_fingerprint(usr)
		if(stat & NOPOWER) return

		if ((!( ticker ) || ticker.shuttle_location == 1))
			return

		if( ticker.mode == "blob" )				// Shuttle cannot be called in blob mode
			usr << "Under directive 7-10, SS13 is quarantined until further notice."
			return

		world << "\blue <B>Alert: The emergency shuttle has been called. It will arrive in T-10:00 minutes.</B>"
		if (!( ticker.timeleft ))
			ticker.timeleft = 6000
		ticker.timing = 1


	// Cancel the shuttle call

	verb/cancel_call()
		set src in oview(1)

		src.add_fingerprint(usr)
		if(stat & NOPOWER) return
		if ((!( ticker ) || ticker.shuttle_location == 1 || ticker.timing == 0 || ticker.timeleft < 300))
			return
		if( ticker.mode == "blob" )
			return

		world << "\blue <B>Alert: The shuttle is going back!</B>"
		ticker.timing = -1.0
