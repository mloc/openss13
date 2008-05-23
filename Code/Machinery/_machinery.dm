/*
 *	The base machinery object
 *
 *	Machines have a process() proc called approximately once per second while a game round is in progress
 *  Thus they can perform repetative tasks, such as calculating pipe gas flow, power usage, etc.
 *
 *
 */


obj/machinery

	var
		p_dir = 0		// directions of regular pipes connected to this machine
						// bitwise-OR of cardinal directions to indicate multiple pipes
		h_dir = 0		// as above, but for heat-exchange pipes

		capmult = 0		// used for gas flow - a capacity multiplier

		stat = 0		// machinery status bitflags
						// currently used values: 1 - BROKEN ; 2 - NOPOWER


	// New() and Del() add and remove machines from the global "machines" list
	// This list is used to call the process() proc for all machines ~1 per second during a round

	New()
		..()
		machines += src

	Del()
		machines -= src
		..()


	// Called when an object is in an explosion
	// Higher "severity" means the object was further from the centre of the explosion

	ex_act(severity)

		switch(severity)
			if(1.0)
				del(src)
				return
			if(2.0)
				if (prob(50))
					del(src)
					return
			if(3.0)
				if (prob(25))
					del(src)
					return


	// Called when attacked by a blob

	blob_act()
		if(prob(25))
			del(src)


	/*
	 *	Prototype procs common to all /obj/machinery objects
	 */


	// Called for all /obj/machinery in the "machines" list, approximately once per second
	// by /datum/control/cellular/process() when a game round is active
	// Any regular action of the machine is executed by this proc.
	// For machines that are part of a pipe network, this routine also calculates the gas flow to/from this machine.

	proc/process()
		return

	/*
	 *	Pipe and gas-flow related prototypes
	 */

	// Machines needing extra processing for gas flow in pipes place themselves in the "gasflowlist" global list
	// All machines in that list have gas_flow() executed after all process() procedures in the world have completed
	// Used to avoid order-of-execution problems in pipe flow.
	// This routine usually just replaces the current gas levels with the new ones calculated in the process() proc.

	proc/gas_flow()
		return


	// Builds pipe-connections for adjacent machines
	// Called after map load, then again whenever a pipeline is altered.

	proc/buildnodes()
		return


	// For pipe-connected machinery, returns self
	// For pipe objects, returns the pipeline object containing this.

	proc/getline()
		if(p_dir || h_dir)
			return src


	// Returns true if this is a pipe (or h/e pipe) object, false otherwise

	proc/ispipe()
		return 0


	// Returns the next connected pipe in a pipeline, or null if this is not a pipe object

	proc/next(from)
		return null


	// Returns the "gas val", usually the total gas content divided by the capacty multiplier
	// Roughly, this is how full of gas the machine is.Used to calculate gas flow in and out of the machine.
	// Argument indicates which node is enequiring, for machines that have more than one gas reservoir

	proc/get_gas_val(from)
		return null


	// Returns the gas reservoir object of a machine (or null if none)
	// Used during gas flow calculations

	proc/get_gas(from)
		return null

	/*
	 *	Power related prototypes
	 */


	// Returns true if the area has power on given channel (or doesn't require power).
	// defaults to equipment channel

	proc/powered(var/chan = EQUIP)
		var/area/A = src.loc.loc		// make sure it's in an area
		if(!A || !isarea(A))
			return 0					// if not, then not powered

		return A.powered(chan)	// return power status of the area


	// Increment the power usage stats for an area
	// usually called by a machine in its process() proc

	proc/use_power(var/amount, var/chan=EQUIP) // defaults to Equipment channel
		var/area/A = src.loc.loc		// make sure it's in an area
		if(!A || !isarea(A))
			return

		A.use_power(amount, chan)


	// Called for all machines in an area whenever power settings of the area change
	// By default, sets NOPOWER flag if the equipment channel is off
	// Override for other behaviour

	proc/power_change()


		if(powered())
			stat &= ~NOPOWER
		else

			stat |= NOPOWER
		return

