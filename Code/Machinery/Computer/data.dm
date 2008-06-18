/*
 *	Data -- A computer that displays data
 *
 *	All these do is display a list of entries, Each entry can be read to display information about it.
 *
 */


obj/machinery/computer/data
	name = "data"
	icon = 'weap_sat.dmi'
	icon_state = "computer"

	var
		list/topics = list(  )			// An associative list of entries and content


	// Display the list of entries

	verb/display()
		set src in oview(1)
		var/result = src.canReach(usr, null, 1)
		if (result==0)
			usr.client_mob() << "You can't reach [src]."
			return

		for(var/x in src.topics)
			usr.client_mob() << "[x], \..."

		usr.client_mob() << ""
		src.add_fingerprint(usr)
		return


	// Display the content of an entry, given the entry name as an argument

	verb/read(topic as text)
		set src in oview(1)
		var/result = src.canReach(usr, null, 1)
		if (result==0)
			usr.client_mob() << "You can't reach [src]."
			return

		if (src.topics[text("[]", topic)])
			usr.client_mob() << "<B>[topic]</B>\n\t [src.topics["[topic]"]]"
		else
			usr.client_mob() << "Unable to find- [topic]"
		src.add_fingerprint(usr)
		return



	weapon
		name = "weapon"

		info
			name = "Research Computer"

			// Create the entries and content for this computer

			New()
				..()
				src.topics["LOG(001)"] = "System: Deployment successful"
				src.topics["LOG(002)"] = "System: Safe orbit at inclination .003 established"
				src.topics["LOG(003)"] = "CenCom: Attempting test fire...ALERT(001)"
				src.topics["ALERT(001)"] = "System: Cannot attempt test fire"
				src.topics["LOG(004)"] = "System: Airlock accessed..."
				src.topics["LOG(005)"] = "System: System successfully reset...Generator engaged"
				src.topics["LOG(006)"] = "Physical: Super-heater (W005) added to power grid"
				src.topics["LOG(007)"] = "Physical: Amplifier (W007) added to power grid"
				src.topics["LOG(008)"] = "Physical: Plasma Energizer (W006) added to power grid"
				src.topics["LOG(009)"] = "Physical: Laser (W004) added to power grid"
				src.topics["LOG(010)"] = "Physical: Laser test firing"
				src.topics["LOG(011)"] = "Physical: Plasma added to Super-heater"
				src.topics["LOG(012)"] = "Physical: Orient N12.525,E22.124"
				src.topics["LOG(013)"] = "System: Location N12.525,E22.124"
				src.topics["LOG(014)"] = "Physical: Test fire...successful"
				src.topics["LOG(015)"] = "Physical: Airlock accessed..."
				src.topics["LOG(016)"] = "******: Disable locater systems"
				src.topics["LOG(017)"] = "System: Locater Beacon-Disengaged,CenCom link-Cut...ALERT(002)"
				src.topics["ALERT(002)"] = "System: Cannot seem to establish contact with Central Command"
				src.topics["LOG(018)"] = "******: Shutting down all systems...ALERT(003)"
				src.topics["ALERT(003)"] = "System: Power grid failure-Activating back-up power...ALERT(004)"
				src.topics["ALERT(004)"] = "System: Engine failure...All systems deactivated."


			// Overrides display verb to show a title

			display()
				set src in oview(1)
				var/result = src.canReach(usr, null, 1)
				if (result==0)
					usr.client_mob() << "You can't reach [src]."
					return

				usr.client_mob() << "<B>Research Information:</B>"
				..()
				return


		log
			name = "Log Computer"


			// Create the list for this computer

			New()
				..()
				src.topics["Super-heater"] = "This turns a can of semi-liquid plasma into a super-heated ball of plasma."
				src.topics["Amplifier"] = "This increases the intensity of a laser."
				src.topics["Class 11 Laser"] = "This creates a very slow laser that is capable of penetrating most objects."
				src.topics["Plasma Energizer"] = "This combines super-heated plasma with a laser beam."
				src.topics["Generator"] = "This controls the entire power grid."
				src.topics["Mirror"] = "this can reflect LOW power lasers. HIGH power goes through it!"
				src.topics["Targetting Prism"] = "This focuses a laser coming from any direction forward."


			// Override display verb to show a title

			display()
				set src in oview(1)
				var/result = src.canReach(usr, null, 1)
				if (result==0)
					usr.client_mob() << "You can't reach [src]."
					return

				usr.client_mob() << "<B>Research Log:</B>"
				..()
				return

