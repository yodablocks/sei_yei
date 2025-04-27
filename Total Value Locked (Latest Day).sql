-- LATEST DAY TVL(USD)
WITH 
latest_day_value AS (
    SELECT 
        day, 
        ROUND(total_value) AS total_value
    FROM query_4284626
    ORDER BY day DESC
    LIMIT 1
)

SELECT * FROM latest_day_value;
