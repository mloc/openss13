/obj/portal
	anchored = 1.0
	density = 1
	icon = 'stationobjs.dmi'
	icon_state = "portal"
	name = "portal"
	var/obj/target = null
	
	New()
		spawn(300) del(src)
	
	Bumped(atom/movable/M)
		spawn(0) src.teleport(M)

	HasEntered(atom/movable/AM)
		spawn(0) src.teleport(AM)

	proc/teleport(atom/movable/M)
		if (M.anchored)
			return
		if (src.icon_state == "portal1")
			return
		if (!(src.target))
			del(src)
			return
		var/obj/effects/sparks/O = new /obj/effects/sparks(src.target)
		O.dir = pick(1, 2, 4, 8)
		spawn(0)
			O.Life()
			return
		if (istype(M, /atom/movable))
			var/tx = src.target.x + rand(-5.0, 5)
			var/ty = src.y + rand(-5.0, 5)
			if (prob(10))
				src.icon_state = "portal1"
				if (ismob(M))
					M.ex_act(2)
				else
					M.ex_act(1)
			if (rand(1, 1000) <= 10)
				if (istype(M, /mob))
					M:client_mob() << ("\red You see a fainting blue light.")
				M.loc = null
			else
				M.loc = locate(tx, ty, src.target.z)
				
