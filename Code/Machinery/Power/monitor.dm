/*
 *	Power Monitor - reports the available power, load, and status of APCs on the same power network.
 *
 *	Also allows (limited) remote control of APCs on same network
 */

obj/machinery/power/monitor
	name = "power monitoring computer"
	icon = 'stationobjs.dmi'
	icon_state = "power_computer"
	density = 1
	anchored = 1
	var
		control = 0						// true if remote APC control is enabled
		access = "4000/2030/3004"		// ID card access levels needed to enable remote control
		allowed = "Systems"				// ID card job assignment needed to enable remote control

	//Attack by AI, show report window
	
	attack_ai(mob/user)
		add_fingerprint(user)

		if(stat & (BROKEN|NOPOWER))
			return
		interact(user)

	// Attack with hand, show report window

	attack_hand(mob/user)
		add_fingerprint(user)

		if(stat & (BROKEN|NOPOWER))
			return
		interact(user)


	// Attack with item
	// If ID card, check access and enable/disable remote APC control

	attackby(obj/item/weapon/W, mob/user)
		if(stat & (BROKEN|NOPOWER))
			return
		if (istype(W, /obj/item/weapon/card/id) )			// trying to toggle remote control with an ID card

			var/obj/item/weapon/card/id/I = W
			if (I.check_access(access, allowed))
				control = !control
				user.client_mob() << "You [ control ? "enable" : "disable"] remote APC control."
			else
				user.client_mob() << "\red Access denied."
		else
			attack_hand(user)		// otherwise interact as usual

	// Show the interaction window to the user

	proc/interact(mob/user)

		if ( (get_dist(src, user) > 1 ) || (stat & (BROKEN|NOPOWER)) )
			if (!istype(user, /mob/ai))	
				user.machine = null
				user.client_mob() << browse(null, "window=powcomp")
				return


		user.machine = src
		var/t = "<TT><B>Power Monitoring</B><HR>"


		if(!powernet)
			t += "\red No connection"
		else

			var/list/L = list()
			for(var/obj/machinery/power/terminal/term in powernet.nodes)
				if(istype(term.master, /obj/machinery/power/apc))
					var/obj/machinery/power/apc/A = term.master
					L += A

			t += "<PRE>Total power: [powernet.avail] W<BR>Total load:  [num2text(powernet.viewload,10)] W<BR>"

			t += "<FONT SIZE=-1>"

			if(L.len > 0)

				if(control)
					t += "<I><BIG>(Swipe ID card to disable remote control.)</BIG></I><BR>"
				else
					t += "<I><BIG>(Swipe ID card to enable remote control.)</BIG></I><BR>"

				t += "Area                           Brkr./Eqp./Lgt./Env.  Load   Cell<HR>"

				var/list/S = list(" Off","AOff","  On", " AOn")
				var/list/chg = list("N","C","F")

				for(var/obj/machinery/power/apc/A in L)

					t += copytext(add_tspace(A.area.name, 30), 1, 30)
					if(control)
						t += " (<A href='?src=\ref[src];apc=\ref[A];breaker=1'>[A.operating? " On" : "Off"]</A>)"
					else
						t += " ([A.operating? "On " : "Off"])"

					t += " [S[A.equipment+1]] [S[A.lighting+1]] [S[A.environ+1]] [add_lspace(A.lastused_total, 6)]  [A.cell ? "[add_lspace(round(A.cell.percent()), 3)]% [chg[A.charging+1]]" : "  N/C"]<BR>"

			t += "</FONT></PRE>"

		t += "<BR><HR><A href='?src=\ref[src];close=1'>Close</A></TT>"

		user.client_mob() << browse(t, "window=powcomp;size=450x740")


	// Handle topic links from the interaction window

	Topic(href, href_list)
		..()
		if (usr.stat || usr.restrained() )
			return
		if ((!( istype(usr, /mob/human) ) && (!( ticker ) || (ticker && ticker.mode != "monkey"))))
			if (!istype(usr, /mob/ai))
				if (!istype(usr, /mob/drone))
					usr.client_mob() << "\red You don't have the dexterity to do this!"
					return

		if (( (get_dist(src, usr) <= 1 && istype(src.loc, /turf)) || (istype(usr, /mob/ai))))
			usr.machine = src
			if (href_list["breaker"])
				var/obj/machinery/power/apc/APC = locate(href_list["apc"])
				APC.operating = !APC.operating
				APC.update()
				APC.updateicon()
				for(var/mob/M in viewers(1, src))
					if ((M.client && M.machine == src))
						src.interact(M)
			else if( href_list["close"] )
				usr.client_mob() << browse(null, "window=powcomp")
				usr.machine = null
				return
		else
			usr.client_mob() << browse(null, "window=powcomp")
			usr.machine = null

	// Timed process - use power, update window to viewers

	process()
		if(!(stat & (NOPOWER|BROKEN)) )

			use_power(250)


		src.updateDialog()


	// Power changed in location area - update icon to unpowered state, set stat

	power_change()

		if(stat & BROKEN)
			icon_state = "broken"
		else
			if( powered() )
				icon_state = initial(icon_state)
				stat &= ~NOPOWER
			else
				spawn(rand(0, 15))
					src.icon_state = "c_unpowered"
					stat |= NOPOWER
