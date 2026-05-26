{{ config(materialized="view") }}

select
    1 as customer_id,
    'Ada Lovelace' as customer_name
