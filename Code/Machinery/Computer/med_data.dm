/*
 *	Med_data -- a computer that shows player medical data.
 *
 *
 */



obj/machinery/computer/med_data
	name = "Medical Records"
	icon = 'weap_sat.dmi'
	icon_state = "computer"
	var
		obj/item/weapon/card/id/scan = null		// ID card inserted in the computer
		authenticated = null					// name on ID card (if has access)
		rank = null								// job assignment of ID card
		screen = null							// active screen displayed
												// 1=menu, 2=list of records, 3=maint. menu ,4=record edit
		datum/data/record/active1 = null		// selected general record (from data_core.general)
		datum/data/record/active2 = null		// selected medical record (from data_code.medical)
		a_id = null								// not used
		temp = null								// temporary text to show in window
		printing = null							// true if printing a record
		allowed = "Medical Researcher/Medical Doctor/Head of Personnel/Captain"		// the job assignments which have access
		access																		// the access levels which have access (none)


	// Monkey interact same as human

	attack_paw(mob/user)
		return src.attack_hand(user)

	// AI interact
	attack_ai(mob/user)
		return src.attack_hand(user)

	// Human interact
	// Show interaction window

	attack_hand(mob/user)

		var/dat
		if (src.temp)			// show temporary text
			dat = "<TT>[temp]</TT><BR><BR><A href='?src=\ref[src];temp=1'>Clear Screen</A>"
		else					// show ID card inserted
			dat = "Confirm Identity: <A href='?src=\ref[src];scan=1'>[src.scan ? "[src.scan.name]" : "----------"]</A><HR>"
			if (src.authenticated)
				switch(src.screen)
					if(1.0)
						dat += {"<A href='?src=\ref[src];search=1'>Search Records</A><BR>
<A href='?src=\ref[src];list=1'>List Records</A><BR>
<BR>
<A href='?src=\ref[src];rec_m=1'>Record Maintenance</A><BR>
<A href='?src=\ref[src];logout=1'>{Log Out}</A><BR>
"}
					if(2.0)
						dat += "<B>Record List</B>:<HR>"
						for(var/datum/data/record/R in data_core.general)
							dat += "<A href='?src=\ref[src];d_rec=\ref[R]'>[R.fields["id"]]: [R.fields["name"]]<BR>"

						dat += "<HR><A href='?src=\ref[src];main=1'>Back</A>"
					if(3.0)
						dat += {"<B>Records Maintenance</B><HR>
<A href='?src=\ref[src];back=1'>Backup To Disk</A><BR>
<A href='?src=\ref[src];u_load=1'>Upload From disk</A><BR>
<A href='?src=\ref[src];del_all=1'>Delete All Records</A><BR>
<BR>
<A href='?src=\ref[src];main=1'>Back</A>"}

					if(4.0)
						dat += "<CENTER><B>Medical Record</B></CENTER><BR>"
						if ((istype(src.active1, /datum/data/record) && data_core.general.Find(src.active1)))
							dat += {"Name: [src.active1.fields["name"]] ID: [src.active1.fields["id"]]<BR>
Sex: <A href='?src=\ref[src];field=sex'>[src.active1.fields["sex"]]</A><BR>
Age: <A href='?src=\ref[src];field=age'>[src.active1.fields["age"]]</A><BR>
Fingerprint: <A href='?src=\ref[src];field=fingerprint'>[src.active1.fields["fingerprint"]]</A><BR>
Physical Status: <A href='?src=\ref[src];field=p_stat'>[src.active1.fields["p_stat"]]</A><BR>
Mental Status: <A href='?src=\ref[src];field=m_stat'>[src.active1.fields["m_stat"]]</A><BR>"}

						else
							dat += "<B>General Record Lost!</B><BR>"
						if ((istype(src.active2, /datum/data/record) && data_core.medical.Find(src.active2)))
							dat += {"<BR>
<CENTER><B>Medical Data</B></CENTER><BR>
Blood Type: <A href='?src=\ref[src];field=b_type'>[src.active2.fields["b_type"]]</A><BR>
<BR>
Minor Disabilities: <A href='?src=\ref[src];field=mi_dis'>[src.active2.fields["mi_dis"]]</A><BR>
Details: <A href='?src=\ref[src];field=mi_dis_d'>[src.active2.fields["mi_dis_d"]]</A><BR>
<BR>
Major Disabilities: <A href='?src=\ref[src];field=ma_dis'>[src.active2.fields["ma_dis"]]</A><BR>
Details: <A href='?src=\ref[src];field=ma_dis_d'>[src.active2.fields["ma_dis_d"]]</A><BR>
<BR>
Allergies: <A href='?src=\ref[src];field=alg'>[src.active2.fields["alg"]]</A><BR>
Details: <A href='?src=\ref[src];field=alg_d'>[src.active2.fields["alg_d"]]</A><BR>
<BR>
Current Diseases: <A href='?src=\ref[src];field=cdi'>[src.active2.fields["cdi"]]</A> (per disease info placed in log/comment section)<BR>
Details: <A href='?src=\ref[src];field=cdi_d'>[src.active2.fields["cdi_d"]]</A><BR>
<BR>
Important Notes:<BR>
	<A href='?src=\ref[src];field=notes'>[src.active2.fields["notes"]]</A><BR>
<BR>
<CENTER><B>Comments/Log</B></CENTER><BR>"}

							var/counter = 1
							while(src.active2.fields["com_[counter]"])
								dat += "[src.active2.fields["com_[counter]"]]<BR><A href='?src=\ref[src];del_c=[counter]'>Delete Entry</A><BR><BR>"
								counter++
							dat += "<A href='?src=\ref[src];add_c=1'>Add Entry</A><BR><BR>"
							dat += "<A href='?src=\ref[src];del_r=1'>Delete Record (Medical Only)</A><BR><BR>"
						else
							dat += "<B>Medical Record Lost!</B><BR>"
							dat += "<A href='?src=\ref[src];new=1'>New Record</A><BR><BR>"
						dat += "\n<A href='?src=\ref[src];print_p=1'>Print Record</A><BR>\n<A href='?src=\ref[src];list=1'>Back</A><BR>"

			else
				dat += "<A href='?src=\ref[src];login=1'>{Log In}</A>"
		user << browse("<HEAD><TITLE>Medical Records</TITLE></HEAD><TT>[dat]</TT>", "window=med_rec")



	// Handle topic links from interaction window

	Topic(href, href_list)
		..()
		if (!( data_core.general.Find(src.active1) ))
			src.active1 = null
		if (!( data_core.medical.Find(src.active2) ))
			src.active2 = null
		if ((usr.stat || usr.restrained()))
			if (!istype(usr, /mob/ai))
				return
		if ((usr.contents.Find(src) || (get_dist(src, usr) <= 1 && istype(src.loc, /turf))) || (istype(usr, /mob/ai)))
			usr.machine = src
			if (href_list["temp"])
				src.temp = null				// close the temporary display
			if (href_list["scan"])
				if (src.scan)
					src.scan.loc = src.loc						// remove ID card from computer
					src.scan = null
				else
					var/obj/item/I = usr.equipped()
					if (istype(I, /obj/item/weapon/card/id))
						usr.drop_item()
						I.loc = src								// insert ID card into computer
						src.scan = I
			else if (href_list["logout"])
				src.authenticated = null
				src.screen = null
				src.active1 = null
				src.active2 = null
			else if (href_list["login"])						// check inserted ID card against access requirements
				if (istype(src.scan, /obj/item/weapon/card/id))
					src.active1 = null
					src.active2 = null
					if(scan.check_access(access, allowed))
						src.authenticated = src.scan.registered
						src.rank = src.scan.assignment
						src.screen = 1
			if (src.authenticated)
				if (href_list["list"])
					src.screen = 2
					src.active1 = null
					src.active2 = null
				else if (href_list["rec_m"])
					src.screen = 3
					src.active1 = null
					src.active2 = null
				else if (href_list["del_all"])
					src.temp = "Are you sure you wish to delete all records?<br>\n\t<A href='?src=\ref[src];temp=1;del_all2=1'>Yes</A><br>\n\t<A href='?src=\ref[src];temp=1'>No</A><br>"
				else if (href_list["del_all2"])
					for(var/datum/data/record/R in data_core.medical)
						del(R)
					src.temp = "All records deleted."
				else if (href_list["main"])
					src.screen = 1
					src.active1 = null
					src.active2 = null

				else if (href_list["field"])			// edit fields
					var/a1 = src.active1
					var/a2 = src.active2
					switch(href_list["field"])
						if("fingerprint")
							if (istype(src.active1, /datum/data/record))
								var/t1 = input("Please input fingerprint hash:", "Med. records", src.active1.fields["id"], null)  as text
								if ((!( t1 ) || !( src.authenticated ) || usr.stat || usr.restrained() || get_dist(src, usr) > 1 || src.active1 != a1))
									return
								src.active1.fields["fingerprint"] = t1
						if("sex")
							if (istype(src.active1, /datum/data/record))
								if (src.active1.fields["sex"] == "Male")
									src.active1.fields["sex"] = "Female"
								else
									src.active1.fields["sex"] = "Male"
						if("age")
							if (istype(src.active1, /datum/data/record))
								var/t1 = input("Please input age:", "Med. records", src.active1.fields["age"], null)  as text
								if ((!( t1 ) || !( src.authenticated ) || usr.stat || usr.restrained() || get_dist(src, usr) > 1 || src.active1 != a1))
									return
								src.active1.fields["age"] = t1
						if("mi_dis")
							if (istype(src.active2, /datum/data/record))
								var/t1 = input("Please input minor disabilities list:", "Med. records", src.active2.fields["mi_dis"], null)  as text
								if ((!( t1 ) || !( src.authenticated ) || usr.stat || usr.restrained() || get_dist(src, usr) > 1 || src.active2 != a2))
									return
								src.active2.fields["mi_dis"] = t1
						if("mi_dis_d")
							if (istype(src.active2, /datum/data/record))
								var/t1 = input("Please summarize minor dis.:", "Med. records", src.active2.fields["mi_dis_d"], null)  as message
								if ((!( t1 ) || !( src.authenticated ) || usr.stat || usr.restrained() || get_dist(src, usr) > 1 || src.active2 != a2))
									return
								src.active2.fields["mi_dis_d"] = t1
						if("ma_dis")
							if (istype(src.active2, /datum/data/record))
								var/t1 = input("Please input major diabilities list:", "Med. records", src.active2.fields["ma_dis"], null)  as text
								if ((!( t1 ) || !( src.authenticated ) || usr.stat || usr.restrained() || get_dist(src, usr) > 1 || src.active2 != a2))
									return
								src.active2.fields["ma_dis"] = t1
						if("ma_dis_d")
							if (istype(src.active2, /datum/data/record))
								var/t1 = input("Please summarize major dis.:", "Med. records", src.active2.fields["ma_dis_d"], null)  as message
								if ((!( t1 ) || !( src.authenticated ) || usr.stat || usr.restrained() || get_dist(src, usr) > 1 || src.active2 != a2))
									return
								src.active2.fields["ma_dis_d"] = t1
						if("alg")
							if (istype(src.active2, /datum/data/record))
								var/t1 = input("Please state allergies:", "Med. records", src.active2.fields["alg"], null)  as text
								if ((!( t1 ) || !( src.authenticated ) || usr.stat || usr.restrained() || get_dist(src, usr) > 1 || src.active2 != a2))
									return
								src.active2.fields["alg"] = t1
						if("alg_d")
							if (istype(src.active2, /datum/data/record))
								var/t1 = input("Please summarize allergies:", "Med. records", src.active2.fields["alg_d"], null)  as message
								if ((!( t1 ) || !( src.authenticated ) || usr.stat || usr.restrained() || get_dist(src, usr) > 1 || src.active2 != a2))
									return
								src.active2.fields["alg_d"] = t1
						if("cdi")
							if (istype(src.active2, /datum/data/record))
								var/t1 = input("Please state diseases:", "Med. records", src.active2.fields["cdi"], null)  as text
								if ((!( t1 ) || !( src.authenticated ) || usr.stat || usr.restrained() || get_dist(src, usr) > 1 || src.active2 != a2))
									return
								src.active2.fields["cdi"] = t1
						if("cdi_d")
							if (istype(src.active2, /datum/data/record))
								var/t1 = input("Please summarize diseases:", "Med. records", src.active2.fields["cdi_d"], null)  as message
								if ((!( t1 ) || !( src.authenticated ) || usr.stat || usr.restrained() || get_dist(src, usr) > 1 || src.active2 != a2))
									return
								src.active2.fields["cdi_d"] = t1
						if("notes")
							if (istype(src.active2, /datum/data/record))
								var/t1 = input("Please summarize notes:", "Med. records", src.active2.fields["notes"], null)  as message
								if ((!( t1 ) || !( src.authenticated ) || usr.stat || usr.restrained() || get_dist(src, usr) > 1 || src.active2 != a2))
									return
								src.active2.fields["notes"] = t1
						if("p_stat")
							if (istype(src.active1, /datum/data/record))
								src.temp = text("<B>Physical Condition:</B><BR>\n\t<A href='?src=\ref[];temp=1;p_stat=deceased'>*Deceased*</A><BR>\n\t<A href='?src=\ref[];temp=1;p_stat=unconscious'>*Unconscious*</A><BR>\n\t<A href='?src=\ref[];temp=1;p_stat=active'>Active</A><BR>\n\t<A href='?src=\ref[];temp=1;p_stat=unfit'>Physically Unfit</A><BR>", src, src, src, src)
						if("m_stat")
							if (istype(src.active1, /datum/data/record))
								src.temp = text("<B>Mental Condition:</B><BR>\n\t<A href='?src=\ref[];temp=1;m_stat=insane'>*Insane*</A><BR>\n\t<A href='?src=\ref[];temp=1;m_stat=unstable'>*Unstable*</A><BR>\n\t<A href='?src=\ref[];temp=1;m_stat=watch'>*Watch*</A><BR>\n\t<A href='?src=\ref[];temp=1;m_stat=stable'>Stable</A><BR>", src, src, src, src)
						if("b_type")
							if (istype(src.active2, /datum/data/record))
								src.temp = text("<B>Blood Type:</B><BR>\n\t<A href='?src=\ref[];temp=1;b_type=an'>A-</A> <A href='?src=\ref[];temp=1;b_type=ap'>A+</A><BR>\n\t<A href='?src=\ref[];temp=1;b_type=bn'>B-</A> <A href='?src=\ref[];temp=1;b_type=bp'>B+</A><BR>\n\t<A href='?src=\ref[];temp=1;b_type=abn'>AB-</A> <A href='?src=\ref[];temp=1;b_type=abp'>AB+</A><BR>\n\t<A href='?src=\ref[];temp=1;b_type=on'>O-</A> <A href='?src=\ref[];temp=1;b_type=op'>O+</A><BR>", src, src, src, src, src, src, src, src)

				else if (href_list["p_stat"])
					if (src.active1)
						switch(href_list["p_stat"])
							if("deceased")
								src.active1.fields["p_stat"] = "*Deceased*"
							if("unconscious")
								src.active1.fields["p_stat"] = "*Unconscious*"
							if("active")
								src.active1.fields["p_stat"] = "Active"
							if("unfit")
								src.active1.fields["p_stat"] = "Physically Unfit"
				else if (href_list["m_stat"])
					if (src.active1)
						switch(href_list["m_stat"])
							if("insane")
								src.active1.fields["m_stat"] = "*Insane*"
							if("unstable")
								src.active1.fields["m_stat"] = "*Unstable*"
							if("watch")
								src.active1.fields["m_stat"] = "*Watch*"
							if("stable")
								src.active2.fields["m_stat"] = "Stable"

				else if (href_list["b_type"])
					if (src.active2)
						switch(href_list["b_type"])
							if("an")
								src.active2.fields["b_type"] = "A-"
							if("bn")
								src.active2.fields["b_type"] = "B-"
							if("abn")
								src.active2.fields["b_type"] = "AB-"
							if("on")
								src.active2.fields["b_type"] = "O-"
							if("ap")
								src.active2.fields["b_type"] = "A+"
							if("bp")
								src.active2.fields["b_type"] = "B+"
							if("abp")
								src.active2.fields["b_type"] = "AB+"
							if("op")
								src.active2.fields["b_type"] = "O+"

				else if (href_list["del_r"])
					if (src.active2)
						src.temp = text("Are you sure you wish to delete the record (Medical Portion Only)?<br>\n\t<A href='?src=\ref[];temp=1;del_r2=1'>Yes</A><br>\n\t<A href='?src=\ref[];temp=1'>No</A><br>", src, src)
				else if (href_list["del_r2"])
					if (src.active2)
						del(src.active2)
				else if (href_list["d_rec"])
					var/datum/data/record/R = locate(href_list["d_rec"])
					var/datum/data/record/M = locate(href_list["d_rec"])
					if (!( data_core.general.Find(R) ))
						src.temp = "Record Not Found!"
						return
					for(var/datum/data/record/E in data_core.medical)
						if ((E.fields["name"] == R.fields["name"] || E.fields["id"] == R.fields["id"]))
							M = E
					src.active1 = R
					src.active2 = M
					src.screen = 4
				else if (href_list["new"])
					if ((istype(src.active1, /datum/data/record) && !( istype(src.active2, /datum/data/record) )))
						var/datum/data/record/R = new /datum/data/record(  )
						R.fields["name"] = src.active1.fields["name"]
						R.fields["id"] = src.active1.fields["id"]
						R.name = text("Medical Record #[]", R.fields["id"])
						R.fields["b_type"] = "Unknown"
						R.fields["mi_dis"] = "None"
						R.fields["mi_dis_d"] = "No minor disabilities have been declared."
						R.fields["ma_dis"] = "None"
						R.fields["ma_dis_d"] = "No major disabilities have been diagnosed."
						R.fields["alg"] = "None"
						R.fields["alg_d"] = "No allergies have been detected in this patient."
						R.fields["cdi"] = "None"
						R.fields["cdi_d"] = "No diseases have been diagnosed at the moment."
						R.fields["notes"] = "No notes."
						data_core.medical += R
						src.active2 = R
						src.screen = 4
				else if (href_list["add_c"])
					if (!( istype(src.active2, /datum/data/record) ))
						return
					var/a2 = src.active2
					var/t1 = input("Add Comment:", "Med. records", null, null)  as message
					if ((!( t1 ) || !( src.authenticated ) || usr.stat || usr.restrained() || get_dist(src, usr) > 1 || src.active2 != a2))
						return
					var/counter = 1
					while(src.active2.fields[text("com_[]", counter)])
						counter++
					src.active2.fields[text("com_[]", counter)] = text("Made by [] ([]) on [], 2053<BR>[]", src.authenticated, src.rank, time2text(world.realtime, "DDD MMM DD hh:mm:ss"), t1)
				else if (href_list["del_c"])
					if ((istype(src.active2, /datum/data/record) && src.active2.fields[text("com_[]", href_list["del_c"])]))
						src.active2.fields[text("com_[]", href_list["del_c"])] = "<B>Deleted</B>"
				else if (href_list["search"])
					var/t1 = input("Search String: (Name or ID)", "Med. records", null, null)  as text
					if ((!( t1 ) || usr.stat || !( src.authenticated ) || usr.restrained() || get_dist(src, usr) > 1))
						return
					src.active1 = null
					src.active2 = null
					t1 = lowertext(t1)
					for(var/datum/data/record/R in data_core.general)
						if ((lowertext(R.fields["name"]) == t1 || t1 == lowertext(R.fields["id"])))
							src.active1 = R
					if (!( src.active1 ))
						src.temp = text("Could not locate record [].", t1)
					else
						for(var/datum/data/record/E in data_core.medical)
							if ((E.fields["name"] == src.active1.fields["name"] || E.fields["id"] == src.active1.fields["id"]))
								src.active2 = E
						src.screen = 4
				else if (href_list["print_p"])
					if (!( src.printing ))
						src.printing = 1
						sleep(50)
						var/obj/item/weapon/paper/P = new /obj/item/weapon/paper( src.loc )
						P.info = "<CENTER><B>Medical Record</B></CENTER><BR>"
						if ((istype(src.active1, /datum/data/record) && data_core.general.Find(src.active1)))
							P.info += text("Name: [] ID: []<BR>\nSex: []<BR>\nAge: []<BR>\nFingerprint: []<BR>\nPhysical Status: []<BR>\nMental Status: []<BR>", src.active1.fields["name"], src.active1.fields["id"], src.active1.fields["sex"], src.active1.fields["age"], src.active1.fields["fingerprint"], src.active1.fields["p_stat"], src.active1.fields["m_stat"])
						else
							P.info += "<B>General Record Lost!</B><BR>"
						if ((istype(src.active2, /datum/data/record) && data_core.medical.Find(src.active2)))
							P.info += text("<BR>\n<CENTER><B>Medical Data</B></CENTER><BR>\nBlood Type: []<BR>\n<BR>\nMinor Disabilities: []<BR>\nDetails: []<BR>\n<BR>\nMajor Disabilities: []<BR>\nDetails: []<BR>\n<BR>\nAllergies: []<BR>\nDetails: []<BR>\n<BR>\nCurrent Diseases: [] (per disease info placed in log/comment section)<BR>\nDetails: []<BR>\n<BR>\nImportant Notes:<BR>\n\t[]<BR>\n<BR>\n<CENTER><B>Comments/Log</B></CENTER><BR>", src.active2.fields["b_type"], src.active2.fields["mi_dis"], src.active2.fields["mi_dis_d"], src.active2.fields["ma_dis"], src.active2.fields["ma_dis_d"], src.active2.fields["alg"], src.active2.fields["alg_d"], src.active2.fields["cdi"], src.active2.fields["cdi_d"], src.active2.fields["notes"])
							var/counter = 1
							while(src.active2.fields[text("com_[]", counter)])
								P.info += text("[]<BR>", src.active2.fields[text("com_[]", counter)])
								counter++
						else
							P.info += "<B>Medical Record Lost!</B><BR>"
						P.info += "</TT>"
						P.name = "paper- 'Medical Record'"
						src.printing = null

		src.add_fingerprint(usr)

		src.updateDialog()
