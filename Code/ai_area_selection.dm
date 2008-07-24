/proc/get_area(area/A)
	while(!istype(A, /area) && A)
		A = A.loc
	return A


/var/const/INFINITY = 1e20 //close enough

/turf/DblClick()
	if(usr.stat || !istype(usr, /mob/ai))
		return ..()
	if (world.time <= usr:lastDblClick+2)
		return ..()

	//try to find the closest working camera in the same area, switch to it
	var/area/A = get_area(src)
	var/best_dist = INFINITY
	var/best_cam = null
	for(var/obj/machinery/camera/C in A)
		if(usr:network != C.network)
			continue // different network (syndicate)
		if(C.z != usr.z)
			continue // different viewing plane
		if(!C.status)
			continue // ignore disabled cameras
		var/dist = get_dist(src, C)
		if(dist < best_dist)
			best_dist = dist
			best_cam = C
	
	if(!best_cam)
		return ..()
	usr:lastDblClick = world.time
	usr:current = best_cam
	usr:reset_view(best_cam)
	usr:cameraFollow = null
