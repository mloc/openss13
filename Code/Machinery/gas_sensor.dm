/*
 * Gas_sensor - Provides remote reading of the current gas conditions at location
 *              Read from engine computers.
 *
 */

obj/machinery/gas_sensor
	name = "gas sensor"
	icon = 'stationobjs.dmi'
	icon_state = "gsensor"
	desc = "A remote sensor for atmospheric gas composition."
	anchored = 1
	var
		id	// Engine computer must have matching id


	// Return a string showing gas values & temperature at object location

	proc/sense_string()

		var/t = ""

		var/turf/T = src.loc

		var/turf_total = T.tot_gas()

		var/t1 = add_tspace("[round(turf_total / CELLSTANDARD * 100, 0.1)]%",6)
		t += "<PRE>Pressure: [t1] Temperature: [round(T.temp - T0C,0.1)]&deg;C<BR>"

		if(turf_total == 0)
			t+="O2: 0 N2: 0 CO2: 0><BR>Plasma: 0 N20: 0"
		else
			t1 = add_tspace(round(T.oxygen/turf_total * 100, 0.1),5)

			t += "O2: [t1] "

			t1 = add_tspace(round(T.n2/turf_total * 100, 0.1),5)

			t += "N2: [t1] "

			t1 = add_tspace(round(T.co2/turf_total * 100, 0.01),5)

			t += "CO2: [t1]<BR>"

			t1 = add_tspace(round(T.poison/turf_total * 100, 0.001),5)

			t += "Plasma: [t1] "

			t1 = add_tspace(round(T.sl_gas/turf_total * 100, 0.001),5)

			t += "N2O: [t1]"

		t += "</PRE>"

		return t
