WITH strk_tx_summary AS (
    SELECT block_date, block_time, block_number, hash, block_l1_da_mode, block_l1_data_gas_price_in_fri, block_l1_data_gas_price_in_wei,
           block_l1_gas_price_in_fri, block_l1_gas_price_in_wei, actual_fee_amount, actual_fee_unit, sender_address,
           p.symbol, p.price,
           p.price * actual_fee_amount / pow(10, 18) AS fee_usd,
           actual_fee_amount / pow(10, 18) AS fee_adj,
           p.symbol AS fee_token
    FROM starknet.transactions t 
    LEFT JOIN prices.usd_daily p 
    ON p.contract_address IS NULL
       AND p.day = t.block_date
       AND (CASE 
                WHEN t.actual_fee_unit = 'FRI' THEN 'STRK' 
                WHEN t.actual_fee_unit = 'WEI' THEN 'ETH' 
            END) = p.symbol
    WHERE block_time > now() - interval '7' day
)
SELECT avg(fee_usd) as avg_fee, approx_percentile(fee_usd, 0.5) as median_fee, count(*) as transactions
FROM strk_tx_summary
