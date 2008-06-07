/*
 * Power Machines -- Base type of machines that connect to the cable network.
 *
 *					 Includes generator, SMES, APC, Solar panels, etc.
 *
 *	Note: While almost all machines comsume power, most do so through their area use_power() proc.
 *        Power machines are those that connect directly to the /obj/cable network and supply and use power from it.
 */


obj/machinery/power
	name = null
	icon = 'power.dmi'
	anchored = 1.0

	var
		datum/powernet/powernet = null		// The powernet connected to this machine.
											// powernets are the data structures that hold information (power usage,
											// connected devices, etc.) about a contiguous network of cables and devices.

		netnum = 0							// the number of the connected powernet (index of the global list/powernets).
											// if 0 or -1, the machine is not connected to a powernet.

		directwired = 1		// by default, power machines are connected by a cable in a neighbouring turf
							// if set to 0, requires stub cable (ending at the centre) on this turf


	// Common helper procs for all power machines
	// Some machines override these.


	// Add an amount of power to the connected powernet
	// Done by generator-type machines to make power available

	proc/add_avail(var/amount)
		if(powernet)
			powernet.newavail += amount


	// Add an amount of load to the connected powernet
	// Done by machines that draw power from the network

	proc/add_load(var/amount)
		if(powernet)
			powernet.newload += amount


	// Returns the surplus power available on the connected powernet

	proc/surplus()
		if(powernet)
			return powernet.avail-powernet.load
		else
			return 0


	// Returns the total available power (neglecting current load) available on the connected powernet

	proc/avail()
		if(powernet)
			return powernet.avail
		else
			return 0


	// Routines used when constructing power cable networks

	// Returns a list of cables that connect to this machine
	// Searches all turfs within 1 step for a cable that points towards the machine
	// If the machine is non-directwired, calls and returns get_indirect_connections() instead

	proc/get_connections()

		if(!directwired)
			return get_indirect_connections()

		var/list/res = list()
		var/cdir

		for(var/turf/T in orange(1, src.loc))

			cdir = get_dir(T, src)

			for(var/obj/cable/C in T)

				if(C.netnum)
					continue

				if(C.d1 == cdir || C.d2 == cdir)
					res += C

		return res


	// Returns a list of stub cables (1/2 length cables that end in the centre of a turf)
	// On the same turf as a non-directwired machine.

	proc/get_indirect_connections()

		var/list/res = list()

		for(var/obj/cable/C in src.loc)

			if(C.netnum)
				continue

			if(C.d1 == 0)
				res += C

		return res


	// Attacking a power machine with a cable_coil object attaches a wire to the machine
	// leading from the turf the player is standing on.
	// Only machines with directwired=1 need or use this.

	attackby(obj/item/weapon/W, mob/user)

		if(istype(W, /obj/item/weapon/cable_coil))

			var/obj/item/weapon/cable_coil/coil = W

			var/turf/T = user.loc

			if(T.intact || !istype(T, /turf/station/floor))
				return

			if(get_dist(src, user) > 1)
				return

			if(!directwired)		// only for attaching to directwired machines
				return

			var/dirn = get_dir(user, src)


			for(var/obj/cable/LC in T)
				if(LC.d1 == dirn || LC.d2 == dirn)
					user.client_mob() << "There's already a cable at that position."
					return

			var/obj/cable/NC = new(T)
			NC.d1 = 0
			NC.d2 = dirn
			NC.add_fingerprint()
			NC.updateicon()
			NC.update_network()
			coil.use(1)
			return
		else
			..()
		return
