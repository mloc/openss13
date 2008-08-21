/*
 *	Pipes -- the basic object in the pipe network
 *
 *  Pipes do not directly contain gas, but unbroken chains of pipes are assembled into /obj/machinery/pipeline objects
 *  Pipelines contain a single gas reservoir that encompass all the gas that would be each individual pipe.
 *
 *  TODO: Implement some method of capacity regulation
 */

#define MAXPIPEHEALTH 10		// the starting health value of each pipe

obj/machinery/pipes
	name = "pipes"
	icon = 'reg_pipe.dmi'
	icon_state = "12"
	anchored = 1
	desc = "A regular pipe."

	/* var/p_dir - inherited from /obj/machinery, is a bitfield of directions of pipe connections from this one */

	var
		capacity = 6000000.0				// nominal gas capacity of each pipe segment - not actually used
		obj/machinery/node1 = null			// the 1st connected node
		obj/machinery/node2 = null			// the 2nd connected node
		termination = 0						// >0 if this is an end pipe in a pipeline
		insulation = NORMPIPERATE			// lower insulation value means pipe temperature is exchanged with turf at a faster rate

		obj/machinery/pipeline/pl			// the pipeline object which contains this pipe
		health = MAXPIPEHEALTH				// the health of the pipe


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

		if(!line)			// If no pipeline was specified, just needed to revalidate the local nodes
			return

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


	// examine verb - show description and amount of damage

	examine()
		set src in view(1)
		if(usr && !usr.stat)
			usr.client_mob() << "[desc] The pipe is [damagetext()][(stat & MAINT)?" and the flanges are unfastened.":"."]"


	// return text description of the damage state of the pipe
	// used in examine verb and when repairing

	proc/damagetext()
		if(health == MAXPIPEHEALTH)
			return "undamaged"
		if(health > 0.7*MAXPIPEHEALTH)
			return "slightly damaged"
		if(health > 0.3*MAXPIPEHEALTH)
			return "damaged"
		else
			return "badly damaged"




	// Update the icon_state and overlays
	// Depends on pipe level and visibility, broken status, and whether this is an unterminated end of a pipe

	proc/updateicon()

		var/turf/T = src.loc

		var/is = "[p_dir]"

		// Set invisibility status depending on whether this pipe is below floor level
		// Also sets a faded (alpha blended) icon_state for the pipe so it can be shown with a T-scanner

		if ((src.level == 1 && isturf(src.loc) && T.intact))
			src.invisibility = 101
			is += "-f"

		else
			src.invisibility = null

		src.icon_state = is

		// If either node is null, this is an unterminated pipe
		// unless a matching broken pipe is present
		// Show special overlays to indicate this

		var/list/dirs = get_node_dirs()

		overlays = null

		if(!node1)														// node1 is not connected
			if(!findbrokenpipe(T, dirs[1], level, 0))					// no broken pipe present
				overlays += image('pipes.dmi', "discon[dirs[1]]", FLY_LAYER)

		if(!node2)														// node2 is not connected
			if(!findbrokenpipe(T, dirs[2], level, 0))					// no broken pipe present
				overlays += image('pipes.dmi', "discon[dirs[2]]", FLY_LAYER)


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

	attackby(obj/item/weapon/W, mob/user)

		if (istype(W, /obj/item/weapon/wrench))
			if(stat & MAINT)
				stat &= ~MAINT
				user.client_mob() << "\blue You fasten the pipe flanges."
			else
				stat |= MAINT
				user.client_mob() << "\blue You unfasten the pipe flanges. The pipe can now be cut."

		else if (istype(W, /obj/item/weapon/weldingtool))
			var/obj/item/weapon/weldingtool/WT = W
			if(WT.welding)

				if(stat & MAINT)
					if(WT.weldfuel > 3)
						WT.weldfuel -=3

						user.client_mob() << "\blue Cutting the pipe. Stand still as this takes some time."
						var/turf/T = user.loc
						sleep(50)

						if ((user.loc == T && user.equipped() == W))
							// make pipe fitting

							var/obj/item/weapon/pipe/P = new(src.loc)
							P.settype(src)

							del(src)
					else
						user.client_mob() << "\blue You need more welding fuel to cut the pipe."

				else
					if(health < MAXPIPEHEALTH)
						if(WT.weldfuel > 1)
							WT.weldfuel--

							user.client_mob() << "\blue Repairing the pipe."
							sleep(5)
							health = min(health+MAXPIPEHEALTH/10, MAXPIPEHEALTH)
							user.client_mob() << "\blue The pipe is now [damagetext()]."
							healthcheck()
							return
						else
							user.client_mob() << "\blue You need more welding fuel to repair the pipe."

					else
						user.client_mob() << "You cannot repair the pipe as it is undamaged."
						return


		else
			var/aforce = round(W.force/10+0.5,1)

			src.health = max(0, src.health - aforce)

			healthcheck()
			..()
		return



	// pipe effected by an explosion

	ex_act(severity)

		switch(severity)
			if(1.0)
				del(src)
				return
			if(2.0)
				health -= rand(MAXPIPEHEALTH*0.5,MAXPIPEHEALTH*1.5)
				healthcheck()
				return
			if(3.0)
				health -= rand(0,MAXPIPEHEALTH*1.5)
				healthcheck()
				return


	// pipe is in a fire


	burn(fi_amount)

		if(fi_amount > 1800000)
			var/turf/T = src.loc
			if(prob(5) && T.temp > 1600)		// if turf temp exceeds pipe melting point, take damage
				health -= round( T.temp/1500)	// damage depends on the actual temperature
				healthcheck()


	/*
	// test verb - destroy a pipe

	verb/destroy()
		set src in view()

		health=0
		healthcheck()
	*/

	// Check the pipe hp, and break it if low enough

	proc/healthcheck()
		if(health<=0)				// check health, if low enough
			health = 0				// break the pipe
			breakpipe()


	// break a pipe
	// create a broken pipe object in place, then delete this pipe
	// pipe Del() proc handles updating of the containing pipeline

	proc/breakpipe()

		if(!isturf(src.loc))		// sanity check
			return

		// create the broken pipe object

		var/obj/brokenpipe/BP = new(src.loc)		// in same loc as original
		BP.update(src)						// update brokenpipe vars from this pipe

		// deletes the pipe segement
		del(src)


	// Delete the pipe
	// must handle updating of the containing pipeline object
	// three possible cases:
	// pipe is the only node in a line	-> delete the line
	// pipe is at one end of a line		-> shorten the line
	// pipe is in the middle of a line	-> split the line into two pieces
	// also handle redistribution of gas in the pipeline(s)

	Del()

		var/obj/machinery/pipeline/line = pl
		var/turf/T = src.loc

		if(!pl || !isturf(T))		// sanity check
			return ..()				// just delete

		var/linepos = line.nodes.Find(src)	// the position of this pipe in the pipeline

		if(linepos == 1 && line.numnodes == 1)	// single pipe pipeline
			// no other nodes in the pipeline, so remove it completely
			line.gas.leak(T)	// dump all gas in line into turf
			src.pl = null


			// update linked machines to reflect new status
			if(line.vnode1)
				line.vnode1.buildnodes()

			if(line.vnode2)
				line.vnode2.buildnodes()

			line.nodes -= src	// remove reference to this pipe object (to prevent infinite loop)
			del(line)			// remove the line

		else if(linepos == 1 || linepos == line.numnodes)	// pipe was at one end of pipeline

			var/obj/substance/gas/G = new()						// temporary holder for gas

			G.transfer_from(line.gas, line.gas.tot_gas()  / line.numnodes)	// transfer gas from line to temp

			G.leak(T)	// dump fraction of line gas into turf


			line.nodes -= src
			line.numnodes--
			line.capmult = 1 + line.numnodes

			src.loc = null

			line.ngas.replace_by(line.gas)

			// now update line and connected machines links between nodes

			if(linepos == 1)						// pipe at start of pipeline
				if(line.vnode1)	line.vnode1.buildnodes()
				var/obj/machinery/pipes/P = line.nodes[1]

				P.buildnodes(null)		// rebuild the local nodes of the next pipe
				line.vnode1 = null
			else									// pipe at end of pipeline
				if(line.vnode2)	line.vnode2.buildnodes()
				var/obj/machinery/pipes/P = line.nodes[line.numnodes]
				P.buildnodes(null)		// rebuild the local nodes of the next pipeline
				line.vnode2 = null


		else	// pipe is somewhere in middle of pipeline	- split into two

			//world << "total : [line.gas.tot_gas()]"

			//world << "pos [linepos] of [line.numnodes]"

			var/linenodes = line.numnodes

			var/obj/machinery/pipeline/newline = new()

			newline.nodes = line.nodes.Copy(linepos+1)

			line.nodes.Cut(linepos)

			line.numnodes = linepos-1

			line.capmult = 1 + line.numnodes

			newline.numnodes = newline.nodes.len

			plines += newline

			newline.name = "pipeline #[plines.len]"

			newline.capmult = 1 + newline.numnodes

			for(var/obj/machinery/pipes/P in newline.nodes)
				P.pl = newline

			src.loc = null

			src.node1.buildnodes(null)
			src.node2.buildnodes(null)

			line.setterm()
			newline.setterm()

			// transfer fraction of gas which will be in second line
			newline.gas.transfer_from(line.gas, line.gas.tot_gas() * (linenodes - linepos ) / linenodes)

			//world << "in 1([line.name]): [line.gas.tot_gas()]"
			//world << "in 2([newline.name]): [newline.gas.tot_gas()]"

			var/obj/substance/gas/G = new()

			G.transfer_from(line.gas, line.gas.tot_gas() / (line.numnodes+1))

			//world << "to turf: [G.tot_gas()]"

			G.leak(T)	// dump pipe's share of gas into the turf

			line.ngas.replace_by(line.gas)
			newline.ngas.replace_by(newline.gas)
			//world << "in 1([line.name]): [line.gas.tot_gas()]"

		..()		// perform actual deletion of pipe object


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

			var/turf/T = src.loc

			var/list/dirs = get_node_dirs()

			var/is = "[h_dir]"

			src.icon_state = is

			overlays = null

			if(!node1)														// node1 is not connected
				if(!findbrokenpipe(T, dirs[1], level, 1))					// no broken pipe present
					overlays += image('pipes.dmi', "discon-he[dirs[1]]", FLY_LAYER)

			if(!node2)														// node2 is not connected
				if(!findbrokenpipe(T, dirs[2], level, 1))					// no broken pipe present
					overlays += image('pipes.dmi', "discon-he[dirs[2]]", FLY_LAYER)


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

			if(!line)
				return

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

