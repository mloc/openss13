/*
 *	Vent -  Machine which dumps pipe gas contents into turf
 *
 *			Similar to an inlet, except only works one way (pipe->turf)
 */


obj/machinery/vent
	name = "vent"
	icon = 'pipes.dmi'
	icon_state = "vent"
	desc = "A gas pipe outlet vent."
	anchored = 1
	p_dir = 2
	capmult = 2

	var
		obj/machinery/node				// the connected object
		obj/machinery/vnode			// the connected pipeline (if node is a pipe)
		obj/substance/gas/gas			// the gas reservoir
		obj/substance/gas/ngas			// the new gas reservoir after calculating flow
		capacity = 6000000				// nominal gas capacity


	// Create a new vent. Pipe connection p_dir is calculated from icon dir, so p_dir does not need to be set on map.
	// Create the gas reservoir and register with the gasflowlist.

	New()
		..()
		p_dir = dir
		gas = new/obj/substance/gas(src)
		gas.maximum = capacity
		ngas = new/obj/substance/gas()
		gasflowlist += src


	// Find the connected machine or pipe to the vent pipe.

	buildnodes()
		var/turf/T = get_step(src.loc, src.dir)
		var/fdir = turn(src.p_dir, 180)

		for(var/obj/machinery/M in T)
			if(M.p_dir & fdir)
				src.node = M
				break

		if(node) vnode = node.getline()

		return


	// Get the gas fullness value.

	get_gas_val(from)
		return gas.tot_gas()/2

	// Get the gas reservoir object

	get_gas(from)
		return gas


	// Replace the gas level by the new level calculated in process()

	gas_flow()
		gas.replace_by(ngas)


	// Timed process. Dump gas into turf, then do standard flow calc for connected pipe.

	process()
		var/delta_gt

		var/turf/T = src.loc

		delta_gt = FLOWFRAC * (gas.tot_gas() / capmult)
		ngas.turf_add(T, delta_gt)
		if(vnode)
			delta_gt = FLOWFRAC * ( vnode.get_gas_val(src) - gas.tot_gas() / capmult)
			calc_delta( src, gas, ngas, vnode, delta_gt)//, dbg)
		else
			leak_to_turf()


	// Leak from pipe to turf if no node connected

	proc/leak_to_turf()

		var/turf/T = get_step(src, dir)
		if(T && !T.density)
			flow_to_turf(gas, ngas, T)



