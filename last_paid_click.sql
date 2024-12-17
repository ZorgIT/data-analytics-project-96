select
    tabb.visitor_id,
    tabb.visit_date,
    tabb.source as utm_source,
    tabb.medium as utm_medium,
    tabb.campaign as utm_campaign,
    l.lead_id,
    l.created_at,
    sum(l.amount) as amount,
    l.closing_reason,
    l.status_id
from
    (
        select distinct on (s.visitor_id)
            s.visitor_id,
            s.visit_date,
            s.source,
            s.medium,
            s.campaign
        from sessions as s
        where
            s.medium = 'cpc' or s.medium = 'cpm'
            or s.medium = 'cpa' or s.medium = 'youtube'
            or s.medium = 'cpp' or s.medium = 'tg'
            or s.medium = 'social'
        order by s.visitor_id asc, s.visit_date desc
    ) as tabb
left join leads as l
    on
        tabb.visitor_id = l.visitor_id
group by
    tabb.visitor_id, tabb.visit_date, utm_source, utm_medium, utm_campaign,
    l.lead_id, l.created_at, l.closing_reason, l.status_id
order by
    amount desc nulls last,
    tabb.visit_date asc, utm_source asc,
    utm_medium asc, utm_campaign asc
limit 10