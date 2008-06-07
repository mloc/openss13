/*
 *	Canister - base gas canister object. Actual placed canister will be one of 6 types defined below
 *
 *				Can release gas into atmosphere, fill or siphon gas from an attached tank,
 * 				or release or accept gas from an attached pipe connector.
 *
 */

obj/machinery/atmoalter/canister
	name = "canister"
	icon = 'canister.dmi'
	density = 1

	// from atmoalter
	maximum = 1.3E8
	t_status = 3.0
	t_per = 50.0
	c_per = 50.0
	c_status = 0.0
	holding = null

	flags = FPRINT|DRIVABLE
	weight = 1.0E7

	var
		color = "blue"				// used to set icon_state
		health = 20.0				// health removed by attacks & fire
		destroyed = null			// true if the canister has broken
		filled = 1.0				//fractional fullness at spawn 0=empty, 1=full


	// Create a new canister. This is called by all canister types
	// Create the gas contents object and set the maximum capacity

	New()
		..()
		src.gas = new /obj/substance/gas( src )
		src.gas.maximum = src.maximum
		return


	// Update the icon state and overlays to reflect canister type and fullness

	proc/update_icon()

		var/air_in = src.gas.tot_gas()		// the amount of gas in the canister

		src.overlays = 0

		if (destroyed)
			icon_state = "[color]-1"

		else
			icon_state = "[color]"
			if(holding)
				overlays += image('canister.dmi', "can-oT")

			if (air_in < 10)
				overlays += image('canister.dmi', "can-o0")
			else if (air_in < (src.gas.maximum * 0.2))
				overlays += image('canister.dmi', "can-o1")
			else if (air_in < (src.maximum * 0.6))
				overlays += image('canister.dmi', "can-o2")
			else
				overlays += image('canister.dmi', "can-o3")
		return




	// Timed process. Depending on valve state, release or accept gas

	process()

		if (src.destroyed)
			return
		var/T = src.loc
		if (istype(T, /turf))
			if (locate(/obj/move, T))
				T = locate(/obj/move, T)
		else
			T = null
		switch(src.t_status)
			if(1.0)									// Valve set to release
				if (src.holding)					// If holding a tank, release the gas into that tank
					var/t1 = src.gas.tot_gas()
					var/t2 = t1
					var/t = src.t_per
					if (src.t_per > t2)
						t = t2
					src.holding.gas.transfer_from(src.gas, t)
				else								// If not holding a tank, release gas into the turf
					if (T)
						var/t1 = src.gas.tot_gas()
						var/t2 = t1
						var/t = src.t_per
						if (src.t_per > t2)
							t = t2
						src.gas.turf_add(T, t)
				src.update_icon()
			if(2.0)									// Valve set to accept
				if (src.holding)					// Siphon gas from the tank into the canister
					var/t1 = src.gas.tot_gas()
					var/t2 = src.maximum - t1
					var/t = src.t_per
					if (src.t_per > t2)
						t = t2
					src.gas.transfer_from(src.holding.gas, t)
				else								// If no tank, do nothing
					src.t_status = 3
				src.update_icon()


		// Transfer for pipe valve is handled by /obj/machinery/connector process() proc


		src.updateDialog()
		src.update_icon()
		return


	//Returns the gas contents object

	get_gas()
		return gas


	// Called when the turf location is burning
	// Reduce health, then check if destroyed

	burn(fi_amount)
		src.health -= 1
		healthcheck()
		return


	// Called when attacked by a blob
	// Reduce health, then check if destroyed

	blob_act()
		src.health -= 1
		healthcheck()
		return

	// Called when hit by a meteor
	// Destroy the canister

	meteorhit(var/obj/O)
		src.health = 0
		healthcheck()
		return


	// Called when hit by a projectile

	las_act(flag)

		if (flag == "bullet")
			src.health = 0
			spawn( 0 )
				healthcheck()
				return
		if (flag)
			var/turf/T = src.loc
			if (!( istype(T, /turf) ))
				return
			else
				T.firelevel = T.poison
		else
			src.health = 0
			spawn( 0 )
				healthcheck()
				return
		return



	// If the canister is damaged enough, destroy it and release all gas contained

	proc/healthcheck()

		if (src.health <= 10)
			var/T = src.loc
			if (!( istype(T, /turf) ))
				return
			src.gas.turf_add(T, -1.0)
			src.destroyed = 1
			src.density = 0
			update_icon()
			if (src.holding)
				src.holding.loc = src.loc
				src.holding = null
			if (src.t_status == 2)
				src.t_status = 3
		return

	// AI interact same as human

	attack_ai(var/mob/user)
		return src.attack_hand(user)


	// Monkey interact same as human

	attack_paw(var/mob/user)
		return src.attack_hand(user)


	// Interact with canister, shows interaction window

	attack_hand(var/mob/user)

		if (src.destroyed)
			return
		user.machine = src
		var/tt
		switch(src.t_status)		// Main valve
			if(1.0)
				tt = "Releasing <A href='?src=\ref[src];t=2'>Siphon (only tank)</A> <A href='?src=\ref[src];t=3'>Stop</A>"
			if(2.0)
				tt = "<A href='?src=\ref[src];t=1'>Release</A> Siphoning (only tank) <A href='?src=\ref[src];t=3'>Stop</A>"
			if(3.0)
				tt = "<A href='?src=\ref[src];t=1'>Release</A> <A href='?src=\ref[src];t=2'>Siphon (only tank)</A> Stopped"
			else
		var/ct = null
		switch(src.c_status)		// Pipe valve
			if(1.0)
				ct = "Releasing <A href='?src=\ref[src];c=2'>Accept</A> <A href='?src=\ref[src];c=3'>Stop</A>"
			if(2.0)
				ct = "<A href='?src=\ref[src];c=1'>Release</A> Accepting <A href='?src=\ref[src];c=3'>Stop</A>"
			if(3.0)
				ct = "<A href='?src=\ref[src];c=1'>Release</A> <A href='?src=\ref[src];c=2'>Accept</A> Stopped"
			else
				ct = "Disconnected"


		var/dat = {"<TT><B>Canister Valves</B><BR>
<FONT color = 'blue'><B>Contains/Capacity</B> [num2text(src.gas.tot_gas(), 20)] / [num2text(src.maximum, 20)]</FONT><BR>
Upper Valve Status: [tt]<BR>
\t[(src.holding ? "<A href='?src=\ref[src];tank=1'>Tank ([src.holding.gas.tot_gas()]</A>)" : null)]<BR>
\t<A href='?src=\ref[src];tp=-[num2text(1000000.0, 7)]'>M</A> <A href='?src=\ref[src];tp=-10000'>-</A> <A href='?src=\ref[src];tp=-1000'>-</A> <A href='?src=\ref[src];tp=-100'>-</A> <A href='?src=\ref[src];tp=-1'>-</A> [src.t_per] <A href='?src=\ref[src];tp=1'>+</A> <A href='?src=\ref[src];tp=100'>+</A> <A href='?src=\ref[src];tp=1000'>+</A> <A href='?src=\ref[src];tp=10000'>+</A> <A href='?src=\ref[src];tp=[num2text(1000000.0, 7)]'>M</A><BR>
Pipe Valve Status: [ct]<BR>
\t<A href='?src=\ref[src];cp=-[num2text(1000000.0, 7)]'>M</A> <A href='?src=\ref[src];cp=-10000'>-</A> <A href='?src=\ref[src];cp=-1000'>-</A> <A href='?src=\ref[src];cp=-100'>-</A> <A href='?src=\ref[src];cp=-1'>-</A> [src.c_per] <A href='?src=\ref[src];cp=1'>+</A> <A href='?src=\ref[src];cp=100'>+</A> <A href='?src=\ref[src];cp=1000'>+</A> <A href='?src=\ref[src];cp=10000'>+</A> <A href='?src=\ref[src];cp=[num2text(1000000.0, 7)]'>M</A><BR>
<BR>
<A href='?src=\ref[user];mach_close=canister'>Close</A><BR>
</TT>"}

		user.client_mob() << browse(dat, "window=canister;size=600x300")
		return


	// Process topic link from interaction window

	Topic(href, href_list)
		usr.client_mob() << "Topic on canister, usr is [usr], src is [src], usr.client_mob() is [usr.client_mob()], href is ([href]), href_list is ([href_list])."
	
		..()
		if (usr.stat || usr.restrained())
			return
		if ((get_dist(src, usr) <= 1 && istype(src.loc, /turf)))
			usr.machine = src

			if (href_list["c"])
				var/c = text2num(href_list["c"])
				switch(c)
					if(1.0)
						src.c_status = 1
					if(2.0)
						c_status = 2
					if(3.0)
						src.c_status = 3

			else if (href_list["t"])
				var/t = text2num(href_list["t"])
				if (src.t_status == 0)
					return
				switch(t)
					if(1.0)
						src.t_status = 1
					if(2.0)
						if (src.holding)
							src.t_status = 2
						else
							src.t_status = 3
					if(3.0)
						src.t_status = 3

			else if (href_list["tp"])
				var/tp = text2num(href_list["tp"])
				src.t_per += tp
				src.t_per = min(max(round(src.t_per), 0), 1000000.0)

			else if (href_list["cp"])
				var/cp = text2num(href_list["cp"])
				src.c_per += cp
				src.c_per = min(max(round(src.c_per), 0), 1000000.0)

			else if (href_list["tank"])
				var/cp = text2num(href_list["tank"])
				if ((cp == 1 && src.holding))
					src.holding.loc = src.loc
					src.holding = null
					if (src.t_status == 2)
						src.t_status = 3

			src.updateDialog()
			src.add_fingerprint(usr)
			update_icon()

		else
			usr.client_mob() << browse(null, "window=canister")


	// Attack by an object
	// If a tank, insert the tank
	// If a wrench (and a connector is present), attach/unattach canister from pipe connector
	// Otherwise, damage the canister

	attackby(var/obj/item/weapon/W, var/mob/user)

		if ((istype(W, /obj/item/weapon/tank) && !( src.destroyed )))
			if (src.holding)
				return
			var/obj/item/weapon/tank/T = W
			user.drop_item()
			T.loc = src
			src.holding = T
			update_icon()

		else if ((istype(W, /obj/item/weapon/wrench)))
			var/obj/machinery/connector/con = locate(/obj/machinery/connector, src.loc)

			if (src.c_status)		// note: don't check is cansiter is destroyed to allow user to unhook a broken cansiter
				src.anchored = 0
				src.c_status = 0
				user.show_message("\blue You have disconnected the canister.", 1)
				if(con)
					con.connected = null
			else
				if(con && !con.connected && !destroyed)
					src.anchored = 1
					src.c_status = 3
					user.show_message("\blue You have connected the canister.", 1)
					con.connected = src
				else
					user.show_message("\blue There is nothing here with which to connect the canister.", 1)
		else
			switch(W.damtype)
				if("fire")
					src.health -= W.force
				if("brute")
					src.health -= W.force * 0.5
				else
			src.healthcheck()
			..()
		return


	/*
	 *	The specific canister types
	 */

	// Canister containing plasma

	poisoncanister
		name = "Canister \[Plasma (Bio)\]"
		icon_state = "orange"
		color = "orange"

		New()
			..()
			src.update_icon()
			src.gas.plasma = 9.0E7*filled
			return


	// Canister containing oxygen

	oxygencanister
		name = "Canister: \[O2\]"
		icon_state = "blue"
		color = "blue"

		New()
			..()
			src.gas.oxygen = 1.0E8*filled
			return


	// Canister containing N2O

	anesthcanister
		name = "Canister: \[N2O\]"
		icon_state = "redws"
		color = "redws"

		New()
			..()
			src.gas.sl_gas = 1.0E8*filled
			return


	// Canister containing nitrogen

	n2canister
		name = "Canister: \[N2\]"
		icon_state = "red"
		color = "red"

		New()
			..()
			src.gas.n2 = 1.0E8*filled
			return


	// Canister containing carbon dioxide

	co2canister
		name = "Canister \[CO2\]"
		icon_state = "black"
		color = "black"

		New()
			..()
			src.gas.co2 = 1.0E8*filled
			return


	// Canister containing air mixture (21% O2, 79% N2)

	aircanister
		name = "Canister \[Air\]"
		icon_state = "grey"
		color = "grey"

		New()
			..()
			src.gas.oxygen = 2.1e7*filled
			src.gas.n2 = 7.9e7*filled
			return



