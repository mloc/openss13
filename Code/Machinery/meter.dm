/*
 *	Meter -- a machine that shows the flow rate of gas in a pipe on the same turf
 *
 *	The meter actually reads a moving average of the flow var of the pipeline object associated with the pipe.
 *  Note that the value can be negative if the flow is going through the pipe "backwards"
 *	If attacked by a wrench, try to locate a working pipe again
 *
 *	TODO: Add an icon overlay showing the actual movement direction of the gas.
 */

obj/machinery/meter
	name = "meter"
	icon = 'pipes.dmi'
	icon_state = "meterX"
	anchored = 1
	var
		obj/machinery/pipes/target = null		// the pipe object to monitor
		average = 0								// the exponential moving average of the flow rate
		alarm = 0								// true if pressure alarm is being shown



	// Create a new meter. Find the target pipe in the same location as the meter

	New()
		..()
		src.target = locate(/obj/machinery/pipes, src.loc)
		average = 0
		return


	// Timed process.
	// Read flow rate from the pipeline object of the target pipe
	// Calculate exponentially weighted moving average of flow rate
	// Update icon state of flow rate bargraph

	process()

		if(!target || !target.pl)
			icon_state = "meterX"
			overlays = null
			return
		if(stat & NOPOWER)
			icon_state = "meter0"
			return

		var/obj/machinery/pipeline/line = target.pl
		use_power(5)

		average = 0.5 * average + 0.5 * line.flow

		var/val = min(18, round( 18.99 * ((abs(average) / 2500000)**0.25)) )
		icon_state = "meter[val]"

		var/pressure = line.gas.tot_gas() / line.numnodes * line.gas.temperature

		if(alarm)
			if(pressure < PRESSURELIMIT)
				overlays = null
				alarm = 0
		else
			if(pressure > PRESSURELIMIT)
				overlays += image('pipes.dmi', "meter-o")
				alarm = 1

	// If the meter is clicked on, report the flow rate and temperature of the gas

	Click()
		var/mob/user = usr
		if (user.currentDrone!=null)
			user = user.currentDrone

		if (get_dist(user, src) <= 3)
			if (src.target)
				user.client_mob() << "\blue <B>Results:\nMass flow [round(100*abs(average)/6e6, 0.1)]%\nTemperature [round(target.pl.gas.temperature,0.1)] K</B>"
				if(alarm)
					user.client_mob() << "\red <B>Warning! Pressure approaching pipe fracture limit!</B>"
			else
				user.client_mob() << "\blue <B>Results: Connection Error!</B>"
		else
			user.client_mob() << "\blue <B>You are too far away.</B>"
		return


	// Attack with weapon
	// if a wrench, try to find pipe at same location and activate

	attackby(var/obj/item/weapon/W, mob/user)

		if(!target && istype(W, /obj/item/weapon/wrench))
			target = locate(/obj/machinery/pipes, src.loc)
			average = 0
			if(target)
				user.client_mob() << "\blue The meter has been attached to the pipe."
				var/turf/T = src.loc		// make sure meter is on top of pipe
				src.loc = null
				src.loc = T
		else
			..()




// Disabled routines

/*
/obj/machinery/meter/proc/pressure()

	if(src.target && src.target.gas)
		return (average * target.gas.temperature)/100000.0
	else
		return 0
*/

/*
/obj/machinery/meter/examine()
	set src in oview(1)

	var/t = "A gas flow meter. "
	if (src.target)
		t += text("Results:\nMass flow []%\nPressure [] kPa", round(100*average/src.target.gas.maximum, 0.1), round(pressure(), 0.1) )
	else
		t += "It is not functioning."

	usr.client_mob() << t

*/
