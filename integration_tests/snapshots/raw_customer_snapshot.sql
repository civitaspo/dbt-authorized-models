{% snapshot raw_customer_snapshot %}
{{
    config(
        target_schema="snapshots",
        unique_key="customer_id",
        strategy="check",
        check_cols=["customer_name"],
        meta={"authorize": ["*"]},
    )
}}

select
    customer_id,
    customer_name
from {{ source("raw", "customers") }}

{% endsnapshot %}
