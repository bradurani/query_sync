WITH company_ids AS(
  SELECT id, sales_force_account_id
  FROM companies
  WHERE is_demo = false
  AND id NOT IN (5723,3432,2639)
  AND lower(name) NOT LIKE '%demo%'
  AND lower(name) NOT LIKE '%sandbox%'
  AND lower(name) NOT LIKE '%test%'
  AND lower(name) NOT LIKE '%delete%'
  AND lower(name) NOT LIKE '%template%'
  AND (LENGTH(sales_force_account_id) =0
  OR (LENGTH(sales_force_account_id) > 10
  AND sales_force_account_id LIKE '001%'))
  AND is_active = true
  ),
project_ids AS (
  SELECT p.id, p.company_id, c.sales_force_account_id
  FROM projects p
  INNER JOIN company_ids c on c.id=p.company_id
  WHERE p.company_id IN (SELECT id FROM company_ids)
  AND lower(p.name) NOT LIKE '%demo%'
  AND lower(p.name) NOT LIKE '%sandbox%'
  AND lower(p.name) NOT LIKE '%test%'
  AND lower(p.name) NOT LIKE '%delete%'
  AND lower(p.name) NOT LIKE '%template%'
  AND p.template = FALSE
),

company_tools as (
    select c.sales_force_account_id,
      (case when t.engine_name like '%generic_tool%' then 'generic_tool'
        else t.engine_name end) as tool_name,
      min(t.created_at)::date as date_created,
      max(t.updated_at)::date as date_updated
    from company_ids c
    inner join tools t on t.provider_type='Company' and t.provider_id=c.id
    where t.is_active = true
    and t.is_available = true
    group by c.sales_force_account_id, tool_name
  ),


project_tools as (
    select p.sales_force_account_id,
      (case when t.engine_name like '%generic_tool%' then 'generic_tool' else t.engine_name end) as tool_name
    from project_ids p
    inner join tools t on t.provider_type='Project' and t.provider_id=p.id
    where t.is_active = true
    and t.is_available = true
    group by p.sales_force_account_id, tool_name
  ),



tools_enabled as (
    select c.sales_force_account_id,
        max(case when ct.tool_name='bidding' or pt.tool_name='bidding' then 1 else 0 end) as bidding_enabled,
        max(case when ct.tool_name='budgeting' or pt.tool_name='budgeting' then 1 else 0 end) as budget_enabled,
        max(case when ct.tool_name='calendar' or pt.tool_name='calendar' then 1 else 0 end) as calendar_enabled,
        max(case when ct.tool_name='change_events' or pt.tool_name='change_events' then 1 else 0 end) as change_events_enabled,
        max(case when ct.tool_name='change_orders' or pt.tool_name='change_orders' then 1 else 0 end) as change_orders_enabled,
        max(case when ct.tool_name='commitments' or pt.tool_name='commitments' then 1 else 0 end) as commitments_enabled,
        max(case when ct.tool_name='documents' then 1 else 0 end) as company_documents_enabled,
        max(case when ct.tool_name='daily_log' or pt.tool_name='daily_log' then 1 else 0 end) as daily_log_enabled,
        max(case when ct.tool_name='direct_costs' or pt.tool_name='direct_costs' then 1 else 0 end) as direct_costs_enabled,
        max(case when ct.tool_name='documents' or pt.tool_name='documents' then 1 else 0 end) as documents_enabled,
        max(case when ct.tool_name='drawing_log' or pt.tool_name='drawing_log' then 1 else 0 end) as drawings_enabled,
        max(case when ct.tool_name='communication' or pt.tool_name='communication' then 1 else 0 end) as email_enabled,
        max(case when ct.tool_name='erp_integrations' or pt.tool_name='erp_integrations' then 1 else 0 end) as erp_integrations_enabled,
        max(case when ct.tool_name='incidents' or pt.tool_name='incidents' then 1 else 0 end) as incidents_enabled,
        max(case when ct.tool_name='checklists' or pt.tool_name='checklists' then 1 else 0 end) as inspections_enabled,
        max(case when ct.tool_name='meetings' or pt.tool_name='meetings' then 1 else 0 end) as meetings_enabled,
        max(case when ct.tool_name='observations' or pt.tool_name='observations' then 1 else 0 end) as observations_enabled,
        max(case when ct.tool_name='images' or pt.tool_name='images' then 1 else 0 end) as photos_enabled,
        max(case when ct.tool_name='prime_contract' or pt.tool_name='prime_contract' then 1 else 0 end) as prime_contract_enabled,
        max(case when pt.tool_name='documents' then 1 else 0 end) as project_documents_enabled,
        max(case when ct.tool_name='punch_list' or pt.tool_name='punch_list' then 1 else 0 end) as punch_list_enabled,
        max(case when ct.tool_name='reports' or pt.tool_name='reports' then 1 else 0 end) as reports_enabled,
        max(case when ct.tool_name='rfi' or pt.tool_name='rfi' then 1 else 0 end) as rfi_enabled,
        max(case when ct.tool_name='site_instructions' or pt.tool_name='site_instructions' then 1 else 0 end) as site_instructions_enabled,
        max(case when ct.tool_name='specification_sections' or pt.tool_name='specification_sections' then 1 else 0 end) as specifications_enabled,
        max(case when ct.tool_name='submittal_log' or pt.tool_name='submittal_log' then 1 else 0 end) as submittals_enabled,
        max(case when ct.tool_name='task_items' or pt.tool_name='task_items' then 1 else 0 end) as tasks_enabled,
        max(case when ct.tool_name='transmittals' or pt.tool_name='transmittals' then 1 else 0 end) as transmittals_enabled,
        max(case when ct.tool_name in ('calendar','task_items') or pt.tool_name in ('calendar','task_items') then 1 else 0 end) as schedule_enabled

    from company_ids c
    left join company_tools ct on ct.sales_force_account_id=c.sales_force_account_id
    left join project_tools pt on pt.sales_force_account_id=c.sales_force_account_id
    group by c.sales_force_account_id
  ),

filtered_session_pages AS (
  SELECT sp.id, sp.created_at, sp.session_report_id, sr.company_id, sp.project_id, sr.login_information_id, sr.browser, l.login,
  p.sales_force_account_id, sp.tab
  FROM session_pages sp
  INNER JOIN session_reports sr ON sp.session_report_id = sr.id
  INNER JOIN login_informations l ON l.id = sr.login_information_id
  INNER JOIN project_ids p on p.id=sp.project_id
  WHERE sp.created_at >= now() - interval '12 weeks'
  AND sp.project_id IN (SELECT id FROM project_ids)
  AND sr.created_at >= now() - interval '12 weeks'
  AND l.is_super = false
  AND l.login NOT LIKE '%procore%'
),
avg_session_pages AS (
  SELECT
    sales_force_account_id
    ,avg(avg_pages_per_session) AS avg_pages_per_session_calc
    FROM (
        SELECT date_trunc('week', sp.created_at) AS date_week,
               date_part('week', sp.created_at) AS week_number,
               sp.sales_force_account_id,
               (rank() OVER (PARTITION BY sp.sales_force_account_id ORDER BY date_trunc('week', sp.created_at))) AS week_rank,
               (count(distinct sp.id)/count(distinct sp.session_report_id)) AS avg_pages_per_session
        FROM filtered_session_pages sp
        WHERE sp.tab<>'API'
        GROUP BY sp.sales_force_account_id, date_week, week_number
      ) AS tbl
    GROUP BY sales_force_account_id
),
weekly_active_users_ as (
  select sales_force_account_id
  ,avg(total_active_users) as total_active_users_calc
  ,avg(active_customer_users) as active_customer_users_calc
  ,avg(active_collaborator_users) as active_collaborator_users_calc
  from
    (SELECT date_trunc('week', sp.created_at) as date_week,
            date_part('week', sp.created_at) as week_number,
            sp.sales_force_account_id,
            (rank() OVER (PARTITION BY sp.sales_force_account_id ORDER BY date_trunc('week', sp.created_at))) as week_rank,
            count(distinct (case when (substring(sp.login from '%[@]#"%#"' for '#')) = c.email_domain then sp.login_information_id end)) as active_customer_users,
            count(distinct (case when (substring(sp.login from '%[@]#"%#"' for '#')) <> c.email_domain then sp.login_information_id end)) as active_collaborator_users,
            count(distinct sp.login_information_id) as total_active_users
    FROM filtered_session_pages sp
    LEFT JOIN companies c on c.id = sp.company_id
    GROUP BY sp.sales_force_account_id, date_week, week_number
  ) as tbl
  group by sales_force_account_id
),
mobile_users_ as (
  select sales_force_account_id
         ,avg(mobile_active_users) as mobile_active_users_calc
  FROM (
    SELECT date_trunc('week', sp.created_at) as date_week,
           date_part('week', sp.created_at) as week_number,
           sales_force_account_id,
           (rank() OVER (PARTITION BY sp.sales_force_account_id ORDER BY date_trunc('week', sp.created_at))) as week_rank,
           count(distinct (case when sp.browser like '%iOS%' or sp.browser like '%Android%' then sp.login_information_id end)) as mobile_active_users,
           count(distinct sp.login_information_id) as total_active_users
    FROM filtered_session_pages sp
    GROUP BY sp.sales_force_account_id, date_week, week_number
  ) as tbl
  GROUP BY sales_force_account_id
),



invited_users_ as (
  SELECT sales_force_account_id
          ,avg(weekly_invited_users) as weekly_invited_users_calc
          ,avg(cumulative_invited_users) as cumulative_invited_users_calc
  FROM (
    SELECT date_trunc('week', tbl.first_invite_date) as date_week,
           date_part('week', tbl.first_invite_date) as week_number,
           tbl.sales_force_account_id,
           (rank() OVER (PARTITION BY tbl.sales_force_account_id ORDER BY date_trunc('week', tbl.first_invite_date))) as week_rank,
           count(distinct tbl.login_information_id) as weekly_invited_users,
           (sum(count(distinct tbl.login_information_id)) OVER (PARTITION BY tbl.sales_force_account_id ORDER BY date_trunc('week', tbl.first_invite_date))) AS cumulative_invited_users
    FROM (
      SELECT c.sales_force_account_id,
             l.id as login_information_id,
             min(ah.created_at) as first_invite_date
      FROM company_ids c
      INNER JOIN contacts ct on ct.type='Contact' and ct.company_id=c.id
      JOIN login_informations l ON l.id = ct.login_information_id
      JOIN active_histories ah ON (ah.ref_type = 'Contact'
                               AND ah.ref_id = ct.id
                               AND ah.column = 'welcome_email_sent_at'
                               AND ah.old_value = ''
                               AND ah.new_value <> ''
                               AND ah.created_at > '2016-03-26 00:00:00')
                               or
                               (ah.ref_type = 'Contact'
                               AND ah.ref_id=ct.id
                               AND ah.column = 'sent_welcome_email'
                               AND ah.old_value = 'false'
                               AND ah.new_value = 'true'
                               AND ah.created_at <= '2016-03-26 00:00:00')
        WHERE ct.deleted_at IS NULL
        AND ct.email_address NOT LIKE '%procore%'
        AND l.is_super = false
        AND l.login NOT LIKE '%procore%'
        GROUP BY c.sales_force_account_id, l.id
      ) as tbl
      GROUP BY date_week, week_number, tbl.sales_force_account_id
  ) as tbl3
  where tbl3.date_week >= now() - interval '12 weeks' -- still needed?
  group by sales_force_account_id
),
project_folders AS (
  SELECT f.id, f.folder_file_id, p.id AS project_id, p.company_id, p.sales_force_account_id, f.created_at, f.deleted_at
  FROM folders f
  JOIN project_ids p ON f.document_holder_type = 'Project'
                     AND f.document_holder_id = p.id
),
project_documents_ as (
    select tbl.sales_force_account_id
    ,avg(tbl.project_documents_created) as project_documents_created_calc
    from
        (select date_trunc('week',ff.created_at) as created_week
        ,date_part('week',ff.created_at) as week_number
        ,f.sales_force_account_id
        ,count(distinct ff.id) as project_documents_created
        FROM project_folders f
        JOIN folder_files ff ON f.folder_file_id = ff.id
        WHERE f.created_at >= now() - interval '12 weeks'
        AND f.deleted_at IS NULL
        GROUP BY created_week, week_number, f.sales_force_account_id
      ) AS tbl
    GROUP BY tbl.sales_force_account_id
),
company_documents_ as (
    SELECT tbl.sales_force_account_id
           ,avg(tbl.company_documents_created) as company_documents_created_calc
    FROM (
      SELECT date_trunc('week',ff.created_at) as created_week
             ,date_part('week',ff.created_at) as week_number
             ,co.sales_force_account_id
             ,count(distinct ff.id) as company_documents_created
      FROM folders f
      JOIN folder_files ff ON f.folder_file_id = ff.id
      JOIN company_ids co ON co.id = f.document_holder_id
                        AND f.document_holder_type = 'Company'
      WHERE f.created_at >= now() - interval '12 weeks'
      AND f.deleted_at is null
      GROUP BY created_week, week_number, co.sales_force_account_id
    ) AS tbl
    GROUP BY tbl.sales_force_account_id
),
reports_ AS (
    SELECT tbl.sales_force_account_id
    ,avg(tbl.reports_created) AS reports_created_calc
    FROM (
      SELECT date_trunc('week', r.created_at) as created_week
            ,date_part('week', r.created_at) as week_number
            ,co.sales_force_account_id
            ,count(distinct r.id) as reports_created
      FROM reports r
      JOIN company_ids co ON co.id = r.company_id
      WHERE r.created_at >= now() - interval '12 weeks'
      AND r.deleted_at is null
      GROUP BY created_week, week_number, co.sales_force_account_id
    ) AS tbl
    GROUP BY tbl.sales_force_account_id
 ),
emails_ as (
    SELECT tbl.sales_force_account_id
    ,avg(tbl.emails_created) as emails_created_calc
    FROM (
      SELECT date_trunc('week',c.created_at) as created_week
              ,date_part('week',c.created_at) as week_number
              ,p.sales_force_account_id
              ,count(distinct c.id) as emails_created
      FROM communications c
      JOIN project_ids p ON p.id = c.topic_id
                          AND c.topic_type = 'Project'
      WHERE c.created_at >= now() - interval '12 weeks'
      AND c.deleted_at is null
      GROUP BY created_week, week_number, p.sales_force_account_id
    ) as tbl
    GROUP BY tbl.sales_force_account_id
),
bidding_ as (
    SELECT tbl.sales_force_account_id
    ,avg(tbl.bidding_created) as bidding_created_calc
    FROM (
      SELECT date_trunc('week',b.created_at) as created_week
            ,date_part('week',b.created_at) as week_number
            ,p.sales_force_account_id
            ,count(distinct b.id) as bidding_created
      FROM bid_packages b
      JOIN project_ids p on p.id = b.project_id
      WHERE b.created_at >= now() - interval '12 weeks'
      AND b.deleted_at IS NULL
      GROUP BY created_week, week_number, p.sales_force_account_id
    ) as tbl
    GROUP BY tbl.sales_force_account_id
),
meetings_ as (
    SELECT tbl.sales_force_account_id
    ,avg(tbl.meetings_created) as meetings_created_calc
    FROM (
      SELECT date_trunc('week',m.created_at) as created_week
            ,date_part('week',m.created_at) as week_number
            ,p.sales_force_account_id
            ,count(distinct m.id) as meetings_created
      FROM meetings m
      JOIN project_ids p on p.id = m.project_id
      WHERE m.created_at >= now() - interval '12 weeks'
      AND m.deleted_at is null
      GROUP BY created_week, week_number, p.sales_force_account_id
    ) as tbl
    GROUP BY tbl.sales_force_account_id
),
submittals_ as (
    SELECT tbl.sales_force_account_id
    ,avg(tbl.submittal_logs_created) as submittal_logs_created_calc
    ,max(tbl.cumulative_submittals_created) as cumulative_submittals_created_calc
    FROM (
      SELECT date_trunc('week',sl.created_at) as created_week
            ,date_part('week',sl.created_at) as week_number
            ,p.sales_force_account_id
            ,count(distinct sl.id) as submittal_logs_created
            ,(sum(count(distinct sl.id)) OVER (PARTITION BY p.sales_force_account_id
              ORDER BY date_trunc('week', sl.created_at))) AS cumulative_submittals_created
      FROM submittal_logs sl
      JOIN project_ids p on p.id = sl.project_id
      AND sl.deleted_at is null
      GROUP BY created_week, week_number, p.sales_force_account_id
    ) as tbl
    WHERE tbl.created_week >= now() - interval '12 weeks'
    GROUP BY tbl.sales_force_account_id
),
transmittals_ as (
    SELECT tbl.sales_force_account_id
    ,avg(tbl.transmittals_created) as transmittals_created_calc
    FROM (
      SELECT date_trunc('week',ts.created_at) as created_week
            ,date_part('week',ts.created_at) as week_number
            ,p.sales_force_account_id
            ,count(distinct ts.id) as transmittals_created
      FROM transmittals ts
        JOIN project_ids p ON p.id = ts.project_id
        WHERE ts.created_at >= now() - interval '12 weeks'
        AND ts.deleted_at is null
        GROUP BY created_week, week_number, p.sales_force_account_id
    ) as tbl
    GROUP BY tbl.sales_force_account_id
),
rfis_ as (
    select tbl.sales_force_account_id
    ,avg(tbl.rfis_created) as rfis_created_calc
    from
        (select date_trunc('week',r.created_at) as created_week
        ,date_part('week',r.created_at) as week_number
        ,p.sales_force_account_id
        ,count(distinct r.id) as rfis_created
        from rfi_headers r
        join project_ids p on p.id = r.project_id
        where r.created_at >= now() - interval '12 weeks'
        AND r.deleted_at is null
        group by created_week
        ,week_number
        ,p.sales_force_account_id
      ) as tbl
    group by tbl.sales_force_account_id
),


rfi_responses_ as (
    select tbl.sales_force_account_id
    ,avg(tbl.rfi_responses_created) as rfi_responses_created_calc
    from
        (select date_trunc('week',rr.created_at) as created_week
        ,date_part('week',rr.created_at) as week_number
        ,p.sales_force_account_id
        ,count(distinct rr.id) as rfi_responses_created
        from rfi_headers r
        inner join rfi_questions rq on rq.header_id=r.id
        inner join rfi_responses rr on rr.question_id=rq.id
        inner join project_ids p on p.id = r.project_id
        where rr.created_at >= now() - interval '12 weeks'
        AND r.deleted_at is null
        group by created_week
        ,week_number
        ,p.sales_force_account_id
      ) as tbl
    group by tbl.sales_force_account_id
  ),

photos_ as (
    select tbl.sales_force_account_id
    ,avg(tbl.photos_created) as photos_created_calc
    from
        (select date_trunc('week',i.created_at) as created_week
        ,date_part('week',i.created_at) as week_number
        ,p.sales_force_account_id
        ,count(distinct i.id) as photos_created
        from images i
        join project_ids p on p.id = i.provider_id
        where i.provider_type = 'Project'
        AND i.created_at >= now() - interval '12 weeks'
        AND i.deleted_at is null
        group by created_week
        ,week_number
        ,p.sales_force_account_id
      ) as tbl
    group by tbl.sales_force_account_id
 ),
schedules_ as (
    select tbl.sales_force_account_id
    ,avg(tbl.schedule_items_created) as schedule_items_created_calc
    from
        (select date_trunc('week',tk.start) as created_week
        ,date_part('week',tk.start) as week_number
        ,p.sales_force_account_id
        ,count(distinct tk.id) as schedule_items_created
        from tasks tk
        left join project_ids p on p.id = tk.project_id
        where tk.start >= now() - interval '12 weeks'
        group by created_week
        ,week_number
        ,p.sales_force_account_id
      ) as tbl
    group by tbl.sales_force_account_id
),
inspections_ as (
    select tbl.sales_force_account_id
    ,avg(tbl.inspections_created) as inspections_created_calc
    from
        (select date_trunc('week',cl.created_at) as created_week
        ,date_part('week',cl.created_at) as week_number
        ,p.sales_force_account_id
        ,count(distinct cl.id) as inspections_created
        from checklist_lists cl
        join tools t2 on t2.id = cl.tool_id and t2.provider_type = 'Project'
        join project_ids p on p.id = t2.provider_id
        where cl.created_at >= now() - interval '12 weeks'
        group by created_week
        ,week_number
        ,p.sales_force_account_id
      ) as tbl
    group by tbl.sales_force_account_id
),
observations_ as (
    select tbl.sales_force_account_id
    ,avg(tbl.observations_items_created) as observations_items_created_calc
    from
        (select date_trunc('week',o.created_at) as created_week
        ,date_part('week',o.created_at) as week_number
        ,p.sales_force_account_id
        ,count(distinct o.id) as observations_items_created
        from observations_items o
        join project_ids p on p.id = o.project_id
        WHERE o.created_at >= now() - interval '12 weeks'
        AND o.deleted_at is null
        group by created_week
        ,week_number
        ,p.sales_force_account_id
      ) as tbl
    group by tbl.sales_force_account_id
),
punch_items_ as (
    select tbl.sales_force_account_id
    ,avg(tbl.punch_items_created) as punch_items_created_calc
    from
        (select date_trunc('week',pi.created_at) as created_week
        ,date_part('week',pi.created_at) as week_number
        ,p.sales_force_account_id
        ,count(distinct pi.id) as punch_items_created
        from punch_items pi
        join project_ids p on p.id = pi.project_id
        where pi.created_at >= now() - interval '12 weeks'
        AND pi.deleted_at is null

        group by created_week
        ,week_number
        ,p.sales_force_account_id
      ) as tbl
    group by tbl.sales_force_account_id
),
prime_contract_ as (
    select tbl.sales_force_account_id
    ,avg(tbl.prime_contracts_created) as prime_contracts_created_calc
    from
        (select date_trunc('week',c.created_at) as created_week
        ,date_part('week',c.created_at) as week_number
        ,p.sales_force_account_id
        ,count(distinct c.id) as prime_contracts_created
        from contracts c
        join project_ids p on p.id = c.project_id
        where c.type='PrimeContract'
        AND c.created_at >= now() - interval '12 weeks'
        AND c.deleted_at is null

        group by created_week
        ,week_number
        ,p.sales_force_account_id
      ) as tbl
    group by tbl.sales_force_account_id
),

cumulative_commitments_ as (
    select tbl.sales_force_account_id
    ,avg(tbl.commitments_created) as commitments_created_calc
    ,max(tbl.cumulative_commitments_created) as cumulative_commitments_created_calc
    from
        (select date_trunc('week',c.created_at) as created_week
        ,date_part('week',c.created_at) as week_number
        ,p.sales_force_account_id
        ,count(distinct c.id) as commitments_created
        ,(sum(count(distinct c.id)) OVER (PARTITION BY p.sales_force_account_id
          ORDER BY date_trunc('week', c.created_at))) AS cumulative_commitments_created
        from contracts c
        join project_ids p on p.id = c.project_id
        where c.type <> 'PrimeContract'
        AND c.deleted_at is null
        group by created_week
        ,week_number
        ,p.sales_force_account_id
      ) as tbl
    where tbl.created_week >= now() - interval '12 weeks'
    group by tbl.sales_force_account_id
),


budget_line_items_ as (
    select tbl.sales_force_account_id
    ,avg(tbl.budget_line_items_created) as budget_line_items_created_calc
    from
        (select date_trunc('week',b.created_at) as created_week
        ,date_part('week',b.created_at) as week_number
        ,p.sales_force_account_id
        ,count(distinct b.id) as budget_line_items_created
        from budget_line_items b
        join project_ids p on p.id = b.project_id
        where b.created_at >= now() - interval '12 weeks'
        AND b.deleted_at is null

        group by created_week
        ,week_number
        ,p.sales_force_account_id
      ) as tbl
    group by tbl.sales_force_account_id
 ),
direct_costs_ as (
    select tbl.sales_force_account_id
    ,avg(tbl.direct_cost_items_created) as direct_cost_items_created_calc
    from
        (select date_trunc('week',d.created_at) as created_week
        ,date_part('week',d.created_at) as week_number
        ,p.sales_force_account_id
        ,count(distinct d.id) as direct_cost_items_created
        from direct_cost_items d
        join tools t2 on t2.id = d.tool_id and t2.provider_type = 'Project'
        join project_ids p on p.id = t2.provider_id
        where d.created_at >= now() - interval '12 weeks'
        AND d.deleted_at is null

        group by created_week
        ,week_number
        ,p.sales_force_account_id
      ) as tbl
    group by tbl.sales_force_account_id
),
change_events_ as (
    select tbl.sales_force_account_id
    ,avg(tbl.change_events_created) as change_events_created_calc
    from
        (select date_trunc('week',ce.created_at) as created_week
        ,date_part('week',ce.created_at) as week_number
        ,p.sales_force_account_id
        ,count(distinct ce.id) as change_events_created
        from change_event_events ce
        join project_ids p on p.id = ce.project_id
        where ce.created_at >= now() - interval '12 weeks'
        AND ce.deleted_at is null

        group by created_week
        ,week_number
        ,p.sales_force_account_id
      ) as tbl
    group by tbl.sales_force_account_id
),
change_orders_ as (
    select tbl.sales_force_account_id
    ,avg(tbl.change_orders_created) as change_orders_created_calc
    from
        (select date_trunc('week',cor.created_at) as created_week
        ,date_part('week',cor.created_at) as week_number
        ,p.sales_force_account_id
        ,count(distinct cor.id) as change_orders_created
        from change_order_requests cor
        join contracts c on c.id = cor.contract_id
        join project_ids p on p.id = c.project_id
        where cor.created_at >= now() - interval '12 weeks'
        AND cor.deleted_at is null

        group by created_week
        ,week_number
        ,p.sales_force_account_id
      ) as tbl
    group by tbl.sales_force_account_id
),
drawings_ as (
      select tbl.sales_force_account_id
      ,avg(tbl.drawings_created) as drawings_created_calc
      from
          (select date_trunc('week',d.created_at) as created_week
          ,date_part('week',d.created_at) as week_number
          ,p.sales_force_account_id
          ,count(distinct d.id) as drawings_created
          from drawings d
          left join project_ids p on p.id = d.project_id
          where d.created_at >= now() - interval '12 weeks'
          AND d.deleted_at is null

          group by created_week
          ,week_number
          ,p.sales_force_account_id
        ) as tbl
    group by tbl.sales_force_account_id)


,drawing_revisions_ as (
      select tbl.sales_force_account_id
      ,avg(tbl.drawing_revisions_created) as drawing_revisions_created_calc
      from
          (select date_trunc('week',dr.created_at) as created_week
          ,date_part('week',dr.created_at) as week_number
          ,p.sales_force_account_id
          ,count(distinct dr.id) as drawing_revisions_created
          from drawing_revisions dr
          join drawings d on d.id = dr.drawing_id
          join project_ids p on p.id = d.project_id
          where dr.created_at >= now() - interval '12 weeks'
          AND dr.deleted_at is null
          group by created_week
          ,week_number
          ,p.sales_force_account_id
        ) as tbl
    group by tbl.sales_force_account_id)


,specifications_ as (
      select tbl.sales_force_account_id
      ,avg(tbl.specifications_created) as specifications_created_calc
      from
          (select date_trunc('week',su.created_at) as created_week
          ,date_part('week',su.created_at) as week_number
          ,p.sales_force_account_id
          ,count(distinct su.id) as specifications_created
          from specification_uploads su
          join specification_sets ss on ss.id = su.specification_set_id
          join project_ids p on p.id = ss.project_id
          where su.created_at >= now() - interval '12 weeks'

          group by created_week
          ,week_number
          ,p.sales_force_account_id
        ) as tbl
    group by tbl.sales_force_account_id)


,specification_revisions_ as (
    select tbl.sales_force_account_id
    ,avg(tbl.specification_revisions_created) as specification_revisions_created_calc
    from
        (select date_trunc('week',sr.created_at) as created_week
        ,date_part('week',sr.created_at) as week_number
        ,p.sales_force_account_id
        ,count(distinct sr.id) as specification_revisions_created
        from specification_section_revisions sr
        join specification_sets ss on ss.id = sr.specification_set_id
        join project_ids p on p.id = ss.project_id
        join tools t on t.provider_type = 'Company' and t.provider_id = p.company_id
        join tools t2 on t2.provider_type = 'Project' and t2.provider_id = p.id
        where sr.created_at >= now() - interval '12 weeks'

        group by created_week
        ,week_number
        ,p.sales_force_account_id
      ) as tbl
    group by tbl.sales_force_account_id
),

commitment_cop as (
      select date_trunc('week',cop.created_at) as created_week
      ,date_part('week',cop.created_at) as week_number
      ,p.sales_force_account_id
      ,count(distinct cop.id) as commitment_cop_created
      from project_ids p
      inner join project_configurations pc on pc.id = p.id and pc.provider_type ='Project' --to get # of tiers
      inner join contracts c on c.project_id = p.id
      inner join change_order_packages cop on cop.contract_id = c.id
      where c.type <> 'PrimeContract'
      AND number_of_commitment_change_order_tiers = 1
      AND cop.created_at >= now() - interval '12 weeks'
      AND cop.deleted_at is null
     group by created_week
      ,week_number
      ,p.sales_force_account_id
    ),
commitment_pco as (
      select date_trunc('week',pco.created_at) as created_week
      ,date_part('week',pco.created_at) as week_number
      ,p.sales_force_account_id
      ,count(distinct pco.id) commitment_pco_created
      from project_ids p
      inner join project_configurations pc on pc.id = p.id and pc.provider_type ='Project' --to get # of tiers
      inner join contracts c on c.project_id = p.id
      inner join potential_change_orders pco on pco.contract_id = c.id and pco.project_id = p.id --more join conditions?
      where c.type <> 'PrimeContract'
      AND number_of_commitment_change_order_tiers in (2,3)
      AND pco.created_at >= now() - interval '12 weeks'
      AND pco.deleted_at is null
      group by created_week
      ,week_number
      ,p.sales_force_account_id
    ),

commitment_change_orders_ as(
      select c.sales_force_account_id
      ,avg(commitment_cop_created + commitment_pco_created) as commitment_change_orders
      from company_ids c
      left join commitment_cop on commitment_cop.sales_force_account_id=c.sales_force_account_id
      left join commitment_pco on commitment_pco.sales_force_account_id = c.sales_force_account_id
      group by c.sales_force_account_id
    ),

primecontract_cop as (
     select date_trunc('week',cop.created_at) as created_week
      ,date_part('week',cop.created_at) as week_number
      ,p.sales_force_account_id
      ,count(distinct cop.id) as primecontract_cop_created
      from project_ids p
      inner join project_configurations pc on pc.id = p.id and pc.provider_type ='Project'
      inner join contracts c on c.project_id = p.id
      inner join change_order_packages cop on cop.contract_id = c.id
      where c.type = 'PrimeContract'
      AND number_of_commitment_change_order_tiers = 1
      AND cop.created_at >= now() - interval '12 weeks'
      AND cop.deleted_at is null
      group by created_week
      ,week_number
      ,p.sales_force_account_id
    ),

primecontract_pco as (
      select date_trunc('week',pco.created_at) as created_week
      ,date_part('week',pco.created_at) as week_number
      ,p.sales_force_account_id
      ,count(distinct pco.id) primecontract_pco_created
      from project_ids p
      inner join project_configurations pc on pc.id = p.id and pc.provider_type ='Project' --to get # of tiers
      inner join contracts c on c.project_id = p.id
      inner join potential_change_orders pco on pco.contract_id = c.id and pco.project_id = p.id --more join conditions?
      where c.type = 'PrimeContract'
      AND number_of_commitment_change_order_tiers in (2,3)
      AND pco.created_at >= now() - interval '12 weeks'
      AND pco.deleted_at is null
      group by created_week
      ,week_number
      ,p.sales_force_account_id
    ),

primecontract_change_orders_ as (
    select c.sales_force_account_id
    ,avg(primecontract_cop_created + primecontract_pco_created) as primecontract_change_orders
    from company_ids c
    left join primecontract_cop on primecontract_cop.sales_force_account_id = c.sales_force_account_id
    left join primecontract_pco on primecontract_pco.sales_force_account_id = c.sales_force_account_id
    group by c.sales_force_account_id
   ),

manpower_dailylogs_ as (
    select tbl.sales_force_account_id
    ,avg(tbl.manpower_logs_created) as manpower_dailylogs_created_calc
    from
        (select date_trunc('week',ml.created_at) as created_week
        ,date_part('week',ml.created_at) as week_number
        ,p.sales_force_account_id
        ,count(distinct ml.id) as manpower_logs_created
        from daily_log_headers dl
        inner join manpower_logs ml on ml.daily_log_header_id = dl.id
        inner join project_ids p on p.id = dl.project_id
        where dl.created_at >= now() - interval '12 weeks'
        and ml.created_at >= now() - interval '12 weeks'
        AND ml.deleted_at is null
        group by created_week
        ,week_number
        ,p.sales_force_account_id
      ) as tbl
  group by tbl.sales_force_account_id
),


notes_dailylogs_ as (
   select tbl.sales_force_account_id
   ,avg(tbl.notes_logs_created) as notes_dailylogs_created_calc
   from
       (select date_trunc('week',nl.created_at) as created_week
       ,date_part('week',nl.created_at) as week_number
       ,p.sales_force_account_id
       ,count(distinct nl.id) as notes_logs_created
       from daily_log_headers dl
       inner join notes_logs nl on nl.daily_log_header_id = dl.id
       inner join project_ids p on p.id = dl.project_id
       where dl.created_at >= now() - interval '12 weeks'
       and nl.created_at >= now() - interval '12 weeks'
       AND nl.deleted_at is null
       group by created_week
       ,week_number
       ,p.sales_force_account_id
     ) as tbl
 group by tbl.sales_force_account_id
),


construction_report_dailylogs_ as (
   select tbl.sales_force_account_id
   ,avg(tbl.daily_construction_logs_created) as construction_report_dailylogs_created_calc
   from
       (select date_trunc('week',dc.created_at) as created_week
       ,date_part('week',dc.created_at) as week_number
       ,p.sales_force_account_id
       ,count(distinct dc.id) as daily_construction_logs_created
       from daily_log_headers dl
       inner join daily_construction_report_logs dc on dc.daily_log_header_id = dl.id
       inner join project_ids p on p.id = dl.project_id
       where dl.created_at >= now() - interval '12 weeks'
       and dc.created_at >= now() - interval '12 weeks'
       AND dc.deleted_at is null
       group by created_week
       ,week_number
       ,p.sales_force_account_id
     ) as tbl
 group by tbl.sales_force_account_id
)

select weekly_active_users_.sales_force_account_id
    ,date_trunc('week', now()) as upload_week
    ,max(avg_session_pages.avg_pages_per_session_calc) as "Average Pages Per Session"
    ,max(weekly_active_users_.total_active_users_calc) as "Average Total Active Users"
    ,max(weekly_active_users_.active_collaborator_users_calc) as "Average Active Collaborator Users"
    ,max(mobile_users_.mobile_active_users_calc) as "Average Mobile Active Users"
    ,max(invited_users_.weekly_invited_users_calc) as "Average Weekly Invited Users"
    ,max(invited_users_.cumulative_invited_users_calc) as "Average Cumulative Invited Users"
    ,max(case when tools_enabled.project_documents_enabled=1 then coalesce(project_documents_.project_documents_created_calc,0) when tools_enabled.project_documents_enabled=0 then -1 end
  ) as "Average Project Documents Created"
    ,max(case when tools_enabled.company_documents_enabled=1 then coalesce(company_documents_.company_documents_created_calc,0) when tools_enabled.company_documents_enabled=0 then -1 end
    ) as "Average Company Documents Created"
    ,max(case when tools_enabled.reports_enabled=1 then coalesce(reports_.reports_created_calc,0) when tools_enabled.reports_enabled=0 then -1 end
    ) as "Average Reports Created"
    ,max(case when tools_enabled.email_enabled=1 then coalesce(emails_.emails_created_calc,0) when tools_enabled.email_enabled=0 then -1 end
    ) as "Average Emails Created"
    ,max(case when tools_enabled.bidding_enabled=1 then coalesce(bidding_.bidding_created_calc,0) when tools_enabled.bidding_enabled=0 then -1 end
    ) as "Average Bid Packages Created"
    ,max(case when tools_enabled.meetings_enabled=1 then coalesce(meetings_.meetings_created_calc,0) when tools_enabled.meetings_enabled=0 then -1 end
    ) as "Average Meetings Created"
    ,max(case when tools_enabled.submittals_enabled=1 then coalesce(submittals_.submittal_logs_created_calc,0) when tools_enabled.submittals_enabled=0 then -1 end
    ) as "Average Submittals Created"
    ,max(case when tools_enabled.submittals_enabled=1 then coalesce(submittals_.cumulative_submittals_created_calc,0) when tools_enabled.submittals_enabled=0 then -1 end
    ) as "Average Cumulative Submittals Created"
    ,max(case when tools_enabled.transmittals_enabled=1 then coalesce(transmittals_.transmittals_created_calc,0) when tools_enabled.transmittals_enabled=0 then -1 end
    ) as "Average Transmittals Created"
    ,max(case when tools_enabled.rfi_enabled=1 then coalesce(rfis_.rfis_created_calc,0) when tools_enabled.rfi_enabled=0 then -1 end
    ) as "Average RFIs Created"
    ,max(case when tools_enabled.rfi_enabled=1 then coalesce(rfi_responses_.rfi_responses_created_calc,0) when tools_enabled.rfi_enabled=0 then -1 end
    ) as "Average RFI Responses Created"
    ,max(case when tools_enabled.photos_enabled=1 then coalesce(photos_.photos_created_calc,0) when tools_enabled.photos_enabled=0 then -1 end
    ) as "Average Photos Created"
    ,max(case when tools_enabled.schedule_enabled=1 then coalesce(schedules_.schedule_items_created_calc,0) when tools_enabled.schedule_enabled=0 then -1 end
    ) as "Average Schedule Items Created"
    ,max(case when tools_enabled.inspections_enabled=1 then coalesce(inspections_.inspections_created_calc,0) when tools_enabled.inspections_enabled=0 then -1 end
    ) as "Average Inspections Created"
    ,max(case when tools_enabled.observations_enabled=1 then coalesce(observations_.observations_items_created_calc,0) when tools_enabled.observations_enabled=0 then -1 end
    ) as "Average Observations Items Created"
    ,max(case when tools_enabled.punch_list_enabled=1 then coalesce(punch_items_.punch_items_created_calc,0) when tools_enabled.punch_list_enabled=0 then -1 end
    ) as "Average Punch Items Created"
    ,max(case when tools_enabled.prime_contract_enabled=1 then coalesce(prime_contract_.prime_contracts_created_calc,0) when tools_enabled.prime_contract_enabled=0 then -1 end
    ) as "Average Prime Contracts Created"
    ,max(case when tools_enabled.commitments_enabled=1 then coalesce(cumulative_commitments_.commitments_created_calc,0) when tools_enabled.commitments_enabled=0 then -1 end
    ) as "Average Commitments Created"
    ,max(case when tools_enabled.commitments_enabled=1 then coalesce(cumulative_commitments_.cumulative_commitments_created_calc,0) when tools_enabled.commitments_enabled=0 then -1 end
  ) as "Average Cumulative Commitments Created"
    ,max(case when tools_enabled.budget_enabled=1 then coalesce(budget_line_items_.budget_line_items_created_calc,0) when tools_enabled.budget_enabled=0 then -1 end
    ) as "Average Budget Line Items Created"
    ,max(case when tools_enabled.direct_costs_enabled=1 then coalesce(direct_costs_.direct_cost_items_created_calc,0) when tools_enabled.direct_costs_enabled=0 then -1 end
    ) as "Average Direct Cost Items Created"
    ,max(case when tools_enabled.change_events_enabled=1 then coalesce(change_events_.change_events_created_calc,0) when tools_enabled.change_events_enabled=0 then -1 end
    ) as "Average Change Events Created"
    ,max(case when tools_enabled.drawings_enabled=1 then coalesce(drawings_.drawings_created_calc,0) when tools_enabled.drawings_enabled=0 then -1 end
    ) as "Average Drawings Created"
    ,max(case when tools_enabled.drawings_enabled=1 then coalesce(drawing_revisions_.drawing_revisions_created_calc,0) when tools_enabled.drawings_enabled=0 then -1 end
    ) as "Average Drawing Revisions Created"
    ,max(case when tools_enabled.specifications_enabled=1 then coalesce(specifications_.specifications_created_calc,0) when tools_enabled.specifications_enabled=0 then -1 end
    ) as "Average Specifications Created"
    ,max(case when tools_enabled.specifications_enabled=1 then coalesce(specification_revisions_.specification_revisions_created_calc,0) when tools_enabled.specifications_enabled=0 then -1 end
    ) as "Average Specification Revisions Created"
    ,max(case when tools_enabled.change_orders_enabled=1 then coalesce(commitment_change_orders_.commitment_change_orders,0) when tools_enabled.change_orders_enabled=0 then -1 end
    ) as "Average Commitment Change Orders Created"
    ,max(case when tools_enabled.change_orders_enabled=1 then coalesce(primecontract_change_orders_.primecontract_change_orders,0) when tools_enabled.change_orders_enabled=0 then -1 end
    ) as "Average Prime Contract Change Orders Created"
    ,max(case when tools_enabled.daily_log_enabled=1 then coalesce(manpower_dailylogs_.manpower_dailylogs_created_calc,0) when tools_enabled.daily_log_enabled=0 then -1 end
    ) as "Average Manpower Daily Logs Created"
    ,max(case when tools_enabled.daily_log_enabled=1 then coalesce(notes_dailylogs_.notes_dailylogs_created_calc,0) when tools_enabled.daily_log_enabled=0 then -1 end
    ) as "Average Notes Daily Logs Created"
    ,max(case when tools_enabled.daily_log_enabled=1 then coalesce(construction_report_dailylogs_.construction_report_dailylogs_created_calc,0) when tools_enabled.daily_log_enabled=0 then -1 end
    ) as "Average Construction Report Daily Logs Created"


from weekly_active_users_
  left join tools_enabled on weekly_active_users_.sales_force_account_id = tools_enabled.sales_force_account_id
  left join avg_session_pages ON weekly_active_users_.sales_force_account_id = avg_session_pages.sales_force_account_id
  left join mobile_users_  on weekly_active_users_.sales_force_account_id = mobile_users_.sales_force_account_id
  left join invited_users_  on weekly_active_users_.sales_force_account_id = invited_users_.sales_force_account_id
  left join project_documents_  on weekly_active_users_.sales_force_account_id = project_documents_.sales_force_account_id
  left join company_documents_  on weekly_active_users_.sales_force_account_id = company_documents_.sales_force_account_id
  left join reports_  on weekly_active_users_.sales_force_account_id = reports_.sales_force_account_id
  left join emails_  on weekly_active_users_.sales_force_account_id = emails_.sales_force_account_id
  left join bidding_  on weekly_active_users_.sales_force_account_id = bidding_.sales_force_account_id
  left join meetings_  on weekly_active_users_.sales_force_account_id = meetings_.sales_force_account_id
  left join submittals_  on weekly_active_users_.sales_force_account_id = submittals_.sales_force_account_id
  left join transmittals_  on weekly_active_users_.sales_force_account_id = transmittals_.sales_force_account_id
  left join rfis_  on weekly_active_users_.sales_force_account_id = rfis_.sales_force_account_id
  left join rfi_responses_ on weekly_active_users_.sales_force_account_id = rfi_responses_.sales_force_account_id
  left join photos_  on weekly_active_users_.sales_force_account_id = photos_.sales_force_account_id
  left join schedules_  on weekly_active_users_.sales_force_account_id = schedules_.sales_force_account_id
  left join inspections_  on weekly_active_users_.sales_force_account_id = inspections_.sales_force_account_id
  left join observations_  on weekly_active_users_.sales_force_account_id = observations_.sales_force_account_id
  left join punch_items_  on weekly_active_users_.sales_force_account_id = punch_items_.sales_force_account_id
  left join prime_contract_  on weekly_active_users_.sales_force_account_id = prime_contract_.sales_force_account_id
  left join cumulative_commitments_  on weekly_active_users_.sales_force_account_id = cumulative_commitments_.sales_force_account_id
  left join budget_line_items_  on weekly_active_users_.sales_force_account_id = budget_line_items_.sales_force_account_id
  left join direct_costs_  on weekly_active_users_.sales_force_account_id = direct_costs_.sales_force_account_id
  left join change_events_  on weekly_active_users_.sales_force_account_id = change_events_.sales_force_account_id
  left join change_orders_  on weekly_active_users_.sales_force_account_id = change_orders_.sales_force_account_id
  left join drawings_  on weekly_active_users_.sales_force_account_id = drawings_.sales_force_account_id
  left join drawing_revisions_  on weekly_active_users_.sales_force_account_id = drawing_revisions_.sales_force_account_id
  left join specifications_  on weekly_active_users_.sales_force_account_id = specifications_.sales_force_account_id
  left join specification_revisions_  on weekly_active_users_.sales_force_account_id = specification_revisions_.sales_force_account_id
  left join commitment_change_orders_ on weekly_active_users_.sales_force_account_id = commitment_change_orders_.sales_force_account_id
  left join primecontract_change_orders_ on weekly_active_users_.sales_force_account_id = primecontract_change_orders_.sales_force_account_id
  left join manpower_dailylogs_ on weekly_active_users_.sales_force_account_id = manpower_dailylogs_.sales_force_account_id
  left join notes_dailylogs_ on weekly_active_users_.sales_force_account_id = notes_dailylogs_.sales_force_account_id
  left join construction_report_dailylogs_ on weekly_active_users_.sales_force_account_id = construction_report_dailylogs_.sales_force_account_id
group by weekly_active_users_.sales_force_account_id, upload_week
