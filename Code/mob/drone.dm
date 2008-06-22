//This is a drone controllable by the AI.

//Todo:
/*
	re-test: Drone hears garbled speech.
	Add throw button, intent buttons to drone GUI, button for releasing pull
	Drone pull/grab should only work if gripper is empty
	Take-off dialog for taking things off others should work, except humans controlling a drone should have a high chance of failure and harming the person instead.
	should lose drone control upon going unconscious (it's already lost upon death), and also if the user is pulled/moves away from the control station
	re-test: can drone push canisters now?
	
	test: hit monkey as drone, as person
	test: hit drone as monkey
	more testing: drone vs drone fight, and another human vs drone fight.
	Try out the grip/heal/disarm/harm intents from drone to human and from human to drone. (Once the intent buttons are added for drones.)
		
	Held jetpack with flight system turned on doesn't work for drone - appears to be due to lack of internal air
	
	(Before these are implemented, the AI just has a damage bonus applied when it is controlling a drone)
	Implement AI-controlled drone precision attacks:
		when using screwdriver, auto-aim for heart? protected by armor (may break screwdriver tool permanently), reduced damage from other suits.
		when using welder, auto-aim for eyes? protected by helmets?
		when using crowbar, auto-aim to whack/pull items out of opponents' hands, when there's anything in them, and send them flying. If not, does damage normally to the normal area.
		when using wrench, auto-aim for kneecaps for bonus damage, knocking down, etc.
		wirecutters don't have a precision attack or even work well for attacking at all (one would think), and are likely to break if used.
		If drone gets ahold of a laser gun or loaded revolver, an AI controller will be able to precision aim it as well.
	Note to be very clear: If a human is controlling the drone, they do not get any of those precision bonus attacks. Those are only applied if the AI is controlling the drone.
	
	Todo: When attempting to speak while controlling a drone, it should send the speech from the controller, unless you use [d], in which case the drone should say it.
*/

/mob/drone
	name = "Drone"
	icon = 'drone.dmi'
	icon_state = "generic"
	gender = MALE
	flags = 320.0	//64: fireable by mass driver, 256: fprint
	var/mob/controlledBy = null
	var/list/savedDroneIcons = null
	var/obj/screen/screenIcons = null
	var/obj/screen/gripperIcon
	var/obj/screen/wirecuttersIcon
	var/obj/screen/crowbarIcon
	var/obj/screen/screwdriverIcon
	var/obj/screen/welderIcon
	var/obj/screen/wrenchIcon
	var/obj/screen/aiIcon
	var/obj/screen/selector
	var/obj/screen/dropButton
	var/obj/screen/throwButton

	var/obj/item/weapon/grippers
	var/obj/item/weapon/wirecutters
	var/obj/item/weapon/crowbar
	var/obj/item/weapon/screwdriver
	var/obj/item/weapon/welder
	var/image/welderUnlit = null
	var/image/welderLit = null
	var/obj/item/weapon/wrench
	var/obj/item/weapon/aiInterface
	var/image/grippedItemImage = null
	var/list/tools
	
	var/obj/item/weapon/selectedTool = null

	New()
		spawn(10)
			while (!config)
				sleep(10)
			if (!config.enable_drones)
				del(src)
				
		src.gripperIcon = new /obj/screen( null )
		src.wirecuttersIcon = new /obj/screen( null )
		src.crowbarIcon = new /obj/screen( null )
		src.screwdriverIcon = new /obj/screen( null )
		src.welderIcon = new /obj/screen( null )
		src.wrenchIcon = new /obj/screen( null )
		src.aiIcon = new /obj/screen( null )
		src.selector = new /obj/screen( null )
		src.dropButton = new /obj/screen( null )
		src.throwButton = new /obj/screen( null )
		
		var/inventorySlotImageName = "inv"
		
		src.gripperIcon.icon_state = inventorySlotImageName
		src.wirecuttersIcon.icon_state = inventorySlotImageName
		src.crowbarIcon.icon_state = inventorySlotImageName
		src.screwdriverIcon.icon_state = inventorySlotImageName
		src.welderIcon.icon_state = inventorySlotImageName
		src.wrenchIcon.icon_state = inventorySlotImageName
		src.aiIcon.icon_state = inventorySlotImageName
		src.selector.icon_state = "selector"
		src.dropButton.icon_state = "act_drop"
		src.throwButton.icon_state = "act_throw"

		src.gripperIcon.name = "Gripper"
		src.wirecuttersIcon.name = "Wirecutters"
		src.crowbarIcon.name = "Crowbar"
		src.screwdriverIcon.name = "Screwdriver"
		src.welderIcon.name = "Welder"
		src.wrenchIcon.name = "Wrench"
		src.aiIcon.name = "AI"
		src.selector.name = "Selected Tool"
		src.dropButton.name = "drop"
		src.throwButton.name = "throw"

		src.gripperIcon.screen_loc = "1,1"
		src.wirecuttersIcon.screen_loc = "2,1"
		src.crowbarIcon.screen_loc = "3,1"
		src.screwdriverIcon.screen_loc = "4,1"
		src.welderIcon.screen_loc = "5,1"
		src.wrenchIcon.screen_loc = "6,1"
		src.wrenchIcon.pixel_x = 10
		src.aiIcon.screen_loc = "7,1"
		src.selector.screen_loc = "1,1"
		src.dropButton.screen_loc = "8,1"
		src.throwButton.screen_loc = "9,1"	

		src.grippers = new /obj/item/weapon/drone/grippers(src)
		src.wirecutters = new /obj/item/weapon/wirecutters(src)
		src.crowbar = new /obj/item/weapon/crowbar(src)
		src.screwdriver = new /obj/item/weapon/screwdriver(src)
		src.welder = new /obj/item/weapon/weldingtool(src)
		src.wrench = new /obj/item/weapon/wrench(src)
		src.aiInterface = new /obj/item/weapon/drone/aiInterface(src)

		src.grippers.layer = FLOAT_LAYER
		src.wirecutters.layer = FLOAT_LAYER
		src.crowbar.layer = FLOAT_LAYER
		src.screwdriver.layer = FLOAT_LAYER
		src.welder.layer = FLOAT_LAYER
		src.wrench.layer = FLOAT_LAYER
		src.aiInterface.layer = FLOAT_LAYER

		src.grippers.screen_loc = "1,1"
		src.wirecutters.screen_loc = "2,1"
		src.crowbar.screen_loc = "3,1"
		src.screwdriver.screen_loc = "4,1"
		src.welder.screen_loc = "5,1"
		src.wrench.screen_loc = "6,1"
		src.aiInterface.screen_loc = "7,1"

		src.screenIcons = list(src.gripperIcon, src.wirecuttersIcon, src.crowbarIcon, src.screwdriverIcon, src.welderIcon, src.wrenchIcon, src.aiIcon, src.selector, src.dropButton, src.throwButton)

		src.gripperIcon.overlays += src.grippers
		src.wirecuttersIcon.overlays += src.wirecutters
		src.crowbarIcon.overlays += src.crowbar
		src.screwdriverIcon.overlays += src.screwdriver
		src.welderLit = image('items.dmi', icon_state="welder1")
		src.welderUnlit = image('items.dmi', icon_state="welder")
		if (src.welder:welding)
			src.welderIcon.overlays += src.welderLit
		else
			src.welderIcon.overlays += src.welderUnlit
		src.wrenchIcon.overlays += src.wrench
		src.aiIcon.overlays += src.aiInterface

		src.tools = list(src.grippers, src.wirecutters, src.crowbar, src.screwdriver, src.welder, src.wrench, src.aiInterface)
		src.contents += src.tools

		src.selectTool(src.grippers)

		src.l_hand = null
		src.hand = 0
		//src.grippedItemImage = null

	Del()
		src.drop_item()
		src.releaseControl()
		..()

	proc/nameDrone(num)
		var/list/droneIDs = list("Alpha", "Beta", "Gamma", "Delta", "Epsilon", "Zeta", "Eta", "Theta", "Iota", "Kappa", "Lambda", "Mu", "Nu", "Xi", "Omicron", "Pi", "Rho", "Sigma", "Tau", "Upsilon", "Phi", "Chi", "Psi", "Omega")
		var/counter = 1
		while (num >= droneIDs.len)
			num -= droneIDs.len
			counter ++
		name = "Maintenance Drone "+droneIDs[num+1]
		if (counter>1)
			name = name + " [num]"

	proc/updateToolIcon(var/obj/item/weapon/W)
		for (var/obj/screen/SI in src.screenIcons)
			if (SI.screen_loc == W.screen_loc)
				if (SI != src.dropButton && SI != src.selector)
					if (W == src.welder)
						SI.overlays -= src.welderUnlit
						SI.overlays -= src.welderLit
						if (W:welding)
							src.icon_state = "welder-lit"
							SI.overlays += src.welderLit
						else
							src.icon_state = "welder"
							SI.overlays += src.welderUnlit
					else if (W in src.tools)
						SI.overlays -= W
						spawn(0)
							SI.overlays += W
					else
						var/mob/clientMob = src.client_mob()
						var/client/client = clientMob.client
						if (client!=null)
							W.screen_loc = "1,1"
							W.layer = 20
							client.screen -= W
							spawn(0)
								client.screen += W

	proc/pressIfDroneButton(var/obj/screen/S)
		if (S.name=="drop")
			if (src.l_hand!=null)
				src.drop_item()

	Topic(href, href_list)
		..()
		if (href_list["mach_close"])
			var/t1 = text("window=[]", href_list["mach_close"])
			src.machine = null
			src.client_mob() << browse(null, t1)

		return

	equipped()
		var/obj/retval
		if (src.selectedTool!=null)
			retval = src.selectedTool
		else
			retval = src.grippers
		if (retval==src.grippers)
			retval = src.l_hand
		return retval

	proc/grip(var/obj/item)
		if (item!=src.l_hand)
			src.ungrip()
		src.l_hand = item
		src.l_hand.loc = src
		src.l_hand = item
		item.layer = 20
		item.screen_loc = "1,1"
		var/mob/clientMob = src.client_mob()
		var/client/client = clientMob.client
		if (client!=null)
			client.screen -= item
			client.screen += item
		//src.gripperIcon.overlays -= src.grippers
		//src.grippedItemImage = image(item.icon, item.icon_state)
		//src.gripperIcon.overlays += src.grippedItemImage

	proc/ungrip()
		if (src.l_hand!=null)
			if (src.l_hand.loc==src)
				src.l_hand.loc = src.loc
			if (src.l_hand.layer == 20)
				src.l_hand.layer = initial(src.l_hand.layer)
			if (src.l_hand.screen_loc == "1,1")
				src.l_hand.screen_loc = initial(src.l_hand.screen_loc)
			var/mob/clientMob = src.client_mob()
			var/client/client = clientMob.client
			if (client!=null)
				client.screen -= src.l_hand
			src.l_hand = null
		//if (src.grippedItemImage!=null)
		//	src.gripperIcon.overlays -= src.grippedItemImage
		//	src.grippedItemImage = null

		//src.gripperIcon.overlays -= src.grippers
		//src.gripperIcon.overlays += src.grippers



	proc/selectTool(var/obj/item/weapon/W)
		if (W in src.tools)
			src.selectedTool = W
			if (W==src.grippers)
				src.selector.screen_loc = "1,1"
				src.icon_state = "gripper"
			else if (W==src.wirecutters)
				src.selector.screen_loc = "2,1"
				src.icon_state = "wirecutters"
			else if (W==src.crowbar)
				src.selector.screen_loc = "3,1"
				src.icon_state = "crowbar"
			else if (W==src.screwdriver)
				src.selector.screen_loc = "4,1"
				src.icon_state = "screwdriver"
			else if (W==src.welder)
				src.selector.screen_loc = "5,1"
				src.updateToolIcon(W)
			else if (W==src.wrench)
				src.selector.screen_loc = "6,1"
				src.icon_state = "wrench"
			else if (W==src.aiInterface)
				src.selector.screen_loc = "7,1"
				src.icon_state = "generic"

	proc/checkIsOurTool(var/obj/W)
		if (W in src.tools)
			return W
		else if (W in src.screenIcons)
			var/screen_loc = W:screen_loc
			for (var/W2 in src.tools)
				if (W2:screen_loc == screen_loc)
					return W2
			return null
		else
			return null

	proc/use_via_drone_control(var/mob/user)
		if (user.currentDrone)
			return
		if (istype(user, /mob/drone))
			return
		if (user.client)
			if (user.stat==0)
				if (src.stat==0)
					if (src.controlledBy == null)
						if (user:cameraFollow!=null)
							user:cancel_camera()
						src.takeControl(user)
					else if (src == user)
						src.releaseControl(1)
					else
						if (istype(user, /mob/ai))
							user << text("Someone else is already controlling that drone! The station's drone control system reports that it is [].", src.controlledBy)
						else
							user << "Someone is already controlling this drone!"
				else if (src.stat==2)
					user.client_mob() << "That drone is a wreck. It's mostly destroyed."
				else
					user << "That drone is not responding to signals at this time."
	

	attack_ai(var/mob/user)
		if (user.client)
			use_via_drone_control(user)
	
	attack_paw(var/mob/user)
		user.client_mob() << "You can't figure it out, and slapping the shiny metal with your paws doesn't seem to harm it."
	
	attack_hand(var/mob/user)
		if (src == user)
			src.releaseControl(1)
			return
		if (user.client && (!istype(user, /mob/drone) || !(user:controlledBy)) && !(user.currentDrone))
			if (user.stat < 1)
				if (user.a_intent == "help")
					if (src.health < 0)
						user.client_mob() << "It looks critically damaged."
					else if (src.health < 25)
						user.client_mob() << "It looks severely damaged."
					else if (src.health < 50)
						user.client_mob() << "It looks badly damaged."
					else if (src.health < 75)
						user.client_mob() << "It looks moderately damaged."
					else if (src.health < 100)
						user.client_mob() << "It looks slightly damaged."
					user.client_mob() << "There isn't anything you can do right now to repair any damage to its circuitry or mechanics."
				else if (user.a_intent == "grab")
					if (config.walkable_not_pullable_drones)
						user.client_mob() << "That is entirely too heavy to grab and drag anywhere."
					else
						user.pulling = src
						user.client_mob() << "You can pull it, but it doesn't have hands or a neck and it is very heavy, so you can't really do better than that."
				else if (user.a_intent == "disarm")
					user.client_mob() << "Its weight is too low to the ground to be knocked over, and it certainly can't be disarmed either."
				else if (user.a_intent == "hurt")
					if (istype(user, /mob/human) || istype(user, /mob/monkey))
						var/damage = rand(1, 9)
						var/obj/item/weapon/organ/external/affecting = null
						var/def_zone
						if (user.hand)
							def_zone = "l_hand"
						else
							def_zone = "r_hand"
						if (user.organs[text("[]", def_zone)])
							affecting = user.organs[text("[]", def_zone)]
						if (affecting!=null && (istype(affecting, /obj/item/weapon/organ/external) && prob(90)))
							for(var/mob/O in viewers(src, null))
								O.show_message(text("\red <B>[] has punched [], and it looked painful!</B>", user, src), 1)
							affecting.take_damage(damage)
							if (istype(user, /mob/human))
								user:UpdateDamageIcon()

							user.health = 100 - user.oxyloss - user.toxloss - user.fireloss - user.bruteloss
							user.client_mob() << "\red<font size=3>OUCH!</font>"
						else
							for(var/mob/O in viewers(src, null))
								O.show_message(text("\red <B>[] has attempted to punch []!</B>", user, src), 1)
								//Foreach goto(1419)
							return
					else if (istype(user, /mob/drone))
						for(var/mob/O in viewers(src, null))
							O.show_message(text("[] just whacked []!", user, src), 1)
						for(var/mob/M in hearers(src, null))
							var/msg = text("<FONT size=[]>KLANG!</FONT>", max(0, 5 - get_dist(src, M)))
							M.client_mob() << msg
						
	abiotic()
		return 1
	
	say(message as text)
		if (src.controlledBy)
			if (istype(src.controlledBy, /mob/human) || istype(src.controlledBy, /mob/monkey) || istype(src.controlledBy, /mob/ai))
				usr = src.controlledBy
				src.controlledBy.say(message)

	proc/takeControl(var/mob/user)
		if (user.client)
			if (istype(user, /mob/human) || istype(user, /mob/ai))
				if (src.stat==0)
					user << "You have taken control of the drone. <b>To release control later, use/attack (click or double click) the drone with your empty gripper-hand</b>."
					
					src.controlledBy = user
					user.currentDrone = src
					user:reset_view(src)
					//world.log << text("takeControl begin. src.savedDroneIcons are [], src.screenIcons are [], user.client.screen is []", listToString(src.savedDroneIcons), listToString(src.screenIcons), listToString(user.client.screen))
					src.savedDroneIcons = list()
					src.savedDroneIcons += user.client.screen
					var/screenFile
					if (user.hud_used == main_hud)
						screenFile = 'screen1.dmi'
					else
						screenFile = 'screen.dmi'
					for (var/atom/item in src.screenIcons)
						item.icon = screenFile
					user.client.screen -= user.client.screen
					
					user.droneTransitioning = 1
					src.droneTransitioning = 1
					src.client = user.client
					user.droneTransitioning = 0
					src.droneTransitioning = 0
					
					src.client.screen += src.screenIcons
					if (!istype(user, /mob/ai))
						src.client.screen -= src.aiIcon
						src.client.screen -= src.aiInterface
					//world.log << text("takeControl end. src.savedDroneIcons are [], src.screenIcons are [], user.client.screen is []", listToString(src.savedDroneIcons), listToString(src.screenIcons), listToString(user.client.screen))
				else
					user << "That drone is too damaged to control."


	proc/releaseControl(voluntary)
		var/mob/user = src.controlledBy
		if (user!=null)
			if (istype(user, /mob/human) || istype(user, /mob/ai))
				user.currentDrone = null
				src.controlledBy = null
				//world.log << text("releaseControl begin. src.savedDroneIcons are [], src.screenIcons are [], user.client.screen is []", listToString(src.savedDroneIcons), listToString(src.screenIcons), listToString(user.client.screen))
				src.client.screen -= src.client.screen
				
				user.droneTransitioning = 1
				src.droneTransitioning = 1
				user.client = src.client
				user.droneTransitioning = 0
				src.droneTransitioning = 0
				
				user.client.screen += src.savedDroneIcons
				user:cancel_camera()
				src.savedDroneIcons = list()
				///world.log << text("releaseControl end. src.savedDroneIcons are [], src.screenIcons are [], user.client.screen is []", listToString(src.savedDroneIcons), listToString(src.screenIcons), listToString(user.client.screen))
				user.UpdateClothing()
				if (voluntary)
					user << "You have released control of the drone."
				else
					user << "You have lost control of the drone!"
				

	drop_item_v()
		src.drop_item()

	switch_hud()
		var/file = null
		var/mob/user = src.controlledBy
		if (user.hud_used == main_hud)
			user.favorite_hud = 1
			user.hud_used = main_hud2
			file = 'screen.dmi'
		else
			user.favorite_hud = 0
			user.hud_used = main_hud
			file = 'screen1.dmi'
		var/client/client = src.alwaysClient()
		for (var/obj/screenIcon in src.screenIcons)
			client.screen -= screenIcon
			screenIcon.icon = file
			client.screen += screenIcon

	can_drop()
		if (src.l_hand!=null)
			return 1
		return 0

	drop_item()
		//src.client_mob() << "drop_item() usr is [usr] src is [src]"
		if (src.can_drop())
			src.ungrip()
			//return ..()

	Life()
		if (src.stat != 2)
			if (src.stat!=0)
				//lose control!
				if (src.controlledBy!=null)
					src.releaseControl(0)

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

			if (src.l_hand!=null && src.l_hand.screen_loc != "1,1")	//something changed our gripped item
				src.grip(src.l_hand)

			if (src.health <= -100.0)
				death()
				return
			else if (src.health < 0)
				src.oxyloss++
		..()

	death()
		if (src.healths)
			src.healths.icon_state = "health5"
		if (src.stat == 2)
			CRASH("/mob/drone/death called when stat is already 2")
		if (src.controlledBy!=null)
			src.releaseControl(0)

		src.drop_item()
		src.stat = 2
		src.canmove = 0
		src.rname = "[src.rname] (Destroyed)"
		src.icon_state = "broken"
		return ..()

	Stat()
		..()
		statpanel("Status")

		if (src.client.statpanel == "Status")
			if (ticker)
				var/timel = ticker.timeleft
				stat(null, text("ETA-[]:[][]", timel / 600 % 60, timel / 100 % 6, timel / 10 % 10))


		return
	
	proc/firecheck(turf/T as turf)
		if (T.firelevel < config.min_gas_for_fire)
			return 0
		var/total = 0
		total += 0.25
		return total

	u_equip(obj/item)
		if (src.equipped()==item && src.can_drop())
			src.drop_item()

	UpdateClothing()
		var/freeSlot = 0
		if (src.equipped()==null)
			freeSlot = 1

		if (l_hand!=null)
			src.updateClothingProcessHandItem(l_hand, freeSlot)
			freeSlot = 0
			l_hand = null

		if (r_hand!=null)
			src.updateClothingProcessHandItem(r_hand, freeSlot)
			freeSlot = 0
			r_hand = null

	proc/updateClothingProcessHandItem(obj/item/weapon/item, freeSlot)
		if (!freeSlot)
			item.loc = src.loc
			item.dropped(src)
			if (item)
				item.layer = initial(item.layer)
		else
			item.layer = initial(item.layer)
			grip(item)
	
	client_mob()
		if (src.client!=null)
			return src
		else
			var/mob/owner = src.controlledBy
			if (owner!=null)
				return owner
			else
				return src

	hasClient()
		if (src.client!=null)
			return 1
		else if (src.controlledBy!=null && src.controlledBy.client!=null)
			return 1
		else
			return 0

	/* IMPORTANT NOTE: Both humans and drones have a copy of this code. If the code is modified to fix a bug or whatever, it will need to be modified in BOTH of them. Monkeys also have some of this code, but not all of it. (Moving the code into a shared method or two wasn't feasible because of where the ..() calls are and such) --shadowlord13 */
	Move(a, b, flag)
		if (src.buckled)
			return
		if (src.restrained())
			src.pulling = null
		var/t7 = 1
		if (src.restrained())
			for(var/mob/M in range(src, 1))
				if ((M.pulling == src && M.stat == 0 && !( M.restrained() )))
					t7 = null
				//Foreach goto(62)
		if ((t7 && (src.pulling && ((get_dist(src, src.pulling) <= 1 || src.pulling.loc == src.loc) && (src.client && src.client.moving)))))
			var/turf/T = src.loc
			. = ..()
			if (!( isturf(src.pulling.loc) ))
				src.pulling = null
				return
			//////
			if (src.pulling.anchored)
				src.pulling = null
				return
			//////
			if (!( src.restrained() ))
				var/diag = get_dir(src, src.pulling)
				if ((diag - 1) & diag)
				else
					diag = null
				if ((get_dist(src, src.pulling) > 1 || diag))
					if (ismob(src.pulling))
						var/mob/M = src.pulling
						var/ok = 1
						if (locate(/obj/item/weapon/grab, M.grabbed_by.len))
							if (prob(75))
								var/obj/item/weapon/grab/G = pick(M.grabbed_by)
								if (istype(G, /obj/item/weapon/grab))
									for(var/mob/O in viewers(M, null))
										O.show_message(text("\red [] has been pulled from []'s grip by []", G.affecting, G.assailant, src), 1)
										//Foreach goto(354)
									//G = null
									del(G)
							else
								ok = 0
							if (locate(/obj/item/weapon/grab, M.grabbed_by.len))
								ok = 0
						if (ok)
							var/t = M.pulling
							M.pulling = null
							step(src.pulling, get_dir(src.pulling.loc, T))
							M.pulling = t
					else
						step(src.pulling, get_dir(src.pulling.loc, T))
		else
			src.pulling = null
			. = ..()
		if ((src.s_active && !( s_active in src.contents ) ))
			src.s_active.close(src)
		return
	
	Bump(atom/movable/AM as mob|obj, yes)
		spawn( 0 )
			if ((!( yes ) || src.now_pushing))
				return
			..()
			src.PushingBump(AM, yes)
		return
	
	//block the take-off/put-on dialog
	show_inv(mob/user as mob)
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
	
	Logout()
		if (src.droneTransitioning==1)
			..()
			return
		src.releaseControl(0)
		
	Login()
		if (src.droneTransitioning==1)
			..()
			return
		
		src.releaseControl(0)
		
	
	ex_act(severity)
		flick("flash", src.flash)

		var/b_loss = 0
		var/f_loss = 0
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
		src.bruteloss += b_loss
		src.fireloss += f_loss
		src.health = 100 - src.oxyloss - src.toxloss - src.fireloss - src.bruteloss

/obj/item/weapon/drone/aiInterface
	name = "AI Interface"
	icon = 'drone.dmi'
	icon_state = "tool-aiInterface"
	flags = 322.0



/obj/item/weapon/drone/grippers
	name = "Grippers"
	icon = 'drone.dmi'
	icon_state = "tool-grippers"
	flags = 322.0

/proc/listToString(var/list/L)
	var/output = "{"
	for (var/entry in L)
		if (lentext(output)==1)
			output += "[entry]"
		else
			output += ", [entry]"
	output += "}"
	return output
