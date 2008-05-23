/obj/machinery/computer/security/New()
	..()
	if(!maplevel)
		src.verbs -= /obj/machinery/computer/security/verb/station_map

/obj/machinery/computer/security/attack_paw(var/mob/user as mob)

	return src.attack_hand(user)
	return

/obj/machinery/computer/security/attack_hand(var/mob/user as mob)

	if(stat & (NOPOWER|BROKEN) ) return

	var/list/L = list(  )
	user.machine = src
	for(var/obj/machinery/camera/C in world)
		if (C.network == src.network)
			L[text("[][]", C.c_tag, (C.status ? null : " (Deactivated)"))] = C
		//Foreach goto(31)
	L["Cancel"] = "Cancel"
	var/t = input(user, "Which camera should you change to?") as null|anything in L

	if(!t)
		user.machine = null
		return 0

	var/obj/machinery/camera/C = L[t]
	if (t == "Cancel")
		user.machine = null
		return 0
	if ((get_dist(user, src) > 1 || user.machine != src || user.blinded || !( user.canmove ) || !( C.status )))
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

	if ((get_dist(user, src) > 1 || !( user.canmove ) || user.blinded || !( src.current ) || !( src.current.status )))
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
		//Foreach goto(15)
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

/turf/space/attackby(obj/item/weapon/tile/T as obj, mob/user as mob)

	if (istype(T, /obj/item/weapon/tile))
		T.build(src)
		T.amount--
		T.add_fingerprint(user)
		if (T.amount < 1)
			user.u_equip(T)
			//SN src = null
			del(T)
			return
	return

/turf/space/updatecell()

	return

/turf/space/conduction()
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
								return
						return
					return 0
	if (src.x <= 2)
		if (src.z >= 10)
			if (world.maxz < 10)
				world.maxz++
				A.z++
			else
				A.z = 9
		else
			A.z++
		A.x = world.maxx - 2
		spawn( 0 )
			if ((A && A.loc))
				A.loc.Entered(A)
			return
	else
		if (A.x >= (world.maxx - 1) )
			if (A.z > 3)
				A.z--
			else
				A.z = 1
			A.x = 3
			spawn( 0 )
				if ((A && A.loc))
					A.loc.Entered(A)
				return
		else
			spawn( 5 )
				if ((A && !( A.anchored ) && A.loc == src))
					if (step(A, A.last_move))
					else
						spawn( 0 )
							src.Entered(A)
							return
				return
	return
