
// shows a browser pop-up window listing the variables in a datum

/proc/Vars(datum/D in view())
	set category = "Debug"

	var/dat = "<HEAD><TITLE>Vars for "

	if(istype(D, /atom))						// if the datum is an atom
		var/atom/A = D							// do special handling
		dat += "[A.name] : [A.type] \ref[A]</TITLE></HEAD><BODY>"

		#ifdef VARSICON
		if(A.icon)								// if the atom has an icon, display it
			dat += variable(usr, "icon", new/icon(A.icon, A.icon_state, A.dir))
		#endif

	else										// not an atom
		dat += "[D] : [D.type] \ref[D]</TITLE><HEAD><BODY>"


	for(var/V in D.vars)						// for each variable in the datum
		dat += variable(usr, V, D.vars[V])	 	//get the text for that variable

	dat += "</BODY>"
	usr.client_mob() << browse(dat, "window=\ref[D]")		// display the browser pop-up


// return a HTML formatted string displaying a variable

/proc/variable(user, vname, val)

	var/t

	if(vname == "*")							// true if this variable is part of a list
		t = "<FONT COLOR=#404040 SIZE=-1>* [val]"	// so format smaller grey text, and just show the value
	else										// otherwise show the name and value without formatting
		if(istext(val))
			t = "<FONT>[vname] = \"[val]\""		// place quotes around text values
		else
			t = "<FONT>[vname] = [val]"


	if(istype(val,/icon))						// if this variable is an icon, display it

		#ifdef VARSICON
		var/rnd = rand(1,10000)					// use random number in filename to avoid conflicts
		user << browse_rsc(val, "tmp\ref[val][rnd].png")	// precache the icon image file
		t+="<IMG SRC=\"tmp\ref[val][rnd].png\">"			// and add the icon to the HTML
		#endif


	else if(istype(val, /datum))				// if this is a datum object
		var/datum/dval = val					// add a link to the object to the HTML
		t+= " ([dval.type]) <A href='?src=\ref[val];Vars=1'><FONT SIZE=-2>\ref[val]</FONT></A>"

	if("[val]" == "/list")						// if this is a list object
		t += " (length [length(val)])</FONT><BR>"

		if( (vname!="vars") && (vname!="verbs") && length(val)<500)	// and it's not vars or verbs, or too long

			for(var/lv in val)					// loop through all items in the list
				t += variable(user, "*", lv)	// and display them

	else
		t += "</FONT><BR>"

	return t					// return the formatted text

// topic handler for linked objects
// invoked when user clicks on an object link in the datum vars pop-up
// note all other Topic procs should call ..() first so this can be called

/datum/Topic(href, href_list)

	if(href_list["Vars"])		// if this link came from the vars window

		Vars(src)				// invoke a new window for this object


/mob/proc/Delete(atom/A in view())
	set category = "Debug"

	switch( alert("Are you sure you wish to delete \the [A.name] at ([A.x],[A.y],[A.z]) ?", "Admin Delete Object","Yes","No") )
		if("Yes")

			if(config.logadmin)	world.log << "ADMIN: [usr.key] deleted [A.name] at ([A.x],[A.y],[A.z])"


			del(A)

