/*
 *	Pipe Misc -- Global procs and support routines used in pipe network calculations.
 *
 */


// Build the list of pipeline objects. Called after world has loaded.

/proc/makepipelines()


	for(var/obj/machinery/pipes/P in machines)		// look for a pipe

		if(!P.pl)									// if not already part of a line
			var/obj/machinery/pipeline/PL = new()	// make a new pipeline
			plines += PL							// add it to the global list
			P.buildnodes(PL)						// and spread to all connected pipes

	// After the above, all pipes in the world will be associated with a pipeline object

	// Now set pipeline names (so they can be distinguished for debugging).

	for(var/L = 1 to length(plines))				// for count of lines found
		var/obj/machinery/pipeline/PL = plines[L]	// get the pipeline virtual object
		PL.name = "pipeline #[L]"					// and set the name

	// Next, find the pipes at the end of each pipeline, and use those to get an ordered list of all pipes in the pipeline
	// Then set the pipeline variables

	for(var/obj/machinery/pipes/P in machines)		// look for pipes

		if(P.termination)							// true if pipe is terminated (ends in blank or a machine)
			var/obj/machinery/pipeline/PL = P.pl	// get the pipeline from the pipe's pl

			var/list/pipes = pipelist(null, P)		// get a list of pipes from P until terminated

			PL.nodes = pipes						// pipeline is this list of nodes
			PL.numnodes = pipes.len					// with this many nodes
			PL.capmult = PL.numnodes+1				// with this flow multiplier


	// Now set the node connections for all machines that connect to pipelines.

	for(var/obj/machinery/M in machines)		// for all machines
		if(M.p_dir || M.h_dir)					// which are pipe-connected
			if(!M.ispipe())						// is not a pipe itself
				M.buildnodes()					// build the nodes, setting the links to the pipelines
												// also sets the vnodes for the pipelines

	// Finally, make sure the pipeline nodes point to the terminating machines.

	for(var/obj/machinery/pipeline/PL in plines)	// for all lines
		PL.setterm()								// orient the pipes and set the pipeline vnodes to the terminating machines



// Return a list of pipes, in order of connection
// Starting at startnode, moving away from source

/proc/pipelist(var/obj/machinery/source, var/obj/machinery/startnode)

	var/list/L = list()

	var/obj/machinery/node = startnode
	var/obj/machinery/prev = source
	var/obj/machinery/newnode

	while(node)
		L += node
		newnode = node.next(prev)
		prev = node

		if(newnode && newnode.ispipe())
			node = newnode
		else
			break

	return L


// Returns the machine with compatible p_dir and level in 1 step in dir mdir from turf S
// Note: "compatible" means the machine has a p_dir pointing towards S.
// Returns null if no such machine is found

/proc/get_machine(var/level, var/turf/S, var/mdir)

	var/flip = turn(mdir, 180)

	var/turf/T = get_step(S, mdir)

	for(var/obj/machinery/M in T.contents)
		if(M.level == level)
			if(M.p_dir & flip)
				return M

	return null


// Returns the machine with compatible h_dir and level in 1 step in dir mdir from turf S
// Same as routine above, but for h/e rather than standard pipe.

/proc/get_he_machine(var/level, var/turf/S, mdir)

	var/flip = turn(mdir, 180)

	var/turf/T = get_step(S, mdir)

	for(var/obj/machinery/M in T.contents)
		if(M.level == level)
			if(M.h_dir & flip)
				return M

	return null


// The main flow routine
// Calculates the movement of "amount" gas between source and target machines
// If amount is negative, flow is from source to target, and source gas level is reduced
// If amount is positive, flow is from target to source, and source gas level is increased by a fraction of the target gas
// The source's new gas level is stored in "sngas", which replaces the actual gas level in the gas_flow() proc for this machine.
// Note the target's gas level isn't altered here; it will run this proc itself and alter it's own gas levels by the correct amount.


/proc/calc_delta(obj/machinery/source, obj/substance/gas/sgas, obj/substance/gas/sngas, obj/machinery/target, amount)

	var/obj/substance/gas/tgas = target.get_gas(source)

	var/obj/substance/gas/ndelta = new()

	if(amount < 0)							// then flowing from source to target

		ndelta.set_frac(sgas, -amount)		// this is fraction of the gas which will be transfered to other node
		sngas.sub_delta(ndelta)				// subtract off the fraction which is gone

	else									// flowing from target to source
		ndelta.set_frac(tgas, amount)		// fraction of gas from the other node
		sngas.add_delta(ndelta)				// add the fraction to the new gas resv


// Called by all gas-handling machines when a pipe node is not present.
// Also used by /obj/machinery/inlet
// Calculates a leak between a gas reservoir (sgas, sngas) and turf T
// Gas can flow both ways, if pipe is less full than the turf


/obj/machinery/proc/flow_to_turf(var/obj/substance/gas/sgas, var/obj/substance/gas/sngas, var/turf/T)



	var/t_tot = T.tot_gas() * 0.2				// partial pressure of turf gas at pipe, for the moment

	var/delta_gt = FLOWFRAC * ( t_tot - sgas.tot_gas() / capmult )


	var/obj/substance/gas/ndelta = new()

	if(delta_gt < 0)							// flow from pipe to turf

		ndelta.set_frac(sgas, -delta_gt)		// ndelta contains gas to transfer to turf
		sngas.sub_delta(ndelta)					// update new gas to remove the amount transfered
		ndelta.turf_add(T, -1)					// add all of ndelta to turf

	else										// flow from turf to pipe

		sngas.turf_take(T, delta_gt)			// grab gas from turf and direcly add it to the new gas

	T.res_vars()								// update turf gas vars for both cases



