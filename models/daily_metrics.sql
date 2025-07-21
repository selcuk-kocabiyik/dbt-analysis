{{
  config(
    materialized='incremental',
    unique_key=['event_date', 'country', 'platform'],
    partition_by={
      "field": "event_date",
      "data_type": "date"
    }
  )
}}

-- Base metrics calculation
WITH base_metrics AS (
  SELECT
    event_date,
    country,
    platform,
    COUNT(DISTINCT CASE WHEN total_session_duration >= 10 OR COALESCE(iap_revenue, 0) > 0 OR COALESCE(ad_revenue, 0) > 0 THEN user_id END) as dau,
    SUM(COALESCE(iap_revenue, 0)) as total_iap_revenue,
    SUM(COALESCE(ad_revenue, 0)) as total_ad_revenue,
    SUM(CASE WHEN total_session_duration >= 10 THEN COALESCE(iap_revenue, 0) ELSE 0 END) + 
    SUM(CASE WHEN total_session_duration >= 10 THEN COALESCE(ad_revenue, 0) ELSE 0 END) as qualified_total_revenue,
    SUM(CASE WHEN total_session_duration >= 10 THEN COALESCE(match_start_count, 0) ELSE 0 END) as matches_started,
    SUM(CASE WHEN total_session_duration >= 10 THEN COALESCE(server_connection_error, 0) ELSE 0 END) as server_errors,
    SUM(COALESCE(match_end_count, 0)) as total_matches_ended,
    SUM(COALESCE(victory_count, 0)) as total_victories,
    SUM(COALESCE(defeat_count, 0)) as total_defeats
  FROM {{ source('bi_projects', 'dataset') }}
  WHERE event_date IS NOT NULL
    AND user_id IS NOT NULL
    AND country IS NOT NULL
    AND platform IS NOT NULL
    {% if is_incremental() %}
      AND event_date > (SELECT DATE_SUB(MAX(event_date), INTERVAL 3 DAY) FROM {{ this }})
    {% endif %}
  GROUP BY event_date, country, platform
)

SELECT
  event_date,
  country,
  platform,
  dau,
  total_iap_revenue,
  total_ad_revenue,
  
  -- ARPDAU calculation (only for qualified DAU)
  CASE 
    WHEN dau > 0 
    THEN qualified_total_revenue / dau
    ELSE 0 
  END as arpdau,
  
  matches_started,
  
  -- Match per DAU (only for qualified DAU)
  CASE 
    WHEN dau > 0 
    THEN matches_started / dau
    ELSE 0 
  END as match_per_dau,
  
  -- Win ratio
  CASE 
    WHEN total_matches_ended > 0 
    THEN total_victories / total_matches_ended
    ELSE 0 
  END as win_ratio,
  
  -- Defeat ratio
  CASE 
    WHEN total_matches_ended > 0 
    THEN total_defeats / total_matches_ended
    ELSE 0 
  END as defeat_ratio,
  
  -- Server error per DAU (only for qualified DAU)
  CASE 
    WHEN dau > 0 
    THEN server_errors / dau
    ELSE 0 
  END as server_error_per_dau

FROM base_metrics