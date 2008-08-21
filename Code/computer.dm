/obj/machinery/computer/security/New()
	..()
	if(!maplevel)
		src.verbs -= /obj/machinery/computer/security/verb/station_map

/obj/machinery/computer/security/attack_ai(var/mob/user as mob)
	return src.attack_hand(user)
	return

/obj/machinery/computer/security/attack_paw(var/mob/user as mob)

	return src.attack_hand(user)
	return

//Using http://en.wikipedia.org/wiki/Shell_sort
//It got a little butchered by me not wanting to have half a dozen things going on in one for condition statement or while condition statement.
/proc/sortList(list/A)
	// Note: A[someNumber] is a string, the name of the camera, and A[thatName] is the camera.
	// We're making a backup of the list named 'B' because when we move elements in A, the list forgets about the camera.
	var/list/B = list()
	var/i = 0
	for (i=1, i<=A.len, i++)
		B[A[i]] = A[A[i]]

	var/j = 0
	var/temp = null
	var/size = A.len
	var/increment = size / 2
	while (increment > 0)
		for (i = increment, i < size, i+=increment)
			j = i
			temp = A[1+i]

			var/other = A[1+j-increment]
			var/sortval = -sorttext(other, temp) //The - is because sorttext(A,B) returns -1 if A > B, rather than 1, and I'd consider having A > B = 1 to be more natural (since you can then check if sortval > 0, using the same comparison operator that you would have if you were directly comparing A and B (If we think that (0 > sortval) isn't also acceptable)).  -Trafalgar

			while ((j >= increment) && (sortval > 0))
				A[1+j] = A[1+j - increment]
				j = j - increment;
				if (j>=increment)
					other = A[1+j-increment]
					sortval = sorttext(temp, other)

			A[1+j] = temp


		if (increment == 2)
			increment = 1
		else
			increment = round(increment / 2.2)

	//Now we go through and assign names to cameras in a new list, but we do it in the order in which we had sorted the strings to
	//The presumable un-speediness of this kind of defeats the point of doing the sorting the way we did it, though.
	var/list/C = list()
	for (i=1, i<=A.len, i++)
		C[A[i]] = B[A[i]]


	return C

/obj/machinery/computer/security/attack_hand(var/mob/user as mob)

	if(stat & (NOPOWER|BROKEN) ) return

	var/list/L = list(  )
	user.machine = src
	for(var/obj/machinery/camera/C in world)
		if (C.network == src.network)
			L[text("[][]", C.c_tag, (C.status ? null : " (Deactivated)"))] = C

	L = sortList(L)
	L["Cancel"] = "Cancel"
	var/t = input(user, "Which camera should you change to?") as null|anything in L

	if(!t)
		user.machine = null
		return 0

	var/obj/machinery/camera/C = L[t]
	if (t == "Cancel")
		user.machine = null
		return 0
	if ((get_dist(user, src) > 1 || user.machine != src || user.blinded || !( user.canmove ) || !( C.status )) && (!istype(user, /mob/ai)))
		user.machine = null
		return 0
	else
		src.current = C
		use_power(50)
		spawn( 5 )
			attack_hand(user)
			return
	return

/obj/machinery/computer/security/check_eye(var/mob/user as mob)

	if ((get_dist(user, src) > 1 || !( user.canmove ) || user.blinded || !( src.current ) || !( src.current.status )) && (!istype(user, /mob/ai)))
		return null
	user.reset_view(src.current)
	return 1
	return


/obj/datacore/proc/manifest()

	for(var/mob/human/H in world)
		if ((H.start && !( findtext(H.rname, "Syndicate ", 1, null) )))
			var/datum/data/record/G = new /datum/data/record(  )
			var/datum/data/record/M = new /datum/data/record(  )
			var/datum/data/record/S = new /datum/data/record(  )
			var/obj/item/weapon/card/id/C = H.wear_id
			if (C)
				G.fields["rank"] = C.assignment
			else
				G.fields["rank"] = "Unassigned"
			G.fields["name"] = H.rname
			G.fields["id"] = text("[]", add_zero(num2hex(rand(1, 1.6777215E7)), 6))
			M.fields["name"] = G.fields["name"]
			M.fields["id"] = G.fields["id"]
			S.fields["name"] = G.fields["name"]
			S.fields["id"] = G.fields["id"]
			if (H.gender == "female")
				G.fields["sex"] = "Female"
			else
				G.fields["sex"] = "Male"
			G.fields["age"] = text("[]", H.age)
			G.fields["fingerprint"] = text("[]", md5(H.primary.uni_identity))
			G.fields["p_stat"] = "Active"
			G.fields["m_stat"] = "Stable"
			M.fields["b_type"] = text("[]", H.b_type)
			M.fields["mi_dis"] = "None"
			M.fields["mi_dis_d"] = "No minor disabilities have been declared."
			M.fields["ma_dis"] = "None"
			M.fields["ma_dis_d"] = "No major disabilities have been diagnosed."
			M.fields["alg"] = "None"
			M.fields["alg_d"] = "No allergies have been detected in this patient."
			M.fields["cdi"] = "None"
			M.fields["cdi_d"] = "No diseases have been diagnosed at the moment."
			M.fields["notes"] = "No notes."
			S.fields["criminal"] = "None"
			S.fields["mi_crim"] = "None"
			S.fields["mi_crim_d"] = "No minor crime convictions."
			S.fields["ma_crim"] = "None"
			S.fields["ma_crim_d"] = "No minor crime convictions."
			S.fields["notes"] = "No notes."
			src.general += G
			src.medical += M
			src.security += S
	return

/turf/space/attack_paw(mob/user as mob)

	return src.attack_hand(user)
	return

/turf/space/attack_hand(mob/user as mob)

	if ((user.restrained() || !( user.pulling )))
		return
	if (user.pulling.anchored)
		return
	if ((user.pulling.loc != user.loc && get_dist(user, user.pulling) > 1))
		return
	if (ismob(user.pulling))
		var/mob/M = user.pulling
		var/t = M.pulling
		M.pulling = null
		step(user.pulling, get_dir(user.pulling.loc, src))
		M.pulling = t
	else
		step(user.pulling, get_dir(user.pulling.loc, src))
	return

/turf/space/attackby(obj/item/weapon/W, mob/user)

	if (istype(W, /obj/item/weapon/tile))
		var/obj/item/weapon/tile/T = W
		T.build(src)
		T.amount--
		T.add_fingerprint(user)
		if (T.amount < 1)
			user.u_equip(T)
			del(T)
			return
	else if (istype(W, /obj/item/weapon/pipe) )
		var/obj/item/weapon/pipe/pipe = W
		if(locate(/obj/lattice) in src)
			pipe.turf_place(src, user)
	return

/turf/space/updatecell()
	if (config.air_pressure_flow)
		if ((src.linkN && src.linkN.firelevel && src.linkN.firelevel > 0) || (src.linkS && src.linkS.firelevel && src.linkS.firelevel > 0) || (src.linkE && src.linkE.firelevel && src.linkE.firelevel > 0) || (src.linkW && src.linkW.firelevel && src.linkW.firelevel > 0))
			..()
	return

/turf/space/conduction()
	if (config.air_pressure_flow)
		if ((src.linkN && src.linkN.firelevel && src.linkN.firelevel > 0) || (src.linkS && src.linkS.firelevel && src.linkS.firelevel > 0) || (src.linkE && src.linkE.firelevel && src.linkE.firelevel > 0) || (src.linkW && src.linkW.firelevel && src.linkW.firelevel > 0))
			..()
	return

/turf/space/Entered(atom/movable/A as mob|obj)

	..()
	if ((!( A ) || src != A.loc || istype(null, /obj/beam)))
		return
	if (!( A.last_move ))
		return
	if (locate(/obj/move, src))
		return 1
	if ((ismob(A) && src.x > 2 && src.x < (world.maxx - 2) ))
		var/mob/M = A
		if ((!( M.restrained() ) && M.canmove))
			var/t1 = 5
			if (locate(/obj/grille, oview(1, M)))
				if (!( M.l_hand ))
					t1 -= 2
				else
					if (M.l_hand.w_class <= 2)
						t1 -= 1
				if (!( M.r_hand ))
					t1 -= 2
				else
					if (M.r_hand.w_class <= 2)
						t1 -= 1
			else if (locate(/obj/move/, oview(1, M)))	//characters 'grab' shuttle walls like regular walls now -shadowlord13
				if (!( M.l_hand ))
					t1 -= 1
				else
					if (M.l_hand.w_class <= 2)
						t1 -= 0.5
				if (!( M.r_hand ))
					t1 -= 1
				else
					if (M.r_hand.w_class <= 2)
						t1 -= 0.5
			else if (locate(/obj/machinery/, oview(1, M)))	//characters 'grab' objects in space like a grille now -zjm7891 Thanks Shadowlord
				if (!( M.l_hand ))
					t1 -= 2
				else
					if (M.l_hand.w_class <= 2)
						t1 -= 1
				if (!( M.r_hand ))
					t1 -= 2
				else
					if (M.r_hand.w_class <= 2)
						t1 -= 1
			else if (locate(/turf/station, oview(1, M)))
				if (!( M.l_hand ))
					t1 -= 1
				else
					if (M.l_hand.w_class <= 2)
						t1 -= 0.5
				if (!( M.r_hand ))
					t1 -= 1
				else
					if (M.r_hand.w_class <= 2)
						t1 -= 0.5
			else
				if (locate(/turf/station, oview(1, M)))
					if (!( M.l_hand ))
						t1 -= 1
					else
						if (M.l_hand.w_class <= 2)
							t1 -= 0.5
					if (!( M.r_hand ))
						t1 -= 1
					else
						if (M.r_hand.w_class <= 2)
							t1 -= 0.5
			t1 = round(t1)
			if (t1 < 5)
				if (prob(t1))
					M << "\blue <B>You slipped!</B>"
				else
					spawn( 5 )
						if (src == A.loc)
							spawn( 0 )
								src.Entered(A)
								return 1
						return 1
					return 1

	if (src.x <= 2 && src.z < world.maxz)
		A.z++
		A.x = world.maxx - 2
		spawn (0)
			if ((A && A.loc))
				A.loc.Entered(A)
	else if (A.x >= (world.maxx - 1) && A.z > 1)
		A.z--
		A.x = 3
		spawn (0)
			if ((A && A.loc))
				A.loc.Entered(A)
	else
		spawn (5)
			if ((A && !( A.anchored ) && A.loc == src))
				if (step(A, A.last_move))
				else
					spawn( 0 )
						src.Entered(A)

/proc/call_shuttle_proc(var/mob/user)
	if ((!( ticker ) || ticker.shuttle_location == 1))
		return

	if( ticker.mode == "blob" )
		user.client_mob() << "Under directive 7-10, SS13 is quarantined until further notice."
		return

	world << "\blue <B>Alert: The emergency shuttle has been called. It will arrive in T-10:00 minutes.</B>"
	if (!( ticker.timeleft ))
		ticker.timeleft = 6000
	ticker.timing = 1
	return

/proc/cancel_call_proc(var/mob/user)
	if ((!( ticker ) || ticker.shuttle_location == 1 || ticker.timing == 0 || ticker.timeleft < 300))
		return
	if( ticker.mode == "blob" )
		return

	world << "\blue <B>Alert: The shuttle is going back!</B>"
	ticker.timing = -1.0

	return
