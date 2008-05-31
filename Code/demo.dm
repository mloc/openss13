/obj/item/weapon/clothing/burn(fi_amount)
	if (fi_amount > src.s_fire)
		spawn(0)
			var/t 			= src.icon_state
			src.icon_state 	= ""
			src.icon 		= 'b_items.dmi'
			flick("[t]", src)
			spawn(14) del(src)
		return 0
	return 1

/obj/item/weapon/clothing/gloves/examine()
	set src in usr
	..()
	return

/obj/item/weapon/clothing/shoes/orange/attack_self(mob/user as mob)
	if (src.chained)
		src.chained = null
		new /obj/item/weapon/handcuffs( user.loc )
		src.icon_state = "o_shoes"
	return

/obj/item/weapon/clothing/shoes/orange/attackby(H as obj, loc)
	if ((istype(H, /obj/item/weapon/handcuffs) && !( src.chained )))
		del(H)
		src.chained = 1
		src.icon_state = "o_shoes1"
	return

/obj/item/weapon/clothing/mask/muzzle/attack_paw(mob/user as mob)

	if (src == user.wear_mask)
		return
	else
		..()
	return


/obj/item/weapon/tank/blob_act()

	if(prob(25))
		var/turf/T = src.loc
		if (!( istype(T, /turf) ))
			return
		if(src.gas)
			src.gas.turf_add(T, -1.0)
		del(src)

/obj/item/weapon/tank/attack_self(mob/user as mob)

	user.machine = src
	if (!( src.gas ))
		return
	var/dat = text("<TT><B>Tank</B><BR>\n<FONT color = 'blue'><B>Contains/Capacity</B> [] / []</FONT><BR>\nInterals Valve: <A href='?src=\ref[];stat=1'>[] Gas Flow</A><BR>\n\t<A href='?src=\ref[];cp=-50'>-</A> <A href='?src=\ref[];cp=-5'>-</A> <A href='?src=\ref[];cp=-1'>-</A> [] <A href='?src=\ref[];cp=1'>+</A> <A href='?src=\ref[];cp=5'>+</A> <A href='?src=\ref[];cp=50'>+</A><BR>\n<BR>\n<A href='?src=\ref[];mach_close=tank'>Close</A>\n</TT>", src.gas.tot_gas(), src.maximum, src, ((src.loc == user && user.internal == src) ? "Stop" : "Restore"), src, src, src, src.i_used, src, src, src, user)
	user << browse(dat, "window=tank;size=600x300")
	return

/obj/item/weapon/tank/Topic(href, href_list)
	..()
	if (usr.stat|| usr.restrained())
		return
	if (src.loc == usr)
		usr.machine = src
		if (href_list["cp"])
			var/cp = text2num(href_list["cp"])
			src.i_used += cp
			src.i_used = min(max(round(src.i_used), 0), 10000)
		if ((href_list["stat"] && src.loc == usr))
			if (usr.internal == src)
				usr.internal = null
				src.updateEquippedDialog()
				return
			if (usr.internal)
				usr.internal = null
			if ((!( usr.wear_mask ) || !( usr.wear_mask.flags & 8 )))
				return
			usr.internal = src
			usr << "\blue Now running on internals!"
		src.add_fingerprint(usr)
		src.updateEquippedDialog()
	else
		usr << browse(null, "window=tank")
		return
	return

/obj/item/weapon/tank/proc/process(mob/M as mob, obj/substance/gas/G as obj)

	var/amount = src.i_used
	var/total = src.gas.tot_gas()
	if (amount > total)
		amount = total
	if (total > 0)
		G.transfer_from(src.gas, amount)
	return G
	return

/obj/item/weapon/tank/attack(mob/M as mob, mob/user as mob)
	
	..()
	if ((prob(30) && M.stat < 2))
		var/mob/human/H = M

// ******* Check

		if ((istype(H, /mob/human) && istype(H, /obj/item/weapon/clothing/head) && H.flags & 8 && prob(80)))
			M << "\red The helmet protects you from being hit hard in the head!"
			return
		var/time = rand(10, 120)
		if (prob(90))
			if (M.paralysis < time)
				M.paralysis = time
		else
			if (M.stunned < time)
				M.stunned = time
		M.stat = 1
		for(var/mob/O in viewers(M, null))
			if ((O.client && !( O.blinded )))
				O << text("\red <B>[] has been knocked unconscious!</B>", M)
			//Foreach goto(169)
		M << text("\red <B>This was a []% hit. Roleplay it! (personality/memory change if the hit was severe enough)</B>", time * 100 / 120)
	return

/obj/item/weapon/tank/New()

	..()
	src.gas = new /obj/substance/gas( src )
	src.gas.maximum = src.maximum
	return

/obj/item/weapon/tank/Del()

	//src.gas = null
	del(src.gas)
	..()
	return

/obj/item/weapon/tank/burn(fi_amount)

	if(src.gas)
		if ( (fi_amount * src.gas.tot_gas()) > (src.maximum * 3.75E7) )
			src.gas.turf_add(get_turf(src.loc), src.gas.tot_gas())
		//SN src = null
			del(src)
			return
	return

/obj/item/weapon/tank/examine()
	set src in view(1)

	if(src)
		usr << text("\blue The \icon[] contains [] unit\s of gas.", src, src.gas.tot_gas())
	return

/obj/item/weapon/tank/oxygentank/New()

	..()
	src.gas.oxygen = src.maximum
	return

/obj/item/weapon/tank/jetpack/New()

	..()
	src.gas.oxygen = src.maximum
	return

/obj/item/weapon/tank/jetpack/verb/toggle()

	src.on = !( src.on )
	src.icon_state = text("jetpack[]", src.on)
	return

/obj/item/weapon/tank/jetpack/proc/allow_thrust(num, mob/user as mob)

	if (!( src.on ))
		return 0
	if ((num < 1 || src.gas.tot_gas() < num))
		return 0
	var/obj/substance/gas/G = new /obj/substance/gas(  )
	G.transfer_from(src.gas, num)
	if (G.oxygen >= 100)
		return 1
	if (G.plasma > 10)
		if (user)
			var/d = G.plasma / 2
			d = min(abs(user.health + 100), d, 25)
			user.fireloss += d
			user.health = 100 - user.oxyloss - user.toxloss - user.fireloss - user.bruteloss
		return (G.oxygen >= 75 ? 0.5 : 0)
	else
		if (G.oxygen >= 75)
			return 0.5
		else
			return 0
	//G = null
	del(G)
	return

/obj/item/weapon/tank/anesthetic/New()

	..()
	src.gas.sl_gas = 700000
	src.gas.oxygen = 1000000
	return

/obj/item/weapon/tank/plasmatank/proc/release()
	var/turf/T = get_turf(src.loc)
	T.poison += src.gas.plasma * src.gas.temperature / 25.0
	T.oxygen += src.gas.oxygen * src.gas.temperature / 25.0
	T.n2 += src.gas.n2 * src.gas.temperature / 25.0
	T.sl_gas += src.gas.sl_gas * src.gas.temperature / 25.0
	T.co2 += src.gas.co2 * src.gas.temperature / 25.0
	T.res_vars()

	src.gas.plasma = 0
	src.gas.oxygen = 0
	src.gas.n2 = 0
	src.gas.sl_gas = 0
	src.gas.co2 = 0

	var/temp = src.gas.temperature
	spawn(10)
		T.firelevel = temp * 3600.0
		T.res_vars()



/obj/item/weapon/tank/plasmatank/proc/ignite()

	var/strength = ((src.gas.plasma + src.gas.oxygen/2.0) / 1600000.0) * src.gas.temperature
	//if ((src.gas.plasma < 1600000.0 || src.gas.temperature < 773))		//500degC
	if (strength < 773.0)
		var/turf/T = get_turf(src.loc)
		T.poison += src.gas.plasma
		T.firelevel = T.poison
		T.res_vars()

		if(src.master)
			src.master.loc = null

		//if ((src.gas.temperature > (450+T0C) && src.gas.plasma == 1600000.0))
		if (strength > (450+T0C))
			var/turf/sw = locate(max(T.x - 4, 1), max(T.y - 4, 1), T.z)
			var/turf/ne = locate(min(T.x + 4, world.maxx), min(T.y + 4, world.maxy), T.z)
			defer_powernet_rebuild = 1

			for(var/turf/U in block(sw, ne))
				var/zone = 4
				if ((U.y <= (T.y + 1) && U.y >= (T.y - 1) && U.x <= (T.x + 2) && U.x >= (T.x - 2)) )
					zone = 3
				if ((U.y <= (T.y + 1) && U.y >= (T.y - 1) && U.x <= (T.x + 1) && U.x >= (T.x - 1) ))
					zone = 2
				for(var/atom/A in U)
					A.ex_act(zone)
					//Foreach goto(342)
				U.ex_act(zone)
				U.buildlinks()
				//Foreach goto(170)
			defer_powernet_rebuild = 0
			makepowernets()

		else
			//if ((src.gas.temperature > (300+T0C) && src.gas.plasma == 1600000.0))
			if (strength > (300+T0C))
				var/turf/sw = locate(max(T.x - 4, 1), max(T.y - 4, 1), T.z)
				var/turf/ne = locate(min(T.x + 4, world.maxx), min(T.y + 4, world.maxy), T.z)
				defer_powernet_rebuild = 1

				for(var/turf/U in block(sw, ne))
					var/zone = 4
					if ((U.y <= (T.y + 2) && U.y >= (T.y - 2) && U.x <= (T.x + 2) && U.x >= (T.x - 2)) )
						zone = 3
					for(var/atom/A in U)
						A.ex_act(zone)
						//Foreach goto(598)
					U.ex_act(zone)
					U.buildlinks()
					//Foreach goto(498)
				defer_powernet_rebuild = 0
				makepowernets()

		//src.master = null
		del(src.master)
		//SN src = null
		del(src)
		return

	var/turf/T = src.loc
	while(!( istype(T, /turf) ))
		T = T.loc

	if(src.master)
		src.master.loc = null

	for(var/mob/M in range(T))
		flick("flash", M.flash)
		//Foreach goto(732)
	var/m_range = 2
	var/extended_range = round(strength / 387)
	if (extended_range < 2)
		extended_range = 2
	if (config.bombtemp_determines_range)
		m_range = extended_range
	for(var/obj/machinery/atmoalter/canister/C in range(2, T))
		if (!( C.destroyed ))
			if (C.gas.plasma >= 35000)
				C.destroyed = 1
				m_range++
		//Foreach goto(776)
	var/min = extended_range
	var/med = extended_range * 2
	var/max = extended_range * 3
	var/u_max = m_range * 4
	
	var/turf/sw = locate(max(T.x - u_max, 1), max(T.y - u_max, 1), T.z)
	var/turf/ne = locate(min(T.x + u_max, world.maxx), min(T.y + u_max, world.maxy), T.z)

	defer_powernet_rebuild = 1
	
	//If m_range is <= 12, then we are going to calculate the squared distance between tiles and ground zero. To avoid complicating comparisons in the for loop with additional if statements, we are going to square max, med, and min. You wouldn't be able to subtract tileRange (squared) from max, med, or min and get a useful distance, but this works fine for comparing the range to max, med, or min, without caring about how far between them it is. -Trafalgar
	
	if (m_range<=12)
		max *= max
		med *= med
		min *= min
		u_max *= u_max
	
	for(var/turf/U in block(sw, ne))
		var tileRange = 0
		var/zone = 4
		//If this if-else were outside the for loop, this would (assuming BYOND doesn't optimize this already) help improve performance more, but the only way I see to do that would be to have two copies of the for loop, one for m_range <= 12 and one for m_range > 12. -Trafalgar
		if (m_range<=12)
			tileRange = (U.y-T.y)*(U.y-T.y) + (U.x-T.x)*(U.x-T.x)
		else
			tileRange = max(abs(U.y-T.y), abs(U.x-T.x))
			

		if (tileRange <= u_max)
			//If this were, say, c++, then this would be faster than the commented out code (for one it isn't doing calculations 3 times over for no reason, for two it's an if-elseif-elseif instead of three ifs which all would get evaluated. It might be slightly faster if we did if (tileRange>max) first, then else if (tileRange > med), then else if (tileRange > min), then else (due to performance increases from having if/elseif/elses's ordered with the choices sorted from most likely at the top to least likely at the end, but who knows if this even applies to BYOND games since the performance benefit is the result of how the CPU processes comparisons and branching and such). -Trafalgar
			if (tileRange <= min)
				zone = 1
			else if (tileRange <= med)
				zone = 2
			else if (tileRange <= max)
				zone = 3
			/*if ((U.y <= (T.y + max) && U.y >= (T.y - max) && U.x <= (T.x + max) && U.x >= (T.x - max) ))
				zone = 3
			if ((U.y <= (T.y + med) && U.y >= (T.y - med) && U.x <= (T.x + med) && U.x >= (T.x - med) ))
				zone = 2
			if ((U.y <= (T.y + min) && U.y >= (T.y - min) && U.x <= (T.x + min) && U.x >= (T.x - min) ))
				zone = 1
			*/
			for(var/atom/A in U)
				A.ex_act(zone)
				//Foreach goto(1217)
			U.ex_act(zone)
			U.buildlinks()
		//U.mark(zone)

		//Foreach goto(961)
	//src.master = null
	defer_powernet_rebuild = 0
	makepowernets()

	del(src.master)
	//SN src = null
	del(src)

	return



/obj/item/weapon/tank/plasmatank/attackby(obj/item/weapon/W as obj, mob/user as mob)

	if (istype(W, /obj/item/weapon/assembly/rad_ignite))
		var/obj/item/weapon/assembly/rad_ignite/S = W
		if (!( S.status ))
			return
		var/obj/item/weapon/assembly/r_i_ptank/R = new /obj/item/weapon/assembly/r_i_ptank( user )
		R.part1 = S.part1
		S.part1.loc = R
		S.part1.master = R
		R.part2 = S.part2
		S.part2.loc = R
		S.part2.master = R
		S.layer = initial(S.layer)
		if (user.client)
			user.client.screen -= S
		if (user.r_hand == S)
			user.u_equip(S)
			user.r_hand = R
		else
			user.u_equip(S)
			user.l_hand = R
		src.master = R
		src.layer = initial(src.layer)
		user.u_equip(src)
		if (user.client)
			user.client.screen -= src
		src.loc = R
		R.part3 = src
		R.layer = 20
		R.loc = user
		S.part1 = null
		S.part2 = null
		//S = null
		del(S)
	if (istype(W, /obj/item/weapon/assembly/prox_ignite))
		var/obj/item/weapon/assembly/prox_ignite/S = W
		if (!( S.status ))
			return
		var/obj/item/weapon/assembly/m_i_ptank/R = new /obj/item/weapon/assembly/m_i_ptank( user )
		R.part1 = S.part1
		S.part1.loc = R
		S.part1.master = R
		R.part2 = S.part2
		S.part2.loc = R
		S.part2.master = R
		S.layer = initial(S.layer)
		if (user.client)
			user.client.screen -= S
		if (user.r_hand == S)
			user.u_equip(S)
			user.r_hand = R
		else
			user.u_equip(S)
			user.l_hand = R
		src.master = R
		src.layer = initial(src.layer)
		user.u_equip(src)
		if (user.client)
			user.client.screen -= src
		src.loc = R
		R.part3 = src
		R.layer = 20
		R.loc = user
		S.part1 = null
		S.part2 = null
		//S = null
		del(S)

	if (istype(W, /obj/item/weapon/assembly/time_ignite))
		var/obj/item/weapon/assembly/time_ignite/S = W
		if (!( S.status ))
			return
		var/obj/item/weapon/assembly/t_i_ptank/R = new /obj/item/weapon/assembly/t_i_ptank( user )
		R.part1 = S.part1
		S.part1.loc = R
		S.part1.master = R
		R.part2 = S.part2
		S.part2.loc = R
		S.part2.master = R
		S.layer = initial(S.layer)
		if (user.client)
			user.client.screen -= S
		if (user.r_hand == S)
			user.u_equip(S)
			user.r_hand = R
		else
			user.u_equip(S)
			user.l_hand = R
		src.master = R
		src.layer = initial(src.layer)
		user.u_equip(src)
		if (user.client)
			user.client.screen -= src
		src.loc = R
		R.part3 = src
		R.layer = 20
		R.loc = user
		S.part1 = null
		S.part2 = null
		//S = null
		del(S)
	return

/obj/item/weapon/tank/plasmatank/New()

	..()
	src.gas.plasma = src.maximum
	return

/obj/meteor/small/Move()

	if (src.steps < 7)
		src.steps++
		if (src.steps >= 7)
			src.icon_state = "smallf"
	else
		var/turf/T = src.loc
		if (istype(T, /turf))
			T.firelevel = T.poison + 5
	..()
	if (src.z != 1)
		//SN src = null
		del(src)
		return
	spawn( 3 )
		step(src, WEST)
		if (prob(30))
			step(src, pick(NORTH, SOUTH))
		return
	return

/obj/meteor/New()

	..()
	sleep(1)
	step(src, WEST)
	return

/obj/meteor/Move()

	if (src.steps < 7)
		src.steps++
		if (src.steps >= 7)
			src.icon_state = "flaming"
	else
		var/turf/T = src.loc
		if (istype(T, /turf))
			T.firelevel = T.poison + 5
	..()
	if (src.z != 1)
		//SN src = null
		del(src)
		return
	spawn( 3 )
		step(src, WEST)
		if (prob(30))
			step(src, pick(NORTH, SOUTH))
		return
	return

/obj/meteor/Bump(atom/A)

	spawn( 0 )
		if (A)
			A.meteorhit(src)




		if (--src.hits <= 0)
			//SN src = null
			//******RM
			if(prob(15) && !istype(A, /obj/grille))

				var/obj/item/weapon/tank/plasmatank/pt = new /obj/item/weapon/tank/plasmatank( src )
				pt.gas.temperature = 475+T0C
				pt.ignite()
			//*****
			del(src)
			return
		return
	return

/obj/meteor/ex_act(severity)

	if (severity < 4)
		//SN src = null
		del(src)
		return
	return

/obj/secloset/alter_health()

	return src.loc
	return

/obj/secloset/CheckPass(O as mob|obj, target as turf)

	if (!( src.opened ))
		return 0
	else
		return 1
	return

/obj/secloset/personal/New()

	..()
	sleep(2)
	new /obj/item/weapon/storage/backpack( src )
	new /obj/item/weapon/radio/headset( src )
	new /obj/item/weapon/radio/signaler( src )
	new /obj/item/weapon/pen( src )
	return

/obj/secloset/personal/attackby(obj/item/weapon/W as obj, mob/user as mob)

	if (src.opened)
		if (istype(W, /obj/item/weapon/grab))
			src.MouseDrop_T(W:affecting, user)	//act like they were dragged onto the closet
		else:
			user.drop_item()
			W.loc = src.loc
	else
		if (istype(W, /obj/item/weapon/card/id))
			var/obj/item/weapon/card/id/I = W
			if (I.check_access(null,"Systems"))
				src.allowed = null
				src.icon_state = "0secloset0"
				src.locked = 1
				src.desc = "The first card swiped gains control."
				return
			if (I.check_access(access,allowed))
				src.locked = !( src.locked )
				for(var/mob/O in viewers(user, 3))
					if ((O.client && !( O.blinded )))
						O << text("\blue The locker has been []locked by [].", (src.locked ? null : "un"), user)
					//Foreach goto(185)
				src.icon_state = text("[]secloset0", (src.locked ? "1" : null))
				if (!( src.allowed ))
					src.allowed = "Name:[I.registered]/Captain/Head of Personnel"
					src.desc = "Owned by [I.registered], Clear by using a card of rank 'Systems'"
			else
				user << "\red Access Denied"
		else
			user << "\red It's closed..."
	return

/obj/secloset/security2/New()

	..()
	sleep(2)
	new /obj/item/weapon/clothing/under/red( src )
	new /obj/item/weapon/storage/fcard_kit( src )
	new /obj/item/weapon/storage/fcard_kit( src )
	new /obj/item/weapon/storage/fcard_kit( src )
	new /obj/item/weapon/storage/lglo_kit( src )
	new /obj/item/weapon/storage/lglo_kit( src )
	new /obj/item/weapon/fcardholder( src )
	new /obj/item/weapon/fcardholder( src )
	new /obj/item/weapon/fcardholder( src )
	new /obj/item/weapon/fcardholder( src )
	new /obj/item/weapon/camera( src )
	new /obj/item/weapon/f_print_scanner( src )
	new /obj/item/weapon/f_print_scanner( src )
	new /obj/item/weapon/f_print_scanner( src )
	return

/obj/secloset/security1/New()

	..()
	sleep(2)
	new /obj/item/weapon/storage/flashbang_kit( src )
	new /obj/item/weapon/storage/handcuff_kit( src )
	new /obj/item/weapon/gun/energy/taser_gun( src )
	new /obj/item/weapon/flash( src )
	new /obj/item/weapon/clothing/under/red( src )
	new /obj/item/weapon/clothing/shoes/brown( src )
	new /obj/item/weapon/clothing/suit/armor( src )
	new /obj/item/weapon/clothing/head/helmet( src )
	new /obj/item/weapon/clothing/glasses/sunglasses( src )
	new /obj/item/weapon/baton( src)
	return

/obj/secloset/highsec/New()

	..()
	sleep(2)
	new /obj/item/weapon/gun/energy/laser_gun( src )
	new /obj/item/weapon/gun/energy/taser_gun( src )
	new /obj/item/weapon/flash( src )
	new /obj/item/weapon/storage/id_kit( src )
	new /obj/item/weapon/clothing/under/green( src )
	new /obj/item/weapon/clothing/shoes/brown( src )
	new /obj/item/weapon/clothing/glasses/sunglasses( src )
	new /obj/item/weapon/clothing/suit/armor( src )
	new /obj/item/weapon/clothing/head/helmet( src )
	return

/obj/secloset/captains/New()

	..()
	sleep(2)
	new /obj/item/weapon/gun/energy/laser_gun( src )
	new /obj/item/weapon/gun/energy/taser_gun( src )
	new /obj/item/weapon/storage/id_kit( src )
	new /obj/item/weapon/clothing/under/darkgreen( src )
	new /obj/item/weapon/clothing/shoes/brown( src )
	new /obj/item/weapon/clothing/glasses/sunglasses( src )
	new /obj/item/weapon/clothing/suit/armor( src )
	new /obj/item/weapon/clothing/head/swat_hel( src )
	return

/obj/secloset/animal/New()

	..()
	sleep(2)
	new /obj/item/weapon/radio/signaler( src )
	new /obj/item/weapon/radio/electropack( src )
	new /obj/item/weapon/radio/electropack( src )
	new /obj/item/weapon/radio/electropack( src )
	new /obj/item/weapon/radio/electropack( src )
	new /obj/item/weapon/radio/electropack( src )
	return

/obj/secloset/medical1/New()

	..()
	sleep(2)
	new /obj/item/weapon/bottle/toxins( src )
	new /obj/item/weapon/bottle/rejuvenators( src )
	new /obj/item/weapon/bottle/s_tox( src )
	new /obj/item/weapon/bottle/s_tox( src )
	new /obj/item/weapon/bottle/toxins( src )
	new /obj/item/weapon/bottle/r_epil( src )
	new /obj/item/weapon/bottle/r_ch_cough( src )
	new /obj/item/weapon/pill_canister/Tourette( src )
	new /obj/item/weapon/pill_canister/cough( src )
	new /obj/item/weapon/pill_canister/epilepsy( src )
	new /obj/item/weapon/pill_canister/sleep( src )
	new /obj/item/weapon/pill_canister/antitoxin( src )
	new /obj/item/weapon/pill_canister/placebo( src )
	new /obj/item/weapon/storage/firstaid/syringes( src )
	new /obj/item/weapon/storage/gl_kit( src )
	new /obj/item/weapon/dropper( src )
	return

/obj/secloset/medical2/New()

	..()
	sleep(2)
	new /obj/item/weapon/tank/anesthetic( src )
	new /obj/item/weapon/tank/anesthetic( src )
	new /obj/item/weapon/tank/anesthetic( src )
	new /obj/item/weapon/tank/anesthetic( src )
	new /obj/item/weapon/tank/anesthetic( src )
	new /obj/item/weapon/clothing/mask/m_mask( src )
	new /obj/item/weapon/clothing/mask/m_mask( src )
	new /obj/item/weapon/clothing/mask/m_mask( src )
	new /obj/item/weapon/clothing/mask/m_mask( src )
	return

/obj/secloset/ex_act(severity)

	switch(severity)
		if(1.0)
			for(var/atom/movable/A as mob|obj in src)
				A.loc = src.loc
				ex_act(severity)
				//Foreach goto(35)
			//SN src = null
			del(src)
			return
		if(2.0)
			if (prob(50))
				for(var/atom/movable/A as mob|obj in src)
					A.loc = src.loc
					ex_act(severity)
					//Foreach goto(108)
				//SN src = null
				del(src)
				return
		if(3.0)
			if (prob(5))
				for(var/atom/movable/A as mob|obj in src)
					A.loc = src.loc
					ex_act(severity)
					//Foreach goto(181)
				//SN src = null
				del(src)
				return
		else
	return

/obj/secloset/blob_act()

	if (prob(50))
		for(var/atom/movable/A as mob|obj in src)
			A.loc = src.loc
		del(src)


/obj/secloset/meteorhit(obj/O as obj)

	if (O.icon_state == "flaming")
		for(var/obj/item/I in src)
			I.loc = src.loc
			//Foreach goto(29)
		for(var/mob/M in src)
			M.loc = src.loc
			if (M.client)
				M.client.eye = M.client.mob
				M.client.perspective = MOB_PERSPECTIVE
			//Foreach goto(71)
		src.icon_state = "secloset1"
		//SN src = null
		del(src)
		return
	return

/obj/secloset/attackby(obj/item/weapon/W as obj, mob/user as mob)

	if (src.opened)
		if (istype(W, /obj/item/weapon/grab))
			src.MouseDrop_T(W:affecting, user)	//act like they were dragged onto the closet
		else:
			user.drop_item()
			W.loc = src.loc
	else
		if (istype(W, /obj/item/weapon/card/id))
			var/obj/item/weapon/card/id/I = W

			if(I.check_access(access,allowed))
				src.locked = !( src.locked )
				for(var/mob/O in viewers(user, 3))
					if ((O.client && !( O.blinded )))
						O << text("\blue The locker has been []locked by [].", (src.locked ? null : "un"), user)
					//Foreach goto(121)
				src.icon_state = text("[]secloset0", (src.locked ? "1" : null))
			else
				user << "\red Access Denied"
		else
			user << "\red It's closed..."
	return

/obj/secloset/relaymove(mob/user as mob)

	if (user.stat)
		return
	if (!( src.locked ))
		for(var/obj/item/I in src)
			I.loc = src.loc
			//Foreach goto(36)
		for(var/mob/M in src)
			M.loc = src.loc
			if (M.client)
				M.client.eye = M.client.mob
				M.client.perspective = MOB_PERSPECTIVE
			//Foreach goto(78)
		src.icon_state = "secloset1"
		src.opened = 1
	else
		user << "\blue It's welded shut!"
		for(var/mob/M in hearers(src, null))
			M << text("<FONT size=[]>BANG, bang!</FONT>", max(0, 5 - get_dist(src, M)))
			//Foreach goto(170)
	return

/obj/secloset/MouseDrop_T(atom/movable/O as mob|obj, mob/user as mob)

	if ((user.restrained() || user.stat))
		return
	if ((!( istype(O, /atom/movable) ) || O.anchored || get_dist(user, src) > 1 || get_dist(user, O) > 1 || user.contents.Find(src)))
		return
	step_towards(O, src.loc)
	if (user != O)
		for(var/mob/B in viewers(user, 3))
			if ((B.client && !( B.blinded )))
				B << text("\red [] stuffs [] into []!", user, O, src)
			//Foreach goto(115)
	src.add_fingerprint(user)
	return

/obj/secloset/attack_paw(mob/user as mob)

	return src.attack_hand(user)
	return

/obj/secloset/attack_hand(mob/user as mob)

	src.add_fingerprint(user)
	if (!( src.opened ))
		if (!( src.locked ))
			for(var/obj/item/I in src)
				I.loc = src.loc
				//Foreach goto(43)
			for(var/mob/M in src)
				M.loc = src.loc
				if (M.client)
					M.client.eye = M.client.mob
					M.client.perspective = MOB_PERSPECTIVE
				//Foreach goto(85)
			src.icon_state = "secloset1"
			src.opened = 1
		else
			usr << "\blue It's locked tight!"
	else
		for(var/obj/item/I in src.loc)
			if (!( I.anchored ))
				I.loc = src
			//Foreach goto(176)
		for(var/mob/M in src.loc)
			if (M.client)
				M.client.perspective = EYE_PERSPECTIVE
				M.client.eye = src
			M.loc = src
			//Foreach goto(226)
		src.icon_state = "secloset0"
		src.opened = 0
	return

/obj/morgue/proc/update()

	if (src.connected)
		src.icon_state = "morgue0"
	else
		if (src.contents.len)
			src.icon_state = "morgue2"
		else
			src.icon_state = "morgue1"
	return

/obj/morgue/alter_health()

	return src.loc
	return

/obj/morgue/attack_paw(mob/user as mob)

	return src.attack_hand(user)
	return

/obj/morgue/attack_hand(mob/user as mob)

	if (src.connected)
		for(var/atom/movable/A as mob|obj in src.connected.loc)
			if (!( A.anchored ))
				A.loc = src
			//Foreach goto(28)
		//src.connected = null
		del(src.connected)
	else
		src.connected = new /obj/m_tray( src.loc )
		step(src.connected, EAST)
		src.connected.layer = OBJ_LAYER
		var/turf/T = get_step(src, EAST)
		if (T.contents.Find(src.connected))
			src.connected.connected = src
			src.icon_state = "morgue0"
			for(var/atom/movable/A as mob|obj in src)
				A.loc = src.connected.loc
				//Foreach goto(168)
			src.connected.icon_state = "morguet"
		else
			//src.connected = null
			del(src.connected)
	src.add_fingerprint(user)
	update()
	return

/obj/morgue/attackby(P as obj, mob/user as mob)

	if (istype(P, /obj/item/weapon/pen))
		var/t = input(user, "What would you like the label to be?", text("[]", src.name), null)  as text
		if (user.equipped() != P)
			return
		if ((get_dist(src, usr) > 1 && src.loc != user))
			return
		t = html_encode(t)
		if (t)
			src.name = text("Morgue- '[]'", t)
		else
			src.name = "Morgue"
	src.add_fingerprint(user)
	return

/obj/morgue/relaymove(mob/user as mob)

	if (user.stat)
		return
	src.connected = new /obj/m_tray( src.loc )
	step(src.connected, EAST)
	src.connected.layer = OBJ_LAYER
	var/turf/T = get_step(src, EAST)
	if (T.contents.Find(src.connected))
		src.connected.connected = src
		src.icon_state = "morgue0"
		for(var/atom/movable/A as mob|obj in src)
			A.loc = src.connected.loc
			//Foreach goto(106)
		src.connected.icon_state = "morguet"
	else
		//src.connected = null
		del(src.connected)
	return

/obj/m_tray/CheckPass(D as obj)

	if (istype(D, /obj/item/weapon/dummy))
		return 1
	else
		return ..()
	return

/obj/m_tray/attack_paw(mob/user as mob)

	return src.attack_hand(user)
	return

/obj/m_tray/attack_hand(mob/user as mob)

	if (src.connected)
		for(var/atom/movable/A as mob|obj in src.loc)
			if (!( A.anchored ))
				A.loc = src.connected
			//Foreach goto(26)
		src.connected.connected = null
		src.connected.update()
		add_fingerprint(user)
		//SN src = null
		del(src)
		return
	return

/obj/m_tray/MouseDrop_T(atom/movable/O as mob|obj, mob/user as mob)

	if ((!( istype(O, /atom/movable) ) || O.anchored || get_dist(user, src) > 1 || get_dist(user, O) > 1 || user.contents.Find(src)))
		return
	O.loc = src.loc
	if (user != O)
		for(var/mob/B in viewers(user, 3))
			if ((B.client && !( B.blinded )))
				B << text("\red [] stuffs [] into []!", user, O, src)
			//Foreach goto(99)
	return

/obj/closet/alter_health()

	return src.loc
	return

/obj/closet/CheckPass(O as mob|obj, target as turf)

	if (!( src.opened ))
		return 0
	else
		return 1
	return

/obj/closet/syndicate/nuclear/New()

	..()
	sleep(2)
	new /obj/item/weapon/ammo/a357( src )
	new /obj/item/weapon/ammo/a357( src )
	new /obj/item/weapon/ammo/a357( src )
	new /obj/item/weapon/storage/handcuff_kit( src )
	new /obj/item/weapon/storage/flashbang_kit( src )
	new /obj/item/weapon/gun/energy/taser_gun( src )
	new /obj/item/weapon/gun/energy/taser_gun( src )
	new /obj/item/weapon/gun/energy/taser_gun( src )
	var/obj/item/weapon/syndicate_uplink/U = new /obj/item/weapon/syndicate_uplink( src )
	U.uses = 5
	return
	
/obj/closet/syndicate/personal/New()

	..()
	sleep(2)
	new /obj/item/weapon/tank/jetpack(src)
	new /obj/item/weapon/clothing/mask/m_mask(src)
	new /obj/item/weapon/clothing/head/s_helmet(src)
	new /obj/item/weapon/clothing/suit/sp_suit(src)
	new /obj/item/weapon/crowbar(src)
	new /obj/item/weapon/cell(src)
	new /obj/item/weapon/card/id/syndicate(src)
	new /obj/item/weapon/multitool(src)

/obj/closet/emcloset/New()

	..()
	sleep(2)
	new /obj/item/weapon/tank/oxygentank( src )
	new /obj/item/weapon/clothing/mask/gasmask( src )
	return

/obj/closet/l3closet/New()

	..()
	sleep(2)
	new /obj/item/weapon/tank/oxygentank( src )
	new /obj/item/weapon/clothing/mask/gasmask( src )
	new /obj/item/weapon/clothing/suit/bio_suit( src )
	new /obj/item/weapon/clothing/under/white( src )
	new /obj/item/weapon/clothing/shoes/white( src )
	new /obj/item/weapon/clothing/gloves/latex( src )
	new /obj/item/weapon/clothing/head/bio_hood( src )
	new /obj/item/weapon/clothing/suit/labcoat(src)

	return

/obj/closet/wardrobe/New()

	new /obj/item/weapon/clothing/under/blue( src )
	new /obj/item/weapon/clothing/under/blue( src )
	new /obj/item/weapon/clothing/under/blue( src )
	new /obj/item/weapon/clothing/under/blue( src )
	new /obj/item/weapon/clothing/under/blue( src )
	new /obj/item/weapon/clothing/under/blue( src )
	new /obj/item/weapon/clothing/shoes/brown( src )
	new /obj/item/weapon/clothing/shoes/brown( src )
	new /obj/item/weapon/clothing/shoes/brown( src )
	new /obj/item/weapon/clothing/shoes/brown( src )
	new /obj/item/weapon/clothing/shoes/brown( src )
	new /obj/item/weapon/clothing/shoes/brown( src )
	return

/obj/closet/wardrobe/red/New()

	new /obj/item/weapon/clothing/under/red( src )
	new /obj/item/weapon/clothing/under/red( src )
	new /obj/item/weapon/clothing/under/red( src )
	new /obj/item/weapon/clothing/under/red( src )
	new /obj/item/weapon/clothing/under/red( src )
	new /obj/item/weapon/clothing/under/red( src )
	new /obj/item/weapon/clothing/shoes/brown( src )
	new /obj/item/weapon/clothing/shoes/brown( src )
	new /obj/item/weapon/clothing/shoes/brown( src )
	new /obj/item/weapon/clothing/shoes/brown( src )
	new /obj/item/weapon/clothing/shoes/brown( src )
	new /obj/item/weapon/clothing/shoes/brown( src )
	return

/obj/closet/wardrobe/pink/New()

	new /obj/item/weapon/clothing/under/pink( src )
	new /obj/item/weapon/clothing/under/pink( src )
	new /obj/item/weapon/clothing/under/pink( src )
	new /obj/item/weapon/clothing/under/pink( src )
	new /obj/item/weapon/clothing/under/pink( src )
	new /obj/item/weapon/clothing/under/pink( src )
	new /obj/item/weapon/clothing/shoes/brown( src )
	new /obj/item/weapon/clothing/shoes/brown( src )
	new /obj/item/weapon/clothing/shoes/brown( src )
	new /obj/item/weapon/clothing/shoes/brown( src )
	new /obj/item/weapon/clothing/shoes/brown( src )
	new /obj/item/weapon/clothing/shoes/brown( src )
	return

/obj/closet/wardrobe/black/New()

	new /obj/item/weapon/clothing/under/black( src )
	new /obj/item/weapon/clothing/under/black( src )
	new /obj/item/weapon/clothing/under/black( src )
	new /obj/item/weapon/clothing/under/black( src )
	new /obj/item/weapon/clothing/under/black( src )
	new /obj/item/weapon/clothing/under/black( src )
	new /obj/item/weapon/clothing/shoes/black( src )
	new /obj/item/weapon/clothing/shoes/black( src )
	new /obj/item/weapon/clothing/shoes/black( src )
	new /obj/item/weapon/clothing/shoes/black( src )
	new /obj/item/weapon/clothing/shoes/black( src )
	new /obj/item/weapon/clothing/shoes/black( src )
	return

/obj/closet/wardrobe/green/New()

	new /obj/item/weapon/clothing/under/green( src )
	new /obj/item/weapon/clothing/under/green( src )
	new /obj/item/weapon/clothing/under/green( src )
	new /obj/item/weapon/clothing/under/green( src )
	new /obj/item/weapon/clothing/under/green( src )
	new /obj/item/weapon/clothing/under/green( src )
	new /obj/item/weapon/clothing/shoes/black( src )
	new /obj/item/weapon/clothing/shoes/black( src )
	new /obj/item/weapon/clothing/shoes/black( src )
	new /obj/item/weapon/clothing/shoes/black( src )
	new /obj/item/weapon/clothing/shoes/black( src )
	new /obj/item/weapon/clothing/shoes/black( src )
	return

/obj/closet/wardrobe/orange/New()

	new /obj/item/weapon/clothing/under/orange( src )
	new /obj/item/weapon/clothing/under/orange( src )
	new /obj/item/weapon/clothing/under/orange( src )
	new /obj/item/weapon/clothing/under/orange( src )
	new /obj/item/weapon/clothing/under/orange( src )
	new /obj/item/weapon/clothing/under/orange( src )
	new /obj/item/weapon/clothing/shoes/orange( src )
	new /obj/item/weapon/clothing/shoes/orange( src )
	new /obj/item/weapon/clothing/shoes/orange( src )
	new /obj/item/weapon/clothing/shoes/orange( src )
	new /obj/item/weapon/clothing/shoes/orange( src )
	new /obj/item/weapon/clothing/shoes/orange( src )
	return

/obj/closet/wardrobe/yellow/New()

	new /obj/item/weapon/clothing/under/yellow( src )
	new /obj/item/weapon/clothing/under/yellow( src )
	new /obj/item/weapon/clothing/under/yellow( src )
	new /obj/item/weapon/clothing/under/yellow( src )
	new /obj/item/weapon/clothing/under/yellow( src )
	new /obj/item/weapon/clothing/under/yellow( src )
	new /obj/item/weapon/clothing/shoes/orange( src )
	new /obj/item/weapon/clothing/shoes/orange( src )
	new /obj/item/weapon/clothing/shoes/orange( src )
	new /obj/item/weapon/clothing/shoes/orange( src )
	new /obj/item/weapon/clothing/shoes/orange( src )
	new /obj/item/weapon/clothing/shoes/orange( src )
	return

/obj/closet/wardrobe/mixed/New()

	new /obj/item/weapon/clothing/under/blue( src )
	new /obj/item/weapon/clothing/under/blue( src )
	new /obj/item/weapon/clothing/under/blue( src )
	new /obj/item/weapon/clothing/under/pink( src )
	new /obj/item/weapon/clothing/under/pink( src )
	new /obj/item/weapon/clothing/under/pink( src )
	new /obj/item/weapon/clothing/shoes/brown( src )
	new /obj/item/weapon/clothing/shoes/brown( src )
	new /obj/item/weapon/clothing/shoes/brown( src )
	new /obj/item/weapon/clothing/shoes/brown( src )
	new /obj/item/weapon/clothing/shoes/brown( src )
	new /obj/item/weapon/clothing/shoes/brown( src )
	return

/obj/closet/wardrobe/white/New()

	new /obj/item/weapon/clothing/under/white( src )
	new /obj/item/weapon/clothing/under/white( src )
	new /obj/item/weapon/clothing/under/white( src )
	new /obj/item/weapon/clothing/under/white( src )
	new /obj/item/weapon/clothing/under/white( src )
	new /obj/item/weapon/clothing/shoes/white( src )
	new /obj/item/weapon/clothing/shoes/white( src )
	new /obj/item/weapon/clothing/shoes/white( src )
	new /obj/item/weapon/clothing/shoes/white( src )
	new /obj/item/weapon/clothing/shoes/white( src )
	new /obj/item/weapon/storage/lglo_kit( src )
	new /obj/item/weapon/storage/stma_kit( src )
	new /obj/item/weapon/clothing/suit/labcoat(src)
	new /obj/item/weapon/clothing/suit/labcoat(src)
	new /obj/item/weapon/clothing/suit/labcoat(src)
	return

/obj/closet/ex_act(severity)

	switch(severity)
		if(1.0)
			for(var/atom/movable/A as mob|obj in src)
				A.loc = src.loc
				ex_act(severity)
				//Foreach goto(35)
			//SN src = null
			del(src)
			return
		if(2.0)
			if (prob(50))
				for(var/atom/movable/A as mob|obj in src)
					A.loc = src.loc
					ex_act(severity)
					//Foreach goto(108)
				//SN src = null
				del(src)
				return
		if(3.0)
			if (prob(5))
				for(var/atom/movable/A as mob|obj in src)
					A.loc = src.loc
					ex_act(severity)
					//Foreach goto(181)
				//SN src = null
				del(src)
				return
		else
	return


/obj/secloset/blob_act()

	if (prob(50))
		for(var/atom/movable/A as mob|obj in src)
			A.loc = src.loc
		del(src)

/obj/closet/meteorhit(obj/O as obj)

	if (O.icon_state == "flaming")
		for(var/obj/item/I in src)
			I.loc = src.loc
			//Foreach goto(29)
		for(var/mob/M in src)
			M.loc = src.loc
			if (M.client)
				M.client.eye = M.client.mob
				M.client.perspective = MOB_PERSPECTIVE
			//Foreach goto(71)
		src.icon_state = "emcloset1"
		//SN src = null
		del(src)
		return
	return

/obj/closet/attackby(obj/item/weapon/W as obj, mob/user as mob)
	if ((src.opened || W.damtype != "fire" || !( istype(W, /obj/item/weapon/weldingtool) )))
		if (istype(W, /obj/item/weapon/grab))
			src.MouseDrop_T(W:affecting, user)	//act like they were dragged onto the closet
		else:
			user.drop_item()
			W.loc = src.loc
	else
		src.welded = !( src.welded )
		for(var/mob/M in viewers(user, null))
			if (M.client)
				M.show_message(text("\red [] has been [] by [].", src, (src.welded ? "welded shut" : "unwelded"), user), 3, "\red You hear welding.", 2)
			//Foreach goto(82)
	return

/obj/closet/relaymove(mob/user as mob)

	if (user.stat)
		return
	if (!( src.welded ))
		for(var/obj/item/I in src)
			I.loc = src.loc
			//Foreach goto(36)
		for(var/mob/M in src)
			M.loc = src.loc
			if (M.client)
				M.client.eye = M.client.mob
				M.client.perspective = MOB_PERSPECTIVE
			//Foreach goto(78)
		src.icon_state = "emcloset1"
		src.opened = 1
	else
		user << "\blue It's welded shut!"
		for(var/mob/M in hearers(src, null))
			M << text("<FONT size=[]>BANG, bang!</FONT>", max(0, 5 - get_dist(src, M)))
			//Foreach goto(170)
	return

/obj/closet/MouseDrop_T(atom/movable/O as mob|obj, mob/user as mob)

	if ((user.restrained() || user.stat))
		return
	if ((!( istype(O, /atom/movable) ) || O.anchored || get_dist(user, src) > 1 || get_dist(user, O) > 1 || user.contents.Find(src)))
		return
	/*
	 * Patch Submitted by shadowlord13, to fix Bug #1936685.
	 */
	if (user.loc==null) // just in case someone manages to get a closet into the blue light dimension, as unlikely as that seems
		return
	if (!istype(user.loc, /turf)) // are you in a container/closet/pod/etc?
		return
	/*
	 * End Patch by shadowlord13
	 */
	step_towards(O, src.loc)
	for(var/mob/M in viewers(user, null))
		if ((M.client && !( M.blinded )))
			M << text("\red [] stuffs [] into []!", user, O, src)
		//Foreach goto(104)
	src.add_fingerprint(user)
	return

/obj/closet/attack_paw(mob/user as mob)

	return src.attack_hand(user)
	return

/obj/closet/attack_hand(mob/user as mob)

	src.add_fingerprint(user)
	if (!( src.opened ))
		if (!( src.welded ))
			for(var/obj/item/I in src)
				I.loc = src.loc
				//Foreach goto(43)
			for(var/mob/M in src)
				if (!( M.buckled ))
					M.loc = src.loc
					if (M.client)
						M.client.eye = M.client.mob
						M.client.perspective = MOB_PERSPECTIVE
				//Foreach goto(85)
			src.icon_state = "emcloset1"
			src.opened = 1
		else
			usr << "\blue It's welded shut!"
	else
		for(var/obj/item/I in src.loc)
			if (!( I.anchored ))
				I.loc = src
			//Foreach goto(187)
		for(var/mob/M in src.loc)
			if (M.client)
				M.client.perspective = EYE_PERSPECTIVE
				M.client.eye = src
			M.loc = src
			//Foreach goto(237)
		src.icon_state = src.original
		src.opened = 0
	return

/obj/closet/CheckPass(O as mob|obj, target as turf)

	if (!( src.opened ))
		return 0
	else
		return 1
	return

/obj/stool/ex_act(severity)

	switch(severity)
		if(1.0)
			//SN src = null
			del(src)
			return
		if(2.0)
			if (prob(50))
				//SN src = null
				del(src)
				return
		if(3.0)
			if (prob(5))
				//SN src = null
				del(src)
				return
		else
	return

/obj/stool/blob_act()

	if(prob(50))
		new /obj/item/weapon/sheet/metal( src.loc )
		del(src)

/obj/stool/attackby(obj/item/weapon/W as obj, mob/user as mob)

	if (istype(W, /obj/item/weapon/wrench))
		new /obj/item/weapon/sheet/metal( src.loc )
		//SN src = null
		del(src)

	return

/obj/stool/bed/attackby(obj/item/weapon/W as obj, mob/user as mob)

	return

/obj/stool/chair/attackby(obj/item/weapon/W as obj, mob/user as mob)

	..()
	if (istype(W, /obj/item/weapon/assembly/shock_kit))
		var/obj/stool/chair/e_chair/E = new /obj/stool/chair/e_chair( src.loc )
		E.dir = src.dir
		E.part1 = W
		W.loc = E
		W.master = E
		user.u_equip(W)
		W.layer = initial(W.layer)
		//SN src = null
		del(src)
		return
	return

/obj/stool/chair/e_chair/New()

	src.overl = new /atom/movable/overlay( src.loc )
	src.overl.icon = 'Icons.dmi'
	src.overl.icon_state = "e_chairo0"
	src.overl.layer = 5
	src.overl.name = "electrified chair"
	src.overl.master = src
	return

/obj/stool/chair/e_chair/Del()

	//src.overl = null
	del(src.overl)
	..()
	return

/obj/stool/chair/e_chair/attackby(obj/item/weapon/W as obj, mob/user as mob)

	if (istype(W, /obj/item/weapon/wrench))
		var/obj/stool/chair/C = new /obj/stool/chair( src.loc )
		C.dir = src.dir
		src.part1.loc = src.loc
		src.part1.master = null
		src.part1 = null
		//SN src = null
		del(src)
		return
	return

/obj/stool/chair/e_chair/verb/toggle_power()
	set src in oview(1)

	if ((usr.stat || usr.restrained() || !( usr.canmove ) || usr.lying))
		return
	src.on = !( src.on )
	src.icon_state = text("e_chair[]", src.on)
	src.overl.icon_state = text("e_chairo[]", src.on)
	return

/obj/stool/chair/e_chair/proc/shock()

	//*****
	//world << "EC: got shock, status is [on]"



	if (!( src.on ))
		return
	if ( (src.last_time + 50) > world.time)
		return
	src.last_time = world.time

	// special power handling
	var/area/A = src.loc.loc
	if(!isarea(A))
		return
	if(!A.powered(EQUIP))
		return
	A.use_power(EQUIP, 5000)
	var/light = A.power_light
	A.updateicon()


	flick("e_chairs", src)
	flick("e_chairos", src.overl)
	for(var/mob/M in src.loc)
		M.burn(7.5E7)
		M << "\red <B>You feel a deep shock course through your body!</B>"
		sleep(1)
		M.burn(7.5E7)
		M.stunned = 600
		//Foreach goto(72)
	for(var/mob/M in hearers(src, null))
		if (!( M.blinded ))
			M << "\red The electric chair went off!"
		else
			M << "\red You hear a deep sharp shock."
		//Foreach goto(142)

	A.power_light = light
	A.updateicon()

	return

/obj/stool/chair/ex_act(severity)

	if (severity < 4)
		for(var/mob/M in src.loc)
			M.buckled = null
			//Foreach goto(28)
	switch(severity)
		if(1.0)
			//SN src = null
			del(src)
			return
		if(2.0)
			if (prob(50))
				//SN src = null
				del(src)
				return
		if(3.0)
			if (prob(5))
				//SN src = null
				del(src)
				return
		else
	return

/obj/stool/chair/blob_act()

	if (prob(50))
		for(var/mob/M in src.loc)
			M.buckled = null
			//Foreach goto(28)
	if(prob(50))
		del(src)

/obj/stool/chair/New()

	src.verbs -= /atom/movable/verb/pull
	if (src.dir == NORTH)
		src.layer = FLY_LAYER
	..()
	return

/obj/stool/chair/Del()

	for(var/mob/M in src.loc)
		if (M.buckled == src)
			M.buckled = null
		//Foreach goto(17)
	..()
	return

/obj/stool/chair/verb/rotate()
	set src in oview(1)

	src.dir = turn(src.dir, 90)
	if (src.dir == NORTH)
		src.layer = FLY_LAYER
	else
		src.layer = OBJ_LAYER
	return

/obj/stool/chair/MouseDrop_T(mob/M as mob, mob/user as mob)
	if (!ticker)
		user << "You can't buckle anyone in before the game starts."
		return
	if ((!( istype(M, /mob) ) || get_dist(src, user) > 1 || M.loc != src.loc || user.restrained() || usr.stat))
		return
	if (M == usr)
		for(var/mob/O in viewers(user, null))
			if ((O.client && !( O.blinded )))
				O << text("\blue [] buckles in!", user)
			//Foreach goto(83)
	else
		for(var/mob/O in viewers(user, null))
			if ((O.client && !( O.blinded )))
				O << text("\blue [] is buckled in by []!", M, user)
			//Foreach goto(137)
	M.anchored = 1
	M.buckled = src
	M.loc = src.loc
	src.add_fingerprint(user)
	return

/obj/stool/chair/attack_paw(mob/user as mob)

	if ((ticker && ticker.mode == "monkey"))
		return src.attack_hand(user)
	return

/obj/stool/chair/attack_hand(mob/user as mob)

	for(var/mob/M in src.loc)
		if (M.buckled)
			if (M != user)
				for(var/mob/O in viewers(user, null))
					if ((O.client && !( O.blinded )))
						O << text("\blue [] is unbuckled by [].", M, user)
					//Foreach goto(64)
			else
				for(var/mob/O in viewers(user, null))
					if ((O.client && !( O.blinded )))
						O << text("\blue [] unbuckles.", M)
					//Foreach goto(123)
			M.anchored = 0
			M.buckled = null
			src.add_fingerprint(user)
		//Foreach goto(17)
	return


/obj/grille/New()
	..()

//returns the netnum of a stub cable at this grille loc, or 0 if none

/obj/grille/proc/get_connection()

	var/turf/T = src.loc
	if(!istype(T, /turf/station/floor))
		return

	for(var/obj/cable/C in T)
		if(C.d1 == 0)
			return C.netnum

	return 0

/obj/grille/ex_act(severity)

	switch(severity)
		if(1.0)
			//SN src = null
			del(src)
			return
		if(2.0)
			if (prob(50))
				//SN src = null
				del(src)
				return
		if(3.0)
			if (prob(25))
				src.health -= 11
				healthcheck()
		else
	return

/obj/grille/blob_act()
	src.health--
	src.healthcheck()


/obj/grille/meteorhit(var/obj/M)

	if (M.icon_state == "flaming")
		src.health -= 2
		healthcheck()
	return

/obj/grille/CheckPass(var/obj/B)

	if ((istype(B, /obj/effects) || istype(B, /obj/item/weapon/dummy) || istype(B, /obj/beam) || istype(B, /obj/meteor/small)))
		return 1
	else
		if (istype(B, /obj/bullet))
			return prob(30)
		else
			return !( src.density )
	return

/obj/grille/attackby(obj/item/weapon/W, mob/user)

	if (istype(W, /obj/item/weapon/wirecutters))
		if(!shock(user, 100))
			src.health = 0
	else if ((istype(W, /obj/item/weapon/screwdriver) && (istype(src.loc, /turf/station) || src.anchored)))
		if(!shock(user, 50))
			src.anchored = !( src.anchored )
			user << (src.anchored ? "You have fastened the grille to the floor." : "You have unfastened the grill.")
	else if(istype(W, /obj/item/weapon/shard))	// can't get a shock by attacking with glass shard

		src.health -= W.force * 0.1

	else						// anything else, chance of a shock
		if(!shock(user, 70))
			switch(W.damtype)
				if("fire")
					src.health -= W.force
				if("brute")
					src.health -= W.force * 0.1


	src.healthcheck()
	..()
	return

/obj/grille/proc/healthcheck()

	if (src.health <= 0)
		if (!( src.destroyed ))
			src.icon_state = "brokengrille"
			src.density = 0
			src.destroyed = 1
			new /obj/item/weapon/rods( src.loc )

		else
			if (src.health <= -10.0)
				new /obj/item/weapon/rods( src.loc )
				//SN src = null
				del(src)
				return
	return

// shock user with probability prb (if all connections & power are working)
// returns 1 if shocked, 0 otherwise

/obj/grille/proc/shock(mob/user, prb)

	if(!anchored || destroyed)		// anchored/destroyed grilles are never connected
		return 0

	if(!prob(prb))
		return 0

	var/net = get_connection()		// find the powernet of the connected cable


	if(!net)		// cable is unpowered
		return 0

	return src.electrocute(user, prb, net)

/obj/window/las_act(flag)

	if (flag == "bullet")

		if(!reinf)
			new /obj/item/weapon/shard( src.loc )
			//SN src = null
			src.density = 0
			src.loc.buildlinks()

			del(src)
		else
			health -= 35
			if(health <=0)
				new /obj/item/weapon/shard( src.loc )
				new /obj/item/weapon/rods( src.loc )
				src.density = 0
				src.loc.buildlinks()
				del(src)

		return
	return

/obj/window/ex_act(severity)

	switch(severity)
		if(1.0)
			//SN src = null
			del(src)
			return
		if(2.0)
			new /obj/item/weapon/shard( src.loc )
			if(reinf) new /obj/item/weapon/rods( src.loc)
			//SN src = null
			del(src)
			return
		if(3.0)
			if (prob(50))
				new /obj/item/weapon/shard( src.loc )
				if(reinf) new /obj/item/weapon/rods( src.loc)

				//SN src = null
				del(src)
				return
		else
	return

/obj/window/blob_act()
	if(prob(50))
		new /obj/item/weapon/shard( src.loc )
		if(reinf) new /obj/item/weapon/rods( src.loc)
		density = 0
		src.loc.buildlinks()
		del(src)

/obj/window/CheckPass(atom/movable/O, target as turf)
	if (istype(O, /obj/beam))
		return 1
	/* Does SOUTHWEST do something hacky for windows, like defines a full 1 square window? --Stephen001 */
	if (src.dir == SOUTHWEST)
		return 0
	else if (get_dir(target, O.loc) == src.dir)
		return 0
	return 1

/obj/window/CheckExit(atom/movable/O, target as turf)
	if (istype(O, /obj/beam))
		return 1
	if (get_dir(O.loc, target) == src.dir)
		return 0
	return 1

/obj/window/meteorhit()
	src.health = 0
	new /obj/item/weapon/shard( src.loc )
	if(reinf) new /obj/item/weapon/rods( src.loc)
	src.density = 0
	src.loc.buildlinks()
	del(src)
	return


/obj/window/hitby(obj/item/weapon/W as obj)

	..()
	var/tforce = W.throwforce
	if(reinf) tforce /= 4.0

	src.health = max(0, src.health - tforce)
	if (src.health <= 7 && !reinf)
		src.anchored = 0
		step(src, get_dir(W, src))
	if (src.health <= 0)
		new /obj/item/weapon/shard( src.loc )
		if(reinf) new /obj/item/weapon/rods( src.loc)
		src.density = 0
		src.loc.buildlinks()
		//SN src = null
		del(src)
		return
	..()
	return

/obj/window/attackby(obj/item/weapon/W as obj, mob/user as mob)

	if (istype(W, /obj/item/weapon/screwdriver))
		if(reinf && state >= 1)
			state = 3 - state
			usr << ( state==1? "You have unfastened the window from the frame." : "You have fastened the window to the frame." )
		else if(reinf && state == 0)
			anchored = !anchored
			user << (src.anchored ? "You have fastened the frame to the floor." : "You have unfastened the frame from the floor.")
		else if(!reinf)
			src.anchored = !( src.anchored )
			user << (src.anchored ? "You have fastened the window to the floor." : "You have unfastened the window.")
	else if(istype(W, /obj/item/weapon/crowbar) && reinf)
		if(state <=1)
			state = 1-state;
			user << (state ? "You have pried the window into the frame." : "You have pried the window out of the frame.")
	else
		var/aforce = W.force
		if(reinf) aforce /= 2.0

		src.health = max(0, src.health - aforce)
		if (src.health <= 7)
			src.anchored = 0
			var/turf/sl = src.loc
			step(src, get_dir(user, src))
			sl.buildlinks()
			src.loc.buildlinks()
		if (src.health <= 0)
			if (src.dir == SOUTHWEST)
				var/index = null
				index = 0
				while(index < 2)
					new /obj/item/weapon/shard( src.loc )
					if(reinf) new /obj/item/weapon/rods( src.loc)
					index++
			else
				new /obj/item/weapon/shard( src.loc )
				if(reinf) new /obj/item/weapon/rods( src.loc)
			//SN src = null

			src.density = 0
			src.loc.buildlinks()
			del(src)
			return
		..()
	src.loc.buildlinks()
	return

/obj/window/verb/rotate()
	set src in oview(1)

	if (src.anchored)
		usr << "It is fastened to the floor; therefore, you can't rotate it!"
		return 0
	else
		if (src.dir == SOUTHWEST)
			usr << "You can't rotate this! "
			return 0
	src.dir = turn(src.dir, 90)
	src.ini_dir = src.dir
	src.loc.buildlinks()
	return

/obj/window/New(Loc,re=0)

	..()

	if(re)	reinf = re

	src.ini_dir = src.dir
	src.loc.buildlinks()
	if(reinf)
		icon_state = "rwindow"
		desc = "A reinforced window."
		name = "reinforced window"
		state = 2*anchored
		health = 40

	return

/obj/window/Del()
	src.density = 0
	src.loc.buildlinks()
	..()

/obj/window/Move()

	var/turf/sl = src.loc
	..()
	src.dir = src.ini_dir
	sl.buildlinks()
	src.loc.buildlinks()
	return

/atom/proc/meteorhit(obj/meteor as obj)

	return

/atom/proc/allow_drop()

	return 1

/atom/proc/CheckPass(atom/O as mob|obj|turf|area)

	return (!( O.density ) || !( src.density ))

/atom/proc/CheckExit()

	return 1

/atom/proc/HasEntered(atom/movable/AM as mob|obj)

	return

/atom/proc/HasProximity(atom/movable/AM as mob|obj)

	return

/atom/movable/overlay/attackby(a, b)

	if (src.master)
		return src.master.attackby(a, b)
	return

/atom/movable/overlay/attack_paw(a, b, c)

	if (src.master)
		return src.master.attack_paw(a, b, c)
	return

/atom/movable/overlay/attack_hand(a, b, c)

	if (src.master)
		return src.master.attack_hand(a, b, c)
	return

/atom/movable/overlay/New()

	for(var/x in src.verbs)
		src.verbs -= x
		//Foreach goto(17)
	return

/turf/CheckPass(atom/O as mob|obj|turf|area)

	return !( src.density )
	return

/turf/New()

	..()
	for(var/atom/movable/AM as mob|obj in src)
		spawn( 0 )
			src.Entered(AM)
			return
		//Foreach goto(19)
	return

/turf/Enter(atom/movable/O as mob|obj, atom/forget as mob|obj|turf|area)

	if (!( isturf(O.loc) ))
		return 1
	for(var/atom/A as mob|obj|turf|area in O.loc)
		if ((!( A.CheckExit(O, src) ) && O != A && A != forget))
			if (O)
				O.Bump(A, 1)
			return 0
		//Foreach goto(34)
	for(var/atom/A as mob|obj|turf|area in src)
		if ((A.flags & 512 && get_dir(A, O) & A.dir))
			if ((!( A.CheckPass(O, src) ) && A != src && A != forget))
				if (O)
					O.Bump(A, 1)
				return 0
		//Foreach goto(127)
	for(var/atom/A as mob|obj|turf|area in src)
		if ((!( A.CheckPass(O, src) ) && A != forget))
			if (O)
				O.Bump(A, 1)
			return 0
		//Foreach goto(244)
	if (src != forget)
		if (!( src.CheckPass(O, src) ))
			if (O)
				O.Bump(src, 1)
			return 0
	return 1
	return

/turf/Entered(atom/movable/M as mob|obj)

	..()
	for(var/atom/A as mob|obj|turf|area in src)
		spawn( 0 )
			if ((A && M))
				A.HasEntered(M, 1)
			return
		//Foreach goto(19)
	for(var/atom/A as mob|obj|turf|area in range(1))
		spawn( 0 )
			if ((A && M))
				A.HasProximity(M, 1)
			return
		//Foreach goto(86)
	return


/turf/proc/levelupdate()


	for(var/obj/O in src)
		if(O.level == 1)
			O.hide(src.intact)


/turf/station/r_wall/updatecell()

	if (src.state == 2)
		return
	else
		..()
	return

/turf/station/r_wall/proc/update()

	if (src.d_state > 6)
		src.d_state = 0
		src.state = 1
	if (src.state == 2)
		src.icon_state = text("r_wall[]", (src.d_state > 0 ? text("-[]", src.d_state) : null))
		src.opacity = 1
		src.density = 1
		src.updatecell = 0
		src.buildlinks()
	else
		src.icon_state = "r_girder"
		src.opacity = 0
		src.density = 1
		src.updatecell = 1
		src.buildlinks()
	return

/turf/station/r_wall/unburn()

	src.luminosity = 0
	src.update()
	return

/turf/station/r_wall/meteorhit(obj/M as obj)

	if ((M.icon_state == "flaming" && prob(30)))
		if (src.state == 2)
			src.state = 1
			new /obj/item/weapon/sheet/metal( src )
			new /obj/item/weapon/sheet/metal( src )
			update()
		else
			if ((prob(20) && src.state == 1))
				src.state = 0
				//var/turf/station/floor/F = new /turf/station/floor( locate(src.x, src.y, src.z) )
				var/turf/station/floor/F = src.ReplaceWithFloor()
				F.oxygen = O2STANDARD
				new /obj/item/weapon/sheet/metal( F )
				new /obj/item/weapon/sheet/metal( F )
				F.buildlinks()
				F.levelupdate()
	return

/turf/station/r_wall/ex_act(severity)

	switch(severity)
		if(1.0)
			//SN src = null
			var/turf/space/S = src.ReplaceWithSpace()
			S.buildlinks()

			//del(src)
			return
		if(2.0)
			if (prob(75))
				src.opacity = 0
				src.updatecell = 1
				src.buildlinks()
				src.state = 1
				src.intact = 0
				src.levelupdate()
				new /obj/item/weapon/sheet/metal( src )
				new /obj/item/weapon/sheet/metal( src )
			else
				src.state = 0
				//var/turf/station/floor/F = new /turf/station/floor( locate(src.x, src.y, src.z) )
				var/turf/station/floor/F = src.ReplaceWithFloor()
				F.burnt = 1
				F.health = 30
				F.icon_state = "Floor1"
				new /obj/item/weapon/sheet/metal( F )
				new /obj/item/weapon/sheet/metal( F )
				F.buildlinks()
				F.levelupdate()
		if(3.0)
			if (prob(15))
				src.opacity = 0
				src.updatecell = 1
				src.buildlinks()
				src.intact = 0
				src.levelupdate()
				src.state = 1
				new /obj/item/weapon/sheet/metal( src )
				new /obj/item/weapon/sheet/metal( src )
				src.icon_state = "girder"
				update()
		else
	return

/turf/station/r_wall/blob_act()

	if(prob(10))
		if(!intact)
			src.state = 0
			//var/turf/station/floor/F = new /turf/station/floor( locate(src.x, src.y, src.z) )
			var/turf/station/floor/F = src.ReplaceWithFloor()
			F.burnt = 1
			F.health = 30
			F.icon_state = "Floor1"
			new /obj/item/weapon/sheet/metal( F )
			F.buildlinks()
			F.levelupdate()
		else

			src.opacity = 0
			src.updatecell = 1
			src.buildlinks()
			src.state = 1
			src.intact = 0
			src.levelupdate()
			new /obj/item/weapon/sheet/metal( src )
			src.icon_state = "girder"
			update()



/turf/station/r_wall/attackby(obj/item/weapon/W as obj, mob/user as mob)

	if ((!( istype(usr, /mob/human) ) && (!( ticker ) || (ticker && ticker.mode != "monkey"))))
		user << "\red You don't have the dexterity to do this!"
		return
	if (src.state == 2)
		if (istype(W, /obj/item/weapon/wrench))
			if (src.d_state == 4)
				var/turf/T = user.loc
				user << "\blue Cutting support rods."
				sleep(40)
				if (!( istype(src, /turf/station/r_wall) ))
					return
				if ((user.loc == T && user.equipped() == W && !( user.stat )))
					src.d_state = 5
		else
			if (istype(W, /obj/item/weapon/wirecutters))
				if (src.d_state == 0)
					src.d_state = 1
					new /obj/item/weapon/rods( src )
			else
				if (istype(W, /obj/item/weapon/weldingtool))
					if (src.d_state == 2)
						var/turf/T = user.loc
						user << "\blue Slicing metal cover."
						sleep(60)
						if (!( istype(src, /turf/station/r_wall) ))
							return
						if ((user.loc == T && user.equipped() == W && !( user.stat )))
							src.d_state = 3
					else
						if (src.d_state == 5)
							var/turf/T = user.loc
							user << "\blue Removing support rods."
							sleep(100)
							if (!( istype(src, /turf/station/r_wall) ))
								return

							if ((user.loc == T && user.equipped() == W && !( user.stat )))
								src.d_state = 6
								new /obj/item/weapon/rods( src )
				else
					if (istype(W, /obj/item/weapon/screwdriver))
						if (src.d_state == 1)
							var/turf/T = user.loc
							user << "\blue Removing support lines."
							sleep(40)
							if (!( istype(src, /turf/station/r_wall) ))
								return
							if ((user.loc == T && user.equipped() == W && !( user.stat )))
								src.d_state = 2
					else
						if (istype(W, /obj/item/weapon/crowbar))
							if (src.d_state == 3)
								var/turf/T = user.loc
								user << "\blue Prying cover off."
								sleep(100)
								if (!( istype(src, /turf/station/r_wall) ))
									return
								if ((user.loc == T && user.equipped() == W && !( user.stat )))
									src.d_state = 4
							else
								if (src.d_state == 6)
									var/turf/T = user.loc
									user << "\blue Prying outer sheath off."
									sleep(100)
									if (!( istype(src, /turf/station/r_wall) ))
										return
									if ((user.loc == T && user.equipped() == W && !( user.stat )))
										src.d_state = 7
										new /obj/item/weapon/sheet/metal( src )
						else
							if (istype(W, /obj/item/weapon/sheet/metal))
								var/turf/T = user.loc
								user << "\blue Repairing wall."
								sleep(100)
								if (!( istype(src, /turf/station/r_wall) ))
									return
								if ((user.loc == T && user.equipped() == W && !( user.stat ) && src.state == 2))
									src.d_state = 0
									if (W:amount > 1)
										W:amount--
									else
										//W = null
										del(W)
	if (src.state == 1)
		if (istype(W, /obj/item/weapon/wrench))
			user << "\blue Now dismantling girders."
			var/turf/T = user.loc
			sleep(100)
			if (!( istype(src, /turf/station/r_wall) ))
				return
			if ((user.loc == T && user.equipped() == W && !( user.stat )))
				src.state = 0
				//var/turf/station/floor/F = new /turf/station/floor( locate(src.x, src.y, src.z) )
				var/turf/station/floor/F = src.ReplaceWithFloor()
				F.oxygen = O2STANDARD
				new /obj/item/weapon/sheet/metal( F )
				new /obj/item/weapon/sheet/metal( F )
				new /obj/item/weapon/sheet/metal( F )
				new /obj/item/weapon/sheet/metal( F )
				F.buildlinks()
				F.levelupdate()
		else
			if (istype(W, /obj/item/weapon/sheet/r_metal))
				src.state = 2
				src.d_state = 0
				//W = null
				del(W)
	if(istype(src,/turf/station/r_wall))
		src.update()
	return

//routine above sometimes erroneously calls turf/station/floor/update
//src being miss-set somehow? Maybe due to multiple-clicking
/turf/station/floor/proc/update()
	return

/turf/station/wall/examine()
	set src in oview(1)

	usr << "It looks like a regular wall."
	return

/turf/station/wall/updatecell()

	if (src.state == 2)
		return
	else
		..()
	return


/turf/station/wall/ex_act(severity)

	switch(severity)
		if(1.0)
			//SN src = null
			var/turf/space/S = src.ReplaceWithSpace()
			S.buildlinks()
			del(src)
			return
		if(2.0)
			if (prob(50))
				src.opacity = 0
				src.updatecell = 1
				buildlinks()
				src.state = 1
				src.intact = 0
				src.levelupdate()
				new /obj/item/weapon/sheet/metal( src )
				new /obj/item/weapon/sheet/metal( src )
				src.icon_state = "girder"
			else
				src.state = 0
				//var/turf/station/floor/F = new /turf/station/floor( locate(src.x, src.y, src.z) )
				var/turf/station/floor/F = src.ReplaceWithFloor()
				F.burnt = 1
				F.health = 30
				F.icon_state = "Floor1"
				new /obj/item/weapon/sheet/metal( F )
				new /obj/item/weapon/sheet/metal( F )
				F.buildlinks()
				F.levelupdate()
		if(3.0)
			if (prob(25))
				src.opacity = 0
				src.updatecell = 1
				buildlinks()
				src.intact = 0
				levelupdate()
				src.state = 1
				new /obj/item/weapon/sheet/metal( src )
				new /obj/item/weapon/sheet/metal( src )
				src.icon_state = "girder"
		else
	return

/turf/station/wall/blob_act()

	if(prob(20))
		if(!intact)
			src.state = 0
			//var/turf/station/floor/F = new /turf/station/floor( locate(src.x, src.y, src.z) )
			var/turf/station/floor/F = src.ReplaceWithFloor()
			F.burnt = 1
			F.health = 30
			F.icon_state = "Floor1"
			new /obj/item/weapon/sheet/metal( F )
			F.buildlinks()
			F.levelupdate()
		else

			src.opacity = 0
			src.updatecell = 1
			buildlinks()
			src.state = 1
			src.intact = 0
			levelupdate()
			new /obj/item/weapon/sheet/metal( src )
			src.icon_state = "girder"



/turf/station/wall/unburn()

	src.luminosity = 0
	if (src.state == 1)
		src.icon_state = "girder"
	else
		src.icon_state = ""
	return

/turf/station/wall/attack_paw(mob/user as mob)

	if ((ticker && ticker.mode == "monkey"))
		return src.attack_hand(user)
	return

/turf/station/wall/attack_hand(mob/user as mob)

	user << "\blue You push the wall but nothing happens!"
	src.add_fingerprint(user)
	return

/turf/station/wall/attackby(obj/item/weapon/W as obj, mob/user as mob)

	if ((!( istype(usr, /mob/human) ) && (!( ticker ) || (ticker && ticker.mode != "monkey"))))
		user << "\red You don't have the dexterity to do this!"
		return
	if ((istype(W, /obj/item/weapon/wrench) && src.state == 1))
		var/turf/T = user.loc
		if (!( istype(T, /turf) ))
			return
		user << "\blue Now dissembling the reinforced girders. Please stand still. This is a long process."
		sleep(100)
		if (!( istype(src, /turf/station/wall) ))
			return
		if ((user.loc == T && src.state == 1 && user.equipped() == W))
			src.state = 0
			//var/turf/station/floor/F = new /turf/station/floor( locate(src.x, src.y, src.z) )
			var/turf/station/floor/F = src.ReplaceWithFloor()
			F.oxygen = O2STANDARD
			new /obj/item/weapon/sheet/metal( F )
			new /obj/item/weapon/sheet/metal( F )
			F.buildlinks()
			F.levelupdate()
	else
		if ((istype(W, /obj/item/weapon/screwdriver) && src.state == 1))
			var/turf/T = user.loc
			if (!( istype(T, /turf) ))
				return
			user << "\blue Now dislodging girders."
			sleep(100)
			if (!( istype(src, /turf/station/wall) ))
				return
			if ((user.loc == T && src.state == 1 && user.equipped() == W))
				src.state = 0
				//var/turf/station/floor/F = new /turf/station/floor( locate(src.x, src.y, src.z) )
				var/turf/station/floor/F = src.ReplaceWithFloor()

				F.oxygen = O2STANDARD
				new /obj/d_girders( F )
				new /obj/item/weapon/sheet/metal( F )
				F.buildlinks()
		else
			if ((istype(W, /obj/item/weapon/sheet/r_metal) && src.state == 1))
				var/turf/T = user.loc
				if (!( istype(T, /turf) ))
					return
				user << "\blue Now reinforcing girders."
				sleep(100)
				if (!( istype(src, /turf/station/wall) ))
					return
				if ((user.loc == T && src.state == 1 && user.equipped() == W))
					src.state = 0
					//var/turf/station/r_wall/F = new /turf/station/r_wall( locate(src.x, src.y, src.z) )
					var/turf/station/r_wall/F = src.ReplaceWithRWall()
					F.oxygen = O2STANDARD
					F.icon_state = "r_girder"
					F.state = 1
					F.opacity = 0
					F.updatecell = 1
					F.buildlinks()
			else
				if ((istype(W, /obj/item/weapon/weldingtool) && src.state == 2))
					var/turf/T = user.loc
					if (!( istype(T, /turf) ))
						return
					var/obj/item/weapon/weldingtool/WT = W
					if(WT.welding)
						if (WT.weldfuel < 5)
							user << "\blue You need more welding fuel to complete this task."
							return
						WT.weldfuel -= 5
						user << "\blue Now dissembling the outer wall plating. Please stand still."
						sleep(50)
						if ((user.loc == T && src.state == 2 && user.equipped() == W))
							src.opacity = 0
							src.updatecell = 1
							buildlinks()
							src.state = 1
							src.intact = 0
							levelupdate()
							new /obj/item/weapon/sheet/metal( src )
							new /obj/item/weapon/sheet/metal( src )
							src.icon_state = "girder"
		return

/turf/station/wall/meteorhit(obj/M as obj)

	if (M.icon_state == "flaming")
		src.icon_state = "girder"
		if (src.state == 2)
			src.state = 1
			src.opacity = 0
			src.updatecell = 1
			buildlinks()
			src.firelevel = 11
			new /obj/item/weapon/sheet/metal( src )
			new /obj/item/weapon/sheet/metal( src )
		else
			if ((prob(20) && src.state == 1))
				src.state = 0
				//var/turf/station/floor/F = new /turf/station/floor( locate(src.x, src.y, src.z) )
				var/turf/station/floor/F = src.ReplaceWithFloor()
				F.oxygen = O2STANDARD
				new /obj/item/weapon/sheet/metal( F )
				new /obj/item/weapon/sheet/metal( F )
				F.buildlinks()
				F.levelupdate()
	return

/turf/station/floor/CheckPass(atom/movable/O as mob|obj)

	if ((istype(O, /obj/machinery/pod) && !( src.burnt )))
		if (!( locate(/obj/machinery/mass_driver, src) ))
			return 0
	return 1
	return

/turf/station/floor/ex_act(severity)
	set src in oview(1)

	switch(severity)
		if(1.0)
			var/turf/space/S = src.ReplaceWithSpace()
			S.buildlinks()
			levelupdate()
			//del(src)	//deleting it makes this method silently stop executing and erases the saved area somehow (SL)
			return
		if(2.0)
			if (prob(50))
				//SN src = null
				var/turf/space/S = src.ReplaceWithSpace()
				S.buildlinks()
				levelupdate()
				//del(src)	//deleting it makes this method silently stop executing and erases the saved area somehow (SL)
				return
			else
				src.icon_state = "burning"
				src.luminosity = 2
				src.burnt = 1
				src.health = 30
				src.intact = 0
				levelupdate()
				src.firelevel = 1800000.0
				src.buildlinks()
		if(3.0)
			if (prob(50))
				src.burnt = 1
				src.health = 1
				src.intact = 0
				levelupdate()
				src.icon_state = "Floor1"
				src.buildlinks()
		else
	return

/turf/station/floor/blob_act()
	return

/turf/station/floor/attack_paw(mob/user as mob)
	return src.attack_hand(user)

/turf/station/floor/attack_hand(mob/user as mob)
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

/turf/station/floor/attackby(obj/item/weapon/C as obj, mob/user as mob)
	if (istype(C, /obj/item/weapon/crowbar))
		if (src.health > 100)
			src.health = 100
			src.burnt = 1
			src.intact = 0
			levelupdate()
			new /obj/item/weapon/tile(src)
			src.icon_state = text("Floor[]", (src.burnt ? "1" : ""))
	else if (istype(C, /obj/item/weapon/tile))
		if (src.health <= 100)
			src.intact = 1
			levelupdate()
			src.health = 150
			src.burnt = 0
			if (src.firelevel >= 900000.0)
				src.icon_state = "burning"
				src.luminosity = 2
			else
				src.icon_state = "Floor"
			var/obj/item/weapon/tile/T = C
			T.amount--
			if (T.amount < 1)
				del(T)
	else if (istype(C, /obj/item/weapon/cable_coil) )
		var/obj/item/weapon/cable_coil/coil = C
		coil.turf_place(src, user)
	return

/turf/station/floor/unburn()

	src.luminosity = 0
	src.icon_state = text("Floor[]", (src.burnt ? "1" : ""))
	return

/turf/station/floor/updatecell()

	..()
	if (src.checkfire)
		if (src.firelevel >= 2700000.0)
			src.health--
		if (src.health <= 0)
			src.burnt = 1
			src.intact = 0
			levelupdate()
			//SN src = null
			del(src)
			return
		else
			if (src.health <= 100)
				src.burnt = 1
				src.intact = 0
				levelupdate()
	return

/turf/station/floor/plasma_test/updatecell()

	..()
	src.poison = 7.5E7
	res_vars()
	return


