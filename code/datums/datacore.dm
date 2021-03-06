
/hook/startup/proc/createDatacore()
	data_core = new /datum/datacore()
	return 1

/datum/datacore
	var/name = "datacore"
	var/medical[] = list()
	var/general[] = list()
	var/security[] = list()
	//This list tracks characters spawned in the world and cannot be modified in-game. Currently referenced by respawn_character().
	var/locked[] = list()


/datum/datacore/proc/get_manifest(monochrome, OOC)
	var/list/heads = new()
	var/list/sec = new()
	var/list/eng = new()
	var/list/med = new()
	var/list/sci = new()
	var/list/car = new()
	var/list/civ = new()
	var/list/bot = new()
	var/list/misc = new()
	var/list/isactive = new()
	var/dat = {"
	<head><style>
		.manifest {border-collapse:collapse;}
		.manifest td, th {border:1px solid [monochrome?"black":"[OOC?"black; background-color:#272727; color:white":"#DEF; background-color:white; color:black"]"]; padding:.25em}
		.manifest th {height: 2em; [monochrome?"border-top-width: 3px":"background-color: [OOC?"#40628A":"#48C"]; color:white"]}
		.manifest tr.head th { [monochrome?"border-top-width: 1px":"background-color: [OOC?"#013D3B;":"#488;"]"] }
		.manifest td:first-child {text-align:right}
		.manifest tr.alt td {[monochrome?"border-top-width: 2px":"background-color: [OOC?"#373737; color:white":"#DEF"]"]}
	</style></head>
	<table class="manifest" width='350px'>
	<tr class='head'><th>Name</th><th>Rank</th><th>Activity</th></tr>
	"}
	var/even = 0
	// sort mobs
	for(var/datum/data/record/t in data_core.general)
		var/name = t.fields["name"]
		var/rank = t.fields["rank"]
		var/real_rank = make_list_rank(t.fields["real_rank"])

		if(OOC)
			var/active = 0
			for(var/mob/M in player_list)
				if(M.real_name == name && M.client && M.client.inactivity <= 10 * 60 * 10)
					active = 1
					break
			isactive[name] = active ? "Active" : "Inactive"
		else
			isactive[name] = t.fields["p_stat"]
			//world << "[name]: [rank]"
			//cael - to prevent multiple appearances of a player/job combination, add a continue after each line
		var/department = 0
		if(real_rank in command_positions)
			heads[name] = rank
			department = 1
		if(real_rank in security_positions)
			sec[name] = rank
			department = 1
		if(real_rank in engineering_positions)
			eng[name] = rank
			department = 1
		if(real_rank in medical_positions)
			med[name] = rank
			department = 1
		if(real_rank in science_positions)
			sci[name] = rank
			department = 1
		if(real_rank in cargo_positions)
			car[name] = rank
			department = 1
		if(real_rank in civilian_positions)
			civ[name] = rank
			department = 1
		if(!department && !(name in heads))
			misc[name] = rank

	// Synthetics don't have actual records, so we will pull them from here.
	for(var/mob/living/silicon/ai/ai in mob_list)
		bot[ai.name] = "Artificial Intelligence"

	for(var/mob/living/silicon/robot/robot in mob_list)
		// No combat/syndicate cyborgs, no drones.
		if(robot.module && robot.module.hide_on_manifest)
			continue

		bot[robot.name] = "[robot.modtype] [robot.braintype]"


	if(heads.len > 0)
		dat += "<tr><th colspan=3>Heads</th></tr>"
		for(name in heads)
			dat += "<tr[even ? " class='alt'" : ""]><td>[name]</td><td>[heads[name]]</td><td>[isactive[name]]</td></tr>"
			even = !even
	if(sec.len > 0)
		dat += "<tr><th colspan=3>Security</th></tr>"
		for(name in sec)
			dat += "<tr[even ? " class='alt'" : ""]><td>[name]</td><td>[sec[name]]</td><td>[isactive[name]]</td></tr>"
			even = !even
	if(eng.len > 0)
		dat += "<tr><th colspan=3>Engineering</th></tr>"
		for(name in eng)
			dat += "<tr[even ? " class='alt'" : ""]><td>[name]</td><td>[eng[name]]</td><td>[isactive[name]]</td></tr>"
			even = !even
	if(med.len > 0)
		dat += "<tr><th colspan=3>Medical</th></tr>"
		for(name in med)
			dat += "<tr[even ? " class='alt'" : ""]><td>[name]</td><td>[med[name]]</td><td>[isactive[name]]</td></tr>"
			even = !even
	if(sci.len > 0)
		dat += "<tr><th colspan=3>Science</th></tr>"
		for(name in sci)
			dat += "<tr[even ? " class='alt'" : ""]><td>[name]</td><td>[sci[name]]</td><td>[isactive[name]]</td></tr>"
			even = !even
	if(car.len > 0)
		dat += "<tr><th colspan=3>Cargo</th></tr>"
		for(name in car)
			dat += "<tr[even ? " class='alt'" : ""]><td>[name]</td><td>[car[name]]</td><td>[isactive[name]]</td></tr>"
			even = !even
	if(civ.len > 0)
		dat += "<tr><th colspan=3>Civilian</th></tr>"
		for(name in civ)
			dat += "<tr[even ? " class='alt'" : ""]><td>[name]</td><td>[civ[name]]</td><td>[isactive[name]]</td></tr>"
			even = !even
	// in case somebody is insane and added them to the manifest, why not
	if(bot.len > 0)
		dat += "<tr><th colspan=3>Silicon</th></tr>"
		for(name in bot)
			dat += "<tr[even ? " class='alt'" : ""]><td>[name]</td><td>[bot[name]]</td><td>[isactive[name]]</td></tr>"
			even = !even
	// misc guys
	if(misc.len > 0)
		dat += "<tr><th colspan=3>Miscellaneous</th></tr>"
		for(name in misc)
			dat += "<tr[even ? " class='alt'" : ""]><td>[name]</td><td>[misc[name]]</td><td>[isactive[name]]</td></tr>"
			even = !even

	dat += "</table>"
	dat = replacetext(dat, "\n", "") // so it can be placed on paper correctly
	dat = replacetext(dat, "\t", "")
	return dat

/datum/datacore/proc/manifest()
	spawn()
		for(var/mob/living/carbon/human/H in player_list)
			manifest_inject(H)
		return

/datum/datacore/proc/manifest_modify(var/name, var/assignment)
	ResetPDAManifest()
	var/datum/data/record/foundrecord
	var/real_title = assignment

	for(var/datum/data/record/t in data_core.general)
		if (t)
			if(t.fields["name"] == name)
				foundrecord = t
				break

	var/list/all_jobs = get_job_datums()

	for(var/datum/job/J in all_jobs)
		var/list/alttitles = get_alternate_titles(J.title)
		if(!J)	continue
		if(assignment in alttitles)
			real_title = J.title
			break

	if(foundrecord)
		foundrecord.fields["rank"] = assignment
		foundrecord.fields["real_rank"] = real_title

/datum/datacore/proc/manifest_inject(var/mob/living/carbon/human/H)
	if(H.mind && !player_is_antag(H.mind, only_offstation_roles = 1))
		var/assignment = GetAssignment(H)

		var/id = generate_record_id()
		//General Record
		var/datum/data/record/G = CreateGeneralRecord(H, id)
		G.fields["name"]		= H.real_name
		G.fields["real_rank"]	= H.mind.assigned_role
		G.fields["rank"]		= assignment
		G.fields["age"]			= H.age
		G.fields["fingerprint"]	= md5(H.dna.uni_identity)
		G.fields["p_stat"]		= "Active"
		G.fields["m_stat"]		= "Stable"
		G.fields["sex"]			= gender2text(H.gender)
		G.fields["species"]		= H.get_species()
		G.fields["home_system"]	= H.home_system
		G.fields["citizenship"]	= H.citizenship
		G.fields["faction"]		= H.personal_faction
		G.fields["religion"]	= H.religion
		if(H.gen_record && !jobban_isbanned(H, "Records"))
			G.fields["notes"] = H.gen_record

		//Medical Record
		var/datum/data/record/M = CreateMedicalRecord(H.real_name, id)
		M.fields["b_type"]		= H.b_type
		M.fields["b_dna"]		= H.dna.unique_enzymes
		M.fields["id_gender"]	= gender2text(H.identifying_gender)
		if(H.med_record && !jobban_isbanned(H, "Records"))
			M.fields["notes"] = H.med_record

		//Security Record
		var/datum/data/record/S = CreateSecurityRecord(H.real_name, id)
		if(H.sec_record && !jobban_isbanned(H, "Records"))
			S.fields["notes"] = H.sec_record

		//Locked Record
		var/datum/data/record/L = new()
		L.fields["id"]			= md5("[H.real_name][H.mind.assigned_role]")
		L.fields["name"]		= H.real_name
		L.fields["rank"] 		= H.mind.assigned_role
		L.fields["age"]			= H.age
		L.fields["fingerprint"]	= md5(H.dna.uni_identity)
		L.fields["sex"]			= gender2text(H.gender)
		L.fields["id_gender"]	= gender2text(H.identifying_gender)
		L.fields["b_type"]		= H.b_type
		L.fields["b_dna"]		= H.dna.unique_enzymes
		L.fields["enzymes"]		= H.dna.SE // Used in respawning
		L.fields["identity"]	= H.dna.UI // "
		L.fields["species"]		= H.get_species()
		L.fields["home_system"]	= H.home_system
		L.fields["citizenship"]	= H.citizenship
		L.fields["faction"]		= H.personal_faction
		L.fields["religion"]	= H.religion
		L.fields["image"]		= getFlatIcon(H)	//This is god-awful
		L.fields["antagfac"]	= H.antag_faction
		L.fields["antagvis"]	= H.antag_vis
		if(H.exploit_record && !jobban_isbanned(H, "Records"))
			L.fields["exploit_record"] = H.exploit_record
		else
			L.fields["exploit_record"] = "No additional information acquired."
		locked += L
	return

/proc/generate_record_id()
	return add_zero(num2hex(rand(1, 65535)), 4)	//no point generating higher numbers because of the limitations of num2hex

/proc/get_id_photo(var/mob/living/carbon/human/H, var/assigned_role)

	var/icon/preview_icon = H.stand_icon
	var/icon/temp

	var/datum/sprite_accessory/hair_style = hair_styles_list[H.h_style ? H.h_style : "bald"]
	if(hair_style)
		temp = new/icon(hair_style.icon, hair_style.icon_state)
		temp.Blend(H.hair_color, ICON_ADD)

	hair_style = facial_hair_styles_list[H.f_style]
	if(hair_style)
		var/icon/facial = new/icon(hair_style.icon, hair_style.icon_state)
		facial.Blend(H.facial_color, ICON_ADD)
		temp.Blend(facial, ICON_OVERLAY)

	preview_icon.Blend(temp, ICON_OVERLAY)


	if(!assigned_role) assigned_role = H.mind.assigned_role
	switch(assigned_role)
		if("Head of Personnel")
			temp = new /icon('icons/mob/uniform.dmi', "hop")
			temp.Blend(new /icon('icons/mob/feet.dmi', "brown"), ICON_UNDERLAY)
		if("Bartender")
			temp = new /icon('icons/mob/uniform.dmi', "ba_suit")
			temp.Blend(new /icon('icons/mob/feet.dmi', "black"), ICON_UNDERLAY)
		if("Gardener")
			temp = new /icon('icons/mob/uniform.dmi', "hydroponics")
			temp.Blend(new /icon('icons/mob/feet.dmi', "black"), ICON_UNDERLAY)
		if("Chef")
			temp = new /icon('icons/mob/uniform.dmi', "chef")
			temp.Blend(new /icon('icons/mob/feet.dmi', "black"), ICON_UNDERLAY)
		if("Janitor")
			temp = new /icon('icons/mob/uniform.dmi', "janitor")
			temp.Blend(new /icon('icons/mob/feet.dmi', "black"), ICON_UNDERLAY)
		if("Librarian")
			temp = new /icon('icons/mob/uniform.dmi', "red_suit")
			temp.Blend(new /icon('icons/mob/feet.dmi', "black"), ICON_UNDERLAY)
		if("Quartermaster")
			temp = new /icon('icons/mob/uniform.dmi', "qm")
			temp.Blend(new /icon('icons/mob/feet.dmi', "brown"), ICON_UNDERLAY)
		if("Cargo Technician")
			temp = new /icon('icons/mob/uniform.dmi', "cargotech")
			temp.Blend(new /icon('icons/mob/feet.dmi', "black"), ICON_UNDERLAY)
		if("Shaft Miner")
			temp = new /icon('icons/mob/uniform.dmi', "miner")
			temp.Blend(new /icon('icons/mob/feet.dmi', "black"), ICON_UNDERLAY)
		if("Lawyer")
			temp = new /icon('icons/mob/uniform.dmi', "internalaffairs")
			temp.Blend(new /icon('icons/mob/feet.dmi', "brown"), ICON_UNDERLAY)
		if("Chaplain")
			temp = new /icon('icons/mob/uniform.dmi', "chapblack")
			temp.Blend(new /icon('icons/mob/feet.dmi', "black"), ICON_UNDERLAY)
		if("Research Director")
			temp = new /icon('icons/mob/uniform.dmi', "director")
			temp.Blend(new /icon('icons/mob/feet.dmi', "brown"), ICON_UNDERLAY)
			temp.Blend(new /icon('icons/mob/suit.dmi', "labcoat_open"), ICON_OVERLAY)
		if("Scientist")
			temp = new /icon('icons/mob/uniform.dmi', "sciencewhite")
			temp.Blend(new /icon('icons/mob/feet.dmi', "white"), ICON_UNDERLAY)
			temp.Blend(new /icon('icons/mob/suit.dmi', "labcoat_tox_open"), ICON_OVERLAY)
		if("Chemist")
			temp = new /icon('icons/mob/uniform.dmi', "chemistrywhite")
			temp.Blend(new /icon('icons/mob/feet.dmi', "white"), ICON_UNDERLAY)
			temp.Blend(new /icon('icons/mob/suit.dmi', "labcoat_chem_open"), ICON_OVERLAY)
		if("Chief Medical Officer")
			temp = new /icon('icons/mob/uniform.dmi', "cmo")
			temp.Blend(new /icon('icons/mob/feet.dmi', "brown"), ICON_UNDERLAY)
			temp.Blend(new /icon('icons/mob/suit.dmi', "labcoat_cmo_open"), ICON_OVERLAY)
		if("Medical Doctor")
			temp = new /icon('icons/mob/uniform.dmi', "medical")
			temp.Blend(new /icon('icons/mob/feet.dmi', "white"), ICON_UNDERLAY)
			temp.Blend(new /icon('icons/mob/suit.dmi', "labcoat_open"), ICON_OVERLAY)
		if("Geneticist")
			temp = new /icon('icons/mob/uniform.dmi', "geneticswhite")
			temp.Blend(new /icon('icons/mob/feet.dmi', "white"), ICON_UNDERLAY)
			temp.Blend(new /icon('icons/mob/suit.dmi', "labcoat_gen_open"), ICON_OVERLAY)
		if("Virologist")
			temp = new /icon('icons/mob/uniform.dmi', "virologywhite")
			temp.Blend(new /icon('icons/mob/feet.dmi', "white"), ICON_UNDERLAY)
			temp.Blend(new /icon('icons/mob/suit.dmi', "labcoat_vir_open"), ICON_OVERLAY)
		if("Captain")
			temp = new /icon('icons/mob/uniform.dmi', "captain")
			temp.Blend(new /icon('icons/mob/feet.dmi', "brown"), ICON_UNDERLAY)
		if("Head of Security")
			temp = new /icon('icons/mob/uniform.dmi', "hosred")
			temp.Blend(new /icon('icons/mob/feet.dmi', "jackboots"), ICON_UNDERLAY)
		if("Warden")
			temp = new /icon('icons/mob/uniform.dmi', "warden")
			temp.Blend(new /icon('icons/mob/feet.dmi', "jackboots"), ICON_UNDERLAY)
		if("Detective")
			temp = new /icon('icons/mob/uniform.dmi', "detective")
			temp.Blend(new /icon('icons/mob/feet.dmi', "brown"), ICON_UNDERLAY)
			temp.Blend(new /icon('icons/mob/suit.dmi', "detective"), ICON_OVERLAY)
		if("Security Officer")
			temp = new /icon('icons/mob/uniform.dmi', "secred")
			temp.Blend(new /icon('icons/mob/feet.dmi', "jackboots"), ICON_UNDERLAY)
		if("Chief Engineer")
			temp = new /icon('icons/mob/uniform.dmi', "chief")
			temp.Blend(new /icon('icons/mob/feet.dmi', "brown"), ICON_UNDERLAY)
			temp.Blend(new /icon('icons/mob/belt.dmi', "utility"), ICON_OVERLAY)
		if("Station Engineer")
			temp = new /icon('icons/mob/uniform.dmi', "engine")
			temp.Blend(new /icon('icons/mob/feet.dmi', "orange"), ICON_UNDERLAY)
			temp.Blend(new /icon('icons/mob/belt.dmi', "utility"), ICON_OVERLAY)
		if("Atmospheric Technician")
			temp = new /icon('icons/mob/uniform.dmi', "atmos")
			temp.Blend(new /icon('icons/mob/feet.dmi', "black"), ICON_UNDERLAY)
			temp.Blend(new /icon('icons/mob/belt.dmi', "utility"), ICON_OVERLAY)
		if("Roboticist")
			temp = new /icon('icons/mob/uniform.dmi', "robotics")
			temp.Blend(new /icon('icons/mob/feet.dmi', "black"), ICON_UNDERLAY)
			temp.Blend(new /icon('icons/mob/suit.dmi', "labcoat_open"), ICON_OVERLAY)
		else
			temp = new /icon('icons/mob/uniform.dmi', "grey")
			temp.Blend(new /icon('icons/mob/feet.dmi', "black"), ICON_UNDERLAY)

	preview_icon.Blend(temp, ICON_OVERLAY)


	qdel(temp)

	return preview_icon

/datum/datacore/proc/CreateGeneralRecord(var/mob/living/carbon/human/H, var/id)
	ResetPDAManifest()
	var/icon/base = get_id_photo(H)
	var/icon/front = new(base, dir = SOUTH)
	var/icon/side = new(base, dir = WEST)

	if(!id) id = text("[]", add_zero(num2hex(rand(1, 65536)), 4))
	var/datum/data/record/G = new /datum/data/record()
	G.name = "Employee Record #[id]"
	G.fields["name"] = "New Record"
	G.fields["id"] = id
	G.fields["rank"] = "Unassigned"
	G.fields["real_rank"] = "Unassigned"
	G.fields["sex"] = "Unknown"
	G.fields["age"] = "Unknown"
	G.fields["fingerprint"] = "Unknown"
	G.fields["p_stat"] = "Active"
	G.fields["m_stat"] = "Stable"
	G.fields["species"] = "Human"
	G.fields["home_system"]	= "Unknown"
	G.fields["citizenship"]	= "Unknown"
	G.fields["faction"]		= "Unknown"
	G.fields["religion"]	= "Unknown"
	G.fields["photo_front"]	= front
	G.fields["photo_side"]	= side
	G.fields["notes"] = "No notes found."
	general += G

	return G

/datum/datacore/proc/CreateSecurityRecord(var/name, var/id)
	ResetPDAManifest()
	var/datum/data/record/R = new /datum/data/record()
	R.name = "Security Record #[id]"
	R.fields["name"] = name
	R.fields["id"] = id
	R.fields["criminal"]	= "None"
	R.fields["mi_crim"]		= "None"
	R.fields["mi_crim_d"]	= "No minor crime convictions."
	R.fields["ma_crim"]		= "None"
	R.fields["ma_crim_d"]	= "No major crime convictions."
	R.fields["notes"]		= "No notes."
	R.fields["notes"] = "No notes."
	data_core.security += R

	return R

/datum/datacore/proc/CreateMedicalRecord(var/name, var/id)
	ResetPDAManifest()
	var/datum/data/record/M = new()
	M.name = "Medical Record #[id]"
	M.fields["id"]			= id
	M.fields["name"]		= name
	M.fields["b_type"]		= "AB+"
	M.fields["b_dna"]		= md5(name)
	M.fields["id_gender"]	= "Unknown"
	M.fields["mi_dis"]		= "None"
	M.fields["mi_dis_d"]	= "No minor disabilities have been declared."
	M.fields["ma_dis"]		= "None"
	M.fields["ma_dis_d"]	= "No major disabilities have been diagnosed."
	M.fields["alg"]			= "None"
	M.fields["alg_d"]		= "No allergies have been detected in this patient."
	M.fields["cdi"]			= "None"
	M.fields["cdi_d"]		= "No diseases have been diagnosed at the moment."
	M.fields["notes"] = "No notes found."
	data_core.medical += M

	return M

/datum/datacore/proc/ResetPDAManifest()
	if(PDA_Manifest.len)
		PDA_Manifest.Cut()

/proc/find_general_record(field, value)
	return find_record(field, value, data_core.general)

/proc/find_medical_record(field, value)
	return find_record(field, value, data_core.medical)

/proc/find_security_record(field, value)
	return find_record(field, value, data_core.security)

/proc/find_record(field, value, list/L)
	for(var/datum/data/record/R in L)
		if(R.fields[field] == value)
			return R

/proc/GetAssignment(var/mob/living/carbon/human/H)
	if(H.mind.role_alt_title)
		return H.mind.role_alt_title
	else if(H.mind.assigned_role)
		return H.mind.assigned_role
	else if(H.job)
		return H.job
	else
		return "Unassigned"
