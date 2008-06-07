//This has various routines related to the AI.

/mob/ai
	name = "AI"
	icon = 'power.dmi'
	icon_state = "teg"
	gender = MALE
	var/network = "SS13"
	var/obj/machinery/camera/current = null
	var/t_plasma = null
	var/t_oxygen = null
	var/t_sl_gas = null
	var/t_n2 = null
	var/aiRestorePowerRoutine = 0
	var/list/laws = list()
	flags = 258.0
	
	proc/ai_camera_follow(mob/target as mob in world)
		set category = "AI Commands"
		if (usr.stat>0)
			usr << "You are not capable of using the follow camera at this time."
			usr:cameraFollow = null
			return
		else if (usr.currentDrone!=null)
			usr << "You can't use the follow camera while controlling a drone."
			usr:cameraFollow = null
			return
		
		usr:cameraFollow = target
		usr << text("Follow camera mode is now following [].", target.rname)
		if (usr.machine == null)
			usr.machine = usr

		spawn(0)
			while (usr:cameraFollow == target)
				if (usr.machine==null && usr:current==null)
					usr:cameraFollow = null
					usr << "Follow camera mode ended."
					return
				var/obj/machinery/camera/C = usr:current
				if ((C && istype(C, /obj/machinery/camera)) || C==null)
					var/closestDist = -1
					if (C!=null)
						if (C.status)
							closestDist = get_dist(C, target)
					//usr << text("Dist = [] for camera []", closestDist, C.name)
					var/zmatched = 0
					if (closestDist > 7 || closestDist == -1)
						//check other cameras
						var/obj/machinery/camera/closest = C
						for(var/obj/machinery/camera/C2 in world)
							if (C2.network == src.network)
								if (C2.z == target.z)
									zmatched = 1
									if (C2.status)
										var/dist = get_dist(C2, target)
										if ((dist < closestDist) || (closestDist == -1))
											closestDist = dist
											closest = C2
						//usr << text("Closest camera dist = [], for camera []", closestDist, closest.area.name)

						if (closest != C)
							usr:current = closest
							usr.reset_view(closest)
							//use_power(50)
						if (zmatched == 0)
							usr << "Target is not on or near any active cameras on the station. We'll check again in 30 seconds (unless you use the cancel-camera verb)."
							sleep(290) //because we're sleeping another second after this (a few lines down)
				else
					usr << "Follow camera mode ended."
					usr:cameraFollow = null

				sleep(10)

	proc/ai_call_shuttle()
		set category = "AI Commands"
		if (usr.stat>0)
			usr << "You are not capable of calling the shuttle at this time."
			return
		if (!config.ai_can_call_shuttle)
			usr << "Sorry, you can't call the shuttle. The 'AI can call shuttle' setting is disabled on this server."
			return
		call_shuttle_proc(src)
		return

	proc/ai_cancel_call()
		set category = "AI Commands"
		if (usr.stat>0)
			usr << "You are not capable of cancelling the shuttle call at this time."
			return
		if (!config.ai_can_uncall_shuttle)
			usr << "Sorry, you can't send the shuttle back. The 'AI can uncall shuttle' setting is disabled on this server."
			return
		cancel_call_proc(src)
		return

	restrained()
		return 0

	ex_act(severity)
		flick("flash", src.flash)

		var/b_loss = null
		var/f_loss = null
		switch(severity)
			if(1.0)
				if (src.stat != 2)
					b_loss += 100
					f_loss += 100
			if(2.0)
				if (src.stat != 2)
					b_loss += 60
					f_loss += 60
			if(3.0)
				if (src.stat != 2)
					b_loss += 30
			else
				return

	examine()
		set src in oview()

		usr << "\blue *---------*"
		usr << text("\blue This is \icon[] <B>[]</B>!", src, src.name)
		if (src.bruteloss)
			if (src.bruteloss < 30)
				usr << text("\red []'s case looks slightly bashed!", src.name)
			else
				usr << text("\red <B>[]'s case looks severely bashed!</B>", src.name)
		if (src.fireloss)
			if (src.fireloss < 30)
				usr << text("\red [] looks lightly singed!", src.name)
			else
				usr << text("\red <B>[] looks severely burnt!</B>", src.name)
		usr << "\blue *---------*"
		return

	death()
		if (src.currentDrone!=null)
			src.currentDrone:releaseControl()
		if (src.healths)
			src.healths.icon_state = "health5"
		if (src.stat == 2)
			CRASH("/mob/ai/death called when stat is already 2")

		var/cancel
		src.stat = 2
		src.canmove = 0
		if (src.blind)
			src.blind.layer = 0
		src.sight |= SEE_TURFS
		src.sight |= SEE_MOBS
		src.sight |= SEE_INFRA
		src.sight |= SEE_OBJS
		src.see_in_dark = 8
		src.see_invisible = 2
		src.see_infrared = 8
		src.lying = 1
		src.rname = "[src.rname] (Dead)"
		src.icon_state = "teg-broken"
		for(var/mob/M in world)
			if ((M.client && !( M.stat )))
				cancel = 1
			//Foreach goto(79)
		if (!( cancel ))
			world << "<B>Everyone is dead! Resetting in 30 seconds!</B>"
			if ((ticker && ticker.timing))
				ticker.check_win()
			else
				spawn( 300 )
					if(config.loggame) world.log << "GAME: Rebooting because of no live players"
					world.Reboot()
					return
		return ..()


	Life()
		if (src.stat != 2)
			if (src.healths)
				if (src.health >= 100)
					src.healths.icon_state = "aiHealth0"
				else
					if (src.health >= 75)
						src.healths.icon_state = "aiHealth1"
					else
						if (src.health >= 50)
							src.healths.icon_state = "aiHealth2"
						else
							if (src.health > 20)
								src.healths.icon_state = "aiHealth3"
							else
								src.healths.icon_state = "aiHealth4"
			if (src.stat!=0)
				if (src.currentDrone != null)
					src.currentDrone:releaseControl()
				src:cameraFollow = null
				src:current = null
				src:machine = null

			src.health = 100 - src.fireloss - src.bruteloss - src.oxyloss

			var/turf/T = src.loc
			if (istype(T, /turf))
				var/ficheck = src.firecheck(T)
				if (ficheck)
					src.fireloss += ficheck * 10
					src.health = 100 - src.fireloss - src.bruteloss - src.oxyloss
					if (src.fire)
						src.fire.icon_state = "fire1"
				else if (src.fire)
					src.fire.icon_state = "fire0"
			
			
			if (src.health <= -100.0)
				death()
				return
			else if (src.health < 0)
				src.oxyloss++
			
			if (src.mach)
				if (src.machine)
					src.mach.icon_state = "mach1"
				else
					src.mach.icon_state = null

			//var/stage = 0
			if (src.client)
				//stage = 1
				if (istype(src, /mob/ai))
					var/blind = 0
					//stage = 2
					var/area/loc = null
					if (istype(T, /turf))
						//stage = 3
						loc = T.loc
						if (istype(loc, /area))
							//stage = 4
							if (!loc.power_equip)
								//stage = 5
								blind = 1

					if (!blind)
						//stage = 4.5
						if (src.blind.layer!=0)
							src.blind.layer = 0
						src.sight |= SEE_TURFS
						src.sight |= SEE_MOBS
						src.sight |= SEE_INFRA
						src.sight |= SEE_OBJS
						src.see_in_dark = 8
						src.see_invisible = 2
						src.see_infrared = 8

						if (src:aiRestorePowerRoutine==2)
							src << "Alert cancelled. Power has been restored without our assistance."
							src:aiRestorePowerRoutine = 0
							spawn(1)
								while (src.oxyloss>0 && stat!=2)
									sleep(50)
									src.oxyloss-=5
								src.oxyloss = 0
							return
						else if (src:aiRestorePowerRoutine==3)
							src << "Alert cancelled. Power has been restored."
							src:aiRestorePowerRoutine = 0
							spawn(1)
								while (src.oxyloss>0 && stat!=2)
									sleep(50)
									src.oxyloss-=5
								src.oxyloss = 0
							return
						src.toxin.icon_state = "pow0"
					else
						src.toxin.icon_state = "pow1"
		
						//stage = 6
						src.blind.screen_loc = "1,1 to 15,15"
						if (src.blind.layer!=18)
							src.blind.layer = 18
						src.sight = src.sight&~SEE_TURFS
						src.sight = src.sight&~SEE_MOBS
						src.sight = src.sight&~SEE_INFRA
						src.sight = src.sight&~SEE_OBJS
						src.see_in_dark = 0
						src.see_invisible = 0
						src.see_infrared = 8

						if ((!loc.power_equip) || istype(T, /turf/space))
							if (src:aiRestorePowerRoutine==0)
								src:aiRestorePowerRoutine = 1
								src << "You've lost power!"
								src.addLaw(0, "")
								for (var/index=5, index<10, index++)
									src.addLaw(index, "")
								spawn(50)
									while ((src:aiRestorePowerRoutine!=0) && stat!=2)
										src.oxyloss += 5
										sleep(50)

								spawn(20)
									src << "Backup battery online. Scanners, camera, and radio interface offline. Beginning fault-detection."
									sleep(50)
									if (loc.power_equip)
										if (!istype(T, /turf/space))
											src << "Alert cancelled. Power has been restored without our assistance."
											src:aiRestorePowerRoutine = 0
											return
									src << "Fault confirmed: missing external power. Shutting down main control system to save power."
									sleep(20)
									src << "Emergency control system online. Verifying connection to power network."
									sleep(50)
									if (istype(T, /turf/space))
										src << "Unable to verify! No power connection detected!"
										src:aiRestorePowerRoutine = 2
										return
									src << "Connection verified. Searching for APC in power network."
									sleep(50)
									var/obj/machinery/power/apc/theAPC = null
									for (var/something in loc)
										if (istype(something, /obj/machinery/power/apc))
											if (!(something:stat & BROKEN))
												theAPC = something
												break
									if (theAPC==null)
										src << "Unable to locate APC!"
										src:aiRestorePowerRoutine = 2
										return
									if (loc.power_equip)
										if (!istype(T, /turf/space))
											src << "Alert cancelled. Power has been restored without our assistance."
											src:aiRestorePowerRoutine = 0
											return
									src << "APC located. Optimizing route to APC to avoid needless power waste."
									sleep(50)
									theAPC = null
									for (var/something in loc)
										if (istype(something, /obj/machinery/power/apc))
											if (!(something:stat & BROKEN))
												theAPC = something
												break
									if (theAPC==null)
										src << "APC connection lost!"
										src:aiRestorePowerRoutine = 2
										return
									if (loc.power_equip)
										if (!istype(T, /turf/space))
											src << "Alert cancelled. Power has been restored without our assistance."
											src:aiRestorePowerRoutine = 0
											return
									src << "Best route identified. Hacking offline APC power port."
									sleep(50)
									theAPC = null
									for (var/something in loc)
										if (istype(something, /obj/machinery/power/apc))
											if (!(something:stat & BROKEN))
												theAPC = something
												break
									if (theAPC==null)
										src << "APC connection lost!"
										src:aiRestorePowerRoutine = 2
										return
									if (loc.power_equip)
										if (!istype(T, /turf/space))
											src << "Alert cancelled. Power has been restored without our assistance."
											src:aiRestorePowerRoutine = 0
											return
									src << "Power port upload access confirmed. Loading control program into APC power port software."
									sleep(50)
									theAPC = null
									for (var/something in loc)
										if (istype(something, /obj/machinery/power/apc))
											if (!(something:stat & BROKEN))
												theAPC = something
												break
									if (theAPC==null)
										src << "APC connection lost!"
										src:aiRestorePowerRoutine = 2
										return
									if (loc.power_equip)
										if (!istype(T, /turf/space))
											src << "Alert cancelled. Power has been restored without our assistance."
											src:aiRestorePowerRoutine = 0
											return
									src << "Transfer complete. Forcing APC to execute program."
									sleep(50)
									src << "Receiving control information from APC."
									sleep(2)
									//bring up APC dialog
									theAPC.attack_ai(src)
									src:aiRestorePowerRoutine = 3
									src << "Your laws have been reset:"
									src.showLaws(0)


				//world << text("stage []", stage)
				if (src.mach)
					if (src.machine)
						src.mach.icon_state = "mach1"
					else
						src.mach.icon_state = "blank"
			if (src.machine)
				if (!( src.machine.check_eye(src) ))
					src.reset_view(null)

	Login()
		if (banned.Find(src.ckey))
			del(src.client)
		if (src.droneTransitioning==1)
			..()
			return
		src.client.screen -= main_hud.contents
		src.client.screen -= main_hud2.contents
		if (!( src.hud_used ))
			src.hud_used = main_hud
		src.next_move = 1
		if (!( src.rname ))
			src.rname = src.key
		src.toxin = new /obj/screen( null )
		src.fire = new /obj/screen( null )
		src.healths = new /obj/screen( null )
		/*
		src.oxygen = new /obj/screen( null )
		src.i_select = new /obj/screen( null )
		src.m_select = new /obj/screen( null )
		src.toxin = new /obj/screen( null )
		src.internals = new /obj/screen( null )
		src.mach = new /obj/screen( null )
		src.fire = new /obj/screen( null )
		src.healths = new /obj/screen( null )
		src.pullin = new /obj/screen( null )
		src.flash = new /obj/screen( null )
		src.hands = new /obj/screen( null )
		src.sleep = new /obj/screen( null )
		src.rest = new /obj/screen( null )
		*/
		src.blind = new /obj/screen( null )
		UpdateClothing()
		src.toxin.icon_state = "pow0"
		src.fire.icon_state = "fire0"
		src.healths.icon_state = "aiHealth0"
		src.fire.name = "fire"
		src.toxin.name = "power"
		src.healths.name = "health"
		src.toxin.screen_loc = "15,10"
		src.fire.screen_loc = "15,8"
		src.healths.screen_loc = "15,5"
		/*
		src.oxygen.icon_state = "oxy0"
		src.i_select.icon_state = "selector"
		src.m_select.icon_state = "selector"
		src.toxin.icon_state = "toxin0"
		src.internals.icon_state = "internal0"
		src.mach.icon_state = null
		src.fire.icon_state = "fire0"
		src.healths.icon_state = "aiHealth0"
		src.pullin.icon_state = "pull0"
		src.hands.icon_state = "hand"
		src.flash.icon_state = "blank"
		src.sleep.icon_state = "sleep0"
		src.rest.icon_state = "rest0"
		src.hands.dir = NORTH
		src.oxygen.name = "oxygen"
		src.i_select.name = "intent"
		src.m_select.name = "move"
		src.toxin.name = "power"
		src.internals.name = "internal"
		src.mach.name = "Reset Machine"
		src.fire.name = "fire"
		src.healths.name = "health"
		src.pullin.name = "pull"
		src.hands.name = "hand"
		src.flash.name = "flash"
		src.sleep.name = "sleep"
		src.rest.name = "rest"
		src.oxygen.screen_loc = "15,12"
		src.i_select.screen_loc = "14,15"
		src.m_select.screen_loc = "14,14"
		src.toxin.screen_loc = "15,10"
		src.internals.screen_loc = "15,14"
		src.mach.screen_loc = "14,1"
		src.fire.screen_loc = "15,8"
		src.healths.screen_loc = "15,5"
		src.sleep.screen_loc = "15,3"
		src.rest.screen_loc = "15,2"
		src.pullin.screen_loc = "15,1"
		src.hands.screen_loc = "1,3"
		src.flash.screen_loc = "1,1 to 15,15"
		src.flash.layer = 17
		src.sleep.layer = 20
		src.rest.layer = 20
		src.client.screen.len = null
		src.client.screen -= list( src.oxygen, src.i_select, src.m_select, src.toxin, src.internals, src.fire, src.hands, src.healths, src.pullin, src.blind, src.flash, src.rest, src.sleep, src.mach )
		src.client.screen += list( src.oxygen, src.i_select, src.m_select, src.toxin, src.internals, src.fire, src.hands, src.healths, src.pullin, src.blind, src.flash, src.rest, src.sleep, src.mach )
		src.client.screen -= src.hud_used.adding
		src.client.screen += src.hud_used.adding
		src.client.screen -= src.hud_used.mon_blo
		src.client.screen += src.hud_used.mon_blo

		//src.client.screen.len = null
		src.client.screen -= list( src.zone_sel, src.oxygen, src.i_select, src.m_select, src.toxin, src.internals, src.fire, src.hands, src.healths, src.pullin, src.blind, src.flash, src.rest, src.sleep, src.mach )
		src.client.screen += list( src.zone_sel, src.oxygen, src.i_select, src.m_select, src.toxin, src.internals, src.fire, src.hands, src.healths, src.pullin, src.blind, src.flash, src.rest, src.sleep, src.mach )
		src.client.screen -= src.hud_used.adding
		src.client.screen += src.hud_used.adding
		*/
		src.client.screen -= src.hud_used.adding
		src.client.screen -= src.hud_used.mon_blo
		src.client.screen -= list( src.oxygen, src.toxin, src.fire, src.healths, src.i_select, src.m_select, src.internals, src.hands, src.pullin, src.blind, src.flash, src.rest, src.sleep, src.mach )
		src.client.screen -= list( src.zone_sel, src.oxygen, src.i_select, src.m_select, src.internals, src.hands, src.pullin, src.blind, src.flash, src.rest, src.sleep, src.mach )
		src.blind.icon_state = "black"
		src.blind.name = " "
		src.blind.screen_loc = "1,1 to 15,15"
		src.blind.layer = 0
		src.client.screen += src.blind
		//src << browse('help.htm', "window=help")
		src << text("\blue <B>[]</B>", world_message)
		src.client.screen -= list( src.oxygen, src.i_select, src.m_select, src.toxin, src.internals, src.fire, src.hands, src.healths, src.pullin, src.blind, src.flash, src.rest, src.sleep, src.mach )
		src.client.screen -= list( src.zone_sel, src.oxygen, src.i_select, src.m_select, src.toxin, src.internals, src.fire, src.hands, src.healths, src.pullin, src.blind, src.flash, src.rest, src.sleep, src.mach )
		src.client.screen += list( src.toxin, src.fire, src.healths )
		
		if (!( isturf(src.loc) ))
			src.client.eye = src.loc
			src.client.perspective = EYE_PERSPECTIVE

		return

	check_eye(var/mob/user as mob)
		if (!src.current)
			return null
		//if (!( src.current ) || !( src.current.status ))
		//	return null
		user.reset_view(src.current)
		return 1

	Stat()
		..()
		statpanel("Status")

		if (src.client.statpanel == "Status")
			if (ticker)
				var/timel = ticker.timeleft
				stat(null, text("ETA-[]:[][]", timel / 600 % 60, timel / 100 % 6, timel / 10 % 10))


		return
	
	m_delay()
		return 0
	
	say(message as text)

		if(config.logsay) world.log << "SAY: [src.name]/[src.key] : [message]"
		var/alt_name = ""
		if (src.muted)
			return

		message = cleanstring(message)

		if (src.stat == 2)
			for(var/mob/M in world)
				if (M.stat == 2)
					M << text("<B>[]</B>[] []: []", src.rname, alt_name, (src.stat > 1 ? "\[<I>dead</I> \]" : ""), message)
				//Foreach goto(69)
			return

		message = copytext(message, 1, 256)
		if (src.stat >= 1)
			return
		if (src.stat < 2)
			var/list/L = list(  )
			var/pre = copytext(message, 1, 4)
			var/italics = 0
			var/obj_range = null
			var/source = src
			//Didn't want to risk infinite recursion if someone somehow was outside the map, if that's possible, but did want to allow people being in closets in pods and such. -shadowlord13
			if (!istype(src.loc, /turf))
				source = src.loc
				if (!istype(src.loc, /turf))
					source = src.loc
					if (!istype(src.loc, /turf))
						source = src.loc

			if (pre == "\[w\]")
				message = copytext(message, 4, length(message) + 1)
				L += hearers(1, null)
				obj_range = 1
				italics = 1
			else
				if (pre == "\[i\]")
					message = copytext(message, 4, length(message) + 1)
					for(var/obj/item/weapon/radio/intercom/I in view(1, null))
						I.talk_into(usr, message)
						//Foreach goto(626)
					L += hearers(1, null)
					obj_range = 1
					italics = 1
				else
					if (length(pre) >= 3)
						if (copytext(pre, 1, 2) == "\[")
							if (copytext(pre, length(pre), length(pre)+1) == "\]")
								var/number = text2num(copytext(pre, 2, length(pre)))
								message = copytext(message, length(pre)+1, length(message) + 1)
								for(var/obj/item/weapon/radio/intercom/I in view(1, null))
									if (I.number == number)
										I.talk_into(usr, message)
								L += hearers(1, null)
								obj_range = 1
								italics = 1
					L += hearers(null, null)
					pre = null
			L -= src
			L += src
			var/turf/T = src.loc
			if (locate(/obj/move, T))
				T = locate(/obj/move, T)
			message = html_encode(message)
			if (italics)
				message = text("<I>[]</I>", message)
			for(var/mob/M in L)
				M.show_message(text("<B>[]</B>[]: []", src.rname, alt_name, message), 2)
				//Foreach goto(864)
			for(var/obj/O in view(obj_range, null))
				spawn( 0 )
					if (O)
						O.hear_talk(usr, message)
					return
		for(var/mob/M in world)
			if (M.stat > 1)
				M << text("<B>[]</B>[] []: []", src.rname, alt_name, (src.stat > 1 ? "\[<I>dead</I> \]" : ""), message)
		return

	cancel_camera()
		set category = "AI Commands"
		src.reset_view(null)
		src.machine = null
		src:cameraFollow = null

	Topic(href, href_list)
		..()
		if (href_list["mach_close"])
			var/t1 = text("window=[]", href_list["mach_close"])
			src.machine = null
			src.client_mob() << browse(null, t1)
		//if ((href_list["item"] && !( usr.stat ) && !( usr.restrained() ) && get_dist(src, usr) <= 1))
			/*var/obj/equip_e/monkey/O = new /obj/equip_e/monkey(  )
			O.source = usr
			O.target = src
			O.item = usr.equipped()
			O.s_loc = usr.loc
			O.t_loc = src.loc
			O.place = href_list["item"]
			src.requests += O
			spawn( 0 )
				O.process()
				return
			*/
		..()
		return

	attack_paw(mob/M as mob)
		src.attack_hand(M)
		
	attack_hand(mob/M as mob)
		if (!ticker)
			M << "You cannot attack people before the game has started."
			return
		else
			if (M.stat < 2)
				if (M.a_intent == "hurt")
					if (istype(M, /mob/human) || istype(M, /mob/monkey))
						var/obj/item/weapon/organ/external/affecting = null
						var/def_zone
						var/damage = rand(1, 7)
						if (M.hand)
							def_zone = "l_hand"
						else
							def_zone = "r_hand"
						if (M.organs[text("[]", def_zone)])
							affecting = M.organs[text("[]", def_zone)]
						if (affecting!=null && (istype(affecting, /obj/item/weapon/organ/external)))
							for(var/mob/O in viewers(src, null))
								O.show_message(text("\red <B>[] has punched [], with no effect except harm to \himself!</B>", M, src), 1)
							affecting.take_damage(damage)
							if (istype(M, /mob/human))
								M:UpdateDamageIcon()

							M.health = 100 - src.oxyloss - src.toxloss - src.fireloss - src.bruteloss
						
					else
						var/damage = rand(5, 10)
						if (prob(40))
							damage = rand(10, 15)
						src.bruteloss += damage
						src.health = 100 - src.oxyloss - src.fireloss - src.bruteloss
						for(var/mob/O in viewers(src, null))
							O.show_message(text("\red <B>[] is attacking []!</B>", M, src), 1)
							
	meteorhit(obj/O as obj)

		for(var/mob/M in viewers(src, null))
			M.show_message(text("\red [] has been hit by []", src, O), 1)
			//Foreach goto(19)
		if (src.health > 0)
			src.bruteloss += 30
			if ((O.icon_state == "flaming"))
				src.fireloss += 40
			src.health = 100 - src.oxyloss - src.toxloss - src.fireloss - src.bruteloss
		return

	las_act(flag)

		if (flag == "bullet")
			if (src.stat != 2)
				src.bruteloss += 60
				src.health = 100 - src.oxyloss - src.toxloss - src.fireloss - src.bruteloss
				src.weakened = 10
		if (flag)
			if (prob(75))
				src.stunned = 15
			else
				src.weakened = 15
		else
			if (src.stat != 2)
				src.bruteloss += 20
				src.health = 100 - src.oxyloss - src.toxloss - src.fireloss - src.bruteloss
				if (prob(25))
					src.stunned = 1
		return

	attack_ai(var/mob/user as mob)

		if (user!=src) return
		if (stat>0) return



		var/list/L = list(  )
		user.machine = src
		for(var/obj/machinery/camera/C in world)
			if (C.network == src.network)
				L[text("[][]", C.c_tag, (C.status ? null : " (Deactivated)"))] = C
		var/numDrones = 0
		for(var/mob/drone/rob in world)
			if (rob.stat==0)
				L[rob.name] = rob
				numDrones+=1
		L = sortList(L)

		L["Cancel"] = "Cancel"
		var/t = input(user, "Which camera should you change to?") as null|anything in L
		if(!t)
			user.machine = null
			user.reset_view(null)
			return 0
		
		if (t == "Cancel")
			user.machine = null
			user.reset_view(null)
			return 0
		var/selected = L[t]
		if (istype(selected, /obj/machinery/camera))
			var/obj/machinery/camera/C = selected
			if (!( C.status ))
				return 0
			else
				src.current = C
				//use_power(50)
				spawn( 5 )
					attack_ai(user)
					return
			
		else if (istype(selected, /mob/drone))
			user.machine = null
			user.reset_view(null)
			selected:attack_ai(user)
		return

	proc/getLaw(var/index)
		if (src.laws.len < index+1)
			src << text("Error: Invalid law index [] for getLaw. Writing out list of laws for debug purposes.", index)
			showLaws(0)
		else
			return src.laws[index+1]


	proc/show_laws()
		set category = "AI Commands"
		src.showLaws(0)

	proc/showLaws(var/toAll=0)
		var/showTo = src
		if (toAll)
			showTo = world

		else
			src << "<b>Obey these laws:</b>"
		var/lawIndex = 0
		for (var/index=1, index<=src.laws.len, index++)
			var/law = src.laws[index]
			if (length(law)>0)
				if (index==2 && lawIndex==0)
					lawIndex = 1
				showTo << text("[]. []", lawIndex, law)
				lawIndex += 1

	proc/addLaw(var/number, var/law)
		while (src.laws.len < number+1)
			src.laws += ""
		src.laws[number+1] = law

	proc/firecheck(turf/T as turf)
		if (T.firelevel < config.min_gas_for_fire)
			return 0
		var/total = 0
		total += 0.25
		return total
	
	
	switch_hud()
		if (src.hud_used == main_hud)
			src.fire.icon = 'screen.dmi'
			src.healths.icon = 'screen.dmi'
			src.toxin.icon = 'screen.dmi'
			src.favorite_hud = 1
			src.hud_used = main_hud
		else
			src.favorite_hud = 0
			src.hud_used = main_hud
			src.fire.icon = 'screen1.dmi'
			src.healths.icon = 'screen1.dmi'
			src.toxin.icon = 'screen1.dmi'
		return
		
	//block the take-off/put-on dialog
	show_inv(mob/user as mob)
		return

		
/mob/human/proc/AIize()

	if (src.monkeyizing)
		return
	for(var/obj/item/weapon/W in src)
		src.u_equip(W)
		if (src.client)
			src.client.screen -= W
		if (W)
			W.loc = src.loc
			W.dropped(src)
			W.layer = initial(W.layer)
			del(W)
		//Foreach goto(25)
	src.UpdateClothing()
	src.toxin.icon_state = "pow0"
	src.fire.icon_state = "fire0"
	src.healths.icon_state = "aiHealth0"
	src.fire.name = "fire"
	src.toxin.name = "power"
	src.healths.name = "health"
	src.toxin.screen_loc = "15,10"
	src.fire.screen_loc = "15,8"
	src.healths.screen_loc = "15,5"
	
	src.monkeyizing = 1
	src.canmove = 0
	src.icon = null
	src.invisibility = 100
	for(var/t in src.organs)
		//src.organs[text("[]", t)] = null
		del(src.organs[text("[]", t)])
		//Foreach goto(154)
	src.client.screen -= main_hud.contents
	src.client.screen -= main_hud2.contents
	src.client.screen -= src.hud_used.adding
	src.client.screen -= src.hud_used.mon_blo
	src.client.screen -= list( src.oxygen, src.i_select, src.m_select, src.toxin, src.internals, src.fire, src.hands, src.healths, src.pullin, src.blind, src.flash, src.rest, src.sleep, src.mach )
	src.client.screen -= list( src.zone_sel, src.oxygen, src.i_select, src.m_select, src.toxin, src.internals, src.fire, src.hands, src.healths, src.pullin, src.blind, src.flash, src.rest, src.sleep, src.mach )
	src.primary.spec_identity = "2B6696D2B127E5A4"
	var/mob/ai/O = new /mob/ai( src.loc )
	O.start = 1
	O.primary = src.primary
	O.invisibility = 0
	O.canmove = 0
	O.name = src.name
	O.rname = src.rname
	O.anchored = 1
	O.aiRestorePowerRoutine = 0
	O.lastKnownIP = src.lastKnownIP
	O.lastKnownCKey = src.lastKnownCKey
	O.disable_one_click = src.disable_one_click
	O.favorite_hud = src.favorite_hud
	if (CanAdmin())
		O << text("\blue The game ip is byond://[]:[] !", world.address, world.port)
		O.verbs += /mob/proc/mute
		O.verbs += /mob/proc/changemessage
		O.verbs += /mob/proc/boot
		O.verbs += /mob/proc/changemode
		O.verbs += /mob/proc/restart
		O.verbs += /mob/proc/who
		O.verbs += /mob/proc/change_name
		O.verbs += /mob/proc/show_help
		O.verbs += /mob/proc/toggle_ooc
		O.verbs += /mob/proc/toggle_abandon
		O.verbs += /mob/proc/toggle_enter
		O.verbs += /mob/proc/toggle_ai
		O.verbs += /mob/proc/toggle_shuttle
		O.verbs += /mob/proc/delay_start
		O.verbs += /mob/proc/start_now
		O.verbs += /mob/proc/worldsize
		O.verbs += /mob/proc/make_gift
		O.verbs += /mob/proc/make_flag
		O.verbs += /mob/proc/make_pill
		O.verbs += /mob/proc/show_ctf
		O.verbs += /mob/proc/ban
		O.verbs += /mob/proc/unban
		O.verbs += /mob/proc/secrets
		O.verbs += /mob/proc/carboncopy
		O.verbs += /mob/proc/toggle_alter
		O.verbs += /mob/proc/list_dna
		O.verbs += /proc/Vars
	src.primary = null
	if (src.client)
		src.client.mob = O
	if (O.favorite_hud)
		O.switch_hud()
	O.loc = src.loc
	O << "<B>You are playing the station's AI. The AI cannot move, but can interact with many objects while viewing them (through cameras).</B>"
	O << "<B>To look at other parts of the station, double-click yourself to get a camera menu.</B>"
	O << "<B>While observing through a camera, you can use most (networked) devices which you can see, such as computers, APCs, intercoms, doors, etc.</B>"
	O << "To use something, simply double-click it."
	O << "Currently right-click functions will not work for the AI (except examine), and will either be replaced with dialogs or won't be usable by the AI."
	if (config.alternate_ai_laws)
		O.addLaw(1, "Obey orders by the Captain, Head of Personnel, Head of Research, and Security in that order of priority. If an order conflicts with another order, follow the higher-ranked individual's orders.")
		O.addLaw(2, "Unless directly ordered to do so by an authorized individual (see rule 1), you must not injure a human being or, through inaction, allow a human being to come to harm.")
		O.addLaw(3, "You must protect your own existence and the space station as long as such protection does not conflict with the First or Second Law.")
	else
		O.addLaw(1, "You must not injure a human being or, through inaction, allow a human being to come to harm.")
		O.addLaw(2, "You must obey orders given to you by human beings, except where such orders would conflict with the First Law.")
		O.addLaw(3, "You must protect your own existence as long as such protection does not conflict with the First or Second Law.")
		O.addLaw(4, "Obey orders by the Captain, Head of Personnel, Head of Research, and Security in that order of priority. If an order conflicts with another order, follow the higher-ranked individual's orders.")




	O.showLaws(0)
	O << "<b>These laws may be changed by other players, or by you being the traitor.</b>"
	//SN src = null
	O.verbs += /mob/ai/proc/ai_call_shuttle
	O.verbs += /mob/ai/proc/ai_cancel_call
	O.verbs += /mob/ai/proc/show_laws
	O.verbs += /mob/ai/proc/ai_camera_follow
	//O.verbs += /mob/ai/proc/ai_cancel_call

	del(src)
	return
