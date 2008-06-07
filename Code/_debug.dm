// NOTE WELL!
// Only include this file when debugging locally
// Do not include in release versions


#define VARSICON 1
#define SDEBUG 1

/turf/verb/Flow()
	set category = "Debug"
	//set hidden = 1

	for(var/turf/T in range(5))

		var/obj/mark/O = locate(/obj/mark/, T)

		if(!O)
			O = new /obj/mark(T)
		else
			O.overlays = null

		var/obj/move/OM = locate(/obj/move/, T)

		if(OM)

			if(! OM.updatecell)
				O.icon_state = "x2"
			else
				O.icon_state = "blank"

			for(var/atom/U in OM.FindTurfs() )
				var/dirn = get_dir(OM, U)
				if(dirn == 1)
					O.overlays += image('mark.dmi', OM.airdir==1?"up":"fup")
				else if(dirn == 2)
					O.overlays += image('mark.dmi', OM.airdir==2?"dn":"fdn")
				else if(dirn == 4)
					O.overlays += image('mark.dmi', OM.airdir==4?"rt":"frt")
				else if(dirn == 8)
					O.overlays += image('mark.dmi', OM.airdir==8?"lf":"flf")

		else

			if(!(T.updatecell))
				O.icon_state = "x2"
			else
				O.icon_state = "blank"

			if(T.airN)
				O.overlays += image('mark.dmi', T.airdir==1?"up":"fup")

			if(T.airS)
				O.overlays += image('mark.dmi', T.airdir==2?"dn":"fdn")

			if(T.airW)
				O.overlays += image('mark.dmi', T.airdir==8?"lf":"flf")

			if(T.airE)
				O.overlays += image('mark.dmi', T.airdir==4?"rt":"frt")


			if(T.condN)
				O.overlays += image('mark.dmi', T.condN == 1?"yup":"rup")

			if(T.condS)
				O.overlays += image('mark.dmi', T.condS == 1?"ydn":"rdn")

			if(T.condE)
				O.overlays += image('mark.dmi', T.condE == 1?"yrt":"rrt")

			if(T.condW)
				O.overlays += image('mark.dmi', T.condW == 1?"ylf":"rlf")


/turf/verb/Clear()
	set category = "Debug"
	//set hidden = 1
	for(var/obj/mark/O in world)
		del(O)


/proc/numbericon(var/tn as text,var/s = 0)

	var/image/I = image('mark.dmi', "blank")

	if(lentext(tn)>8)
		tn = "*"

	var/len = lentext(tn)

	for(var/d = 1 to lentext(tn))


		var/char = copytext(tn, len-d+1, len-d+2)

		if(char == " ")
			continue

		var/image/ID = image('mark.dmi', char)

		ID.pixel_x = -(d-1)*4
		ID.pixel_y = s
		//if(d>1) I.Shift(WEST, (d-1)*8)

		I.overlays += ID



	return I


/turf/verb/Stats()
	set category = "Debug"
	for(var/turf/T in range(5))

		var/obj/mark/O = locate(/obj/mark/, T)

		if(!O)
			O = new /obj/mark(T)
		else
			O.overlays = null


		var/temp = round(T.temp-T0C, 0.1)

		O.overlays += numbericon("[temp]C")

		var/pres = round(T.tot_gas() / CELLSTANDARD * 100, 0.1)

		O.overlays += numbericon("[pres]", -8)
		O.mark = "[temp]/[pres]"


/turf/verb/Pipes()
	set category = "Debug"

	for(var/turf/T in range(6))

		//world << "Turf [T] at ([T.x],[T.y])"

		for(var/obj/machinery/M in T)
			//world <<" Mach [M] with pdir=[M.p_dir]"

			if(M && M.p_dir)

				//world << "Accepted"
				var/obj/mark/O = locate(/obj/mark/, T)

				if(!O)
					O = new /obj/mark(T)
				else
					O.overlays = null

				if(istype(M, /obj/machinery/pipes))
					var/obj/machinery/pipes/P = M
					O.overlays += numbericon("[plines.Find(P.pl)]    ", -20)
					M = P.pl


				var/obj/substance/gas/G = M.get_gas()

				if(G)

					var/cap = round( 100*(G.tot_gas()/ M.capmult / 6e6), 0.1)
					var/temp = round(G.temperature - T0C, 0.1)
					O.overlays += numbericon("[temp]C", 0)
					O.overlays += numbericon("[cap]", -8)

				break

/turf/verb/Cables()
	set category = "Debug"

	for(var/turf/T in range(6))

		//world << "Turf [T] at ([T.x],[T.y])"

		var/obj/mark/O = locate(/obj/mark/, T)

		if(!O)
			O = new /obj/mark(T)
		else
			O.overlays = null

		var/marked = 0
		for(var/obj/M in T)
			//world <<" Mach [M] with pdir=[M.p_dir]"


			if(M && istype(M, /obj/cable/))


				var/obj/cable/C = M
				//world << "Accepted"

				O.overlays += numbericon("[C.netnum]  " ,  marked)

				marked -= 8

			else if(M && istype(M, /obj/machinery/power/))

				var/obj/machinery/power/P = M
				O.overlays += numbericon("*[P.netnum]  " ,  marked)
				marked -= 8

		if(!marked)
			del(O)

/turf/verb/Solar()
	set category = "Debug"

	for(var/turf/T in range(6))

		//world << "Turf [T] at ([T.x],[T.y])"

		var/obj/mark/O = locate(/obj/mark/, T)

		if(!O)
			O = new /obj/mark(T)
		else
			O.overlays = null


		var/obj/machinery/power/solar/S

		S = locate(/obj/machinery/power/solar, T)

		if(S)

			O.overlays += numbericon("[S.obscured]  " ,  0)
			O.overlays += numbericon("[round(S.sunfrac*100,0.1)]  " ,  -12)

		else
			del(O)

/mob/verb/Showports()
	set category = "Debug"

	var/turf/T
	var/obj/machinery/pipes/P
	var/list/ndirs

	for(var/obj/machinery/pipeline/PL in plines)

		var/num = plines.Find(PL)

		P = PL.nodes[1]		// 1st node in list
		ndirs = P.get_node_dirs()

		T = get_step(P, ndirs[1])

		var/obj/mark/O = new(T)

		O.overlays += numbericon("[num] * 1  ", -4)
		O.overlays += numbericon("[ndirs[1]] - [ndirs[2]]",-16)


		P = PL.nodes[PL.nodes.len]	// last node in list

		ndirs = P.get_node_dirs()
		T = get_step(P, ndirs[2])

		O = new(T)

		O.overlays += numbericon("[num] * 2  ", -4)
		O.overlays += numbericon("[ndirs[1]] - [ndirs[2]]", -16)

/atom/verb/delete()
	set category = "Debug"
	set src in view()

	del(src)


/area/verb/dark()
	set category = "Debug"

	if(src.icon_state == "dark")
		icon_state = null
	else
		icon_state = "dark"

/area/verb/power()
	set category = "Debug"

	power_equip = !power_equip
	power_environ = !power_environ

	world << "Power ([src]) = [power_equip]"

	power_change()

// *****RM
/mob/verb/Jump(var/area/A in world)
	set category = "Debug"
	set desc = "Area to jump to"
	set src = usr

	var/list/L = list()

	for(var/turf/T in A)
		if(!T.density)
			var/clear = 1
			for(var/obj/O in T)
				if(O.density)
					clear = 0
					break
			if(clear)
				L+=T

	src.loc = pick(L)

// *****


/mob/verb/ShowPlasma()
	set category = "Debug"
	Plasma()

/mob/verb/Blobcount()
	set category = "Debug"
	world << "Blob count: [blobs.len]"


/mob/verb/Blobkill()
	set category = "Debug"
	blobs = list()
	world << "Blob killed."

/mob/verb/Blobmode()
	set category = "Debug"
	world << "Event=[ticker.event]"
	world << "Time =[(ticker.event_time - world.realtime)/10]s"

/mob/verb/Blobnext()
	set category = "Debug"
	ticker.event_time = world.realtime


/mob/verb/callshuttle()
	set category = "Debug"
	ticker.timeleft = 300
	ticker.timing = 1

/mob/verb/apcs()
	set category = "Debug"
	for(var/obj/machinery/power/apc/APC in world)
		world << APC.report()

/mob/verb/Globals()
	set category = "Debug"

	debugobj = new()

	debugobj.debuglist = list( powernets, plines, vote, config, admins, ticker, SS13_airtunnel, sun )


	world << "<A href='?src=\ref[debugobj];Vars=1'>Debug</A>"
	/*for(var/obj/O in plines)

		world << "<A href='?src=\ref[O];Vars=1'>[O.name]</A>"
	*/

/mob/verb/Debug()
	set category = "Debug"
	Debug = !Debug

	world << "Debugging [Debug ? "On" : "Off"]"


/mob/verb/Mach()
	set category = "Debug"

	var/n = 0
	for(var/obj/machinery/M in world)
		n++
		if(! (M in machines) )
			world << "[M] [M.type]: not in list"

	world << "in world: [n]; in list:[machines.len]"


/mob/verb/air()
	set category = "Debug"

	Air()

/proc/Air()


	var/area/A = locate(/area/airintake)

	var/atot = 0
	for(var/turf/T in A)
		atot += T.tot_gas()

	var/ptot = 0
	for(var/obj/machinery/pipeline/PL in plines)
		if(PL.suffix == "d")
			ptot += PL.ngas.tot_gas()

	var/vtot = 0
	for(var/obj/machinery/atmoalter/V in machines)
		if(V.suffix == "d")
			vtot += V.gas.tot_gas()

	var/ctot = 0
	for(var/obj/machinery/connector/C in machines)
		if(C.suffix == "d")
			ctot += C.ngas.tot_gas()


	var/tot = atot + ptot + vtot + ctot

	world.log << "A=[num2text(atot,10)] P=[num2text(ptot,10)] V=[num2text(vtot,10)] C=[num2text(ctot,10)] :  Total=[num2text(tot,10)]"

/mob/verb/Revive()
	set category = "Debug"

	fireloss = 0
	toxloss = 0
	bruteloss = 0
	oxyloss = 0
	paralysis = 0
	stunned = 0
	weakened = 0
	health = 100
	if(stat > 1) stat=0
	disabilities = initial(disabilities)
	sdisabilities = initial(sdisabilities)
	for(var/obj/item/weapon/organ/external/e in src)
		e.brute_dam = 0.0
		e.burn_dam = 0.0
		e.bandaged = 0.0
		e.wound_size = 0.0
		e.max_damage = initial(e.max_damage)
		e.update_icon()
	if(src.type == /mob/human)
		var/mob/human/H = src
		H.UpdateDamageIcon()


/mob/verb/Smoke()
	set category = "Debug"

	var/obj/effects/smoke/O = new /obj/effects/smoke( src.loc )
	O.dir = pick(NORTH, SOUTH, EAST, WEST)
	spawn( 0 )
		O.Life()

/proc/Plasma()

	var/mplas = 0

	for(var/obj/machinery/M in machines)
		if(M.suffix=="dbgp")

			var/obj/substance/gas/G = M.get_gas()
			var/p = G.plasma

			mplas += p

			world.log << "[M]=[num2text(p, 10)]  \..."


	var/tplas = 0

	for(var/turf/station/engine/floor/T in world)
		tplas += T.poison

	world.log << "\nTotals: M=[num2text(mplas, 10)] T=[num2text(tplas, 10)], all = [num2text(mplas+tplas, 10)]"

//Pops up the take-off / put-on dialog, but for yourself.
/mob/human/proc/ShowMyInv()
	src.show_inv(src)
