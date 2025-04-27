-- YEI PROTOCOL CONTRACTS REGISTRY
-- Centralized registry of all protocol contract addresses and configurations

WITH yei_contracts AS (
    SELECT * FROM (
        VALUES
            -- Token Symbol, Underlying Token Address, aToken Address, debtToken Address, Decimals
            ('kavaUSDT', from_hex('B75D0B03c06A926e488e2659DF1A861F860bD3d1'), from_hex('945C042a18A90Dd7adb88922387D12EfE32F4171'), from_hex('25eA70DC3332b9960E1284D57ED2f6A90d4a8373'), 6),
            ('USDT0', from_hex('9151434b16b9763660705744891fA906F660EcC5'), from_hex('368A466cD8679197a08a3F6318B6a5b67df81fb0'), from_hex('6953c1564ff90Ae639f571E774f2c300e49daAFb'), 6),
            ('USDC', from_hex('3894085Ef7Ff0f0aeDf52E2A2704928d1Ec074F1'), from_hex('c1a6f27a4ccbabb1c2b1f8e98478e52d3d3cb935'), from_hex('5Bfc2d187e8c7F51BE6d547B43A1b3160D72a142'), 6),
            ('WETH', from_hex('160345fC359604fC6e70E3c5fAcbdE5F7A9342d8'), from_hex('093066736E6762210de13F92b39Cf862eee32819'), from_hex('CBaD33e1233fc415be5D98E3CFB6AF1f074e67AD'), 18),
            ('wstETH', from_hex('BE574b6219C6D985d08712e90C21A88fd55f1ae8'), from_hex('56eCcE7c130dc9F0D3Af1DD2e31e5C9319b61bb7'), from_hex('C054A292Bf6183b8dEA3E059cBF61a6f9ABf8E47'), 18),
            ('SEI', from_hex('E30feDd158A2e3b13e9badaeABaFc5516e95e8C7'), from_hex('809FF4801aA5bDb33045d1fEC810D082490D63a4'), from_hex('648e683aaE7C18132564F8B48C625aE5038A9607'), 18),
            ('iSEI', from_hex('5Cf6826140C1C56Ff49C808A1A75407Cd1DF9423'), from_hex('a524c4a280f3641743eBa56e955a1c58e300712b'), from_hex('13Cfe1e14379F67f2188120DeCb6a15dA1F3e861'), 6),
            ('sFRAX', from_hex('5Bff88cA1442c2496f7E475E9e7786383Bc070c0'), from_hex('7090D5fdCEfB496651B55c20D56282CbcdDC2EE2'), from_hex('43d095F50366acB0cA2FeAb68eBE2C90383CFa19'), 18),
            ('frxETH', from_hex('43edd7f3831b08fe70b7555ddd373c8bf65a9050'), from_hex('2a662eF26556a7d8795BF7a678E3Dd4b36FDec1e'), from_hex('768a2f5e5397Ff911BDbe488f59b24FE838f529B'), 18),
            ('sfrxETH', from_hex('3Ec3849C33291a9eF4c5dB86De593EB4A37fDe45'), from_hex('1C4b5c523f859c0F1f14A722a1EAFDe10348F995'), from_hex('b2308aB4Ce77A6c73991766Cb76159614115A8e9'), 18),
            ('fastUSD', from_hex('37a4dD9CED2b19Cfe8FAC251cd727b5787E45269'), from_hex('04295E6912F95f2690993473E6CCAAE438Cf3f06'), from_hex('F546E9A1e0F60ec8b89F50A23Bbdd81b0D94Fe3c'), 18),
            ('WBTC', from_hex('0555E30da8f98308EdB960aa94C0Db47230d2B9c'), from_hex('B6298BCD7EC6CA2A6EaBdD84A88969091b2c3291'), from_hex('C7054BC3a42d51c06FF26e0C455a5799183C6A28'), 8),
            ('sfastUSD', from_hex('df77686D99667Ae56BC18f539B777DBc2BBE3E9F'), from_hex('f8FEb964A1D02F61BcD4B8429c82cb8f5ee58993'), from_hex('42BccB9F752F89B27791D43aa7314E52A3CF401a'), 18),
            ('sfrxUSD', from_hex('5Bff88cA1442c2496f7E475E9e7786383Bc070c0'), from_hex('7090D5fdCEfB496651B55c20D56282CbcdDC2EE2'), from_hex('43d095F50366acB0cA2FeAb68eBE2C90383CFa19'), 18),
            ('frxUSD', from_hex('80Eede496655FB9047dd39d9f418d5483ED600df'), from_hex('C15dce4e1BfABbe0897845d7f7Ee56bc37113E08'), from_hex('5BC80c7975221A1e81F4c2fa4c23f29fd067564A'), 18),
            ('SolvBTC', from_hex('541FD749419CA806a8bc7da8ac23D346f2dF8B77'), from_hex('7A2B7109ca4D1557993EBaFA00FA93Af4c636F2E'), from_hex('9f273bA2A559190a6A6f712699ac8Ca30B2E1A6A'), 18),
            ('xSolvBTC', from_hex('CC0966D8418d412c599A6421b760a847eB169A8c'), from_hex('D36ceD499E83c778b3c79b2cB76DED61108E301b'), from_hex('29e59fba0458F4e8BcD59E992C6fa140e30FA245'), 18)
    ) AS t(symbol, underlying_token, a_token, debt_token, decimal)
)

-- Final output
SELECT 
    symbol,
    underlying_token,
    a_token,
    debt_token,
    decimal
FROM yei_contracts
ORDER BY symbol;
