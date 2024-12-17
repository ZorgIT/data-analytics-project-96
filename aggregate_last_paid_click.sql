WITH combined_ads AS (
    SELECT 
        utm_source,
        utm_medium,
        utm_campaign,
        utm_content,
        DATE(campaign_date) AS campaign_date,
        daily_spent
    FROM ya_ads
    UNION ALL
    SELECT 
        utm_source,
        utm_medium,
        utm_campaign,
        utm_content,
        DATE(campaign_date) AS campaign_date,
        daily_spent
    FROM vk_ads
),
ad_cost AS (
    SELECT
        campaign_date AS visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        SUM(daily_spent) AS total_cost
    FROM combined_ads
    GROUP BY 
        campaign_date,
        utm_source,
        utm_medium,
        utm_campaign
),
session_data AS (
    SELECT
        DATE(visit_date) AS visit_date,
        source AS utm_source,
        medium AS utm_medium,
        campaign AS utm_campaign,
        content AS utm_content,
        visitor_id
    FROM sessions
),
visitors_agg AS (
    SELECT
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        COUNT(DISTINCT visitor_id) AS visitors_count
    FROM session_data
    GROUP BY
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign
),
leads_agg AS (
    SELECT
        DATE(s.visit_date) AS visit_date,
        s.source AS utm_source,
        s.medium AS utm_medium,
        s.campaign AS utm_campaign,
        COUNT(DISTINCT l.lead_id) AS leads_count
    FROM sessions s
    JOIN leads l ON s.visitor_id = l.visitor_id
    WHERE DATE(s.visit_date) = DATE(l.created_at)
    GROUP BY
        DATE(s.visit_date),
        s.source,
        s.medium,
        s.campaign
),
purchases_agg AS (
    SELECT
        DATE(s.visit_date) AS visit_date,
        s.source AS utm_source,
        s.medium AS utm_medium,
        s.campaign AS utm_campaign,
        COUNT(DISTINCT l.lead_id) AS purchases_count,
        SUM(l.amount) AS revenue
    FROM sessions s
    JOIN leads l ON s.visitor_id = l.visitor_id
    WHERE DATE(s.visit_date) = DATE(l.created_at)
      AND (
          l.closing_reason = 'Успешно реализовано' 
          OR l.status_id = 142
      )
    GROUP BY
        DATE(s.visit_date),
        s.source,
        s.medium,
        s.campaign
)
SELECT
    v.visit_date,
    sum(v.visitors_count) as visitors_count,
    v.utm_source,
    v.utm_medium,
    v.utm_campaign,
    sum(COALESCE(a.total_cost, 0)) AS total_cost,
    sum(COALESCE(le.leads_count, 0)) AS leads_count,
    sum(COALESCE(p.purchases_count, 0)) AS purchases_count,
    sum(COALESCE(p.revenue, 0)) AS revenue
FROM visitors_agg v
LEFT JOIN ad_cost a
    ON v.visit_date = a.visit_date
    AND v.utm_source = a.utm_source
    AND v.utm_medium = a.utm_medium
    AND v.utm_campaign = a.utm_campaign
LEFT JOIN leads_agg le
    ON v.visit_date = le.visit_date
    AND v.utm_source = le.utm_source
    AND v.utm_medium = le.utm_medium
    AND v.utm_campaign = le.utm_campaign
LEFT JOIN purchases_agg p
    ON v.visit_date = p.visit_date
    AND v.utm_source = p.utm_source
    AND v.utm_medium = p.utm_medium
    AND v.utm_campaign = p.utm_campaign
group by v.visit_date,v.visitors_count, v.utm_source, v.utm_medium,v.utm_campaign
ORDER BY
    revenue DESC NULLS LAST,
    visit_date ASC,
    visitors_count DESC,
    utm_source ASC,
    utm_medium ASC,
    utm_campaign asc
 limit 15;
