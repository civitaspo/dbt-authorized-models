{{ config(materialized="view") }}

select
    customer_id,
    customer_name
from {{ source("project_meta_table", "customers") }}
