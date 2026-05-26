#define TENCTALE_ICON_DEFAULT 'icons/mob/human/tentari.dmi'
#define TENCTALE_ICON_BURNT 'icons/mob/human/tentari_burnt.dmi'
#define TENCTALE_ICON_HUSK 'icons/mob/human/tentari_husk.dmi'
// #define TENCTALE_ICON_ZOMBIE 'icons/mob/human/tentari.dmi'
#define TENCTALE_ICON_SLIME 'icons/mob/human/tentari.dmi'
#define TENTACLE_ICON_SPACESUIT 'icons/mob/human/tentari_spacesuit_general.dmi'
#define TENTACLE_ICON_SPACESUIT_NATIVE 'icons/mob/human/tentari_spacesuit_native.dmi'


/datum/species/tentari
	name = TENTARI
	icobase = 'icons/mob/human/tentari.dmi'
	// deformed = 'icons/mob/human/tentari_deformed.dmi'
	// skeleton = 'icons/mob/human/tentari_skeleton.dmi'
	skeleton = null
	eyes_colorable_layer = null
	eyes_static_layer = "tentari"
	gender_body_icons = FALSE

	language = LANGUAGE_TENTARIAN
	primitive = /mob/living/carbon/monkey/skrell
	unarmed_type = /datum/unarmed_attack/punch
	dietflags = DIET_MEAT
	taste_sensitivity = TASTE_SENSITIVITY_DULL

	siemens_coefficient = 1.3

	speed_mod = 1
	speed_mod_no_shoes = 1

	flags = list(
	 IS_WHITELISTED = TRUE
	,HAS_LIPS = TRUE
	,HAS_UNDERWEAR = TRUE
	// ,HAS_SKIN_COLOR = TRUE
	,HAS_HAIR_COLOR = TRUE
	,FACEHUGGABLE = TRUE
	,IS_SOCIAL = TRUE
	,NO_SLIP = TRUE // ?
	)

	has_bodypart = list(
		 BP_CHEST  = /obj/item/organ/external/chest
		,BP_GROIN  = /obj/item/organ/external/groin
		,BP_HEAD   = /obj/item/organ/external/head
		,BP_L_ARM  = /obj/item/organ/external/l_arm/tentacle
		,BP_R_ARM  = /obj/item/organ/external/r_arm/tentacle
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

	// sprite_sheets = list(
	// 	SPRITE_SHEET_HEAD     = 'icons/mob/species/tentari/helmet.dmi',
	// 	SPRITE_SHEET_SUIT     = 'icons/mob/species/tentari/suit.dmi',
	// 	SPRITE_SHEET_SUIT_FAT = 'icons/mob/species/tentari/suit_fat.dmi'
	// )

	blood_datum_path = /datum/dirt_cover/purple_blood
	flesh_color = "#8cd7a3"
	default_skin_color = "#06aa00"
	
	butcher_drops = list(/obj/item/weapon/reagent_containers/food/snacks/tentacle = 5)
	bodypart_butcher_results = list(/obj/item/weapon/reagent_containers/food/snacks/tentacle = 2)

	min_age = 25
	max_age = 150

	is_common = TRUE

/mob/living/carbon/human
	var/datum/tentacles/tentacles // Will be created by tentacle bodypart

/mob/living/carbon/human/Destroy()
	qdel(tentacles)
	return ..()

/mob/living/carbon/human/swap_hand()
	var/previous_hand = hand
	..()
	if(tentacles != null)
		tentacles.swap_tentacles(previous_hand)

// datum serve to link /bodypart_controller/tentacle between themselves and integrate them to /human
/datum/tentacles
	var/mob/living/carbon/human/owner
	var/list/datum/bodypart_controller/tentacle/bodypart_tentacles = list()
	var/datum/bodypart_controller/dragging_bp // Owner getting dragged by that bp
	var/tentacle_icon = TENCTALE_ICON_DEFAULT

	var/is_in_spacesuit = FALSE
	var/is_in_nativespacesuit = FALSE
	var/is_burnt = FALSE
	var/is_husk = FALSE
	var/is_slime = FALSE

/datum/tentacles/New(var/mob/living/carbon/human/H)
	to_chat(world, "/datum/tentacles/New")
	owner = H
	RegisterSignal(owner, COMSIG_CLIENTMOB_PREMOVE_CONSCIOUS, TYPE_PROC_REF(/datum/tentacles, premove_try_release_tentacle))

	// Signals for icon updates
	RegisterSignal(owner, list(COMSIG_MOB_EQUIPPED), PROC_REF(mob_equipped))
	RegisterSignal(owner, SIGNAL_ADDTRAIT(TRAIT_HUSK), TYPE_PROC_REF(/datum/tentacles, owner_husked))
	RegisterSignal(owner, SIGNAL_REMOVETRAIT(TRAIT_HUSK), TYPE_PROC_REF(/datum/tentacles, owner_unhusked))
	RegisterSignal(owner, SIGNAL_ADDTRAIT(TRAIT_BURNT), TYPE_PROC_REF(/datum/tentacles, owner_burnt))
	RegisterSignal(owner, SIGNAL_REMOVETRAIT(TRAIT_BURNT), TYPE_PROC_REF(/datum/tentacles, owner_unburnt))
	RegisterSignal(owner, SIGNAL_ADDTRAIT(ELEMENT_TRAIT_SLIME), TYPE_PROC_REF(/datum/tentacles, owner_slimed))
	RegisterSignal(owner, SIGNAL_REMOVETRAIT(ELEMENT_TRAIT_SLIME), TYPE_PROC_REF(/datum/tentacles, owner_unslimed))

/datum/tentacles/Destroy()
	UnregisterSignal(owner, COMSIG_CLIENTMOB_PREMOVE_CONSCIOUS)
	return ..()

/datum/tentacles/proc/update_tentacle_icon()
	var/previous_icon = tentacle_icon
	// Firstly spacesuit, then skin states according to human states priority
	if(is_in_nativespacesuit)
		tentacle_icon = TENTACLE_ICON_SPACESUIT_NATIVE
	else if(is_in_spacesuit)
		tentacle_icon = TENTACLE_ICON_SPACESUIT
	else if(is_husk)
		tentacle_icon = TENCTALE_ICON_HUSK
	else if(is_burnt)
		tentacle_icon = TENCTALE_ICON_BURNT
	else if(is_slime)
		tentacle_icon = TENCTALE_ICON_SLIME
	else
		tentacle_icon = TENCTALE_ICON_DEFAULT

	if(previous_icon == tentacle_icon) // No need to update icons, if didnt changed
		return
	
	for(var/i as anything in bodypart_tentacles)
		var/datum/bodypart_controller/tentacle/bp = bodypart_tentacles[i]
		bp.update_tentacle_icon()

/datum/tentacles/proc/mob_equipped(datum/source, obj/item/I, slot)
	SIGNAL_HANDLER
	if(slot != SLOT_WEAR_SUIT)
		return
	if(I.flags_pressure == 0)
		return
	is_in_spacesuit = TRUE
	if(istype(I, /obj/item/clothing/suit/space/tentari))
		is_in_nativespacesuit = TRUE
	// I.RegisterSignal()
	update_tentacle_icon()

/datum/tentacles/proc/owner_spacesuit_unequiped(var/obj/cloth/suit/S)
	// S.UnregisterSignal()
	is_in_spacesuit = FALSE
	is_in_nativespacesuit = FALSE
	update_tentacle_icon()

/datum/tentacles/proc/owner_husked()
	SIGNAL_HANDLER
	is_husk = TRUE
	update_tentacle_icon()

/datum/tentacles/proc/owner_unhusked()
	SIGNAL_HANDLER
	is_husk = FALSE
	update_tentacle_icon()

/datum/tentacles/proc/owner_burnt()
	SIGNAL_HANDLER
	is_burnt = TRUE
	update_tentacle_icon()

/datum/tentacles/proc/owner_unburnt()
	SIGNAL_HANDLER
	is_burnt = FALSE
	update_tentacle_icon()

/datum/tentacles/proc/owner_slimed()
	SIGNAL_HANDLER
	is_slime = TRUE
	update_tentacle_icon()

/datum/tentacles/proc/owner_unslimed()
	SIGNAL_HANDLER
	is_slime = FALSE
	update_tentacle_icon()

/datum/tentacles/proc/swap_tentacles(var/previous_hand)
	to_chat(world, "/datum/tentacles/proc/swap_tentacles")
	var/datum/bodypart_controller/tentacle/previous_bp = bodypart_tentacles[previous_hand == 0 ? BP_R_ARM : BP_L_ARM]
	var/datum/bodypart_controller/tentacle/next_bp = bodypart_tentacles[owner.hand == 0 ? BP_R_ARM : BP_L_ARM]
	
	var/datum/mind/mind = owner.mind ? owner.mind : previous_bp.grabber.mind
	var/mob/swap_to_mob = next_bp?.grabber == null ? owner : next_bp.grabber
	mind.transfer_to(swap_to_mob)

/datum/tentacles/proc/premove_try_release_tentacle(datum/source, atom/NewLoc, movedir)
	SIGNAL_HANDLER
	var/datum/bodypart_controller/tentacle/bp_controller = bodypart_tentacles[owner.hand == 0 ? BP_R_ARM : BP_L_ARM]
	if(bp_controller != null)
		if(!ISDIAGONALDIR(movedir))
			bp_controller.release_tentacle(movedir)
		return COMPONENT_CLIENTMOB_BLOCK_PREMOVE_CONSCIOUS
	return NONE

////////// ORGAN ARMS
/obj/item/organ/external/l_arm/tentacle
	name = "left tentacle"
	cases = list("левое щупальце", "левого щупальца", "левому щупальцу", "левое щупальце", "левым щупальцем", "левом щупальце")
	controller_type = /datum/bodypart_controller/tentacle

// /obj/item/organ/external/l_arm/tentacle/atom_init(mapload)
// 	. = ..()

/obj/item/organ/external/r_arm/tentacle
	name = "right tentacle"
	cases = list("правое щупальце", "правого щупальца", "правому щупальцу", "правое щупальце", "правым щупальцем", "правом щупальце")
	controller_type = /datum/bodypart_controller/tentacle

// /obj/item/organ/external/r_arm/tentacle/atom_init(mapload)
// 	. = ..()

/obj/item/released_tentacle_abstract
	name = "released tentacle"
	icon = 'icons/mob/human/tentari.dmi'
	icon_state = "grabber"
	w_class = SIZE_LARGE
	flags = ABSTRACT | NODROP | DROPDEL
	canremove = FALSE
