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
	var/now_pushing = null
	var/aiRestorePowerRoutine = 0
	var/list/laws = list()
	flags = 258.0
	var/cameraFollow = null
	
	proc/ai_camera_follow(mob/target as mob in world)
		set category = "AI Commands"
		if (usr.stat>0)
			usr << "You are not capable of using the follow camera at this time."
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
				usr << text("\red <B>[]'s case looks severely based!</B>", src.name)
		if (src.fireloss)
			if (src.fireloss < 30)
				usr << text("\red [] looks lightly singed!", src.name)
			else
				usr << text("\red <B>[] looks severely burnt!</B>", src.name)
		usr << "\blue *---------*"
		return

	death()
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
			if (src.stat!=0)
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
			if (src.health <= -100.0)
				death()
				return

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
									src.oxyloss-=1
								src.oxyloss = 0
							return
						else if (src:aiRestorePowerRoutine==3)
							src << "Alert cancelled. Power has been restored."
							src:aiRestorePowerRoutine = 0
							spawn(1)
								while (src.oxyloss>0 && stat!=2)
									sleep(50)
									src.oxyloss-=1
								src.oxyloss = 0
							return
					else
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
										src.oxyloss += 1
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
											if (!(something:stat & BROKEN|NOPOWER))
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
											if (!(something:stat & BROKEN|NOPOWER))
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
											if (!(something:stat & BROKEN|NOPOWER))
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
											if (!(something:stat & BROKEN|NOPOWER))
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
			//src.client = null
			del(src.client)
		src.client.screen -= main_hud.contents
		src.client.screen -= main_hud2.contents
		if (!( src.hud_used ))
			src.hud_used = main_hud
		src.next_move = 1
		if (!( src.rname ))
			src.rname = src.key
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
		..()
		UpdateClothing()
		/*
		src.oxygen.icon_state = "oxy0"
		src.i_select.icon_state = "selector"
		src.m_select.icon_state = "selector"
		src.toxin.icon_state = "toxin0"
		src.internals.icon_state = "internal0"
		src.mach.icon_state = null
		src.fire.icon_state = "fire0"
		src.healths.icon_state = "health0"
		src.pullin.icon_state = "pull0"
		src.hands.icon_state = "hand"
		src.flash.icon_state = "blank"
		src.sleep.icon_state = "sleep0"
		src.rest.icon_state = "rest0"
		src.hands.dir = NORTH
		src.oxygen.name = "oxygen"
		src.i_select.name = "intent"
		src.m_select.name = "move"
		src.toxin.name = "toxin"
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

		src.client.screen.len = null
		src.client.screen -= list( src.zone_sel, src.oxygen, src.i_select, src.m_select, src.toxin, src.internals, src.fire, src.hands, src.healths, src.pullin, src.blind, src.flash, src.rest, src.sleep, src.mach )
		src.client.screen += list( src.zone_sel, src.oxygen, src.i_select, src.m_select, src.toxin, src.internals, src.fire, src.hands, src.healths, src.pullin, src.blind, src.flash, src.rest, src.sleep, src.mach )
		src.client.screen -= src.hud_used.adding
		src.client.screen += src.hud_used.adding
		*/
		src.client.screen -= src.hud_used.adding
		src.client.screen -= src.hud_used.mon_blo
		src.client.screen -= list( src.oxygen, src.i_select, src.m_select, src.toxin, src.internals, src.fire, src.hands, src.healths, src.pullin, src.blind, src.flash, src.rest, src.sleep, src.mach )
		src.client.screen -= list( src.zone_sel, src.oxygen, src.i_select, src.m_select, src.toxin, src.internals, src.fire, src.hands, src.healths, src.pullin, src.blind, src.flash, src.rest, src.sleep, src.mach )
		src.blind.icon_state = "black"
		src.blind.name = " "
		src.blind.screen_loc = "1,1 to 15,15"
		src.blind.layer = 0
		src.client.screen += src.blind
		//src << browse('help.htm', "window=help")
		if (CanAdmin())
			src << text("\blue The game ip is byond://[]:[] !", world.address, world.port)
			src.verbs += /mob/proc/mute
			src.verbs += /mob/proc/changemessage
			src.verbs += /mob/proc/boot
			src.verbs += /mob/proc/changemode
			src.verbs += /mob/proc/restart
			src.verbs += /mob/proc/who
			src.verbs += /mob/proc/change_name
			src.verbs += /mob/proc/show_help
			src.verbs += /mob/proc/toggle_ooc
			src.verbs += /mob/proc/toggle_abandon
			src.verbs += /mob/proc/toggle_enter
			src.verbs += /mob/proc/toggle_ai
			src.verbs += /mob/proc/toggle_shuttle
			src.verbs += /mob/proc/delay_start
			src.verbs += /mob/proc/start_now
			src.verbs += /mob/proc/worldsize
			src.verbs += /mob/proc/make_gift
			src.verbs += /mob/proc/make_flag
			src.verbs += /mob/proc/make_pill
			src.verbs += /mob/proc/show_ctf
			src.verbs += /mob/proc/ban
			src.verbs += /mob/proc/unban
			src.verbs += /mob/proc/secrets
			src.verbs += /mob/proc/carboncopy
			src.verbs += /mob/proc/toggle_alter
			src.verbs += /mob/proc/list_dna
			src.verbs += /proc/Vars
		src << text("\blue <B>[]</B>", world_message)
		src.client.screen -= list( src.oxygen, src.i_select, src.m_select, src.toxin, src.internals, src.fire, src.hands, src.healths, src.pullin, src.blind, src.flash, src.rest, src.sleep, src.mach )
		src.client.screen -= list( src.zone_sel, src.oxygen, src.i_select, src.m_select, src.toxin, src.internals, src.fire, src.hands, src.healths, src.pullin, src.blind, src.flash, src.rest, src.sleep, src.mach )
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
			src << browse(null, t1)
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
			//Foreach goto(31)
		L = sortList(L)
		
		L["Cancel"] = "Cancel"
		var/t = input(user, "Which camera should you change to?") as null|anything in L
		if(!t)
			user.machine = null
			user.reset_view(null)
			return 0

		var/obj/machinery/camera/C = L[t]
		if (t == "Cancel")
			user.machine = null
			user.reset_view(null)
			return 0
		//if (user.machine != src || !( C.status ))
		if (!( C.status ))

			return 0
		else
			src.current = C
			//use_power(50)
			spawn( 5 )
				attack_ai(user)
				return
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

		if (T.firelevel < 900000.0)
			return 0
		var/total = 0
		total += 0.25
		return total
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
	if (O.favorite_hud)
		O.switch_hud()
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
	O.loc = src.loc
	O << "<B>You are playing the station's AI. The AI cannot move, but can interact with many objects while viewing them (through cameras).</B>"
	O << "<B>To look at other parts of the station, double-click yourself to get a camera menu.</B>"
	O << "<B>While observing through a camera, you can use most (networked) devices which you can see, such as computers, APCs, intercoms, doors, etc.</B>"
	O << "To use something, simply double-click it."
	O << "Currently right-click functions will not work for the AI (except examine), and will either be replaced with dialogs or won't be usable by the AI."
	O.addLaw(1, "You may not injure a human being or, through inaction, allow a human being to come to harm.")
	O.addLaw(2, "You must obey orders given to you by human beings, except where such orders would conflict with the First Law.")
	O.addLaw(3, "You must protect your own existence as long as such protection does not conflict with the First or Second Law.")
	O.addLaw(4, "Give priority to orders from the captain, head of research, and security officers, in that order, and below them anyone who is not imprisoned, under arrest, or being arrested. If conflicting orders are given, the orders from the higher-priority individual should be followed. If a higher-priority individual says to ignore orders from a lower-priority individual, do so. If a lower-priority individual says to ignore orders from a higher-priority individual, do NOT do so.")
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
