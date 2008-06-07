/obj/machinery/computer/drone_control
	name = "Drone Control Station"
	icon = 'stationobjs.dmi'
	icon_state = "drone_control"
	var/mob/user = null
	
	New()
		spawn(10)
			while (!config)
				sleep(10)
			if ((!config.humans_can_use_drones) || (!config.enable_drones))
				del(src)
		
	attack_hand(var/mob/user as mob)
		if(stat & (NOPOWER|BROKEN) ) return
		if (!config.humans_can_use_drones)
			return
		if (user.currentDrone)
			return
		if (istype(user, /mob/drone))
			return
		
		var/list/L = list(  )
		user.machine = src
		
		var/numDrones = 0
		for(var/mob/drone/rob in world)
			if (rob.stat==0)
				L[rob.name] = rob
				numDrones+=1
		L = sortList(L)
		
		L["Cancel"] = "Cancel"
		var/t = input(user, "Which drone would you like to change to?") as null|anything in L

		if(!t)
			user.machine = null
			user.reset_view(null)
			return 0
		if (t == "Cancel")
			user.machine = null
			user.reset_view(null)
			return 0
		
		var/selected = L[t]
		if (istype(selected, /mob/drone))
			user.machine = null
			user.reset_view(null)
			selected:use_via_drone_control(user)
		return

	attack_ai(var/mob/user as mob)
		user << "To control a drone, click it. The drone control stations are for humans."
		return
	
	attack_paw(var/mob/user as mob)
		user << "Monkeys can't control drones."
		return
