/*
 *	Junction - a junction between standard and heat-exchanger pipe.
 *
 */

obj/machinery/junction
	name = "junction"
	icon = 'pipes.dmi'
	icon_state = "junction"
	desc = "A junction between regular and heat-exchanger pipework."
	anchored = 1
	dir = 2
	p_dir = 1				// junctions are unique in that the have both p_dir (standard pipe) and h_dir (h/e pipe) set
	h_dir = 2				//
	capmult = 2

	var/obj/substance/gas/gas = null			// the gas reservoir
	var/obj/substance/gas/ngas = null

	var/obj/machinery/node1 = null				// the node connecting to the h/e pipe
	var/obj/machinery/node2 = null				// the node connecting to the standard pipe

	var/obj/machinery/vnode1					// the pipeline object of the h/e pipe
	var/obj/machinery/vnode2					// the pipeline object of the standard pipe

	var/capacity = 6000000						// nominal gas capacity


	// Create a new junction, create gas reservoir
	// Calculated p_dir and h_dir from the icon dir

	New()
		..()
		gas = new/obj/substance/gas(src)
		ngas = new/obj/substance/gas()
		gasflowlist += src

		h_dir = dir					// the h/e pipe is in icon dir
		p_dir = turn(dir, 180)		// the reg pipe is in opposite dir


	// Find the connected machines or pipes

	buildnodes()

		var/turf/T = src.loc

		node1 = get_he_machine(level, T, h_dir )		// the h/e pipe

		node2 = get_machine(level, T , p_dir )			// the regular pipe

		vnode1 = node1 ? node1.getline() : null
		vnode2 = node2 ? node2.getline() : null

		return


	// Replace gas levels with the newly calculated values

	gas_flow()
		gas.replace_by(ngas)


	// Calculate the flow through the junction

	process()
		var/delta_gt

		if(vnode1)
			delta_gt = FLOWFRAC * ( vnode1.get_gas_val(src) - gas.tot_gas() / capmult)
			calc_delta( src, gas, ngas, vnode1, delta_gt)
		else
			leak_to_turf(1)

		if(vnode2)
			delta_gt = FLOWFRAC * ( vnode2.get_gas_val(src) - gas.tot_gas() / capmult)
			calc_delta( src, gas, ngas, vnode2, delta_gt)

		else
			leak_to_turf(2)


	// Return the gas fullness value

	get_gas_val(from)
		return gas.tot_gas()/capmult


	// Return the gas reservoir

	get_gas(from)
		return gas


	// If a node is not connected, leak gas to the turf location

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

		flow_to_turf(gas, ngas, T)


	// Attack by item
	// If welder, make a fitting and delete self

	attackby(obj/item/weapon/W, mob/user)

		if(istype(W, /obj/item/weapon/weldingtool))
			if(attack_welder(W, user))
				del(src)
		else
			..()
