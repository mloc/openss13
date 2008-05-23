/area
	var/fire = null
	level = null
	name = "area"
	mouse_opacity = 0
	var/lightswitch = 1

	var/eject = null

	var/requires_power = 1
	var/power_equip = 1
	var/power_light = 1
	var/power_environ = 1

	var/used_equip = 0
	var/used_light = 0
	var/used_environ = 0

	var/numturfs = 0
	var/linkarea = null
	var/area/linked = null
	var/no_air = null

/area/aircontrol
	name = "aircontrol"
	linkarea = "airintake"
/area/airintake
	name = "air intake"
/area/airtunnel1
	name = "airtunnel"
/area/control_room
	name = "control room"
/area/controlaccess
	name = "control access"
/area/crew_quarters
	name = "crew quarters"
/area/decontamination
	name = "decon"
/area/dummy

/area/engine
	name = "engine"
/area/engine_access
	name = "engine access"
/area/escapezone
	name = "escape zone"
/area/hallways
	name = "hallway"
/area/hallways/centralhall
	name = "central hall"
/area/hallways/eastairlock
	name = "east airlock"
/area/hallways/labaccess
	name = "lab access"
/area/hallways/loungehall
	name = "lounge hall"
/area/lounge
	name = "lounge"
/area/medical
	name = "medical bay"
/area/medicalstorage
	name = "medical storage"
/area/oxygen_storage
	name = "gas storage"
/area/security
	name = "security"
	linkarea = "brig"
/area/shuttle
	requires_power = 0
	name = "shuttle"
/area/shuttle_airlock
	name = "shuttle airlock"
/area/shuttle_prison
	name = "prison shuttle"
	requires_power = 0
/area/sleep_area
	name = "sleep area"
/area/solar_con
	name = "solar power control"
/area/start
	name = "start area"
/area/supply_station
	name = "supply station"
/area/testlab1
	name = "testlab1"
/area/testlab2
	name = "testlab2"
/area/testlab3
	name = "testlab3"
/area/testlab4
	name = "testlab4"
/area/aux_engine
	name = "aux. engine"
/area/toolstorage
	name = "tool storage"
/area/tech_storage
	name = "technical storage"
/area/toxinlab
	name = "toxin lab"
/area/vehicles
	requires_power = 0
/area/vehicles/shuttle1
/area/vehicles/shuttle2
/area/vehicles/shuttle3

// new areas

/area/sleep_area_annexe
	name = "sleep area annexe"
/area/south_access
	name = "southern access corridor"
/area/transport_tube
	name = "transport tube"
/area/shuttle_docking_arm
	name = "shuttle docking arm"
/area/secure_storage
	name = "secure stores"
/area/emergency_storage
	name = "emergency stores"
/area/morgue
	name = "morgue"
/area/repair_bay
	name = "repair bay"
/area/engine/engine_gas_storage
	name = "engine gas storage"
/area/engine/engine_storage
	name = "engine storage"
/area/engine/engine_hallway
	name = "engine hallway"
/area/engine/generator
	name = "generator room"
/area/engine/combustion
	name = "combustion chamber"
/area/engine/engine_control
	name = "engine control"
/area/engine/engine_mon
	name = "engine monitoring"
/area/station_teleport
	name = "SS13 teleporter"
/area/chapel
	name = "chapel"
/area/attack_ship
	name = "attack ship"
/area/security_sub
	name = "security annexe"
/area/aux_storage
	name = "aux. storage"
/area/eva_storage
	name = "EVA storage"

/area/weapon_sat
	name = "weapon sat"
	requires_power = 0
/area/med_sat
	name = "med. sat"
	requires_power = 0

/area/secret_base
	name = "secret base"
	no_air = 1
	power_equip = 0
	power_light = 0
	power_environ = 0

/area/prison
	name = "prison"
	requires_power = 0

/area/control_station
	name = "control station"
	requires_power = 0

/area/brig
	name = "brig"



/area/New()

	..()
	src.icon = 'alert.dmi'
	src.layer = 10

	if(!requires_power)
		power_light = 1
		power_equip = 1
		power_environ = 1

	spawn(5)
		for(var/turf/T in src)		// count the number of turfs (for lighting calc)
			numturfs++				// spawned with a delay so turfs can finish loading
			if(no_air)
				T.oxygen = 0		// remove air if so specified for this area
				T.n2 = 0
				T.res_vars()

		if(linkarea)
			linked = locate(text2path("/area/[linkarea]"))		// area linked to this for power calcs


	spawn(15)
		src.power_change()		// all machines set to current power level, also updates lighting icon

/area/vehicles/New()

	..()
	sleep(1)
	var/obj/shut_controller/S = new /obj/shut_controller(  )
	shuttles += S
	for(var/obj/move/O in src)
		S.parts += O
		O.master = S
		//Foreach goto(42)
	return

/area/proc/firealert()

	if (!( src.fire ))
		src.fire = 1
		src.updateicon()
		src.mouse_opacity = 0
		for(var/obj/machinery/door/firedoor/D in src)
			if (!( D.density ))
				spawn( 0 )
					D.closefire()
					return
			//Foreach goto(74)
	return


/area/proc/updateicon()

	if( fire || eject )
		if(power_environ)
			if(fire && !eject)
				icon_state = "blue"
			else if(!fire && eject)
				icon_state = "red"
			else
				icon_state = "blue-red"
		else
			if(lightswitch && power_light)
				icon_state = null
			else
				icon_state = "dark"
	else
		if(lightswitch && power_light)
			icon_state = null
		else
			icon_state = "dark"

/*
#define EQUIP 1
#define LIGHT 2
#define ENVIRON 3
*/

/area/proc/powered(var/chan)		// return true if the area has power to given channel
	if(!requires_power)
		return 1
	switch(chan)
		if(EQUIP)
			return power_equip
		if(LIGHT)
			return power_light
		if(ENVIRON)
			return power_environ

	return 0


// called when power status changes

/area/proc/power_change()

	for(var/obj/machinery/M in src)		// for each machine in the area
		M.power_change()				// reverify power status (to update icons etc.)

	spawn(rand(15,25))
		src.updateicon()


	if(linked)
		linked.power_equip = power_equip
		linked.power_light = power_light
		linked.power_environ = power_environ
		linked.power_change()




/area/proc/usage(var/chan)
	var/used = 0
	switch(chan)
		if(LIGHT)
			used += used_light
		if(EQUIP)
			used += used_equip
		if(ENVIRON)
			used += used_environ
		if(TOTAL)
			used += used_light + used_equip + used_environ

	if(linked)
		return linked.usage(chan) + used
	else
		return used

/area/proc/clear_usage()
	if(linked)
		linked.clear_usage()
	used_equip = 0
	used_light = 0
	used_environ = 0

/area/proc/use_power(var/amount, var/chan)

	switch(chan)
		if(EQUIP)
			used_equip += amount
		if(LIGHT)
			used_light += amount
		if(ENVIRON)
			used_environ += amount

#define LIGHTING_POWER 8		// power (W) per turf used for lighting

/area/proc/calc_lighting()
	if(lightswitch && power_light)
		used_light += numturfs * LIGHTING_POWER

