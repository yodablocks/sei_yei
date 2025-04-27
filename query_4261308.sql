WITH
-- YEI Supply Transfers
yei_supply_transfers AS (
    SELECT 
        date_trunc('day', evt_block_time) as day,
        "from" as from_address,
        "to" as to_address
    FROM erc20_sei.evt_Transfer
        -- find contract address from yei_contract query result
        WHERE contract_address IN (
            SELECT a_token FROM query_4261812
        )
),

-- Combine All Supply Transfers
all_supply_transfers AS (
    SELECT day, to_address as user_address FROM yei_supply_transfers -- aToken is sent to to_address
),

-- Unique Active Users Per Day
daily_active_users AS (
    SELECT
        day,
        user_address,
        ROW_NUMBER() OVER (PARTITION BY user_address ORDER BY day) as first_usage
    FROM all_supply_transfers
),

-- Filter First Usage Only
first_time_users AS (
    SELECT day, user_address
    FROM daily_active_users
    WHERE first_usage = 1
),

-- Count of First-Time Users Per Day
first_time_user_counts AS (
    SELECT 
        day,
        COUNT(DISTINCT user_address) as new_active_users
    FROM first_time_users
    GROUP BY day
),

-- Generate All Days Using Existing Data
all_days AS (
    SELECT DISTINCT day
    FROM all_supply_transfers
),

-- Merge All Days with User Counts
merged_counts AS (
    SELECT 
        d.day,
        COALESCE(f.new_active_users, 0) as new_active_users
    FROM all_days d
    LEFT JOIN first_time_user_counts f ON d.day = f.day
),

-- Accumulative Count of Active Users Per Day
accumulative_active_users AS (
    SELECT 
        day,
        new_active_users,
        SUM(new_active_users) OVER (ORDER BY day ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as accumulative_active_users
    FROM merged_counts
)

-- Final Query: Show Accumulative Active Users Per Day with Daily New Active Users
SELECT 
    day,
    new_active_users,
    accumulative_active_users
FROM accumulative_active_users
ORDER BY day DESC;
