    with primary_casemanager as (select ru.id, c.first_name, c.last_name 
	from public.roles_users ru 
	join public.contacts c on c.contactable_id = ru.user_id and c.contactable_type = 'User'), 
	contacts_details as (
    select c.contactable_id, c.first_name, c.last_name, l.address, l.city, c.company_name, l.zip_string, l.county_id, c.id,l.state_id 
	from contacts c 
	join contact_infos ci 
	on c.id = ci.contact_id  and ci.type = 'ContactInfoAddress' and ci.precedence =1 
	join locations l on ci.id = l.contact_info_address_id
	where c.contactable_type = 'User')
		 
	SELECT distinct ---63,195, 139,671, 46,760, 60,129
	js.id as job_seeker_id, 
	jobseeker.first_name js_first_name, 
	jobseeker.last_name js_last_name, 
	jobseeker.address js_address, 
	jobseeker.state js_state, 
	jobseeker.city js_city, 
	jobseeker.zip_string js_zip, 
	jobseeker.county_of_residence js_county,
	ep.enrollment_id, 
	ep.status enrollment_status,
	ep.id enrollment_participation_id, 
	pp.id program_participation_id,
	ep.participated_on as enrollment_participation_date, 
	ep.starts_on enrollment_start_date,
	ep.ends_on as enrollment_exit_date,
	sp.actually_started_on  as service_actual_start_date,
	sp.actually_ended_on as service_actual_end_date,
	pp.ends_on as program_exit_date, 
	pp.starts_on program_start_date,
	(
		select distinct 
			case 
				when ds.student_status in (1,2,5) 
					and date_part('year',age(ds.registered_on,jss.date_of_birth)) >= 14 
					and date_part('year',age(ds.registered_on,jss.date_of_birth)) <= 21
					and (
							dlis.income_cash_assistance is true or 
							dlis.disabled_income_poverty_line is true or 
							dlis.food_stamp_eligible is true or 
							dlis.foster_child in (1,2,3) or 
							dlis.qualify_reduced_or_free_lunch is true or 
							dlis.homeless is true or 
							dlis.income_less_than_70_percent_of_llsil is true or 
							dlis.income_poverty_line is true or 
							dlis.rec_ssi_last_6_months is true or 
							dlis.tanf_last_6_months = 1
						)
					and (
							dnabs.has_low_literacy is true or 
							ds.limited_english is true or 
							dnabs.offender in (1,2,3) or 
							dlis.homeless is true or 
							dnabs.runaway is true or 
							dlis.foster_child in (1,3) or 
							dnabs.youth_chafee_foster_care is true or 
							dnabs.pregnant is true or 
							dnabs.teen_parent is true or 
							ds.disabled = 1 or 
							dnabs.requires_assistance_for_education is true or 
							dnabs.requires_assistance_for_employment is true
						) then 'ISY'
				when ds.student_status in (3,4,6)
					and date_part('year',age(ds.registered_on,jss.date_of_birth)) >= 16 
					and date_part('year',age(ds.registered_on,jss.date_of_birth)) <= 24
					and (
							ds.student_status = 3 or 
							ds.student_status = 6 or 
							dnabs.offender in (1,2,3) or 
							dlis.homeless is true or 
							dnabs.runaway is true or 
							dlis.foster_child in (1,3) or 
							dnabs.youth_chafee_foster_care is true or 
							dnabs.pregnant is true or 
							dnabs.teen_parent is true or 
							ds.disabled =1 or 
							(
								(
									dlis.income_cash_assistance is true or 
									dlis.disabled_income_poverty_line is true or 
									dlis.food_stamp_eligible is true or 
									dlis.foster_child in (1,2,3) or 
									dlis.qualify_reduced_or_free_lunch is true or 
									dlis.homeless is true or 
									dlis.income_less_than_70_percent_of_llsil is true or 
									dlis.income_poverty_line is true or 
									dlis.rec_ssi_last_6_months is true or 
									dlis.tanf_last_6_months = 1
								)
								and 
								(
									(
										dnabs.requires_assistance_for_education is true or 
										dnabs.requires_assistance_for_employment is true 
									)
									or 
									(
										ds.student_status = 4 and 
										(
											dnabs.has_low_literacy is true or 
											ds.limited_english is true 
										)
									)
								)
							)
						) then 'OSY'
				else ''
			end 
			from public.demographic_snapshots ds 
			left join public.job_seeker_snapshots jss on ds.enrollment_participation_id = jss.enrollment_participation_id 
			left join public.demographic_low_income_snapshots dlis on dlis.demographic_snapshot_id = ds.id 
			left join public.demographic_need_and_barrier_snapshots dnabs on dnabs.demographic_snapshot_id = ds.id 
			where ds.enrollment_participation_id = ep.id 
		        limit 1
	) as ISY_OSY_Status,
	s.name as service,
	sp.id service_participation_id, 
	CASE sp.status
            WHEN 0 THEN 'Closed'
            WHEN 1 THEN 'Completed'
            WHEN 2 THEN 'Denied'
            WHEN 3 THEN 'Exited w/o Completing'
            WHEN 4 THEN 'Edited, Funding Source Change'
            WHEN 5 THEN 'Exited, Grant Ended'
            WHEN 6 THEN 'Exited, Program Year Ended'
            WHEN 7 THEN 'Failed to Report'
            WHEN 8 THEN 'In-Progress'
            WHEN 9 THEN 'Open'
            WHEN 10 THEN 'Proposed'
            WHEN 11 THEN 'Rescheduled'
            WHEN 12 THEN 'Scheduled'
            WHEN 13 THEN 'Service Cancelled'
            WHEN 14 THEN 'Transferred Schools'
            WHEN 15 THEN 'Unsuccessful Completion'
            WHEN 16 THEN 'Waived'
            WHEN 17 THEN 'Cancelled'
            ELSE NULL
    END AS service_status,
	(select c.company_name from contacts c where c.id = sp.service_provider_contact_id  ) service_provider, 
	service_provider_contact_info.company_name as service_provider_name,
	service_provider_contact_info.zip_string as service_provider_zip,
	service_provider_contact_info.county_name as service_provider_county,
	(select tp.name from training_providers tp 
						join training_programs tp2 on tp.id = tp2.training_institution_id 
						where sp.training_program_id = tp2.id) training_provider,
	(select l2.zip_string from training_programs tp3 
							  join locations l2 on l2.id = tp3.location_id 
							  where sp.training_program_id = tp3.id) training_program_zip,
	(select tp4.location_description from training_programs tp4 
										 where sp.training_program_id  = tp4.id) training_program_location,
	(select distinct cy.name from training_programs tp5 join public.locations l3 on l3.id = tp5.location_id 
															join public.counties_local_areas cla2 on cla2.county_id = l3.county_id 
															join public.counties cy on cy.id = l3.county_id 
															where sp.training_program_id = tp5.id limit 1) training_program_county,
	sp.training_program_id, 
	(select tpgm.name from training_programs tpgm where tpgm.id = sp.training_program_id) course,
	(select coip.code || ' - ' || coip.title from public.classification_of_instructional_programs coip where coip.id = sp.classification_of_instructional_program_id ) as service_cip_code_title,
	(select o.code || ' - ' || o.title  service_onet_code_title from public.occupations o where o.code = sp.onet_code) as service_onet_code_title,		
	case b.approved when false then 'Not Approved' when true then 'Approved' else 'Pending' end as budget_pending_status, 
	ca.funding_year, 
	ca.contract_id,  
	ca.id contract_amount_id, 
	es.id expense_id, 
	ca.amount as budget_amount,
	es.budget_amount amount_paid,
	ca.amount - es.budget_amount as balance,
	chks.check_on date_paid_ar_id_ks_me_vt,
	es.created_at date_paid_az,
	v.file_created_at date_paid_de,
	es.pay_begins_at date_paid_ok,
	ex.category_description expenditure_category,
	primary_casemanager.first_name as primary_casemanager_first_name,
	primary_casemanager.last_name as primary_casemanager_last_name,
	(
		select o.name
		from public.offices o
		where o.id = pp.office_id 
	) as office_name,
	(
		select la.name
		from public.contacts c 
		join public.contact_infos ci on c.id = ci.contact_id and ci.type = 'ContactInfoAddress' and ci.precedence = 1
		join public.locations l on ci.id = l.contact_info_address_id 
		join public.counties_local_areas cla on cla.county_id = l.county_id 
		join public.local_areas la on la.id = cla.local_area_id 
		where c.contactable_id = pp.office_id and c.contactable_type = 'Office'
		and la.government_program_id = (select id from public.government_programs where name = 'Workforce Investment Act') 
		limit 1
	) as office_local_area_name
FROM public.job_seekers js 
left join (
		select cd.contactable_id, cd.first_name, cd.last_name, cd.address, s.abbrev as state, cd.city, cd.zip_string, cy.name as county_of_residence
		FROM contacts_details cd 
		join public.states s on cd.state_id = s.id 
		join public.counties cy on cd.county_id = cy.id
		) jobseeker on jobseeker.contactable_id = js.user_id
join public.program_participations pp on js.id = pp.job_seeker_id 
join public.enrollment_participations ep on pp.id = ep.program_participation_id 
join public.service_participations sp on ep.id = sp.enrollment_participation_id 
join public.enrollments el on ep.enrollment_id = el.id 
join public.services s on sp.service_id = s.id 
join public.budget_clients bc on sp.id = bc.service_participation_id 
join public.budgets b on b.id = bc.budget_id
join public.contracts c on bc.budget_id = c.budget_id 
join public.contract_amounts ca on c.id = ca.contract_id 
left join public.expenses es on ca.id = es.contract_amount_id 
left join primary_casemanager on primary_casemanager.id = ep.role_user_id
left join public.vouchers v on es.voucher_id = v.id 
join public.expenditures ex on c.expenditure_id = ex.id and ex.enabled is true
left join public.checks chks on chks.id = es.check_id 
left join public.classification_of_instructional_programs coip on coip.id = sp.classification_of_instructional_program_id 
left join (
		select cd.company_name, cd.zip_string, cy.name county_name, cd.id
		from contacts_details cd 
	    join counties_local_areas cla on cla.county_id  = cd.county_id
		join public.counties cy on cy.id = cd.county_id 
 ) service_provider_contact_info on service_provider_contact_info.id = sp.service_provider_contact_id 
where pp.starts_on <= now()::date and (pp.ends_on is null or pp.ends_on >= '07/01/2016'::date) 