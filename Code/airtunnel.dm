
/obj/move/airtunnel/process()

	if (!( src.deployed ))
		return null
	else
		..()
	return

/obj/move/airtunnel/connector/create()

	src.current = src
	src.next = new /obj/move/airtunnel( null )
	src.next.master = src.master
	src.next.previous = src
	spawn( 0 )
		src.next.create(36, src.y)
		return
	return

/obj/move/airtunnel/connector/wall/create()

	src.current = src
	src.next = new /obj/move/airtunnel/wall( null )
	src.next.master = src.master
	src.next.previous = src
	spawn( 0 )
		src.next.create(36, src.y)
		return
	return

/obj/move/airtunnel/connector/wall/process()

	return

/obj/move/airtunnel/wall/create(num, y_coord)

	if (((num < 7 || (num > 14 && num < 21)) && y_coord == 72))
		src.next = new /obj/move/airtunnel( null )
	else
		src.next = new /obj/move/airtunnel/wall( null )
	src.next.master = src.master
	src.next.previous = src
	if (num > 1)
		spawn( 0 )
			src.next.create(num - 1, y_coord)
			return
	return

/obj/move/airtunnel/wall/move_right()

	flick("wall-m", src)
	return ..()
	return

/obj/move/airtunnel/wall/move_left()

	flick("wall-m", src)
	return ..()
	return

/obj/move/airtunnel/wall/process()

	return

/obj/move/airtunnel/proc/move_left()

	src.relocate(get_step(src, WEST))
	if ((src.next && src.next.deployed))
		return src.next.move_left()
	else
		return src.next
	return

/obj/move/airtunnel/proc/move_right()

	src.relocate(get_step(src, EAST))
	if ((src.previous && src.previous.deployed))
		src.previous.move_right()
	return src.previous
	return

/obj/move/airtunnel/proc/create(num, y_coord)

	if (y_coord == 72)
		if ((num < 7 || (num > 14 && num < 21)))
			src.next = new /obj/move/airtunnel( null )
		else
			src.next = new /obj/move/airtunnel/wall( null )
	else
		src.next = new /obj/move/airtunnel( null )
	src.next.master = src.master
	src.next.previous = src
	if (num > 1)
		spawn( 0 )
			src.next.create(num - 1, y_coord)
			return
	return




/datum/air_tunnel/air_tunnel1/New()

	..()
	for(var/obj/move/airtunnel/A in locate(/area/airtunnel1))
		A.master = src
		A.create()
		src.connectors += A
		//Foreach goto(21)
	return

/datum/air_tunnel/proc/siphons()

	switch(src.siphon_status)
		if(0.0)
			for(var/obj/machinery/atmoalter/siphs/S in locate(/area/airtunnel1))
				S.t_status = 3
				//Foreach goto(42)
		if(1.0)
			for(var/obj/machinery/atmoalter/siphs/fullairsiphon/S in locate(/area/airtunnel1))
				S.t_status = 2
				S.t_per = 1000000.0
				//Foreach goto(86)
			for(var/obj/machinery/atmoalter/siphs/scrubbers/S in locate(/area/airtunnel1))
				S.t_status = 3
				//Foreach goto(136)
		if(2.0)
			for(var/obj/machinery/atmoalter/siphs/S in locate(/area/airtunnel1))
				S.t_status = 4
				//Foreach goto(180)
		if(3.0)
			for(var/obj/machinery/atmoalter/siphs/fullairsiphon/S in locate(/area/airtunnel1))
				S.t_status = 1
				S.t_per = 1000000.0
				//Foreach goto(224)
			for(var/obj/machinery/atmoalter/siphs/scrubbers/S in locate(/area/airtunnel1))
				S.t_status = 3
				//Foreach goto(274)
		else
	return

/datum/air_tunnel/proc/stop()

	src.operating = 0
	return

/datum/air_tunnel/proc/extend()
	if (src.operating)
		return

	spawn(0)
		src.operating = 2
		while(src.operating == 2)
			var/ok = 1
			for(var/obj/move/airtunnel/connector/A in src.connectors)
				if (!( A.current.next ))
					src.operating = 0
					return
				if (!( A.move_left() ))
					ok = 0
				//Foreach goto(56)
			if (!( ok ))
				src.operating = 0
			else
				for(var/obj/move/airtunnel/connector/A in src.connectors)
					if (A.current)
						A.current.next.loc = get_step(A.current.loc, EAST)
						A.current = A.current.next
						A.current.deployed = 1
					else
						src.operating = 0
					//Foreach goto(150)
			sleep(20)
		return

/datum/air_tunnel/proc/retract()

	if (src.operating)
		return
	spawn(0)
		src.operating = 1
		while(src.operating == 1)
			var/ok = 1
			for(var/obj/move/airtunnel/connector/A in src.connectors)
				if (A.current == A)
					src.operating = 0
					return
				if (A.current)
					A.current.loc = null
					A.current.deployed = 0
					A.current = A.current.previous
				else
					ok = 0
				//Foreach goto(56)
			if (!( ok ))
				src.operating = 0
			else
				for(var/obj/move/airtunnel/connector/A in src.connectors)
					if (!( A.current.move_right() ))
						src.operating = 0
					//Foreach goto(188)
			sleep(20)
		return
