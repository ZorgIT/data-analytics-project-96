WITH paid_sessions AS (
    SELECT
        s.visitor_id,
        s.visit_date,
        s.source AS utm_source,
        s.medium AS utm_medium,
        s.campaign AS utm_campaign,
        s.content AS utm_content
    FROM
        sessions s
    WHERE
        s.medium IN ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
),
lead_last_paid_session AS (
    SELECT
        l.lead_id,
        l.visitor_id,
        l.created_at,
        l.amount,
        l.closing_reason,
        l.status_id,
        s.visit_date,
        s.utm_source,
        s.utm_medium,
        s.utm_campaign
    FROM
        leads l
    LEFT JOIN LATERAL (
        SELECT
            ps.visit_date,
            ps.utm_source,
            ps.utm_medium,
            ps.utm_campaign
        FROM
            paid_sessions ps
        WHERE
            ps.visitor_id = l.visitor_id
            AND ps.visit_date <= l.created_at
        ORDER BY
            ps.visit_date DESC
        LIMIT 1
    ) s ON TRUE
),
data_mart AS (
    SELECT
        ps.visitor_id,
        ps.visit_date,
        ps.utm_source,
        ps.utm_medium,
        ps.utm_campaign,
        llps.lead_id,
        llps.created_at,
        llps.amount,
        llps.closing_reason,
        llps.status_id
    FROM
        paid_sessions ps
    LEFT JOIN
        lead_last_paid_session llps
    ON
        ps.visitor_id = llps.visitor_id
        AND ps.visit_date = llps.visit_date
)

SELECT
    visitor_id,
    visit_date,
    utm_source,
    utm_medium,
    utm_campaign,
    lead_id,
    created_at,
    amount,
    closing_reason,
    status_id
FROM
    data_mart
ORDER BY
    amount DESC NULLS LAST,
    visit_date ASC,
    utm_source ASC,
    utm_medium ASC,
    utm_campaign asc;
