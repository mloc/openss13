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



// pipe item
// used in constrction of pipe system; can be carried, moved, rotated, unlike static pipes
// does not carry gas at this time

/obj/item/weapon/pipe/New()
	..()

	update()

//update the name and icon of the pipe item depending on the type

/obj/item/weapon/pipe/proc/update()
	var/list/nlist = list("pipe", "bent pipe", "h/e pipe", "bent h/e pipe", "connector", "manifold", "junction", "vent")
	name = nlist[ptype+1] + " fitting"
	updateicon()

//update the icon of the item

/obj/item/weapon/pipe/proc/updateicon()

	var/list/islist = list("straight", "bend", "he-straight", "he-bend", "connector", "manifold", "junction", "vent")

	icon_state = islist[ptype + 1]

	if(invisibility)				// true if placed under floor
		icon -= rgb(0,0,0,128)		// fade the icon
	else
		icon = initial(icon)		// otherwise reset to inital icon

// called to hide or unhide a pipe
// i=true if hiding

/obj/item/weapon/pipe/hide(var/i)

	invisibility = i ? 101 : 0		// make hidden pipe items invisible
	updateicon()


//called when a turf is attacked with a pipe item
// place the pipe on the turf, setting pipe level to 1 (underfloor) if the turf is not intact

/obj/item/weapon/pipe/proc/turf_place(turf/T, mob/user)

	if(!isturf(user.loc))
		return

	if(get_dist(T,user) > 1)
		user.client_mob() << "You can't lay pipe at a place that far away."
		return

	if(!T.intact && (ptype == 2 || ptype == 3 || ptype == 6) )
		user.client_mob() << "That type of pipe cannot be laid under the floor."
		return


	user.drop_item()		// drop the pipe at the user's feet
	src.loc = T

	level = 2		// defaults to above floor laying

	if(!T.intact)
		level = 1		// if floor is not intact, make a low-level pipe

	anchored = 1		// anchor the item so that it can't be dragged around if placed
						// otherwise able to drag underfloor pipes into intact turfs


// called when an item is dropped

/obj/item/weapon/pipe/dropped(mob/user)
	src.anchored = 0	// set unanchored if dropped manually. Will be set anchored if placed (above)


// rotate the pipe item clockwise

/obj/item/weapon/pipe/verb/rotate()
	set src in view(1)

	if ( usr.stat || usr.restrained() )
		return

	var/turf/T = src.loc
	if(isturf(T) && T.intact && level==1)		// if the pipe is underfloor, don't rotate
		return						// incase the pipe has been revaled with a t-scanner

	src.dir = turn(src.dir, -90)
	return

// returns the p_dir from the pipe item type and dir

/obj/item/weapon/pipe/proc/get_pdir()

	var/flip = turn(dir, 180)
	var/cw = turn(dir, -90)
	var/acw = turn(dir, 90)

	switch(ptype)
		if(0)
			return dir|flip
		if(1)
			return dir|cw
		if(2,3)
			return 0
		if(4,7)
			return dir
		if(5)
			return dir|cw|acw
		if(6)
			return flip

	return 0

// return the h_dir (heat-exchange pipes) from the type and the dir

/obj/item/weapon/pipe/proc/get_hdir()

	var/flip = turn(dir, 180)
	var/cw = turn(dir, -90)

	switch(ptype)
		if(0,1,4,5,7)
			return 0
		if(2)
			return dir|flip
		if(3)
			return dir|cw
		if(6)
			return dir

	return 0

// test verb

/obj/item/weapon/pipe/verb/inc()
	set src in view(1)

	ptype = (ptype+1)%8
	update()

/obj/item/weapon/pipe/attackby(obj/item/weapon/W, mob/user)

	var/turf/T = src.loc
	if(T.intact && level==1)		// if the pipe is underfloor, don't interact
		return						// in case the pipe has been revealed with a t-scanner

	var/pipedir = src.get_pdir()|src.get_hdir()		// all possible pipe dirs including h/e

	if (istype(W, /obj/item/weapon/weldingtool) )
		var/obj/item/weapon/weldingtool/WT = W
		if (WT.welding && WT.weldfuel>=0)
			WT.weldfuel--

			for(var/obj/machinery/M in T)		// check to make sure no other pipes conflit with this one

				if(M.level == src.level)		// only on same level
					if( (M.p_dir & pipedir) || (M.h_dir & pipedir) )	// matches at least one direction on either type of pipe
						user.client_mob() << "There is already a pipe at that location and position."
						return


			// no conflicts found

			// 0	  1			   2			3				4			  5			 6			7
			//"pipe", "bent pipe", "h/e pipe", "bent h/e pipe", "connector", "manifold", "junction"	vent

			var/obj/machinery/pipes/P

			switch(ptype)
				if(0,1)		// straight or bent pipe
					P = new/obj/machinery/pipes(T)

					P.icon_state = "[pipedir]"
					P.level = level
					P.update()
					P.updateicon()

					var/list/dirs = P.get_dirs()

					P.node1 = get_machine(P.level, P.loc, dirs[1])
					P.node2 = get_machine(P.level, P.loc, dirs[2])

				if(2,3)		// straight or bent h/e pipe
					P = new/obj/machinery/pipes/heat_exch(T)
					P.icon_state = "[pipedir]"
					P.level = 2
					P.update()
					P.updateicon()

					var/list/dirs = P.get_dirs()

					P.node1 = get_he_machine(P.level, P.loc, dirs[1])
					P.node2 = get_he_machine(P.level, P.loc, dirs[2])

				if(4)		// connector
					var/obj/machinery/connector/C = new(T)
					C.dir = src.dir
					C.p_dir = src.dir
					C.level = level

					C.buildnodes()

					setlineterm(C.node, C.vnode)


				if(5)		//manifold
					var/obj/machinery/manifold/M = new(T)
					M.dir = dir
					M.p_dir = pipedir
					M.level = level
					M.buildnodes()
					setlineterm(M.node1, M.vnode1)
					setlineterm(M.node2, M.vnode2)
					setlineterm(M.node3, M.vnode3)

				if(6)		//junctions
					var/obj/machinery/junction/J = new(T)
					J.dir = dir
					J.p_dir = src.get_pdir()
					J.h_dir = src.get_hdir()
					J.level = 2

					J.buildnodes()
					setlineterm(J.node1, J.vnode1)
					setlineterm(J.node2, J.vnode2)

				if(7)		// vent
					var/obj/machinery/vent/V = new(T)
					V.dir = src.dir
					V.p_dir = src.dir
					V.level = level

					V.buildnodes()

					setlineterm(V.node, V.vnode)


			// for pipe objects, now do updating of pipelines if needed
			switch(ptype)
				if(0,1,2,3)		// new regular or or h/e pipe

					// number of pipes connected to P
					var/pipecon =  (P.node1 && P.node1.ispipe()) + (P.node2 && P.node2.ispipe())

					if(Debug) world << "Pipecon [pipecon]"

					if(!pipecon)		// simplest case - no connection pipes (but may be machines)
						var/obj/machinery/pipeline/PL = new()	// create a new pipeline
						P.buildnodes(PL)				// set new pipe to use new pl
						PL.nodes += P					// and add it
						PL.numnodes = 1
						PL.capmult = 2
						plines += PL					// and new pipeline to the global list
						PL.setterm()					// and ensure any connections to machines are made
						PL.name = "pipeline #[plines.Find(PL)]"		// set the name

					else if(pipecon == 1)		// single connected pipe

						var/obj/machinery/pipes/CP		// the connected pipe

						if(P.node1 && P.node1.ispipe())	// find the connected pipe
							CP = P.node1
						else
							CP = P.node2

						var/obj/machinery/pipeline/PL = CP.pl	// the pipeline we connected to

						P.buildnodes(PL)			// set the pipeline and nodes of any adjoining pipes

						if(PL.nodes[1] == CP)		// if the connected pipe is at start of line nodes list
							PL.nodes.Insert(1, P)	// insert new pipe into start of node list
						else
							PL.nodes += P			// otherwise, insert it at end
						PL.numnodes++
						PL.capmult++
						PL.setterm()				// connect to any machines

						CP.termination = 0			// connected pipe no longer terminal

					else //(pipecon==2)

						var/obj/machinery/pipes/CP1 = P.node1
						var/obj/machinery/pipes/CP2 = P.node2

						var/obj/machinery/pipeline/PL1 = CP1.pl
						var/obj/machinery/pipeline/PL2 = CP2.pl

						if(PL1 == PL2)		// special case - completing a loop
							// make sure to check if this works properly
							P.buildnodes(PL1)

							PL1.nodes += P
							PL1.numnodes++
							PL1.capmult++
							PL1.setterm()

							CP1.termination = 0
							CP2.termination = 0

							PL1.vnode1 = PL1		// link pipeline to self
							PL1.vnode2 = PL1

						else		// separate pipelines

							P.buildnodes(PL1)

							CP1.termination = 0
							CP2.termination = 0

							var/list/plist
							if(PL1.nodes[1] == CP1)
								plist = pipelist(null, PL1.nodes[PL1.nodes.len])
							else
								plist = pipelist(null, PL1.nodes[1])

							PL1.gas.transfer_from(PL2.gas, -1)
							PL1.ngas.transfer_from(PL2.ngas, -1)

							plines -= PL2
							for(var/obj/machinery/pipes/OP in PL2.nodes)
								OP.pl = PL1

							PL1.nodes = plist
							PL1.numnodes = plist.len
							PL1.capmult = plist.len+1


							PL1.setterm()

							del(PL2)



			del(src)	// remove the pipe item

	return


// ensure that setterm() is called for a newly connected pipeline

/proc/setlineterm(var/obj/machinery/node, var/obj/machinery/vnode)

	if(vnode)
		if( istype(vnode, /obj/machinery/pipeline) )


			var/obj/machinery/pipeline/PL = vnode
			node.buildnodes(PL)
			PL.setterm()
		else
			node.buildnodes()


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

