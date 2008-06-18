
/obj/machinery/computer/teleporter/New()

	src.id = text("[]", rand(1000, 9999))
	..()
	return

/obj/machinery/computer/teleporter/ex_act(severity)

	switch(severity)
		if(1.0)
			//SN src = null
			del(src)
			return
		if(2.0)
			if (prob(50))
				for(var/x in src.verbs)
					src.verbs -= x
					//Foreach goto(58)
				src.icon_state = "broken"
		if(3.0)
			if (prob(25))
				for(var/x in src.verbs)
					src.verbs -= x
					//Foreach goto(109)
				src.icon_state = "broken"
		else
	return

/obj/machinery/computer/teleporter/verb/lock_in(freq as num)
	set src in oview(1)
	set desc = "Frequency to check"

	if(stat & (NOPOWER|BROKEN) )
		return
	var/result = src.canReach(usr, null, 1)
	if (result==0)
		usr.client_mob() << "You can't reach [src]."
		return
	
	var/list/L = list(  )
	for(var/obj/item/weapon/radio/R in world)
		if (R.freq != freq)
			continue //goto(26)
		var/turf/T = src.find_loc(R)
		if (!( T ))
			continue //goto(26)
		var/t1 = text("-[],[],[]", T.x, T.y, T.z)
		t1 = text("[][]", R.text, t1)
		L[t1] = R
		//Foreach goto(26)
	var/t1 = input("Please select a location to lock in.", "Locking Computer", null, null) in L
	var/R = L[t1]
	if ((prob(30) || istype(R, /obj/item/weapon/radio/beacon) && prob(50)))
		src.locked = src.find_loc(R)
	else
		if (L.len)
			R = L[text("[]", pick(L))]
			src.locked = src.find_loc(R)
		else
			src.locked = null
	for(var/mob/O in hearers(src, null))
		O.show_message("\blue Locked In", 2)
		//Foreach goto(270)
	src.add_fingerprint(usr)
	return

/obj/machinery/computer/teleporter/verb/set_id(t as text)
	set src in oview(1)
	set desc = "ID Tag:"

	if(stat & (NOPOWER|BROKEN) )
		return
	var/result = src.canReach(usr, null, 1)
	if (result==0)
		usr.client_mob() << "You can't reach [src]."
		return
	if (t)
		src.id = t
	return

/obj/machinery/computer/teleporter/proc/find_loc(obj/R as obj)

	if (!( R ))
		return null

	var/turf/T = R.loc

	while(!( istype(T, /turf) ))
		T = T.loc

		if(!T)
			return null

		if (istype(T, /area))
			return null


	return T
	return

/obj/machinery/teleport/hub/Bumped(M as mob|obj)

	spawn( 0 )
		if (src.icon_state == "tele1")
			teleport(M)
			use_power(5000)
		return
	return

/obj/machinery/teleport/hub/proc/teleport(atom/movable/M as mob|obj)

	var/atom/l = src.loc
	var/obj/machinery/computer/teleporter/com = locate(/obj/machinery/computer/teleporter, locate(l.x - 2, l.y, l.z))
	if (!( com ))
		return
	var/atom/target = com.locked
	if (!( com.locked ))
		for(var/mob/O in hearers(src, null))
			O.show_message("\red Failure: Cannot authenticate locked on coordinates. Please reinstantiat coordinate matrix.", 1, "\red Error!", 2)
			//Foreach goto(80)
		return
	var/obj/effects/sparks/O = new /obj/effects/sparks( target )
	O.dir = pick(1, 2, 4, 8)
	spawn( 0 )
		O.Life()
		return
	if (istype(M, /atom/movable))
		if (rand(1, 1000) == 7)
			M << "\red You see a fainting blue light."
			M.loc = null
		else
			var/tx = target.x + rand(-2.0, 2)
			var/ty = target.y + rand(-2.0, 2)
			tx = max(min(tx, world.maxx), 1)
			ty = max(min(ty, world.maxy), 1)
			M.loc = locate(tx, ty, target.z)
	else
		for(var/mob/B in hearers(src, null))
			B.show_message("\blue Test fire completed.", 2)
			//Foreach goto(316)
	return

/obj/machinery/teleport/station/verb/engage()
	set src in oview(1)
	if(stat & NOPOWER) return
	var/result = src.canReach(usr, null, 1)
	if (result==0)
		usr.client_mob() << "You can't reach [src]."
		return
	
	var/atom/l = src.loc
	var/atom/com = locate(/obj/machinery/teleport/hub, locate(l.x + 1, l.y, l.z))
	if (com)
		com.icon_state = "tele1"
		use_power(5000)
		for(var/mob/O in hearers(src, null))
			O.show_message("\blue Teleporter engaged!", 2)
			//Foreach goto(70)
	src.add_fingerprint(usr)
	return

/obj/machinery/teleport/station/verb/disengage()
	set src in oview(1)
	if(stat & NOPOWER) return
	var/result = src.canReach(usr, null, 1)
	if (result==0)
		usr.client_mob() << "You can't reach [src]."
		return
	
	var/atom/l = src.loc
	var/atom/com = locate(/obj/machinery/teleport/hub, locate(l.x + 1, l.y, l.z))
	if (com)
		com.icon_state = "tele0"
		for(var/mob/O in hearers(src, null))
			O.show_message("\blue Teleporter disengaged!", 2)
			//Foreach goto(70)
	src.add_fingerprint(usr)
	return

/obj/machinery/teleport/station/verb/testfire()
	set src in oview(1)

	if(stat & NOPOWER) return
	var/result = src.canReach(usr, null, 1)
	if (result==0)
		usr.client_mob() << "You can't reach [src]."
		return
	
	var/atom/l = src.loc
	var/obj/machinery/teleport/hub/com = locate(/obj/machinery/teleport/hub, locate(l.x + 1, l.y, l.z))
	if (com && !active)
		active = 1
		for(var/mob/O in hearers(src, null))
			O.show_message("\blue Test firing!", 2)
			//Foreach goto(60)
		com.teleport()
		use_power(5000)

		spawn(30)
			active=0

	src.add_fingerprint(usr)
	return

/obj/machinery/teleport/station/power_change()
	..()
	if(stat & NOPOWER)
		icon_state = "controller-p"
		var/obj/machinery/teleport/hub/com = locate(/obj/machinery/teleport/hub, locate(x + 1, y, z))
		if(com)
			com.icon_state = "tele0"
	else
		icon_state = "controller"

/obj/effects/smoke/proc/Life()

	if (src.amount > 1)
		var/obj/effects/smoke/W = new src.type( src.loc )
		W.amount = src.amount - 1
		W.dir = src.dir
		spawn( 0 )
			W.Life()
			return
	src.amount--
	if (src.amount <= 0)
		sleep(50)
		//SN src = null
		del(src)
		return
	var/turf/T = get_step(src, turn(src.dir, pick(90, 0, 0, -90.0)))
	if ((T && T.density))
		src.dir = turn(src.dir, pick(-90.0, 90))
	else
		step_to(src, T, null)
		T = src.loc
		if (istype(T, /turf))
			T.firelevel = T.poison
	spawn( 3 )
		src.Life()
		return
	return

/obj/effects/sparks/proc/Life()

	if (src.amount > 1)
		var/obj/effects/sparks/W = new src.type( src.loc )
		W.amount = src.amount - 1
		W.dir = src.dir
		spawn( 0 )
			W.Life()
			return
	src.amount--
	if (src.amount <= 0)
		sleep(50)
		//SN src = null
		del(src)
		return
	var/turf/T = get_step(src, turn(src.dir, pick(90, 0, 0, -90.0)))
	if ((T && T.density))
		src.dir = turn(src.dir, pick(-90.0, 90))
	else
		step_to(src, T, null)
		T = src.loc
		if (istype(T, /turf))
			T.firelevel = T.poison
	spawn( 3 )
		src.Life()
		return
	return

/obj/effects/sparks/New()

	..()
	var/turf/T = src.loc
	if (istype(T, /turf))
		T.firelevel = T.poison
	return

/obj/effects/sparks/Del()

	var/turf/T = src.loc
	if (istype(T, /turf))
		T.firelevel = T.poison
	..()
	return

/obj/effects/sparks/Move()

	..()
	var/turf/T = src.loc
	if (istype(T, /turf))
		T.firelevel = T.poison
	return

/obj/laser/Bump()

	src.range--
	return

/obj/laser/Move()

	src.range--
	return

/atom/proc/laserhit(L as obj)

	return 1
	return
