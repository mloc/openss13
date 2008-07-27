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



obj/machinery/emergencyrelease


	name = "vent"
	icon = 'pipes.dmi'
	icon_state = "vent"
	desc = "An emergency release vent.  Releases at 133% suggested mass content."
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

		if(gas.tot_gas() >= gas.maximum * 1.3)

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









//Regulator for pipe based atmosphere



obj/machinery/regulator
	name = "Atmospheric Control Vent"
	icon = 'pipes.dmi'
	icon_state = "vent"
	desc = "A gas pipe outlet vent, fitted with a regulator and filter."
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
		regulator = 1		//Positive, Regulator is on
		filtertype = 1		//0- No Filter, vent will not operate,  1- Nitrogen & Oxygen, 2 - co2, 3- Nitrogen, Oxygen, Plasma, n2o 4- co2, Plasma, n2o, 5- Hacked filter, allow all
		ofiltertype = 1		//Orig. filter type before tampering.  Used so removed type 5 filters are repairable.
		orname				//Orig. filter name before tampering.
		ordescription		//Orig. description before tampering.


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


	// Timed process. Dump gas into turf if regulator off, or dump regulated amount if on, associated filttration, then do standard flow calc for connected pipe.

	process()
		var/delta_gt
		var/turf/T = src.loc		//Set T
		if (src.regulator == 0)		//If the regulator is off.  All following will just dump gas without regulation.
			if (src.filtertype == 0)		//NO Filter.  They will not run without filters.
				if (src.cover == 1)		//Check if the filter has it's cover on.
					flick("ventnofilter",src)		//Of so flick the warning button icon_state
					return
				else		//If the cover is up
					return		//Just return, don't flick the warning
//				delta_gt = FLOWFRAC * (gas.tot_gas() / capmult)
//				ngas.turf_add(T, delta_gt)
			if (src.filtertype == 1)		//Filter Type 1, Allow: Oxygen & N2
				delta_gt = FLOWFRAC * (gas.oxygen / capmult)
				ngas.turf_add_oxy(T, delta_gt)
				delta_gt = FLOWFRAC * (gas.n2 / capmult)
				ngas.turf_add_n2(T, delta_gt)
			if (src.filtertype == 2)		//Filter Type 1, Allow: co2
				delta_gt = FLOWFRAC * (gas.co2 / capmult)
				ngas.turf_add_co2(T, delta_gt)
			if (src.filtertype == 3)		//Filter Type 3, Allow: Oxygen, N2, Plasma, n2o
				delta_gt = FLOWFRAC * (gas.oxygen / capmult)
				ngas.turf_add_oxy(T, delta_gt)
				delta_gt = FLOWFRAC * (gas.n2 / capmult)
				ngas.turf_add_n2(T, delta_gt)
				delta_gt = FLOWFRAC * (gas.plasma / capmult)
				ngas.turf_add_plasma(T, delta_gt)
				delta_gt = FLOWFRAC * (gas.sl_gas / capmult)
				ngas.turf_add_sl(T, delta_gt)
			if (src.filtertype == 4)		//Filter Type 4, Allow: co2, Plasma, n2o
				delta_gt = FLOWFRAC * (gas.co2 / capmult)
				ngas.turf_add_co2(T, delta_gt)
				delta_gt = FLOWFRAC * (gas.plasma / capmult)
				ngas.turf_add_plasma(T, delta_gt)
				delta_gt = FLOWFRAC * (gas.sl_gas / capmult)
				ngas.turf_add_sl(T, delta_gt)
			if (src.filtertype == 5)		//Filter Type 5,  AKA: Malfunctioning Filter/Hacked Filter Allow: All
				delta_gt = FLOWFRAC * (gas.tot_gas() / capmult)
				ngas.turf_add(T, delta_gt)

		if (src.regulator == 1)		//If regulator is on.  All gas will be regulated when dumped.
			var/difference		//Define the difference
			var/t1		//Define t1
			if (src.filtertype == 0)		//No Filter, vent will not operate.  Same process as above.
				if (src.cover == 1)
					flick("ventnofilter",src)
					return
				else
					return

			if (src.filtertype == 1)		//Same filtertypes as above.
				difference = 756000.0 - T.oxygen		//Set difference as CELLSTANDARD for oxygen - turf oxygen
				if (difference > 0)		//If there is a difference
					t1 = src.gas.oxygen		//Set t1 as the vents gas.oxygen level
					if (difference > t1)		//Make sure the difference (which will determine the dump amount) is not bigger than oxygen amount in gas in vent.
						difference = t1		//If it is, set it to dump all that is there.
					ngas.turf_add_oxy(T, difference)		//Call turf_add_oxy proc, to the turf, for the difference.
				difference = 2844000.0 - T.n2		//Same as oxygen, except for N2
				if (difference > 0)
					t1 = src.gas.n2
					if (difference > t1)
						difference = t1
					ngas.turf_add_n2(T, difference)

			if (src.filtertype == 2)
				delta_gt = FLOWFRAC * (gas.co2 / capmult / 10)
				ngas.turf_add_co2(T, delta_gt)

			if (src.filtertype == 3)
				difference = 756000.0 - T.oxygen
				if (difference > 0)
					t1 = src.gas.oxygen
					if (difference > t1)
						difference = t1
					ngas.turf_add_oxy(T, difference)
				difference = 2844000.0 - T.n2
				if (difference > 0)
					t1 = src.gas.n2
					if (difference > t1)
						difference = t1
					ngas.turf_add_n2(T, difference)
				delta_gt = FLOWFRAC * (gas.plasma / capmult / 10)
				ngas.turf_add_plasma(T, delta_gt)
				delta_gt = FLOWFRAC * (gas.sl_gas / capmult / 10)
				ngas.turf_add_sl(T, delta_gt)

			if (src.filtertype == 4)
				delta_gt = FLOWFRAC * (gas.co2 / capmult / 10)
				ngas.turf_add_co2(T, delta_gt)
				delta_gt = FLOWFRAC * (gas.plasma / capmult / 10)
				ngas.turf_add_plasma(T, delta_gt)
				delta_gt = FLOWFRAC * (gas.sl_gas / capmult / 10)
				ngas.turf_add_sl(T, delta_gt)

			if (src.filtertype == 5)
				difference = 756000.0 - T.oxygen
				if (difference > 0)
					t1 = src.gas.oxygen
					if (difference > t1)
						difference = t1
					ngas.turf_add_oxy(T, difference)
				difference = 2844000.0 - T.n2
				if (difference > 0)
					t1 = src.gas.n2
					if (difference > t1)
						difference = t1
					ngas.turf_add_n2(T, difference)
				delta_gt = FLOWFRAC * (gas.co2 / capmult / 10)
				ngas.turf_add_co2(T, delta_gt)
				delta_gt = FLOWFRAC * (gas.plasma / capmult / 10)
				ngas.turf_add_plasma(T, delta_gt)
				delta_gt = FLOWFRAC * (gas.sl_gas / capmult / 10)
				ngas.turf_add_sl(T, delta_gt)


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

	//Cover, Self explanitory

	attackby(obj/item/weapon/W, mob/user)
		if ( istype(W, /obj/item/weapon/screwdriver))
			if (src.cover == 1)
				user.show_message("\blue You carefully unscrew the cover to the vent.")
				src.cover = 0
				src.icon_state="ventopen"
				src.add_fingerprint(user)
			else
				user.show_message("\blue You carefully screw the cover back on the vent.")
				src.cover = 1
				src.icon_state="vent"
				src.add_fingerprint(user)


	//Remove Filter

		else
			if ( istype(W, /obj/item/weapon/wrench))
				if (src.cover == 1)		//If it's covered, this won't happen.
					return
				else
					if (src.filtertype > 0)
						user.show_message("\blue You remove the bolts holding the filter and slide it out of place.  The vent shuts down.")
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
							user.show_message("\blue You slide the filter into position and tighten the bolts.  The vent starts up.")
							src.filtertype = W:ftype		//Set the vent to the correct filter status
							src.ofiltertype = W:oftype		//Store filter's original filter type.
							src.orname = W:oname			//Store filter's original name.
							src.ordescription = W:odesc		//Store filter's original description.
							src.add_fingerprint(user)
							del (W)
						else
							user.show_message("\blue There is already a filter installed!")

	//Toggle Regulator

				else
					if ( istype(W, /obj/item/weapon/wirecutters))
						if (src.cover == 1)		//If it's covered this won't happen.
							return
						if (src.filtertype > 0)		//Filter must be removed to reach regulator.  Did this so there would be an order to dissasembling a vent.
							user.show_message("\blue The filter must be removed to reach the regulator.")
							return
						else
							if (src.regulator == 1)
								user.show_message("\blue You cut the wires to the regulator, gas will now flow freely.")
								src.regulator = 0
								src.add_fingerprint(user)
							else
								user.show_message("\blue You mend the wires to the regulator, gas flow will now be regulated.")
								src.regulator=1
								src.add_fingerprint(user)
