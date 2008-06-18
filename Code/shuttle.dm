

/obj/shut_controller/proc/rotate(direct)

	var/SE_X = 1
	var/SE_Y = 1
	var/SW_X = 1
	var/SW_Y = 1
	var/NE_X = 1
	var/NE_Y = 1
	var/NW_X = 1
	var/NW_Y = 1
	for(var/obj/move/M in src.parts)
		if (M.x < SW_X)
			SW_X = M.x
		if (M.x > SE_X)
			SE_X = M.x
		if (M.y < SW_Y)
			SW_Y = M.y
		if (M.y > NW_Y)
			NW_Y = M.y
		if (M.y > NE_Y)
			NE_Y = M.y
		if (M.y < SE_Y)
			SE_Y = M.y
		if (M.x > NE_X)
			NE_X = M.x
		if (M.x < NW_X)
			NW_X = M.y
		//Foreach goto(75)
	var/length = abs(NE_X - NW_X)
	var/width = abs(NE_Y - SE_Y)
	var/obj/random = pick(src.parts)
	var/s_direct = null
	switch(s_direct)
		if(1.0)
			switch(direct)
				if(90.0)
					var/tx = SE_X
					var/ty = SE_Y
					var/t_z = random.z
					for(var/obj/move/M in src.parts)
						M.ty =  -M.x - tx
						M.tx =  -M.y - ty
						var/T = locate(M.x, M.y, 11)
						M.relocate(T)
						M.ty =  -M.ty
						M.tx += length
						//Foreach goto(374)
					for(var/obj/move/M in src.parts)
						M.tx += tx
						M.ty += ty
						var/T = locate(M.tx, M.ty, t_z)
						M.relocate(T, 90)
						//Foreach goto(468)
				if(-90.0)
					var/tx = SE_X
					var/ty = SE_Y
					var/t_z = random.z
					for(var/obj/move/M in src.parts)
						M.ty = M.x - tx
						M.tx = M.y - ty
						var/T = locate(M.x, M.y, 11)
						M.relocate(T)
						M.ty =  -M.ty
						M.ty += width
						//Foreach goto(571)
					for(var/obj/move/M in src.parts)
						M.tx += tx
						M.ty += ty
						var/T = locate(M.tx, M.ty, t_z)
						M.relocate(T, -90.0)
						//Foreach goto(663)
				else
		else
	return

/obj/shuttle/door/attackby(obj/item/I as obj, mob/user as mob)
	if (src.operating)
		return
	if (src.density)
		return open()
	else
		return close()

/obj/shuttle/door/attack_ai(mob/user as mob)
	return src.attack_hand(user)

/obj/shuttle/door/attack_paw(mob/user as mob)
	return src.attack_hand(user)

/obj/shuttle/door/attack_hand(mob/user as mob)
	return attackby(user, user)

/obj/shuttle/door/verb/open()
	set src in oview(1)
	var/result = src.canReach(usr, null, 1)
	if (result==0)
		usr.client_mob() << "You can't reach [src]."
		return
	
	src.add_fingerprint(usr)
	if (src.operating)
		return
	src.operating = 1
	flick("doorc0", src)
	src.icon_state = "door0"
	sleep(15)
	src.density = 0
	src.opacity = 0
	src.verbs -= /obj/shuttle/door/verb/open
	src.verbs += /obj/shuttle/door/proc/close
	src.operating = 0

	src.loc.buildlinks()

	return

/obj/shuttle/door/proc/close()
	set src in oview(1)
	var/result = src.canReach(usr, null, 1)
	if (result==0)
		usr.client_mob() << "You can't reach [src]."
		return

	src.add_fingerprint(usr)
	if (src.operating)
		return
	src.operating = 1
	flick("doorc1", src)
	src.icon_state = "door1"
	src.density = 1
	if (src.visible)
		src.opacity = 1
	sleep(15)
	src.verbs += /obj/shuttle/door/verb/open
	src.verbs -= /obj/shuttle/door/proc/close
	src.operating = 0

	src.loc.buildlinks()
	return

/turf/station/shuttle/ex_act(severity)

	switch(severity)
		if(1.0)
			//SN src = null
			var/turf/space/S = src.ReplaceWithSpace()
			S.buildlinks()

			del(src)
			return
		if(2.0)
			if (prob(50))
				//SN src = null
				var/turf/space/S = src.ReplaceWithSpace()
				S.buildlinks()

				del(src)
				return
		else
	return

/turf/station/shuttle/blob_act()
	if(prob(20))

		var/turf/space/S = src.ReplaceWithSpace()
		S.buildlinks()

		del(src)
