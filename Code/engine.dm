#define ENGINE_EJECT_Z 6





/turf/station/engine/attack_paw(var/mob/user as mob)

	return src.attack_hand(user)

/turf/station/engine/attack_hand(var/mob/user as mob)

	if ((!( user.canmove ) || user.restrained() || !( user.pulling )))
		return
	if (user.pulling.anchored)
		return
	if ((user.pulling.loc != user.loc && get_dist(user, user.pulling) > 1))
		return
	if (ismob(user.pulling))
		var/mob/M = user.pulling
		var/mob/t = M.pulling
		M.pulling = null
		step(user.pulling, get_dir(user.pulling.loc, src))
		M.pulling = t
	else
		step(user.pulling, get_dir(user.pulling.loc, src))
	return

/turf/station/engine/attackby(obj/item/weapon/C as obj, mob/user as mob)

	if (istype(C, /obj/item/weapon/pipe) )
		var/obj/item/weapon/pipe/P = C
		P.turf_place(src, user)

/turf/station/engine/floor/ex_act(severity)

	switch(severity)
		if(1.0)
			//SN src = null
			var/turf/space/S = new /turf/space( locate(src.x, src.y, src.z) )
			S.buildlinks()
			del(src)
			return
		if(2.0)
			if (prob(50))
				//SN src = null
				var/turf/space/S = new /turf/space( locate(src.x, src.y, src.z) )
				S.buildlinks()

				del(src)
				return
		else
	return

/turf/station/engine/floor/blob_act()
	return

/datum/engine_eject/proc/ejectstart()

	if (!( src.status ))
		if (src.timeleft <= 0)
			src.timeleft = 60
		world << "\red <B>Alert: Ejection Sequence for Engine Module has been engaged.</B>"
		world << text("\red <B>Ejection Time in T-[] seconds!</B>", src.timeleft)
		src.resetting = 0

		var/list/EA = engine_areas()

		for(var/area/A in EA)
			A.eject = 1
			A.updateicon()

		src.status = 1
		for(var/obj/machinery/computer/engine/E in machines)
			E.icon_state = "engaging"
			//Foreach goto(113)
		spawn( 0 )
			src.countdown()
			return
	return

/datum/engine_eject/proc/resetcount()

	if (!( src.status ))
		src.resetting = 1
	sleep(50)
	if (src.resetting)
		src.timeleft = 60
		world << "\red <B>Alert: Ejection Sequence Countdown for Engine Module has been reset.</B>"
	return

/datum/engine_eject/proc/countdone()

	src.status = -1.0

	var/list/E = engine_areas()

	var/list/engineturfs = list()
	for(var/area/EA in E)
		EA.eject = 0
		EA.updateicon()
		for(var/turf/ET in EA)
			engineturfs += ET

	defer_powernet_rebuild = 1
	for(var/turf/T in engineturfs)
		var/turf/S = new T.type( locate(T.x, T.y, ENGINE_EJECT_Z) )

		var/area/A = T.loc

		for(var/atom/movable/AM as mob|obj in T)
			AM.loc = S
			S.oxygen = T.oxygen
			S.oldoxy = T.oldoxy
			S.tmpoxy = T.tmpoxy
			S.poison = T.poison
			S.oldpoison = T.oldpoison
			S.tmppoison = T.tmppoison
			S.co2 = T.co2
			S.oldco2 = T.oldco2
			S.tmpco2 = T.tmpco2
			S.sl_gas = T.sl_gas
			S.osl_gas = T.osl_gas
			S.tsl_gas = T.tsl_gas
			S.n2 = T.n2
			S.on2 = T.on2
			S.tn2 = T.tn2
			S.temp = T.temp
			S.ttemp = T.ttemp
			S.otemp = T.otemp
			S.firelevel = T.firelevel
			//Foreach goto(100)
			S.buildlinks()



		A.contents += S
		var/turf/P = new T.type( locate(T.x, T.y, T.z) )
		var/area/D = locate(/area/dummy)
		D.contents += P

		//T = null

		del(T)
		P.buildlinks()



		//Foreach goto(60)
	defer_powernet_rebuild = 0
	makepowernets()
	world << "\red <B>Engine Ejected!</B>"
	for(var/obj/machinery/computer/engine/CE in machines)
		CE.icon_state = "engaged"
		//Foreach goto(392)
	return

/datum/engine_eject/proc/stopcount()

	if (src.status > 0)
		src.status = 0
		world << "\red <B>Alert: Ejection Sequence for Engine Module has been disengaged!</B>"

		var/list/E = engine_areas()

		for(var/area/A in E)
			A.eject = 0
			A.updateicon()

		for(var/obj/machinery/computer/engine/CE in machines)
			CE.icon_state = null
			//Foreach goto(84)
	return

/datum/engine_eject/proc/countdown()

	if (src.timeleft <= 0)
		spawn( 0 )
			countdone()
			return
		return
	if (src.status > 0)
		src.timeleft--
		if ((src.timeleft <= 15 || src.timeleft == 30))
			world << text("\red <B>[] seconds until engine ejection.</B>", src.timeleft)
		spawn( 10 )
			src.countdown()
			return
	return


//returns a list of areas that are under /area/engine
/datum/engine_eject/proc/engine_areas()
	var/list/L = list()
	for(var/area/A in world)
		if(istype(A, /area/engine))
			L += A

	return L






