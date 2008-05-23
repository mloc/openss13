/*
 *	Sleeper -- allows a mob to be preserved without further damage
 *
 *	/obj/machinery/sleeper -- the sleeper itself
 *
 *	/obj/machinery/computer/sleep_console -- the control console
 *
 *	TODO: Sleepers currently do not use or need power. If altered, need to make the occupant suffer if the power goes out.
 *
 */


/*
 *	The sleeper
 */

obj/machinery/sleeper
	name = "sleeper"
	icon = 'Cryogenic2.dmi'
	icon_state = "sleeper_0"
	density = 1
	anchored = 1
	var
		mob/occupant = null				// the mob in the sleeper, or null if none


	// Eject verb
	// Remove the occupant from the sleeper

	verb/eject()
		set src in oview(1)

		if (usr.stat != 0)
			return
		src.go_out()
		add_fingerprint(usr)


	// Move inside verb
	// Insert the mob you are pulling into the sleeper
	// Sleeper must be empty, and mob cannot be wearing anything

	verb/move_inside()
		set src in oview(1)

		if (usr.stat != 0)
			return
		if (src.occupant)
			usr << "\blue <B>The sleeper is already occupied!</B>"
			return
		if (usr.abiotic())
			usr << "Subject may not have abiotic items on."
			return
		usr.pulling = null
		usr.client.perspective = EYE_PERSPECTIVE
		usr.client.eye = src
		usr.loc = src
		src.occupant = usr
		src.icon_state = "sleeper_1"
		for(var/obj/O in src)
			del(O)

		src.add_fingerprint(usr)


	// Attack by item
	// Only used for the grab pseudo-item, places the grabbed mob in the sleeper

	attackby(obj/item/weapon/grab/G, mob/user)

		if ((!( istype(G, /obj/item/weapon/grab) ) || !( ismob(G.affecting) )))
			return
		if (src.occupant)
			user << "\blue <B>The sleeper is already occupied!</B>"
			return
		if (G.affecting.abiotic())
			user << "Subject may not have abiotic items on."
			return
		var/mob/M = G.affecting
		if (M.client)
			M.client.perspective = EYE_PERSPECTIVE
			M.client.eye = src
		M.loc = src
		src.occupant = M
		src.icon_state = "sleeper_1"
		for(var/obj/O in src)
			O.loc = src.loc

		src.add_fingerprint(user)

		del(G)


	// Called to remove a mob from the sleeper
	// If a client, reset the view to normal

	proc/go_out()
		if (!( src.occupant ))
			return
		for(var/obj/O in src)
			O.loc = src.loc

		if (src.occupant.client)
			src.occupant.client.eye = src.occupant.client.mob
			src.occupant.client.perspective = MOB_PERSPECTIVE
		src.occupant.loc = src.loc
		src.occupant = null
		src.icon_state = "sleeper_0"


	// Called to inject rejuve chemicals into the occupant
	// Maximum is 60 units

	proc/inject(mob/user)

		if (src.occupant)
			if (src.occupant.rejuv < 60)
				src.occupant.rejuv = 60
			user << text("Occupant now has [] units of rejuvenation in his/her bloodstream.", src.occupant.rejuv)
		else
			user << "No occupant!"


	// Shows the health statistics of the occupant
	// Does not seem to be used?

	proc/check(mob/user)
		if (src.occupant)
			user << "\blue <B>Occupant ([src.occupant]) Statistics:</B>"
			var/t1
			switch(src.occupant.stat)
				if(0.0)
					t1 = "Conscious"
				if(1.0)
					t1 = "Unconscious"
				if(2.0)
					t1 = "*dead*"
				else
			user << "[(src.occupant.health > 50 ? "\blue " : "\red ")]\t Health %: [src.occupant.health] ([t1])"
			user << "[(src.occupant.oxyloss < 60 ? "\blue " : "\red ")]\t -Respiratory Damage %: [src.occupant.oxyloss]"
			user << "[(src.occupant.toxloss < 60 ? "\blue " : "\red ")]\t -Toxin Content %: [src.occupant.toxloss]"
			user << "[(src.occupant.fireloss < 60 ? "\blue " : "\red ")]\t -Burn Severity %: [src.occupant.fireloss]"
			user << "\blue Expected time till occupant can safely awake: (note: If health is below 20% these times are inaccurate)"
			user << "\blue \t [src.occupant.paralysis / 5] second\s (if around 1 or 2 the sleeper is keeping them asleep.)"
		else
			user << "\blue There is no one inside!"
		return


	// Called in mob/Life() while the occupant is inside
	// Sets the health settings of the occupant

	alter_health(mob/M)

		if (M.health > 0)
			if (M.oxyloss >= 10)
				var/amount = max(0.15, 1)
				M.oxyloss -= amount
			else
				M.oxyloss = 0
			M.health = 100 - M.oxyloss - M.toxloss - M.fireloss - M.bruteloss
		M.paralysis -= 4
		M.weakened -= 4
		M.stunned -= 4
		if (M.paralysis <= 1)
			M.paralysis = 3
		if (M.weakened <= 1)
			M.weakened = 3
		if (M.stunned <= 1)
			M.stunned = 3
		if (M.rejuv < 3)
			M.rejuv = 4


	// Explosion damage
	// Chance to remove the occupant and explode them, then delete the sleeper

	ex_act(severity)

		switch(severity)
			if(1.0)
				for(var/atom/movable/A in src)
					A.loc = src.loc
					A.ex_act(severity)
				del(src)
				return
			if(2.0)
				if (prob(50))
					for(var/atom/movable/A in src)
						A.loc = src.loc
						A.ex_act(severity)
					del(src)
					return
			if(3.0)
				if (prob(25))
					for(var/atom/movable/A in src)
						A.loc = src.loc
						A.ex_act(severity)
					del(src)
					return


	// Blob attack, remove the occupant and delete

	blob_act()
		for(var/atom/movable/A in src)
			A.loc = src.loc
		del(src)


  	/* Unused

	allow_drop()
		return 0

 	*/

/*
 * 	The sleep console
 */


obj/machinery/computer/sleep_console
	name = "sleep console"
	icon = 'Cryogenic2.dmi'
	icon_state = "sleeperconsole"
	var
		obj/machinery/sleeper/connected = null			// the associated sleeper


	// Create a new sleep console
	// Locate the connected sleeper 1 step west

	New()
		..()
		spawn( 5 )		// wait for world to finish loading
			src.connected = locate(/obj/machinery/sleeper, get_step(src, WEST))


	// Monkey interact same as human

	attack_paw(mob/user)
		return src.attack_hand(user)

	// Human interact
	// Show the interaction window

	attack_hand(mob/user)
		if (src.connected)
			var/mob/occupant = src.connected.occupant
			var/dat = "<font color='blue'><B>Occupant Statistics:</B></FONT><BR>"
			if (occupant)
				var/t1
				switch(occupant.stat)
					if(0.0)
						t1 = "Conscious"
					if(1.0)
						t1 = "Unconscious"
					if(2.0)
						t1 = "*dead*"
					else
				dat += "[occupant.health > 50 ? "<font color='blue'>" : "<font color='red'>"]\tHealth %: [occupant.health] ([t1])</FONT><BR>"
				dat += "[occupant.oxyloss < 60 ? "<font color='blue'>" : "<font color='red'>"]\t-Respiratory Damage %: [occupant.oxyloss]</FONT><BR>"
				dat += "[occupant.toxloss < 60 ? "<font color='blue'>" : "<font color='red'>"]\t-Toxin Content %: [occupant.toxloss]</FONT><BR>"
				dat += "[occupant.fireloss < 60 ? "<font color='blue'>" : "<font color='red'>"]\t-Burn Severity %: [occupant.fireloss]</FONT><BR>"
				dat += "<BR>Paralysis Summary %: [occupant.paralysis] ([round(occupant.paralysis / 4)] seconds left!)</FONT><BR>"
				dat += "<HR><A href='?src=\ref[src];refresh=1'>Refresh</A><BR><A href='?src=\ref[src];rejuv=1'>Inject Rejuvenators</A>"
			else
				dat += "The sleeper is empty."
			dat += "<BR><BR><A href='?src=\ref[user];mach_close=sleeper'>Close</A>"
			user << browse(dat, "window=sleeper;size=400x500")


	// Handle topic links from interaction window

	Topic(href, href_list)
		..()
		if ((usr.stat || usr.restrained()))
			return
		if ((usr.contents.Find(src) || (get_dist(src, usr) <= 1 && istype(src.loc, /turf))))
			usr.machine = src
			if (href_list["rejuv"])
				if (src.connected)
					src.connected.inject(usr)
			if (href_list["refresh"])
				for(var/mob/M in viewers(1, src))
					if ((M.client && M.machine == src))
						src.attack_hand(M)
					//Foreach goto(123)
			src.add_fingerprint(usr)


	// Timed process - just update interaction window for those viewing

	process()

		for(var/mob/M in viewers(1, src))
			if ((M.client && M.machine == src))
				src.attack_hand(M)


	// Called when area power state changes
	// no change - sleeper works without power
	// Note overrides standard /obj/machinery/computer/power_change()

	power_change()
		return


	// Explosion damage, chance to delete the sleeper console

	ex_act(severity)

		switch(severity)
			if(1.0)
				del(src)

			if(2.0)
				if (prob(50))
					del(src)
