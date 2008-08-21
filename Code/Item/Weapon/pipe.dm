/*
 *	Pipe item
 * 	used in constrction of pipe system; can be carried, moved, rotated, unlike static pipes
 * 	can be laid on or underfloor; when welded, is added to the static pipe network
 */


obj/item/weapon/pipe
	name = "pipe"
	icon = 'pipe-item.dmi'
	icon_state = "straight"
	flags = TABLEPASS|DRIVABLE|FPRINT
	w_class = 3
	s_istate = "pipe"
	level = 2
	var/ptype = 0	// the type of pipe item:
					// 0	  1			   2			3				4			  5			 6			7		8
					//"pipe", "bent pipe", "h/e pipe", "bent h/e pipe", "connector", "manifold", "junction"	vent	inlet


	// create a new pipe

	New()
		..()

		update()

	//update the name and icon of the pipe item depending on the type

	proc/update()
		var/list/nlist = list("pipe", "bent pipe", "h/e pipe", "bent h/e pipe", "connector", "manifold", "junction", "vent", "inlet")
		name = nlist[ptype+1] + " fitting"
		updateicon()

	//update the icon of the item

	proc/updateicon()

		var/list/islist = list("straight", "bend", "he-straight", "he-bend", "connector", "manifold", "junction", "vent", "inlet")

		icon_state = islist[ptype + 1]

		if(invisibility)				// true if placed under floor
			icon -= rgb(0,0,0,128)		// fade the icon
		else
			icon = initial(icon)		// otherwise reset to inital icon


	// called to hide or unhide a pipe
	// i=true if hiding

	hide(var/i)

		invisibility = i ? 101 : 0		// make hidden pipe items invisible
		updateicon()


	//called when a turf is attacked with a pipe item
	// place the pipe on the turf, setting pipe level to 1 (underfloor) if the turf is not intact

	proc/turf_place(turf/T, mob/user)

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


	// called when the item is dropped

	dropped(mob/user)
		src.anchored = 0	// set unanchored if dropped manually. Will be set anchored if placed (above)


	// rotate the pipe item clockwise

	verb/rotate()
		set src in view(1)

		if ( usr.stat || usr.restrained() )
			return

		var/turf/T = src.loc
		if(isturf(T) && T.intact && level==1)		// if the pipe is underfloor, don't rotate
			return						// incase the pipe has been revaled with a t-scanner

		src.dir = turn(src.dir, -90)
		return

	// returns the p_dir from the pipe item type and dir

	proc/get_pdir()

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
			if(4,7,8)
				return dir
			if(5)
				return dir|cw|acw
			if(6)
				return flip

		return 0

	// return the h_dir (heat-exchange pipes) from the type and the dir

	proc/get_hdir()

		var/flip = turn(dir, 180)
		var/cw = turn(dir, -90)

		switch(ptype)
			if(0,1,4,5,7,8)
				return 0
			if(2)
				return dir|flip
			if(3)
				return dir|cw
			if(6)
				return dir

		return 0

	/*
	// test verb
	// increment through the various pipe types

	verb/inc()
		set src in view(1)

		ptype = (ptype+1)%9
		update()
	*/

	// attack with welding tool to lay the pipe

	attackby(obj/item/weapon/W, mob/user)

		var/turf/T = src.loc
		if(!isturf(T))						// only do anything when located on a turf
			return

		if(T.intact && level==1)		// if the pipe is underfloor and floor is in place, don't interact
			return						// in case the pipe has been revealed with a t-scanner

		var/pipedir = src.get_pdir()|src.get_hdir()		// all possible pipe dirs including h/e

		if (istype(W, /obj/item/weapon/weldingtool) )
			var/obj/item/weapon/weldingtool/WT = W
			if (WT.welding && WT.weldfuel>=0)


				for(var/obj/machinery/M in T)		// check to make sure no other pipes conflit with this one

					if(M.level == src.level)		// only on same level
						if( (M.p_dir & pipedir) || (M.h_dir & pipedir) )	// matches at least one direction on either type of pipe
							user.client_mob() << "There is already a pipe at that location and position."
							return

				for(var/obj/brokenpipe/BP in T)		// check for broken pipes
					if(BP.level == src.level)
						if(BP.p_dir & pipedir)
							user.client_mob() << "The broken pipe needs to be removed first."
							return

				// no conflicts found
				WT.weldfuel--

				sleep(10)

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

					if(8)		// inlet
						var/obj/machinery/inlet/I = new(T)
						I.dir = src.dir
						I.p_dir = src.dir
						I.level = level

						I.buildnodes()

						setlineterm(I.node, I.vnode)

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

	proc/setlineterm(var/obj/machinery/node, var/obj/machinery/vnode)

		if(vnode)
			if( istype(vnode, /obj/machinery/pipeline) )


				var/obj/machinery/pipeline/PL = vnode
				node.buildnodes(PL)
				PL.setterm()
			else
				node.buildnodes()


	// set the type and orientation of a pipe fitting to the same as the pipe object it is being created from

	proc/settype(var/obj/machinery/M)

		if(istype(M, /obj/machinery/pipes))					// is a type of pipe

			ptype = 0									// the base pipe type
			var/pipedir = M.p_dir
			if(istype(M, /obj/machinery/pipes/heat_exch))	//if a h/e pipe
				pipedir = M.h_dir							// pipedirs form h_dir
				ptype = 2								// base pipetype is 2

			switch(pipedir)			// find the pipe orientation and type from the pipe dirs
				if(3)				// straight N-S
					dir = SOUTH
				if(12)				// straight E-W
					dir = EAST
				if(5)				// bent N-E
					dir = NORTH
					ptype++
				if(6)				// bent E-S
					dir = EAST
					ptype++
				if(10)				// bent S-W
					dir = SOUTH
					ptype++
				if(9)				// bent W-N
					dir = WEST
					ptype++
		else if(istype(M, /obj/machinery/connector))
			ptype = 4
			dir = M.dir
		else if(istype(M, /obj/machinery/manifold))
			ptype = 5
			dir = M.dir
		else if(istype(M, /obj/machinery/junction))
			ptype = 6
			dir = M.h_dir		// junction h/e pipe is always in object direction
		else if(istype(M, /obj/machinery/vent))
			ptype = 7
			dir = M.dir
		else if(istype(M, /obj/machinery/inlet))
			ptype = 8
			dir = M.dir


		update()
