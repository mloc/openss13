/*
 *	Circulator - A gas pump and heat-exchanger
 *				 Part of the main engine generator system
 *
 *	Machine contains two gas reservoirs. Gas flows from the pipe to the south into the first
 *  Is pumped from the first reservoir to the second at "rate"
 *  Then flows out of the second reservoir into the pipe at the north
 */

obj/machinery/circulator
	name = "circulator/heat exchanger"
	desc = "A gas circulator pump and heat exchanger."
	icon = 'pipes.dmi'
	icon_state = "circ1-off"
	p_dir = 3				// pipes connect to north & south directions
	anchored = 1.0
	density = 1
	capmult = 1				// Since we have a separate reservoir connected to each node, capmult is 1

	var
		side = 1 			// Ciculators can be to the left or to the right of a generator. 1=left 2=right
		status = 0			// 0 = off, 1 = on, 2 = slow
		rate = 0			// the gas transfer rate between the two internal reservoirs
		maxrate = 400000	// the maximum transfer rate

		obj/substance/gas/gas1 = null		// the first gas reservoir, connected to node1 (south)
		obj/substance/gas/ngas1 = null

		obj/substance/gas/gas2 = null		// the second gas reservoir, connected to node 2 (north)
		obj/substance/gas/ngas2 = null

		capacity = 6000000.0				// the maximum gas capacity of each reservoir

		obj/machinery/node1 = null			// the physical pipe object to the south
		obj/machinery/node2 = null			// the physical pipe object to the north

		obj/machinery/vnode1				// the pipeline object to the south
		obj/machinery/vnode2				// the pipeline object to the north




	// Create a new circulator object

	New()
		..()
		gas1 = new/obj/substance/gas(src)
		gas1.maximum = capacity
		gas2 = new/obj/substance/gas(src)
		gas2.maximum = capacity

		ngas1 = new/obj/substance/gas()
		ngas2 = new/obj/substance/gas()

		gasflowlist += src

		updateicon()


	// Find the pipe connections to the north and south
	// Set the node & vnode values

	buildnodes()

		var/turf/T = src.loc

		node1 = get_machine(level, T, SOUTH)
		node2 = get_machine(level, T, NORTH)


		if(node1)
			vnode1 = node1.getline()
		else
			vnode1 = null

		if(node2)
			vnode2 = node2.getline()
		else
			vnode2 = null


	// Set the current status and pumping rate (as a percentage)
	// Called by the generator object

	proc/control(var/on, var/prate)

		rate = prate/100*maxrate

		if(status == 1)
			if(!on)
				status = 2				// switching from on to off makes the generator slow down for 3 seconds
				spawn(30)
					if(status == 2)		// then switch to off
						status = 0
						updateicon()
		else if(status == 0)
			if(on)
				status = 1
		else	// status ==2
			if(on)
				status = 1

		updateicon()


	// Update the icon state, depending on the circulator settings

	proc/updateicon()

		if(stat & NOPOWER)
			icon_state = "circ[side]-p"
			return

		var/is
		switch(status)
			if(0)
				is = "off"
			if(1)
				is = "run"
			if(2)
				is = "slow"

		icon_state = "circ[side]-[is]"


	// When the power of the area changes, to standard processing then update the icon state

	power_change()
		..()
		updateicon()


	// Gas flow - update the gas reservoirs with the new values as set in process()

	gas_flow()

		gas1.replace_by(ngas1)
		gas2.replace_by(ngas2)


	// Main process. Pump gas between the reservoirs, then do standard gas flow to the connected nodes

	process()

		// if operating, pump from resv1 to resv2

		if(! (stat & NOPOWER) )				// only do circulator step if powered; still do rest of gas flow at all times
			if(status==1 || status==2)
				gas2.transfer_from(gas1, status==1? rate : rate/2)
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