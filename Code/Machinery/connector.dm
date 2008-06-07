/*
 *	Connector -- Machine that links atmoalter machines (canisters, siphons, heaters) to a pipe network.
 *
 *				 Connection is performed by attacking the device to be connected with a wrench (or screwdriver)
 */


/obj/machinery/connector
	name = "connector"
	icon = 'pipes.dmi'
	desc = "A connector for gas canisters."
	icon_state = "connector"
	anchored = 1
	p_dir = 2
	capmult = 2

	var
		obj/machinery/node = null					// the pipe-connected machine or pipe
		obj/machinery/vnode = null					// the pipe-connected pipeline, if node is a pipe

		obj/machinery/atmoalter/connected = null	// the connected device (canister, etc.), or null if none

		obj/substance/gas/gas = null				// the gas reservoir
		obj/substance/gas/ngas = null

		capacity = 6000000.0						// the capacity of the gas reservoir. This value is actually used,
													// unlike most pipe-related objects


	// Create a new connector, create gas reservoir.
	// Pipe direction (p_dir) is same as icon dir
	//If a compatible machine is at the same location, and its c_status (pipe valve) is not 0, set the machine as connected

	New()
		..()

		p_dir = dir

		gas = new/obj/substance/gas(src)
		gas.maximum = capacity
		ngas = new/obj/substance/gas()

		gasflowlist += src
		spawn(5)							// wait until world has finished loading
			var/obj/machinery/atmoalter/A = locate(/obj/machinery/atmoalter, src.loc)	// find compatible machine in same loc

			if(A && A.c_status != 0)		// c_status=0 -> disconnected
				connected = A
				A.anchored = 1				// ensure canister etc. is anchored if connected


	// Find the machine/pipe that connects to this one

	buildnodes()

		var/turf/T = get_step(src.loc, src.dir)
		var/fdir = turn(src.p_dir, 180)

		for(var/obj/machinery/M in T)
			if(M.p_dir & fdir)
				src.node = M
				break

		if(node) vnode = node.getline()


		return

	// Examine verb for the connector

	examine()
		set src in oview(1)

		if (usr.stat)
			return

		if(connected)
			usr.client_mob() << "A pipe connector for gas equipment. It is connected to \an [connected.name]."
		else
			usr.client_mob() << "A pipe connector for gas equipment. It is unconnected."



	// Return the gas fullness value

	get_gas_val(from)
		return gas.tot_gas()/capmult


	// Return the gas reservoir

	get_gas(from)
		return gas


	// Update gas values with the new ones calculated in process()

	gas_flow()
		gas.replace_by(ngas)


	// Timed process. Calculate gas flow to connected node.
	// If a device is connected (canister etc.), transfer gas to/from reservoir depending on device valve settings.

	process()
		var/delta_gt

		if(vnode)

			delta_gt = FLOWFRAC * ( vnode.get_gas_val(src) - gas.tot_gas() / capmult)
			calc_delta( src, gas, ngas, vnode, delta_gt)//, dbg)
		else
			leak_to_turf()

		if(connected)
			var/amount
			if(connected.c_status == 1)				// canister set to release

				amount = min(connected.c_per, capacity - gas.tot_gas() )	// limit to space in connector
				amount = max(0, min(amount, connected.gas.tot_gas() ) )		// limit to amount in canister, or 0
				ngas.transfer_from( connected.gas, amount)
			else if(connected.c_status == 2)		// canister set to accept

				amount = min(connected.c_per, connected.gas.maximum - connected.gas.tot_gas())	//limit to space in canister
				amount = max(0, min(amount, gas.tot_gas() ) )				// limit to amount in connector, or 0

				connected.gas.transfer_from( ngas, amount)


	// If pipe-connected node is missing, leak the gas to turf

	proc/leak_to_turf()
		var/turf/T = get_step(src, dir)

		if(T && !T.density)
			flow_to_turf(gas, ngas, T)

