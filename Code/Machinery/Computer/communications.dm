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
		var/result = src.canReach(usr, null, 1)
		if (result==0)
			usr.client_mob() << "You can't reach [src]."
			return
		src.add_fingerprint(usr)
		if(stat & NOPOWER) return
		call_shuttle_proc(usr)

	// Cancel the shuttle call

	verb/cancel_call()
		set src in oview(1)
		var/result = src.canReach(usr, null, 1)
		if (result==0)
			usr.client_mob() << "You can't reach [src]."
			return
		src.add_fingerprint(usr)
		if(stat & NOPOWER) return
		cancel_call_proc(usr)
		
