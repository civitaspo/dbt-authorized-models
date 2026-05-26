{{ config(
    enabled=var("enable_missing_authorize_source_report", false),
    materialized="view"
) }}

select
    customer_id,
    customer_name
from {{ source("missing_authorize", "customers") }}
