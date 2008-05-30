// If you don't have the wallFloorSpaceChanges-darkSpaceFix.dm enabled, enable this dm instead.
// See wallFloorSpaceChanges-darkSpaceFix.dm for more information.

/turf/proc/ReplaceWithFloor()
	var/turf/station/floor/W
	W = new /turf/station/floor( locate(src.x, src.y, src.z) )
	return W

/turf/proc/ReplaceWithSpace()
	var/turf/space/S = new /turf/space( locate(src.x, src.y, src.z) )
	return S

/turf/proc/ReplaceWithWall()
	var/turf/station/wall/S = new /turf/station/wall( locate(src.x, src.y, src.z) )
	return S

/turf/proc/ReplaceWithRWall()
	var/turf/station/r_wall/S = new /turf/station/r_wall( locate(src.x, src.y, src.z) )
	return S
