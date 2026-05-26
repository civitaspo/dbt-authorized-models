{{ config(
    enabled=var("enable_unauthorized_source_report", false),
    materialized="view"
) }}

select
    customer_id,
    customer_name
from {{ source("raw", "customers") }}
