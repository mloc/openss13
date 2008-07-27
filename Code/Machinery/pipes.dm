/*
 *	Pipes -- the basic object in the pipe network
 *
 *  Pipes do not directly contain gas, but unbroken chains of pipes are assembled into /obj/machinery/pipeline objects
 *  Pipelines contain a single gas reservoir that encompass all the gas that would be each individual pipe.
 *
 *	TODO: Complete routines for pipe disassembly, damage, and exploding under pressure.
 *	TODO: Finalize method of showing broken pipes & pipe ends.
 *  TODO: Implement some method of capacity regulation
 */

obj/machinery/pipes
	name = "pipes"
	icon = 'reg_pipe.dmi'
	icon_state = "12"
	anchored = 1

	/* var/p_dir - inherited from /obj/machinery, is a bitfield of directions of pipe connections from this one */

	var
		capacity = 6000000.0				// nominal gas capacity of each pipe segment - not actually used
		obj/machinery/node1 = null			// the 1st connected node
		obj/machinery/node2 = null			// the 2nd connected node
		termination = 0						// >0 if this is an end pipe in a pipeline
		insulation = NORMPIPERATE			// lower insulation value means pipe temperature is exchanged with turf at a faster rate

		obj/machinery/pipeline/pl			// the pipeline object which contains this pipe
		health = 10							// the health of the pipe (not yet implemented)


	// Create a new pipe, and update the p_dir according to the icon_state.

	New()
		..()
		update()


	// Update the p_dir bitfield according to the current icon state
	// Icons_states for each pipe state match the correct p_dir value, so pipes placed on the map
	// do not need the p_dir state set at compile time, since it is calculated at spawn.

	proc/update()
		p_dir = text2num(icon_state)


	// Return true as this is a pipe. All other machines return false.

	ispipe()
		return 1


	// Find the machines or pipes which connect to this one
	// Argument is the current pipeline object being built
	// If another pipe segment is found, call this routine for that pipe to propagate the connection

	buildnodes(var/obj/machinery/pipeline/line)

		// First find the machines/pipes that connect to this pipe

		var/list/dirs = get_dirs()

		node1 = get_machine(level, src.loc, dirs[1])
		node2 = get_machine(level, src.loc, dirs[2])

		if(pl)				// If the pipeline is already set, there is no need to propagate anymore
			return

		updateicon()		// Update the icon_state according to p_dir and other states

		pl = line			// Set the pipeline of the pipe segment

		termination = 0

		if(node1 && node1.ispipe() )		// If node1 is a pipe, propagate this pipeline object to it

			node1.buildnodes(line)
		else
			termination++					// Otherwise we are at an end of the pipeline

		if(node2 && node2.ispipe() )		// If node2 is a pipe, propagate this pipeline object to it
			node2.buildnodes(line)
		else
			termination++					// Otherwise we are at the end of the pipeline



	// Flip the node order of a pipe

	proc/flip()

		var/obj/machinery/tempnode = node1
		node1 = node2
		node2 = tempnode
		return


	// Return the next pipe object in the node chain
	// Argument "from" is the node we are approaching from; if null, returns the first actual pipe found

	next(var/obj/machinery/from)

		if(from == null)		// if from null, then return the next actual pipe
			if(node1 && node1.ispipe() )
				return node1
			if(node2 && node2.ispipe() )
				return node2
			return null			// else return null if no real pipe connected

		else if(from == node1)		// otherwise, return the node opposite the incoming one
			return node2
		else
			return node1


	// Returns the pipeline object that this pipe is in

	getline()
		return pl


	// Finds the actual directions corresponding to the p_dir bitfield
	// Returns as a list (dir1, dir2, p_dir)
	// Note this direction order is not guaranteed to be the same order as node1 & node2
	// For that, use get_node_dirs()

	proc/get_dirs()
		var/b1
		var/b2

		for(var/d in cardinal)
			if(p_dir & d)
				if(!b1)
					b1 = d
				else if(!b2)
					b2 = d

		return list(b1, b2, p_dir)


	// Returns a list of the directions of a pipe, matched to nodes (if present)
	// Note unlike get_dirs(), 1st direction on list is always the direction of node1, 2nd is node2

	proc/get_node_dirs()
		var/list/dirs = get_dirs()


		if(!node1 && !node2)		// no nodes - just return the standard dirs
			return dirs				// note extra p_dir on end of list is unimportant
		else
			if(node1)
				var/d1 = get_dir(src, node1)		// find the direction of node1
				if(d1==dirs[1])						// if it matches
					return dirs						// then dirs list is correct
				else
					return list(dirs[2], dirs[1])	// otherwise return the list swapped

			else		// node2 must be valid
				var/d2 = get_dir(src, node2)		// direction of node2
				if(d2==dirs[2])						// matches
					return dirs						// dirs list is correct
				else
					return list(dirs[2], dirs[1])	// otherwise swap order


	// Update the icon_state and overlays
	// Depends on pipe level and visibility, broken status, and whether this is an unterminated end of a pipe

	proc/updateicon()

		var/turf/T = src.loc

		var/is = "[p_dir]"

		if(stat & BROKEN)
			is += "-b"

		// Set invisibility status depending on whether this pipe is below floor level
		// Also sets a faded (alpha blended) icon_state for the pipe so it can be shown with a T-scanner

		if ((src.level == 1 && isturf(src.loc) && T.intact))
			src.invisibility = 101
			is += "-f"

		else
			src.invisibility = null

		src.icon_state = is

		// If either node is null, this is an unterminated pipe
		// Show special overlays to indicate this

		var/list/dirs = get_node_dirs()

		overlays = null
		if(!node1 && !node2)												// neither end of pipe is connected
			overlays += image('pipes.dmi', "discon", FLY_LAYER, dirs[1])
			overlays += image('pipes.dmi', "discon", FLY_LAYER, dirs[2])

		else if(!node1)														// node1 is not connected
			overlays += image('pipes.dmi', "discon", FLY_LAYER, dirs[1])

		else if(!node2)														// node2 is not connected
			overlays += image('pipes.dmi', "discon", FLY_LAYER, dirs[2])

		return


	// Called when a pipe is revealed or hidden when a floor tile is removed, etc.
	// Just call updateicon(), since all is handled there already

	hide(var/i)
		updateicon()



	// Exchange heat between a pipe and the turf it is on
	// Called by /obj/machinery/pipeline/process()
	//

	proc/heat_exchange(var/obj/substance/gas/gas, var/tot_node, var/numnodes, var/temp)

		var/turf/T = src.loc		// turf location of pipe
		if(T.density) return

		if( level != 1)				// no heat exchange for under-floor pipes
			if(istype(T,/turf/space))		// heat exchange less efficient in space (no conduction)
				gas.temperature += ( T.temp - temp) / (3.0 * insulation * numnodes)
			else

				var/delta_T = (T.temp - temp) / (insulation)	// normal turf

				gas.temperature += delta_T	/ numnodes			// heat the pipe due to turf temperature

				var/tot_turf = max(1, T.tot_gas())
				T.temp -= delta_T*min(10,tot_node/tot_turf)			// also heat the turf due to pipe temp
				T.res_vars()	// ensure turf tmp vars are updated

		else								// if level 1 but in space, perform cooling anyway - exposed pipes
			if(istype(T,/turf/space))
				gas.temperature += ( T.temp - temp) / (3.0 * insulation * numnodes)




	// Routines to allow cutting and damage of pipes
	// Not yet implemented

	/*
	attackby(obj/item/weapon/W, mob/user)

		if (istype(W, /obj/item/weapon/weldingtool))
			var/obj/item/weapon/weldingtool/WT = W
			if(WT.welding && WT.weldfuel > 3)
				WT.weldfuel -=3

				user.client_mob() << "\blue Cutting the pipe. Stand still as this takes some time."
				var/turf/T = user.loc
				sleep(50)

				if ((user.loc == T && user.equipped() == W))

				// make pipe fitting
					sleep(1)

		else
			var/aforce = W.force

			src.health = max(0, src.health - aforce)

			healthcheck()

		return

	proc/healthcheck()
		//if(health<1)
	*/


	/*
	 * Heat_exch -	Heat-exchange pipe subtype. Same as a standard pipe, but uses different icon, has lower insulation value
	 *				Also uses h_dir for connection direction bitfield instead of p_dir
	 */

	heat_exch
		icon = 'heat_pipe.dmi'
		name = "heat exchange pipe"
		desc = "A bundle of small pipes designed for maximum heat transfer."
		insulation = HEATPIPERATE

		/* h_dir - inherited from /obj/machinery */


		// Update h_dir from the icon state

		update()
			h_dir = text2num(icon_state)


		// Update icon_state and overlays depending in h_dir connections and whether nodes are present

		updateicon()

			var/list/dirs = get_node_dirs()

			var/is = "[h_dir]"

			if(stat & BROKEN)
				is += "-b"

			src.icon_state = is

			overlays = null

			if(!node1 && !node2)
				overlays += image('pipes.dmi', "discon-he", FLY_LAYER, dirs[1])
				overlays += image('pipes.dmi', "discon-he", FLY_LAYER, dirs[2])
			else if(!node1)
				overlays += image('pipes.dmi', "discon-he", FLY_LAYER, dirs[1])
			else if(!node2)
				overlays += image('pipes.dmi', "discon-he", FLY_LAYER, dirs[2])
			return


		// Return list of directions corresponding to h_dir bitflags

		get_dirs()
			var/b1
			var/b2

			for(var/d in cardinal)
				if(h_dir & d)
					if(!b1)
						b1 = d
					else if(!b2)
						b2 = d

			return list(b1, b2, h_dir)


		// Find the nodes that connect to this pipe
		// If they are pipes themselves, propagate the set pipeline object to them

		buildnodes(var/obj/machinery/pipeline/line)

			src.level = 2		// h/e pipe cannot be put underfloor

			var/list/dirs = get_dirs()

			node1 = get_he_machine(level, src.loc, dirs[1])
			node2 = get_he_machine(level, src.loc, dirs[2])

			if(pl)
				return

			updateicon()

			pl = line

			termination = 0

			if(node1 && node1.ispipe() )

				node1.buildnodes(line)
			else
				termination++

			if(node2 && node2.ispipe() )
				node2.buildnodes(line)
			else
				termination++


	// Flexpipe sub-type. Identical to standard pipe except for appearance, since capacity differences are not implemented
	// Currently only used between freezer/cryocell

	flexipipe
		desc = "Flexible hose-like piping."
		name = "flexipipe"
		icon = 'wire.dmi'
		capacity = 10.0
		p_dir = 12.0


	// High-capacity pipe subtype. Not implemented.

	high_capacity
		desc = "A large bore pipe with high capacity."
		name = "high capacity"
		icon = 'hi_pipe.dmi'
		density = 1
		capacity = 1.8E7


obj/machinery/pump
	name = "Gas Pump"
	desc = "A gas pump"
	icon = 'pipes.dmi'
	icon_state = "one-way"
	anchored = 1
	density = 0
	capmult = 1

	var
		status = 0			// 0 = off, 1 = on
		rate = 400000
		maxrate = 1e22

		obj/substance/gas/gas1 = null
		obj/substance/gas/ngas1 = null

		obj/substance/gas/gas2 = null
		obj/substance/gas/ngas2 = null

		capacity = 1e22

		obj/machinery/node1 = null			// the physical pipe object to the south
		obj/machinery/node2 = null			// the physical pipe object to the north

		obj/machinery/vnode1				// the pipeline object
		obj/machinery/vnode2				// the pipeline object


	New()
		..()
		gas1 = new/obj/substance/gas(src)
		gas1.maximum = capacity
		gas2 = new/obj/substance/gas(src)
		gas2.maximum = capacity

		ngas1 = new/obj/substance/gas()
		ngas2 = new/obj/substance/gas()

		gasflowlist += src

	proc/update()
		p_dir = text2num(icon_state)

	buildnodes()
		var/turf/n1
		var/turf/n2
		if (src.dir == 1)
			n1 = get_step(src, SOUTH)
			n2 = get_step(src, NORTH)
		if (src.dir == 8)
			n1 = get_step(src, EAST)
			n2 = get_step(src, WEST)
		if (src.dir == 2)
			n1 = get_step(src, NORTH)
			n2 = get_step(src, SOUTH)
		if (src.dir == 4)
			n1 = get_step(src, WEST)
			n2 = get_step(src, EAST)
		for(var/obj/machinery/M in n1)

//			if(M && (M.p_dir & 1))
			node1 = M
			break

		for(var/obj/machinery/M in n2)

//			if(M && (M.p_dir & 2))
			node2 = M
			break


		if(node1) vnode1 = node1.getline()

		if(node2) vnode2 = node2.getline()



/*	proc/control(var/on, var/prate)

		rate = prate/100*maxrate

		if(status == 1)
			if(!on)
				status = 2
				spawn(30)
					if(status == 2)			//Most of the pump code is shamefully swiped and hacked from circulators :p
						status = 0
//						updateicon()
		else if(status == 0)
			if(on)
				status = 1
		else	// status ==2
			if(on)
				status = 1*/




	gas_flow()

		gas1.replace_by(ngas1)
		gas2.replace_by(ngas2)



	process()

		if(! (stat & NOPOWER) )
			if(status==1 || status==2)
				gas2.transfer_from(gas1, 1e22)
				use_power(rate/capacity * 100)
			ngas1.replace_by(gas1)
			ngas2.replace_by(gas2)


		// now do standard gas flow process

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


	// If nothing connected to either pipe node, leak the gas to the turf instead

	proc/leak_to_turf(var/port)

		var/turf/T

		switch(port)
			if(1)
				T = get_step(src, SOUTH)
			if(2)
				T = get_step(src, NORTH)

		if(T.density)
			T = src.loc
			if(T.density)
				return

		switch(port)
			if(1)
				flow_to_turf(gas1, ngas1, T)
			if(2)
				flow_to_turf(gas2, ngas2, T)


	// Get the current gas fill level. Note since we have two reservoirs, value depends on which node is enquiring

	get_gas_val(from)

		if(from == vnode1)
			return gas1.tot_gas()/capmult
		else
			return gas2.tot_gas()/capmult


	// Get the gas reservoir object connected to node "from"

	get_gas(from)

		if(from == vnode1)
			return gas1
		else
			return gas2

	attack_hand(var/mob/user)

		if (src.status == 0)
			user.show_message("\blue You activate the pump")
			src.status = 1
			src.rate = 1e22
		else
			user.show_message("\blue You deactivate the pump")
			src.status = 0
			src.rate = 400000
