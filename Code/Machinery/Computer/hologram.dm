/*
 *	/obj/machinery/computer/hologram_comp - Hologram computer
 *
 *	/obj/machinery/holograp_proj - Hologram projector
 *
 *	/obj/projection	- Hologram projection
 *
 *	Used to display a mob with variable skin colour, hair, etc.
 */


/*
 * The hologram computer
 */


obj/machinery/computer/hologram_comp
	name = "Hologram Computer"
	icon = 'stationobjs.dmi'
	icon_state = "holo_console0"

	var
		obj/machinery/hologram_proj/projector = null	// the projector object associated with this computer
		temp = null				// temporary text for interaction window (not used)
		lumens = 0.0			// brightness of the hologram skin image
		h_r = 245.0				//
		h_g = 245.0				// RGB settings for the hologram hair
		h_b = 245.0				//


	// Create a new computer
	// After world has finished loading, located the hologram projector to the north

	New()
		..()
		spawn( 10 )
			src.projector = locate(/obj/machinery/hologram_proj, get_step(src.loc, NORTH))


	// Interact when double clicked
	// Possibly using this instead of usual attack_hand() because its designed to be used before game starts
	// However this doesn't seem to be necessary in the current code

	DblClick()
		if (get_dist(src, usr) > 1)
			return 0
		src.show_console(usr)


	// Render a human male with the current settings
	// Set the projector to use the resulting icon

	proc/render()
		var/icon/I = new /icon( 'human.dmi', "male" )
		if (src.lumens >= 0)
			I.Blend(rgb(src.lumens, src.lumens, src.lumens), 0)
		else
			I.Blend(rgb(- src.lumens,  -src.lumens,  -src.lumens), 1)
		I.Blend(new /icon( 'human.dmi', "mouth" ), 3)
		var/icon/U = new /icon( 'human.dmi', "diaper" )
		U.Blend(U, 3)
		U = new /icon( 'mob.dmi', "hair_a" )
		U.Blend(rgb(src.h_r, src.h_g, src.h_b), 0)
		I.Blend(U, 3)
		src.projector.projection.icon = I


	// Show interaction window

	proc/show_console(var/mob/user)

		var/dat
		user.machine = src
		if (src.temp)
			dat = "[temp]<BR><BR><A href='?src=\ref[src];temp=1'>Clear</A>"
		else
			dat = {"<B>Hologram Status:</B><HR>
Power: <A href='?src=\ref[src];power=1'>[(src.projector.projection ? "On" : "Off")]</A><HR>
<B>Hologram Control:</B><BR>
Color Luminosity: [-src.lumens + 35]/220 <A href='?src=\ref[src];reset=1'>\[Reset\]</A><BR>
Lighten: <A href='?src=\ref[src];light=1'>1</A> <A href='?src=\ref[src];light=10'>10</A><BR>
Darken: <A href='?src=\ref[src];light=-1'>1</A> <A href='?src=\ref[src];light=-10'>10</A><BR>
<BR>
Hair Color: ([h_r],[h_g],[h_b]) <A href='?src=\ref[src];h_reset=1'>\[Reset\]</A><BR>
Red (0-255): <A href='?src=\ref[src];h_r=-300'>\[0\]</A> <A href='?src=\ref[src];h_r=-10'>-10</A> <A href='?src=\ref[src];h_r=-1'>-1</A> [h_r] <A href='?src=\ref[src];h_r=1'>1</A> <A href='?src=\ref[src];h_r=10'>10</A> <A href='?src=\ref[src];h_r=300'>\[255\]</A><BR>
Green (0-255): <A href='?src=\ref[src];h_g=-300'>\[0\]</A> <A href='?src=\ref[src];h_g=-10'>-10</A> <A href='?src=\ref[src];h_g=-1'>-1</A> [h_g] <A href='?src=\ref[src];h_g=1'>1</A> <A href='?src=\ref[src];h_g=10'>10</A> <A href='?src=\ref[src];h_g=300'>\[255\]</A><BR>
Blue (0-255): <A href='?src=\ref[src];h_b=-300'>\[0\]</A> <A href='?src=\ref[src];h_b=-10'>-10</A> <A href='?src=\ref[src];h_b=-1'>-1</A> [h_b] <A href='?src=\ref[src];h_b=1'>1</A> <A href='?src=\ref[src];h_b=10'>10</A> <A href='?src=\ref[src];h_b=300'>\[255\]</A><BR>"}
		user.client_mob() << browse(dat, "window=hologram_console")


	// Handle topic links from window

	Topic(href, href_list)
		..()
		if (get_dist(src, usr) <= 1)
			flick("holo_console1", src)
			if (href_list["power"])
				if (src.projector.projection)					// remove the current projection
					src.projector.icon_state = "hologram0"
					del(src.projector.projection)
				else											// create a new projection
					src.projector.projection = new /obj/projection( src.projector.loc )
					src.projector.projection.icon = 'human.dmi'
					src.projector.projection.icon_state = "male"
					src.projector.icon_state = "hologram1"
					src.render()
			else if (href_list["h_r"])
				if (src.projector.projection)
					src.h_r += text2num(href_list["h_r"])
					src.h_r = min(max(src.h_r, 0), 255)
					render()
			else if (href_list["h_g"])
				if (src.projector.projection)
					src.h_g += text2num(href_list["h_g"])
					src.h_g = min(max(src.h_g, 0), 255)
					render()
			else if (href_list["h_b"])
				if (src.projector.projection)
					src.h_b += text2num(href_list["h_b"])
					src.h_b = min(max(src.h_b, 0), 255)
					render()
			else if (href_list["light"])
				if (src.projector.projection)
					src.lumens += text2num(href_list["light"])
					src.lumens = min(max(src.lumens, -185.0), 35)
					render()
			else if (href_list["reset"])
				if (src.projector.projection)
					src.lumens = 0
					render()
			else if (href_list["temp"])
				src.temp = null

			for(var/mob/M in viewers(1, src))
				if ((M.client && M.machine == src))
					src.show_console(M)


/*
 * The hologram projector
 */


obj/machinery/hologram_proj
	name = "Hologram Projector"
	icon = 'stationobjs.dmi'
	icon_state = "hologram0"
	anchored = 1
	var
		obj/projection/projection = null			// the projection object


/*
 *	The projected hologram
 */

/obj/projection
	name = "Projection"
	anchored = 1.0