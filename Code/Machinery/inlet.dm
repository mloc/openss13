/*
 *	Inlet -- Pipe inlet object
 *			 Equalizes gas content between its turf and the pipe.
 *			 Thus can also act as an outlet if the pipe has more gas in it than the turf.
 *
 *			 Similar to /obj/machinery/vent, except that vents flow only one way (from pipe to the turf)
 */

obj/machinery/inlet
	name = "inlet"
	icon = 'pipes.dmi'
	icon_state = "inlet"
	desc = "A gas pipe inlet."
	anchored = 1
	p_dir = 2					// default pipe direction is south
	capmult = 2

	var
		obj/machinery/node			// the connected object
		obj/machinery/vnode			// the connected pipeline object (if node is a pipe)

		obj/substance/gas/gas		// the gas reservoir
		obj/substance/gas/ngas		// the new gas reservoir (as calculated in process())

		capacity = 6000000			// nominal gas capacity; not actually used


	// Create a new inlet. Pipe connection direction is set same as icon direction, thus p_dir does not need to be set
	// when placing inlet on map. Create gas reservoir and register self with the gasflowlist

	New()

		..()
		p_dir = dir
		gas = new/obj/substance/gas(src)
		gas.maximum = capacity
		ngas = new/obj/substance/gas()
		gasflowlist += src


	// Find the connected pipe or machine

	buildnodes()

		var/turf/T = get_step(src.loc, src.dir)
		var/fdir = turn(src.p_dir, 180)

		for(var/obj/machinery/M in T)
			if(M.p_dir & fdir)
				src.node = M
				break

		if(node) vnode = node.getline()

		return


	// Returns the gas fullness value. Capmult is 2 for inlets because they in effect have two connections: the pipe, and the turf

	get_gas_val(from)
		return gas.tot_gas()/capmult


	// Return the internal gas reservoir

	get_gas(from)
		return gas


	// After all machine process()es in world are complete, update the current gas levels with the new calculated levels

	gas_flow()
		gas.replace_by(ngas)


	// Timed process. Calculate gas flow to and from the turf, and to and from the connected pipe

	process()
		var/delta_gt

		var/turf/T = src.loc

		if(T && !T.density)
			flow_to_turf(gas, ngas, T)		// act as gas leak at the turf we are located on

		if(vnode)
			delta_gt = FLOWFRAC * ( vnode.get_gas_val(src) - gas.tot_gas() / capmult)
			calc_delta( src, gas, ngas, vnode, delta_gt)
		else
			leak_to_turf()


	// If no node is present, leak the contents to the turf position the node would be.
	// note this is a leak from the node, not the inlet itself
	// thus acts as a link between the inlet turf and the turf in step(dir)

	proc/leak_to_turf()

		var/turf/T = get_step(src, dir)
		if(T && !T.density)
			flow_to_turf(gas, ngas, T)


