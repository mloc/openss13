/*
 *	Shuttle - machines for shuttle propulsion
 *
 *	These do nothing, but are used in certain places as graphical elements
 *
 *	TODO: Make them actually do something? This would require significant coding for moving objects.
 */

obj/machinery/shuttle
	name = "shuttle"
	icon = 'shuttle.dmi'

	engine
		name = "engine"
		density = 1
		anchored = 1.0

		heater
			name = "heater"
			icon_state = "heater"

		platform
			name = "platform"
			icon_state = "platform"

		propulsion
			name = "propulsion"
			icon_state = "propulsion"
			opacity = 1

			burst
				left
					name = "left"
					icon_state = "burst_l"
				right
					name = "right"
					icon_state = "burst_r"

		router
			name = "router"
			icon_state = "router"
