{{ config(
    enabled=var("enable_empty_authorize_source_report", false),
    materialized="view"
) }}

select
    customer_id,
    customer_name
from {{ source("empty_authorize", "customers") }}
