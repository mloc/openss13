
// the power cell
// charge from 0 to 100%
// fits in PDU to provide backup power

/obj/item/weapon/cell/New()
	..()

	charge = charge * maxcharge/100.0		// map obj has charge as percentage, convert to real value here

	spawn(5)
		updateicon()


/obj/item/weapon/cell/proc/updateicon()

	if(maxcharge == 1000)
		icon_state = "cell"
	else
		icon_state = "hpcell"

	overlays = null

	if(charge < 0.01)
		return
	else if(charge/maxcharge >=0.995)
		overlays += image('power.dmi', "cell-o2")
	else
		overlays += image('power.dmi', "cell-o1")

/obj/item/weapon/cell/proc/percent()		// return % charge of cell
	return 100.0*charge/maxcharge

/obj/item/weapon/cell/examine()
	set src in view(1)
	if(usr && !usr.stat)
		if(maxcharge == 1000)
			usr << "[desc]\nThe charge meter reads [round(src.percent() )]%."
		else
			usr << "A high-capacity rechargable electrochemical power cell.\nThe charge meter reads [round(src.percent() )]%."



// the power cable object

/obj/cable/New()
	..()


	// ensure d1 & d2 reflect the icon_state for entering and exiting cable

	var/dash = findtext(icon_state, "-")

	d1 = text2num( copytext( icon_state, 1, dash ) )

	d2 = text2num( copytext( icon_state, dash+1 ) )

	var/turf/T = src.loc			// hide if turf is not intact

	if(level==1) hide(T.intact)


/obj/cable/Del()		// called when a cable is deleted

	if(!defer_powernet_rebuild)	// set if network will be rebuilt manually

		if(netnum && powernets && powernets.len >= netnum)		// make sure cable & powernet data is valid
			var/datum/powernet/PN = powernets[netnum]
			PN.cut_cable(src)									// updated the powernets
	else
		if(Debug) world.log << "Defered cable deletion at [x],[y]: #[netnum]"
	..()													// then go ahead and delete the cable

/obj/cable/hide(var/i)

	invisibility = i ? 101 : 0
	updateicon()

/obj/cable/proc/updateicon()
	if(invisibility)
		//icon_state = "[d1]-[d2]"
		//icon -= rgb(0,0,0,128)
		icon_state = "[d1]-[d2]-f"
	else
		//icon = initial(icon)
		icon_state = "[d1]-[d2]"


/obj/cable/attackby(obj/item/weapon/W, mob/user)

	var/turf/T = src.loc
	if(T.intact)
		return

	if(istype(W, /obj/item/weapon/wirecutters))

		if(src.d1)	// 0-X cables are 1 unit, X-X cables are 2 units long
			new/obj/item/weapon/cable_coil(T, 2)
		else
			new/obj/item/weapon/cable_coil(T, 1)

		for(var/mob/O in viewers(src, null))
			O.show_message("[user] cuts the cable.", 1)

		shock(user, 50)

		defer_powernet_rebuild = 0		// to fix no-action bug
		del(src)

		return	// not needed, but for clarity


	else if(istype(W, /obj/item/weapon/cable_coil))
		var/obj/item/weapon/cable_coil/coil = W

		coil.cable_join(src, user)
		//note do shock in cable_join
	else
		shock(user, 10)

	src.add_fingerprint(user)

// shock the user with probability prb

/obj/cable/proc/shock(mob/user, prb)

	if(!netnum)		// unconnected cable is unpowered
		return 0

	return src.electrocute(user, prb, netnum)


atom/proc/electrocute(mob/user, prb, netnum)

	if(!prob(prb))
		return 0

	if(!netnum)		// unconnected cable is unpowered
		return 0

	var/datum/powernet/PN			// find the powernet
	if(powernets && powernets.len >= netnum)
		PN = powernets[netnum]

	if(PN && PN.avail > 0)		// is it powered?
		var/prot = 0

		if(istype(user, /mob/human))
			var/mob/human/H = user
			if(H.gloves)
				var/obj/item/weapon/clothing/gloves/G = H.gloves

				prot = G.elec_protect
		else if (istype(user, /mob/ai))
			return 0
		
		if(prot == 10)		// elec insulted gloves protect completely
			return 0

		prot++

		var/obj/effects/sparks/O = new /obj/effects/sparks( src.loc )
		O.dir = pick(NORTH, SOUTH, EAST, WEST)
		spawn( 0 )
			O.Life()

		if(PN.avail > 10000)
			user.burn(5e7/prot)

		user << "\red <B>You feel a powerful shock course through your body!</B>"
		sleep(1)

		user.stunned = 120/prot
		user.weakened = 20/prot
		//Foreach goto(72)
		for(var/mob/M in hearers(src, null))
			if(M == user)
				continue
			if (!( M.blinded ))
				M << text("\red [user.name] was shocked by the [src.name]!")
			else
				M << "\red You hear a heavy electrical crack."
		return 1
	return 0


/obj/cable/ex_act(severity)

	switch(severity)
		if(1.0)
			del(src)
		if(2.0)
			if (prob(50))
				new/obj/item/weapon/cable_coil(src.loc, src.d1 ? 2 : 1)
				del(src)

		if(3.0)
			if (prob(25))
				new/obj/item/weapon/cable_coil(src.loc, src.d1 ? 2 : 1)
				del(src)
		else
	return

/obj/cable/burn(fi_amount)

	if(fi_amount > 1800000)
		var/turf/T = src.loc
		if(!T.intact)
			if(prob(10))
				defer_powernet_rebuild = 0
				del(src)




// the cable coil object, used for laying cable

/obj/item/weapon/cable_coil/New(loc, length = MAXCOIL)
	src.amount = length
	pixel_x = rand(-2,2)
	pixel_y = rand(-2,2)
	updateicon()
	..(loc)


/obj/item/weapon/cable_coil/proc/updateicon()
	if(amount == 1)
		icon_state = "coil1"
		name = "cable piece"
	else if(amount == 2)
		icon_state = "coil2"
		name = "cable piece"
	else
		icon_state = "coil"
		name = "cable coil"

/obj/item/weapon/cable_coil/examine()
	set src in view(1)

	if(amount == 1)
		usr << "A short piece of power cable."
	else if(amount == 1)
		usr << "A piece of power cable."
	else
		usr << "A coil of power cable. There are [amount] lengths of cable in the coil."



/obj/item/weapon/cable_coil/attackby(obj/item/weapon/W, mob/user)

	if( istype(W, /obj/item/weapon/wirecutters) && src.amount > 1)
		src.amount--
		new/obj/item/weapon/cable_coil(user.loc, 1)
		user << "You cut a piece off the cable coil."
		src.updateicon()
		return

	else if( istype(W, /obj/item/weapon/cable_coil) )
		var/obj/item/weapon/cable_coil/C = W
		if(C.amount == MAXCOIL)
			user << "The coil is too long, you cannot add any more cable to it."
			return

		if( (C.amount + src.amount <= MAXCOIL) )
			C.amount += src.amount
			user << "You join the cable coils together."
			C.updateicon()
			del(src)
			return

		else
			user << "You transfer [MAXCOIL - src.amount ] length\s of cable from one coil to the other."
			src.amount -= (MAXCOIL-C.amount)
			src.updateicon()
			C.amount = MAXCOIL
			C.updateicon()
			return



/obj/item/weapon/cable_coil/proc/use(var/used)
	if(src.amount < used)
		return 0
	else if (src.amount == used)
		del(src)
	else
		amount -= used
		updateicon()
		return 1



// called when cable_coil is clicked on a turf/station/floor

/obj/item/weapon/cable_coil/proc/turf_place(turf/station/floor/F, mob/user)

	if(!isturf(user.loc))
		return

	if(get_dist(F,user) > 1)
		user << "You can't lay cable at a place that far away."
		return

	if(F.intact)		// if floor is intact, complain
		user << "You can't lay cable there unless the floor tiles are removed."
		return

	else
		var/dirn

		if(user.loc == F)
			dirn = user.dir			// if laying on the tile we're on, lay in the direction we're facing
		else
			dirn = get_dir(F, user)

		for(var/obj/cable/LC in F)
			if(LC.d1 == dirn || LC.d2 == dirn)
				user << "There's already a cable at that position."
				return

		var/obj/cable/C = new(F)
		C.d1 = 0
		C.d2 = dirn
		C.add_fingerprint(user)
		C.updateicon()
		C.update_network()
		use(1)
		//src.laying = 1
		//last = C


// called when cable_coil is click on an installed obj/cable

/obj/item/weapon/cable_coil/proc/cable_join(obj/cable/C, mob/user)


	var/turf/U = user.loc
	if(!isturf(U))
		return

	var/turf/T = C.loc

	if(!isturf(T) || T.intact)		// sanity checks, also stop use interacting with T-scanner revealed cable
		return

	if(get_dist(C, user) > 1)		// make sure it's close enough
		user << "You can't lay cable at a place that far away."
		return


	if(U == T)		// do nothing if we clicked a cable we're standing on
		return		// may change later if can think of something logical to do

	var/dirn = get_dir(C, user)

	if(C.d1 == dirn || C.d2 == dirn)		// one end of the clicked cable is pointing towards us
		if(U.intact)						// can't place a cable if the floor is complete
			user << "You can't lay cable there unless the floor tiles are removed."
			return
		else
			// cable is pointing at us, we're standing on an open tile
			// so create a stub pointing at the clicked cable on our tile

			var/fdirn = turn(dirn, 180)		// the opposite direction

			for(var/obj/cable/LC in U)		// check to make sure there's not a cable there already
				if(LC.d1 == fdirn || LC.d2 == fdirn)
					user << "There's already a cable at that position."
					return

			var/obj/cable/NC = new(U)
			NC.d1 = 0
			NC.d2 = fdirn
			NC.add_fingerprint()
			NC.updateicon()
			NC.update_network()
			use(1)
			C.shock(user, 25)

			return
	else if(C.d1 == 0)		// exisiting cable doesn't point at our position, so see if it's a stub
							// if so, make it a full cable pointing from it's old direction to our dirn

		var/nd1 = C.d2	// these will be the new directions
		var/nd2 = dirn

		if(nd1 > nd2)		// swap directions to match icons/states
			nd1 = dirn
			nd2 = C.d2


		for(var/obj/cable/LC in T)		// check to make sure there's no matching cable
			if(LC == C)			// skip the cable we're interacting with
				continue
			if(LC.d1 == nd1 || LC.d2 == nd1 || LC.d1 == nd2 || LC.d2 == nd2)	// make sure no cable matches either direction
				user << "There's already a cable at that position."
				return
		C.shock(user, 25)
		del(C)
		var/obj/cable/NC = new(T)
		NC.d1 = nd1
		NC.d2 = nd2
		NC.add_fingerprint()
		NC.updateicon()
		NC.update_network()

		use(1)

		return


// called when a new cable is created
// can be 1 of 3 outcomes:
// 1. Isolated cable (or only connects to isolated machine) -> create new powernet
// 2. Joins to end or bridges loop of a single network (may also connect isolated machine) -> add to old network
// 3. Bridges gap between 2 networks -> merge the networks (must rebuild lists also)



/obj/cable/proc/update_network()
	// easy way: do /makepowernets again
	makepowernets()
	// do things more logically if this turns out to be too slow
	// may just do this for case 3 anyway (simpler than refreshing list)







// the powernet datum
// each contiguous network of cables & nodes


// rebuild all power networks from scratch

/proc/makepowernets()

	var/netcount = 0
	powernets = list()

	for(var/obj/cable/PC in world)
		PC.netnum = 0
	for(var/obj/machinery/power/M in machines)
		if(M.netnum >=0)
			M.netnum = 0


	for(var/obj/cable/PC in world)
		if(!PC.netnum)
			PC.netnum = ++netcount

			if(Debug) world.log << "Starting mpn at [PC.x],[PC.y] ([PC.d1]/[PC.d2]) #[netcount]"
			powernet_nextlink(PC, PC.netnum)

	if(Debug) world.log << "[netcount] powernets found"

	for(var/L = 1 to netcount)
		var/datum/powernet/PN = new()
		//PN.tag = "powernet #[L]"
		powernets += PN
		PN.number = L


	for(var/obj/cable/C in world)
		var/datum/powernet/PN = powernets[C.netnum]
		PN.cables += C

	for(var/obj/machinery/power/M in machines)
		if(M.netnum<=0)		// APCs have netnum=-1 so they don't count as network nodes directly
			continue

		M.powernet = powernets[M.netnum]
		M.powernet.nodes += M





// returns a list of all power-related objects (nodes, cable, junctions) in turf,
// excluding source, that match the direction d
// if unmarked==1, only return those with netnum==0

/proc/power_list(var/turf/T, var/source, var/d, var/unmarked=0)
	var/list/result = list()
	var/fdir = (!d)? 0 : turn(d, 180)	// the opposite direction to d (or 0 if d==0)

	for(var/obj/machinery/power/P in T)
		if(P.netnum < 0)	// exclude APCs
			continue

		if(P.directwired)	// true if this machine covers the whole turf (so can be joined to a cable on neighbour turf)
			if(!unmarked || !P.netnum)
				result += P
		else if(d == 0)		// otherwise, need a 0-X cable on same turf to connect
			if(!unmarked || !P.netnum)
				result += P


	for(var/obj/cable/C in T)
		if(C.d1 == fdir || C.d2 == fdir)
			if(!unmarked || !C.netnum)
				result += C

	result -= source

	return result


/obj/cable/proc/get_connections()

	var/list/res = list()	// this will be a list of all connected power objects

	var/turf/T
	if(!d1)
		T = src.loc		// if d1=0, same turf as src
	else
		T = get_step(src, d1)

	res += power_list(T, src , d1, 1)

	T = get_step(src, d2)

	res += power_list(T, src, d2, 1)

	return res




/proc/powernet_nextlink(var/obj/O, var/num)

	var/list/P

	//world.log << "start: [O] at [O.x].[O.y]"


	while(1)

		if( istype(O, /obj/cable) )
			var/obj/cable/C = O

			C.netnum = num

		else if( istype(O, /obj/machinery/power) )

			var/obj/machinery/power/M = O

			M.netnum = num


		if( istype(O, /obj/cable) )
			var/obj/cable/C = O

			P = C.get_connections()

		else if( istype(O, /obj/machinery/power) )

			var/obj/machinery/power/M = O

			P = M.get_connections()

		if(P.len == 0)
			//world.log << "end1"
			return

		O = P[1]


		for(var/L = 2 to P.len)

			powernet_nextlink(P[L], num)

		//world.log << "next: [O] at [O.x].[O.y]"







// cut a powernet at this cable object

/datum/powernet/proc/cut_cable(var/obj/cable/C)

	var/turf/T1 = C.loc
	if(C.d1)
		T1 = get_step(C, C.d1)

	var/turf/T2 = get_step(C, C.d2)

	var/list/P1 = power_list(T1, C, C.d1)	// what joins on to cut cable in dir1

	var/list/P2 = power_list(T2, C, C.d2)	// what joins on to cut cable in dir2

	if(Debug)
		for(var/obj/O in P1)
			world.log << "P1: [O] at [O.x] [O.y] : [istype(O, /obj/cable) ? "[O:d1]/[O:d2]" : null] "
		for(var/obj/O in P2)
			world.log << "P2: [O] at [O.x] [O.y] : [istype(O, /obj/cable) ? "[O:d1]/[O:d2]" : null] "



	if(P1.len == 0 || P2.len ==0)			// if nothing in either list, then the cable was an endpoint
											// no need to rebuild the powernet, just remove cut cable from the list
		cables -= C
		if(Debug) world.log << "Was end of cable"
		return

	// zero the netnum of all cables & nodes in this powernet

	for(var/obj/cable/OC in cables)
		OC.netnum = 0
	for(var/obj/machinery/power/OM in nodes)
		OM.netnum = 0


	// remove the cut cable from the network
	C.netnum = -1
	C.loc = null
	cables -= C




	powernet_nextlink(P1[1], number)		// propagate network from 1st side of cable, using current netnum

	// now test to see if propagation reached to the other side
	// if so, then there's a loop in the network

	var/notlooped = 0
	for(var/obj/O in P2)
		if( istype(O, /obj/machinery/power) )
			var/obj/machinery/power/OM = O
			if(OM.netnum != number)
				notlooped = 1
				break
		else if( istype(O, /obj/cable) )
			var/obj/cable/OC = O
			if(OC.netnum != number)
				notlooped = 1
				break

	if(notlooped)

		// not looped, so make a new powernet

		var/datum/powernet/PN = new()
		//PN.tag = "powernet #[L]"
		powernets += PN
		PN.number = powernets.len

		if(Debug) world.log << "Was not looped: spliting PN#[number] ([cables.len];[nodes.len])"

		for(var/obj/cable/OC in cables)

			if(!OC.netnum)		// non-connected cables will have netnum==0, since they weren't reached by propagation

				OC.netnum = PN.number
				cables -= OC
				PN.cables += OC		// remove from old network & add to new one

		for(var/obj/machinery/power/OM in nodes)
			if(!OM.netnum)
				OM.netnum = PN.number
				OM.powernet = PN
				nodes -= OM
				PN.nodes += OM		// same for power machines

		if(Debug)
			world.log << "Old PN#[number] : ([cables.len];[nodes.len])"
			world.log << "New PN#[PN.number] : ([PN.cables.len];[PN.nodes.len])"

	else
		if(Debug)
			world.log << "Was looped."
		//there is a loop, so nothing to be done
		return

	return



/datum/powernet/proc/reset()
	load = newload
	newload = 0
	avail = newavail
	newavail = 0


	viewload = 0.8*viewload + 0.2*load

	viewload = round(viewload)

	var/numapc = 0

	for(var/obj/machinery/power/terminal/term in nodes)
		if( istype( term.master, /obj/machinery/power/apc ) )
			numapc++

	if(numapc)
		perapc = avail/numapc

	netexcess = avail - load

	if( netexcess > 100)		// if there was excess power last cycle
		for(var/obj/machinery/power/smes/S in nodes)	// find the SMESes in the network
			S.restore()				// and restore some of the power that was used



