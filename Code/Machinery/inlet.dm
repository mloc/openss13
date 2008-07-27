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


//Filtration Procs for Filtered Inlet

/obj/machinery/proc
	flow_filter1(var/obj/substance/gas/sgas, var/obj/substance/gas/sngas, var/turf/T)
		var/t_tot = T.tot_gas() * 0.2
		var/delta_gt = FLOWFRAC * ( t_tot - sgas.tot_gas() / capmult )
		sngas.turf_take_filter1(T, delta_gt)
		T.res_vars()
	flow_filter2(var/obj/substance/gas/sgas, var/obj/substance/gas/sngas, var/turf/T)
		var/t_tot = T.tot_gas() * 0.2
		var/delta_gt = FLOWFRAC * ( t_tot - sgas.tot_gas() / capmult )
		sngas.turf_take_filter2(T, delta_gt)
		T.res_vars()
	flow_filter3(var/obj/substance/gas/sgas, var/obj/substance/gas/sngas, var/turf/T)
		var/t_tot = T.tot_gas() * 0.2
		var/delta_gt = FLOWFRAC * ( t_tot - sgas.tot_gas() / capmult )
		sngas.turf_take_filter3(T, delta_gt)
		T.res_vars()
	flow_filter4(var/obj/substance/gas/sgas, var/obj/substance/gas/sngas, var/turf/T)
		var/t_tot = T.tot_gas() * 0.2
		var/delta_gt = FLOWFRAC * ( t_tot - sgas.tot_gas() / capmult )
		sngas.turf_take_filter4(T, delta_gt)
		T.res_vars()
	flow_filter5(var/obj/substance/gas/sgas, var/obj/substance/gas/sngas, var/turf/T)
		var/t_tot = T.tot_gas() * 0.2
		var/delta_gt = FLOWFRAC * ( t_tot - sgas.tot_gas() / capmult )
		sngas.turf_take_filter5(T, delta_gt)
		T.res_vars()

/obj/substance/gas/proc
	turf_take_filter1(var/turf/target as turf, amount)
		if (((!( istype(target, /turf) ) && !( istype(target, /obj/move) )) || !( amount )))
			return
		if (locate(/obj/move, target))
			target = locate(/obj/move, target)
		var/t1 = target.oxygen + target.n2
		if (!( t1 ))
			return
		var/t2 = src.oxygen + src.n2
		if (amount > 0)
			if ((src.maximum > 0 && (src.maximum - t2) < amount))
				amount = src.maximum - t2
		else
			amount = src.oxygen + src.n2
		if (amount > t1)
			amount = t1
		var/turf_total = target.oxygen + target.n2
		var/heat_gain = (turf_total ? amount * target.temp : 0)
		var/t_oxygen = amount * target.co2 / t1
		var/t_n2 = amount * target.n2 / t1
		if(t2+amount>0)
			temperature = (temperature*t2 + heat_gain * TURF_TAKE_FRAC)/(t2+amount)
		src.oxygen += t_oxygen
		src.n2 += t_n2
		target.oxygen -= t_oxygen
		target.n2 -= t_n2
		target.res_vars()
		return
	turf_take_filter2(var/turf/target as turf, amount)
		if (((!( istype(target, /turf) ) && !( istype(target, /obj/move) )) || !( amount )))
			return
		if (locate(/obj/move, target))
			target = locate(/obj/move, target)
		var/t1 = target.co2
		if (!( t1 ))
			return
		var/t2 = src.co2
		if (amount > 0)
			if ((src.maximum > 0 && (src.maximum - t2) < amount))
				amount = src.maximum - t2
		else
			amount = src.co2
		if (amount > t1)
			amount = t1
		var/turf_total = target.co2
		var/heat_gain = (turf_total ? amount * target.temp : 0)
		var/t_co2 = amount * target.co2 / t1
		if(t2+amount>0)
			temperature = (temperature*t2 + heat_gain * TURF_TAKE_FRAC)/(t2+amount)
		src.co2 += t_co2
		target.co2 -= t_co2
		target.res_vars()
		return
	turf_take_filter3(var/turf/target as turf, amount)
		if (((!( istype(target, /turf) ) && !( istype(target, /obj/move) )) || !( amount )))
			return
		if (locate(/obj/move, target))
			target = locate(/obj/move, target)
		var/t1 = target.oxygen + target.n2 + target.poison + target.sl_gas
		if (!( t1 ))
			return
		var/t2 = src.oxygen + src.n2 + src.plasma + src.sl_gas
		if (amount > 0)
			if ((src.maximum > 0 && (src.maximum - t2) < amount))
				amount = src.maximum - t2
		else
			amount = src.oxygen + src.n2 + src.plasma + src.sl_gas
		if (amount > t1)
			amount = t1
		var/turf_total = target.oxygen + target.n2 + target.poison + target.sl_gas
		var/heat_gain = (turf_total ? amount * target.temp : 0)
		var/t_oxygen = amount * target.co2 / t1
		var/t_n2 = amount * target.n2 / t1
		var/t_poison = amount * target.poison / t1
		var/t_sl_gas = amount * target.sl_gas / t1
		if(t2+amount>0)
			temperature = (temperature*t2 + heat_gain * TURF_TAKE_FRAC)/(t2+amount)
		src.oxygen += t_oxygen
		src.n2 += t_n2
		src.plasma += t_poison
		src.sl_gas += t_sl_gas
		target.oxygen -= t_oxygen
		target.n2 -= t_n2
		target.poison -= t_poison
		target.sl_gas -= t_sl_gas
		target.res_vars()
		return
	turf_take_filter4(var/turf/target as turf, amount)
		if (((!( istype(target, /turf) ) && !( istype(target, /obj/move) )) || !( amount )))
			return
		if (locate(/obj/move, target))
			target = locate(/obj/move, target)
		var/t1 = target.co2 + target.poison + target.sl_gas
		if (!( t1 ))
			return
		var/t2 = src.co2 + src.plasma + src.sl_gas
		if (amount > 0)
			if ((src.maximum > 0 && (src.maximum - t2) < amount))
				amount = src.maximum - t2
		else
			amount = src.co2 + src.plasma + src.sl_gas
		if (amount > t1)
			amount = t1
		var/turf_total = target.co2 + src.plasma + src.sl_gas
		var/heat_gain = (turf_total ? amount * target.temp : 0)
		var/t_co2 = amount * target.co2 / t1
		var/t_poison = amount * target.poison / t1
		var/t_sl_gas = amount * target.sl_gas / t1
		if(t2+amount>0)
			temperature = (temperature*t2 + heat_gain * TURF_TAKE_FRAC)/(t2+amount)
		src.co2 += t_co2
		src.plasma += t_poison
		src.sl_gas += t_sl_gas
		target.co2 -= t_co2
		target.poison -= t_poison
		target.sl_gas -= t_sl_gas
		target.res_vars()
		return
	turf_take_filter5(var/turf/target as turf, amount)
		if (((!( istype(target, /turf) ) && !( istype(target, /obj/move) )) || !( amount )))
			return
		if (locate(/obj/move, target))
			target = locate(/obj/move, target)
		var/t1 = target.co2 + target.poison + target.sl_gas + target.oxygen + target.n2
		if (!( t1 ))
			return
		var/t2 = src.co2 + src.plasma + src.sl_gas + src.oxygen + src.n2
		if (amount > 0)
			if ((src.maximum > 0 && (src.maximum - t2) < amount))
				amount = src.maximum - t2
		else
			amount = src.co2 + src.plasma + src.sl_gas + src.oxygen + src.n2
		if (amount > t1)
			amount = t1
		var/turf_total = target.co2 + src.plasma + src.sl_gas + target.oxygen + target.n2
		var/heat_gain = (turf_total ? amount * target.temp : 0)
		var/t_co2 = amount * target.co2 / t1
		var/t_poison = amount * target.poison / t1
		var/t_sl_gas = amount * target.sl_gas / t1
		var/t_oxygen = amount * target.co2 / t1
		var/t_n2 = amount * target.n2 / t1
		if(t2+amount>0)
			temperature = (temperature*t2 + heat_gain * TURF_TAKE_FRAC)/(t2+amount)
		src.oxygen += t_oxygen
		src.n2 += t_n2
		src.co2 += t_co2
		src.plasma += t_poison
		src.sl_gas += t_sl_gas
		target.oxygen -= t_oxygen
		target.n2 -= t_n2
		target.co2 -= t_co2
		target.poison -= t_poison
		target.sl_gas -= t_sl_gas
		target.res_vars()
		return



obj/machinery/inletfiltered
	name = "Atmospheric Preservation Inlet"
	icon = 'pipes.dmi'
	icon_state = "inlet"
	desc = "A gas pipe inlet, fitted with a filter."
	anchored = 1
	p_dir = 2
	capmult = 2

	var
		obj/machinery/node				// the connected object
		obj/machinery/vnode			// the connected pipeline (if node is a pipe)
		obj/substance/gas/gas			// the gas reservoir
		obj/substance/gas/ngas			// the new gas reservoir after calculating flow
		capacity = 6000000				// nominal gas capacity

		cover = 1			//positive if cover is screwed on
		filtertype = 2		//0- No Filter, vent will not operate,  1- Nitrogen & Oxygen, 2 - co2, 3- Nitrogen, Oxygen, Plasma, n2o 4- co2, Plasma, n2o, 5- Hacked filter, allow all
		ofiltertype = 2		//Orig. filter type before tampering.  Used so removed type 5 filters are repairable.
		orname				//Orig. filter name before tampering.
		ordescription		//Orig. description before tampering.

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
			if (src.filtertype == 0)		//NO Filter.  Will not run without filters.
				if (src.cover == 1)		//Check if the filter has it's cover on.
					flick("inletnofilter",src)		//Of so flick the warning button icon_state
					return
				else		//If the cover is up
					return		//Just return, don't flick the warning


			if (src.filtertype == 1)		//Filter Type 1, Allow: Oxygen & Nitrogen
				flow_filter1(gas, ngas, T)
			if (src.filtertype == 2)		//Filter Type 2, Allow: co2
				flow_filter2(gas, ngas, T)
			if (src.filtertype == 3)		//Filter Type 3, Allow: Oxygen, Nitrogen, Plasma, n2o
				flow_filter3(gas, ngas, T)
			if (src.filtertype == 4)		//Filter Type 4, Allow: co2, Plasma, n2o
				flow_filter4(gas, ngas, T)
			if (src.filtertype == 5)		//Filter Type 5, Allow: All
				flow_filter5(gas, ngas, T)

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

	//Remove Cover

	attackby(obj/item/weapon/W, mob/user)
		if ( istype(W, /obj/item/weapon/screwdriver))
			if (src.cover == 1)
				user.show_message("\blue You carefully unscrew the cover to the inlet")
				src.cover = 0
				src.icon_state="inletopen"
				src.add_fingerprint(user)
			else
				user.show_message("\blue You carefully screw the cover back on the inlet")
				src.cover = 1
				src.icon_state="inlet"
				src.add_fingerprint(user)


	//Remove Filter

		else
			if ( istype(W, /obj/item/weapon/wrench))
				if (src.cover == 1)		//If it's covered, this won't happen.
					return
				else
					if (src.filtertype > 0)
						user.show_message("\blue You remove the bolts holding the filter and slide it out of place.  The inlet shuts down.")
						if (src.filtertype == 1)
							new /obj/item/weapon/filter/filtertype1 (src.loc)
						if (src.filtertype == 2)
							new /obj/item/weapon/filter/filtertype2 (src.loc)
						if (src.filtertype == 3)
							new /obj/item/weapon/filter/filtertype3 (src.loc)
						if (src.filtertype == 4)
							new /obj/item/weapon/filter/filtertype4 (src.loc)
						if (src.filtertype == 5)
							var/obj/item/weapon/filter/filtertype5/I = new(src.loc)		//Spawn Malf. Filter
							I.oftype = src.ofiltertype		//Set filters original filter type, so it can be repaired.
							I.oname = src.orname			//Set filters original name
							I.odesc = src.ordescription		//Set filters original desc
						src.filtertype = 0
						src.add_fingerprint(user)
					else
						user.show_message("\blue There is no filter installed!")

	//Apply filter
	//TODO:  Maybe just store the physical filter instead of using variables.  Maybe not :p I sort of like variables...
			else
				if ( istype(W, /obj/item/weapon/filter))
					if (src.cover == 1)		//If it's covered this won't happen.
						return
					else
						if (src.filtertype == 0)
							user.show_message("\blue You slide the filter into position and tighten the bolts.  The inlet starts up.")
							src.filtertype = W:ftype		//Set the vent to the correct filter status
							src.ofiltertype = W:oftype		//Store filter's original filter type.
							src.orname = W:oname			//Store filter's original name.
							src.ordescription = W:odesc		//Store filter's original description.
							src.add_fingerprint(user)
							del (W)
						else
							user.show_message("\blue There is already a filter installed!")