var
	hsboxspawn = 0
	list
		hrefs = list(
					"hsbsuit" = "Suit Up (Space Travel Gear)",
					"hsbmetal" = "Spawn 50 Metal",
					"hsbglass" = "Spawn 50 Glass",
					"hsbairlock" = "Spawn Airlock",
					"hsbregulator" = "Spawn Air Regulator",
					"hsbfilter" = "Spawn Air Filter",
					"hsbcanister" = "Spawn Canister",
					"hsbfueltank" = "Spawn Welding Fuel Tank",
					"hsbwater	tank" = "Spawn Water Tank",
					"hsbtoolbox" = "Spawn Toolbox",
					"hsbmedkit" = "Spawn Medical Kit")

mob
	var
		datum/hSB/sandbox = null
	proc
		CanBuild()
			if(master_mode == "sandbox")
				sandbox = new/datum/hSB
				sandbox.owner = src.ckey
				if(src.client.holder)
					sandbox.admin = 1
				verbs += new/mob/proc/sandbox_panel
		sandbox_panel()
			if(sandbox)
				sandbox.update()

datum/hSB
	var
		owner = null
		admin = 0
	proc
		update()
			var/hsbpanel = "<center><b>h_Sandbox Panel</b></center><hr>"
			if(admin)
				hsbpanel += "<b>Administration Tools:</b><br>"
				hsbpanel += "- <a href=\"?\ref[src];hsb=hsbtobj\">Toggle Object Spawning</a><br><br>"
			hsbpanel += "<b>Regular Tools:</b><br>"
			for(var/T in hrefs)
				hsbpanel += "- <a href=\"?\ref[src];hsb=[T]\">[hrefs[T]]</a><br>"
			if(hsboxspawn)
				hsbpanel += "- <a href=\"?\ref[src];hsb=hsbobj\">Spawn Object</a><br><br>"
			usr.client_mob() << browse(hsbpanel, "window=hsbpanel")
	Topic(href, href_list)
		if(!(src.owner == usr.ckey)) return
		if(href_list["hsb"])
			switch(href_list["hsb"])
				if("hsbtobj")
					if(!admin) return
					if(hsboxspawn)
						world << "<b>Sandbox:  [usr.key] has disabled object spawning!</b>"
						hsboxspawn = 0
						return
					if(!hsboxspawn)
						world << "<b>Sandbox:  [usr.key] has enabled object spawning!</b>"
						hsboxspawn = 1
						return
				if("hsbsuit")
					var/mob/human/P = usr
					if(P.wear_suit)
						P.wear_suit.loc = P.loc
						P.wear_suit.layer = initial(P.wear_suit.layer)
						P.wear_suit = null
					P.wear_suit = new/obj/item/weapon/clothing/suit/sp_suit(P)
					P.wear_suit.layer = 20
					if(P.head)
						P.head.loc = P.loc
						P.head.layer = initial(P.head.layer)
						P.head = null
					P.head = new/obj/item/weapon/clothing/head/s_helmet(P)
					P.head.layer = 20
					if(P.wear_mask)
						P.wear_mask.loc = P.loc
						P.wear_mask.layer = initial(P.wear_mask.layer)
						P.wear_mask = null
					P.wear_mask = new/obj/item/weapon/clothing/mask/gasmask(P)
					P.wear_mask.layer = 20
					if(P.back)
						P.back.loc = P.loc
						P.back.layer = initial(P.back.layer)
						P.back = null
					P.back = new/obj/item/weapon/tank/jetpack(P)
					P.back.layer = 20
					P.internal = P.back
				if("hsbmetal")
					var/obj/item/weapon/sheet/hsb = new/obj/item/weapon/sheet/metal
					hsb.amount = 50
					hsb.loc = usr.loc
				if("hsbglass")
					var/obj/item/weapon/sheet/hsb = new/obj/item/weapon/sheet/glass
					hsb.amount = 50
					hsb.loc = usr.loc
				if("hsbairlock")
					var/obj/machinery/door/hsb = new/obj/machinery/door/airlock
					var/r_access = input(usr, "What general access will this airlock require?", "Sandbox:") as num
					var/r_lab = input(usr, "What laboratory access will this airlock require?", "Sandbox:") as num
					var/r_engine = input(usr, "What engine access will this airlock require?", "Sandbox:") as num
					var/r_air = input(usr, "What air access will this airlock require?", "Sandbox:") as num

					hsb.access = "[r_access][r_lab][r_engine][r_air]"

					hsb.loc = usr.loc
					hsb.loc.buildlinks()
					usr.client_mob() << "<b>Sandbox:  Created an airlock requiring at least [r_access]>[r_lab]-[r_engine]-[r_air] access."
				if("hsbregulator")
					var/obj/machinery/atmoalter/siphs/fullairsiphon/hsb = new/obj/machinery/atmoalter/siphs/fullairsiphon/air_vent
					hsb.loc = usr.loc
				if("hsbfilter")
					var/obj/machinery/atmoalter/siphs/scrubbers/hsb = new/obj/machinery/atmoalter/siphs/scrubbers/air_filter
					hsb.loc = usr.loc
				if("hsbcanister")
					var/list/hsbcanisters = typesof(/obj/machinery/atmoalter/canister/) - /obj/machinery/atmoalter/canister/
					var/hsbcanister = input(usr, "Choose a canister to spawn.", "Sandbox:") in hsbcanisters + "Cancel"
					if(!(hsbcanister == "Cancel"))
						new hsbcanister(usr.loc)
				if("hsbfueltank")
					var/obj/hsb = new/obj/weldfueltank
					hsb.loc = usr.loc
				if("hsbwatertank")
					var/obj/hsb = new/obj/watertank
					hsb.loc = usr.loc
				if("hsbtoolbox")
					var/obj/item/weapon/storage/hsb = new/obj/item/weapon/storage/toolbox
					for(var/obj/item/weapon/radio/T in hsb)
						del(T)
					new/obj/item/weapon/crowbar (hsb)
					hsb.loc = usr.loc
				if("hsbmedkit")
					var/obj/item/weapon/storage/firstaid/hsb = new/obj/item/weapon/storage/firstaid/regular
					hsb.loc = usr.loc
				if("hsbobj")
					if(!hsboxspawn) return
					var/list/hsbitems = typesof(/obj/)
					var/hsbitem = input(usr, "Choose an object to spawn.", "Sandbox:") in hsbitems + "Cancel"
					if(!(hsbitem == "Cancel"))
						new hsbitem(usr.loc)
