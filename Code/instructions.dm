
/obj/begin/verb/ready()
	set src in usr.loc


	if ((!( istype(usr, /mob/human) ) || usr.start))
		usr << "You have already started!"
		return
	var/mob/human/M = usr
	src.get_dna_ready(M)
	if ((!( M.w_uniform ) && !( ticker )))
		if (M.gender == "female")
			M.w_uniform = new /obj/item/weapon/clothing/under/pink( M )
		else
			M.w_uniform = new /obj/item/weapon/clothing/under/blue( M )
		M.w_uniform.layer = 20
		M.shoes = new /obj/item/weapon/clothing/shoes/brown( M )
		M.shoes.layer = 20
	else
		M << "You will have to find clothes from the station."
	if ((ticker && !( M.l_hand )))
		var/obj/item/weapon/card/id/I = new /obj/item/weapon/card/id( M )
		var/list/L = list( "Technical Assistant", "Research Assistant", "Staff Assistant", "Medical Assistant" )
		var/choose
		if (L.Find(M.occupation1))
			choose = M.occupation1
		else
			choose = pick(L)
		switch(choose)
			if("Research Assistant")
				I.assignment = "Research Assistant"
				I.registered = M.rname
				I.access_level = 1
				I.lab_access = 1
				I.engine_access = 0
				I.air_access = 0
			if("Technical Assistant")
				I.assignment = "Technical Assistant"
				I.registered = M.rname
				I.access_level = 1
				I.lab_access = 0
				I.engine_access = 0
				I.air_access = 1
			if("Medical Assistant")
				I.assignment = "Medical Assistant"
				I.registered = M.rname
				I.access_level = 1
				I.lab_access = 1
				I.engine_access = 0
				I.air_access = 0
			if("Staff Assistant")
				I.assignment = "Staff Assistant"
				I.registered = M.rname
				I.access_level = 2
				I.lab_access = 0
				I.engine_access = 0
				I.air_access = 0
			else
		I.name = text("[]'s ID Card ([]>[]-[]-[])", I.registered, I.access_level, I.lab_access, I.engine_access, I.air_access)
		I.layer = 20
		M.l_hand = I
	M.start = 1
	M.update_face()
	M.update_body()
	return

/obj/begin/verb/enter()
	set src in usr.loc

	if(config.loggame) world.log << "GAME: [usr.key] entered as [usr.name]"

	if (!( enter_allowed ))
		usr << "\blue There is an administrative lock on entering the game!"
		return
	if ((!( usr.start ) || !( istype(usr, /mob/human) )))
		usr << "\blue <B>You aren't ready! Use the ready verb on this pad to set up your character!</B>"
		return
	if (ctf)
		var/obj/rogue = locate("landmark*CTF-rogue")
		usr.loc = rogue.loc
		usr << "<B>It's CTF mode. You are a late joiner so you are a Rogue!</B>"
		usr << "\blue Now teleporting."
		if (ticker)
			var/mob/H = usr
			if (istype(H, /mob/human))
				reg_dna[text("[]", H.primary.uni_identity)] = H.rname
		return
	var/mob/human/M = usr
	var/list/start_loc = list(  )

	var/area/A = locate(/area/arrival/start)
	var/list/L = list(  )
	for(var/turf/T in A)
		if(T.isempty())
			L += T
		//Foreach goto(239)
	start_loc["SS13"] = pick(L)



	if (locate(text("spstart[]", M.ckey)))
		for(var/obj/sp_start/S in world)
			if (S.tag == text("spstart[]", M.ckey))
				start_loc[text("[]", S.desc)] = S
			//Foreach goto(295)
	var/option = input(M, "Where should you start?", "Start Selector", null) in start_loc
	if (usr==null)
		return
	if ((!( usr.start ) || !( istype(usr, /mob/human) ) || usr.loc != src.loc))
		return
	if (ticker)
		reg_dna[text("[]", M.primary.uni_identity)] = M.rname
	var/obj/sp_start/S = start_loc[option]
	if (istype(S, /obj/sp_start))
		M << "\blue Now teleporting to special location."
		if (S.special == 2)
			for(var/obj/O in M)
				//O = null
				del(O)
				//Foreach goto(492)
			M.loc = S.loc
		else
			if (S.special == 3)
				for(var/obj/O in M)
					//O = null
					del(O)
					//Foreach goto(560)
				var/obj/O = new /mob/monkey( S.loc )
				M.client.mob = O
				O.loc = S.loc
				//M = null
				del(M)
			else
				M.loc = S.loc		//was O.loc
	else
		if (isturf(S))
			M << "\blue Now teleporting."
			M.loc = S
	return

/obj/begin/proc/get_dna_ready(var/mob/user as mob)

	var/mob/human/M = user
	if (!( M.primary ))
		M.r_hair = M.nr_hair
		M.b_hair = M.nb_hair
		M.g_hair = M.ng_hair
		M.s_tone = M.ns_tone
		var/t1 = rand(1000, 1500)
		dna_ident += t1
		if (dna_ident > 65536.0)
			dna_ident = rand(1, 1500)
		M.primary = new /obj/dna( null )
		M.primary.uni_identity = text("[]", add_zero(num2hex(dna_ident), 4))
		var/t2 = add_zero(num2hex(M.nr_hair), 2)
		M.primary.uni_identity = text("[][]", M.primary.uni_identity, t2)
		t2 = add_zero(num2hex(M.ng_hair), 2)
		M.primary.uni_identity = text("[][]", M.primary.uni_identity, t2)
		t2 = add_zero(num2hex(M.nb_hair), 2)
		M.primary.uni_identity = text("[][]", M.primary.uni_identity, t2)
		t2 = add_zero(num2hex(M.r_eyes), 2)
		M.primary.uni_identity = text("[][]", M.primary.uni_identity, t2)
		t2 = add_zero(num2hex(M.g_eyes), 2)
		M.primary.uni_identity = text("[][]", M.primary.uni_identity, t2)
		t2 = add_zero(num2hex(M.b_eyes), 2)
		M.primary.uni_identity = text("[][]", M.primary.uni_identity, t2)
		t2 = add_zero(num2hex( -M.ns_tone + 35), 2)
		M.primary.uni_identity = text("[][]", M.primary.uni_identity, t2)
		t2 = (M.gender == "male" ? text("[]", num2hex(rand(1, 124))) : text("[]", num2hex(rand(127, 250))))
		if (length(t2) < 2)
			M.primary.uni_identity = text("[]0[]", M.primary.uni_identity, t2)
		else
			M.primary.uni_identity = text("[][]", M.primary.uni_identity, t2)
		M.primary.spec_identity = "5BDFE293BA5500F9FFFD500AAFFE"
		M.primary.struc_enzyme = "CDE375C9A6C25A7DBDA50EC05AC6CEB63"
		if (rand(1, 3125) == 13)
			M.need_gl = 1
			M.be_epil = 1
			M.be_cough = 1
			M.be_tur = 1
			M.be_stut = 1

		var/b_vis
		if (M.need_gl)
			b_vis = add_zero(text("[]", num2hex(rand(10, 1400))), 3)
			M.disabilities = M.disabilities | 1
			M << "\blue You need glasses!"
		else
			b_vis = "5A7"
		var/epil
		if (M.be_epil)
			epil = add_zero(text("[]", num2hex(rand(10, 1400))), 3)
			M.disabilities = M.disabilities | 2
			M << "\blue You are epileptic!"
		else
			epil = "6CE"
		var/cough
		if (M.be_cough)
			cough = add_zero(text("[]", num2hex(rand(10, 1400))), 3)
			M.disabilities = M.disabilities | 4
			M << "\blue You have a chronic coughing syndrome!"
		else
			cough = "EC0"
		var/Tourette
		if (M.be_tur)
			epil = add_zero(text("[]", num2hex(rand(10, 1400))), 3)
			M.disabilities = M.disabilities | 8
			M << "\blue You have Tourette syndrome!"
		else
			Tourette = "5AC"
		var/stutter
		if (M.be_stut)
			stutter = add_zero(text("[]", num2hex(rand(10, 1400))), 3)
			M.disabilities = M.disabilities | 16
			M << "\blue You have a stuttering problem!"
		else
			stutter = "A50"
		M.primary.struc_enzyme = text("CDE375C9A6C2[]DBD[][][][]B63", b_vis, stutter, cough, Tourette, epil)
		M.primary.use_enzyme = "493DB249EB6D13236100A37000800AB71"
		M.primary.n_chromo = 28
	return

/turf/station/command/floor/updatecell()

	src.oxygen = O2STANDARD
	src.firelevel = 0
	src.co2 = 0
	src.poison = 0
	src.sl_gas = 0
	src.n2 = N2STANDARD
	return

/turf/station/command/conduction()
	return

/turf/station/command/floor/attack_paw(user as mob)

	return src.attack_hand(user)
	return

/turf/station/command/floor/attack_hand(var/mob/user as mob)

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
