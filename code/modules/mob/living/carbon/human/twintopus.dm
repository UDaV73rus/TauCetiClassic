#define DEFAULT_LENGTH 15

/mob/living/carbon/human
	var/list/mob/living/carbon/twintopus_grabber/released_grabbers = list()
	
/mob/living/carbon/human/swap_hand()
	..()
	var/grabber_found = FALSE
	for(var/mob/living/carbon/twintopus_grabber/G in released_grabbers)
		if(hand == G.owner_hand)
			remote_control = G
			grabber_found = TRUE
	if(!grabber_found)
		remote_control = null
////////// TENTACLE BODY
/obj/tentacle_body
	name = "tentacle body"
	icon = 'icons/mob/human_races/r_twintopus.dmi'
	icon_state = "no"
	anchored = TRUE
	var/obj/tentacle_body/previous_body // leads to owner mob
	var/obj/tentacle_body/next_body		// leads to grabber
	var/mob/living/carbon/twintopus_grabber/parent_grabber
	var/mob/living/carbon/human/owner
	var/dir_of_return
	var/returning_state = FALSE

/obj/tentacle_body/atom_init(mapload, var/mob/living/carbon/twintopus_grabber/grabber, var/obj/tentacle_body/prev, var/start_dir, var/end_dir)
	. = ..()
	to_chat(world, "body atom_init")
	if(!grabber)
		to_chat(world, "body atom_init if(!grabber)")
		return
	parent_grabber = grabber
	owner = grabber.owner
	if(prev)
		previous_body = prev
		previous_body.next_body = src

	dir_of_return = turn(end_dir, 180)
	
	start_dir = start_dir ? turn(start_dir, 180) : SOUTH // SOUTH for connecting first t-body sprite with legs sprite
	icon_state =  start_dir < end_dir ? "[start_dir][end_dir]" : "[end_dir][start_dir]"
	to_chat(world, "body atom_init icon_state = [icon_state]")
	
/obj/tentacle_body/Destroy()
	if(previous_body && !returning_state)
		previous_body.cascade_return()
	if(next_body && !returning_state)
		next_body.cascade_cut()
	. = ..()

// chain-cut every tentacle body from src to grabber
/obj/tentacle_body/proc/cascade_cut()
	if(next_body)
		next_body.cascade_cut()
	else if(parent_grabber)
		qdel(parent_grabber)
	var/obj/t = new /obj/item/weapon/reagent_containers/food/snacks/tentacle(get_turf(src))
	t.pixel_x += rand(-6, 6)
	t.pixel_y += rand(-6, 6)
	qdel(src)

// chain-return every tentacle body from src to owner mob
/obj/tentacle_body/proc/cascade_return()
	if(previous_body)
		previous_body.cascade_return()
	qdel(src)

////////// GRABBER
/mob/living/carbon/twintopus_grabber
	name = "tentacle grabber"
	icon = 'icons/mob/human_races/r_twintopus.dmi'
	icon_state = "grabber"
	gender = NEUTER
	pass_flags = PASSTABLE | PASSCRAWL
	w_class = SIZE_BIG
	moveset_type = /datum/combat_moveset/human

	var/mob/living/carbon/human/owner
	var/tentacle_type
	var/owner_hand
	var/obj/tentacle_body/connected_body
	var/previous_dir
	var/returning_state = FALSE

/mob/living/carbon/twintopus_grabber/atom_init(mapload, var/mob/living/carbon/human/H, var/type)
	to_chat(world, "Grabber atom_init")
	. = ..()
	tentacle_type = type
	owner = H
	owner_hand = H.hand
	RegisterSignal(H, list(COMSIG_HUMAN_EQUIP_EMPTY_HAND), PROC_REF(try_return_tentacle))
	RegisterSignal(H, list(COMSIG_HUMAN_HOTKEY_HOLSTER), PROC_REF(try_move_owner))

/mob/living/carbon/twintopus_grabber/Destroy()
	to_chat(world, "Grabber Destroy()")
	owner.released_grabbers -= src
	if(!owner.released_grabbers)
		owner.anchored = FALSE // как быть... TODO additional checks?
	if(connected_body)
		connected_body.cascade_return()
	. = ..()

/mob/living/carbon/twintopus_grabber/Moved(atom/OldLoc, Dir)
	. = ..()
	if(returning_state)
		to_chat(world, "Grabber Moved returning_state")
		return
	var/current_dir = get_dir(OldLoc, src)
	to_chat(world, "Grabber Moved current_dir = [current_dir], previous_dir = [previous_dir]")
	connected_body = new /obj/tentacle_body(get_turf(OldLoc), src, connected_body, previous_dir, current_dir)
	previous_dir = current_dir
	
/mob/living/carbon/twintopus_grabber/update_canmove(no_transform = FALSE)
	..() // need to move as anchored mob
	canmove = !(paralysis || stat || (status_flags & FAKEDEATH) && buckled.buckle_movable)

/mob/living/carbon/twintopus_grabber/relaymove(mob/user, direction)
	if(!user)
		return
	user.client?.move_delay = world.time
	if(user.confused)
		direction = user.confuse_input(direction)
	return Move(get_step(src, direction))

/mob/living/carbon/twintopus_grabber/proc/try_return_tentacle()
	to_chat(world, "Grabber try_return_tentacle1")
	if(!(owner_hand == owner.hand)) // TODO
		return
	if(!(src in owner.released_grabbers) \
	&& !((owner_hand ? BP_L_ARM : BP_R_ARM) in owner.get_missing_bodyparts()))
		qdel(src)
		return
	returning_state = TRUE
	returning()

/mob/living/carbon/twintopus_grabber/proc/returning()
	to_chat(world, "Grabber returning()")
	if(!connected_body.previous_body)
		if(get_dist(owner, src) <= 1) //&& Adjacent(owner)) // successful return, attach body_part back
			owner.remote_control = null // TODO additional checks?
			var/obj/item/organ/external/BP_tentacle = new tentacle_type(null)
			BP_tentacle.insert_organ(owner)
			qdel(src)
			return
	var/loc_before = get_turf(src)
	Move(get_step(src, connected_body.dir_of_return))
	var/loc_current = get_turf(src)
	if(loc_before != loc_current)
		if(loc_current == get_turf(connected_body)) // successful step
			to_chat(world, "Grabber returning() 3 successful step")
			connected_body.returning_state = TRUE
			var/prev = connected_body.previous_body
			qdel(connected_body)
			connected_body = prev
		else // move gone wrong, ex: thru teleport
			to_chat(world, "Grabber returning() 4  gone wrong")
			qdel(src)
			return
	
	to_chat(world, "Grabber returning() 5  CALLBACK")
	addtimer(CALLBACK(src, PROC_REF(returning)), 1)

/mob/living/carbon/twintopus_grabber/proc/try_move_owner()
	if(!(owner_hand == owner.hand)) // TODO
		return
	move_owner()

/mob/living/carbon/twintopus_grabber/proc/move_owner()
	var/obj/tentacle_body/start_body
	if(connected_body)
		start_body = connected_body
		while(start_body.previous_body)
			start_body = start_body.previous_body
	
	if(!start_body)
		if(get_dist(owner, src) <= 1) //&& Adjacent(owner)) // successful return, attach body_part back
			owner.remote_control = null // TODO additional checks?
			var/obj/item/organ/external/BP_tentacle = new tentacle_type(null)
			BP_tentacle.insert_organ(owner)
			qdel(src)
			return
	var/loc_before = get_turf(owner)
	Move(get_step(owner, turn(start_body.dir_of_return, 180)))
	var/loc_current = get_turf(owner)
	if(loc_before != loc_current)
		if(loc_current == get_turf(start_body)) // successful step
			to_chat(world, "Grabber returning() 3 successful step")
			start_body.returning_state = TRUE
			// var/next = start_body.next
			qdel(start_body)
			// start_body = next
		else // move gone wrong, ex: thru teleport
			to_chat(world, "Grabber returning() 4  gone wrong")
			qdel(src)
			return
	
	to_chat(world, "Grabber returning() 5  CALLBACK")
	addtimer(CALLBACK(src, PROC_REF(returning)), 1)


////////// BODYPART_CONTROLLER
/datum/bodypart_controller/twintopus_tentacle
	var/length = DEFAULT_LENGTH
/datum/bodypart_controller/twintopus_tentacle/New(obj/item/organ/external/B)
	..()
	to_chat(world, "controller NEW1")
	RegisterSignal(BP.owner, list(COMSIG_CLIENTMOB_MOVE), PROC_REF(try_release_tentacle))
	to_chat(world, "controller NEW2")

/datum/bodypart_controller/twintopus_tentacle/proc/try_release_tentacle(datum/source, atom/NewLoc, movedir)
	SIGNAL_HANDLER
	to_chat(world, "controller try_release_tentacle1")
	if((BP.owner.hand ? BP_L_ARM : BP_R_ARM) == BP.body_zone)
		release_tentacle(movedir)
		to_chat(world, "controller try_release_tentacle2")
		return COMPONENT_CLIENTMOB_BLOCK_MOVE

/datum/bodypart_controller/twintopus_tentacle/proc/release_tentacle(movedir)
	to_chat(world, "controller release_tentacle1")
	var/mob/living/carbon/human/H = BP.owner
	var/mob/living/carbon/twintopus_grabber/G = new(get_turf(H), H, BP.type)
	to_chat(world, "controller release_tentacle2 G = [G]")
	H.released_grabbers += G
	if(H.remote_control == null)
		H.remote_control = G
	H.anchored = TRUE
	qdel(BP)
	to_chat(world, "controller release_tentacle3")
	step(get_turf(src), movedir)
	to_chat(world, "controller release_tentacle4")

////////// ORGAN ARMS
/obj/item/organ/external/l_arm/twintopus_tentacle
	name = "left tentacle"
	cases = list("левое щупальце", "левого щупальца", "левому щупальцу", "левое щупальце", "левым щупальцем", "левом щупальце")
	controller_type = /datum/bodypart_controller/twintopus_tentacle

// /obj/item/organ/external/l_arm/twintopus_tentacle/atom_init(mapload)
// 	. = ..()

/obj/item/organ/external/r_arm/twintopus_tentacle
	name = "right tentacle"
	cases = list("правое щупальце", "правого щупальца", "правому щупальцу", "правое щупальце", "правым щупальцем", "правом щупальце")
	controller_type = /datum/bodypart_controller/twintopus_tentacle

// /obj/item/organ/external/r_arm/twintopus_tentacle/atom_init(mapload)
// 	. = ..()

////////// SPECIES
/datum/species/twintopus
	name = TWINTOPUS
	icobase = 'icons/mob/human_races/r_twintopus.dmi'
	deform = 'icons/mob/human_races/r_def_skrell.dmi'
	language = LANGUAGE_SKRELLIAN
	primitive = /mob/living/carbon/monkey/skrell
	unarmed_type = /datum/unarmed_attack/punch
	dietflags = DIET_MEAT
	taste_sensitivity = TASTE_SENSITIVITY_DULL

	siemens_coefficient = 1.3
	has_gendered_icons = FALSE

	speed_mod = 1
	speed_mod_no_shoes = 1

	flags = list(
	 IS_WHITELISTED = TRUE
	,HAS_LIPS = TRUE
	,HAS_UNDERWEAR = TRUE
	,HAS_SKIN_COLOR = TRUE
	,FACEHUGGABLE = TRUE
	,HAS_HAIR_COLOR = TRUE
	,IS_SOCIAL = TRUE
	,NO_MINORCUTS = TRUE
	,NO_SLIP = TRUE
	)

	has_bodypart = list(
		 BP_CHEST  = /obj/item/organ/external/chest
		,BP_GROIN  = /obj/item/organ/external/groin
		,BP_HEAD   = /obj/item/organ/external/head
		,BP_L_ARM  = /obj/item/organ/external/l_arm/twintopus_tentacle
		,BP_R_ARM  = /obj/item/organ/external/r_arm/twintopus_tentacle
		,BP_L_LEG  = /obj/item/organ/external/l_leg
		,BP_R_LEG  = /obj/item/organ/external/r_leg
		)

	has_organ = list(
		O_HEART   = /obj/item/organ/internal/heart,
		O_BRAIN   = /obj/item/organ/internal/brain,
		O_EYES    = /obj/item/organ/internal/eyes,
		O_LUNGS   = /obj/item/organ/internal/lungs/skrell,
		O_LIVER   = /obj/item/organ/internal/liver,
		O_KIDNEYS = /obj/item/organ/internal/kidneys
		)

	// eyes = "skrell_eyes"
	blood_datum_path = /datum/dirt_cover/purple_blood
	flesh_color = "#8cd7a3"

	min_age = 25
	max_age = 150

	is_common = TRUE

	// skeleton_type = SKELETON_SKRELL
