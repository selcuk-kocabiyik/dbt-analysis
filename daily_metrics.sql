{{
  config(
    materialized='table',
    partition_by={
      "field": "event_date",
      "data_type": "date"
    },
    cluster_by=["country", "platform"]
  )
}}

WITH daily_aggregates AS (
  SELECT
    event_date,
    country,
    platform,
    COUNT(DISTINCT user_id) as dau,
    SUM(COALESCE(iap_revenue, 0)) as total_iap_revenue,
    SUM(COALESCE(ad_revenue, 0)) as total_ad_revenue,
    SUM(COALESCE(match_start_count, 0)) as matches_started,
    SUM(COALESCE(match_end_count, 0)) as matches_ended,
    SUM(COALESCE(victory_count, 0)) as total_victories,
    SUM(COALESCE(defeat_count, 0)) as total_defeats,
    SUM(COALESCE(server_connection_error, 0)) as total_server_errors
  FROM {{ source('bi_projects', 'raw_user_daily_metrics') }}
  WHERE event_date IS NOT NULL
    AND user_id IS NOT NULL
    AND country IS NOT NULL
    AND platform IS NOT NULL
  GROUP BY 1, 2, 3
)

SELECT
  event_date,
  country,
  platform,
  dau,
  total_iap_revenue,
  total_ad_revenue,
  
  -- ARPDAU calculation
  CASE 
    WHEN dau > 0 THEN (total_iap_revenue + total_ad_revenue) / dau 
    ELSE 0 
  END as arpdau,
  
  matches_started,
  
  -- Match per DAU
  CASE 
    WHEN dau > 0 THEN matches_started / dau 
    ELSE 0 
  END as match_per_dau,
  
  -- Win ratio
  CASE 
    WHEN matches_ended > 0 THEN total_victories / matches_ended 
    ELSE 0 
  END as win_ratio,
  
  -- Defeat ratio
  CASE 
    WHEN matches_ended > 0 THEN total_defeats / matches_ended 
    ELSE 0 
  END as defeat_ratio,
  
  -- Server error per DAU
  CASE 
    WHEN dau > 0 THEN total_server_errors / dau 
    ELSE 0 
  END as server_error_per_dau

FROM daily_aggregates
WHERE dau > 0  -- Filter out days with no active users