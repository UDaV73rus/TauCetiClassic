/mob/living/carbon/human/tentacle_grabber
	name = "tentacle grabber"
	icon = 'icons/mob/human/tentari.dmi'
	icon_state = "grabber"
	gender = NEUTER
	pass_flags = PASSTABLE
	w_class = SIZE_BIG
	moveset_type = /datum/combat_moveset/human

	var/datum/bodypart_controller/tentacle/bp_controller
	var/bodies_in_grabber = 0

/mob/living/carbon/human/tentacle_grabber/atom_init(mapload, var/datum/bodypart_controller/tentacle/bp)
	to_chat(world, "Grabber atom_init")
	. = ..(mapload, GRABBER)
	bp_controller = bp
	var/mob/living/carbon/human/owner = bp_controller.BP.owner

	icon = owner.tentacles.tentacle_icon
	
	if(owner.hand != hand)
		swap_hand(TRUE)
	set_a_intent(owner.a_intent)
	set_m_intent(owner.m_intent)

	new /obj/tentacle_body(get_turf(owner), bp_controller, SOUTH)
	bodies_in_grabber = bp_controller.available_length - 1
	bp_controller.available_length = 0

	ADD_TRAIT(owner, TRAIT_ANCHORED, src)
	owner.update_canmove()
	RegisterSignal(src, COMSIG_MOVABLE_PRE_MOVE, PROC_REF(pre_move))
	RegisterSignal(src, COMSIG_CLIENTMOB_MOVE, PROC_REF(client_move))
	RegisterSignal(owner, COMSIG_MOB_SET_A_INTENT, PROC_REF(owner_action_intent_changed))
	RegisterSignal(owner, COMSIG_MOB_SET_M_INTENT, PROC_REF(owner_move_intent_changed))
	// подписаться на /mob/living/carbon/human/Stun Weaken Paralyse jittery
	bp_controller.RegisterSignal(src, COMSIG_HUMAN_HOTKEY_QUICK_EQUIP, TYPE_PROC_REF(/datum/bodypart_controller/tentacle, toggle_retrieving_grabber))
	bp_controller.RegisterSignal(src, COMSIG_HUMAN_HOTKEY_HOLSTER, TYPE_PROC_REF(/datum/bodypart_controller/tentacle, toggle_drag_owner))

/mob/living/carbon/human/tentacle_grabber/Destroy()
	to_chat(world, "Grabber Destroy()")
	var/mob/living/carbon/human/owner = bp_controller.BP.owner
	if(hand == 0) // Delete abstract item in hand
		qdel(owner.r_hand)
	else
		qdel(owner.l_hand)
	var/obj/item/item_in_grabber = get_active_hand()
	if(item_in_grabber && (get_dist(src, owner) <= 1)) // Transfer item held by grabber to owner
		drop_item()
		if(hand == 0)
			owner.put_in_r_hand(item_in_grabber)
		else
			owner.put_in_l_hand(item_in_grabber)
	REMOVE_TRAIT(owner, TRAIT_ANCHORED, src)
	owner.update_canmove()
	
	if(mind)
		mind.transfer_to(owner)
	bp_controller.grabber_destroyed()
	UnregisterSignal(src, COMSIG_MOVABLE_PRE_MOVE)
	UnregisterSignal(src, COMSIG_CLIENTMOB_MOVE)
	UnregisterSignal(owner, COMSIG_MOB_SET_A_INTENT)
	UnregisterSignal(owner, COMSIG_MOB_SET_M_INTENT)
	bp_controller.UnregisterSignal(src, COMSIG_HUMAN_HOTKEY_QUICK_EQUIP)
	bp_controller.UnregisterSignal(src, COMSIG_HUMAN_HOTKEY_HOLSTER)
	. = ..()

/mob/living/carbon/human/tentacle_grabber/proc/owner_action_intent_changed(datum/source, new_intent)
	SIGNAL_HANDLER
	if(!mind)
		set_a_intent(new_intent)

/mob/living/carbon/human/tentacle_grabber/proc/owner_move_intent_changed(datum/source, new_intent)
	SIGNAL_HANDLER
	if(!mind)
		set_m_intent(new_intent)

/mob/living/carbon/human/tentacle_grabber/set_a_intent(new_intent)
	..()
	if(mind)
		bp_controller.BP.owner.set_a_intent(new_intent)

/mob/living/carbon/human/tentacle_grabber/set_m_intent(new_intent)
	if(new_intent != bp_controller.BP.owner.m_intent)
		bp_controller.BP.owner.set_m_intent(new_intent)
	else
		..()

/mob/living/carbon/human/tentacle_grabber/proc/pre_move(datum/source, atom/Newloc, dir)
	SIGNAL_HANDLER
	to_chat(world, "/mob/living/carbon/human/tentacle_grabber/proc/pre_move([source], [Newloc], [dir])")
	for(var/i as anything in bp_controller.BP.owner.tentacles.bodypart_tentacles)
		var/datum/bodypart_controller/tentacle/bp = bp_controller.BP.owner.tentacles.bodypart_tentacles[i]
		if(bp != bp_controller && bp.grabber)
			if(get_turf(bp.grabber) == Newloc && bp.retrieving_state)
				return COMPONENT_MOVABLE_BLOCK_PRE_MOVE
	
	var/last_body_i = bp_controller.tentacle_bodies.len
	var/obj/tentacle_body/last_body = bp_controller.tentacle_bodies[last_body_i]
	if(bodies_in_grabber <= 0 && get_dir(src, Newloc) != last_body.start_dir)
		if(m_intent == MOVE_INTENT_RUN) // Run intent = autodrag
			bp_controller.start_drag_owner()
		return COMPONENT_MOVABLE_BLOCK_PRE_MOVE

/mob/living/carbon/human/tentacle_grabber/Moved(atom/OldLoc, Dir)
	to_chat(world, "Grabber Moved  dir: [Dir]")
	. = ..()
	
	var/last_body_i = bp_controller.tentacle_bodies.len
	var/obj/tentacle_body/last_body = bp_controller.tentacle_bodies[last_body_i]
	var/move_dir = Dir
	if(!move_dir)
		move_dir = get_dir(last_body, src)
	
	if(last_body_i > 1)
		if((last_body.start_dir == Dir || get_turf(bp_controller.tentacle_bodies[last_body_i-1]) == get_turf(src)) && get_turf(OldLoc) != get_turf(src)) // If grabber stepped backward, retrieve body to grabber
			last_body.retrieve_to_grabber()
			return
	
	if(bodies_in_grabber <= 0) // Cannot move further, reached max length
		if(loc != last_body.loc)
			new /obj/tentacle_body/stretched_body(get_turf(src), bp_controller, turn(move_dir, 180))
		return
	
	bodies_in_grabber--
	new /obj/tentacle_body(get_turf(src), bp_controller, turn(move_dir, 180))

/mob/living/carbon/human/tentacle_grabber/swap_hand(is_forced = FALSE)
	if(is_forced)
		..()
	else
		bp_controller.BP.owner.swap_hand()

/mob/living/carbon/human/tentacle_grabber/proc/client_move(datum/source, atom/NewLoc, movedir)
	SIGNAL_HANDLER
	if(ISDIAGONALDIR(movedir))
		return COMPONENT_CLIENTMOB_BLOCK_MOVE
	if(bp_controller.BP.owner.tentacles.dragging_bp != null) // If owner dragging to grabber
		return COMPONENT_CLIENTMOB_BLOCK_MOVE
	if(get_turf(NewLoc) == get_turf(bp_controller.BP.owner)) // Retrieve grabber if moved back to owner
		bp_controller.retrieve_grabber()
	bp_controller.stop_retrieving_grabber()
	return NONE

/mob/living/carbon/human/tentacle_grabber/proc/update_tentacle_icon()
	icon = bp_controller.BP.owner.tentacles.tentacle_icon

/datum/species/grabber
	name = GRABBER

	// icobase = 'icons/mob/human/tentari.dmi'
	icobase = null
	// deformed = 'icons/mob/human_races/r_golem.dmi'
	eyes_colorable_layer = null

	// brute_mod = 0.0
	// burn_mod = 0.0
	oxy_mod = 0.0
	tox_mod = 0.0
	clone_mod = 0.0
	brain_mod = 0.0
	speed_mod = -0.8
	// speed_mod_no_shoes = -2

	blood_datum_path = /datum/dirt_cover/purple_blood
	flesh_color = "#8cd7a3"

	flags = list(
		// NO_BLOOD = TRUE,
		// NO_DNA = TRUE,
		NO_BREATHE = TRUE,
		NO_SCAN = TRUE,
		NO_PAIN = TRUE,
		NO_EMBED = TRUE,
		RAD_IMMUNE = TRUE,
		VIRUS_IMMUNE = TRUE,
		BIOHAZZARD_IMMUNE = TRUE,
		NO_VOMIT = TRUE,
		// NO_FINGERPRINT = TRUE,
		// NO_MINORCUTS = TRUE,
		NO_EMOTION = TRUE,
		NO_MUTATION = TRUE,
		NO_FAT = TRUE,
	)

	has_organ = list(
	)

	gender_body_icons = FALSE

	// min_age = 1
	// max_age = 1000

	// Only left and right hand are present.
	restricted_inventory_slots = list(
		SLOT_BACK,
		SLOT_WEAR_MASK,
		SLOT_HANDCUFFED,
		SLOT_BELT,
		SLOT_WEAR_ID,
		SLOT_L_EAR,
		SLOT_R_EAR,
		SLOT_GLASSES,
		SLOT_GLOVES,
		SLOT_HEAD,
		SLOT_SHOES,
		SLOT_WEAR_SUIT,
		SLOT_W_UNIFORM,
		SLOT_L_STORE,
		SLOT_R_STORE,
		SLOT_S_STORE,
		SLOT_IN_BACKPACK,
		SLOT_LEGCUFFED,
		SLOT_TIE,
		SLOT_EARS,
	)

	// default_mood_event = /datum/mood_event/machine
	unarmed_type = /datum/unarmed_attack/punch

/datum/species/grabber/on_gain(mob/living/carbon/human/H)
	..()
	// Clothing on the Bluespace Debug Creature is created before the hud_list is generated in the atom
	H.prepare_huds()

	// H.status_flags &= ~(CANSTUN | CANWEAKEN | CANPARALYSE)

	qdel(H.GetComponent(/datum/component/mood))

/datum/species/grabber/on_loose(mob/living/carbon/human/H)
	H.status_flags |= MOB_STATUS_FLAGS_DEFAULT
	H.AddComponent(/datum/component/mood)

	..()

// /datum/species/grabber/call_digest_proc(mob/living/M, datum/reagent/R)
// 	return FALSE
