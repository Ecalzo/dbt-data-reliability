{{
  config(
    materialized = 'incremental',
    unique_key = 'config_id'
  )
}}


with tables_config as (

    select * from {{ elementary.get_source_path('edr_configuration', 'table_monitors_config') }}

),

information_schema_tables as (

    select * from {{ ref('filtered_information_schema_tables') }}

),

information_schema_columns as (

    select * from {{ ref('filtered_information_schema_columns') }}

),

config_existing_tables as (

    select
        {{ dbt_utils.surrogate_key([
            'config.full_table_name','config.table_monitors', 'config.columns_monitored', 'config.timestamp_column'
        ]) }} as config_id,
        upper(config.full_table_name) as full_table_name,
        upper(config.database_name) as database_name,
        upper(config.schema_name) as schema_name,
        upper(config.table_name) as table_name,
        col.column_name as timestamp_column,
        bucket_duration_hours,
        table_monitored,
        table_monitors,
        columns_monitored,
        case
            when col.data_type in {{ elementary.strings_list_to_tuple(elementary.data_type_list('timestamp')) }} then 'timestamp'
            when col.data_type in {{ elementary.strings_list_to_tuple(elementary.data_type_list('string')) }} then 'string'
            else null
        end as timestamp_column_data_type,
        {{ elementary.run_start_column() }} as config_loaded_at
    from
        information_schema_tables as info_schema join tables_config as config
        on (upper(info_schema.database_name) = upper(config.database_name)
            and upper(info_schema.schema_name) = upper(config.schema_name)
            and upper(info_schema.table_name) = upper(config.table_name))
        left join information_schema_columns as col
        on (upper(col.database_name) = upper(config.database_name)
            and upper(col.schema_name) = upper(config.schema_name)
            and upper(col.table_name) = upper(config.table_name)
            and upper(col.column_name) = upper(config.timestamp_column))

),

final as (

    select
        config_id,
        full_table_name,
        database_name,
        schema_name,
        table_name,
        timestamp_column,
        timestamp_column_data_type,
        bucket_duration_hours,
        table_monitored,
        table_monitors,
        columns_monitored,
        max(config_loaded_at) as config_loaded_at
    from config_existing_tables
    group by 1,2,3,4,5,6,7,8,9,10,11

)

select *
from final
