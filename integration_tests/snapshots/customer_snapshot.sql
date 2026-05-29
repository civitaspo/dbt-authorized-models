{% snapshot customer_snapshot %}
{{
    config(
        target_schema="snapshots",
        unique_key="customer_id",
        strategy="check",
        check_cols=["customer_name"],
        meta={
            "authorize": [
                {
                    "resource_type": "model",
                    "database": ".*",
                    "schema": ".*marts",
                    "identifier": "snapshot_customer_report",
                }
            ]
        },
    )
}}

select
    customer_id,
    customer_name
from {{ ref("customers") }}

{% endsnapshot %}
