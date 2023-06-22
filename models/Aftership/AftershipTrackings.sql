{% if var('AftershipTrackings') %}
{{ config( enabled = True ) }}
{% else %}
{{ config( enabled = False ) }}
{% endif %}

{% if is_incremental() %}
{%- set max_loaded_query -%}
SELECT coalesce(MAX(_daton_batch_runtime)-2592000000,0) FROM {{ this }}
{% endset %}

{%- set max_loaded_results = run_query(max_loaded_query) -%}


{%- if execute -%}
{% set max_loaded = max_loaded_results.rows[0].values()[0] %}
{% else %}
{% set max_loaded = 0 %}
{%- endif -%}
{% endif %}

{% set table_name_query %}
{{set_table_name('%aftership%trackings')}}    
{% endset %} 

{% set results = run_query(table_name_query) %}

{% if execute %}
{# Return the first column #}
{% set results_list = results.columns[0].values() %}
{% else %}
{% set results_list = [] %}
{% endif %}

{% for i in results_list %}
        {% if var('get_brandname_from_tablename_flag') %}
            {% set brand =i.split('.')[2].split('_')[var('brandname_position_in_tablename')] %}
        {% else %}
            {% set brand = var('default_brandname') %}
        {% endif %}

        {% if var('get_storename_from_tablename_flag') %}
            {% set store =i.split('.')[2].split('_')[var('storename_position_in_tablename')] %}
        {% else %}
            {% set store = var('default_storename') %}
        {% endif %}

        {% if var('timezone_conversion_flag') and i.lower() in tables_lowercase_list and i in var('raw_table_timezone_offset_hours') %}
            {% set hr = var('raw_table_timezone_offset_hours')[i] %}
        {% else %}
            {% set hr = 0 %}
        {% endif %}

    SELECT * {{exclude()}}(rnk)
    FROM (
        SELECT
        '{{brand}}' as brand,
        '{{store}}' as store,
        id,
        a.created_at,
        updated_at,
        last_updated_at,
        a.tracking_number,
        a.slug,
        active,
        checkpoints,
        {% if target.type=='snowflake' %} 
        custom_fields.VALUE:item_names::VARCHAR as custom_fields_item_names,
        latest_estimated_delivery.VALUE:type::VARCHAR as latest_estimated_delivery_type,
        latest_estimated_delivery.VALUE:source::VARCHAR as latest_estimated_delivery_source,
        latest_estimated_delivery.VALUE:datetime::TIMESTAMP as latest_estimated_delivery_datetime,
        first_estimated_delivery.VALUE:type::VARCHAR as first_estimated_delivery_type,
        first_estimated_delivery.VALUE:source::VARCHAR as first_estimated_delivery_source,
        first_estimated_delivery.VALUE:datetime::TIMESTAMP as first_estimated_delivery_datetime,
        first_estimated_delivery.VALUE:datetime_dtm::TIMESTAMP as first_estimated_delivery_datetime_dtm,
        next_couriers.VALUE:slug::VARCHAR as next_couriers_slug,
        next_couriers.VALUE:tracking_number::VARCHAR as next_couriers_tracking_number,
        next_couriers.VALUE:source::VARCHAR as next_couriers_source,
        {% else %}
        custom_fields.item_names as custom_fields_item_names,
        latest_estimated_delivery.type as latest_estimated_delivery_type,
        latest_estimated_delivery.source as latest_estimated_delivery_source,
        latest_estimated_delivery.datetime as latest_estimated_delivery_datetime,
        first_estimated_delivery.type as first_estimated_delivery_type,
        first_estimated_delivery.source as first_estimated_delivery_source,
        first_estimated_delivery.datetime as first_estimated_delivery_datetime,
        first_estimated_delivery.datetime_dtm as first_estimated_delivery_datetime_dtm,
        next_couriers.slug as next_couriers_slug,
        next_couriers.tracking_number as next_couriers_tracking_number,
        next_couriers.source as next_couriers_source,
        {% endif %}
        customer_name,
        delivery_time,
        destination_country_iso3,
        courier_destination_country_iso3,
        emails,
        note,
        order_id,
        order_date,
        origin_country_iso3,
        shipment_pickup_date,
        a.source,
        a.tag,
        a.subtag,
        a.subtag_message,
        title,
        tracked_count,
        last_mile_tracking_supported,
        language,
        unique_token,
        return_to_sender,
        courier_tracking_link,
        courier_redirect_link,
        order_tags,
        order_number,
        destination_raw_location,
        origin_raw_location,
        destination_city,
        destination_postal_code,
        tracking_destination_country,
        tracking_postal_code,
        tracking_ship_date,
        shipment_delivery_date,
        pickup_location,
        first_attempted_at,
        smses,
        expected_delivery,
        shipment_weight,
        shipment_weight_unit,
        origin_postal_code,
        shipment_type,
        shipment_delivery_date_dtm,
        first_attempted_at_dtm,
        destination_state,
        signed_by,
        shipment_pickup_date_dtm,
        shipment_package_count,
        tracking_state,
        tracking_origin_country,
        {{daton_user_id()}} as _daton_user_id,
        {{daton_batch_runtime()}} as _daton_batch_runtime,
        {{daton_batch_id()}} as _daton_batch_id,
        current_timestamp() as _last_updated,
        '{{env_var("DBT_CLOUD_RUN_ID", "manual")}}' as _run_id,
        ROW_NUMBER() OVER (PARTITION BY id ORDER BY {{daton_batch_runtime()}} DESC) AS rnk
        FROM {{i}} a
                {{unnesting("custom_fields")}} 
                {{unnesting("latest_estimated_delivery")}} 
                {{unnesting("first_estimated_delivery")}} 
                {{unnesting("next_couriers")}} 
            {% if is_incremental() %}
            {# /* -- this filter will only be applied on an incremental run */ #}
            WHERE {{daton_batch_runtime()}} >= {{max_loaded}}
            {% endif %})
    WHERE rnk = 1
    {% if not loop.last %} union all {% endif %}
{% endfor %}