/**
 * camera -- A security camera, allows remote viewing of its location from a security computer
 *
 *	Note: Cameras do not use or need power.
 *
 */

obj/machinery/camera
	name = "Security Camera"
	icon = 'stationobjs.dmi'
	icon_state = "camera"
	anchored = 1
	var
		network = "SS13"	// must match the network var of a security computer to allow viewing from that computer
		c_tag = null		// the displayed name of the camera when picking from a security computer
		status = 1.0		// 0 if camera has been disabled
		invuln = null		// if true, camera will not be affected by explosions


	// attacking with wirecutters allows the camera to be disabled/enabled

	attackby(obj/item/weapon/W, mob/user)

		if (istype(W, /obj/item/weapon/wirecutters))
			src.status = !( src.status )
			if (!( src.status ))
				for(var/mob/O in viewers(user, null))
					O.show_message("\red [user] has deactivated [src]!", 1)
				src.icon_state = "camera1"
				//check if anyone is looking through the camera
				for (var/mob/M in world)
					if (istype(M, /mob/ai))
						if (M:current == src)
							M.show_message("\red [user] has deactivated [src]!", 1)
							M:current = null
							M.reset_view(null)
					else
						if (M.machine!=null && istype(M.machine, /obj/machinery/computer/security))
							if (M.machine:current == src)
								M.show_message("\red [user] has deactivated [src]!", 1)
								M.machine:current = null
								M.machine = null
								M.reset_view(null)
			else
				for(var/mob/O in viewers(user, null))
					O.show_message("\red [user] has reactivated [src]!", 1)
				src.icon_state = "camera"
		return

	// called when object is in an explosion
	// if invuln flag is set, explosion has no effect

	ex_act(severity)
		if(src.invuln)
			return
		else
			..(severity)
		return

	// blob attacks have no effect

	blob_act()
		return
