// code\game\jobs\_access.dm
/mob/living/carbon/human/tentacle_grabber/try_access(obj/O)
	return bp_controller.BP.owner.try_access(O)

// code\modules\mob\mob.dm
/mob/living/carbon/human/tentacle_grabber/m_intent_delay()
	. = 0
	if(drowsyness > 0)
		. += 6
	. += config.run_speed

// code\modules\mob\living\carbon\human\human_damage.dm
/mob/living/carbon/human/tentacle_grabber/getBrainLoss()
    return BP.owner.getBrainLoss()

// code\modules\mob\living\carbon\human\human.dm
/mob/living/carbon/human/tentacle_grabber/get_authentification_rank(if_no_id = "No id", if_no_job = "No job")
    return BP.owner.get_authentification_rank(if_no_id, if_no_job)

/mob/living/carbon/human/tentacle_grabber/get_assignment(if_no_id = "No id", if_no_job = "No job")
    return BP.owner.get_assignment(if_no_id, if_no_job)