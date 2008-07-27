/*
 *	Valve - on/off valve machine, prevents gas flow through a pipe when off
 *
 *	Valves work by having two internal gas reservoirs, and flowing between them only when open.
 */

obj/machinery/valve
	name = "valve"
	icon = 'pipes.dmi'
	icon_state = "valve0"
	desc = "A gas valve."
	anchored = 1
	capmult = 2
	var
		obj/substance/gas/gas1 = null			// gas reservoir connected to node1
		obj/substance/gas/ngas1 = null

		obj/substance/gas/gas2 = null			// gas reservoir connected to node2
		obj/substance/gas/ngas2 = null

		capacity = 6000000.0

		obj/machinery/node1 = null				// pipe/machine connected to gas1
		obj/machinery/node2 = null				// pipe/machine connected to gas2
		obj/machinery/vnode1 = null				// pipeline of node1
		obj/machinery/vnode2 = null				// pipeline of node2
		id = "v1"		// Not implemented: planned id to control valves remotely
		open = 0								// true if the valve is open


	// Create a valve, create gas reservoirs.
	// p_dir calculated from icon direction

	New()
		..()
		gas1 = new/obj/substance/gas(src)
		ngas1 = new/obj/substance/gas()
		gas2 = new/obj/substance/gas(src)
		ngas2 = new/obj/substance/gas()

		gasflowlist += src
		switch(dir)
			if(1, 2)
				p_dir = 3
			if(4,8)
				p_dir = 12

		icon_state = "valve[open]"

	// Examine verb

	examine()
		set src in oview(1)
		if(usr.stat)
			return

		usr.client_mob() << "[desc] It is [ open? "open" : "closed"]."


	// Find the connected nodes

	buildnodes()

		var/turf/T = src.loc

		node1 = get_machine(level, T, dir )		// the h/e pipe

		node2 = get_machine(level, T , turn(dir, 180) )	// the regular pipe

		if(node1) vnode1 = node1.getline()
		if(node2) vnode2 = node2.getline()

		return


	// Update the gas values with the newly calculated values

	gas_flow()

		gas1.replace_by(ngas1)
		gas2.replace_by(ngas2)


	// Perform flow into and out of the valve, and if open, between the two reservoirs

	process()

		var/delta_gt

		if(vnode1)
			delta_gt = FLOWFRAC * ( vnode1.get_gas_val(src) - gas1.tot_gas() / capmult)
			calc_delta( src, gas1, ngas1, vnode1, delta_gt)

		else
			leak_to_turf(1)

		if(vnode2)
			delta_gt = FLOWFRAC * ( vnode2.get_gas_val(src) - gas2.tot_gas() / capmult)
			calc_delta( src, gas2, ngas2, vnode2, delta_gt)

		else
			leak_to_turf(2)


		if(open)		// valve operating, so transfer btwen resv1 & 2

			delta_gt = FLOWFRAC * (gas1.tot_gas() / capmult - gas2.tot_gas() / capmult)

			var/obj/substance/gas/ndelta = new()

			if(delta_gt < 0)		// then flowing from R2 to R1

				ndelta.set_frac(gas2, -delta_gt)

				ngas2.sub_delta(ndelta)
				ngas1.add_delta(ndelta)

			else				// flowing from R1 to R2
				ndelta.set_frac(gas1, delta_gt)
				ngas2.add_delta(ndelta)
				ngas1.sub_delta(ndelta)


	// Return the gas fullness value. Two reservoirs, so which value returned depends on who's asking

	get_gas_val(from)
		if(from == vnode2)
			return gas2.tot_gas()/capmult
		else
			return gas1.tot_gas()/capmult

	// Return the corresponding gas resevoir connected to the given node

	get_gas(from)
		if(from == vnode2)
			return gas2
		return gas1

	// Leak gas to turf if either node is null

	proc/leak_to_turf(var/port)
		var/turf/T


		switch(port)
			if(1)
				T = get_step(src, dir)
			if(2)
				T = get_step(src, turn(dir, 180) )

		if(T.density)
			T = src.loc
			if(T.density)
				return

		if(port==1)
			flow_to_turf(gas1, ngas1, T)
		else
			flow_to_turf(gas2, ngas2, T)

	// Monkey interact same as human

	attack_paw(mob/user)
		attack_hand(user)


	// Interact, toggle open/closed state, show correct animation, set correct final icon state

	attack_hand(mob/user)
		..()
		add_fingerprint(user)
	//	if(stat & NOPOWER) return

	//	use_power(5)

		if(!open)		// now opening
			flick("valve01", src)
			icon_state = "valve1"
			sleep(10)
		else			// now closing
			flick("valve10", src)
			icon_state = "valve0"
			sleep(10)
		open = !open