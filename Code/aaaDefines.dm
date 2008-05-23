/proc/add_zero(t, u)

	while(length(t) < u)
		t = text("0[]", t)
	return t

/proc/add_lspace(t, u)
	while(length(t) < u)
		t = " [t]"
	return t

/proc/add_tspace(t, u)
	while(length(t) < u)
		t = "[t] "
	return t

/obj/bomb/New()

	..()				//*****RM
	switch(btype)
		if(0)			// radio
			var/obj/item/weapon/assembly/r_i_ptank/R = new /obj/item/weapon/assembly/r_i_ptank( src.loc )
			var/obj/item/weapon/tank/plasmatank/p3 = new /obj/item/weapon/tank/plasmatank( R )
			var/obj/item/weapon/radio/signaler/p1 = new /obj/item/weapon/radio/signaler( R )
			var/obj/item/weapon/igniter/p2 = new /obj/item/weapon/igniter( R )
			R.part1 = p1
			R.part2 = p2
			R.part3 = p3
			p1.master = R
			p2.master = R
			p3.master = R
			R.status = explosive
			p1.b_stat = 0
			p2.status = 1
			p3.gas.temperature = btemp + T0C
			//SN src = null

		if(1)			// prox
			var/obj/item/weapon/assembly/m_i_ptank/R = new /obj/item/weapon/assembly/m_i_ptank( src.loc )
			var/obj/item/weapon/tank/plasmatank/p3 = new /obj/item/weapon/tank/plasmatank( R )
			var/obj/item/weapon/prox_sensor/p1 = new /obj/item/weapon/prox_sensor( R )
			var/obj/item/weapon/igniter/p2 = new /obj/item/weapon/igniter( R )
			R.part1 = p1
			R.part2 = p2
			R.part3 = p3
			p1.master = R
			p2.master = R
			p3.master = R
			R.status = explosive

			p3.gas.temperature = btemp +T0C
			p2.status = 1


			if(src.active)
				R.part1.state = 1
				R.part1.icon_state = text("motion[]", 1)
				R.c_state(1, src)

		if(2)			// time

			var/obj/item/weapon/assembly/t_i_ptank/R = new /obj/item/weapon/assembly/t_i_ptank( src.loc )
			var/obj/item/weapon/tank/plasmatank/p3 = new /obj/item/weapon/tank/plasmatank( R )
			var/obj/item/weapon/timer/p1 = new /obj/item/weapon/timer( R )
			var/obj/item/weapon/igniter/p2 = new /obj/item/weapon/igniter( R )
			R.part1 = p1
			R.part2 = p2
			R.part3 = p3
			p1.master = R
			p2.master = R
			p3.master = R
			R.status = explosive

			p3.gas.temperature = btemp +T0C
			p2.status = 1

	del(src)
	return

/obj/proc/throwing(t_dir, rs)

	if (src.throwspeed <= 1)
		src.throwing = 0
	src.throwspeed--
	if (rs == 0)
		rs = 1
	if (src.throwing)
		if (rs == 1)
			step(src, t_dir)
			sleep(1)
			spawn( 0 )
				throwing(t_dir, rs)
				return
		else
			if (rs > 1)
				var/t = null
				while(t < rs)
					step(src, t_dir)
					t++
				sleep(10)
				spawn( 0 )
					src.throwing(t_dir, rs)
					return
			else
				step(src, t_dir)
				sleep(10 / rs)
				spawn( 0 )
					throwing(t_dir, rs)
					return
	else
		//*****RM
		//src.density = 0
		if(istype(src, /obj/item))
			src.density = 0

		//*****
	return


//*****RM

/obj/Bump(atom/O)

	if (src.throwing)
		//world<<"[src] bumped into [O] and stopped"
		src.throwing = 0
	..()

//*****
/atom/proc/burn(fi_amount)

	return

/atom/movable/Move()

	var/atom/A = src.loc
	. = ..()
	src.move_speed = world.time - src.l_move_time
	src.l_move_time = world.time
	src.m_flag = 1
	if ((A != src.loc && A && A.z == src.z))
		src.last_move = get_dir(A, src.loc)
	return


/proc/cleanstring(var/t)

	var/index = findtext(t, "\n")
	while(index)
		t = copytext(t, 1, index) + "#" + copytext(t, index+1)
		index = findtext(t, "\n")


	index = findtext(t, "\t")
	while(index)
		t = copytext(t, 1, index) + "#" + copytext(t, index+1)
		index = findtext(t, "\t")


	return t


/datum/config/New()

	for(var/M in modes)
		pickprob[M] = 1

/datum/config/proc/pickmode()
	var/total = 0
	var/list/accum = list()

	for(var/M in modes)
		total += pickprob[M]
		accum[M] = total

		//world << "[M] [pickprob[M]] [accum[M]]"

	var/r = total-(rand()*total)

	//world << "Chosen value is [r]"

	for(var/M in modes)
		if(pickprob[M]>0 && accum[M]>=r)
			//world << "Returning mode [M]"
			return M

	//world << "Failed to pick gamemode in config/pickmode()"

	return null

/proc/upperfirst(var/t as text)
	return uppertext(copytext(t,1,2))+copytext(t,2)


