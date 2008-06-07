/*
 *	Pod -- escape pod.
 *
 *	Pilotable object that can carry people and other objects
 *
 *	TODO: Work out whats going on at low speeds <=10 in process()
 *  TODO: Limit the capcity of the pod in some way - current carrying capacity is infinite
 *        Could use a simple count or based on item weight, w_class, etc.
 */

obj/machinery/pod
	name = "Escape Pod"
	icon = 'escapepod.dmi'
	icon_state = "pod"
	density = 1
	flags = FPRINT|DRIVABLE
	anchored = 1

	var
		id = 1.0					// Not used
		speed = 10.0				// The current speed, in tiles per second, roughly
		capacity = null				// Not used


	// Timed process
	// Move the pod depending on its speed and direction

	process()
		if (src.speed)
			if (src.speed <= 10)					// at low speed
				var/t1 = 10 - src.speed				// very odd - step (with delay) an inverse number of times?
				//var t1 = speed					// consider replacing with this - much more controllable! - Hobnob
				while(t1 > 0)
					step(src, src.dir)
					sleep(1)
					t1--
			else									// at high speed
				var/t1 = round(src.speed / 5)		// step speed/5 times per process
				while(t1 > 0)
					step(src, src.dir)
					t1--


	// Called when pod bumps into something
	// Set the speed to zero

	Bump(var/atom/A)
		spawn( 0 )
			..()
			src.speed = 0


	// Called when client attempts to move, and is inside a pod
	// direction is the direction key the client used

	relaymove(mob/user, direction)

		if (user.stat)
			return
		if ((user in src))							// make sure player is inside this pod

			if (direction & 1)						// North pressed
				src.speed = max(src.speed - 1, 1)	// slow down to minimum speed (1)

			else if (direction & 2)					// South pressed
				src.speed++							// Increase speed up to maximum (10)
				if (src.speed > 10)
					src.speed = 10
			if (direction & 4)						// East pressed
				src.dir = turn(src.dir, -90.0)		// Turn clockwise

			else if (direction & 8)					// West pressed
				src.dir = turn(src.dir, 90)			// Turn anticlockwise



	// Pod Verbs


	// Eject from pod - place player behind pod and restore view

	//I left these all as regular .client since the verbs won't work if the mob doesn't have the client anyhow (a remote-controlled mob with no client won't be able to use the verbs). --shadowlord13

	verb/eject()
		set src = usr.loc

		if (usr.stat)
			return
		var/mob/M = usr
		M.loc = src.loc
		if (M.client)
			M.client.eye = M.client.mob
			M.client.perspective = MOB_PERSPECTIVE
		step(M, turn(src.dir, 180))


	// Board the pod - place player inside the pod and set the view to follow the pod

	verb/board()
		set src in oview(1)

		if (usr.stat)
			return
		var/mob/M = usr
		if (M.client)
			M.client.perspective = EYE_PERSPECTIVE
			M.client.eye = src
		M.loc = src
		return


	// Load pod - whatever the player is pulling gets loaded into the pod (including other players)

	verb/load()
		set src in oview(1)

		if (usr.stat)
			return
		if (( ( istype(usr, /mob/human) ) && (!( ticker ) || (ticker && ticker.mode != "monkey"))))
			var/mob/human/H = usr

			if ((H.pulling && !( H.pulling.anchored )))

				H.pulling.loc = src

				if (ismob(H.pulling))
					var/mob/M = H.pulling
					if (M.client)
						M.client.perspective = EYE_PERSPECTIVE
						M.client.eye = src
				for(var/mob/O in viewers(src, null))
					if (O.hasClient() && (!( O.blinded )))
						O.client_mob() << text("\blue <B> [] loads [] into []!</B>", H, H.pulling, src)
				H.pulling = null
		return


	// Unload a pod - remove an item or mob from the pod
	// If a client mob, restore their view settings

	verb/unload(var/atom/movable/A in src.contents)
		set src in oview(1)

		if (usr.stat)
			return
		if (istype(A, /atom/movable))
			A.loc = src.loc
			for(var/mob/O in viewers(src, null))
				if (O.hasClient() && (!( O.blinded )))
					O.client_mob() << text("\blue <B> [] unloads [] from []!</B>", usr, A, src)
				//Foreach goto(54)
			if (ismob(A))
				var/mob/M = A
				if (M.client)
					M.client.perspective = MOB_PERSPECTIVE
					M.client.eye = M
			step(A, turn(src.dir, 180))
		return


	// Damage procs

	// Hit by meteor - eject/unload everything from the pod

	meteorhit(var/obj/O)

		if (O.icon_state == "flaming")
			for(var/obj/item/I in src)
				I.loc = src.loc

			for(var/mob/M in src)
				M.loc = src.loc
				if (M.client)
					M.client.eye = M.client.mob
					M.client.perspective = MOB_PERSPECTIVE

			del(src)


	// In explosion - eject everything and destroy pod

	ex_act(severity)
		switch(severity)
			if(1.0)
				for(var/atom/movable/A in src)
					A.loc = src.loc
					A.ex_act(severity)
				del(src)
			if(2.0)
				if (prob(50))
					for(var/atom/movable/A in src)
						A.loc = src.loc
						A.ex_act(severity)
					del(src)


	// Blob attack - eject everything and destroy pod

	blob_act()

		for(var/atom/movable/A in src)
			A.loc = src.loc
		del(src)
