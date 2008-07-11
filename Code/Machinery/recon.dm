/*
 *	Recon -- reconaissance pod
 *
 *	Very similar to escape pods, except can carry only 1 person
 *
 */


obj/machinery/recon
	name = "1-Person Reconaissance Pod"
	icon = 'escapepod.dmi'
	icon_state = "recon"
	density = 1
	flags = FPRINT|DRIVABLE
	anchored = 1
	var
		speed = 1			// the current speed, turfs/second


	// Timed process
	// Move according to current speed and direction

	process()
		if (src.speed)
			if (src.speed <= 10)
				var/t1 = 10 - src.speed				// See note for pod/process()
				// var/t1 = src.speed
				while(t1 > 0)
					step(src, src.dir)
					sleep(1)
					t1--
			else
				var/t1 = round(src.speed / 5)
				while(t1 > 0)
					step(src, src.dir)
					t1--


	// Called when we bump into a dense object
	// Set speed to zero

	Bump()
		spawn( 0 )
			..()
			src.speed = 0


	// Called by client/Move() when player tries to move while inside a recon
	// direction is the key pressed

	relaymove(mob/user, direction)
		if (user.stat)
			return

		if ((user in src))
			if (direction & 1)						// North
				src.speed = max(src.speed - 1, 1)	// Slow down

			else if (direction & 2)					// South
				src.speed++							// Speed up

			if (direction & 4)						// East
				src.dir = turn(src.dir, -90.0)		// Turn clockwise

			else if (direction & 8)					// West
				src.dir = turn(src.dir, 90)			// Turn anticlockwise

			if (direction & 16)						// Centre
				src.speed = 30						// Speed boost
			else
				src.speed = min(src.speed, 10)		// otherwise max speed is 10 turfs/second


	// Recon verbs


	// Eject from the recon, reset view to player

	verb/eject()
		set src = usr.loc

		var/result = src.canReach(usr, null, 1)
		if (result==0)
			usr << "You can't reach [src]."
			return
		var/mob/M = usr
		M.loc = src.loc
		if (M.client)
			M.client.eye = M.client.mob
			M.client.perspective = MOB_PERSPECTIVE


	// Board the recon, set view to follow the object

	verb/board()
		set src in oview(1)

		var/result = src.canReach(usr, null, 1)
		if (result==0)
			usr << "You can't reach [src]."
			return
		if (locate(/mob, src))
			usr.client_mob() << "There is no room! You can only fit one person."
			return
		var/mob/M = usr
		if (M.client)
			M.client.perspective = EYE_PERSPECTIVE
			M.client.eye = src
		M.loc = src


	// Load the recon with the pulled object
	// Note recons can carry only items, unlike escape pobs which can carry any movable object

	verb/load()
		set src in oview(1)

		var/result = src.canReach(usr, null, 1)
		if (result==0)
			usr << "You can't reach [src]."
			return
		if ((( istype(usr, /mob/human) ) && (!( ticker ) || (ticker && ticker.mode != "monkey"))))
			var/mob/human/H = usr
			if ((H.pulling && !( H.pulling.anchored )))
				if (!( istype(H.pulling, /obj/item/weapon) ))
					usr.client_mob() << "You may only place items in."
				else
					if ((locate(/mob, src) && ismob(H.pulling)))
						usr.client_mob() << "There is no room! You can only fit one person."
					else
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


	// Unload an object from the recon
	// If a player, reset the player's view to normal

	verb/unload(atom/movable/A in src)
		set src in oview(1)

		var/result = src.canReach(usr, null, 1)
		if (result==0)
			usr << "You can't reach [src]."
			return
		if (istype(A, /atom/movable))
			A.loc = src.loc
			for(var/mob/O in view(src, null))
				if ((!( O.blinded )))
					O.client_mob() << text("\blue <B> [] unloads [] from []!</B>", usr, A, src)
			if (ismob(A))
				var/mob/M = A
				if (M.client)
					M.client.perspective = MOB_PERSPECTIVE
					M.client.eye = M


	// Damage procs

	// Meteor hit, dump all contents and delete recon

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


	// Explosion, dump all contents and explode them, then delete recon

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


	// Blob attack, dump contents and delete recon

	blob_act()
		for(var/atom/movable/A in src)
			A.loc = src.loc
		del(src)
