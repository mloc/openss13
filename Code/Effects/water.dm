/obj/effects/water
	flags 			= 2.0
	icon 			= 'water.dmi'
	icon_state 		= "extinguish"
	mouse_opacity 	= 0
	name 			= "water"
	weight 			= 1000
	var/life 		= 15.0

	New()
		..()
		var/turf/T = src.loc
		if (istype(T, /turf))
			T.firelevel = 0
		spawn(70) del(src)

	Del()
		var/turf/T = src.loc
		if (istype(T, /turf))
			T.firelevel = 0
		..()

	Move(turf/newloc)
		var/turf/T = src.loc
		if (istype(T, /turf))
			T.firelevel = 0
		if (--src.life < 1)
			del(src)
		if(newloc.density)
			return 0
		.=..()
