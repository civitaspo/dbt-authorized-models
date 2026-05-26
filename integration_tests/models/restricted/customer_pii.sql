{{ config(materialized="view") }}

select
    1 as customer_id,
    'Ada Lovelace' as customer_name,
    'ada@example.com' as email,
    '123-45-6789' as ssn
