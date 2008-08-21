/*
 *	Manifold - Machine that allows three gas lines to be connected together.
 *
 */


obj/machinery/manifold
	name = "manifold"
	icon = 'pipes.dmi'
	icon_state = "manifold"
	desc = "A three-port gas manifold."
	anchored = 1
	dir = 2
	p_dir = 14
	capmult = 3

	var
		n1dir			// direction of node1
		n2dir			// direction of node2
						// "dir" is the direction of node3

		obj/substance/gas/gas = null		// the gas reservoir
		obj/substance/gas/ngas = null
		capacity = 6000000.0				// nominal gas capacity

		obj/machinery/node1 = null			// }
		obj/machinery/node2 = null			// } the machine connected to each port
		obj/machinery/node3 = null			// }

		obj/machinery/vnode1				// }
		obj/machinery/vnode2				// } the pipeline connected to each port, if nodeX is a pipe object
		obj/machinery/vnode3				// }



	// Create a new manifold. Pipe p_dir is calculated from the icon dir, so p_dir does not need to be set on map.

	New()
		..()
		switch(dir)
			if(NORTH)
				p_dir = 13 //NORTH|EAST|WEST

			if(SOUTH)
				p_dir = 14 //SOUTH|EAST|WEST

			if(EAST)
				p_dir = 7 //EAST|NORTH|SOUTH

			if(WEST)
				p_dir = 11 //WEST|NORTH|SOUTH



		src.gas = new /obj/substance/gas( src )
		src.gas.maximum = src.capacity
		src.ngas = new /obj/substance/gas()
		gasflowlist += src


	// Find the connected machines/pipelines for each port

	buildnodes()
		var/turf/T = src.loc

		node3 = get_machine( level, T, dir )		// the side port

		n1dir = turn(dir, 90)
		n2dir = turn(dir,-90)

		node1 = get_machine( level, T , n1dir )	// the main flow dir


		node2 = get_machine( level, T , n2dir )


		vnode1 = node1 ? node1.getline() : null
		vnode2 = node2 ? node2.getline() : null
		vnode3 = node3 ? node3.getline() : null

		return


	// Replace the gas levels with the new levels calculated in process()

	gas_flow()
		gas.replace_by(ngas)


	// Calculate the gas flow to/from each port

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

		if(vnode3)
			delta_gt = FLOWFRAC * ( vnode3.get_gas_val(src) - gas.tot_gas() / capmult)
			calc_delta( src, gas, ngas, vnode3, delta_gt)
		else
			leak_to_turf(3)


	// Return the gas fullness value

	get_gas_val(from)
		return gas.tot_gas()/capmult


	// Return the gas reservoir

	get_gas(from)
		return gas


	// If a node is not connected, leak the gas into the turf in that direction

	proc/leak_to_turf(var/port)

		var/turf/T

		switch(port)
			if(1)
				T = get_step(src, n1dir)
			if(2)
				T = get_step(src, n2dir)
			if(3)
				T = get_step(src, dir)

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
