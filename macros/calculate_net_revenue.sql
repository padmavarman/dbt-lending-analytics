-- Macro: Calculate net revenue for a loan
-- Reusable across fact and mart models

{% macro calculate_net_revenue(interest_col, late_fee_col, recovery_col, collection_fee_col) %}
    ({{ interest_col }} + {{ late_fee_col }} + {{ recovery_col }} - {{ collection_fee_col }})
{% endmacro %}
