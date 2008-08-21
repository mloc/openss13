/obj/item/weapon/t_scanner/attack_self(mob/user)

	on = !on
	icon_state = "t-scanner[on]"

	if(on)
		src.process()


/obj/item/weapon/t_scanner/proc/process()

	while(on)
		for(var/turf/T in range(1, src.loc) )

			if(!T.intact)
				continue

			for(var/obj/O in T.contents)

				if(O.level != 1)
					continue

				if(O.invisibility == 101)
					O.invisibility = 0
					spawn(10)
						if(O)
							var/turf/U = O.loc
							if(U.intact)
								O.invisibility = 101

			var/mob/human/M = locate() in T
			if(M && M.invisibility == 2)
				M.invisibility = 0
				spawn(2)
					if(M)
						M.invisibility = 2


		sleep(10)



// test flashlight object
/obj/item/weapon/flashlight/attack_self(mob/user)

	on = !on
	icon_state = "flight[on]"
	if(on)
		src.process()

/obj/item/weapon/flashlight/proc/process()
	lastHolder = null

	while(on)
		var/atom/holder = loc
		var/isHeld = 0
		if (ismob(holder))
			isHeld=1
		else
			isHeld=0
			if (lastHolder!=null)
				lastHolder:luminosity = 0
				lastHolder = null
		if (isHeld==1)
			if (holder!=lastHolder && lastHolder!=null)
				lastHolder:luminosity = 0
			holder:luminosity = 5
			lastHolder = holder

		luminosity = 5

		sleep(10)
	if (lastHolder!=null)
		lastHolder:luminosity = 0
		lastHolder = null
	luminosity = 0;



//Filter Attackby Procs

//Remove & Replace cover

/obj/item/weapon/filter/attackby(obj/item/weapon/W, mob/user)
	if ( istype(W, /obj/item/weapon/screwdriver))
		if (src.cover == 1)		//If its closed
			if (src.ftype == src.oftype)		//If the filter is operating normaly.
				user.show_message("\blue You unscrew the protective cover.")
				src.cover = 0
				src.icon_state="filter[src.ftype]open"		//Set its operating open state.
				src.add_fingerprint(user)
			else
				user.show_message("\blue You unscrew the protective cover.")		//If it's malfunctioning.
				src.cover = 0
				src.icon_state="filter5open"		//Set malfunctioning open state.
				src.add_fingerprint(user)
		else		//If its open.
			if (src.ftype == src.oftype)		//If the filter is operating normaly.
				src.icon_state="regulatorfilter[src.ftype]"		//Set its operating closed state.
				user.show_message("\blue You carefully screw on the protective cover")
				src.cover = 1
				src.add_fingerprint(user)
			else		//If the filter is malfunctioning.
				src.icon_state="regulatorfilter5"		//Set malfunctioning closed state.
				user.show_message("\blue You carefully screw on the protective cover")
				src.cover = 1
				src.add_fingerprint(user)



//Cut & Mend wires

	else
		if ( istype(W, /obj/item/weapon/wirecutters))
			if (src.cover == 1)
				return
			else
				if (src.ftype == src.oftype)
					src.icon_state="filter5open"
					src.name = "Malfunctioning Filter"
					src.desc = "A malfunctioning Air Filter.  Filters nothing."
					user.show_message("\blue You cut the safety wires.  Gases will now bypass the filter.")
					src.ftype = 5
					src.add_fingerprint(user)
				else
					src.icon_state="filter[src.oftype]open"
					src.name = src.oname
					src.desc = src.odesc
					user.show_message("\blue You mend the safety wires.  The filter will now work as it should.")
					src.ftype = src.oftype
					src.add_fingerprint(user)


//Special process for Filter Type 5 AKA: Malfunctioning Filter.
//These objects are only spawned when taken out of a vent, since a Type 5 at first is actually just it's original object
//with a changed name, desc, and filter type.

//Remove & Replace cover

/obj/item/weapon/filter/filtertype5/attackby(obj/item/weapon/W, mob/user)
	if ( istype(W, /obj/item/weapon/screwdriver))
		if (src.cover == 1)
			user.show_message("\blue You unscrew the protective cover.")
			src.cover = 0
			src.icon_state="filter5open"
			src.add_fingerprint(user)
		else
			src.icon_state="regulatorfilter5"
			user.show_message("\blue You carefully screw on the protective cover")
			src.cover = 1
			src.add_fingerprint(user)

//Cut & Mend wires

	else
		if ( istype(W, /obj/item/weapon/wirecutters))
			if (src.cover == 1)
				return
			else
				if (src.oftype == 1)
					var/obj/item/weapon/filter/filtertype1/I = new(src.loc)
					I.icon_state = "filter1open"
					I.cover = 0
				if (src.oftype == 2)
					var/obj/item/weapon/filter/filtertype2/I = new(src.loc)
					I.icon_state = "filter2open"
					I.cover = 0
				if (src.oftype == 3)
					var/obj/item/weapon/filter/filtertype3/I = new(src.loc)
					I.icon_state = "filter3open"
					I.cover = 0
				if (src.oftype == 4)
					var/obj/item/weapon/filter/filtertype4/I = new(src.loc)
					I.icon_state = "filter4open"
					I.cover = 0
				user.show_message("\blue You mend the safety wires.  The filter will now work as it should.")
				del (src)

