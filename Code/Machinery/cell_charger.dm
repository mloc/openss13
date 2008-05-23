/**
 * cell_charger -- Allows the charging of power cell (as used in APCs).
 *
 *	Uses an overlay to display the current charge level of the inserted cell
 *
 */

obj/machinery/cell_charger
	name = "cell charger"
	desc = "A charging unit for power cells."
	icon = 'power.dmi'
	icon_state = "ccharger0"
	anchored = 1
	var
		obj/item/weapon/cell/charging = null		// the cell inserted for charging (or null if none)
		chargelevel = -1							// the (cached) charge indicator level (0-4)
													// set -1 to force the indicator to be updated

	// insert a cell into the charger, unless there is already one inside

	attackby(obj/item/weapon/W, mob/user)

		if(stat & BROKEN) return

		if(istype(W, /obj/item/weapon/cell))
			if(charging)
				user << "There is already a cell in the charger."
				return
			else
				user.drop_item()
				W.loc = src
				charging = W
				user << "You insert the cell into the charger."
				chargelevel = -1


			updateicon()


	// updates the icon_state and overlays to reflect a whether a cell is inserted and the charge state

	proc/updateicon()

		icon_state = "ccharger[charging ? 1 : 0]"

		if(charging && !(stat & (BROKEN|NOPOWER)) )

			var/newlevel = 	round( charging.percent() * 4.0 / 99 )

			if(chargelevel != newlevel)		// displayed charge level is cached, so as to only update the overlay when needed

				overlays = null
				overlays += image('power.dmi', "ccharger-o[newlevel]")

				chargelevel = newlevel

		else
			overlays = null


	// removes the cell from the charger (if a cell is inserted)

	attack_hand(mob/user)

		add_fingerprint(user)

		if(stat & BROKEN) return

		if(charging)
			charging.loc = usr
			charging.layer = 20
			if (user.hand )
				user.l_hand = charging
			else
				user.r_hand = charging

			charging.add_fingerprint(user)
			charging.updateicon()

			src.charging = null
			user << "You remove the cell from the charger."
			chargelevel = -1
			updateicon()

	// every cycle, increase the charge level of cell if inserted

	process()

		if(!charging || (stat & (BROKEN|NOPOWER)) )
			return

		var/newch = charging.charge + 5
		newch = min(newch, charging.maxcharge)		// limit to maximum charge capacity of the cell

		use_power((newch - charging.charge) / CELLRATE)
		charging.charge = newch
		updateicon()



