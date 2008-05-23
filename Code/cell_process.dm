
/obj/move/CheckPass(O as mob|obj)

	return !( src.density )


/obj/move/attack_paw(user as mob)

	return src.attack_hand(user)


/obj/move/attack_hand(var/mob/user as mob)

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

/obj/move/proc/res_vars()

	oldoxy = oxygen
	tmpoxy = oxygen

	oldpoison = poison
	tmppoison = poison

	oldco2 = co2
	tmpco2 = co2

	osl_gas = sl_gas
	tsl_gas = sl_gas

	on2 = src.n2
	tn2 = src.n2

	otemp = temp
	ttemp = temp

	return

/obj/move/proc/relocate(T as turf, degree)

	if (degree)
		for(var/atom/movable/A as mob|obj in src.loc)
			A.dir = turn(A.dir, degree)
			//*****RM as 4.1beta
			A.loc = T

			//Foreach goto(25)
	else
		for(var/atom/movable/A as mob|obj in src.loc)
			A.loc = T
			//Foreach goto(73)
	return

/obj/move/proc/unburn()

	src.icon_state = initial(src.icon_state)
	return


/obj/move/proc/Neighbors()

	var/list/L = cardinal.Copy()
	for(var/obj/machinery/door/window/D in src.loc)
		if(!( D.density ))
			continue

		//++++++
		//L -= D.dir

		if (D.dir & 12)
			L -= SOUTH
		else
			L -= EAST



		//Foreach goto(36)

	for(var/obj/window/D in src.loc)
		if(!( D.density ))
			continue
		L -= D.dir
		if (D.dir == SOUTHWEST)
			L.len = null
			return L

		//Foreach goto(115)
	return L

/obj/move/proc/FindTurfs()


	var/list/L = list(  )
	for(var/dir in src.Neighbors())
		var/turf/T = get_step(src.loc, dir)


		//++++++

		if(!( T ))
			goto Label_299
		L += T
		var/direct = turn(dir, 180)
		//*****RM as 4.1beta

		for(var/obj/machinery/door/window/D in T)
			if(!( D.density ))
				goto Label_181
			//var/direct = get_dir(src, T)
			if ((D.dir & 12))
				if (dir & 1)	// was direct&1
					L -= T
					goto Label_181
			else
				if(dir & 8) // was direct&8
					L -= T
					goto Label_181
			Label_181:
			//Foreach goto(81)

		for(var/obj/window/D in T)
			if(!( D.density ))
				goto Label_294
			//var/direct = get_dir(T, src.loc)
			if (D.dir == SOUTHWEST)
				L -= T
				goto Label_294
			else
				if(direct == D.dir)
					L -= T


			Label_294:
			//Foreach goto(199)

		//*****
		Label_299:
		if ((locate(/obj/move, T) && (T in L)))
			L -= T
			var/obj/move/O = locate(/obj/move, T)
			if (O.updatecell)
				L += O
		else
			if ((isturf(T) && !( T.updatecell )))
				L -= T
		//Foreach goto(26)


	return L


/obj/move/proc/tot_gas()
	return co2 + oxygen + poison + sl_gas + n2


/obj/move/proc/process()

	if (locate(/obj/shuttle/door, src.loc))
		var/obj/shuttle/door/D = locate(/obj/shuttle/door, src.loc)
		src.updatecell = !( D.density )
		if (!( src.updatecell ))
			return
	src.checkfire = !( src.checkfire )
	if (src.checkfire)
		if (cellcontrol.var_swap)
			var/divideby = 1
			var/total = src.oxygen
			var/tpoison = src.poison
			var/tco2 = src.co2
			var/tosl_gas = src.sl_gas
			var/ton2 = src.n2
			var/totemp = src.temp
			var/space = 0
			var/burn = src.firelevel >= 10
			for(var/atom/S in src.FindTurfs())
				var/obj/move/T = S
				if (istype(T, /turf/space))
					space = 1
				else
					divideby++
					total += T.oldoxy
					tpoison += T.oldpoison
					tco2 += T.oldco2
					tosl_gas += T.osl_gas
					ton2 += T.on2
					totemp += T.temp
					if (T.firelevel >= 900000.0)
						burn = 1
					//Foreach continue //goto(158)
			if (space)
				src.oxygen = 0
				src.poison = 0
				src.co2 = 0
				src.sl_gas = 0
				src.n2 = 0
				src.temp = 0
			else
				src.oxygen = total / divideby
				src.poison = tpoison / divideby
				src.co2 = tco2 / divideby
				src.sl_gas = tosl_gas / divideby
				src.n2 = ton2 / divideby
				src.temp = totemp / divideby
			if (src.sl_gas > 0)
				src.sl_gas--
			if (src.poison > 100000.0)
				src.overlays = list( plmaster )
			else
				if (src.sl_gas > 101000.0)
					src.overlays = list( slmaster )
				else
					src.overlays = null
			if (burn)
				src.firelevel = src.oxygen + src.poison
			if (src.firelevel >= 900000.0)
				src.icon_state = "burning"
				if (src.oxygen > 5000)
					src.co2 += 2500
					src.oxygen -= 5000
				else
					src.oxygen = 0

				// heating from fire
				temp += (firelevel/FIREQUOT+FIREOFFSET - temp) / FIRERATE

				src.poison = max(0, src.poison - 1000)
				if (locate(/obj/effects/water, src))
					src.firelevel = 0
				for(var/atom/movable/A in src)
					A.burn(src.firelevel)
					//Foreach goto(561)
			else
				src.firelevel = 0
				if (src.icon_state == "burning")
					unburn()
			src.tmpoxy = src.oxygen
			src.tmppoison = src.poison
			src.tmpco2 = src.co2
			src.tsl_gas = src.sl_gas
			src.tn2 = src.n2
			src.ttemp = src.temp
		else
			var/divideby = 1
			var/total = src.oxygen
			var/tpoison = src.poison
			var/tco2 = src.co2
			var/tosl_gas = src.sl_gas
			var/ton2 = src.n2
			var/totemp = src.temp
			var/space = 0
			var/burn = src.firelevel >= 10
			for(var/atom/S in src.FindTurfs())
				var/obj/move/T = S
				if (istype(T, /turf/space))
					space = 1
				else
					divideby++
					total += T.tmpoxy
					tpoison += T.tmppoison
					tco2 += T.tmpco2
					tosl_gas += T.tsl_gas
					ton2 += T.tn2
					totemp += T.ttemp
					if (T.firelevel >= 900000.0)
						burn = 1
					//Foreach continue //goto(744)
			if (space)
				src.oxygen = 0
				src.poison = 0
				src.co2 = 0
				src.sl_gas = 0
				src.n2 = 0
				src.temp = 0
			else
				src.oxygen = total / divideby
				src.poison = tpoison / divideby
				src.co2 = tco2 / divideby
				src.sl_gas = tosl_gas / divideby
				src.n2 = ton2 / divideby
				src.temp = totemp / divideby
			if (src.sl_gas > 0)
				src.sl_gas--
			if (src.poison > 100000.0)
				src.overlays = list( plmaster )
			else
				if (src.sl_gas > 101000.0)
					src.overlays = list( slmaster )
				else
					src.overlays = null
			if (burn)
				src.firelevel = src.oxygen + src.poison
			if (src.firelevel >= 900000.0)
				src.icon_state = "burning"
				if (src.oxygen > 5000)
					src.co2 += 2500
					src.oxygen -= 5000
				else
					src.oxygen = 0

				// heating from fire
				temp += (firelevel/FIREQUOT+FIREOFFSET - temp) / FIRERATE


				src.poison = max(0, src.poison - 1000)
				src.co2 += 2500
				if (locate(/obj/effects/water, src))
					src.firelevel = 0
				for(var/atom/movable/A as mob|obj in src)
					A.burn(src.firelevel)
					//Foreach goto(1153)
			else
				if (src.icon_state == "burning")
					src.firelevel = 0
					unburn()
			src.oldoxy = src.oxygen
			src.oldpoison = src.poison
			src.oldco2 = src.co2
			src.osl_gas = src.sl_gas
			src.on2 = src.n2
			src.otemp = src.temp
	else
		if (cellcontrol.var_swap)
			var/divideby = 1
			var/total = src.oxygen
			var/tpoison = src.poison
			var/tco2 = src.co2
			var/tosl_gas = src.sl_gas
			var/ton2 = src.n2
			var/totemp = src.temp
			var/space = 0
			src.airdir = null
			src.airforce = 0
			var/adiff = null
			for(var/atom/S in src.FindTurfs())
				var/obj/move/T = S
				if (istype(T, /turf/space))
					space = 1
					src.airforce = src.oxygen + src.n2 + src.poison + src.co2 + 25000
					src.airdir = get_dir(src, T)
				else
					divideby++
					total += T.oldoxy
					tpoison += T.oldpoison
					tco2 += T.oldco2
					tosl_gas += T.osl_gas
					ton2 += T.on2
					totemp += T.otemp
					adiff = src.oldoxy + src.oldco2 + src.on2 - (T.oldoxy + T.oldco2 + T.on2)
					if (adiff > src.airforce)
						src.airforce = adiff
						src.airdir = get_dir(src, T)
					//Foreach continue //goto(1356)
			if (src.airforce > 25000)
				for(var/atom/movable/AM as mob|obj in src.loc)
					if ((!( AM.anchored ) && AM.weight <= src.airforce))
						spawn( 0 )
							step(AM, src.airdir)
							return
					//Foreach goto(1559)
			if (space)
				src.oxygen = 0
				src.poison = 0
				src.co2 = 0
				src.sl_gas = 0
				src.n2 = 0
				src.temp = 0
			else
				src.oxygen = total / divideby
				src.poison = tpoison / divideby
				src.co2 = tco2 / divideby
				src.sl_gas = tosl_gas / divideby
				src.n2 = ton2 / divideby
				src.temp = totemp / divideby
			if (src.sl_gas > 0)
				src.sl_gas--
			if (src.co2 >= src.poison)
				src.co2 -= src.poison
				src.oxygen += src.poison
				src.poison = 0
			else
				src.poison -= src.co2
				src.oxygen += src.co2
				src.co2 = 0
			src.tmpoxy = src.oxygen
			src.tmppoison = src.poison
			src.tmpco2 = src.co2
			src.tsl_gas = src.sl_gas
			src.tn2 = src.n2
			src.ttemp = src.temp
		else
			var/divideby = 1
			var/total = src.oxygen
			var/tpoison = src.poison
			var/tco2 = src.co2
			var/tosl_gas = src.sl_gas
			var/ton2 = src.n2
			var/totemp = src.temp
			var/space = 0
			src.airdir = null
			src.airforce = 0
			var/adiff = null
			for(var/atom/S in src.FindTurfs())
				var/obj/move/T = S
				if (istype(T, /turf/space))
					space = 1
					src.airforce = src.oxygen + src.poison + src.n2 + src.co2 + 25000
					src.airdir = get_dir(src, T)
				else
					divideby++
					total += T.tmpoxy
					tpoison += T.tmppoison
					tco2 += T.tmpco2
					tosl_gas += T.tsl_gas
					ton2 += T.tn2
					totemp += T.ttemp
					adiff = src.tmpoxy + src.tmpco2 + src.tn2 - (T.tmpoxy + T.tmpco2 + T.tn2)
					if (adiff > src.airforce)
						src.airforce = adiff
						src.airdir = get_dir(src, T)
					//Foreach continue //goto(1927)
			if (src.airforce > 25000)
				for(var/atom/movable/AM as mob|obj in src.loc)
					if ((!( AM.anchored ) && AM.weight <= src.airforce))
						spawn( 0 )
							step(AM, src.airdir)
							return
					//Foreach goto(2130)
			if (space)
				src.oxygen = 0
				src.poison = 0
				src.co2 = 0
				src.sl_gas = 0
				src.n2 = 0
				src.temp = 0
			else
				src.oxygen = total / divideby
				src.poison = tpoison / divideby
				src.co2 = tco2 / divideby
				src.sl_gas = tosl_gas / divideby
				src.n2 = ton2 / divideby
				src.temp = totemp / divideby
			if (src.sl_gas > 0)
				src.sl_gas--
			if (src.co2 >= src.poison)
				src.co2 -= src.poison
				src.oxygen += src.poison
				src.poison = 0
			else
				src.poison -= src.co2
				src.oxygen += src.co2
				src.co2 = 0
			src.oldoxy = src.oxygen
			src.oldpoison = src.poison
			src.oldco2 = src.co2
			src.osl_gas = src.sl_gas
			src.on2 = src.n2
			src.otemp = src.temp
	if ((locate(/obj/effects/water, src.loc) || src.firelevel < 900000.0))
		src.firelevel = 0
		//cool due to water
		temp += (T20C - temp) / FIRERATE



	return

/obj/move/wall/New()

	var/F = locate(/obj/move/floor, src.loc)
	if (F)
		//F = null
		del(F)
	return

/obj/move/wall/process()

	src.updatecell = 0
	return

/obj/move/wall/blob_act()
	del(src)
	return

/obj/move/New()

	if ( (src.x & 1) == (src.y & 1) )
		src.checkfire = 0
	src.tmpoxy = src.oxygen
	src.oldoxy = src.oxygen
	src.tmppoison = src.poison
	src.oldpoison = src.poison
	src.tmpco2 = src.co2
	src.oldco2 = src.co2
	src.tn2 = src.n2
	src.on2 = src.n2

	otemp = temp
	ttemp = temp
	..()
	return

/turf/proc/res_vars()

	src.oldoxy = src.oxygen
	src.tmpoxy = src.oxygen
	src.oldpoison = src.poison
	src.tmppoison = src.poison
	src.oldco2 = src.co2
	src.tmpco2 = src.co2
	src.osl_gas = src.sl_gas
	src.tsl_gas = src.sl_gas
	src.on2 = src.n2
	src.tn2 = src.n2
	otemp = temp
	ttemp = temp
	return

/turf/proc/unburn()

	src.icon_state = initial(src.icon_state)
	return


//*****


// returns 0 if turf is dense or contains a dense object
// returns 1 otherwise
/turf/proc/isempty()
	if(src.density)
		return 0
	for(var/atom/A in src)
		if(A.density)
			return 0
	return 1


/turf/proc/Neighbors()

	var/list/L = cardinal.Copy()
	for(var/obj/machinery/door/window/D in src)
		if(!( D.density ))
			goto Label_96 //continue
		//+++++
		//L -= D.dir

		if (D.dir & 12)
			L -= SOUTH
		else
			L -= EAST

		Label_96
		//Foreach goto(34)
	for(var/obj/window/D in src)
		if(!( D.density ))
			goto Label_178 //continue
		L -= D.dir
		if (D.dir == SOUTHWEST)
			L.len = null
			return L
		Label_178
		//Foreach goto(111)
	return L


/*
/proc/flipdir(dir)

	switch(dir)
		if(1)
			return 2
		if(2)
			return 1
		if(4)
			return 8
		if(8)
			return 4
		if(5)
			return 10
		if(6)
			return 9
		if(9)
			return 10
		if(10)
			return 9
		else
			return 0

*/


/turf/proc/FindTurfs()

	var/list/L = list(  )
	if (locate(/obj/move, src))
		return list(  )
	for(var/dir in src.Neighbors())
		var/turf/T = get_step(src, dir)
		//*****RM

		//
		if((!( T ) || !( T.updatecell )))
			goto Label_317

		L += T
		var/direct = turn(dir, 180)
		//*****RM as 4.1beta

		for(var/obj/machinery/door/window/D in T)
			if(!( D.density ))
				goto Label_201
			//var/direct = get_dir(src, T)
			if (D.dir & 12)
				if((dir & 1))		// was (direct & 1)
					L -= T
					goto Label_201
			else
				if(dir & 8)			//was (direct&8)
					L -= T

			Label_201:
			//Foreach goto(101)

		for(var/obj/window/D in T)
			if(!( D.density ))
				goto Label_312
			//var/direct = get_dir(T, src)
			if (D.dir == SOUTHWEST)
				L -= T
				goto Label_312
			else
				if(direct == D.dir)
					L -= T

			Label_312:

			//Foreach goto(219)

		//*****

		Label_317:
		//Foreach goto(40)

	for(var/turf/T in L)
		if (locate(/obj/move, T))
			L -= T
			var/obj/move/O = locate(/obj/move, T)
			if (O.updatecell)
				L += O
		//Foreach goto(333)
	return L

/turf/New()

	if ((src.x & 1) == (src.y & 1))
		src.checkfire = 0
	src.tmpoxy = src.oxygen
	src.oldoxy = src.oxygen
	src.tmppoison = src.poison
	src.oldpoison = src.poison
	src.tmpco2 = src.co2
	src.oldco2 = src.co2
	src.osl_gas = src.sl_gas
	src.tsl_gas = src.sl_gas
	src.on2 = src.n2
	src.tn2 = src.n2

	otemp = temp
	ttemp = temp

	..()
	return


/turf/proc/setlink(dir, var/turf/T)

	switch(dir)
		if(1)
			linkN = T
		if(2)
			linkS = T
		if(4)
			linkE = T
		if(8)
			linkW = T

/turf/proc/setairlink(dir, val)

	switch(dir)
		if(1)
			airN = val
		if(2)
			airS = val
		if(4)
			airE = val
		if(8)
			airW = val

/turf/proc/setcondlink(dir, val)

	switch(dir)
		if(1)
			condN += val
		if(2)
			condS += val
		if(4)
			condE += val
		if(8)
			condW += val

/turf/buildlinks()				// call this one to update a cell and neighbours (on cell state change)

	updatelinks()

	for(var/dir in cardinal)
		var/turf/T = get_step(src,dir)
		if(T)
			T.updatelinks()

/turf/proc/updatelinks()			// this does updating for a single cell

	airN = null
	airS = null
	airE = null
	airW = null

	condN = 0
	condS = 0
	condE = 0
	condW = 0

	// originally in turf/Neighbors()

	var/list/NL = cardinal.Copy()

	for(var/obj/machinery/door/window/D in src)
		if(!( D.density ))
			continue

		if (D.dir & 12)
			NL -= SOUTH
			condS = 1
		else
			NL -= EAST
			condE = 1


	for(var/obj/window/D in src)
		if(!( D.density ))
			continue
		NL -= D.dir
		setcondlink(D.dir, 1+D.reinf)

		if (D.dir == SOUTHWEST)
			NL.len = null
			break



	for(var/dir in cardinal)
		var/turf/T = get_step(src, dir)
		setlink(dir,T)


		var/obj/move/O = locate(/obj/move, T)
		if (O)
			setlink(dir, O)
			if (!O.updatecell)
				goto Label_317


		if((!( T ) || !( T.updatecell )) || !(dir in NL))
			goto Label_317

		//L += T
		setairlink(dir, 1)

		var/direct = turn(dir, 180)

		for(var/obj/machinery/door/window/D in T)
			if(!( D.density ))
				goto Label_201

			if (D.dir & 12)
				if((dir & 1))
					//L -= T
					setairlink(dir, null)
					setcondlink(dir, 1)
					goto Label_201
			else
				if(dir & 8)			//was (direct&8)
					setairlink(dir, null)
					setcondlink(dir, 1)
			Label_201:
			//Foreach goto(101)

		for(var/obj/window/D in T)
			if(!( D.density ))
				goto Label_312
			//var/direct = get_dir(T, src)
			if (D.dir == SOUTHWEST)
				//L -= T
				setairlink(dir, null)
				setcondlink(dir, 1+D.reinf)
				goto Label_312
			else
				if(direct == D.dir)
					//L -= T
					setairlink(dir, null)
					setcondlink(dir,1+D.reinf)

			Label_312:

			//Foreach goto(219)

		//*****

		Label_317:
		//Foreach goto(40)




/turf/proc/FindLinkedTurfs()


	//if (locate(/obj/move, src))
	//	return list(  )

	var/list/L = list(  )
	if(airN)
		L += linkN
	if(airS)
		L += linkS
	if(airE)
		L += linkE
	if(airW)
		L += linkW

/*
	for(var/turf/T in L)
		var/obj/move/O = locate(/obj/move, T)
		if (O)
			L -= T
			if (O.updatecell)
				L += O
		//Foreach goto(333)
*/
	return L


/turf/proc/report()
	return "[src.type] [x] [y] [z]"


// return the total gas contents of a turf

/turf/proc/tot_gas()
	return co2 + oxygen + poison + sl_gas + n2

turf/proc/tot_old_gas()
	return oldco2 + oldoxy + oldpoison + osl_gas + on2

/turf/proc/tot_tmp_gas()
	return tmpco2 + tmpoxy + tmppoison + tsl_gas + tn2


// return the gas contents of a turf as a gas obj

/turf/proc/get_gas()

	var/obj/substance/gas/tgas = new()

	tgas.oxygen = src.oxygen
	tgas.n2 = src.n2
	tgas.plasma = src.poison
	tgas.co2 = src.co2
	tgas.sl_gas = src.sl_gas
	tgas.temperature = src.temp
	tgas.maximum = CELLSTANDARD		// not actually a maximum

	return tgas




/turf/updatecell()


	/*var/list/FT = FindTurfs()
	var/list/FLT = FindLinkedTurfs()
	if(FT.len != FLT.len)
		world << "TLM: [src.report()] FT:[FT.len] != FLT:[FLT.len]"
		for(var/turf/T1 in FT)
			world << "FT: [T1.report()]"
		for(var/turf/T2 in FLT)
			world << "FLT: [T2.report()]"
*/

	//if(tag && Debug)
	//	world.log << "T[tag]=[tot_gas()] Old=[tot_old_gas()] Tmp=[tot_tmp_gas()]"


	src.checkfire = !( src.checkfire )
	if (src.checkfire)
		if (cellcontrol.var_swap)
			var/divideby = 1
			var/total = src.oxygen
			var/tpoison = src.poison
			var/tco2 = src.co2
			var/tosl_gas = src.sl_gas
			var/ton2 = src.n2
			var/totemp = src.temp
			var/space = 0
			var/burn = src.firelevel >= 10



			/*
			for(var/turf/T in src.FindLinkedTurfs())
				if (istype(T, /turf/space))
					space = 1
					break // *****RM
				else
					divideby++
					total += T.oldoxy
					tpoison += T.oldpoison
					tco2 += T.oldco2
					tosl_gas += T.osl_gas
					ton2 += T.on2
					totemp += T.otemp
					if (T.firelevel >= 900000.0)
						burn = 1
					//Foreach continue //goto(113)
			*/


			if(airN)
				if(istype(linkN, /turf/space))
					space = 1
					goto Enddir1
				else
					divideby++
					total   += linkN.oldoxy
					tpoison += linkN.oldpoison
					tco2    += linkN.oldco2
					tosl_gas+= linkN.osl_gas
					ton2    += linkN.on2
					totemp  += linkN.otemp
					if (linkN.firelevel >= 900000.0)
						burn = 1
			if(airS)
				if(istype(linkS, /turf/space))
					space = 1
					goto Enddir1
				else
					divideby++
					total   += linkS.oldoxy
					tpoison += linkS.oldpoison
					tco2    += linkS.oldco2
					tosl_gas+= linkS.osl_gas
					ton2    += linkS.on2
					totemp  += linkS.otemp
					if (linkS.firelevel >= 900000.0)
						burn = 1
			if(airE)
				if(istype(linkE, /turf/space))
					space = 1
					goto Enddir1
				else
					divideby++
					total   += linkE.oldoxy
					tpoison += linkE.oldpoison
					tco2    += linkE.oldco2
					tosl_gas+= linkE.osl_gas
					ton2    += linkE.on2
					totemp  += linkE.otemp
					if (linkE.firelevel >= 900000.0)
						burn = 1
			if(airW)
				if(istype(linkW, /turf/space))
					space = 1
					goto Enddir1
				else
					divideby++
					total   += linkW.oldoxy
					tpoison += linkW.oldpoison
					tco2    += linkW.oldco2
					tosl_gas+= linkW.osl_gas
					ton2    += linkW.on2
					totemp  += linkW.otemp
					if (linkW.firelevel >= 900000.0)
						burn = 1

			Enddir1:

			if (space)
				src.oxygen = 0
				src.poison = 0
				src.co2 = 0
				src.sl_gas = 0
				src.n2 = 0
				src.temp = 0
			else
				src.oxygen = total / divideby
				src.poison = tpoison / divideby
				src.co2 = tco2 / divideby
				src.sl_gas = tosl_gas / divideby
				src.n2 = ton2 / divideby
				src.temp = totemp / divideby
			if (src.sl_gas > 0)
				src.sl_gas--
			if (src.poison > 100000.0)
				src.overlays = list( plmaster )
			else
				if (src.sl_gas > 101000.0)
					src.overlays = list( slmaster )
				else
					src.overlays = null
			if (burn)
				src.firelevel = src.oxygen + src.poison
			if (src.firelevel >= 900000.0)
				src.icon_state = "burning"
				if (src.oxygen > 5000)
					src.co2 += 2500
					src.oxygen -= 5000
				else
					src.oxygen = 0

				// heating from fire
				temp += (firelevel/FIREQUOT+FIREOFFSET - temp) / FIRERATE


				src.poison = max(0, src.poison - 1000)
				src.co2 += 2500
				if (locate(/obj/effects/water, src))
					src.firelevel = 0
				for(var/atom/movable/A in src)
					A.burn(src.firelevel)
					//Foreach goto(522)
			else
				src.firelevel = 0
				if (src.icon_state == "burning")
					unburn()
			src.tmpoxy = src.oxygen
			src.tmppoison = src.poison
			src.tmpco2 = src.co2
			src.tsl_gas = src.sl_gas
			src.tn2 = src.n2
			src.ttemp = src.temp
			//if(tag && Debug)
			//	world.log << "Tot[tag]=[total+tpoison+tco2+tosl_gas+ton2]  /  [divideby]"
			//	world.log << "T[tag]=[tot_gas()] .Tmp=[tot_tmp_gas()]"

		else
			var/divideby = 1
			var/total = src.oxygen
			var/tpoison = src.poison
			var/tco2 = src.co2
			var/tosl_gas = src.sl_gas
			var/ton2 = src.n2
			var/totemp = src.temp
			var/space = 0
			var/burn = src.firelevel >= 10

			/*
			for(var/turf/T in src.FindLinkedTurfs())
				if (istype(T, /turf/space))
					space = 1
					break // *****RM
				else
					divideby++
					total += T.tmpoxy
					tpoison += T.tmppoison
					tco2 += T.tmpco2
					tosl_gas += T.tsl_gas
					ton2 += T.tn2
					totemp += T.ttemp
					if (T.firelevel >= 900000.0)
						burn = 1
					//Foreach continue //goto(705)
			*/

			if(airN)
				if(istype(linkN, /turf/space))
					space = 1
					goto Enddir2
				else
					divideby++
					total   += linkN.tmpoxy
					tpoison += linkN.tmppoison
					tco2    += linkN.tmpco2
					tosl_gas+= linkN.tsl_gas
					ton2    += linkN.tn2
					totemp  += linkN.ttemp
					if (linkN.firelevel >= 900000.0)
						burn = 1
			if(airS)
				if(istype(linkS, /turf/space))
					space = 1
					goto Enddir2
				else
					divideby++
					total   += linkS.tmpoxy
					tpoison += linkS.tmppoison
					tco2    += linkS.tmpco2
					tosl_gas+= linkS.tsl_gas
					ton2    += linkS.tn2
					totemp  += linkS.ttemp
					if (linkS.firelevel >= 900000.0)
						burn = 1
			if(airE)
				if(istype(linkE, /turf/space))
					space = 1
					goto Enddir2
				else
					divideby++
					total   += linkE.tmpoxy
					tpoison += linkE.tmppoison
					tco2    += linkE.tmpco2
					tosl_gas+= linkE.tsl_gas
					ton2    += linkE.tn2
					totemp  += linkE.ttemp
					if (linkE.firelevel >= 900000.0)
						burn = 1
			if(airW)
				if(istype(linkW, /turf/space))
					space = 1
					goto Enddir2
				else
					divideby++
					total   += linkW.tmpoxy
					tpoison += linkW.tmppoison
					tco2    += linkW.tmpco2
					tosl_gas+= linkW.tsl_gas
					ton2    += linkW.tn2
					totemp  += linkW.ttemp
					if (linkW.firelevel >= 900000.0)
						burn = 1

			Enddir2:


			if (space)
				src.oxygen = 0
				src.poison = 0
				src.co2 = 0
				src.sl_gas = 0
				src.n2 = 0
				src.temp = 0
			else
				src.oxygen = total / divideby
				src.poison = tpoison / divideby
				src.co2 = tco2 / divideby
				src.sl_gas = tosl_gas / divideby
				src.n2 = ton2 / divideby
				src.temp = totemp / divideby
			if (src.sl_gas > 0)
				src.sl_gas--
			if (src.poison > 100000.0)
				src.overlays = list( plmaster )
			else
				if (src.sl_gas > 101000.0)
					src.overlays = list( slmaster )
				else
					src.overlays = null
			if (burn)
				src.firelevel = src.oxygen + src.poison
			if (src.firelevel >= 900000.0)
				src.icon_state = "burning"
				if (src.oxygen > 5000)
					src.co2 += 2500
					src.oxygen -= 5000
				else
					src.oxygen = 0

					// heating from fire
				temp += (firelevel/FIREQUOT+FIREOFFSET - temp) / FIRERATE



				src.poison = max(0, src.poison - 1000)
				src.co2 += 2500
				if (locate(/obj/effects/water, src))
					src.firelevel = 0
				for(var/atom/movable/A as mob|obj in src)
					A.burn(src.firelevel)
					//Foreach goto(1114)
			else
				if (src.icon_state == "burning")
					src.firelevel = 0
					unburn()
			src.oldoxy = src.oxygen
			src.oldpoison = src.poison
			src.oldco2 = src.co2
			src.osl_gas = src.sl_gas
			src.on2 = src.n2
			src.otemp = src.temp
			//if(tag && Debug)
			//	world.log << "Tot[tag]=[total+tpoison+tco2+tosl_gas+ton2]  /  [divideby]"
			//	world.log << "T[tag]=[tot_gas()] .Old=[tot_old_gas()]"

	else
		if (cellcontrol.var_swap)
			var/divideby = 1
			var/total = src.oxygen
			var/tpoison = src.poison
			var/tco2 = src.co2
			var/tosl_gas = src.sl_gas
			var/ton2 = src.n2
			var/totemp = src.temp
			var/space = 0
			src.airdir = null
			src.airforce = 0
			var/adiff = null
			/*
			for(var/turf/T in src.FindLinkedTurfs())
				if (istype(T, /turf/space))
					space = 1
					src.airforce = src.oxygen + src.poison + src.n2 + src.co2 + 25000
					src.airdir = get_dir(src, T)
					break // *****RM
				else
					divideby++
					total += T.oldoxy
					tpoison += T.oldpoison
					tco2 += T.oldco2
					tosl_gas += T.osl_gas
					ton2 += T.on2
					totemp += T.otemp
					adiff = src.oldoxy + src.oldco2 + src.on2 - (T.oldoxy + T.oldco2 + T.on2)
					if (adiff > src.airforce)
						src.airforce = adiff
						src.airdir = get_dir(src, T)
					//Foreach continue //goto(1317)

			*/
			if(airN)
				if(istype(linkN, /turf/space))
					space = 1
					src.airforce = src.oxygen + src.poison + src.n2 + src.co2 + 25000
					src.airdir = NORTH
					goto Enddir3
				else
					divideby++
					total   += linkN.oldoxy
					tpoison += linkN.oldpoison
					tco2    += linkN.oldco2
					tosl_gas+= linkN.osl_gas
					ton2    += linkN.on2
					totemp  += linkN.otemp
					adiff = src.oldoxy + src.oldco2 + src.on2 - (linkN.oldoxy + linkN.oldco2 + linkN.on2)
					if (adiff > src.airforce)
						src.airforce = adiff
						src.airdir = NORTH
			if(airS)
				if(istype(linkS, /turf/space))
					space = 1
					src.airforce = src.oxygen + src.poison + src.n2 + src.co2 + 25000
					src.airdir = get_dir(src, SOUTH)
					goto Enddir3
				else
					divideby++
					total   += linkS.oldoxy
					tpoison += linkS.oldpoison
					tco2    += linkS.oldco2
					tosl_gas+= linkS.osl_gas
					ton2    += linkS.on2
					totemp  += linkS.otemp
					adiff = src.oldoxy + src.oldco2 + src.on2 - (linkS.oldoxy + linkS.oldco2 + linkS.on2)
					if (adiff > src.airforce)
						src.airforce = adiff
						src.airdir = SOUTH
			if(airE)
				if(istype(linkE, /turf/space))
					space = 1
					src.airforce = src.oxygen + src.poison + src.n2 + src.co2 + 25000
					src.airdir = EAST
					goto Enddir3
				else
					divideby++
					total   += linkE.oldoxy
					tpoison += linkE.oldpoison
					tco2    += linkE.oldco2
					tosl_gas+= linkE.osl_gas
					ton2    += linkE.on2
					totemp  += linkE.otemp
					adiff = src.oldoxy + src.oldco2 + src.on2 - (linkE.oldoxy + linkE.oldco2 + linkE.on2)
					if (adiff > src.airforce)
						src.airforce = adiff
						src.airdir = EAST
			if(airW)
				if(istype(linkW, /turf/space))
					space = 1
					src.airforce = src.oxygen + src.poison + src.n2 + src.co2 + 25000
					src.airdir = get_dir(src, WEST)
					goto Enddir3
				else
					divideby++
					total   += linkW.oldoxy
					tpoison += linkW.oldpoison
					tco2    += linkW.oldco2
					tosl_gas+= linkW.osl_gas
					ton2    += linkW.on2
					totemp  += linkW.otemp
					adiff = src.oldoxy + src.oldco2 + src.on2 - (linkW.oldoxy + linkW.oldco2 + linkW.on2)
					if (adiff > src.airforce)
						src.airforce = adiff
						src.airdir = WEST

			Enddir3:

			if (src.airforce > 25000)
				for(var/atom/movable/AM in src)
					if ((!( AM.anchored ) && AM.weight <= src.airforce))
						spawn( 0 )
							step(AM, src.airdir)
							return
					//Foreach goto(1518)

			if (space)
				src.oxygen = 0
				src.poison = 0
				src.co2 = 0
				src.sl_gas = 0
				src.n2 = 0
				src.temp = 0
			else
				src.oxygen = total / divideby
				src.poison = tpoison / divideby
				src.co2 = tco2 / divideby
				src.sl_gas = tosl_gas / divideby
				src.n2 = ton2 / divideby
				src.temp = totemp / divideby



			if (src.co2 >= src.poison)
				src.co2 -= src.poison
				src.oxygen += src.poison
				src.poison = 0
			else
				src.poison -= src.co2
				src.oxygen += src.co2
				src.co2 = 0
			src.tmpoxy = src.oxygen
			src.tmppoison = src.poison
			src.tmpco2 = src.co2
			src.tsl_gas = src.sl_gas
			src.tn2 = src.n2
			src.ttemp = src.temp
			//if(tag && Debug)
			//	world.log << "Tot[tag]=[total+tpoison+tco2+tosl_gas+ton2]  /  [divideby]"
			//	world.log << "T[tag]=[tot_gas()] .Tmp=[tot_tmp_gas()]"
		else
			var/divideby = 1
			var/total = src.oxygen
			var/tpoison = src.poison
			var/tco2 = src.co2
			var/tosl_gas = src.sl_gas
			var/ton2 = src.n2
			var/totemp = src.temp
			var/space = 0
			src.airdir = null
			src.airforce = 0
			var/adiff = null
			/*for(var/turf/T in src.FindLinkedTurfs())
				if (istype(T, /turf/space))
					space = 1
					src.airforce = src.oxygen + src.poison + src.n2 + src.co2 + 25000
					src.airdir = get_dir(src, T)
					break // *****RM
				else
					divideby++
					total += T.tmpoxy
					tpoison += T.tmppoison
					tco2 += T.tmpco2
					tosl_gas += T.tsl_gas
					ton2 += T.tn2
					totemp += T.ttemp
					adiff = src.tmpoxy + src.tmpco2 + src.tn2 - (T.tmpoxy + T.tmpco2 + T.tn2)
					if (adiff > src.airforce)
						src.airforce = adiff
						src.airdir = get_dir(src, T)
					//Foreach continue //goto(1872)

			*/

			if(airN)
				if(istype(linkN, /turf/space))
					space = 1
					src.airforce = src.oxygen + src.poison + src.n2 + src.co2 + 25000
					src.airdir = NORTH
					goto Enddir4
				else
					divideby++
					total   += linkN.tmpoxy
					tpoison += linkN.tmppoison
					tco2    += linkN.tmpco2
					tosl_gas+= linkN.tsl_gas
					ton2    += linkN.tn2
					totemp  += linkN.ttemp
					adiff = src.tmpoxy + src.tmpco2 + src.tn2 - (linkN.tmpoxy + linkN.tmpco2 + linkN.tn2)
					if (adiff > src.airforce)
						src.airforce = adiff
						src.airdir = NORTH
			if(airS)
				if(istype(linkS, /turf/space))
					space = 1
					src.airforce = src.oxygen + src.poison + src.n2 + src.co2 + 25000
					src.airdir = get_dir(src, SOUTH)
					goto Enddir4
				else
					divideby++
					total   += linkS.tmpoxy
					tpoison += linkS.tmppoison
					tco2    += linkS.tmpco2
					tosl_gas+= linkS.tsl_gas
					ton2    += linkS.tn2
					totemp  += linkS.ttemp
					adiff = src.tmpoxy + src.tmpco2 + src.tn2 - (linkS.tmpoxy + linkS.tmpco2 + linkS.tn2)
					if (adiff > src.airforce)
						src.airforce = adiff
						src.airdir = SOUTH
			if(airE)
				if(istype(linkE, /turf/space))
					space = 1
					src.airforce = src.oxygen + src.poison + src.n2 + src.co2 + 25000
					src.airdir = EAST
					goto Enddir4
				else
					divideby++
					total   += linkE.tmpoxy
					tpoison += linkE.tmppoison
					tco2    += linkE.tmpco2
					tosl_gas+= linkE.tsl_gas
					ton2    += linkE.tn2
					totemp  += linkE.ttemp
					adiff = src.tmpoxy + src.tmpco2 + src.tn2 - (linkE.tmpoxy + linkE.tmpco2 + linkE.tn2)
					if (adiff > src.airforce)
						src.airforce = adiff
						src.airdir = EAST
			if(airW)
				if(istype(linkW, /turf/space))
					space = 1
					src.airforce = src.oxygen + src.poison + src.n2 + src.co2 + 25000
					src.airdir = get_dir(src, WEST)
					goto Enddir4
				else
					divideby++
					total   += linkW.tmpoxy
					tpoison += linkW.tmppoison
					tco2    += linkW.tmpco2
					tosl_gas+= linkW.tsl_gas
					ton2    += linkW.tn2
					totemp  += linkW.ttemp
					adiff = src.tmpoxy + src.tmpco2 + src.tn2 - (linkW.tmpoxy + linkW.tmpco2 + linkW.tn2)
					if (adiff > src.airforce)
						src.airforce = adiff
						src.airdir = WEST


			Enddir4:

			if (src.airforce > 25000)
				for(var/atom/movable/AM as mob|obj in src)
					if ((!( AM.anchored ) && AM.weight <= src.airforce))
						spawn( 0 )
							step(AM, src.airdir)
							return
					//Foreach goto(2073)
			if (space)
				src.oxygen = 0
				src.poison = 0
				src.co2 = 0
				src.sl_gas = 0
				src.n2 = 0
				src.temp = 0
			else
				src.oxygen = total / divideby
				src.poison = tpoison / divideby
				src.co2 = tco2 / divideby
				src.sl_gas = tosl_gas / divideby
				src.n2 = ton2 / divideby
				src.temp = totemp / divideby
			if (src.sl_gas > 0)
				src.sl_gas--
			if (src.co2 >= src.poison)
				src.co2 -= src.poison
				src.oxygen += src.poison
				src.poison = 0
			else
				src.poison -= src.co2
				src.oxygen += src.co2
				src.co2 = 0

			src.oldoxy = src.oxygen
			src.oldpoison = src.poison
			src.oldco2 = src.co2
			src.osl_gas = src.sl_gas
			src.on2 = src.n2
			src.otemp = src.temp

			//if(tag && Debug)
			//	world.log << "Tot[tag]=[total+tpoison+tco2+tosl_gas+ton2]  /  [divideby]"
			//	world.log << "T[tag]=[tot_gas()] .Old=[tot_old_gas()]"

	if ((locate(/obj/effects/water, src) || src.firelevel < 900000.0))
		src.firelevel = 0
		//cool due to water
		temp += (T20C - temp) / FIRERATE

	return

/turf/conduction()

	var/difftemp = 0
	for(var/turf/T in FindCondTurfs())
		var/cond = getCond(get_dir(src, T))
		difftemp += (T.otemp-src.temp)/(10*cond)

	temp += difftemp


/turf/proc/FindCondTurfs()

	var/list/L = list(  )
	if(condN)
		L += linkN
	if(condS)
		L += linkS
	if(condE)
		L += linkE
	if(condW)
		L += linkW


	return L

/turf/proc/getCond(dir)
	switch(dir)
		if(1)
			return condN
		if(2)
			return condS
		if(4)
			return condE
		if(8)
			return condW
	return 0

