/*
 *	Pipeline -- The pipeline machine responsible for gas flow through pipes.
 *
 *				Pipelines are logical, not physical objects, and do not exist at a location in the world.
 *				They are collections of /obj/machinery/pipes objects that form an unbroken connection.
 *
 *	By consolidating the gas content of a series of pipes into one pipeline, the number of gas flow calculations is reduced.
 *  This also allows faster flow of gas through long lines.
 *  For instance, if each pipe segment performed as an independent object, it would take at least 10 seconds for any gas
 *  to flow through a 10-segment pipe,
 */


obj/machinery/pipeline				// logical pipeline consisting of multiple /obj/machinery/pipes

	name = "pipeline"
	invisibility = 101		// since pipelines do not exist as tangible objects, they are set invisible
	capmult = 0				// actual capmult will be the number of pipe segments + 1

	var
		list/nodes = list()				// the list of /obj/machinery/pipes objects in this pipeline
										// nodes will be sorted during creation so that adjacent pipes are adjacent in the list
		numnodes = 0					// the number of nodes

		obj/substance/gas/gas = null	// the gas reservoir for this pipeline
		obj/substance/gas/ngas = null	// the new calculated gas levels

		obj/machinery/vnode1			// the machine connected to the start of this pipeline (or null if none)
		obj/machinery/vnode2			// the machine connected to the end of this pipeline (or null if none)

		flow = 0						// flow rate through this pipe, calculated from the gas flowing into or out of each end.
										// can be negative if flowing backwards.


	// Create a new pipeline. Create gas reservoir
	// Register self with gasflowlist since this object has a gas_flow() proc.

	New()
		..()

		gas = new/obj/substance/gas(src)
		ngas = new/obj/substance/gas()

		gasflowlist += src


	// Sets the vnode1 & vnode2 values to the machines connected at each end of the pipe
	// Also orientates the pipes in the node list so that for each pipe, node1 points to previous entry, and node2 points to next

	proc/setterm()
		//first make sure pipes are oriented correctly

		var/obj/machinery/M = null

		for(var/obj/machinery/pipes/P in nodes)
			if(!M)			// special case for 1st pipe
				if(P.node1 && P.node1.ispipe())

					P.flip()		// flip if node1 is a pipe

			else
				if(P.node1 != M)		//other cases, flip if node1 doesn't point to previous node
					P.flip()			// (including if it is null)

			P.updateicon()

			M = P			// the previous node



		// pipes are now ordered so that n1/n2 is in same order as pipeline list

		var/obj/machinery/pipes/P = nodes[1]		// 1st node in list
		vnode1 = P.node1							// n1 points to 1st machine
		P = nodes[nodes.len]						// last node in list
		vnode2 = P.node2							// n2 points to last machine


		// confirm node connections are valid for the machines at each end of the pipeline
		// not needed in initial makepipelines, but may be if new pipeline is constructed

		if(vnode1)
			vnode1.buildnodes()
		if(vnode2)
			vnode2.buildnodes()

		return


	// Return the gas fullness value
	// For pipelines, capmult is set to (number of pipe segements)+1
	// Thus the longer the pipeline, the bigger the gas reservoir appears

	get_gas_val(from)
		return gas.tot_gas()/capmult


	// Return the gas reservoir for the pipeline

	get_gas(from)
		return gas


	// Update the current gas levels to that calculated in process()

	gas_flow()
		gas.replace_by(ngas)


	// Timed process for the pipeline.
	// First do heat-exchange for every node in this pipeline
	// The do standard gas flow from each end of the pipeline.
	// Also update "flow" variable to show rate of flow through the complete pipeline.

	process()

		if(!numnodes)		// check to see if there are any nodes in the pipeline
			return			// if none, skip it. Used because some PLs may get zero lengthed during pipe laying

		// heat exchange for whole pipeline

		var/gtemp = ngas.temperature								// cached current temperature for heat exch calc
		var/tot_node = ngas.tot_gas() / numnodes					// fraction of gas in this node


		if(tot_node>0.1)											// no pipe contents, don't heat
			for(var/obj/machinery/pipes/P in src.nodes)				// for each segment of pipe
				P.heat_exchange(ngas, tot_node, numnodes, gtemp) 	// exchange heat with its turf


		// now do standard gas flow proc

		var/delta_gt

		if(vnode1)
			delta_gt = FLOWFRAC * ( vnode1.get_gas_val(src) - gas.tot_gas() / capmult)
			calc_delta( src, gas, ngas, vnode1, delta_gt)

			flow = delta_gt
		else
			leak_to_turf(1)

		if(vnode2)
			delta_gt = FLOWFRAC * ( vnode2.get_gas_val(src) - gas.tot_gas() / capmult)
			calc_delta( src, gas, ngas, vnode2, delta_gt)

			flow -= delta_gt
		else
			leak_to_turf(2)


	// Depending on which end is leaking, vent gas contents into turf

	// Note: added some temporary error-checking to fix runtime errors when blob destroys pipes
	//       full pipe damage system will remove the need for this

	proc/leak_to_turf(var/port)

		var/turf/T
		var/obj/machinery/pipes/P
		var/list/ndirs

		switch(port)
			if(1)
				P = nodes[1]		// 1st node in list

				if(P)
					ndirs = P.get_node_dirs()
					T = get_step(P, ndirs[1])


			if(2)
				P = nodes[nodes.len]	// last node in list

				if(P)
					ndirs = P.get_node_dirs()
					T = get_step(P, ndirs[2])

		if(!T  || T.density)
			return

		flow_to_turf(gas, ngas, T)

