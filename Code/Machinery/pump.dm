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
