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

/mob/living/carbon/human/tentacle_grabber/get_authentification_name(if_no_id = "Unknown")
    return BP.owner.get_authentification_name(if_no_id)

// del everywhere use of /mob/living/carbon/human/proc/get_idcard()

/mob/living/carbon/human/tentacle_grabber/electrocute_act(shock_damage, obj/source, siemens_coeff = 1.0, def_zone = null, tesla_shock = 0)
    . = ..()
    BP.owner.electrocute_act(shock_damage, source, siemens_coeff, def_zone, tesla_shock)
