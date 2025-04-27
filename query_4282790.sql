WITH
-- `daily_net_flow`：根據 yei contracts(query_4261812)，計算每個代幣的每日淨供應量，並將轉移量標準化為代幣的正確單位
daily_net_flow AS (
    SELECT
        date_trunc('day', evt_block_time) AS day,
        symbol,
        SUM(CASE WHEN "to" != from_hex('0000000000000000000000000000000000000000') THEN CAST(value AS double) / POW(10, yc.decimal) ELSE 0 END) -
        SUM(CASE WHEN "from" != from_hex('0000000000000000000000000000000000000000') THEN CAST(value AS double) / POW(10, yc.decimal) ELSE 0 END) AS net_difference
    FROM erc20_sei.evt_Transfer
    JOIN query_4261812 yc ON erc20_sei.evt_Transfer.contract_address = yc.debt_token
    GROUP BY date_trunc('day', evt_block_time), underlying_token, symbol
),

-- `daily_balance_by_symbol`：將每日淨供應變動值與所有日期範圍匹配，確保每個代幣在每一天都有記錄，即使該日無交易，淨變動量設置為0
daily_balance_by_symbol AS (
    SELECT DISTINCT
        dp.date AS day,
        dns.symbol,
        COALESCE(dns.net_difference, 0) AS net_difference
    FROM query_4280480 dp
    LEFT JOIN daily_net_flow dns ON dp.date = dns.day
    WHERE dns.symbol IN ('USDT', 'USDC', 'SEI', 'iSEI', 'WETH', 'sFRAX', 'FRAX', 'frxETH', 'sfrxETH', 'fastUSD', 'sfastUSD','sfrxUSD','frxUSD', 'WBTC', 'SolvBTC', 'xSolvBTC', 'wstETH', 'USDT0')  -- 根據需要篩選對應的 symbol
),

-- `net_balance_per_symbol_per_day`：將每日每種代幣的淨變動值分配至各欄位，並填補無交易的日期數值為0
net_balance_per_symbol_per_day AS (
    SELECT
        day,
        COALESCE(MAX(CASE WHEN symbol = 'USDT' THEN net_difference END), 0) AS usdt_net_balance,
        COALESCE(MAX(CASE WHEN symbol = 'USDC' THEN net_difference END), 0) AS usdc_net_balance,
        COALESCE(MAX(CASE WHEN symbol = 'SEI' THEN net_difference END), 0) AS sei_net_balance,
        COALESCE(MAX(CASE WHEN symbol = 'iSEI' THEN net_difference END), 0) AS isei_net_balance,
        COALESCE(MAX(CASE WHEN symbol = 'WETH' THEN net_difference END), 0) AS weth_net_balance,
        COALESCE(MAX(CASE WHEN symbol = 'FRAX' THEN net_difference END), 0) AS frax_net_balance,
        COALESCE(MAX(CASE WHEN symbol = 'sFRAX' THEN net_difference END), 0) AS sfrax_net_balance,
        COALESCE(MAX(CASE WHEN symbol = 'frxETH' THEN net_difference END), 0) AS frxeth_net_balance,
        COALESCE(MAX(CASE WHEN symbol = 'sfrxETH' THEN net_difference END), 0) AS sfrxeth_net_balance,
        COALESCE(MAX(CASE WHEN symbol = 'fastUSD' THEN net_difference END), 0) AS fastusd_net_balance,
        COALESCE(MAX(CASE WHEN symbol = 'sfastUSD' THEN net_difference END), 0) AS sfastusd_net_balance,
        COALESCE(MAX(CASE WHEN symbol = 'sfrxUSD' THEN net_difference END), 0) AS sfrxusd_net_balance,
        COALESCE(MAX(CASE WHEN symbol = 'frxUSD' THEN net_difference END), 0) AS frxusd_net_balance,
        COALESCE(MAX(CASE WHEN symbol = 'WBTC' THEN net_difference END), 0) AS wbtc_net_balance,
        COALESCE(MAX(CASE WHEN symbol = 'SolvBTC' THEN net_difference END), 0) AS solvbtc_net_balance,
        COALESCE(MAX(CASE WHEN symbol = 'xSolvBTC' THEN net_difference END), 0) AS xsolvbtc_net_balance,
        COALESCE(MAX(CASE WHEN symbol = 'wstETH' THEN net_difference END), 0) AS wsteth_net_balance,
        COALESCE(MAX(CASE WHEN symbol = 'USDT0' THEN net_difference END), 0) AS usdt0_net_balance
    FROM daily_balance_by_symbol
    GROUP BY day
    ORDER BY day
),

-- `cumulative_balance_per_symbol`：計算每種代幣的累積供應量，利用 `WINDOW` 函數將每日的淨供應變動量進行累加
cumulative_balance_per_symbol AS (
    SELECT
        day,
        SUM(usdt_net_balance) OVER (ORDER BY day ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS usdt_cumulative_balance,
        SUM(usdc_net_balance) OVER (ORDER BY day ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS usdc_cumulative_balance,
        SUM(sei_net_balance) OVER (ORDER BY day ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS sei_cumulative_balance,
        SUM(isei_net_balance) OVER (ORDER BY day ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS isei_cumulative_balance,
        SUM(weth_net_balance) OVER (ORDER BY day ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS weth_cumulative_balance,
        SUM(frax_net_balance) OVER (ORDER BY day ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS frax_cumulative_balance,
        SUM(sfrax_net_balance) OVER (ORDER BY day ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS sfrax_cumulative_balance,
        SUM(frxeth_net_balance) OVER (ORDER BY day ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS frxeth_cumulative_balance,
        SUM(sfrxeth_net_balance) OVER (ORDER BY day ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS sfrxeth_cumulative_balance,
        SUM(fastusd_net_balance) OVER (ORDER BY day ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS fastusd_cumulative_balance,
        SUM(sfastusd_net_balance) OVER (ORDER BY day ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS sfastusd_cumulative_balance,
        SUM(sfrxusd_net_balance) OVER (ORDER BY day ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS sfrxusd_cumulative_balance,
        SUM(frxusd_net_balance) OVER (ORDER BY day ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS frxusd_cumulative_balance,
        SUM(wbtc_net_balance) OVER (ORDER BY day ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS wbtc_cumulative_balance,
        SUM(solvbtc_net_balance) OVER (ORDER BY day ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS solvbtc_cumulative_balance,
        SUM(xsolvbtc_net_balance) OVER (ORDER BY day ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS xsolvbtc_cumulative_balance,
        SUM(wsteth_net_balance) OVER (ORDER BY day ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS wsteth_cumulative_balance,
        SUM(usdt0_net_balance) OVER (ORDER BY day ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS usdt0_cumulative_balance

    FROM net_balance_per_symbol_per_day
    ORDER BY day
),

-- `usd_value_per_symbol`：將累積的供應量轉換為美元價值，根據 `dp` 中的每種代幣價格進行計算，並按每日匯總
usd_value_per_symbol AS (
    SELECT
        cb.day,
        -- 根據 symbol 來選擇對應的價格並計算 USD 值
        COALESCE(SUM(CASE WHEN dp.symbol = 'USDT' THEN cb.usdt_cumulative_balance * dp.usd_price ELSE 0 END), 0) AS usdt_value,
        COALESCE(SUM(CASE WHEN dp.symbol = 'USDC' THEN cb.usdc_cumulative_balance * dp.usd_price ELSE 0 END), 0) AS usdc_value,
        COALESCE(SUM(CASE WHEN dp.symbol = 'SEI' THEN cb.sei_cumulative_balance * dp.usd_price ELSE 0 END), 0) AS sei_value,
        COALESCE(SUM(CASE WHEN dp.symbol = 'iSEI' THEN cb.isei_cumulative_balance * dp.usd_price ELSE 0 END), 0) AS isei_value,
        COALESCE(SUM(CASE WHEN dp.symbol = 'WETH' THEN cb.weth_cumulative_balance * dp.usd_price ELSE 0 END), 0) AS weth_value,
        COALESCE(SUM(CASE WHEN dp.symbol = 'FRAX' THEN cb.frax_cumulative_balance * dp.usd_price ELSE 0 END), 0) AS frax_value,
        COALESCE(SUM(CASE WHEN dp.symbol = 'sFRAX' THEN cb.sfrax_cumulative_balance * dp.usd_price ELSE 0 END), 0) AS sfrax_value,
        COALESCE(SUM(CASE WHEN dp.symbol = 'frxETH' THEN cb.frxeth_cumulative_balance * dp.usd_price ELSE 0 END), 0) AS frxeth_value,
        COALESCE(SUM(CASE WHEN dp.symbol = 'sfrxETH' THEN cb.sfrxeth_cumulative_balance * dp.usd_price ELSE 0 END), 0) AS sfrxeth_value,
        COALESCE(SUM(CASE WHEN dp.symbol = 'fastUSD' THEN cb.fastusd_cumulative_balance * dp.usd_price ELSE 0 END), 0) AS fastusd_value,
        COALESCE(SUM(CASE WHEN dp.symbol = 'sfastUSD' THEN cb.sfastusd_cumulative_balance * dp.usd_price ELSE 0 END), 0) AS sfastusd_value,
        COALESCE(SUM(CASE WHEN dp.symbol = 'sfrxUSD' THEN cb.sfrxusd_cumulative_balance * dp.usd_price ELSE 0 END), 0) AS sfrxusd_value,
        COALESCE(SUM(CASE WHEN dp.symbol = 'frxUSD' THEN cb.frxusd_cumulative_balance * dp.usd_price ELSE 0 END), 0) AS frxusd_value,
        COALESCE(SUM(CASE WHEN dp.symbol = 'WBTC' THEN cb.wbtc_cumulative_balance * dp.usd_price ELSE 0 END), 0) AS wbtc_value,
        COALESCE(SUM(CASE WHEN dp.symbol = 'Solvbtc' THEN cb.solvbtc_cumulative_balance * dp.usd_price ELSE 0 END), 0) AS solvbtc_value,
        COALESCE(SUM(CASE WHEN dp.symbol = 'xSolvbtc' THEN cb.xsolvbtc_cumulative_balance * dp.usd_price ELSE 0 END), 0) AS xsolvbtc_value,
        COALESCE(SUM(CASE WHEN dp.symbol = 'wstETH' THEN cb.wsteth_cumulative_balance * dp.usd_price ELSE 0 END), 0) AS wsteth_value,
        COALESCE(SUM(CASE WHEN dp.symbol = 'USDT0' THEN cb.usdt0_cumulative_balance * dp.usd_price ELSE 0 END), 0) AS usdt0_value
    FROM cumulative_balance_per_symbol cb
    JOIN query_4280480 dp ON cb.day = dp.date
    GROUP BY cb.day
    ORDER BY cb.day DESC
)

-- 查詢最終結果，按日期排序
SELECT * FROM usd_value_per_symbol
ORDER BY day
