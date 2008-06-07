/*
 *	Poddoor -- A remotely controlled door. Operable from pod computers and remote door controls.
 *
 */


obj/machinery/door/poddoor
	name = "poddoor"
	icon = 'Door1.dmi'
	icon_state = "pdoor1"
	var
		id = 1.0			// ID that must match that of the controlling device


	// Standard open() and close() procs do not work

	open()
		usr.client_mob() << "This is a remote controlled door!"

	close()
		usr.client_mob() << "This is a remote controlled door!"



	// Attack by item.
	// If crowbar (and door unpowered), open the door

	attackby(obj/item/weapon/C as obj, mob/user as mob)
		src.add_fingerprint(user)
		if (!( istype(C, /obj/item/weapon/crowbar) ))
			return
		if ((src.density && (stat & NOPOWER) && !( src.operating )))
			spawn( 0 )
				src.operating = 1
				flick("pdoorc0", src)
				src.icon_state = "pdoor0"
				sleep(15)
				src.density = 0
				src.opacity = 0
				var/turf/T = src.loc
				if (istype(T, /turf))
					T.updatecell = 1
					T.buildlinks()
				src.operating = 0
				return

	// Called to open a poddoor

	proc/openpod()
		set src in oview(1)

		if(stat & NOPOWER) return

		if (src.operating || !src.density)
			return
		src.operating = 1
		use_power(50)
		flick("pdoorc0", src)
		src.icon_state = "pdoor0"
		sleep(15)
		src.density = 0
		src.opacity = 0
		var/turf/T = src.loc
		if (istype(T, /turf))
			T.updatecell = 1
			T.buildlinks()
		src.operating = 0


	// Called to close a poddoor

	proc/closepod()
		set src in oview(1)

		if(stat & NOPOWER) return

		if (src.operating || src.density)
			return
		use_power(50)
		src.operating = 1
		flick("pdoorc1", src)
		src.icon_state = "pdoor1"
		src.density = 1
		src.opacity = 1
		var/turf/T = src.loc
		if (istype(T, /turf))
			T.updatecell = 0
			T.buildlinks()
		sleep(15)
		src.operating = 0
