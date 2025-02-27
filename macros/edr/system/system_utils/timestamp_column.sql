{% macro run_start_column() %}
    cast ('{{ run_started_at.strftime("%Y-%m-%d %H:%M:%S") }}' as {{ dbt_utils.type_timestamp() }})
{% endmacro %}

{% macro current_timestamp_column() %}
    cast ({{dbt_utils.current_timestamp_in_utc()}} as {{ dbt_utils.type_timestamp() }})
{% endmacro %}