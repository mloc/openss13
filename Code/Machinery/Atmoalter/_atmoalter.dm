/*
 *	Atmoalter - base machine type for gas canisters, siphons, scrubbers, air regulator and filters, and heaters
 *
 *
 */



obj/machinery/atmoalter

	var
		obj/substance/gas/gas = null	// the gas contents of the machine
		maximum							// the maximum capacity of the gas

		t_status						// main valve status 1 = release, 2= siphon, 3 = stop, 4 = automatic
		t_per							// main valve rate

		c_per							// pipe valve rate
		c_status						// pipe vale status 0 = disconnected, 1 = release, 2 = accept, 3 = stop

		obj/item/weapon/tank/holding	// the tank item being held (or null)

		max_valve = 1e6					// the maximum setting of both valves
