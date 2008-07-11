
/area/turret_protected
	name = "Turret Protected Area"
	var/list/turretTargets = list()

/area/turret_protected/proc/subjectDied(var/mob/target)
	if (istype(target, /mob))
		if (!istype(target, /mob/ai))
			if (target:stat==2)
				if (target in turretTargets)
					src.Exited(target)


/area/turret_protected/Entered(atom/movable/O)
	if (istype(O, /mob))
		if (!istype(O, /mob/ai))
			if (!(O in turretTargets))
				turretTargets += O
			//else
	return 1

/area/turret_protected/Exited(atom/movable/O)
	if (istype(O, /mob))
		if (!istype(O, /mob/ai))
			if (O in turretTargets)
				turretTargets -= O
			//else
			if (turretTargets.len == 0)
				popDownTurrets()

	return 1

/area/turret_protected/proc/popDownTurrets()
	for (var/obj/machinery/turret/aTurret in src)
		aTurret.popDown()


/obj/machinery/turret
	name = "turret"
	icon = 'weap_sat.dmi'
	icon_state = "grey_target_prism"
	var/raised = 0
	var/enabled = 1
	anchored = 1
	layer = 3
	invisibility = 2
	density = 1
	var/lasers = 0
	var/health = 9
	var/obj/machinery/turretcover/cover = null
	var/popping = 0
	var/wasvalid = 0
	var/lastfired = 0
	var/const/shot_delay = 30 //3 seconds between shots


/obj/machinery/turretcover
	name = "pop-up turret cover"
	icon = 'weap_sat.dmi'
	icon_state = "turretCover"
	anchored = 1
	layer = 3.5
	density = 0

/obj/machinery/turret/proc/isPopping()
	return (popping!=0)

/obj/machinery/turret/power_change()
	if(stat & BROKEN)
		icon_state = "grey_target_prism"
	else
		if( powered() )
			if (src.enabled)
				if (src.lasers)
					icon_state = "orange_target_prism"
				else
					icon_state = "target_prism"
			else
				icon_state = "grey_target_prism"
			stat &= ~NOPOWER
		else
			spawn(rand(0, 15))
				src.icon_state = "grey_target_prism"
				stat |= NOPOWER

/obj/machinery/turret/proc/setState(var/enabled, var/lethal)
	src.enabled = enabled
	src.lasers = lethal

	src.power_change()

/obj/machinery/turret/process()
	if(stat & (NOPOWER|BROKEN))
		return
		if(lastfired && world.time - lastfired < shot_delay)
			return
		lastfired = world.time
	if (src.cover==null)
		src.cover = new /obj/machinery/turretcover(src.loc)
	use_power(50)
	var/loc = src.loc
	if (istype(loc, /turf))
		loc = loc:loc
	if (!istype(loc, /area))
		world << text("Badly positioned turret - loc.loc is [].", loc)
		return
	var/area/area = loc
	if (istype(area, /area))
		if (istype(loc, /area/turret_protected))
			src.wasvalid = 1
			var/area/turret_protected/tarea = loc

			if (tarea.turretTargets.len>0)
				if (!isPopping())
					if (isDown())
						popUp()
					else
						var/mob/target = pick(tarea.turretTargets)
						src.dir = get_dir(src, target)
						if (src.enabled)
							if (target.stat!=2)
								src.shootAt(target)
							else
								tarea.subjectDied(target)

		else
			if (src.wasvalid)
				src.die()
			else
				world << text("ERROR: Turret at [], [], [] is NOT in a turret-protected area!", x, y, z)

/obj/machinery/turret/proc/isDown()
	return (invisibility!=0)

/obj/machinery/turret/proc/popUp()
	if ((!isPopping()) || src.popping==-1)
		invisibility = 0
		popping = 1
		if (src.cover!=null)
			flick("popup", src.cover)
			src.cover.icon_state = "openTurretCover"
		spawn(10)
			if (popping==1) popping = 0

/obj/machinery/turret/proc/popDown()
	if ((!isPopping()) || src.popping==1)
		popping = -1
		if (src.cover!=null)
			flick("popdown", src.cover)
			src.cover.icon_state = "turretCover"
		spawn(10)
			if (popping==-1)
				invisibility = 2
				popping = 0


/obj/machinery/turret/proc/shootAt(var/mob/target)
	var/turf/T = loc
	var/atom/U = (istype(target, /atom/movable) ? target.loc : target)
	if ((!( U ) || !( T )))
		return
	while(!( istype(U, /turf) ))
		U = U.loc
	if (!( istype(T, /turf) ))
		return

	var/obj/beam/a_laser/A
	if (src.lasers)
		A = new /obj/beam/a_laser( loc )
		use_power(50)
	else
		A = new /obj/beam/a_laser/s_laser( loc )
		use_power(100)

	if (!( istype(U, /turf) ))
		//A = null
		del(A)
		return
	A.current = U
	A.yo = U.y - T.y
	A.xo = U.x - T.x
	spawn( 0 )
		A.process()
		return
	return

/obj/machinery/turret/las_act(flag)
	if (flag == "bullet")
		src.health -= 3
	if (flag) //taser
		return
		//src.health -= 1
	else
		src.health -= 2

	if (src.health <= 0)
		src.die()
	return

/obj/machinery/turret/ex_act(str)
	src.die()

/obj/machinery/turret/proc/die()
	src.health = 0
	src.density = 0
	src.stat |= BROKEN
	src.icon_state = "destroyed_target_prism"
	//src.icon_state = "explosion"
	if (cover!=null)
		del(cover)
	flick("explosion", src)
	spawn(14)
		del(src)

/obj/machinery/turretid
	name = "Turret deactivation control"
	icon = 'items.dmi'
	icon_state = "motion3"
	anchored = 1
	density = 0
	var/enabled = 1
	var/lethal = 0
	var/locked = 1
	var/access = "5555"
	var/allowed = null

/obj/machinery/turretid/attackby(obj/item/weapon/W, mob/user)
	if(stat & BROKEN) return
	if (istype(user, /mob/ai))
		return src.attack_hand(user)
	else if (istype(W, /obj/item/weapon/card/id) )			// trying to unlock the interface with an ID card
		var/obj/item/weapon/card/id/I = W
		if (I.check_access(access, allowed))
			locked = !locked
			user.client_mob() << "You [ locked ? "lock" : "unlock"] the panel."
			if (locked)
				if (user.machine==src)
					user.machine = null
					user.client_mob() << browse(null, "window=turretid")
			else
				if (user.machine==src)
					src.attack_hand(usr)
		else
			user.client_mob() << "\red Access denied."

/obj/machinery/turretid/attack_ai(mob/user as mob)
	return attack_hand(user)

/obj/machinery/turretid/attack_hand(mob/user as mob)
	if ( (get_dist(src, user) > 1 ))
		if (!istype(user, /mob/ai))
			user.client_mob() << "Too far away."
			user.machine = null
			user.client_mob() << browse(null, "window=turretid")
			return

	user.machine = src
	var/loc = src.loc
	if (istype(loc, /turf))
		loc = loc:loc
	if (!istype(loc, /area))
		user.client_mob() << text("Turret badly positioned - loc.loc is [].", loc)
		return
	var/area/area = loc
	var/t = "<TT><B>Turret Control Panel</B> ([area.name])<HR>"

	if(src.locked && (!istype(user, /mob/ai)))
		t += "<I>(Swipe ID card to unlock control panel.)</I><BR>"
	else
		t += text("Turrets [] - <A href='?src=\ref[];toggleOn=1'>[]?</a><br>\n", src.enabled?"activated":"deactivated", src, src.enabled?"Disable":"Enable")
		t += text("Currently set for [] - <A href='?src=\ref[];toggleLethal=1'>Change to []?</a><br>\n", src.lethal?"lethal":"stun repeatedly", src,  src.lethal?"Stun repeatedly":"Lethal")

	user.client_mob() << browse(t, "window=turretid")

/obj/machinery/turretid/Topic(href, href_list)
	..()
	if (usr.stat || usr.restrained() )
		return
	if (src.locked)
		if (!istype(usr, /mob/ai))
			usr.client_mob() << "Control panel is locked!"
			return
	if (href_list["toggleOn"])
		src.enabled = !src.enabled
		src.updateTurrets()
	else if (href_list["toggleLethal"])
		src.lethal = !src.lethal
		src.updateTurrets()
	src.attack_hand(usr)

/obj/machinery/turretid/proc/updateTurrets()
	if (src.enabled)
		if (src.lethal)
			icon_state = "motion1"
		else
			icon_state = "motion3"
	else
		icon_state = "motion0"

	var/loc = src.loc
	if (istype(loc, /turf))
		loc = loc:loc
	if (!istype(loc, /area))
		world << text("Turret badly positioned - loc.loc is [].", loc)
		return
	var/area/area = loc

	for (var/obj/machinery/turret/aTurret in area)
		aTurret.setState(enabled, lethal)
