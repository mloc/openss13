/**
 * Recharger -- A recharger is a piece of Machinery that re-supplys tazers and lazers.
 *
 * TODO: Need seriously improved documentation on this object. Most of the procs and
 *       variables seem to live elsewhere, need a project decision on how these cases
 *       get documented and referenced.
 */
obj/machinery/recharger
	anchored = 1.0
	icon = 'stationobjs.dmi'
	icon_state = "recharger0"
	name = "recharger"

	var
		obj/item/weapon/gun/energy/charging = null	// the weapon being charged, or null if none

	// attacking with a gun inserts the gun into the charger

	attackby(obj/item/weapon/G, mob/user)
		if (src.charging)
			return
		if (istype(G, /obj/item/weapon/gun/energy))
			user.drop_item()
			G.loc = src
			src.charging = G

	// hand attack removes the gun from the charger (and leaves it on the same turf)

	attack_hand(mob/user)
		src.add_fingerprint(user)
		if (src.charging)
			src.charging.update_icon()
			src.charging.loc = src.loc
			src.charging = null

	// monkey attack same as human if in monkey mode

	attack_paw(mob/user)
		if ((ticker && ticker.mode == "monkey"))
			return src.attack_hand(user)

	// if a gun is inserted, recharge once per second until fully charged

	process()
		if (src.charging && ! (stat & NOPOWER) )
			if (src.charging.charges < 10)
				src.charging.charges++
				src.icon_state = "recharger1"
				use_power(250)
			else
				src.icon_state = "recharger2"
		else
			src.icon_state = "recharger0"
