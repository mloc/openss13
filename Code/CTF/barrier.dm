/obj/barrier
	anchored = 1.0
	density = 1
	icon = 'stationobjs.dmi'
	icon_state = "barrier"
	name = "barrier"
	opacity = 1	

	New()
		var/t = 1800
		if (ctf)
			t = round(ctf.barriertime * 600)
		spawn(t) del(src)
