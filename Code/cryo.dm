

/obj/item/weapon/flasks/examine()
	set src in oview(1)

	usr.client_mob() << text("The flask is []% full", (src.oxygen + src.plasma + src.coolant) * 100 / 500)
	usr.client_mob() << "The flask can ONLY store liquids."
	return

/mob/human/abiotic()

	if ((src.l_hand && !( src.l_hand.abstract )) || (src.r_hand && !( src.r_hand.abstract )) || (src.back || src.wear_mask || src.head || src.shoes || src.w_uniform || src.wear_suit || src.w_radio || src.glasses || src.ears || src.gloves))
		return 1
	else
		return 0
	return

/mob/proc/abiotic()

	if ((src.l_hand && !( src.l_hand.abstract )) || (src.r_hand && !( src.r_hand.abstract )) || src.back || src.wear_mask)
		return 1
	else
		return 0
	return

/datum/data/function/proc/reset()

	return

/datum/data/function/proc/r_input(href, href_list, mob/user as mob)

	return

/datum/data/function/proc/display()

	return
