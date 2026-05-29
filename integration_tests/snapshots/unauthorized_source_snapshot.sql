{% snapshot unauthorized_source_snapshot %}
{{
    config(
        enabled=var("enable_unauthorized_source_snapshot", false),
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
