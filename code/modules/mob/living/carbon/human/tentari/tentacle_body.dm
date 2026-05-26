/obj/tentacle_body
	name = "tentacle body"
	icon = 'icons/mob/human/tentari.dmi'
	icon_state = "no"
	anchored = TRUE
	
	var/datum/bodypart_controller/tentacle/bp_controller
	var/start_dir = SOUTH // SOUTH for visually connecting with owner mob or grabber mob
	var/end_dir = SOUTH
	var/deleting_state = FALSE

/obj/tentacle_body/atom_init(mapload, var/datum/bodypart_controller/tentacle/controller, var/dir_start)
	. = ..()
	to_chat(world, "body atom_init()")
	bp_controller = controller
	bp_controller.tentacle_bodies += src

	icon = bp_controller.BP.owner.tentacles.tentacle_icon
	start_dir = dir_start
	update_dir_icon()
	
	var/prev_body_index = bp_controller.tentacle_bodies.len-1
	if(prev_body_index > 0)
		var/obj/tentacle_body/previous_body = bp_controller.tentacle_bodies[prev_body_index]
		previous_body.end_dir = turn(start_dir, 180)
		previous_body.update_dir_icon()


/obj/tentacle_body/Destroy()
	to_chat(world, "body Destroy()")
	if(!deleting_state)
		bp_controller.body_destroyed(src) // If not cutted or retrieved - something destroyed the body
	var/list/obj/tentacle_body/bodies = bp_controller.tentacle_bodies
	var/len = bodies.len
	if(len > 1) // If deleting first or last body - change sprite of previous body
		if(src == bodies[1])
			bodies[2].start_dir = SOUTH
			bodies[2].update_dir_icon()
		else if(src == bodies[len])
			bodies[len-1].end_dir = SOUTH
			bodies[len-1].update_dir_icon()
			
	bp_controller.tentacle_bodies.Remove(src)

	. = ..()

/obj/tentacle_body/proc/update_dir_icon()
	icon_state = start_dir < end_dir ? "[start_dir][end_dir]" : "[end_dir][start_dir]" // Dirs in icon state names are sorted that way
	to_chat(world, "body icon_state = [icon_state]")

/obj/tentacle_body/proc/retrieve_to_owner()
	deleting_state = TRUE
	qdel(src)
	bp_controller.available_length++

/obj/tentacle_body/proc/retrieve_to_grabber()
	deleting_state = TRUE
	qdel(src)
	bp_controller.grabber.bodies_in_grabber++

/obj/tentacle_body/proc/cut()
	deleting_state = TRUE
	qdel(src)
	var/obj/T = new /obj/item/weapon/reagent_containers/food/snacks/tentacle(get_turf(src))
	T.pixel_x += rand(-6, 6)
	T.pixel_y += rand(-6, 6)

// When grabber moves over the limit, grabber leaves trail of stretched bodies
/obj/tentacle_body/stretched_body
	name = "stretched tentacle body"

/obj/tentacle_body/stretched_body/atom_init(mapload, var/datum/bodypart_controller/tentacle/controller, var/dir_start)
	. = ..()
	bp_controller.stretched_bodies++

/obj/tentacle_body/stretched_body/Destroy()
	. = ..()
	bp_controller.stretched_bodies--

/obj/tentacle_body/stretched_body/update_dir_icon()
	. = ..()
	icon_state = "[icon_state]_stretched"

/obj/tentacle_body/stretched_body/retrieve_to_owner()
	deleting_state = TRUE
	qdel(src)

/obj/tentacle_body/stretched_body/retrieve_to_grabber()
	deleting_state = TRUE
	qdel(src)

/obj/tentacle_body/proc/update_tentacle_icon()
	icon = bp_controller.BP.owner.tentacles.tentacle_icon
