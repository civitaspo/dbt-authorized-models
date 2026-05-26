{{ config(
    tags=["pii_approved"],
    materialized="view"
) }}

select
    customer_id,
    customer_name,
    email
from {{ ref("customer_pii") }}
