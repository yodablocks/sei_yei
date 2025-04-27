-- TVL (supply-borrow)
WITH tvl_calculation AS (
    SELECT
        s.day,
        -- 計算每個 token 的 TVL：supply 減去 borrow
        s.usdt_value - b.usdt_value AS usdt_vl,
        s.usdc_value - b.usdc_value AS usdc_vl,
        s.sei_value - b.sei_value AS sei_vl,
        s.isei_value - b.isei_value AS isei_vl,
        s.weth_value - b.weth_value AS weth_vl,
        s.frax_value - b.frax_value AS frax_vl,
        s.sfrax_value - b.sfrax_value AS sfrax_vl,
        s.frxeth_value - b.frxeth_value AS frxeth_vl,
        s.sfrxeth_value - b.sfrxeth_value AS sfrxeth_vl,
        s.fastusd_value - b.fastusd_value AS fastusd_vl,
        s.sfastusd_value - b.sfastusd_value AS sfastusd_vl,

        -- 加總所有 TVL 欄位以計算總價值
        (s.usdt_value - b.usdt_value) +
        (s.usdc_value - b.usdc_value) +
        (s.sei_value - b.sei_value) +
        (s.isei_value - b.isei_value) +
        (s.weth_value - b.weth_value) +
        (s.frax_value - b.frax_value) +
        (s.sfrax_value - b.sfrax_value) +
        (s.frxeth_value - b.frxeth_value) +
        (s.sfrxeth_value - b.sfrxeth_value) +
        (s.fastusd_value - b.fastusd_value)+
        (s.sfastusd_value - b.sfastusd_value) AS total_value
    FROM
        query_4284585 s
    JOIN
        query_4282790 b ON s.day = b.day
)

SELECT * FROM tvl_calculation
ORDER BY day;
