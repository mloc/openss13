

/obj/item/weapon/infra_sensor/New()

	..()
	spawn( 0 )
		src.process()
		return
	return

/obj/item/weapon/infra_sensor/proc/process()

	if (src.passive)
		for(var/obj/beam/i_beam/I in range(2, src.loc))
			I.left = 2
			//Foreach goto(30)
	spawn( 10 )
		src.process()
		return
	return

/obj/item/weapon/infra_sensor/proc/burst()

	for(var/obj/beam/i_beam/I in range(src.loc))
		I.left = 10
		//Foreach goto(22)
	for(var/obj/item/weapon/infra/I in range(src.loc))
		I.visible = 1
		spawn( 0 )
			if ((I && I.first))
				I.first.vis_spread(1)
			return
		//Foreach goto(69)
	for(var/obj/item/weapon/assembly/rad_infra/I in range(src.loc))
		I.part2.visible = 1
		spawn( 0 )
			if ((I.part2 && I.part2.first))
				I.part2.first.vis_spread(1)
			return
		//Foreach goto(145)
	return

/obj/item/weapon/infra_sensor/attack_self(mob/user as mob)

	user.machine = src
	var/dat = text("<TT><B>Infrared Sensor</B><BR>\n<B>Passive Emitter</B>: []<BR>\n<B>Active Emitter</B>: <A href='?src=\ref[];active=0'>Burst Fire</A>\n</TT>", (src.passive ? text("<A href='?src=\ref[];passive=0'>On</A>", src) : text("<A href='?src=\ref[];passive=1'>Off</A>", src)), src)
	user << browse(dat, "window=infra_sensor")
	return

/obj/item/weapon/infra_sensor/Topic(href, href_list)
	..()
	if (usr.stat || usr.restrained())
		return
	if ((usr.contents.Find(src) || (usr.contents.Find(src.master) || (get_dist(src, usr) <= 1 && istype(src.loc, /turf)))))
		usr.machine = src
		if (href_list["passive"])
			src.passive = !( src.passive )
		if (href_list["active"])
			spawn( 0 )
				src.burst()
				return
		if (!( src.master ))
			if (istype(src.loc, /mob))
				attack_self(src.loc)
			else
				for(var/mob/M in viewers(1, src))
					if (M.client)
						src.attack_self(M)
					//Foreach goto(164)
		else
			if (istype(src.master.loc, /mob))
				src.attack_self(src.master.loc)
			else
				for(var/mob/M in viewers(1, src.master))
					if (M.client)
						src.attack_self(M)
					//Foreach goto(240)
		src.add_fingerprint(usr)
	else
		usr << browse(null, "window=infra_sensor")
		return
	return

/obj/item/weapon/prox_sensor/dropped()

	spawn( 0 )
		src.sense()
		return
	return

/obj/item/weapon/prox_sensor/proc/sense()

	if (src.state)
		if (src.master)
			spawn( 0 )
				src.master:r_signal(1, src)
				return
		else
			for(var/mob/O in hearers(null, null))
				O.show_message(text("\icon[] *beep* *beep*", src), 3, "*beep* *beep*", 2)
				//Foreach goto(58)
	return

/obj/item/weapon/prox_sensor/HasProximity(atom/movable/AM as mob|obj)

	if (istype(AM, /obj/beam))
		return
	if (AM.move_speed < 12)

		src.sense()
	return

/obj/item/weapon/prox_sensor/attackby(obj/item/weapon/radio/signaler/S as obj, mob/user as mob)

	if ((!( istype(S, /obj/item/weapon/radio/signaler) ) || !( S.b_stat )))
		return
	var/obj/item/weapon/assembly/rad_prox/R = new /obj/item/weapon/assembly/rad_prox( user )
	S.loc = R
	R.part1 = S
	S.layer = initial(S.layer)
	if (user.client)
		user.client.screen -= S
	if (user.r_hand == S)
		user.u_equip(S)
		user.r_hand = R
	else
		user.u_equip(S)
		user.l_hand = R
	S.master = R
	src.master = R
	src.layer = initial(src.layer)
	user.u_equip(src)
	if (user.client)
		user.client.screen -= src
	src.loc = R
	R.part2 = src
	R.layer = 20
	R.loc = user
	R.dir = src.dir
	src.add_fingerprint(user)
	return

/obj/item/weapon/prox_sensor/attack_self(mob/user as mob)

	user.machine = src
	var/dat = text("<TT><B>Proximity Sensor</B>\n<B>Status</B>: []<BR>\n[]\n</TT>", (src.state ? text("<A href='?src=\ref[];state=0'>On</A>", src) : text("<A href='?src=\ref[];state=1'>Off</A>", src)), (src.state ? "<b>\red Time On (30)</b>" : text("<A href='?src=\ref[];time=1'>Time On (30)</A>", src)))
	user << browse(dat, "window=prox")
	return




/obj/item/weapon/prox_sensor/Topic(href, href_list)
	..()
	if (usr.stat || usr.restrained())
		return
	if ((usr.contents.Find(src) || usr.contents.Find(src.master) || get_dist(src, usr) <= 1 && istype(src.loc, /turf)))
		usr.machine = src
		if (href_list["state"])
			src.state = !( src.state )
			src.icon_state = text("motion[]", src.state)
			if (src.master)
				src.master:c_state(src.state, src)
		if (href_list["time"])
			src.icon_state = "motion2"

			if(src.master)
				src.master:c_state(2, src)
			spawn( 300 )
				if (src.state == 0)
					src.state = !( src.state )
					src.icon_state = text("motion[]", src.state)
					if (src.master)
						src.master:c_state(src.state, src)
				return
		if (!( src.master ))
			if (istype(src.loc, /mob))
				attack_self(src.loc)
			else
				for(var/mob/M in viewers(1, src))
					if (M.client)
						src.attack_self(M)
					//Foreach goto(234)
		else
			if (istype(src.master.loc, /mob))
				src.attack_self(src.master.loc)
			else
				for(var/mob/M in viewers(1, src.master))
					if (M.client)
						src.attack_self(M)
					//Foreach goto(310)
	else
		usr << browse(null, "window=prox")
		return
	return

/obj/item/weapon/prox_sensor/attack_paw(mob/user as mob)

	return src.attack_hand(user)
	return

/obj/item/weapon/prox_sensor/Move()

	..()
	src.sense()
	return

/obj/item/weapon/infra/proc/hit()

	if (src.master)
		spawn( 0 )
			src.master:r_signal(1, src)
			return
	else
		for(var/mob/O in hearers(null, null))
			O.show_message(text("\icon[] *beep* *beep*", src), 3, "*beep* *beep*", 2)
			//Foreach goto(51)
	return

/obj/item/weapon/infra/proc/process()


	if ((!( src.first ) && (src.state && (istype(src.loc, /turf) || (src.master && istype(src.master.loc, /turf))))))
		//world << "infra process : at [x] [y] [z]"

		var/obj/beam/i_beam/I = new /obj/beam/i_beam( (src.master ? src.master.loc : src.loc) )
		//world << "infra spawning beam : \ref[I]"
		I.master = src
		I.density = 1
		I.dir = src.dir
		step(I, I.dir)
		if (I)
			//world << "infra: beam at [I.x] [I.y] [I.z]"
			I.density = 0
			src.first = I
			//world << "infra : vis_spread"
			I.vis_spread(src.visible)
			spawn( 0 )
				if (I)
					//world << "infra: setting limit"
					I.limit = 20
					//world << "infra: processing beam \ref[I]"
					I.process()
				return
	if (!( src.state ))
		//src.first = null
		del(src.first)
	spawn( 10 )
		src.process()
		return
	return

/obj/item/weapon/infra/attackby(obj/item/weapon/radio/signaler/S as obj, mob/user as mob)

	if ((!( istype(S, /obj/item/weapon/radio/signaler) ) || !( S.b_stat )))
		return
	var/obj/item/weapon/assembly/rad_infra/R = new /obj/item/weapon/assembly/rad_infra( user )
	S.loc = R
	R.part1 = S
	S.layer = initial(S.layer)
	if (user.client)
		user.client.screen -= S
	if (user.r_hand == S)
		user.u_equip(S)
		user.r_hand = R
	else
		user.u_equip(S)
		user.l_hand = R
	S.master = R
	src.master = R
	src.layer = initial(src.layer)
	user.u_equip(src)
	if (user.client)
		user.client.screen -= src
	src.loc = R
	R.part2 = src
	R.layer = 20
	R.loc = user
	R.dir = src.dir
	src.add_fingerprint(user)
	return

/obj/item/weapon/infra/New()

	spawn( 0 )
		src.process()
		return
	..()
	return

/obj/item/weapon/infra/attack_self(mob/user as mob)

	user.machine = src
	var/dat = text("<TT><B>Infrared Laser</B>\n<B>Status</B>: []<BR>\n<B>Visibility</B>: []<BR>\n</TT>", (src.state ? text("<A href='?src=\ref[];state=0'>On</A>", src) : text("<A href='?src=\ref[];state=1'>Off</A>", src)), (src.visible ? text("<A href='?src=\ref[];visible=0'>Visible</A>", src) : text("<A href='?src=\ref[];visible=1'>Invisible</A>", src)))
	user << browse(dat, "window=infra")
	return

/obj/item/weapon/infra/Topic(href, href_list)
	..()
	if (usr.stat || usr.restrained())
		return
	if ((usr.contents.Find(src) || usr.contents.Find(src.master) || get_dist(src, usr) <= 1 && istype(src.loc, /turf)))
		usr.machine = src
		if (href_list["state"])
			src.state = !( src.state )
			src.icon_state = text("infrared[]", src.state)
			if (src.master)
				src.master:c_state(src.state, src)
		if (href_list["visible"])
			src.visible = !( src.visible )
			spawn( 0 )
				if (src.first)
					src.first.vis_spread(src.visible)
				return
		if (!( src.master ))
			if (istype(src.loc, /mob))
				attack_self(src.loc)
			else
				for(var/mob/M in viewers(1, src))
					if (M.client)
						src.attack_self(M)
					//Foreach goto(211)
		else
			if (istype(src.master.loc, /mob))
				src.attack_self(src.master.loc)
			else
				for(var/mob/M in viewers(1, src.master))
					if (M.client)
						src.attack_self(M)
					//Foreach goto(287)
	else
		usr << browse(null, "window=infra")
		return
	return

/obj/item/weapon/infra/attack_paw(mob/user as mob)

	return src.attack_hand(user)
	return

/obj/item/weapon/infra/attack_hand()

	//src.first = null
	del(src.first)
	..()
	return

/obj/item/weapon/infra/Move()

	var/t = src.dir
	..()
	src.dir = t
	//src.first = null
	del(src.first)
	return

/obj/item/weapon/infra/verb/rotate()
	set src in usr

	src.dir = turn(src.dir, 90)
	return

/obj/item/weapon/timer/proc/time()


	src.c_state(0)

	if (src.master)
		spawn( 0 )
			src.master:r_signal(1, src)
			return
	else
		for(var/mob/O in hearers(null, null))
			O.show_message(text("\icon[] *beep* *beep*", src), 3, "*beep* *beep*", 2)
			//Foreach goto(51)
	return

//*****RM


/obj/item/weapon/timer/proc/c_state(n)

	src.icon_state = text("timer[]", n)

	if(src.master)
		src.master:c_state(n)

	return


//*****

/obj/item/weapon/timer/proc/process()

	if (src.timing)
		if (src.time > 0)
			src.time = round(src.time) - 1
			if(time<5)
				src.c_state(2)
			else
				// they might increase the time while it is timing
				src.c_state(1)
		else
			time()
			src.time = 0
			src.timing = 0
		if (!( src.master ))
			if (istype(src.loc, /mob))
				attack_self(src.loc)
			else
				for(var/mob/M in viewers(1, src))
					if (M.client)
						src.attack_self(M)
					//Foreach goto(100)
		else
			if (istype(src.master.loc, /mob))
				src.attack_self(src.master.loc)
			else
				for(var/mob/M in viewers(1, src.master))
					if (M.client)
						src.attack_self(M)
	else
		//If it's not timing, reset the icon so it doesn't look like it's still about to go off.
		src.c_state(0)
	
	spawn( 10 )
		src.process()
		return
	return

/obj/item/weapon/timer/attackby(obj/item/weapon/W as obj, mob/user as mob)


	if (istype(W, /obj/item/weapon/radio/signaler) )
		var/obj/item/weapon/radio/signaler/S = W
		if(!S.b_stat)
			return

		var/obj/item/weapon/assembly/rad_time/R = new /obj/item/weapon/assembly/rad_time( user )
		S.loc = R
		R.part1 = S
		S.layer = initial(S.layer)
		if (user.client)
			user.client.screen -= S
		if (user.r_hand == S)
			user.u_equip(S)
			user.r_hand = R
		else
			user.u_equip(S)
			user.l_hand = R
		S.master = R
		src.master = R
		src.layer = initial(src.layer)
		user.u_equip(src)
		if (user.client)
			user.client.screen -= src
		src.loc = R
		R.part2 = src
		R.layer = 20
		R.loc = user
		R.dir = src.dir
		src.add_fingerprint(user)
		R.add_fingerprint(user)
		return

/obj/item/weapon/timer/New()

	spawn( 0 )
		src.process()
		return
	..()
	return

/obj/item/weapon/timer/attack_self(mob/user as mob)

	if ((user.contents.Find(src) || user.contents.Find(src.master) || get_dist(src, user) <= 1 && istype(src.loc, /turf)))

		user.machine = src
		var/second = src.time % 60
		var/minute = (src.time - second) / 60
		var/dat = text("<TT><B>Timing Unit</B>\n[] []:[]\n<A href='?src=\ref[];tp=-30'>-</A> <A href='?src=\ref[];tp=-1'>-</A> <A href='?src=\ref[];tp=1'>+</A> <A href='?src=\ref[];tp=30'>+</A>\n</TT>", (src.timing ? text("<A href='?src=\ref[];time=0'>Timing</A>", src) : text("<A href='?src=\ref[];time=1'>Not Timing</A>", src)), minute, second, src, src, src, src)
		user << browse(dat, "window=timer")
	else
		user << browse(null, "window=timer")
		user.machine = null

	return

/obj/item/weapon/timer/Topic(href, href_list)
	..()
	if (usr.stat)
		return
	if ((usr.contents.Find(src) || usr.contents.Find(src.master) || get_dist(src, usr) <= 1 && istype(src.loc, /turf)))
		usr.machine = src
		if (href_list["time"])
			src.timing = text2num(href_list["time"])
			if(timing)
				src.c_state(1)

		if (href_list["tp"])
			var/tp = text2num(href_list["tp"])
			src.time += tp
			src.time = min(max(round(src.time), 0), 600)

		if (!( src.master ))
			if (istype(src.loc, /mob))
				attack_self(src.loc)
			else
				for(var/mob/M in viewers(1, src))
					if (M.client)
						src.attack_self(M)
					//Foreach goto(192)
		else
			if (istype(src.master.loc, /mob))
				src.attack_self(src.master.loc)
			else
				for(var/mob/M in viewers(1, src.master))
					if (M.client)
						src.attack_self(M)
					//Foreach goto(268)
		src.add_fingerprint(usr)
	else
		usr << browse(null, "window=timer")
		return
	return

/obj/item/weapon/assembly/proc/r_signal(signal)

	return

/obj/item/weapon/assembly/proc/c_state(n, O as obj)

	return

/obj/item/weapon/assembly/shock_kit/Del()

	//src.part1 = null
	del(src.part1)
	//src.part2 = null
	del(src.part2)
	..()
	return

/obj/item/weapon/assembly/shock_kit/attackby(obj/item/weapon/W as obj, mob/user as mob)

	if ((istype(W, /obj/item/weapon/wrench) && !( src.status )))
		var/turf/T = src.loc
		if (ismob(T))
			T = T.loc
		src.part1.loc = T
		src.part2.loc = T
		src.part1.master = null
		src.part2.master = null
		src.part1 = null
		src.part2 = null
		//SN src = null
		del(src)
		return
	if (!( istype(W, /obj/item/weapon/screwdriver) ))
		return
	src.status = !( src.status )
	if (src.status)
		user.show_message("\blue The shock pack is now secured!", 1)
	else
		user.show_message("\blue The shock pack is now unsecured!", 1)
	src.add_fingerprint(user)
	return

/obj/item/weapon/assembly/shock_kit/attack_self(mob/user as mob)

	src.part1.attack_self(user, src.status)
	src.part2.attack_self(user, src.status)
	src.add_fingerprint(user)
	return

/obj/item/weapon/assembly/shock_kit/r_signal(n, source)

	//*****
	//world << "Shock kit got r_signal"
	if (istype(src.loc, /obj/stool/chair/e_chair))
		var/obj/stool/chair/e_chair/C = src.loc
		//world << "Shock kit sending shock to EC"
		C.shock()
	return

//*****RM

/obj/item/weapon/assembly/time_ignite/Del()
	del(part1)
	del(part2)
	..()

/obj/item/weapon/assembly/time_ignite/attack_self(mob/user as mob)

	src.part1.attack_self(user, src.status)
	src.add_fingerprint(user)
	return

/obj/item/weapon/assembly/time_ignite/r_signal()

	for(var/mob/O in hearers(1, src.loc))
		O.show_message(text("\icon[] *beep* *beep*", src), 3, "*beep* *beep*", 2)
		//Foreach goto(20)
	src.part2.ignite()
	return

/obj/item/weapon/assembly/time_ignite/attackby(obj/item/weapon/W as obj, mob/user as mob)

	if ((istype(W, /obj/item/weapon/wrench) && !( src.status )))
		var/turf/T = src.loc
		if (ismob(T))
			T = T.loc
		src.part1.loc = T
		src.part2.loc = T
		src.part1.master = null
		src.part2.master = null
		src.part1 = null
		src.part2 = null

		del(src)
		return
	if (!( istype(W, /obj/item/weapon/screwdriver) ))
		return
	src.status = !( src.status )
	if (src.status)
		user.show_message("\blue The timer is now secured!", 1)
	else
		user.show_message("\blue The timer is now unsecured!", 1)

	src.add_fingerprint(user)
	return

/obj/item/weapon/assembly/time_ignite/c_state(n)

	src.icon_state = text("time_igniter[]", n)
	return

//*****

/obj/item/weapon/assembly/rad_time/Del()

	//src.part1 = null
	del(src.part1)
	//src.part2 = null
	del(src.part2)
	..()
	return

/obj/item/weapon/assembly/rad_time/attackby(obj/item/weapon/W as obj, mob/user as mob)

	if ((istype(W, /obj/item/weapon/wrench) && !( src.status )))
		var/turf/T = src.loc
		if (ismob(T))
			T = T.loc
		src.part1.loc = T
		src.part2.loc = T
		src.part1.master = null
		src.part2.master = null
		src.part1 = null
		src.part2 = null
		//SN src = null
		del(src)
		return
	if (!( istype(W, /obj/item/weapon/screwdriver) ))
		return
	src.status = !( src.status )
	if (src.status)
		user.show_message("\blue The signaler is now secured!", 1)
	else
		user.show_message("\blue The signaler is now unsecured!", 1)
	src.part1.b_stat = !( src.status )
	src.add_fingerprint(user)
	return

/obj/item/weapon/assembly/rad_time/attack_self(mob/user as mob)

	src.part1.attack_self(user, src.status)
	src.part2.attack_self(user, src.status)
	src.add_fingerprint(user)
	return

/obj/item/weapon/assembly/rad_time/r_signal(n, source)

	if (source == src.part2)
		src.part1.s_signal(1)
	return

/obj/item/weapon/assembly/rad_prox/c_state(n)

	src.icon_state = text("motion[]", n)
	return

/obj/item/weapon/assembly/rad_prox/Del()

	//src.part1 = null
	del(src.part1)
	//src.part2 = null
	del(src.part2)
	..()
	return

/obj/item/weapon/assembly/rad_prox/HasProximity(atom/movable/AM as mob|obj)

	if (istype(AM, /obj/beam))
		return
	if (AM.move_speed < 12)
		src.part2.sense()
	return

/obj/item/weapon/assembly/rad_prox/attackby(obj/item/weapon/W as obj, mob/user as mob)

	if ((istype(W, /obj/item/weapon/wrench) && !( src.status )))
		var/turf/T = src.loc
		if (ismob(T))
			T = T.loc
		src.part1.loc = T
		src.part2.loc = T
		src.part1.master = null
		src.part2.master = null
		src.part1 = null
		src.part2 = null
		//SN src = null
		del(src)
		return
	if (!( istype(W, /obj/item/weapon/screwdriver) ))
		return
	src.status = !( src.status )
	if (src.status)
		user.show_message("\blue The proximity sensor is now secured!", 1)
	else
		user.show_message("\blue The proximity sensor is now unsecured!", 1)
	src.part1.b_stat = !( src.status )
	src.add_fingerprint(user)
	return

/obj/item/weapon/assembly/rad_prox/attack_self(mob/user as mob)

	src.part1.attack_self(user, src.status)
	src.part2.attack_self(user, src.status)
	src.add_fingerprint(user)
	return

/obj/item/weapon/assembly/rad_prox/r_signal(n, source)

	if (source == src.part2)
		src.part1.s_signal(1)
	return

/obj/item/weapon/assembly/rad_prox/Move()

	..()
	src.part2.sense()
	return

/obj/item/weapon/assembly/rad_prox/attack_paw(mob/user as mob)

	return src.attack_hand(user)
	return

/obj/item/weapon/assembly/rad_prox/dropped()

	spawn( 0 )
		src.part2.sense()
		return
	return

/obj/item/weapon/assembly/rad_infra/c_state(n)

	src.icon_state = text("infrared[]", n)
	return

/obj/item/weapon/assembly/rad_infra/Del()

	//src.part1 = null
	del(src.part1)
	//src.part2 = null
	del(src.part2)
	..()
	return

/obj/item/weapon/assembly/rad_infra/attackby(obj/item/weapon/W as obj, mob/user as mob)

	if ((istype(W, /obj/item/weapon/wrench) && !( src.status )))
		var/turf/T = src.loc
		if (ismob(T))
			T = T.loc
		src.part1.loc = T
		src.part2.loc = T
		src.part1.master = null
		src.part2.master = null
		src.part1 = null
		src.part2 = null
		//SN src = null
		del(src)
		return
	if (!( istype(W, /obj/item/weapon/screwdriver) ))
		return
	src.status = !( src.status )
	if (src.status)
		user.show_message("\blue The infrared laser is now secured!", 1)
	else
		user.show_message("\blue The infrared laser is now unsecured!", 1)
	src.part1.b_stat = !( src.status )
	src.add_fingerprint(user)
	return

/obj/item/weapon/assembly/rad_infra/attack_self(mob/user as mob)

	src.part1.attack_self(user, src.status)
	src.part2.attack_self(user, src.status)
	src.add_fingerprint(user)
	return

/obj/item/weapon/assembly/rad_infra/r_signal(n, source)

	if (source == src.part2)
		src.part1.s_signal(1)
	return

/obj/item/weapon/assembly/rad_infra/verb/rotate()
	set src in usr

	src.dir = turn(src.dir, 90)
	src.part2.dir = src.dir
	src.add_fingerprint(usr)
	return

/obj/item/weapon/assembly/rad_infra/Move()

	var/t = src.dir
	..()
	src.dir = t
	//src.part2.first = null
	del(src.part2.first)
	return

/obj/item/weapon/assembly/rad_infra/attack_paw(mob/user as mob)

	return src.attack_hand(user)
	return

/obj/item/weapon/assembly/rad_infra/attack_hand(M)

	//src.part2.first = null
	del(src.part2.first)
	..()
	return

/obj/item/weapon/assembly/prox_ignite/HasProximity(atom/movable/AM as mob|obj)

	if (istype(AM, /obj/beam))
		return
	if (AM.move_speed < 12)
		src.part1.sense()
	return

/obj/item/weapon/assembly/prox_ignite/dropped()

	spawn( 0 )
		src.part1.sense()
		return
	return

/obj/item/weapon/assembly/prox_ignite/Del()

	//src.part1 = null
	del(src.part1)
	//src.part2 = null
	del(src.part2)
	..()
	return

/obj/item/weapon/assembly/prox_ignite/c_state(n)

	src.icon_state = text("prox_igniter[]", n)
	return

/obj/item/weapon/assembly/prox_ignite/attackby(obj/item/weapon/W as obj, mob/user as mob)

	if ((istype(W, /obj/item/weapon/wrench) && !( src.status )))
		var/turf/T = src.loc
		if (ismob(T))
			T = T.loc
		src.part1.loc = T
		src.part2.loc = T
		src.part1.master = null
		src.part2.master = null
		src.part1 = null
		src.part2 = null
		//SN src = null
		del(src)
		return
	if (!( istype(W, /obj/item/weapon/screwdriver) ))
		return
	src.status = !( src.status )
	if (src.status)
		user.show_message("\blue The proximity sensor is now secured! The igniter now works!", 1)
	else
		user.show_message("\blue The proximity sensor is now unsecured! The igniter will not work.", 1)
	src.part2.status = src.status
	src.add_fingerprint(user)
	return

/obj/item/weapon/assembly/prox_ignite/attack_self(mob/user as mob)

	src.part1.attack_self(user, src.status)
	src.add_fingerprint(user)
	return

/obj/item/weapon/assembly/prox_ignite/r_signal()

	for(var/mob/O in hearers(1, src.loc))
		O.show_message(text("\icon[] *beep* *beep*", src), 3, "*beep* *beep*", 2)
		//Foreach goto(20)
	src.part2.ignite()
	return

/obj/item/weapon/assembly/rad_ignite/Del()

	//src.part1 = null
	del(src.part1)
	//src.part2 = null
	del(src.part2)
	..()
	return

/obj/item/weapon/assembly/rad_ignite/attackby(obj/item/weapon/W as obj, mob/user as mob)

	if ((istype(W, /obj/item/weapon/wrench) && !( src.status )))
		var/turf/T = src.loc
		if (ismob(T))
			T = T.loc
		src.part1.loc = T
		src.part2.loc = T
		src.part1.master = null
		src.part2.master = null
		src.part1 = null
		src.part2 = null
		//SN src = null
		del(src)
		return
	if (!( istype(W, /obj/item/weapon/screwdriver) ))
		return
	src.status = !( src.status )
	if (src.status)
		user.show_message("\blue The radio is now secured! The igniter now works!", 1)
	else
		user.show_message("\blue The radio is now unsecured! The igniter will not work.", 1)
	src.part2.status = src.status
	src.part1.b_stat = !( src.status )
	src.add_fingerprint(user)
	return

/obj/item/weapon/assembly/rad_ignite/attack_self(mob/user as mob)

	src.part1.attack_self(user, src.status)
	src.add_fingerprint(user)
	return

/obj/item/weapon/assembly/rad_ignite/r_signal()

	for(var/mob/O in hearers(1, src.loc))
		O.show_message(text("\icon[] *beep* *beep*", src), 3, "*beep* *beep*", 2)
		//Foreach goto(20)
	src.part2.ignite()
	return

/obj/item/weapon/assembly/m_i_ptank/c_state(n)

	src.icon_state = text("m_i_ptank[]", n)
	return

/obj/item/weapon/assembly/m_i_ptank/HasProximity(atom/movable/AM as mob|obj)

	if (istype(AM, /obj/beam))
		return
	if (AM.move_speed < 12)
		src.part1.sense()
	return


//*****RM
/obj/item/weapon/assembly/m_i_ptank/Bump(atom/O)
	spawn(0)
		//world << "miptank bumped into [O]"
		if(src.part1.state)
			//world << "sending signal"
			r_signal()
		else
			//world << "not active"
	..()


/obj/item/weapon/assembly/m_i_ptank/verb/Arm()
	set src in view(1)

	usr.show_message("\blue The proximity sensor has been armed with a delay of 15 seconds.", 1)

	src.icon_state = "m_i_ptank2"
	spawn( 150 )
		if (src.part1.state == 0)
			//world << "\red miptank went active"
			src.part1.state = !( src.part1.state )
			src.part1.icon_state = text("motion[]", src.part1.state)
			src.c_state(src.part1.state, src)
			//sleep(50)
			//src.prox_check()



/obj/item/weapon/assembly/m_i_ptank/proc/prox_check()

	if(!part1 || !part1.state)
		return
	for(var/atom/A in view(1, src.loc))
		if(A!=src && !istype(A, /turf/space) && !isarea(A))
			//world << "[A]:[A.type] was sensed"
			src.part1.sense()
			break

	spawn(50)
		prox_check()


//*****


/obj/item/weapon/assembly/m_i_ptank/dropped()

	spawn( 0 )
		src.part1.sense()
		return
	return

/obj/item/weapon/assembly/m_i_ptank/Del()

	//src.part1 = null
	del(src.part1)
	//src.part2 = null
	del(src.part2)
	//src.part3 = null
	del(src.part3)
	..()
	return

/obj/item/weapon/assembly/m_i_ptank/attackby(obj/item/weapon/W as obj, mob/user as mob)

	if ((istype(W, /obj/item/weapon/wrench) && !( src.status )))
		var/obj/item/weapon/assembly/prox_ignite/R = new /obj/item/weapon/assembly/prox_ignite(  )
		R.part1 = src.part1
		R.part2 = src.part2
		R.loc = src.loc
		if (user.r_hand == src)
			user.r_hand = R
			R.layer = 20
		else
			if (user.l_hand == src)
				user.l_hand = R
				R.layer = 20
		src.part1.loc = R
		src.part2.loc = R
		src.part1.master = R
		src.part2.master = R
		var/turf/T = src.loc
		if (!( istype(T, /turf) ))
			T = T.loc
		if (!( istype(T, /turf) ))
			T = T.loc
		src.part3.loc = T
		src.part1 = null
		src.part2 = null
		src.part3 = null
		//SN src = null
		del(src)
		return
	if (!( istype(W, /obj/item/weapon/weldingtool) ))
		return
	if (!( src.status ))
		src.status = 1
		bombers -= user.ckey
		bombers += user.ckey
		user.show_message("\blue A pressure hole has been bored to the plasma tank valve. The plasma tank can now be ignited.", 1)
	else
		src.status = 0
		user << "\blue The hole has been closed."
	src.part2.status = src.status
	src.add_fingerprint(user)
	return

/obj/item/weapon/assembly/m_i_ptank/attack_self(mob/user as mob)

	src.part1.attack_self(user, 1)
	src.add_fingerprint(user)
	return

/obj/item/weapon/assembly/m_i_ptank/r_signal()
	//world << "miptank [src] got signal"
	for(var/mob/O in hearers(1, null))
		O.show_message(text("\icon[] *beep* *beep*", src), 3, "*beep* *beep*", 2)
		//Foreach goto(19)

	if ((src.status && prob(90)))
		//world << "sent ignite() to [src.part3]"
		src.part3.ignite()
	else
		if(!src.status)
			src.part3.release()
			src.part1.state = 0.0

	return

//*****RM

/obj/item/weapon/assembly/t_i_ptank/c_state(n)

	src.icon_state = text("t_i_ptank[]", n)
	return


/obj/item/weapon/assembly/t_i_ptank/Del()

	//src.part1 = null
	del(src.part1)
	//src.part2 = null
	del(src.part2)
	//src.part3 = null
	del(src.part3)
	..()
	return

/obj/item/weapon/assembly/t_i_ptank/attackby(obj/item/weapon/W as obj, mob/user as mob)

	if ((istype(W, /obj/item/weapon/wrench) && !( src.status )))
		var/obj/item/weapon/assembly/time_ignite/R = new /obj/item/weapon/assembly/time_ignite(  )
		R.part1 = src.part1
		R.part2 = src.part2
		R.loc = src.loc
		if (user.r_hand == src)
			user.r_hand = R
			R.layer = 20
		else
			if (user.l_hand == src)
				user.l_hand = R
				R.layer = 20
		src.part1.loc = R
		src.part2.loc = R
		src.part1.master = R
		src.part2.master = R
		var/turf/T = src.loc
		if (!( istype(T, /turf) ))
			T = T.loc
		if (!( istype(T, /turf) ))
			T = T.loc
		src.part3.loc = T
		src.part1 = null
		src.part2 = null
		src.part3 = null
		//SN src = null
		del(src)
		return
	if (!( istype(W, /obj/item/weapon/weldingtool) ))
		return
	if (!( src.status ))
		src.status = 1
		bombers -= user.ckey
		bombers += user.ckey
		user.show_message("\blue A pressure hole has been bored to the plasma tank valve. The plasma tank can now be ignited.", 1)
	else
		src.status = 0
		user << "\blue The hole has been closed."
	src.part2.status = src.status

	src.add_fingerprint(user)
	return

/obj/item/weapon/assembly/t_i_ptank/attack_self(mob/user as mob)

	if (src.part1)
		src.part1.attack_self(user, 1)
	src.add_fingerprint(user)
	return

/obj/item/weapon/assembly/t_i_ptank/r_signal()
	//world << "tiptank [src] got signal"
	for(var/mob/O in hearers(1, null))
		O.show_message(text("\icon[] *beep* *beep*", src), 3, "*beep* *beep*", 2)
		//Foreach goto(19)
	if ((src.status && prob(90)))
		//world << "sent ignite() to [src.part3]"
		src.part3.ignite()
	else
		if(!src.status)
			src.part3.release()
	return

/*
/obj/item/weapon/assembly/t_i_ptank/examine()
	usr << "t_i_ptank"
	usr << "P1: [src.part1] : [src.part1.master]"
	usr << "P2: [src.part2] : [src.part2.master]"
	usr << "P3: [src.part3] : [src.part3.master]"

	usr << "status: [status]   flags: [flags]"



/obj/item/weapon/assembly/r_i_ptank/examine()
	usr << "r_i_ptank"
	usr << "P1: [src.part1] : [src.part1.master]"
	usr << "P2: [src.part2] : [src.part2.master]"
	usr << "P3: [src.part3] : [src.part3.master]"

	usr << "status: [status]   flags: [flags]"

*/
//*****


/obj/item/weapon/assembly/r_i_ptank/Del()

	//src.part1 = null
	del(src.part1)
	//src.part2 = null
	del(src.part2)
	//src.part3 = null
	del(src.part3)
	..()
	return

/obj/item/weapon/assembly/r_i_ptank/attackby(obj/item/weapon/W as obj, mob/user as mob)

	if ((istype(W, /obj/item/weapon/wrench) && !( src.status )))
		var/obj/item/weapon/assembly/rad_ignite/R = new /obj/item/weapon/assembly/rad_ignite(  )
		R.part1 = src.part1
		R.part2 = src.part2
		R.loc = src.loc
		if (user.r_hand == src)
			user.r_hand = R
			R.layer = 20
		else
			if (user.l_hand == src)
				user.l_hand = R
				R.layer = 20
		src.part1.loc = R
		src.part2.loc = R
		src.part1.master = R
		src.part2.master = R
		var/turf/T = src.loc
		if (!( istype(T, /turf) ))
			T = T.loc
		if (!( istype(T, /turf) ))
			T = T.loc
		src.part3.loc = T
		src.part1 = null
		src.part2 = null
		src.part3 = null
		//SN src = null
		del(src)
		return
	if (!( istype(W, /obj/item/weapon/weldingtool) ))
		return
	if (!( src.status ))
		src.status = 1
		bombers -= user.ckey
		bombers += user.ckey
		user.show_message("\blue A pressure hole has been bored to the plasma tank valve. The plasma tank can now be ignited.", 1)
	else
		src.status = 0
		user << "\blue The hole has been closed."
	src.part2.status = src.status
	src.part1.b_stat = !( src.status )
	src.add_fingerprint(user)
	return

/obj/item/weapon/assembly/r_i_ptank/attack_self(mob/user as mob)

	if (src.part1)
		src.part1.attack_self(user, 1)
	src.add_fingerprint(user)
	return

/obj/item/weapon/assembly/r_i_ptank/r_signal()
	//world << "riptank [src] got signal"
	for(var/mob/O in hearers(1, null))
		O.show_message(text("\icon[] *beep* *beep*", src), 3, "*beep* *beep*", 2)
		//Foreach goto(19)
	if ((src.status && prob(90)))
		//world << "sent ignite() to [src.part3]"
		src.part3.ignite()
	else
		if(!src.status)
			src.part3.release()
	return

/obj/bullet/Bump(atom/A as mob|obj|turf|area)

	spawn( 0 )
		if (A)
			A.las_act("bullet", src)
		//SN src = null
		del(src)
		return
		return
	return

/obj/bullet/CheckPass(B as obj)

	if (istype(B, /obj/bullet))
		return prob(95)
	else
		return 1
	return

/obj/bullet/proc/process()

	if ((!( src.current ) || src.loc == src.current))
		src.current = locate(min(max(src.x + src.xo, 1), world.maxx), min(max(src.y + src.yo, 1), world.maxy), src.z)
	if ((src.x == 1 || src.x == world.maxx || src.y == 1 || src.y == world.maxy))
		//SN src = null
		del(src)
		return
	step_towards(src, src.current)
	spawn( 1 )
		process()
		return
	return

/obj/beam/a_laser/Bump(atom/A as mob|obj|turf|area)

	spawn( 0 )
		if (A)
			A.las_act(null, src)
		//SN src = null
		del(src)
		return
		return
	return

/obj/beam/a_laser/proc/process()

	if ((!( src.current ) || src.loc == src.current))
		src.current = locate(min(max(src.x + src.xo, 1), world.maxx), min(max(src.y + src.yo, 1), world.maxy), src.z)
	if ((src.x == 1 || src.x == world.maxx || src.y == 1 || src.y == world.maxy))
		//SN src = null
		del(src)
		return
	step_towards(src, src.current)
	src.life--
	if (src.life <= 0)
		//SN src = null
		del(src)
		return
	spawn( 1 )
		src.process()
		return
	return

/obj/beam/a_laser/s_laser/Bump(atom/A as mob|obj|turf|area)

	spawn( 0 )
		if(A)
			A.las_act(1)
		//SN src = null
		del(src)
		return
		return
	return

/obj/beam/i_beam/proc/hit()

	//world << "beam \ref[src]: hit"
	if (src.master)
		//world << "beam hit \ref[src]: calling master \ref[master].hit"
		src.master.hit()
	//SN src = null
	del(src)
	return
	return

/obj/beam/i_beam/proc/vis_spread(v)
	//world << "i_beam \ref[src] : vis_spread"
	src.visible = v
	spawn( 0 )
		if (src.next)
			//world << "i_beam \ref[src] : is next [next.type] \ref[next], calling spread"
			src.next.vis_spread(v)
		return
	return

/obj/beam/i_beam/proc/process()

	//world << "i_beam \ref[src] : process"

	if ((src.loc.density || !( src.master )))
		//SN src = null
	//	world << "beam hit loc [loc] or no master [master], deleting"
		del(src)
		return
	//world << "proccess: [src.left] left"

	if (src.left > 0)
		src.left--
	if (src.left < 1)
		if (!( src.visible ))
			src.invisibility = 100
		else
			src.invisibility = 0
	else
		src.invisibility = 0


	//world << "now [src.left] left"
	var/obj/beam/i_beam/I = new /obj/beam/i_beam( src.loc )
	I.master = src.master
	I.density = 1
	I.dir = src.dir
	//world << "created new beam \ref[I] at [I.x] [I.y] [I.z]"
	step(I, I.dir)

	if (I)
		//world << "step worked, now at [I.x] [I.y] [I.z]"
		if (!( src.next ))
			//world << "no src.next"
			I.density = 0
			//world << "spreading"
			I.vis_spread(src.visible)
			src.next = I
			spawn( 0 )
				//world << "limit = [src.limit] "
				if ((I && src.limit > 0))
					I.limit = src.limit - 1
					//world << "calling next process"
					I.process()
				return
		else
			//world << "is a next: \ref[next], deleting beam \ref[I]"
			//I = null
			del(I)
	else
		//src.next = null
		//world << "step failed, deleting \ref[src.next]"
		del(src.next)
	spawn( 10 )
		src.process()
		return
	return

/obj/beam/i_beam/Bump()

	//SN src = null

	del(src)
	return

/obj/beam/i_beam/Bumped()

	src.hit()
	return

/obj/beam/i_beam/HasEntered(atom/movable/AM as mob|obj)

	if (istype(AM, /obj/beam))
		return
	spawn( 0 )
		src.hit()
		return
	return

/obj/beam/i_beam/Del()

	//src.next = null
	del(src.next)
	..()
	return

/atom/proc/ex_act()

	return

/atom/proc/blob_act()
	return

/atom/proc/las_act()

	return

/atom/proc/buildlinks()
	return

/turf/Entered(atom/A as mob|obj)

	..()
	if ((A && A.density && !( istype(A, /obj/beam) )))
		for(var/obj/beam/i_beam/I in src)
			spawn( 0 )
				if (I)
					I.hit()
				return
			//Foreach goto(44)
	return
