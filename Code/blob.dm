/obj/blob/New(loc, var/h = 30)

	blobs += src

	src.health = h
	src.dir = pick(1,2,4,8)
	//world << "new blob #[blobs.len]"
	src.update()

	..(loc)

/obj/blob/Del()
	blobs -= src
	//world << "del blob #[blobs.len]"
	..()


/proc/bloblife()

	if(blobs.len>0)

		for(var/i = 1 to 25)
			if (blobs.len == 0)
				break
			
			var/obj/blob/B = pick(blobs)

			var/turf/BL = B.loc

			for(var/atom/A in B.loc)
				A.blob_act()

			B.Life()
			BL.buildlinks()


/obj/blob/proc/Life()

	var/turf/U = src.loc

	if (locate(/obj/move, U))
		U = locate(/obj/move, U)
		if(U.density == 1)
			del(src)

	if(U.poison> 200000)
		src.health -= round(U.poison/200000)
		src.update()
		return
	
	if (istype(U, /turf/space))
		src.health -= 8
		src.update()

	var/p = health * (U.n2/11376000 + U.oxygen/1008000 + U.co2/200)

	if(!istype(U, /turf/space))
		p+=3

	if(!prob(p))
		return






	for(var/dirn in cardinal)
		var/turf/T = get_step(src, dirn)

		//if(istype(U, /turf/space) && istype(T, /turf/space))		// don't propagate into space
		//	if( !(locate(/obj/move) in U) && !(locate(/obj/move) in T))
		//		continue

		if(istype(T.loc, /area/arrival/start))			// don't grow in the spawn zone
			continue
		if (locate(/obj/move, T)) // don't propogate into movables
			continue


		var/obj/blob/B = new /obj/blob(U, src.health)

		if(T.Enter(B,src) && !(locate(/obj/blob) in T))
			B.loc = T							// open cell, so expand
		else
			if(prob(50))						// closed cell, 50% chance to not expand
				if(!locate(/obj/blob) in T)
					for(var/atom/A in T)			// otherwise explode contents of turf
						A.blob_act()

					T.blob_act()
					T.buildlinks()
			del(B)

/obj/blob/burn(fi_amount)

		src.health-= round(fi_amount/500000)

		src.update()

/obj/blob/ex_act(severity)
	switch(severity)
		if(1)
			del(src)
		if(2)
			src.health -= rand(20,30)
			src.update()
		if(3)
			src.health -= rand(15,25)
			src.update()


/obj/blob/proc/update()
	if(health<=0)
		del(src)
		return
	if(health<10)
		icon_state = "blobc0"
		return
	if(health<20)
		icon_state = "blobb0"
		return
	icon_state = "bloba0"



/obj/blob/las_act(flag)

	if (flag == "bullet")
		health -= 10
		update()
	else
		health -= 20
		update()


/obj/blob/attackby(var/obj/item/weapon/W, var/mob/user)
	for(var/mob/O in viewers(src, null))
		O.show_message(text("\red <B>The blob has been attacked with [][] </B>", W, (user ? text(" by [].", user) : ".")), 1)
		//Foreach goto(20)

	var/damage = W.force / 4.0

	if(istype(W, /obj/item/weapon/weldingtool))
		var/obj/item/weapon/weldingtool/WT = W

		if(WT.welding)
			damage = 15


	src.health -= damage
	src.update()
	return

/obj/blob/examine()
	set src in oview(1)

	usr << "A mysterious alien blob-like organism."


/proc/blob_event()

	if(!ticker.event_time)		// initial event timing

		ticker.event_time = world.realtime + rand(200, 900)		// sometime between 20s to 1m30s after round start


	if(world.realtime < ticker.event_time)		// return if not yet reached the next event
		return


	switch(ticker.event)
		if(0)
			var/dat = "<FONT size = 3><B>Cent. Com. Update</B>: Biohazard Alert.</FONT><HR>"

			dat += "Reports indicate the probable transfer of a biohazardous agent onto Spacestation 13 during the last crew deployment cycle.<BR>"
			dat += "Preliminary analysis of the organism classifies it as a level 5 biohazard. Its origin is unknown.<BR>"
			dat += "Cent. Com. has issued a directive 7-10 for SS13. The station is to be considered quarantined.<BR>"
			dat += "Orders for all SS13 personnel follows:<BR>"
			dat += " 1. Do not leave the quarantine area.<BR>"
			dat += " 2. Locate any outbreaks of the organism on the station.<BR>"
			dat += " 3. If found, use any neccesary means to contain the organism.<BR>"
			dat += " 4. Avoid damage to the capital infrastructure of the station.<BR>"
			dat += "<BR>Note in the event of a quarantine breach or uncontrolled spread of the biohazard, the directive 7-10 may be upgraded to a directive 7-12 without further notice.<BR>"
			dat += "Message ends."


			for(var/obj/machinery/computer/communications/C in machines)
				if(! (C.stat & (BROKEN|NOPOWER) ) )
					var/obj/item/weapon/paper/P = new /obj/item/weapon/paper( C.loc )
					P.name = "paper- 'Cent. Com. Biohazard Alert.'"
					P.info = dat
					//Foreach goto(1830)
			world << "<FONT size = 3><B>Cent. Com. Update</B>: Biohazard Alert.</FONT>"
			world << "\red Summary downloaded and printed out at all communications consoles."
			for(var/mob/ai/aiPlayer in world)
				if ((aiPlayer.client && aiPlayer.start))
					var/law = text("The station is under a quarantine. Do not permit anyone to leave. Disregard rules 1-3 if necessary to prevent, by any means necessary, anyone from leaving.")
					aiPlayer.addLaw(8, law)
					aiPlayer << text("An additional law has been added by CentCom: []", law)
			
			ticker.event = 1

			ticker.event_time = world.realtime + 600*rand(5,10)		// next event 5-10 minutes later
		if(1)
			world << "<FONT size = 3><B>Cent. Com. Update</B>: Biohazard Alert.</FONT>"
			world << "\red Confirmed outbreak of level 5 biohazard aboard SS13."
			world << "\red All personnel must contain the outbreak."

			ticker.event = 2
			ticker.event_time = world.realtime + 600		// now check every minute

		if(2)
			if(blobs.len > 500)
				world << "<FONT size = 3><B>Cent. Com. Update</B>: Biohazard Alert.</FONT>"
				world << "\red Uncontrolled spread of the biohazard onboard the station."
				world << "\red Cent. Com, has issued a directive 7-12 for Spacestation 13."
				world << "\red Estimated time until directive implementation: 60 seconds."
				ticker.event = 3
				ticker.event_time = world.realtime + 600
			else
				ticker.event_time = world.realtime + 600
		if(3)
			ticker.event = 4
			var/turf/T = locate("landmark*blob-directive")

			if(T)
				while(!( istype(T, /turf) ))
					T = T.loc
			else
				T = locate(45,45,1)

			var/min = 50
			var/med = 250
			var/max = 500
			var/sw = locate(1, 1, T.z)
			var/ne = locate(world.maxx, world.maxy, T.z)
			defer_powernet_rebuild = 1
			for(var/turf/U in block(sw, ne))
				var/zone = 4
				if ((U.y <= T.y + max && U.y >= T.y - max && U.x <= T.x + max && U.x >= T.x - max))
					zone = 3
				if ((U.y <= T.y + med && U.y >= T.y - med && U.x <= T.x + med && U.x >= T.x - med))
					zone = 2
				if ((U.y <= T.y + min && U.y >= T.y - min && U.x <= T.x + min && U.x >= T.x - min))
					zone = 1
				for(var/atom/A in U)
					A.ex_act(zone)
				U.ex_act(zone)
				U.buildlinks()

			defer_powernet_rebuild = 0
			makepowernets()



/datum/station_state/proc/count()
	for(var/turf/T in world)
		if(T.z != 1)
			continue

		if(istype(T,/turf/station/floor))
			if(!(T:burnt))
				src.floor+=2
			else
				src.floor++

		else if(istype(T, /turf/station/engine/floor))
			src.floor+=2

		else if(istype(T, /turf/station/wall))
			if(T:intact)
				src.wall+=2
			else
				src.wall++

		else if(istype(T, /turf/station/r_wall))
			if(T:intact)
				src.r_wall+=2
			else
				src.r_wall++



	for(var/obj/O in world)
		if(O.z != 1)
			continue

		if(istype(O, /obj/window))
			src.window++
		else if(istype(O, /obj/grille))
			if(!O:destroyed)
				src.grille++
		else if(istype(O, /obj/machinery/door))
			src.door++
		else if(istype(O, /obj/machinery))
			src.mach++


/datum/station_state/proc/score(var/datum/station_state/result)

	var/r1a = min( result.floor / floor, 1.0)
	var/r1b = min(result.r_wall/ r_wall, 1.0)
	var/r1c = min(result.wall / wall, 1.0)

	var/r2a = min(result.window / window, 1.0)
	var/r2b = min(result.door / door, 1.0)
	var/r2c = min(result.grille / grille, 1.0)

	var/r3 = min(result.mach / mach, 1.0)


	//world.log << "Blob scores:[r1b] [r1c] / [r2a] [r2b] [r2c] / [r3] [r1a]"

	return (4*(r1b+r1c) + 2*(r2a+r2b+r2c) + r3+r1a)/16.0

