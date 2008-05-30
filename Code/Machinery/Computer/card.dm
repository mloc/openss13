/*
 *	Card -- the identification computer
 *
 *	Used to alter the settings of an ID card
 *	Also provides a crew manifest
 *
 */

obj/machinery/computer/card
	name = "Identification Computer"
	icon = 'stationobjs.dmi'
	icon_state = "id_computer"

	var
		obj/item/weapon/card/id/scan = null				// The ID card used to authenticate
														// Must be assigned to Captain or Head of Personnel
		obj/item/weapon/card/id/modify = null			// The ID card to modify
		authenticated = 0								// true if Capt/HoP card is authenticated
		mode = 0										// 0 = show card edit, 1 = show crew manifest
		printing = null									// true if printing the crew manifest



	// Attack with object same as interact

	attackby(obj/I, mob/user)
		src.attack_hand(user)


	// Monkey interact same as human

	attack_paw(mob/user)
		return src.attack_hand(user)

	// AI interact
	
	attack_ai(mob/user)
		return src.attack_hand(user)

	// Human interact.
	// Show interaction window

	attack_hand(mob/user)

		if(stat & (NOPOWER|BROKEN) ) return

		user.machine = src
		var/dat
		if (!( ticker ))
			return

		if (src.mode)

			var/d2 = "Confirm Identity: <A href='?src=\ref[src];scan=1'>[(src.scan ? text("[]", src.scan.name) : "----------")]</A>\n[(src.authenticated ? "You are logged in!" :"<A href='?src=\ref[src];auth=1'>{Log in}</A>")]"

			var/d1 = "Please use security Records to modify entries.<BR>"
			for(var/datum/data/record/t in data_core.general)
				d1 += "[t.fields["name"]] - [t.fields["rank"]]<BR>"

			dat = "<HTML><HEAD></HEAD><BODY><TT>[d2]<BR>\n<BR>\n<B>Crew Manifest:</B><BR>\n[d1]\n<BR>\n<A href='?src=\ref[src];print=1'>Print</A><BR>\n<BR>\n<A href='?src=\ref[src];mode=0'>Access ID modification console.</A><BR>\n</TT></BODY></HTML>"
		else
			var/d1 = "<A href='?src=\ref[src];auth=1'>{Log in}</A>"
			if ((src.authenticated && src.modify))
				var/vo = null
				var/va = null
				var/vl = null
				var/ve = null
				switch(src.modify.access_level)
					if(1.0)
						vo = "<A href='?src=\ref[src];vo=-1'>0</A> 1 <A href='?src=\ref[src];vo=2'>2</A> <A href='?src=\ref[src];vo=3'>3</A> <A href='?src=\ref[src];vo=4'>4</A> <A href='?src=\ref[src];vo=5'>5</A>"
					if(2.0)
						vo = "<A href='?src=\ref[src];vo=-1'>0</A> <A href='?src=\ref[src];vo=1'>1</A> 2 <A href='?src=\ref[src];vo=3'>3</A> <A href='?src=\ref[src];vo=4'>4</A> <A href='?src=\ref[src];vo=5'>5</A>"
					if(3.0)
						vo = "<A href='?src=\ref[src];vo=-1'>0</A> <A href='?src=\ref[src];vo=1'>1</A> <A href='?src=\ref[src];vo=2'>2</A> 3 <A href='?src=\ref[src];vo=4'>4</A> <A href='?src=\ref[src];vo=5'>5</A>"
					if(4.0)
						vo = "<A href='?src=\ref[src];vo=-1'>0</A> <A href='?src=\ref[src];vo=1'>1</A> <A href='?src=\ref[src];vo=2'>2</A> <A href='?src=\ref[src];vo=3'>3</A> 4 <A href='?src=\ref[src];vo=5'>5</A>"
					if(5.0)
						vo = "<A href='?src=\ref[src];vo=-1'>0</A> <A href='?src=\ref[src];vo=1'>1</A> <A href='?src=\ref[src];vo=2'>2</A> <A href='?src=\ref[src];vo=3'>3</A> <A href='?src=\ref[src];vo=4'>4</A> 5"
					else
						vo = "0 <A href='?src=\ref[src];vo=1'>1</A> <A href='?src=\ref[src];vo=2'>2</A> <A href='?src=\ref[src];vo=3'>3</A> <A href='?src=\ref[src];vo=4'>4</A> <A href='?src=\ref[src];vo=5'>5</A>"
				switch(src.modify.lab_access)
					if(1.0)
						vl = "<A href='?src=\ref[src];vl=-1'>0</A> 1 <A href='?src=\ref[src];vl=2'>2</A> <A href='?src=\ref[src];vl=3'>3</A> <A href='?src=\ref[src];vl=4'>4</A> <A href='?src=\ref[src];vl=5'>5</A>"
					if(2.0)
						vl = "<A href='?src=\ref[src];vl=-1'>0</A> <A href='?src=\ref[src];vl=1'>1</A> 2 <A href='?src=\ref[src];vl=3'>3</A> <A href='?src=\ref[src];vl=4'>4</A> <A href='?src=\ref[src];vl=5'>5</A>"
					if(3.0)
						vl = "<A href='?src=\ref[src];vl=-1'>0</A> <A href='?src=\ref[src];vl=1'>1</A> <A href='?src=\ref[src];vl=2'>2</A> 3 <A href='?src=\ref[src];vl=4'>4</A> <A href='?src=\ref[src];vl=5'>5</A>"
					if(4.0)
						vl = "<A href='?src=\ref[src];vl=-1'>0</A> <A href='?src=\ref[src];vl=1'>1</A> <A href='?src=\ref[src];vl=2'>2</A> <A href='?src=\ref[src];vl=3'>3</A> 4 <A href='?src=\ref[src];vl=5'>5</A>"
					if(5.0)
						vl = "<A href='?src=\ref[src];vl=-1'>0</A> <A href='?src=\ref[src];vl=1'>1</A> <A href='?src=\ref[src];vl=2'>2</A> <A href='?src=\ref[src];vl=3'>3</A> <A href='?src=\ref[src];vl=4'>4</A> 5"
					else
						vl = "0 <A href='?src=\ref[src];vl=1'>1</A> <A href='?src=\ref[src];vl=2'>2</A> <A href='?src=\ref[src];vl=3'>3</A> <A href='?src=\ref[src];vl=4'>4</A> <A href='?src=\ref[src];vl=5'>5</A>"
				switch(src.modify.engine_access)
					if(1.0)
						ve = "<A href='?src=\ref[src];ve=-1'>0</A> 1 <A href='?src=\ref[src];ve=2'>2</A> <A href='?src=\ref[src];ve=3'>3</A> <A href='?src=\ref[src];ve=4'>4</A> <A href='?src=\ref[src];ve=5'>5</A>"
					if(2.0)
						ve = "<A href='?src=\ref[src];ve=-1'>0</A> <A href='?src=\ref[src];ve=1'>1</A> 2 <A href='?src=\ref[src];ve=3'>3</A> <A href='?src=\ref[src];ve=4'>4</A> <A href='?src=\ref[src];ve=5'>5</A>"
					if(3.0)
						ve = "<A href='?src=\ref[src];ve=-1'>0</A> <A href='?src=\ref[src];ve=1'>1</A> <A href='?src=\ref[src];ve=2'>2</A> 3 <A href='?src=\ref[src];ve=4'>4</A> <A href='?src=\ref[src];ve=5'>5</A>"
					if(4.0)
						ve = "<A href='?src=\ref[src];ve=-1'>0</A> <A href='?src=\ref[src];ve=1'>1</A> <A href='?src=\ref[src];ve=2'>2</A> <A href='?src=\ref[src];ve=3'>3</A> 4 <A href='?src=\ref[src];ve=5'>5</A>"
					if(5.0)
						ve = "<A href='?src=\ref[src];ve=-1'>0</A> <A href='?src=\ref[src];ve=1'>1</A> <A href='?src=\ref[src];ve=2'>2</A> <A href='?src=\ref[src];ve=3'>3</A> <A href='?src=\ref[src];ve=4'>4</A> 5"
					else
						ve = "0 <A href='?src=\ref[src];ve=1'>1</A> <A href='?src=\ref[src];ve=2'>2</A> <A href='?src=\ref[src];ve=3'>3</A> <A href='?src=\ref[src];ve=4'>4</A> <A href='?src=\ref[src];ve=5'>5</A>"
				switch(src.modify.air_access)
					if(1.0)
						va = "<A href='?src=\ref[src];va=-1'>0</A> 1 <A href='?src=\ref[src];va=2'>2</A> <A href='?src=\ref[src];va=3'>3</A> <A href='?src=\ref[src];va=4'>4</A> <A href='?src=\ref[src];va=5'>5</A>"
					if(2.0)
						va = "<A href='?src=\ref[src];va=-1'>0</A> <A href='?src=\ref[src];va=1'>1</A> 2 <A href='?src=\ref[src];va=3'>3</A> <A href='?src=\ref[src];va=4'>4</A> <A href='?src=\ref[src];va=5'>5</A>"
					if(3.0)
						va = "<A href='?src=\ref[src];va=-1'>0</A> <A href='?src=\ref[src];va=1'>1</A> <A href='?src=\ref[src];va=2'>2</A> 3 <A href='?src=\ref[src];va=4'>4</A> <A href='?src=\ref[src];va=5'>5</A>"
					if(4.0)
						va = "<A href='?src=\ref[src];va=-1'>0</A> <A href='?src=\ref[src];va=1'>1</A> <A href='?src=\ref[src];va=2'>2</A> <A href='?src=\ref[src];va=3'>3</A> 4 <A href='?src=\ref[src];va=5'>5</A>"
					if(5.0)
						va = "<A href='?src=\ref[src];va=-1'>0</A> <A href='?src=\ref[src];va=1'>1</A> <A href='?src=\ref[src];va=2'>2</A> <A href='?src=\ref[src];va=3'>3</A> <A href='?src=\ref[src];va=4'>4</A> 5"
					else
						va = "0 <A href='?src=\ref[src];va=1'>1</A> <A href='?src=\ref[src];va=2'>2</A> <A href='?src=\ref[src];va=3'>3</A> <A href='?src=\ref[src];va=4'>4</A> <A href='?src=\ref[src];va=5'>5</A>"

				var/list/L = list( "Research Assistant", "Staff Assistant", "Medical Assistant", "Technical Assistant", "Engineer", "Forensic Technician", "Research Technician", "Medical Doctor", "Captain", "Security Officer", "Medical Researcher", "Toxin Researcher", "Head of Research", "Head of Personnel", "Station Technician", "Atmospheric Technician", "Unassigned", "Systems", "Custom" )
				var/assign = ""
				if (istype(user, /mob/human) || istype(user, /mob/ai))
					var/counter = 1
					for(var/t in L)
						assign += "<A href='?src=\ref[src];assign=[t]'>[t]</A>  "
						counter++
						if (counter >= 3)
							assign += "<BR>"
							counter = 1

					d1 = "[src.modify.name] :<BR>\nGeneral Access Level: [vo]<BR>\nLaboratory Access: [vl]<BR>\nReactor/Engine Access: [ve]<BR>\nMain Systems Access: [va]<BR>\nRegistered: <A href='?src=\ref[src];reg=1'>[src.modify.registered ? "[src.modify.registered]" : "{None: Click to modify}"]</A><BR>\nAssignment: [src.modify.assignment ? "[src.modify.assignment]" : "None"]<BR>\n[assign]<BR>"
				else
					var/counter = 1
					for(var/t in L)
						assign += "<A href='?src=\ref[src];assign=[t]'>[stars(t)]</A>  "
						counter++
						if (counter >= 4)
							assign += "<BR>"
							counter = 1

					d1 = "[stars(modify.name)] :<BR>\n[stars("General Access Level:")] [vo]<BR>\n[stars("Laboratory Access:")] [vl]<BR>\n[stars("Reactor/Engine Access:")] [ve]<BR>\n[stars("Main Systems Access:")] [va]<BR>\n[stars("Registered:")] <A href='?src=\ref[src];reg=1'>[src.modify.registered ? stars(src.modify.registered) : stars("{None: Click to modify}")]</A><BR>\n[stars("Assignment:")] [src.modify.assignment ? "[stars(src.modify.assignment)]" : "None"]<BR>\n[assign]<BR>"


			if (istype(user, /mob/human))
				dat = text("<TT><B>Identification Card Modifier</B><BR>\n<I>Please Insert the cards into the slots</I><BR>\nTarget: <A href='?src=\ref[];modify=1'>[]</A><BR>\nConfirm Identity: <A href='?src=\ref[];scan=1'>[]</A><BR>\n-----------------<BR>\n[]<BR>\n<BR>\n<BR>\n<A href='?src=\ref[];mode=1'>Access Crew Manifest</A><BR>\n</TT>", src, (src.modify ? text("[]", src.modify.name) : "----------"), src, (src.scan ? text("[]", src.scan.name) : "----------"), d1, src)
			else
				dat = text("<TT><B>[]</B><BR>\n<I>[]</I><BR>\n[] <A href='?src=\ref[];modify=1'>[]</A><BR>\n[] <A href='?src=\ref[];scan=1'>[]</A><BR>\n-----------------<BR>\n[]<BR>\n<BR>\n<BR>\n<A href='?src=\ref[];mode=1'>[]</A><BR>\n</TT>", stars("Identification Card Modifier"), stars("Please Insert the cards into the slots"), stars("Target:"), src, (src.modify ? text("[]", stars(src.modify.name)) : "----------"), stars("Confirm Identity:"), src, (src.scan ? text("[]", stars(src.scan.name)) : "----------"), d1, src, stars("Access Crew Manifest"))
		user << browse(dat, "window=id_com;size=400x500")


	// Handle topic links from interaction window

	Topic(href, href_list)
		..()

		if(stat & (NOPOWER|BROKEN))
			usr << browse(null, "window=id_com")
			return

		if(usr.restrained() || usr.lying)
			if (!istype(usr, /mob/ai))
				return

		if ((!( istype(usr, /mob/human) ) && (!( ticker ) || (ticker && ticker.mode != "monkey"))))
			if (!istype(usr, /mob/ai))		
				usr << "\red You don't have the dexterity to do this!"
				return
		if ((usr.stat || usr.restrained()))
			if (!istype(usr, /mob/ai))
				return

		if ((get_dist(src, usr) <= 1 && istype(src.loc, /turf)) || (istype(usr, /mob/ai)))
			usr.machine = src
			if (href_list["modify"])
				if (src.modify)
					src.modify.name = "[src.modify.registered]'s ID Card ([src.modify.access_level]>[src.modify.lab_access]-[src.modify.engine_access]-[src.modify.air_access])"
					src.modify.loc = src.loc
					src.modify = null
				else
					var/obj/item/I = usr.equipped()
					if (istype(I, /obj/item/weapon/card/id))
						usr.drop_item()
						I.loc = src
						src.modify = I
				src.authenticated = 0

			if (href_list["scan"])
				if (src.scan)
					src.scan.loc = src.loc
					src.scan = null
				else
					var/obj/item/I = usr.equipped()
					if (istype(I, /obj/item/weapon/card/id))
						usr.drop_item()
						I.loc = src
						src.scan = I
				src.authenticated = 0

			if ((!( src.authenticated ) && (src.scan || (istype(usr, /mob/ai))) && (src.modify || src.mode)))
				if (istype(usr, /mob/ai))
					src.authenticated = 1
				else
					if ((src.scan.assignment == "Captain" || src.scan.assignment == "Head of Personnel"))
						src.authenticated = 1
			else
				if ((!( src.authenticated ) && (istype(usr, /mob/ai))) && (!src.modify))
					usr << "You can't modify an ID without an ID inserted to modify. Once one is in the modify slot on the computer, you can log in."
			
			if (href_list["vo"])
				if (src.authenticated)
					var/t1 = text2num(href_list["vo"])
					if (t1 == -1.0)
						t1 = 0
					src.modify.access_level = t1

			if (href_list["vl"])
				if (src.authenticated)
					var/t1 = text2num(href_list["vl"])
					if (t1 == -1.0)
						t1 = 0
					src.modify.lab_access = t1

			if (href_list["ve"])
				if (src.authenticated)
					var/t1 = text2num(href_list["ve"])
					if (t1 == -1.0)
						t1 = 0
					src.modify.engine_access = t1

			if (href_list["va"])
				if (src.authenticated)
					var/t1 = text2num(href_list["va"])
					if (t1 == -1.0)
						t1 = 0
					src.modify.air_access = t1

			if (href_list["assign"])
				if (src.authenticated)
					var/t1 = href_list["assign"]

					if(t1 == "Custom")
						t1 = input("Enter a custom job assignment.","Assignment")

					src.modify.assignment = t1

			if (href_list["reg"])
				if (src.authenticated)
					var/t2 = src.modify
					var/t1 = input(usr, "What name?", "ID computer", null)  as text
					if ((src.authenticated && src.modify == t2 && get_dist(src, usr) <= 1 && istype(src.loc, /turf)))
						src.modify.registered = t1

			if (href_list["mode"])
				src.mode = text2num(href_list["mode"])

			if (href_list["print"])
				if (!( src.printing ))
					src.printing = 1
					sleep(50)
					var/obj/item/weapon/paper/P = new /obj/item/weapon/paper( src.loc )
					var/t1 = "<B>Crew Manifest:</B><BR>"
					for(var/datum/data/record/t in data_core.general)
						t1 += "<B>[t.fields["name"]]</B> - [t.fields["rank"]]<BR>"

					P.info = "[t1]"
					P.name = "paper- 'Crew Manifest'"
					src.printing = null

			if (href_list["mode"])
				src.authenticated = 0
				src.mode = text2num(href_list["mode"])
			if (src.modify)
				src.modify.name = "[src.modify.registered]'s ID Card ([src.modify.access_level]>[src.modify.lab_access]-[src.modify.engine_access]-[src.modify.air_access])"

			for(var/mob/M in viewers(1, src))
				if ((M.client && M.machine == src))
					src.attack_hand(M)

			src.add_fingerprint(usr)
		else
			usr << browse(null, "window=id_com")


	// Called when area power state changes
	// Update machione stat and icon_state

	power_change()
		if(stat & BROKEN)
			icon_state = "broken"
		else
			if( powered() )
				icon_state = initial(icon_state)
				stat &= ~NOPOWER
			else
				spawn(rand(0, 15))
					src.icon_state = "id_unpowered"
					stat |= NOPOWER


