/*
 *	Heater - A machine that allows heating of gases.
 *
 * 			 Can siphon/fill gas from ab attached tank, or connect to pipe network via a connector.
 *
 */



obj/machinery/atmoalter/heater
	name = "heater"
	icon = 'stationobjs.dmi'
	icon_state = "heater1"
	density = 1

	// from atmoalter
	maximum = 1.3E8
	anchored = 1.0
	t_status = 3.0
	t_per = 50.0
	c_per = 50.0
	c_status = 0.0
	holding = null			// the inserted tank item, or null if none
	var
		h_tar = 20.0				// the target temperature (degC)
		h_status = 0.0				// the heater status 0=off, 1=on
		heatrate = 1500000.0		// the rate at which heating takes place


	// Create a new heater, set gas content & maximum capacity

	New()

		..()
		src.gas = new /obj/substance/gas( src )
		src.gas.maximum = src.maximum
		return


	// Set the heater's icon state depending on status

	proc/setstate()

		if(stat & NOPOWER)
			icon_state = "heater-p"
			return

		if (src.holding)
			src.icon_state = "heater1-h"
		else
			src.icon_state = "heater1"
		return


	// Timer process. Heat the contained gas towards the target temperature, and flow gas to/from tank is valve open.

	process()

		if(stat & NOPOWER)	return
		use_power(5)

		var/turf/T = src.loc
		if (istype(T, /turf))
			if (locate(/obj/move, T))
				T = locate(/obj/move, T)
		else
			T = null


		if (src.h_status)				// true if heating on
			var/t1 = src.gas.tot_gas()
			if ((t1 > 0 && src.gas.temperature < (src.h_tar+T0C)))	// note gas.temperature in kelvin but target temp in celcius
				var/increase = src.heatrate / t1
				var/n_temp = src.gas.temperature + increase
				src.gas.temperature = min(n_temp, (src.h_tar+T0C))

				use_power( src.h_tar*8)

		switch(src.t_status)		// main valve; 1=release, 2=siphon, 3=stop
			if(1.0)
				if (src.holding)
					var/t1 = src.gas.tot_gas()
					var/t2 = t1
					var/t = src.t_per
					if (src.t_per > t2)
						t = t2
					src.holding.gas.transfer_from(src.gas, t)
				else
					src.t_status = 3
			if(2.0)
				if (src.holding)
					var/t1 = src.gas.tot_gas()
					var/t2 = src.maximum - t1
					var/t = src.t_per
					if (src.t_per > t2)
						t = t2
					src.gas.transfer_from(src.holding.gas, t)
				else
					src.t_status = 3
			else

		// Pipe valve transfer handled by /obj/machinery/connector process()

		updateDialog()
		src.setstate()
		return

	// AI interact same as human

	attack_ai(mob/user)
		return src.attack_hand(user)

	// monkey interact same as human

	attack_paw(mob/user)
		return src.attack_hand(user)


	// interact, show window

	attack_hand(var/mob/user)

		if(stat & NOPOWER)	return

		user.machine = src
		var/tt
		switch(src.t_status)
			if(1.0)
				tt = "Releasing <A href='?src=\ref[src];t=2'>Siphon</A> <A href='?src=\ref[src];t=3'>Stop</A>"
			if(2.0)
				tt = "<A href='?src=\ref[src];t=1'>Release</A> Siphoning<A href='?src=\ref[src];t=3'>Stop</A>"
			if(3.0)
				tt = "<A href='?src=\ref[src];t=1'>Release</A> <A href='?src=\ref[src];t=2'>Siphon</A> Stopped"
			else

		var/ht = null
		if (src.h_status)
			ht = "Heating <A href='?src=\ref[src];h=2'>Stop</A>"
		else
			ht = "<A href='?src=\ref[src];h=1'>Heat</A> Stopped"

		var/ct = null
		switch(src.c_status)
			if(1.0)
				ct = "Releasing <A href='?src=\ref[src];c=2'>Accept</A> <A href='?src=\ref[src];ct=3'>Stop</A>"
			if(2.0)
				ct = "<A href='?src=\ref[src];c=1'>Release</A> Accepting <A href='?src=\ref[src];c=3'>Stop</A>"
			if(3.0)
				ct = "<A href='?src=\ref[src];c=1'>Release</A> <A href='?src=\ref[src];c=2'>Accept</A> Stopped"
			else
				ct = "Disconnected"

		var/dat = text("<TT><B>Canister Valves</B><BR>\n<FONT color = 'blue'><B>Contains/Capacity</B> [] / []</FONT><BR>\nUpper Valve Status: [][]<BR>\n\t<A href='?src=\ref[];tp=-[]'>M</A> <A href='?src=\ref[];tp=-10000'>-</A> <A href='?src=\ref[];tp=-1000'>-</A> <A href='?src=\ref[];tp=-100'>-</A> <A href='?src=\ref[];tp=-1'>-</A> [] <A href='?src=\ref[];tp=1'>+</A> <A href='?src=\ref[];tp=100'>+</A> <A href='?src=\ref[];tp=1000'>+</A> <A href='?src=\ref[];tp=10000'>+</A> <A href='?src=\ref[];tp=[]'>M</A><BR>\nHeater Status: [] - []<BR>\n\tTrg Tmp: <A href='?src=\ref[];ht=-50'>-</A> <A href='?src=\ref[];ht=-5'>-</A> <A href='?src=\ref[];ht=-1'>-</A> [] <A href='?src=\ref[];ht=1'>+</A> <A href='?src=\ref[];ht=5'>+</A> <A href='?src=\ref[];ht=50'>+</A><BR>\n<BR>\nPipe Valve Status: []<BR>\n\t<A href='?src=\ref[];cp=-[]'>M</A> <A href='?src=\ref[];cp=-10000'>-</A> <A href='?src=\ref[];cp=-1000'>-</A> <A href='?src=\ref[];cp=-100'>-</A> <A href='?src=\ref[];cp=-1'>-</A> [] <A href='?src=\ref[];cp=1'>+</A> <A href='?src=\ref[];cp=100'>+</A> <A href='?src=\ref[];cp=1000'>+</A> <A href='?src=\ref[];cp=10000'>+</A> <A href='?src=\ref[];cp=[]'>M</A><BR>\n<BR>\n<A href='?src=\ref[];mach_close=canister'>Close</A><BR>\n</TT>", src.gas.tot_gas(), src.maximum, tt, (src.holding ? text("<BR><A href='?src=\ref[];tank=1'>Tank ([]</A>)", src, src.holding.gas.tot_gas()) : null), src, num2text(1000000.0, 7), src, src, src, src, src.t_per, src, src, src, src, src, num2text(1000000.0, 7), ht, (src.gas.tot_gas() ? (src.gas.temperature-T0C) : 20), src, src, src, src.h_tar, src, src, src, ct, src, num2text(1000000.0, 7), src, src, src, src, src.c_per, src, src, src, src, src, num2text(1000000.0, 7), user)
		user << browse(dat, "window=canister;size=600x300")
		return


	// handle topic links from interaction window

	Topic(href, href_list)
		..()
		if (usr.stat || usr.restrained())
			return
		if ((get_dist(src, usr) <= 1 && istype(src.loc, /turf)) || (istype(usr, /mob/ai)))
			usr.machine = src

			if (href_list["c"])
				var/c = text2num(href_list["c"])
				switch(c)
					if(1.0)
						src.c_status = 1
					if(2.0)
						src.c_status = 2
					if(3.0)
						src.c_status = 3
					else
			else if (href_list["t"])
				var/t = text2num(href_list["t"])
				if (src.t_status == 0)
					return
				switch(t)
					if(1.0)
						src.t_status = 1
					if(2.0)
						src.t_status = 2
					if(3.0)
						src.t_status = 3
					else
			else if (href_list["h"])
				var/h = text2num(href_list["h"])
				if (h == 1)
					src.h_status = 1
				else
					src.h_status = null
			else if (href_list["tp"])
				var/tp = text2num(href_list["tp"])
				src.t_per += tp
				src.t_per = min(max(round(src.t_per), 0), 1000000.0)
			else if (href_list["cp"])
				var/cp = text2num(href_list["cp"])
				src.c_per += cp
				src.c_per = min(max(round(src.c_per), 0), 1000000.0)
			else if (href_list["ht"])
				var/cp = text2num(href_list["ht"])
				src.h_tar += cp
				src.h_tar = min(max(round(src.h_tar), 0), 500)
			else if (href_list["tank"])
				var/cp = text2num(href_list["tank"])
				if ((cp == 1 && src.holding))
					src.holding.loc = src.loc
					src.holding = null
					if (src.t_status == 2)
						src.t_status = 3

			src.updateDialog()
			src.add_fingerprint(usr)
		else
			usr << browse(null, "window=canister")
			return
		return

	// attack by tank, insert the tank
	// attack by wrench, connect to pipe connector (if present)

	attackby(var/obj/item/weapon/W, var/mob/user)

		if (istype(W, /obj/item/weapon/tank))
			if (src.holding)
				return
			var/obj/item/weapon/tank/T = W
			user.drop_item()
			T.loc = src
			src.holding = T

		else if (istype(W, /obj/item/weapon/wrench))
			var/obj/machinery/connector/con = locate(/obj/machinery/connector, src.loc)

			if (src.c_status)
				src.anchored = 0
				src.c_status = 0
				user.show_message("\blue You have disconnected the heater.", 1)
				if(con)
					con.connected = null
			else
				if (con && !con.connected)
					src.anchored = 1
					src.c_status = 3
					user.show_message("\blue You have connected the heater.", 1)
					con.connected = src
				else
					user.show_message("\blue There is no connector here to attach the heater to.", 1)
		return


