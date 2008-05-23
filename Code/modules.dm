
// module datum.
// this is per-object instance, and shows the condition of the modules in the object
// actual modules needed is referenced through modulestypes and the object type

/datum/module
	var/status				// bits set if working, 0 if broken
	var/installed			// bits set if installed, 0 if missing

// moduletypes datum
// this is per-object type, and shows the modules needed for a type of object

/datum/moduletypes
	var/list/modcount = list()	// assoc list of the count of modules for a type


var/list/modules = list(			// global associative list
"/obj/machinery/power/apc" = "card_reader,power_control,id_auth,cell_power,cell_charge")





/datum/module/New(var/obj/O)

	var/type = O.type		// the type of the creating object

	var/mneed = mods.inmodlist(type)		// find if this type has modules defined

	if(!mneed)		// not found in module list?
		del(src)	// delete self, thus ending proc

	var/needed = mods.getbitmask(type)		// get a bitmask for the number of modules in this object
	status = needed
	installed = needed

/datum/moduletypes/proc/addmod(var/type, var/modtextlist)

	modules += type	// index by type text
	modules[type] = modtextlist


/datum/moduletypes/proc/inmodlist(var/type)
	return ("[type]" in modules)

/datum/moduletypes/proc/getbitmask(var/type)
	var/count = modcount["[type]"]
	if(count)
		return 2**count-1

	var/modtext = modules["[type]"]
	var/num = 1
	var/pos = 1

	while(1)
		pos = findText(modtext, ",", pos, 0)
		if(!pos)
			break
		else
			pos++
			num++

	modcount += "[type]"
	modcount["[type]"] = num

	return 2**num-1


/obj/item/weapon/module
	icon = 'module.dmi'
	icon_state = "std_module"
	w_class = 2.0
	s_istate = "electronic"
	flags = FPRINT|DRIVABLE|TABLEPASS
	var/mtype = 1						// 1=electronic 2=hardware

/obj/item/weapon/module/card_reader
	name = "card reader module"
	icon_state = "card_mod"
	desc = "An electronic module for reading data and ID cards."

/obj/item/weapon/module/power_control
	name = "power control module"
	icon_state = "power_mod"
	desc = "Heavy-duty switching circuits for power control."

/obj/item/weapon/module/id_auth
	name = "ID authentication module"
	icon_state = "id_mod"
	desc = "A module allowing secure authorization of ID cards."
	var/access = null
	var/allowed = null

/obj/item/weapon/module/cell_power
	name = "power cell regulator module"
	icon_state = "power_mod"
	desc = "A converter and regulator allowing the use of power cells."

/obj/item/weapon/module/cell_power
	name = "power cell charger module"
	icon_state = "power_mod"
	desc = "Charging circuits for power cells."




