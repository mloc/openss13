/**
 * Alarm -- Provides a visual indication when air quality is unbreathable (toxins, low pressure, etc.)
 *
 */

obj/machinery/alarm
	name = "alarm"
	icon = 'stationobjs.dmi'
	icon_state = "alarm:0"
	anchored = 1.0


	// Monitors location air quality and changes icon_state to reflect it

	process()
		if(stat & NOPOWER)
			icon_state = "alarm-p"
			return

		use_power(5, ENVIRON)

		var/safe = 1
		var/turf/T = src.loc
		if (!( istype(T, /turf) ))
			return
		if (locate(/obj/move, T))
			T = locate(/obj/move, T)
		var/turf_total = T.co2 + T.oxygen + T.poison + T.sl_gas + T.n2
		turf_total = max(turf_total, 1)
		var/t1 = turf_total / CELLSTANDARD * 100
		if (!( (90 < t1 && t1 < 110) ))
			safe = 0
		t1 = T.oxygen / turf_total * 100
		if (!( (20 < t1 && t1 < 30) ))
			safe = 0
		src.icon_state = text("alarm:[]", !( safe ))
		return


	// Called when area power status changes. Alarms use the ENVIRON channel

	power_change()
		if( powered(ENVIRON) )
			stat &= ~NOPOWER
		else
			stat |= NOPOWER

	// Examining an alarm provides an air quality readout the same as a handheld air analyzer

	examine()
		set src in oview(1)

		if (usr.stat || stat & NOPOWER)
			return
		if ((!( istype(usr, /mob/human) ) && (!( ticker ) || (ticker && ticker.mode != "monkey"))))
			if (!istype(usr, /mob/ai) && !istype(usr, /mob/drone))
				usr.client_mob() << "\red You don't have the dexterity to do this!"
				return
		var/turf/T = src.loc
		if (!( istype(T, /turf) ))
			return

		var/turf_total = T.co2 + T.oxygen + T.poison + T.sl_gas + T.n2
		turf_total = max(turf_total, 1)
		usr.show_message("\blue <B>Results:</B>", 1)
		var/t = ""
		var/t1 = turf_total / CELLSTANDARD * 100
		if ((90 < t1 && t1 < 110))
			usr.show_message(text("\blue Air Pressure: []%", t1), 1)
		else
			usr.show_message(text("\blue Air Pressure:\red []%", t1), 1)
		t1 = T.n2 / turf_total * 100
		t1 = round(t1, 0.0010)
		if ((60 < t1 && t1 < 80))
			t += text("<font color=blue>Nitrogen: []</font> ", t1)
		else
			t += text("<font color=red>Nitrogen: []</font> ", t1)
		t1 = T.oxygen / turf_total * 100
		t1 = round(t1, 0.0010)
		if ((20 < t1 && t1 < 24))
			t += text("<font color=blue>Oxygen: []</font> ", t1)
		else
			t += text("<font color=red>Oxygen: []</font> ", t1)
		t1 = T.poison / turf_total * 100
		t1 = round(t1, 0.0010)
		if (t1 < 0.5)
			t += text("<font color=blue>Plasma: []</font> ", t1)
		else
			t += text("<font color=red>Plasma: []</font> ", t1)
		t1 = T.co2 / turf_total * 100
		t1 = round(t1, 0.0010)
		if (t1 < 1)
			t += text("<font color=blue>CO2: []</font> ", t1)
		else
			t += text("<font color=red>CO2: []</font> ", t1)
		t1 = T.sl_gas / turf_total * 100
		t1 = round(t1, 0.0010)
		if (t1 < 5)
			t += text("<font color=blue>NO2: []</font>", t1)
		else
			t += text("<font color=red>NO2: []</font>", t1)
		usr.show_message(t, 1)
		usr.show_message(text("\blue \t Temperature: []&deg;C", T.temp - T0C), 1)
		src.add_fingerprint(usr)
		return




/**
 * Indicator -- Subtype of alarm, used to indicated air quality in the airtunnel
 *
 */

obj/machinery/alarm/indicator
	name = "indicator"
	icon = 'airtunnel.dmi'
	icon_state = "indicator"


	// Monitors location air quality and changes icon_state to reflect it
	// Also sets airtunnel datum air status

	process()

		if(stat & NOPOWER)
			icon_state = "indicator-p"
			return

		var/safe = 1
		var/turf/T = src.loc
		if (!( istype(T, /turf) ))
			return
		if (locate(/obj/move, T))
			T = locate(/obj/move, T)
		var/turf_total = T.co2 + T.oxygen + T.poison + T.sl_gas + T.n2
		turf_total = max(turf_total, 1)
		var/t1 = turf_total / CELLSTANDARD * 100
		if (!( (90 < t1 && t1 < 110) ))
			safe = 0
		t1 = T.oxygen / turf_total * 100
		if (!( (20 < t1 && t1 < 30) ))
			safe = 0
		src.icon_state = text("indicator[]", safe)
		SS13_airtunnel.air_stat = safe
		return
