/* TODO
Восстановление лимита

Урон овнеру
Убрать переломы и все все все. Пока только у рук
Перенос накаченности мышц и тп
Продолжение драгинга после возврата тентаклей
Говорить и слушать от лица хозяина

Звуки

Красивости при вытягивании

на будущее:
Запрет кликать при превышении лимита?
Зрение от овнера?
Anchored и состояние овнера, в станах встает и тд :(
*/
#define TENTACLE_MAX_LENGTH 15 // including bodies under owner and grabber

/datum/bodypart_controller/tentacle
	var/list/obj/tentacle_body/tentacle_bodies = list()
	var/mob/living/carbon/human/tentacle_grabber/grabber
	var/max_length = TENTACLE_MAX_LENGTH
	var/current_length = TENTACLE_MAX_LENGTH // Decreased when tentacle cut off. Regenerate naturally
	var/available_length = TENTACLE_MAX_LENGTH // When grabber released it becomes 0, grabber gets this number
	var/retrieving_state = FALSE
	var/stretched_bodies = 0 // Count of stretched bodies

/datum/bodypart_controller/tentacle/New(obj/item/organ/external/B)
	..()
	to_chat(world, "bodypart_controller NEW")
	RegisterSignal(BP, COMSIG_ORGAN_EXTERNAL_PRE_DROPLIMB, TYPE_PROC_REF(/datum/bodypart_controller/tentacle, pre_droplimb))
	RegisterSignal(BP, COMSIG_ORGAN_EXTERNAL_POST_INSERT_ORGAN, TYPE_PROC_REF(/datum/bodypart_controller/tentacle, post_insert_organ))
	
/datum/bodypart_controller/tentacle/Destroy()
	to_chat(world, "/datum/bodypart_controller/tentacle/Destroy()")
	remove_self()
	. = ..()

/datum/bodypart_controller/tentacle/proc/pre_droplimb()
	SIGNAL_HANDLER
	remove_self()
	
/datum/bodypart_controller/tentacle/proc/post_insert_organ()
	SIGNAL_HANDLER
	if(BP.owner.tentacles == null)
		BP.owner.tentacles = new /datum/tentacles(BP.owner)
	BP.owner.tentacles.bodypart_tentacles[BP.body_zone] = src

/datum/bodypart_controller/tentacle/proc/remove_self()
	cut_bodies_from_index(1)
	BP.owner.tentacles.bodypart_tentacles.Remove(BP.body_zone)

/datum/bodypart_controller/tentacle/proc/body_destroyed(var/obj/tentacle_body/T)
	to_chat(world, "bodypart_controller body_destroyed")
	var/body_index = tentacle_bodies.Find(T)
	cut_bodies_from_index(body_index+1) // Cut bodies after destroyed body
	retrieve_bodies_from_index(body_index-1) // Retrieve bodies before destroyed body

/datum/bodypart_controller/tentacle/proc/grabber_destroyed()
	to_chat(world, "bodypart_controller grabber_destroyed")
	if(BP.owner.tentacles.dragging_bp == src)
		stop_drag_owner()
	grabber = null

/datum/bodypart_controller/tentacle/proc/release_tentacle(movedir)
	to_chat(world, "bodypart_controller release_tentacle1")
	stop_drag_owner()
	grabber = new(get_turf(BP.owner), src)
	var/obj/item/item_in_hand = BP.owner.get_active_hand()
	if(item_in_hand) // Transfer item held in hand to grabber
		BP.owner.drop_item()
		grabber.put_in_active_hand(item_in_hand)
	BP.owner.put_in_active_hand(new /obj/item/released_tentacle_abstract(null))
	BP.owner.mind.transfer_to(grabber)

// Chain-cut every tentacle bodies from index to grabber
/datum/bodypart_controller/tentacle/proc/cut_bodies_from_index(var/i)
	to_chat(world, "bodypart_controller cut_bodies_from_index1")
	if(i < 1)
		return
	if(i > tentacle_bodies.len)
		cut_grabber()
		return
	tentacle_bodies[i].cut()
	cut_bodies_from_index(i) // Cut next body, current i already deleted

// Chain-retrieve every tentacle bodies from index to owner mob
/datum/bodypart_controller/tentacle/proc/retrieve_bodies_from_index(var/i)
	to_chat(world, "bodypart_controller retrieve_bodies_from_index [i]")
	if((i < 1) || (i > tentacle_bodies.len))
		return
	tentacle_bodies[i].retrieve_to_owner()
	retrieve_bodies_from_index(i-1)

/datum/bodypart_controller/tentacle/proc/toggle_retrieving_grabber()
	SIGNAL_HANDLER
	if(!grabber)
		return
	if(retrieving_state)
		stop_retrieving_grabber()
	else
		start_retrieving_grabber()

/datum/bodypart_controller/tentacle/proc/start_retrieving_grabber()
	stop_drag_owner()
	if(retrieving_state == FALSE) // This check preventing multiple calls of retrieving_grabber()
		retrieving_state = TRUE
		retrieving_grabber()

/datum/bodypart_controller/tentacle/proc/stop_retrieving_grabber()
	retrieving_state = FALSE

/datum/bodypart_controller/tentacle/proc/retrieving_grabber()
	to_chat(world, "bodypart_controller retrieving_grabber")
	if(!retrieving_state)
		return
	var/len = tentacle_bodies.len
	if(len == 2) // 2 bodies - means that grabber should be next to owner
		if(retrieve_grabber())
			return // This check may legitly fail without derail, if tentacle released right in wormhole for example
	else if(len == 1) // Check if grabber under owner.
		if(!retrieve_grabber())
			to_chat(world, "bodypart_controller retrieving_grabber2 DERAILED")
			cut_grabber() // DERAILED
		return

	grabber.Move(get_step(grabber, tentacle_bodies[len].start_dir)) // After succesfull step, last body should be retrieved, handled in /mob/living/carbon/human/tentacle_grabber/Moved()

	if(get_turf(grabber) != get_turf(tentacle_bodies[tentacle_bodies.len])) // If moved, next last body should be under grabber
		to_chat(world, "bodypart_controller retrieving_grabber3 DERAILED")
		cut_grabber() // DERAILED
		return

	addtimer(CALLBACK(src, PROC_REF(retrieving_grabber)), 1)

/datum/bodypart_controller/tentacle/proc/retrieve_grabber() // TRUE - retrieved. FALSE - retrieve failed.
	to_chat(world, "bodypart_controllerretrieve_grabber1")
	if(!grabber)
		return FALSE
	var/distance = get_dist(BP.owner, grabber)
	if(distance > 1)
		return FALSE

	available_length += grabber.bodies_in_grabber
	var/dir_to_grabber = tentacle_bodies[1].end_dir
	var/is_bp_dragging = BP.owner.tentacles.dragging_bp == src
	retrieve_bodies_from_index(tentacle_bodies.len)
	qdel(grabber)
	if(is_bp_dragging)
		BP.owner.Move(get_step(BP.owner, dir_to_grabber)) // Owner step into grabber tile
	return TRUE

/datum/bodypart_controller/tentacle/proc/cut_grabber()
	to_chat(world, "bodypart_controller cut_grabber1")
	if(!grabber)
		return
	cut_bodies_from_index(tentacle_bodies.len) // Cut body under grabber
	retrieve_bodies_from_index(tentacle_bodies.len) // Retrieve other bodies. No checks if bodies are lost as well, but its okay. Keep it simple
	qdel(grabber)

/datum/bodypart_controller/tentacle/proc/toggle_drag_owner()
	SIGNAL_HANDLER
	if(BP.owner.tentacles.dragging_bp == null)
		start_drag_owner()
	else
		stop_drag_owner()

/datum/bodypart_controller/tentacle/proc/start_drag_owner()
	if(!grabber)
		return
	if(stretched_bodies > 0)
		return
	if(BP.owner.tentacles.dragging_bp == src)
		return
	var/no_other_grabbers = TRUE
	for(var/i as anything in BP.owner.tentacles.bodypart_tentacles)
		var/datum/bodypart_controller/tentacle/bp = BP.owner.tentacles.bodypart_tentacles[i]
		if(bp == src)
			continue
		if(bp.grabber != null)
			no_other_grabbers = FALSE
			bp.start_retrieving_grabber()
	if(no_other_grabbers)
		stop_retrieving_grabber()
		BP.owner.tentacles.dragging_bp = src
		dragging_owner()

/datum/bodypart_controller/tentacle/proc/stop_drag_owner()
	BP?.owner?.tentacles?.dragging_bp = null

/datum/bodypart_controller/tentacle/proc/dragging_owner()
	to_chat(world, "bodypart_controller dragging_owner()")
	if(BP.owner.tentacles.dragging_bp != src)
		return
	var/len = tentacle_bodies.len
	if(len == 2) // 2 bodies - means that owner should be next to grabber, if owner arent next to grabber, lets try extra step
		if(retrieve_grabber())
			return
	else if(len == 1) // 1 body - means that owner stepped in tile with grabber
		// For example: If owner was near portal, grabber instatly got into portal. So let the owner step into portal and apear in tile with grabber
		if(!retrieve_grabber())
			cut_bodies_from_index(1) // DERAILED
		return

	var/loc_before = get_turf(BP.owner)
	BP.owner.Move(get_step(BP.owner, tentacle_bodies[1].end_dir))
	var/loc_current = get_turf(BP.owner)
	
	if(loc_before != loc_current) // If owner move not interrupted, retrieve body that left behind
		tentacle_bodies[1].retrieve_to_owner()
	
	if(!istype(BP.owner.loc, /turf)) // If owner moved into something. Ex: moved into disposal chute
		stop_drag_owner()
		return

	if(loc_current != get_turf(tentacle_bodies[1])) // If owner got derailed
		cut_bodies_from_index(1) // DERAILED
		return

	addtimer(CALLBACK(src, PROC_REF(dragging_owner)), 0.5)

/datum/bodypart_controller/tentacle/proc/update_tentacle_icon()
	to_chat(world, "tentacle_bodies len: [tentacle_bodies.len]")
	if(tentacle_bodies.len <= 0)
		return
	for(var/obj/tentacle_body/tentacle_body as anything in tentacle_bodies)
		to_chat(world, "tentacle_bodies [tentacle_body]")
		tentacle_body.update_tentacle_icon()
	grabber.update_tentacle_icon()

/datum/bodypart_controller/tentacle/proc/increase_limit(var/increase = 1)
	to_chat(world, "increase_limit([increase])")
	current_length += increase


/datum/bodypart_controller/tentacle/fracture()
	return
