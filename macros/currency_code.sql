{% macro currency_code(variable) %}
    case
    when {{variable}}  = 'United States' or {{variable}}  = 'US' then 'USD'
    when {{variable}}  = 'Canada' or {{variable}}  = 'CA' then 'CAD'
    when {{variable}}  = 'India' or {{variable}}  = 'IN' then 'INR'
    else {{variable}}  end as currency
{% endmacro %}